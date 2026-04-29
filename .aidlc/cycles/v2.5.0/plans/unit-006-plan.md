# Unit 006 計画: 氾濫緩和（重複検出 + サイクル毎上限）

## 概要

Unit 005 が実装した mirror フロー（detect → AskUserQuestion → send / record）に対する**後付けフィルタ**として、同一サイクル内 retrospective.md における重複項目の統合と、サイクル毎の上限ガードを実装する。Unit 005 の `_detect()` 内で `skill_caused=true` 候補を `_classify_candidates` で検出した直後、**candidate 出力前**に新規フィルタ層 `_filter_dedup_and_cap` を挿入する。フィルタ層は純粋関数として切り出し、ユニットテストで挙動を検証する。

スコープは「同一サイクル内の重複検出 + サイクル毎の上限ガード」に限定する（過去サイクル横断 / AI 推論ベース類似度 / 優先度フィルタは v2.6.x 以降）。

## 前提条件と関連 Unit

- **Unit 005 完了済み**: `retrospective-mirror.sh` の `_detect()` が candidate 行 TSV `mirror\tcandidate\t<idx>\t<title>\t<draft_path>` を出力する構造が確立済み
- **Unit 004 完了済み**: `retrospective-schema.yml` を単一ソースとする検証契約が確立済み
- **Unit 006 の挿入点**: Unit 005 の `_detect()` における classify → emit candidate の中間。フィルタ層は **拡張された classify 出力 TSV**（後述）を入力とし、emit 対象 idx 集合 + 抑制対象 idx 集合 + 抑制理由を返す純粋関数（**ファイル I/O 禁止 / 副作用なし / 入出力のみ**）
- **後方互換**: `feedback_max_per_cycle` が未設定（旧 defaults.toml）のときはスキーマ default = 3 を使用

## 対象ストーリー

| # | ストーリー | 受け入れ基準（要約） |
|---|-----------|---------------------|
| 7 | 氾濫緩和（重複検出 + サイクル毎上限） | 同一サイクル内で skill 引用箇所の正規化一致 / タイトル類似度しきい値超過の項目をグルーピングし最初の 1 件のみ candidate に通す。`skill_caused=true` 件数が `feedback_max_per_cycle` を超えた時点で超過分を AskUserQuestion 抑制。dedup-merged / cap-exceeded を summary 行に記録 |

## スコープと境界

### 含まれるもの

- `defaults.toml` に `[rules.retrospective] feedback_max_per_cycle = 3` を追加（user-global / project-local 上書き可）
- `retrospective-schema.yml` に `flood_mitigation` セクションを追加（`feedback_max_per_cycle_default` / `dedup_quote_normalize_rules` / `dedup_jaccard_threshold_milli` (整数 0..1000 / default 700) / `dedup_edit_distance_ratio_pct` (整数 0..100 / default 30) / `nfkc_unavailable_policy: fatal` / `cap_strategy: skip-and-record`）。**旧キー名 `dedup_jaccard_threshold` / `dedup_edit_distance_ratio` は採用しない**（浮動小数点回避のため整数キーに統一）
- `retrospective-mirror.sh` に `_filter_dedup_and_cap()` 関数を新規追加（**純粋関数 / ファイル I/O 禁止 / 拡張 6 列 candidate TSV を入力**。詳細は §2 / §3 / §4 参照）
- `_detect()` を改修し、emit candidate の直前にフィルタ層を呼び出す
- summary 行を拡張: `summary\tcounts\ttotal=N;skill_caused_true=K;already-processed=M;dedup-merged=D;cap-exceeded=C` 形式
- TSV 出力に dedup-merged / cap-exceeded 行を追加（idx 単位の抑制理由を機械可読化）: `mirror\tdedup-merged\t<idx>\t<merged-into-idx>` / `mirror\tcap-exceeded\t<idx>\t<count>;<max>`

### 含まれないもの

- 過去サイクル横断の重複検出（v2.6.x 以降）
- LLM ベース類似度判定（NFR で禁止）
- 優先度フィルタ（自動起票候補 / Mirror 推奨の振り分け / v2.5.0 スコープ外）
- `defaults.toml` 既存キー（`feedback_mode` / `upstream_repo`）への変更

## 技術設計の方向性

### 1. しきい値の単一ソース化

`retrospective-schema.yml` に `flood_mitigation` セクションを追加し、Unit 006 / Unit 007 以降が共有する。**しきい値は整数で永続化**（実装側の bash が浮動小数点を扱えないため、計画段階で整数化を確定）。

```yaml
retrospective_schema:
  # ... 既存定義 ...
  flood_mitigation:
    feedback_max_per_cycle_default: 3
    dedup_quote_normalize_rules:
      - trim_whitespace        # 前後空白除去
      - collapse_whitespace    # 連続空白を 1 個に
      - nfkc_unicode           # 全角半角揃え（NFKC 正規化 / Python 3 必須）
    # Jaccard 整数化: 内部スケール *1000、切り捨て丸め。閾値 700 = 0.700 ちょうど
    dedup_jaccard_threshold_milli: 700
    # 編集距離比率の整数化: 距離 / 短い側長 * 100、切り捨て。閾値 30 = 30%
    dedup_edit_distance_ratio_pct: 30
    # NFKC 不可時の方針: fatal（exit 2 + error\tnfkc-unavailable）。CI で Python 3 必須
    nfkc_unavailable_policy: fatal
    cap_strategy: skip-and-record
```

#### 整数化の丸め規則（Codex Round 1 指摘 #3 反映）

- Jaccard 比較: `intersection_size * 1000 / union_size`（bash 整数除算 = 切り捨て）。閾値判定 `>= 700`
- 編集距離比較: `edit_distance * 100 / min(len_a, len_b)`（切り捨て）。閾値判定 `<= 30`
- 境界値: 0.6995 → 699（不一致） / 0.7000 → 700（一致） / 0.7004 → 700（一致）

### 2. classify 出力 TSV の拡張（Codex Round 1 指摘 #1 / #2 反映）

Unit 005 の `_classify_candidates` 出力は現状 `candidate\t<idx>\t<state-or-dash>\t<skill_caused>` の 4 列のみ。dedup 判定に必要な「正規化済み引用箇所」と「タイトル」をフィルタへ渡すため、以下のように拡張する:

```text
candidate\t<idx>\t<state-or-dash>\t<skill_caused>\t<title>\t<normalized_quote>
```

| 列 | 値 | 責務 |
|----|----|------|
| 1 | `candidate` | 種別タグ（既存） |
| 2 | `<idx>` | 1 始まり整数（既存） |
| 3 | `<state-or-dash>` | mirror_state.state（空時は `-`、既存） |
| 4 | `<skill_caused>` | 派生値 true/false（既存） |
| 5 | `<title>` | extract → `_extract_title` で事前抽出した文字列（**新規**） |
| 6 | `<normalized_quote>` | q1〜q3_quote のうち最初の non-empty を `_normalize_quote` で正規化した値（**新規**） |

**列 5 / 6 の責務**: `_classify_candidates` が `_extract_title` / `_normalize_quote` を呼び出して事前展開する。フィルタ層は受け取った 6 列のみで判定し、ファイル I/O は一切行わない（純粋関数性を保証）。

### 3. 重複検出アルゴリズム

#### Pass A: skill 引用箇所完全一致（正規化後）

正規化済み引用箇所は **classify 段で事前展開済み**（列 6）。フィルタ内では正規化処理は行わず、列 6 の文字列をそのまま比較する。正規化ルール（`_classify_candidates` で事前適用）:

1. `trim_whitespace`: 前後空白除去
2. `collapse_whitespace`: 連続空白（タブ・改行含む）を半角スペース 1 個に
3. `nfkc_unicode`: NFKC 正規化（全角英数 → 半角、合成文字統一 / Python 3 必須）

フィルタ内では列 6 の正規化済み文字列が完全一致する candidate を 1 グループとし、最小 idx を「主候補」、それ以外を「dedup-merged」と分類。

#### Pass B: タイトル類似度

タイトル（列 5）は `_classify_candidates` 段で `_normalize_title`（trim + collapse + NFKC、引用箇所と同じ正規化）を適用済み前提。フィルタ内では列 5 の正規化済み文字列同士を比較し、以下のいずれかに該当すれば同グループ:

- Jaccard 整数比較 `>= 700`（文字 bigram ベース / `_jaccard_bigram_milli` 関数）
- 編集距離整数比較 `<= 30`（`_edit_distance_ratio_pct` 関数）

判定は **Pass A の主候補のみ**を比較対象にする（Pass A で merged された項目はすでに代表に統合済み）。

### 4. 上限ガード

Pass A + Pass B 後の主候補集合に対し、idx 昇順で `feedback_max_per_cycle` 件まで通過させる。超過分は `cap-exceeded` として stdout に記録、AskUserQuestion 抑制対象とする。

設定解決順序（既存 4 階層マージ）:
1. project-local: `.aidlc/config.toml`
2. project-shared: `.aidlc/shared.toml`
3. user-global: `~/.config/aidlc/config.toml`
4. defaults: `skills/aidlc/config/defaults.toml`

不正値（負数 / 整数以外）はスキーマ default = 3 にフォールバック + stderr に warn ログ。

### 5. 出力フォーマット拡張

#### TSV 出力（既存 + 新規）

| kind | 用途 |
|------|------|
| `mirror\tcandidate\t<idx>\t<title>\t<draft_path>` | （既存）emit 対象 |
| `mirror\tdedup-merged\t<idx>\t<merged-into-idx>` | （新規）重複統合された候補 |
| `mirror\tcap-exceeded\t<idx>\t<count>;<max>` | （新規）上限超過候補 |
| `summary\tcounts\ttotal=N;skill_caused_true=K;already-processed=M;dedup-merged=D;cap-exceeded=C` | （拡張）件数集計 |

#### Step 5 文書側

- detect 出力で `mirror\tcandidate` 行のみが AskUserQuestion 対象（Unit 005 既定）
- `mirror\tdedup-merged` / `mirror\tcap-exceeded` 行は summary に件数表示するのみ（対話なし）

## テスト戦略

### 観点 F (Filter)

`_filter_dedup_and_cap` 純粋関数を直接呼び出すユニットテスト:

- F1: 引用箇所完全一致（正規化前）→ 1 件のみ通過
- F2: 引用箇所が前後空白違い（正規化で一致）→ 1 件のみ通過
- F3: 引用箇所が全角半角違い（NFKC で一致）→ 1 件のみ通過
- F4: タイトル類似度 Jaccard 700/1000 ちょうど → 統合
- F4b: タイトル類似度 Jaccard 701/1000 → 統合（境界直後）
- F5: タイトル類似度 Jaccard 699/1000 → 統合しない（境界直前）
- F5b: タイトル類似度 Jaccard 695/1000 → 統合しない
- F6: 上限超過なし（候補 2 件 / max=3）→ 全通過
- F7: 上限超過（候補 5 件 / max=3）→ 3 件通過 + 2 件 cap-exceeded
- F8: dedup → cap の順序保証（候補 5 件中 2 件が dedup マージ → 残り 3 件 / max=3）→ 全通過

### 観点 DI (Detect Integration)

`_detect()` 呼び出しでフィルタ統合の挙動を end-to-end 検証:

- DI1: dedup フィクスチャで `mirror\tdedup-merged` 行 + 主候補のみ candidate emit
- DI2: cap フィクスチャ（5 candidate）で 3 件 candidate + 2 件 cap-exceeded
- DI3: summary 行に dedup-merged=N / cap-exceeded=M 反映確認
- DI4: feedback_max_per_cycle = 0（極端設定）で全 candidate cap-exceeded
- DI5: 不正値（"abc"）でスキーマ default フォールバック + stderr warn
- DI6: Python 3 不在環境で fatal（exit 2 + `error\tnfkc-unavailable`）/ Codex Round 1 #4 反映

### 観点 RG (Regression)

既存 Unit 005 テストが回帰しないこと:

- detect 7 / send 6 / record 6 / step-integration 5 = 24 PASS（変更なし）
- retrospective 43 PASS（変更なし）

### フィクスチャ追加

- `tests/fixtures/retrospective-mirror/dedup-quote-match/`（引用箇所一致 3 件）
- `tests/fixtures/retrospective-mirror/dedup-title-similar/`（タイトル類似 2 件）
- `tests/fixtures/retrospective-mirror/cap-exceeded-5items/`（5 件 candidate）

## 影響ファイル

| ファイル | 変更種別 | 概要 |
|---------|---------|------|
| `skills/aidlc/config/defaults.toml` | 編集 | `[rules.retrospective] feedback_max_per_cycle = 3` 追加 |
| `skills/aidlc/config/retrospective-schema.yml` | 編集 | `flood_mitigation` セクション追加 |
| `skills/aidlc/scripts/retrospective-mirror.sh` | 編集 | `_filter_dedup_and_cap` 追加 + `_detect()` 統合 |
| `skills/aidlc/steps/operations/04-completion.md` | 編集 | Step 5 文書に dedup-merged / cap-exceeded 行の意味記載 |
| `tests/retrospective-mirror/dedup.bats` | 新規 | 観点 F の F1〜F5b（dedup 単体 / 7 件）+ DI1（detect 統合） |
| `tests/retrospective-mirror/cap.bats` | 新規 | 観点 F の F6〜F8（cap 単体 / 3 件）+ DI2〜DI6（detect 統合 / Python 3 不在 fatal を含む 5 件） |
| `tests/fixtures/retrospective-mirror/dedup-*/` | 新規 | 重複系 2 種 |
| `tests/fixtures/retrospective-mirror/cap-exceeded-5items/` | 新規 | 上限超過 1 種 |

## エラー処理方針

| ケース | 検出 | 対応 |
|-------|------|------|
| feedback_max_per_cycle 不正値 | dasel 型解析失敗 / 負数 / 非整数 | warn ログ + スキーマ default フォールバック（recoverable） |
| dedup_jaccard_threshold_milli 不正値 | 0〜1000 範囲外 / 非整数 | warn ログ + スキーマ default 700 fallback |
| dedup_edit_distance_ratio_pct 不正値 | 0〜100 範囲外 / 非整数 | warn ログ + スキーマ default 30 fallback |
| 引用箇所抽出失敗（YAML 解析エラー） | extract → classify が失敗 | Unit 005 既定経路（exit 2 fatal）に従う / 本 Unit では新規エラーを追加しない |
| NFKC 不可（Python 3 不在） | `command -v python3` 失敗 | **fatal**（exit 2 + `error\tnfkc-unavailable\tpython3-required`）/ CI で Python 3 必須 / Codex Round 1 #4 反映 |

## 完了条件チェックリスト

### スコープ完遂

- [x] `defaults.toml` に `[rules.retrospective] feedback_max_per_cycle = 3` が追加され、4 階層マージ（user-global / project-shared / project-local / defaults）で正しく解決される（DI5 で不正値 fallback 含めて検証済み）
- [x] `retrospective-schema.yml` に `flood_mitigation` セクションが追加され、しきい値が単一ソースとして読み込まれる（dasel 経由 6 キー読み込み確認）
- [x] `_filter_dedup_and_cap` が純粋関数（ファイル I/O なし）として実装され、観点 F の F1〜F5c + F6〜F8（合計 11 件）が PASS する（純粋性レベル: ビジネス副作用なし / python3 サブプロセスのみ許容）
- [x] `_detect()` がフィルタ層を統合し、観点 DI の DI1〜DI6（6 件）が PASS する
- [x] dedup-merged / cap-exceeded 行が TSV 出力に追加される（`mirror\tdedup-merged\t<idx>\t<rep_idx>` / `mirror\tcap-exceeded\t<idx>\t<count>;<max>`）
- [x] summary 行が `dedup-merged=N;cap-exceeded=M` を含む拡張形式で出力される

### 品質基準

- [x] bats テスト合計 17 件 PASS（観点 F 11 件 / F1〜F5c + F6〜F8 + 観点 DI 6 件 / DI1〜DI6）
- [x] shellcheck で警告ゼロ（`retrospective-mirror.sh` actionable 0 件 / SC1091 SC2016 info のみ残存）
- [x] markdownlint で警告ゼロ（unit-006-plan.md / 設計 .md / retrospective_template.md / 04-completion.md）
- [x] 既存 retrospective-mirror テスト 24 件が引き続き全件 PASS
- [x] 既存 retrospective テスト 43 件が引き続き全件 PASS
- [x] **Unit 005 の終了コード契約（detect / send / record の exit 0 / 2 / recoverable failure 5 種）が回帰しない**（DR-006 整合 / 実績: 既存 24/24 PASS）
- [x] `.github/workflows/migration-tests.yml` の PATHS_REGEX が `tests/retrospective-mirror/.+` / `tests/fixtures/retrospective-mirror/.+` で新規 .bats / フィクスチャをカバー済み（変更不要）

### Issue 受け入れ基準（#590 Story 7）との対応

- [x] 同一サイクル内で重複する `skill_caused=true` 項目が最初の 1 件のみ candidate に通る（F1〜F3 / DI1 で検証済み）
- [x] `feedback_max_per_cycle` 超過分が AskUserQuestion 抑制対象として記録される（F6〜F7 / DI2〜DI4 で検証済み）
- [x] `feedback_max_per_cycle` を user-global で上書き可能（read-config.sh の 4 階層マージ経由で動作確認）
- [x] LLM 推論を使わない（NFR / 純粋関数実装 / python3 NFKC・Jaccard・Levenshtein のみ）

## 既知のリスクとミティゲーション

### リスク 1: bash での Jaccard 係数計算精度（解消済み）

- **リスク**: 浮動小数点演算（bash は整数のみ）で境界値判定がブレる
- **ミティゲーション**: スキーマ側で `dedup_jaccard_threshold_milli` (整数 0〜1000) として永続化し、計算は `intersection * 1000 / union`（bash 整数除算 = 切り捨て）で `>= 700` 比較。編集距離も `edit_distance * 100 / min_len` で `<= 30` 比較
- **検証**: F4（700 ちょうど）/ F4b（701）/ F5（699）/ F5b（695）の 4 境界値テストで担保

### リスク 2: NFKC 正規化のシェル依存（解消済み・fatal 方針確定）

- **リスク**: macOS BSD `iconv` と GNU `iconv` で NFKC 動作差。シェル単独では NFKC 完全対応不可
- **ミティゲーション**: **Python 3 必須**前提に統一（`python3 -c 'import unicodedata,sys; print(unicodedata.normalize("NFKC", sys.stdin.read()))'`）。Python 不在時は **fatal**（exit 2 + `error\tnfkc-unavailable\tpython3-required`）として degrade 動作を許容しない
- **CI 整合**: `.github/workflows/migration-tests.yml` のランナー（ubuntu-latest）は Python 3 標準同梱のため CI 動作は保証済み
- **代替案検討と却下**: `iconv` フォールバックは Story 7「正規化一致」要件を環境差で満たせない可能性があるため不採用（Codex Round 1 #4 反映）

### リスク 3: フィルタ層の責務複雑化

- **リスク**: dedup と cap を 1 関数に詰めると Unit テストが書きづらい
- **ミティゲーション**: 以下 6 ヘルパーに分解。**フィルタ本体（`_filter_dedup_and_cap`）はファイル I/O 禁止 / 入出力のみ**。タイトル抽出と引用箇所正規化は `_classify_candidates` 段で事前展開（純粋関数性確保 / Codex Round 1 #2 反映）
  - `_normalize_text(s)` → string（trim + collapse + NFKC / classify 段で使用）
  - `_jaccard_bigram_milli(a, b)` → integer 0..1000
  - `_edit_distance_ratio_pct(a, b)` → integer 0..100
  - `_dedup_pass_a(rows)` → groups（引用箇所完全一致）
  - `_dedup_pass_b(rows)` → groups（タイトル類似度 / Pass A 残のみ対象）
  - `_cap_filter(rows, max)` → (passing_idx[], cap_exceeded_idx[])
  - `_filter_dedup_and_cap(rows, max)`: 上記 6 関数を呼び出すオーケストレーション責務のみ

## 実装順序

1. defaults.toml + retrospective-schema.yml にしきい値定義追加
2. ヘルパー関数群（normalize / jaccard / edit_distance / cap_filter）実装
3. `_filter_dedup_and_cap` オーケストレーション実装
4. `_detect()` への統合
5. 観点 F のユニットテスト作成 + 反復修正
6. 観点 DI のインテグレーションテスト作成 + 反復修正
7. summary 行 / 04-completion.md ドキュメント更新

## Unit 007 への引き継ぎ点

- 本 Unit 後の dedup-merged / cap-exceeded 行は機械可読 TSV のため、Unit 007 が「過去サイクル横断重複検出」を加える際の入力として再利用可能
- `flood_mitigation` セクションは将来の `cross_cycle_dedup_enabled` などの拡張ポイントとして設計
