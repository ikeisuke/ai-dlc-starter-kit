# 論理設計: Unit 006 氾濫緩和（重複検出 + サイクル毎上限）

## 概要

Unit 005 が実装した mirror フロー（detect → AskUserQuestion → send / record）に対する**後付けフィルタ層**を、Unit 005 の `_detect()` 内に挿入する論理設計。フィルタ層は **純粋関数（ファイル I/O 禁止）** として `_filter_dedup_and_cap` を中心に構築し、しきい値は `retrospective-schema.yml` の `flood_mitigation` セクション + `defaults.toml` 4 階層マージで単一ソース化する。

**Unit 006 のスコープ（明示）**:

| 項目 | スコープ内／外 |
|------|---------------|
| `skills/aidlc/scripts/retrospective-mirror.sh` への `_filter_dedup_and_cap` + 6 ヘルパー関数追加 | **スコープ内**（主目的）|
| Unit 005 `_classify_candidates` の出力 TSV 4 列 → 6 列拡張（title / normalized_quote 追加） | **スコープ内** |
| `_detect()` のフィルタ層統合（classify → filter → emit） | **スコープ内** |
| `skills/aidlc/config/retrospective-schema.yml` への `flood_mitigation` セクション追加 | **スコープ内** |
| `skills/aidlc/config/defaults.toml` への `[rules.retrospective] feedback_max_per_cycle = 3` 追加 | **スコープ内** |
| `tests/retrospective-mirror/dedup.bats` / `cap.bats` および fixtures 新規作成 | **スコープ内** |
| `.github/workflows/migration-tests.yml` の PATHS_REGEX 拡張 / Python 3 動作確認 | **スコープ内** |
| `skills/aidlc/steps/operations/04-completion.md` の Step 5 文書補足（dedup-merged / cap-exceeded 行の意味記載）| **スコープ内** |
| 過去サイクル横断の dedup | **スコープ外**（v2.6.x 以降）|
| LLM ベース類似度判定 | **スコープ外**（NFR で禁止）|
| 優先度フィルタ（Mirror 推奨 / 自動起票候補の振り分け）| **スコープ外**（v2.5.0 全体スコープ外）|

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的な bash 実装 / bats アサーション / YAML 差分 / Markdown 文言は Phase 2（コード生成）で作成する。

## アーキテクチャパターン

**Pure Function Filter Pipeline**（本 Unit で新規導入）+ **Strict Step-Script Separation Pattern**（Unit 004 から継承）+ **Schema-Driven Single Source**（Unit 004 から継承）。

フィルタ層は副作用を持たない純粋関数として実装し、入出力のみで完結する。Step 文書 / Script の責務分離は Unit 004 / 005 と同じ。

**選定理由**:

- 純粋関数化によりユニットテストでフィルタロジック単体を直接検証可能（観点 F のテストが拡張 6 列 TSV 行を直接渡して検証）
- Pipeline 構成（Pass A → Pass B → Cap）により、各ステップの責務が分離されレビュー / 拡張が容易
- 既存 Unit 005 のサブコマンド境界（detect / send / record）は変更せず、内部実装のみ拡張するため後方互換維持

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/
├── config/
│   ├── retrospective-schema.yml                   [変更]  flood_mitigation セクション追加
│   └── defaults.toml                              [変更]  [rules.retrospective] feedback_max_per_cycle = 3 追加
├── scripts/
│   └── retrospective-mirror.sh                    [変更]
│       ├── _normalize_text(s)                     [新規]  trim + collapse + NFKC（Python 3）
│       ├── _resolve_flood_mitigation_config()     [新規]  schema + defaults.toml 4 階層マージ
│       ├── _classify_candidates()                 [変更]  4 列 → 6 列（title / normalized_quote 追加）
│       ├── _jaccard_bigram_milli(a, b)            [新規]  整数 Jaccard 計算
│       ├── _edit_distance_ratio_pct(a, b)         [新規]  整数編集距離比率計算
│       ├── _dedup_pass_a()                        [新規]  stdin: 6列 → stdout: 7列 / 引用箇所完全一致グルーピング
│       ├── _dedup_pass_b(jaccard_milli, edit_dist_pct)  [新規]  stdin: 7列 → stdout: 7列 / タイトル類似度グルーピング
│       ├── _cap_filter(max)                       [新規]  stdin: 7列 → stdout: 7列 / 上限超過抑制
│       ├── _filter_dedup_and_cap(max, jaccard_milli, edit_dist_pct)  [新規]  stdin: 6列 TSV → stdout: 7列 TSV / オーケストレーション（ビジネス副作用なし）
│       └── _detect()                              [変更]  classify → filter → emit に拡張
└── steps/operations/
    └── 04-completion.md                           [変更]  Step 5 文書補足（TSV 行種別記載）

tests/retrospective-mirror/
├── dedup.bats                                     [新規]  観点 F の F1〜F5b（7 件）+ DI1
├── cap.bats                                       [新規]  観点 F の F6〜F8（3 件）+ DI2〜DI6（5 件）
└── fixtures/
    ├── dedup-quote-match/                         [新規]
    ├── dedup-title-similar/                       [新規]
    └── cap-exceeded-5items/                       [新規]
```

### コンポーネント依存関係

```text
+--------------------------------------------------------------------+
| skills/aidlc/scripts/retrospective-mirror.sh _detect()             |
|                                                                    |
|   _extract → _classify_candidates(*)                               |
|     │   (* 6 列 TSV: kind/idx/state/sc/title/normalized_quote)     |
|     │                                                              |
|     ↓                                                              |
|   _resolve_flood_mitigation_config()                               |
|     │   stdout: config\t<max>\t<jaccard_milli>\t<edit_pct>\t...    |
|     │   (TSV 1 行 / 呼び出し側で read して引数に詰め直す)           |
|     │                                                              |
|     ↓                                                              |
|   _filter_dedup_and_cap(max, jaccard_milli, edit_dist_pct)         |
|       stdin: 6列 candidate TSV → stdout: 7列（status 列付与）       |
|       ビジネス副作用なし（python3 サブプロセスあり / 全設定値を     |
|       引数で明示的に受け取る）                                       |
|     │                                                              |
|     ├── _dedup_pass_a()                  (stdin: 6列 → stdout: 7列)|
|     │     └── (引用箇所完全一致 → MergeReason.QuoteExactMatch)     |
|     │                                                              |
|     ├── _dedup_pass_b(jaccard_milli, edit_dist_pct)                |
|     │     │     (stdin: 7列 → stdout: 7列)                         |
|     │     ├── _jaccard_bigram_milli(title_a, title_b)              |
|     │     │     └── 整数比較 >= jaccard_milli                      |
|     │     └── _edit_distance_ratio_pct(title_a, title_b)           |
|     │           └── 整数比較 <= edit_dist_pct                      |
|     │                                                              |
|     └── _cap_filter(max)                 (stdin: 7列 → stdout: 7列)|
|           └── idx 昇順で max 件まで通過                            |
|                                                                    |
|   FilterResult → emit candidate (passing_indices のみ)             |
|              → emit dedup-merged TSV 行                            |
|              → emit cap-exceeded TSV 行                            |
|              → emit summary 拡張行                                 |
+--------------------------------------------------------------------+

+--------------------------------------------------------------------+
| skills/aidlc/config/retrospective-schema.yml                        |
|   flood_mitigation:                                                 |
|     feedback_max_per_cycle_default: 3                               |
|     dedup_quote_normalize_rules: [trim/collapse/nfkc]               |
|     dedup_jaccard_threshold_milli: 700  (整数 0..1000)              |
|     dedup_edit_distance_ratio_pct: 30   (整数 0..100)               |
|     nfkc_unavailable_policy: fatal                                  |
|     cap_strategy: skip-and-record                                   |
+--------------------------------------------------------------------+

+--------------------------------------------------------------------+
| skills/aidlc/config/defaults.toml                                   |
|   [rules.retrospective]                                             |
|   feedback_max_per_cycle = 3                                        |
+--------------------------------------------------------------------+

+--------------------------------------------------------------------+
| 外部依存: python3 (NFKC)                                            |
|   _normalize_text 内で `python3 -c '...unicodedata.normalize("NFKC")'` |
|   不在時: exit 2 + error\tnfkc-unavailable\tpython3-required (fatal) |
+--------------------------------------------------------------------+
```

依存方向は `_detect()` → ヘルパー関数群（一方向）。フィルタ層内では Pass A → Pass B → Cap の単方向 Pipeline。循環依存なし。

## インターフェース定義

### コンポーネント A: `skills/aidlc/scripts/retrospective-mirror.sh`（変更）

#### 既存サブコマンド構成（Unit 005 / 変更なし）

| サブコマンド | 引数 | 主要責務 | exit code |
|------------|------|---------|----------|
| `detect` | `<retrospective.md>` | feedback_mode 解決 / candidate 抽出 / **フィルタ層適用** / IssueDraft 生成 | 0（候補ありなしいずれも） / 2（fatal） |
| `send` | `<retrospective.md> <problem_index> <title> <draft_body_path>` | （Unit 005 既定 / 本 Unit で変更なし） | 0（成功 + recoverable failure） / 2（fatal） |
| `record` | `<retrospective.md> <problem_index> <decision>` | （Unit 005 既定 / 本 Unit で変更なし） | 0（成功） / 2（fatal） |

#### 新規 / 変更関数の論理 API

| 関数名 | 入力 | 出力 | 純粋関数性 | 失敗時動作 |
|-------|------|------|-----------|-----------|
| `_normalize_text(s)` | String s | String（trim/collapse/NFKC 後） | I/O依存あり（python3 サブプロセス呼び出し）/ ビジネス副作用なし | python3 不在時は親 _detect() に伝播 → exit 2 fatal |
| `_resolve_flood_mitigation_config()` | （引数なし） | **stdout 1 行に TSV 構造化出力**: `config\t<feedback_max_per_cycle>\t<jaccard_milli>\t<edit_dist_pct>\t<nfkc_policy>\t<cap_strategy>` | dasel 経由 schema 読み込み + 4 階層 toml マージ。**呼び出し側は read で TSV を解析して引数に詰め直し`_filter_dedup_and_cap` へ明示的に渡す（暗黙的グローバル変数経由は禁止）** | 不正値は schema default に fallback + warn ログ stderr 出力（recoverable）|
| `_classify_candidates(extracted_tsv, retrospective_path)` | extract 出力 TSV, retrospective.md パス | candidate TSV（**6 列**: kind/idx/state/sc/title/normalized_quote） | I/O依存あり（retrospective.md から `_extract_title` で title 抽出 + `_normalize_text` 呼び出し）/ ビジネス副作用なし | extract 不在時は exit 2 fatal / title 抽出失敗時は `（タイトル不明）` プレースホルダ |
| `_jaccard_bigram_milli(a, b)` | String a, String b | Integer 0..1000 | **ビジネス副作用なし**（マルチバイト文字対応のため python3 経由で計算 / NFKC 後の文字単位 bigram） | 入力空文字時は 0 を返す。Python 3 不在は親 _detect() に伝播 → exit 2 fatal |
| `_edit_distance_ratio_pct(a, b)` | String a, String b | Integer 0..100 | **ビジネス副作用なし**（マルチバイト文字対応のため python3 経由で Levenshtein 距離計算） | 両方空文字時は 0 を返す。Python 3 不在は親 _detect() に伝播 → exit 2 fatal |
| `_dedup_pass_a(rows)` | stdin: 6列 TSV | stdout: 7列 TSV（dedup-merged:<rep>:quote-exact-match status 付与） | **完全純粋** | エラーなし |
| `_dedup_pass_b(jaccard_milli, edit_dist_pct)` | stdin: 7列 TSV, Integer jaccard_milli, Integer edit_dist_pct | stdout: 7列 TSV（status 更新） | **ビジネス副作用なし**（`_jaccard_bigram_milli` / `_edit_distance_ratio_pct` 経由で python3 サブプロセス呼び出しあり） | エラーなし |
| `_cap_filter(max)` | stdin: 7列 TSV, Integer max | stdout: 7列 TSV（status 更新） | **完全純粋（awk のみ）** | max < 0 は schema default に置換 |
| `_filter_dedup_and_cap(max, jaccard_milli, edit_dist_pct)` | stdin: 6列 TSV, Integer max, Integer jaccard_milli, Integer edit_dist_pct | stdout: 7列 TSV（passing / dedup-merged / cap-exceeded） | **ビジネス副作用なし（_dedup_pass_b 経由で python3 サブプロセス呼び出しあり / グローバル変数禁止 / 引数で全設定値を受け取る）** | 内部関数の伝播のみ |
| `_detect()` | retrospective.md path | TSV 行群 + summary 行 | I/O 依存あり（ファイル I/O / config 読み込み）/ ビジネス副作用あり（draft 一時ファイル作成） | exit 0 / 2（Unit 005 既定維持）|

#### 純粋性の定義（本設計で使用する区別）

- **完全純粋**: 同じ入力に対し常に同じ出力を返し、I/O 副作用も外部プロセス依存もない。bash 整数演算 / 文字列操作のみで完結
- **ビジネス副作用なし**: ファイル / 永続ストアを更新せず、呼び出しても同等系の状態が変化しない。ただし実装上は外部プロセス（python3）/ 一時ファイル / stderr 警告ログは許容
- **完全純粋**: `_dedup_pass_a` / `_cap_filter`（awk / bash 整数演算 / 配列操作のみで完結）
- **ビジネス副作用なし**: `_filter_dedup_and_cap` / `_dedup_pass_b` / `_jaccard_bigram_milli` / `_edit_distance_ratio_pct`（マルチバイト文字対応のため python3 サブプロセス呼び出しあり / ファイル / 永続ストア更新なし）/ `_normalize_text` / `_resolve_flood_mitigation_config` / `_classify_candidates`（python3 / dasel / awk / ファイル読み込みあり）

#### `_detect()` 改修フロー（Unit 005 → Unit 006 差分）

```text
[Unit 005]
extract → classify → emit candidate (skill_caused=true && state==Empty)

[Unit 006]
extract → classify (6 列拡張) → resolve_config → filter_dedup_and_cap → emit:
  - candidate (FilterResult.passing_indices のみ)
  - dedup-merged 行群
  - cap-exceeded 行群
  - summary (拡張: dedup-merged=N;cap-exceeded=M 追加)
```

#### 終了コード規約（DR-006 整合 / 本 Unit で追加なし）

| exit code | 出力 | 意味 |
|-----------|------|------|
| `0` + 主要ステータス | `mirror\tcandidate / sent / recorded / skip` | 正常完了 |
| `0` + recoverable | `mirror\tsend-failed\t<idx>\t<reason>` | 個別 candidate 単位の失敗（Unit 005 5 種固定）|
| `2` + fatal | `error\t<code>\t<payload>` | フロー継続不能 |

**本 Unit で追加する fatal エラーコード**: `nfkc-unavailable`（Python 3 不在時）。recoverable failure 列挙は変更しない。

`1` は使用しない（Unit 004 / 005 と同方針）。

### コンポーネント B: `skills/aidlc/config/retrospective-schema.yml`（変更）

#### 追加内容

```yaml
retrospective_schema:
  # ...(既存定義)
  flood_mitigation:
    feedback_max_per_cycle_default: 3
    dedup_quote_normalize_rules:
      - trim_whitespace
      - collapse_whitespace
      - nfkc_unicode
    dedup_jaccard_threshold_milli: 700
    dedup_edit_distance_ratio_pct: 30
    nfkc_unavailable_policy: fatal
    cap_strategy: skip-and-record
```

#### 設定解決優先順位

| 優先 | ソース | キー |
|-----|--------|------|
| 1（最高） | project-local `.aidlc/config.toml` | `[rules.retrospective] feedback_max_per_cycle` |
| 2 | project-shared `.aidlc/shared.toml` | 同上 |
| 3 | user-global `~/.config/aidlc/config.toml` | 同上 |
| 4 | defaults `skills/aidlc/config/defaults.toml` | 同上 |
| 5（最低） | schema `retrospective-schema.yml` | `flood_mitigation.feedback_max_per_cycle_default` |

`dedup_jaccard_threshold_milli` / `dedup_edit_distance_ratio_pct` / `nfkc_unavailable_policy` / `cap_strategy` は schema のみで定義（v2.5.0 では config.toml 上書き不可 / 将来必要時に追加）。

### コンポーネント C: `skills/aidlc/config/defaults.toml`（変更）

#### 追加内容

```toml
[rules.retrospective]
# 既存 feedback_mode は変更しない（Unit 004 / 005）
feedback_max_per_cycle = 3
```

不正値（負数 / 非整数）時の動作: warn ログ + schema default 3 に fallback。

### コンポーネント D: `skills/aidlc/steps/operations/04-completion.md`（変更）

#### 追加内容

Step 5 の補足セクションに以下を明記:

- `mirror\tdedup-merged\t<idx>\t<merged-into-idx>`: 重複統合された候補（AskUserQuestion 対象外）
- `mirror\tcap-exceeded\t<idx>\t<count>;<max>`: 上限超過候補（AskUserQuestion 対象外）
- summary 行の拡張形式: `summary\tcounts\ttotal=N;skill_caused_true=K;already-processed=M;dedup-merged=D;cap-exceeded=C`
- AskUserQuestion 対象は `mirror\tcandidate` 行のみ（既定 / 変更なし）

## エラー処理戦略

### 失敗種別と契約（Unit 005 から継承 + 1 種追加）

| カテゴリ | 検出 | 終了コード | 出力 |
|---------|-----|-----------|------|
| Python 3 不在 | `command -v python3` 失敗 | exit 2 fatal | `error\tnfkc-unavailable\tpython3-required` |
| feedback_max_per_cycle 不正値 | dasel 解析失敗 / 負数 / 非整数 | recoverable | warn ログ + schema default 3 fallback |
| dedup_jaccard_threshold_milli 不正値 | 0..1000 範囲外 / 非整数 | recoverable | warn ログ + schema default 700 fallback |
| dedup_edit_distance_ratio_pct 不正値 | 0..100 範囲外 / 非整数 | recoverable | warn ログ + schema default 30 fallback |
| extract 段の YAML 解析失敗 | extract が exit != 0 | exit 2 fatal | Unit 005 既定経路 |
| その他 fatal（schema 不在 / dasel 不在） | Unit 005 既定 | exit 2 fatal | Unit 005 既定 |

### NFR 観点との対応

| NFR | 該当エラー | 検証方法 |
|-----|-----------|---------|
| AI 推論非依存 | LLM 経路の混入 | コードレビューで検出（pure shell + python3 NFKC のみ）|
| テスタビリティ | フィルタ純粋関数 | 観点 F の F1〜F5b + F6〜F8（10 件）でフィルタ単体 PASS |
| 設定上書き互換 | 4 階層マージ動作 | DI5（不正値 fallback）/ DI4（max=0）で検証 |

## NFR 充足戦略

### 後方互換性

- Unit 004 / 005 の retrospective.md（mirror_state 欠落形式）に対しても本 Unit の `_classify_candidates` 6 列拡張は動作（state は `-` プレースホルダ → `""` 復元、Unit 005 既定経路を維持）
- 既存 Unit 005 テスト（detect 7 / send 6 / record 6 / step-integration 5 = 24 件）は引き続き全件 PASS

### CI 対応

- `.github/workflows/migration-tests.yml` の PATHS_REGEX に `tests/retrospective-mirror/dedup\.bats` / `cap\.bats` / `tests/fixtures/retrospective-mirror/dedup-.+/.+` / `cap-exceeded-.+/.+` を追加
- ubuntu-latest ランナーは Python 3 標準同梱のため NFKC 動作保証
- macOS ローカル実行時も Python 3 (Homebrew / system) があれば動作

### shellcheck 適合性

- 整数演算は `(( ))` または `expr` で実装
- 配列を bash 関数間で渡す場合は名前参照（`local -n`）または改行区切り文字列で渡す
- IFS は明示設定（タブ区切り維持 / Unit 005 で確立した方針）

### markdownlint 適合性

- `04-completion.md` の追記部分は既存セクション構造（見出しレベル / 箇条書き）を維持

## テスト戦略

### bats 観点別マッピング

| 観点 | テスト対象 | 検証ケース | テストファイル |
|------|-----------|-----------|---------------|
| F (Filter) | `_filter_dedup_and_cap` 純粋関数（拡張 6 列 TSV を直接渡す） | F1〜F5b: dedup（7 件）/ F6〜F8: cap（3 件） | dedup.bats / cap.bats |
| DI (Detect Integration) | `_detect()` end-to-end（フィルタ統合後） | DI1〜DI6: dedup フィクスチャ / cap フィクスチャ / 不正値 / max=0 / Python 3 不在 fatal | dedup.bats / cap.bats |
| RG (Regression) | Unit 005 既定テスト | detect 7 / send 6 / record 6 / step-integration 5 | （既存 / 変更なし）|

### フィクスチャ設計

| フィクスチャ | 内容 | 用途 |
|------------|-----|------|
| `dedup-quote-match/` | skill_caused=true 候補 3 件、引用箇所完全一致（半角空白違い + 全角半角違い）| F1 / F2 / F3 / DI1 |
| `dedup-title-similar/` | skill_caused=true 候補 2 件、タイトル類似度 700/699 境界 | F4 / F4b / F5 / F5b |
| `cap-exceeded-5items/` | skill_caused=true 候補 5 件（重複なし）+ feedback_max_per_cycle=3 | F6 / F7 / DI2 |

### テストカバレッジ目標

- フィルタ層純粋関数（観点 F）: ロジック分岐 100%（dedup / cap 両 Pass の分岐網羅）
- detect 統合（観点 DI）: 主要 6 ケース（dedup 適用 / cap 適用 / 不正値 / max=0 / Python 3 不在）
- 既存 Unit 005 / 004: 回帰なし（67 件 PASS 維持）

## 性能 / 計算量

- 入力サイズ: 1 retrospective.md あたり candidate 数 N（典型: 1〜10 件、最大想定: 50 件）
- フィルタ計算量:
  - Pass A: O(N) ハッシュベース（associative array で正規化済み引用箇所をキー）
  - Pass B: O(N²) Pairwise 比較（N=50 で 2500 ペア / 許容範囲）
  - Cap: O(N) 線形通過判定
- 全体: O(N²)（タイトル類似度比較が支配的）。N が 100 を超える場合は事前ソート + 早期打ち切りを検討（v2.6.x 以降）

## セキュリティ考慮事項

| 観点 | 対応 |
|------|-----|
| パストラバーサル | 本 Unit では新規ファイル書き込みなし（フィルタ層は読み取り専用）|
| Python 3 サブプロセス安全性 | `python3 -c` の引数は固定文字列（ユーザー入力を直接渡さない）。stdin から正規化対象を渡す |
| 機密情報漏洩 | `_normalize_text` 入力は retrospective.md 内テキスト（git 管理対象 / 公開済み）。stderr / stdout に正規化済み値を出すが、機密情報を新たに露出しない |
| ログ・監視 | ローカル CLI / 監視基盤なしのため N/A |
| 通信暗号化 | 本 Unit は通信を行わないため N/A |

## Unit 007 への引き継ぎ点

- `_filter_dedup_and_cap` の拡張ポイント: `MergeReason` 列挙に新規値を追加することで AI 類似度判定 / 過去サイクル横断 dedup を後付け可能
- `flood_mitigation` schema セクションに `cross_cycle_dedup_enabled` 等のフラグ追加で機能拡張可能
- `FilterResult` の TSV 行種別（dedup-merged / cap-exceeded）は機械可読のため、Unit 007 が後段でさらに加工する設計が可能

## 設計判断のトレーサビリティ

| 判断 | 根拠 | 代替案と却下理由 |
|------|------|-----------------|
| 純粋関数（ファイル I/O 禁止） | テスタビリティ最大化 / Codex Round 1 #2 反映 | ファイル I/O 許容 → ユニットテスト困難（fixtures 依存）|
| 整数演算（Jaccard `*1000` / 編集距離 `*100`） | bash 互換性 / 浮動小数点誤差排除 / Codex Round 1 #3 反映 | 浮動小数点（bc / awk） → 境界値判定がブレる |
| Python 3 必須 / fatal 方針 | Story 7 「正規化一致」要件を環境差で満たすため / Codex Round 1 #4 反映 | iconv フォールバック → NFKC 不完全（半角全角のみ）/ 要件不成立リスク |
| classify 6 列拡張（title / normalized_quote） | フィルタ純粋関数化のため事前展開 / Codex Round 1 #1 反映 | フィルタ内でファイル読み込み → 純粋関数性破綻 |
| dedup-merged / cap-exceeded TSV 行 | 機械可読 / Unit 007 引き継ぎ容易性 | summary 行のみで件数表示 → Unit 007 で個別 idx 追跡不能 |
