# 論理設計: Unit 004 retrospective テンプレートと Operations 自動生成

## 概要

Operations Phase 完了時に retrospective.md を自動生成 + 検証 + ダウングレードするフローを実装する。markdown-driven step（`steps/operations/04-completion.md` の新セクション `3.5. retrospective 作成`）が**呼び出し順序と分岐のみ**を編成し、bash script（`retrospective-generate.sh` / `retrospective-validate.sh`）が決定論的な生成 + 検証を担う**完全責務分離型ハイブリッド構成**を採る（Unit 003 のハイブリッドパターンを Step → Script 委譲完全化方向で発展させる）。

**Unit 004 のスコープ（明示）**:

| 項目 | スコープ内／外 |
|------|---------------|
| `skills/aidlc/templates/retrospective_template.md` 新規作成 | **スコープ内**（主目的 1） |
| `skills/aidlc/config/retrospective-schema.yml` 新規作成（機械可読契約） | **スコープ内**（主目的 2） |
| `skills/aidlc/scripts/lib/cycle-version-check.sh` 新規作成 | **スコープ内** |
| `skills/aidlc/scripts/retrospective-generate.sh` 新規作成 | **スコープ内** |
| `skills/aidlc/scripts/retrospective-validate.sh` 新規作成（3 段サブコマンド） | **スコープ内** |
| `skills/aidlc/config/defaults.toml` への `[rules.retrospective]` 追加 | **スコープ内** |
| `skills/aidlc/steps/operations/04-completion.md` への `3.5` 追加 | **スコープ内**（既存番号 4 / 5 / 5.5 / 6 / 7 / 8 はそのまま） |
| `tests/retrospective/*.bats` および helpers / fixtures 新規作成 | **スコープ内** |
| `.github/workflows/migration-tests.yml` の PATHS_REGEX + 実行コマンド拡張 | **スコープ内** |
| mirror モードの `/aidlc-feedback` 連動実装 | **スコープ外**（Unit 005） |
| 重複検出 + サイクル毎上限ガード | **スコープ外**（Unit 006） |
| `on` モード（自動起票） | **スコープ外**（v2.6.x 以降） |
| 既存サイクルへの retrospective.md 遡及生成 | **スコープ外**（cycle-version-check で v2.5.0 以降ガード） |

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的な bash 実装 / bats アサーション / YAML 差分 / Markdown 文言は Phase 2（コード生成）で作成する。

## アーキテクチャパターン

**Strict Step-Script Separation Pattern**（Unit 003 の Hybrid Driven Pattern を発展）— Step 文書は呼び出し順序と分岐のみを記述し、判定ロジック / I/O / 検証ルールは全て bash script に集約する。**機械可読契約スキーマ（retrospective-schema.yml）** を導入し、テンプレート文言ではなくスキーマファイルを下流 Unit が参照する単一ソース原則を強化した形態。

**選定理由**:

- マージ前完結契約により retrospective.md の書き込みタイミングが厳密に決まる（5. PR マージ後の手順より前 / 3. バックログ記録の直後）→ Step での順序明文化が必須
- skill 起因判定ロジック（10 文字未満 / 禁止語 4 種 / 6 キー）を Step 文書と script の両方に書くと二重保守 → 完全に script 側に集約
- Unit 005 / Unit 006 はテンプレート文言ではなくスキーマファイルを `dasel` でパースする設計に統一 → テンプレート文言変更で下流が壊れない
- 既存 `_safe_transform`（Unit 001/003 で実績）と `read-config.sh`（4 階層マージ）が本 Unit の I/O 要件に十分適合

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/
├── config/
│   ├── defaults.toml                                  [変更]  [rules.retrospective] feedback_mode = "silent" 追加
│   └── retrospective-schema.yml                       [新規]  機械可読契約スキーマ（単一ソース）
├── templates/
│   └── retrospective_template.md                      [新規]  生成テンプレート
├── scripts/
│   ├── lib/
│   │   └── cycle-version-check.sh                     [新規]  bash 数値比較 v2.5.0 ガード
│   ├── retrospective-generate.sh                      [新規]  生成 + feedback_mode 解決 + 空ファイル禁止補完
│   └── retrospective-validate.sh                      [新規]  3 段責務（extract / validate / apply）
├── steps/operations/
│   └── 04-completion.md                               [変更]  ## 3.5 retrospective 作成 追加（既存 4〜8 / 5.5 はそのまま）
└── (既存 read-config.sh / write-config.sh 等は変更なし)

tests/retrospective/
├── helpers/
│   └── setup.bash                                     [新規]
├── template-structure.bats                            [新規]
├── cycle-version-check.bats                           [新規]
├── feedback-mode-resolution.bats                      [新規]
├── schema-contract.bats                               [新規]
├── generate-script.bats                               [新規]
├── validate-script.bats                               [新規]
└── step-integration.bats                              [新規]

tests/fixtures/retrospective/
├── empty-cycle/                                       [新規]  問題項目 0 件 fixture
├── single-problem-no-cause/                           [新規]  q*_answer 全 no fixture
├── single-problem-yes-valid-quote/                    [新規]  q1_answer=yes / q1_quote 正常 fixture
├── single-problem-yes-empty-quote/                    [新規]  q1_answer=yes / q1_quote 空 fixture
├── single-problem-yes-short-quote/                    [新規]  q1_answer=yes / q1_quote 5 文字 fixture
├── single-problem-yes-forbidden-word/                 [新規]  q1_answer=yes / q1_quote `該当` 単独 fixture
└── multiple-problems/                                 [新規]  3 問題項目 + 各種パターン fixture

.github/workflows/
└── migration-tests.yml                                [変更]  PATHS_REGEX 5 種追加 + 実行コマンド拡張
```

### コンポーネント間の依存関係

```text
[04-completion.md ## 3.5]
   │
   │ (Step 1) アンカー直前 + cycle-version-check 呼び出し
   ▼
[cycle-version-check.sh::aidlc_is_cycle_v25_or_later]
   │ (exit 0/1/2)
   │
   │ (Step 2) generate 呼び出し
   ▼
[retrospective-generate.sh]
   │
   ├──→ [read-config.sh rules.retrospective.feedback_mode]
   │       │ (4 階層マージで FeedbackMode 解決)
   │       ▼
   │     [defaults.toml + user-global + project-shared + project-local]
   │
   ├──→ [templates/retrospective_template.md]
   │       │ (LF/CRLF 統一 / {{cycle}} 置換 / 空ファイル禁止補完)
   │       ▼
   │     [.aidlc/cycles/{{cycle}}/operations/retrospective.md]
   │
   ├──→ stdout: retrospective\tcreated\t<path> / retrospective\tskip\t*
   └──→ stderr: warn\t* / error\t*（補助情報 / Step 機械判定対象外）
   │
   │ (Step 3) 出力プレフィックス分岐 / created で続行
   ▼
[retrospective-validate.sh validate <path> --apply]
   │
   ├──→ [retrospective-schema.yml] (dasel で動的読み込み)
   │       │ (quote_min_length / forbidden_words / 6 キー)
   │       ▼
   │     検証ルール（ハードコードなし）
   │
   ├──→ [生成済み retrospective.md]
   │       │ (Markdown コードブロック → YAML 抽出 → TSV 中間表現)
   │       ▼
   │     [extract → validate → apply の 3 段処理]
   │
   ├──→ stdout: extracted\t* / downgrade\t* / applied\t* / summary\t*
   └──→ stderr: warn\t* / error\t*（補助情報 / Step 機械判定対象外）
   │
   │ (Step 4) downgrade 行を表示
   ▼
[ユーザに完了サマリ提示]
```

**依存方向の原則**:

- Step → Script 単方向（Script は Step を知らない）
- Script → Schema 単方向（Schema は Script を知らない）
- Validate Script → Schema を `dasel` で動的読み込み（ハードコード禁止）
- Generate Script → read-config.sh + テンプレート（4 階層マージは既存 / テンプレートは表示層）
- 下流 Unit 005/006 → Schema 単方向（テンプレート文言には依存しない）

**循環依存なし**:

- Step / Generate / Validate / Schema / cycle-version-check の DAG 構成
- `retrospective-schema.yml` が下層（依存される側のみ）で循環の起点なし

## モジュール / コンポーネント詳細

### コンポーネント A: `skills/aidlc/templates/retrospective_template.md`（新規）

#### 目的

retrospective.md の生成テンプレート。問題項目構造 + skill 起因判定 YAML フロントマターを表示層として提供。検証ルールはこのファイルに書かず、`retrospective-schema.yml` に集約する。

#### 静的構造

- **必須セクション 3 件**: `## 概要` / `## 問題項目` / `## 次サイクルへの引き継ぎ事項`
- **問題項目テンプレート**: `### 問題 N: {{タイトル}}` + 4 サブ見出し（何が起きたか / なぜ起きたか / 損失と影響 / skill 起因判定）+ YAML フロントマターコードブロック
- **空ファイル禁止コメント**: 問題項目 0 件時の自動補完用「問題なし」明示テンプレート（HTML コメント内に記述）
- **YAML フロントマター 6 キー**: q1_answer / q1_quote / q2_answer / q2_quote / q3_answer / q3_quote
- **質問文（コメント内）**: `retrospective-schema.yml` の `questions.q1/q2/q3` と一字一句一致（schema-contract.bats 観点 K2 で検証）

#### 静的検証

- markdownlint 警告ゼロ
- template-structure.bats（観点 T）で必須セクション 3 件 + skill 起因判定 6 キー + markdownlint パスを検証

### コンポーネント B: `skills/aidlc/config/retrospective-schema.yml`（新規）

#### 目的

retrospective フローの検証ルール / 質問文 / 許容値を機械可読 YAML として単一ソース化。テンプレート / 生成 / 検証 / Unit 005 / Unit 006 が**唯一参照する**契約定義。

#### スキーマ構造

```yaml
retrospective_schema:
  version: 1
  required_sections:
    - "## 概要"
    - "## 問題項目"
    - "## 次サイクルへの引き継ぎ事項"
  skill_caused_judgment:
    # 永続化キー（YAML フロントマターに書き出す契約 6 キーのみ。skill_caused は派生値で永続化しない）
    keys: [q1_answer, q1_quote, q2_answer, q2_quote, q3_answer, q3_quote]
    questions:
      q1: "skill 内の具体的な箇所を引用できるか?"
      q2: "別の skill ファイルとの矛盾を示せるか?"
      q3: "「どう読んでも複数解釈できる」と示せるか?"
    answer_enum: [yes, no]
    quote_min_length: 10
    quote_forbidden_words: [該当, あり, 該当箇所, あります]
  # skill_caused は派生値（YAML フロントマターに書き出さず、validate スクリプトが都度計算して summary 行で集計通知）
  skill_caused_rule: "q1_answer / q2_answer / q3_answer のいずれかが yes かつ対応する quote が valid → skill_caused = true（派生値計算 / 永続化しない）"
  # apply ダウングレード時は q*_answer を yes → no に書き換え（quote 違反時の判定不能を表現）
  downgrade_rule: "q*_quote 違反時は対応する q*_answer を no に書き換え。skill_caused は派生値のため書き換え対象外"
  valid_feedback_modes: [silent, mirror, disabled]
  default_feedback_mode: silent
  stable_id: unit004-retrospective-creation
```

#### 動的読み込み契約

- validate スクリプトは `dasel -f retrospective-schema.yml -r yaml` で動的読み込み（ハードコード禁止）
- Unit 005 / Unit 006 は `dasel` で同じスキーマファイルを読み込む
- スキーマ更新時は schema-contract.bats（観点 K / K2）で参照可能性を回帰検証

### コンポーネント C: `skills/aidlc/scripts/lib/cycle-version-check.sh`（新規）

#### 目的

`{{cycle}}` 文字列が v2.5.0 以降かを bash 内蔵数値比較で判定する純粋関数 helper。`sort -V` 不使用で環境差分排除。

#### 関数インターフェース

```text
aidlc_is_cycle_v25_or_later <cycle>
  入力: cycle（^v[0-9]+\.[0-9]+\.[0-9]+$ 形式）
  出力: なし（exit code のみ）
  exit 0: v2.5.0 以降
  exit 1: v2.5.0 未満
  exit 2: フォーマット違反 or 引数不足（stderr に error:cycle-version-check:invalid-format:<input> 出力）
```

#### 実装方針

- `set -euo pipefail` + 関数定義のみ（source して使う）
- 入力フォーマット検証は bash regex（`[[ "$cycle" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]`）
- `v` プレフィックス除去後 `IFS=.` で major/minor/patch に分解
- 数値比較で v2.5.0 と各成分を順に評価（major < 2 → 1 / major > 2 → 0 / major == 2 && minor < 5 → 1 / ...）
- 副作用なし（標準入出力読まない / ファイル書かない / 環境変数依存なし）

#### 静的検証

- cycle-version-check.bats（観点 V）で v2.5.0 以降 4 種 + 未満 3 種 + 異常系 4 種の 11 ケース PASS

### コンポーネント D: `skills/aidlc/scripts/retrospective-generate.sh`（新規）

#### 目的

retrospective.md の生成 + feedback_mode 解決一元化 + テンプレート展開 + 空ファイル禁止補完を担うドメインロジック。Step 文書からの委譲先。

#### サブコマンド

```text
retrospective-generate.sh <cycle>
  入力: cycle（^v[0-9]+\.[0-9]+\.[0-9]+$ 形式 / cycle-version-check.sh で事前検証済み）
  出力: タブ区切り <kind>\t<code>\t<payload> フォーマット行（複数行可）
  exit 0: 正常終了（生成 / disabled スキップ / already-exists スキップ いずれも 0）
  exit 2: fatal エラー
```

#### 内部分岐ロジック

| 分岐条件 | 出力 | exit |
|---------|------|------|
| `feedback_mode = disabled` | `retrospective\tskip\tdisabled` | 0 |
| 既存ファイルあり | `retrospective\tskip\talready-exists` | 0 |
| 不正値（3 値以外） | `warn\tfeedback-mode-invalid\t<value>:downgrade-to-silent` + 通常生成へ | 0 |
| 通常（silent / mirror） | テンプレート展開 + 空ファイル禁止補完 → `retrospective\tcreated\t<path>` | 0 |
| 致命エラー | `error\t<code>\t<payload>` | 2 |

#### 実装方針

- `read-config.sh rules.retrospective.feedback_mode` で値を解決し FeedbackMode に変換
- テンプレート読み込み: `cat skills/aidlc/templates/retrospective_template.md`
- `{{cycle}}` プレースホルダ置換: `sed 's|{{cycle}}|<value>|g'`
- 空ファイル禁止補完: テンプレートに「問題なし」コメントが残っている場合、自動的に展開
- 書き込み: `_safe_transform` 相当（テンプレート読み込み → 一時ファイル → mv の安全パターン）

#### 責務外（明示）

- YAML スキーマ検証 / `q*_answer` ダウングレード判定 / Markdown 内 YAML 抽出は **コンポーネント E** が担当
- mirror モード固有の下書き生成 / 承認フロー / Issue 起票は Unit 005

### コンポーネント E: `skills/aidlc/scripts/retrospective-validate.sh`（新規 / 3 段責務分割）

#### 目的

retrospective.md の YAML フロントマター検証 + skill_caused ダウングレードを 3 段サブコマンド（extract / validate / apply）で実装。各段独立テスト可能で障害切り分けが容易な設計。

#### サブコマンド

```text
retrospective-validate.sh extract <path>
  入力: path（retrospective.md のパス）
  出力: extracted\t<problem_index>\t<key>=<value> + summary\textracted_keys\t<N>
  責務: Markdown コードブロック内の YAML を抽出し、TSV 中間表現として stdout 出力

retrospective-validate.sh validate <path>
  入力: path
  出力: extract 出力 + downgrade\t<problem_index>\t<question>:<reason> + summary\tcounts\ttotal=<N>;downgraded=<M>;skill_caused_true=<K>
  責務: extract → validate（6 キー存在 / quote_min_length / forbidden_words 検証）

retrospective-validate.sh validate <path> --apply
  入力: path（書き込み）
  出力: validate 出力 + applied\t<problem_index>\t<question>
  責務: extract → validate → apply（YAML 書き換え + backup + rollback）
  exit 0: 正常 / exit 2: fatal（rollback 完了時は error\tapply-failed\trollback-completed）
```

#### 実装方針

- **extract 段**: bash + awk で `## 問題 N` セクションを抽出、各セクション内の YAML コードブロックから 6 キーを TSV 出力
- **validate 段**: extract の結果をパイプで受け取り、`retrospective-schema.yml` を dasel で動的読み込み → quote_min_length（10）/ forbidden_words（4 種）/ 6 キー存在を機械的に検証
- **apply 段**: validate の downgrade 行をパイプで受け取り、**対応する problem の `q*_answer` を `yes` → `no` に書き換える**（6 キーのみが書き換え対象 / `skill_caused` は派生値のため永続化対象外）。dasel YAML 編集 + tmp + mv
- **トランザクション化**: `--apply` 時は backup（`.bak`）作成 → 書き換え → 失敗時は backup から復元 + `error\tapply-failed\trollback-completed` 出力

#### 検証ルールの動的読み込み

- ハードコード禁止: `quote_min_length` / `forbidden_words` / 6 キー / 質問文 は **`retrospective-schema.yml` から dasel で読み出す**
- スキーマ参照可能性は schema-contract.bats（観点 K）で回帰検証

### コンポーネント F: `skills/aidlc/config/defaults.toml`（変更）

#### 目的

`[rules.retrospective] feedback_mode = "silent"` セクションを既存 13 セクションに追加し、4 階層マージ仕様で user-global / project から上書き可能にする。

#### 変更内容

```toml
[rules.retrospective]
feedback_mode = "silent"
# 許容値: "silent"（自動生成 + ローカル記録のみ） / "mirror"（自動生成 + 下書き → 承認 → upstream Issue 起票）/ "disabled"（自動生成スキップ）
# mirror モードの実装は Unit 005 / 上限ガードは Unit 006 を参照
```

#### 静的検証

- feedback-mode-resolution.bats（観点 F）で defaults / user-global / project の各層からの読み出しと不正値ダウングレードを検証

### コンポーネント G: `skills/aidlc/steps/operations/04-completion.md`（変更）

#### 目的

retrospective サブステップを `## 3.5 retrospective 作成` として既存 `## 3 バックログ記録` と `## 4 次期サイクル計画` の間に挿入。マージ前完結契約に従う配置（5. PR マージ後の手順より前）。

#### 静的構造

- **既存番号保持**: `## 4 〜 ## 8` / `## 5.5` / `## 7` の番号は変更せず、`## 3.5` を新設のみ
- **安定 ID コメントアンカー**: `<!-- guidance:id=unit004-retrospective-creation -->` を `## 3.5` 直前行に配置
- **本文構成**: Step 1（cycle-version-check）→ Step 2（generate 呼び出し）→ Step 3（出力プレフィックス分岐）→ Step 4（validate 呼び出し）の 4 ステップ

#### Step 3 の判定優先順位（複数行出力時 / 上から順に評価し最初にマッチした行で確定）

1. **最優先 / exit code != 0**: generate スクリプトの exit code が `2`（fatal）の場合、即座に停止（`error\t...` 行を表示してユーザに通知）
2. **次優先 / `error\t...` 行**: stderr に `error\t...` 行が存在し、かつ stdout に `retrospective\t...` 行が **1 件もない**場合、停止（fatal だが exit 0 で stdout は空のケース）
3. **続行判定 / `retrospective\tcreated\t<path>`**: stdout に `retrospective\tcreated\t<path>` 行が **1 行以上存在すれば**続行（`warn\t...` 行は無視 / 警告は表示するが分岐に使わない）
4. **スキップ判定 / `retrospective\tskip\t*`**: stdout に `retrospective\tskip\tdisabled` または `retrospective\tskip\talready-exists` 行が存在すればスキップ（次のサブステップへ進まず Step 3.5 終了）
5. **その他**: 上記いずれにも該当しない場合は警告を表示してスキップ（保守的フォールバック）

**判定対象の分離契約**:

- 機械判定対象: stdout の `retrospective\t` プレフィックス行のみ
- 補助情報（表示のみ / 分岐に使わない）: stderr の `warn\t...` / `error\t...` 行
- 障害伝播の優先順位: `exit code != 0` > `error 行のみ存在` > `retrospective 行` > フォールバック

#### 静的検証

- step-integration.bats（観点 IS）で `## 3.5` セクション存在 + 安定 ID + cycle-version-check 呼び出し記述 + retrospective-generate.sh 呼び出し記述 + retrospective-validate.sh --apply 呼び出し記述 + Unit 005 引き継ぎ言及 + 既存番号保持 の 7 ケース検証

## インターフェース定義

### 入力インターフェース

| インターフェース | 入力源 | フォーマット |
|------------------|--------|-------------|
| `cycle-version-check.sh aidlc_is_cycle_v25_or_later <cycle>` | コマンドライン | `^v[0-9]+\.[0-9]+\.[0-9]+$` |
| `retrospective-generate.sh <cycle>` | コマンドライン | 上記同等 |
| `retrospective-validate.sh extract <path>` | コマンドライン | 既存ファイルパス |
| `retrospective-validate.sh validate <path>` | コマンドライン | 上記同等 |
| `retrospective-validate.sh validate <path> --apply` | コマンドライン | 上記同等 |
| `read-config.sh rules.retrospective.feedback_mode` | 4 階層マージ | TOML 値（silent / mirror / disabled / 不正値） |
| `retrospective-schema.yml` | dasel 動的読み込み | YAML |

### 出力インターフェース（厳密タブ区切り `<kind>\t<code>\t<payload>`）

| 出力 | 出力先 | 例 |
|------|--------|-----|
| 通常生成 | stdout | `retrospective\tcreated\t.aidlc/cycles/v2.5.0/operations/retrospective.md` |
| disabled スキップ | stdout | `retrospective\tskip\tdisabled` |
| already-exists スキップ | stdout | `retrospective\tskip\talready-exists` |
| 不正値ダウングレード警告 | stderr | `warn\tfeedback-mode-invalid\ton:downgrade-to-silent` |
| 致命エラー | stderr + exit 2 | `error\tretrospective-template-not-found\tskills/aidlc/templates/retrospective_template.md` |
| extract 中間表現 | stdout | `extracted\t1\tq1_answer=yes` |
| validate downgrade | stdout | `downgrade\t1\tq1_quote:length-below-10` |
| apply 書き換え | stdout | `applied\t1\tq1_quote` |
| summary | stdout 最終行 | `summary\tcounts\ttotal=3;downgraded=1;skill_caused_true=2` |

### 終了コード

- `0`: 正常終了（generate / validate ともに）
- `2`: fatal エラー
- `1`: **使用しない**（set -e 文脈での誤判定回避 / Unit 003 と同方針）

## エラーハンドリング戦略

### エラーカテゴリと対応

| カテゴリ | 例 | 対応 | 出力プレフィックス |
|---------|-----|------|------------------|
| 入力フォーマット違反 | cycle 値が `2.5.0`（v 抜き） | exit 2 + stderr | `error\tcycle-version-format\t<input>` |
| 必須ファイル不在 | retrospective_template.md 不在 | exit 2 + stderr | `error\tretrospective-template-not-found\t<path>` |
| スキーマ不在 | retrospective-schema.yml 不在 | exit 2 + stderr | `error\tschema-not-found\t<path>` |
| dasel 未インストール | dasel 不在 | exit 2 + stderr | `error\tdasel-not-installed\tinstall-required` |
| feedback_mode 不正値 | `feedback_mode = "on"` | warn + 通常生成へ（silent ダウングレード） | `warn\tfeedback-mode-invalid\t<value>:downgrade-to-silent` |
| skill_caused 違反値 | q1_answer=yes + q1_quote 5 文字 | downgrade（**q1_answer を yes → no に書き換え** / skill_caused は派生値のため書き換え対象外） | `downgrade\t<index>\tq1_quote:length-below-10` |
| apply 書き込み失敗 | retrospective.md write 不可 | rollback + exit 2 | `error\tapply-failed\trollback-completed` |

### NFR 観点との対応

| NFR | 該当エラー | 検証方法 |
|-----|-----------|---------|
| 空ファイル禁止 | 問題項目 0 件 | generate-script.bats（観点 GE）で「問題なし」自動補完を検証 |
| markdownlint パス | テンプレート lint 警告 | `markdownlint-cli2` を CI で実行 |
| トリガー精度 | v2.5.0 未満で誤生成 | cycle-version-check.bats（観点 V）の異常系 + 7 ケースで実機検証 |
| 単一ソース原則 | テンプレート文言と検証ルールの分離 | schema-contract.bats（観点 K2）で文言一致を回帰検証 |

## テスト戦略

### テスト分類と観点

| テストファイル | 観点 | ケース数 | カバレッジ目的 |
|--------------|------|---------|--------------|
| template-structure.bats | T（テンプレート構造） | 3 | 必須セクション 3 件 + skill 起因判定 6 キー + markdownlint パス |
| cycle-version-check.bats | V（バージョン判定） | 11 | v2.5.0 以降 4 種 + 未満 3 種 + フォーマット違反 4 種 |
| feedback-mode-resolution.bats | F（モード解決） | 4 | defaults / user-global / project / 不正値 |
| schema-contract.bats | K（スキーマ参照） + K2（文言一致） | 2 | validate スクリプトのスキーマ参照 + テンプレート文言一致 |
| generate-script.bats | GE（生成） | 4 | 通常生成 / disabled / already-exists / 不正値ダウングレード |
| validate-script.bats | EX / VA / AP / RB | 8 | 抽出 1 + 検証 4 + 適用 2 + ロールバック 1 |
| step-integration.bats | IS（ステップ統合） | 7 | ## 3.5 セクション + 安定 ID + 各種呼び出し記述 + Unit 005 引き継ぎ + 既存番号保持 |
| **合計** | - | **39** | - |

### Fixture 設計

| Fixture | 用途 |
|---------|------|
| empty-cycle | 問題項目 0 件 → 「問題なし」自動補完検証（観点 GE） |
| single-problem-no-cause | q*_answer 全 no → skill_caused=false（派生値計算 / 観点 VA） |
| single-problem-yes-valid-quote | q1_answer=yes + 10 文字以上正常 quote → skill_caused=true（派生値計算 / 観点 VA） |
| single-problem-yes-empty-quote | q1_answer=yes + 空 quote → downgrade（観点 VA） |
| single-problem-yes-short-quote | q1_answer=yes + 5 文字 quote → downgrade（観点 VA） |
| single-problem-yes-forbidden-word | q1_answer=yes + `該当` 単独 → downgrade（観点 VA） |
| multiple-problems | 3 問題項目 + 各種パターン → 6 キー × 3 = 18 行 + summary（観点 EX） |

## CI 接続

### `.github/workflows/migration-tests.yml` 拡張

#### PATHS_REGEX 追加

- `tests/retrospective/.*\.bats`
- `skills/aidlc/scripts/retrospective-.*\.sh`
- `skills/aidlc/scripts/lib/cycle-version-check\.sh`
- `skills/aidlc/config/retrospective-schema\.yml`
- `skills/aidlc/templates/retrospective_template\.md`

#### 実行コマンド追加

- `bats tests/retrospective/`

### 統合テストカバレッジ目標

- 既存 119 件 + 新規 39 件 = **158 件**（150+ 件想定 +α）
- ローカル `bats tests/migration/ tests/config-defaults/ tests/aidlc-setup/ tests/aidlc-migrate-prefs/ tests/retrospective/` で全件 PASS を確認

## 後方互換性 / 既存テストへの影響

### 影響範囲（明示）

- 既存 4 階層マージテスト（`tests/config-defaults/`）: 影響なし（`[rules.retrospective]` セクションは新規追加のみで既存セクション値に影響なし）
- 既存 migration テスト（`tests/migration/`）: 影響なし（aidlc-migrate / aidlc-setup は変更しない）
- 既存 aidlc-setup テスト（`tests/aidlc-setup/`）: 影響なし（Unit 002 の guidance は変更しない）
- 既存 aidlc-migrate-prefs テスト（`tests/aidlc-migrate-prefs/`）: 影響なし（Unit 003 のスクリプトは変更しない）

### 04-completion.md への影響

- **既存番号 4 / 5 / 5.5 / 6 / 7 / 8 は変更せず**、`## 3.5` を新設のみ
- step-integration.bats（観点 IS）で既存番号の保持を回帰検証

## ドキュメント差分

### 新規ファイル（10 件）

- `skills/aidlc/templates/retrospective_template.md`
- `skills/aidlc/config/retrospective-schema.yml`
- `skills/aidlc/scripts/lib/cycle-version-check.sh`
- `skills/aidlc/scripts/retrospective-generate.sh`
- `skills/aidlc/scripts/retrospective-validate.sh`
- `tests/retrospective/helpers/setup.bash`
- `tests/retrospective/template-structure.bats`
- `tests/retrospective/cycle-version-check.bats`
- `tests/retrospective/feedback-mode-resolution.bats`
- `tests/retrospective/schema-contract.bats`
- `tests/retrospective/generate-script.bats`
- `tests/retrospective/validate-script.bats`
- `tests/retrospective/step-integration.bats`
- `tests/fixtures/retrospective/*`（7 fixtures）

### 変更ファイル（3 件）

- `skills/aidlc/config/defaults.toml`（`[rules.retrospective]` 追加）
- `skills/aidlc/steps/operations/04-completion.md`（`## 3.5` 追加）
- `.github/workflows/migration-tests.yml`（PATHS_REGEX + 実行コマンド拡張）

## Unit 005 / Unit 006 への引き継ぎ点（明示）

### Unit 005（mirror モードの /aidlc-feedback 連動）

- **参照点**: `retrospective-schema.yml` の `valid_feedback_modes` / `stable_id` をパース
- **トリガー**: `RetrospectiveDocument.has_skill_caused_problems() == true` の場合
- **インターフェース**: `cycle` + 生成済み retrospective.md パス（疎結合）

### Unit 006（重複検出 + 上限ガード）

- **参照点**: `retrospective-schema.yml` の `quote_min_length` / `quote_forbidden_words` / 6 キーをパース
- **トリガー**: 同一サイクル内 retrospective に複数 `skill_caused=true` 項目存在時
- **インターフェース**: 生成済み retrospective.md の YAML フロントマターをパースして類似度判定

両者ともテンプレート文言には依存せず、`retrospective-schema.yml` を単一ソースとして参照する。
