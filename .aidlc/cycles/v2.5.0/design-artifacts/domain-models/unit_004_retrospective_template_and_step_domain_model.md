# ドメインモデル: Unit 004 retrospective テンプレートと Operations 自動生成

## 概要

Operations Phase 完了時に「なぜ間違えたか」のプロセス学習を残す retrospective フローを表現するドメインモデル。`templates/retrospective_template.md` を新規作成し、`steps/operations/04-completion.md` に retrospective サブステップを追加する。`feedback_mode ∈ {silent, mirror}` で自動実行 / `disabled` でスキップする条件分岐 + skill 起因判定（3 問自問）の YAML フロントマタースキーマ + 不正値ガード（10 文字未満 / 禁止語）を表現する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2（コード生成）で行う。

## エンティティ（Entity）

### RetrospectiveDocument

サイクルごとに 1 件生成される retrospective.md の文書全体を表すエンティティ。

- **ID**: `cycle`（CycleVersion 値オブジェクト）
- **属性**:
  - `cycle`: CycleVersion — 対象サイクルのバージョン文字列（`v2.5.0` 形式）
  - `path`: FilePath — `.aidlc/cycles/{{cycle}}/operations/retrospective.md`
  - `summary`: String — 「概要」セクション本文
  - `problems`: List<ProblemItem> — 問題項目のリスト（最低 1 件、または「問題なし」明示）
  - `handover_notes`: String — 「次サイクルへの引き継ぎ事項」本文（なしの場合は「なし」と明示）
- **不変条件**:
  - `cycle` は `^v[0-9]+\.[0-9]+\.[0-9]+$` フォーマット（CycleVersion の不変条件）
  - `cycle` は v2.5.0 以降（v2.5.0 未満なら自動生成しない / Unit 004 トリガーガード）
  - `problems` は最低 1 件、または「問題なし」明示の単一エントリを持つ（空ファイル禁止 NFR）
  - `path` は `.aidlc/cycles/{{cycle}}/operations/retrospective.md` 固定
- **振る舞い**:
  - `requires_problem_completion()`: Boolean — `problems.size() == 0` を返す（generate スクリプトで「問題なし」自動補完判定）
  - `has_skill_caused_problems()`: Boolean — `problems` のいずれかで `skill_caused == true` のものがあれば true（Unit 005 mirror モード連動の判定根拠）

### ProblemItem

retrospective に記録される個別の問題項目を表すエンティティ。複数記録可能。

- **ID**: `(cycle, problem_index)` の複合キー
- **属性**:
  - `problem_index`: Integer — 1 始まりの通し番号
  - `title`: String — 問題のタイトル
  - `what_happened`: String — 「何が起きたか」本文
  - `why_happened`: String — 「なぜ起きたか」本文
  - `loss_and_impact`: String — 「損失と影響」本文
  - `skill_caused_judgment`: SkillCausedJudgment — 3 問自問の判定結果
- **不変条件**:
  - `problem_index >= 1`
  - `title.length > 0`（空タイトル禁止）
  - `skill_caused_judgment` は 6 キー（q1_answer/q1_quote/q2_answer/q2_quote/q3_answer/q3_quote）を全て含む
- **振る舞い**:
  - `skill_caused()`: Boolean — `skill_caused_judgment.is_skill_caused()` を返す
  - `is_no_problem_marker()`: Boolean — タイトルが「問題なし」のテンプレート明示エントリかを判定（`problems.size() == 1 && title == "問題なし"`）

### SkillCausedJudgment

3 問自問による skill 起因判定の結果を表すエンティティ。ProblemItem ごとに 1 件。**`skill_caused` は永続化する契約値ではなく、6 キーから都度計算する派生値**として扱う（後述「派生値原則」を参照）。

- **ID**: `(cycle, problem_index)`（ProblemItem に従属）
- **永続化属性（YAML フロントマターに書き込まれる契約 6 キー）**:
  - `q1_answer`: AnswerValue — `Yes` / `No`
  - `q1_quote`: String — q1_answer=Yes の場合の引用箇所（empty の場合は「""」）
  - `q2_answer`: AnswerValue
  - `q2_quote`: String
  - `q3_answer`: AnswerValue
  - `q3_quote`: String
- **派生値（読み取り専用 / 永続化しない）**:
  - `skill_caused`: Boolean — `is_skill_caused()` の戻り値。**YAML フロントマターに書き出さない**。`summary` 行で集計通知のみ
- **不変条件**:
  - `q*_answer ∈ {Yes, No}`（YAML enum の `yes` / `no` リテラルに対応）
  - `q*_answer == Yes` の場合、対応する `q*_quote` は以下を満たす:
    - `length(q*_quote) >= 10`（quote_min_length）
    - `q*_quote` が「該当」/「あり」/「該当箇所」/「あります」のいずれか単独 + 10 文字以下ではない（forbidden_words）
  - 上記不変条件に違反する場合、apply 段は `q*_answer` を `no` に書き換えてダウングレード（**6 キーのみ書き換え対象 / `skill_caused` は派生値のため書き換えない**）
- **振る舞い**:
  - `is_skill_caused()`: Boolean — `(q1_answer == Yes && quote_valid(q1_quote)) || (q2_answer == Yes && quote_valid(q2_quote)) || (q3_answer == Yes && quote_valid(q3_quote))` を返す（派生値計算）
  - `quote_valid(quote: String)`: Boolean — `length >= 10` かつ禁止語単独でない場合 true
  - `validate()`: ValidationResult — 違反項目を `DowngradeRecord` のリストとして返す（validate スクリプトで使用）

#### 派生値原則（重要）

- `skill_caused` は YAML フロントマターに書き出さない（テンプレート / 生成時 / apply 時すべて 6 キーのみ）
- ダウングレード時の書き換え対象は **`q*_answer: yes → no`**（quote 違反時の判定不能を表現）
- `summary` 行で `skill_caused_true_count` を集計通知（Unit 005 / Unit 006 はこの行を参照）
- スキーマ（`retrospective-schema.yml`）の `keys` は 6 キーのみ（`skill_caused` は含めない）

## 値オブジェクト（Value Object）

### CycleVersion

サイクルバージョン文字列を表す不変値オブジェクト。

- **属性**:
  - `value`: String — `^v[0-9]+\.[0-9]+\.[0-9]+$` 形式の文字列
- **不変条件**:
  - フォーマット違反は構築時 reject（cycle-version-check 側で exit 2）
  - `value.length > 0`
- **振る舞い**:
  - `is_v25_or_later()`: Boolean — major/minor/patch を bash 数値比較で評価し v2.5.0 以降なら true
  - `compare(other: CycleVersion)`: Integer — semver 比較（-1 / 0 / 1）

### FeedbackMode

retrospective フローの動作モードを表す列挙型。

- **値**:
  - `Silent` — 自動生成 + ローカル記録のみ（デフォルト）
  - `Mirror` — 自動生成 + 下書き → 承認 → upstream Issue 起票（Unit 005 で実装）
  - `Disabled` — 自動生成スキップ
- **不変条件**:
  - 不正値（上記 3 値以外）は `Silent` に強制ダウングレード + 警告ログ
- **振る舞い**:
  - `should_generate()`: Boolean — `Disabled` 以外で true
  - `should_mirror()`: Boolean — `Mirror` で true（Unit 005 連動）
  - `from_string(s: String)`: FeedbackMode — 文字列からの安全な構築（不正値は Silent + warn）

### AnswerValue

3 問自問の回答を表す列挙型。

- **値**: `Yes` / `No`
- **不変条件**: YAML リテラル `yes` / `no` のみ受け付ける（`true` / `false` / `Y` / `N` 等は不正値）
- **振る舞い**: 文字列 `"yes"` / `"no"` への変換（YAML 出力用）

### OutputLine

retrospective-generate.sh / retrospective-validate.sh の出力 1 行を表す不変値オブジェクト。タブ区切り単一形式。

- **属性**:
  - `kind`: OutputKind — `Retrospective` / `Warn` / `Error` / `Downgrade` / `Extracted` / `Applied` / `Summary`
  - `code`: String — 状態コード（`created` / `skip` / `feedback-mode-invalid` / `apply-failed` 等）
  - `payload`: List<String> — タブ区切り後続フィールド（path / problem_index / question / value 等）
  - `stream`: OutputStream — 出力チャネル（`Stdout` / `Stderr`）
- **不変条件**:
  - `kind` ごとに必須 payload 数が決まる（`retrospective\tcreated` → 1 / `retrospective\tskip` → 1 / `warn\t<code>` → 1 / `error\t<code>` → 1 / `downgrade\t...` → 3 / `extracted\t...` → 3 / `applied\t...` → 2 / `summary\t...` → 任意）
  - 値中にタブ・改行を含まない
  - **チャネル割り当て契約**: `Retrospective` / `Extracted` / `Downgrade` / `Applied` / `Summary` → `Stdout`、`Warn` / `Error` → `Stderr`（Step は **stdout のみ機械判定対象**、stderr は補助情報として表示）
- **振る舞い**:
  - `to_tsv()`: String — `<kind>\t<code>\t<payload_joined>` フォーマット出力
  - `is_continue_signal()`: Boolean — `kind == Retrospective && code == created` で true（Step 3 続行判定）
  - `is_skip_signal()`: Boolean — `kind == Retrospective && code == skip` で true

### OutputStream

出力ストリームを表す列挙型。

- **値**: `Stdout`（機械判定対象 / 主要ステータス + 中間表現）/ `Stderr`（補助情報 / 警告 + 致命エラー）
- **契約**: Step は stdout の `retrospective\t` プレフィックス行のみで分岐判定する。stderr は表示するのみで分岐に使わない

### OutputKind

タブ区切り出力の `<kind>` フィールドを表す列挙型。

- **値**: `Retrospective` / `Warn` / `Error` / `Downgrade` / `Extracted` / `Applied` / `Summary`
- **意味論**:
  - `Retrospective` — 主要ステータス通知（created / skip）。Step が分岐判定に使う
  - `Warn` — 処理継続可能な警告（feedback-mode-invalid / 値ダウングレード等 / exit 0）
  - `Error` — 致命エラー（exit 2）
  - `Downgrade` — validate スクリプトの違反項目記録
  - `Extracted` — extract サブコマンドの中間表現出力
  - `Applied` — --apply サブコマンドの書き換え記録
  - `Summary` — 集計行（最終行）

### ConfigSchema

retrospective-schema.yml が定義する機械可読契約スキーマを表す不変値オブジェクト。

- **属性**:
  - `version`: Integer — スキーマバージョン（本 Unit では 1）
  - `required_sections`: List<String> — テンプレートに必須のセクション見出し
  - `skill_caused_keys`: List<String> — `[q1_answer, q1_quote, q2_answer, q2_quote, q3_answer, q3_quote]`
  - `questions`: Map<String, String> — `q1` / `q2` / `q3` の質問文（テンプレートのコメント文と一致を保証）
  - `answer_enum`: List<String> — `["yes", "no"]`
  - `quote_min_length`: Integer — `10`
  - `quote_forbidden_words`: List<String> — `["該当", "あり", "該当箇所", "あります"]`
  - `valid_feedback_modes`: List<String> — `["silent", "mirror", "disabled"]`
  - `default_feedback_mode`: String — `"silent"`
  - `stable_id`: String — `"unit004-retrospective-creation"`
- **責務**:
  - validate スクリプトはこのスキーマを `dasel` で動的に読み込み、ハードコードしない
  - Unit 005 / Unit 006 はテンプレート文言ではなくこのスキーマを参照する（単一ソース原則）
  - schema-contract.bats の観点 K / K2 で参照可能性 + テンプレート文言一致を回帰検証

## ドメインサービス（Domain Service）

### CycleVersionGuard

`{{cycle}}` が v2.5.0 以降かを判定するドメインサービス。

- **責務**:
  - 入力フォーマット `^v[0-9]+\.[0-9]+\.[0-9]+$` の厳格検証（違反時は exit 2 + stderr）
  - bash 内蔵の major/minor/patch 数値比較で v2.5.0 以降かを判定
  - 環境差分（GNU/BSD `sort` 差異）の影響を排除
- **実装契約**: `skills/aidlc/scripts/lib/cycle-version-check.sh::aidlc_is_cycle_v25_or_later <cycle>`
  - exit 0: v2.5.0 以降
  - exit 1: v2.5.0 未満
  - exit 2: フォーマット違反 or 引数不足

### RetrospectiveGenerator

retrospective.md の生成 + feedback_mode 解決 + 空ファイル禁止補完を担うドメインサービス。

- **責務**:
  - `read-config.sh rules.retrospective.feedback_mode` で値を解決し、`FeedbackMode` 値オブジェクトに変換
  - `FeedbackMode` に応じて 4 分岐（disabled スキップ / already-exists スキップ / 不正値 silent ダウングレード警告 / 通常生成）
  - テンプレート（`templates/retrospective_template.md`）を読み込み、`{{cycle}}` プレースホルダを置換して `RetrospectiveDocument` を生成
  - `RetrospectiveDocument.requires_problem_completion()` の場合、「問題なし」明示エントリを自動補完
  - 全ての出力は `OutputLine` の `<kind>\t<code>\t<payload>` フォーマットで出力（チャネル割り当ては OutputLine の不変条件に従う / Retrospective / Extracted / Downgrade / Applied / Summary は stdout、Warn / Error は stderr）
- **責務外（明示）**: YAML スキーマ検証 / `q*_answer` ダウングレード判定 / Markdown 内 YAML 抽出は **RetrospectiveValidator** が担当
- **実装契約**: `skills/aidlc/scripts/retrospective-generate.sh <cycle>`

### RetrospectiveValidator

retrospective.md の YAML フロントマター検証 + `skill_caused` ダウングレードを担うドメインサービス（3 段責務に内部分割）。

- **責務（3 段サブコマンド構成）**:
  1. **extract**: Markdown コードブロック内の YAML を抽出し、中間表現として TSV を stdout に出力
  2. **validate**: extract の結果を input にして 6 キー存在 / `q*_answer == Yes` 時の quote 検証 / 禁止語チェック → 違反項目を `Downgrade` 出力
  3. **apply**: validate の Downgrade 行を input にして retrospective.md の YAML を書き換え（backup + rollback でトランザクション化）
- **検証ルール参照**: `ConfigSchema`（retrospective-schema.yml）から動的に読み込む（quote_min_length / forbidden_words / 6 キー）
- **実装契約**: `skills/aidlc/scripts/retrospective-validate.sh extract|validate <path> [--apply]`

### MirrorModeHandover

`feedback_mode == Mirror` の場合の Unit 005 への引き継ぎ点を表す概念サービス。本 Unit ではフロー記述のみ（実装非対象）。

- **責務**:
  - `RetrospectiveDocument.has_skill_caused_problems() == true` の場合に Unit 005 で導入される下書き生成フローへ引き継ぐ
  - 引き継ぎインターフェースは `cycle` + 生成済み retrospective.md パスのみ（疎結合）
- **実装非対象**: 本 Unit ではドメインモデルとして概念定義のみ。実装は Unit 005

## 集約（Aggregate）

### RetrospectiveAggregate

単一サイクルの retrospective フロー全体を凝集する集約。生成・検証・ダウングレードの整合性境界。

- **集約ルート**: `RetrospectiveDocument`（cycle をキーとする）
- **メンバー**:
  - `RetrospectiveDocument`（1 件）
  - `ProblemItem`（0〜N 件 / 「問題なし」明示時は擬似エントリ 1 件）
  - `SkillCausedJudgment`（ProblemItem と 1:1）
  - `OutputLine`（実行ごとの一時的なメッセージ列）
- **不変条件**:
  - `RetrospectiveDocument.cycle` は `CycleVersion.is_v25_or_later() == true`
  - `ProblemItem` の `problem_index` は 1 始まりの連番
  - `SkillCausedJudgment` は対応する `ProblemItem` を持つ
  - 違反値検出時の `skill_caused` ダウングレードは `RetrospectiveValidator.apply` のみが書き換え（`RetrospectiveGenerator` は触れない）
- **集約境界外との関係**:
  - Unit 001 の defaults.toml への `[rules.retrospective]` セクション追加（read-only 参照 + 値変更時に 4 階層マージ仕様で上書き）
  - Unit 002 の SetupGuidanceAggregate との関係: 直接の依存なし（separate concerns）
  - Unit 005 / Unit 006 への引き継ぎ: `ConfigSchema`（retrospective-schema.yml）を単一ソースとして参照（テンプレート文言ではなく）

## リポジトリインターフェース

本 Unit の I/O は以下のファイルシステムが対象。永続化リポジトリは TOML / YAML / Markdown ファイルそのもので代替する。**実装非対象**として概念のみ記載する。

### RetrospectiveRepository（概念）

- **責務**: `.aidlc/cycles/{{cycle}}/operations/retrospective.md` の読み書き
- **インターフェース**:
  - `exists(cycle: CycleVersion)`: Boolean
  - `read(cycle: CycleVersion)`: RetrospectiveDocument
  - `write(cycle: CycleVersion, doc: RetrospectiveDocument)`: void（_safe_transform で書き込み + backup + rollback）

### ConfigSchemaRepository（概念）

- **責務**: `skills/aidlc/config/retrospective-schema.yml` の読み込み
- **インターフェース**:
  - `load()`: ConfigSchema（dasel ベースの YAML パース）

### TemplateRepository（概念）

- **責務**: `skills/aidlc/templates/retrospective_template.md` の読み込み
- **インターフェース**:
  - `load()`: String（テンプレート本文）

## ドメインルール（Business Rules）

### Rule 1: トリガーガード

- v2.5.0 未満のサイクルでは retrospective を**生成しない**（既存サイクルへの遡及生成防止）
- 入力フォーマット違反は exit 2 で停止（環境依存性排除）

### Rule 2: feedback_mode 三値ガード

- `silent` / `mirror` / `disabled` 以外は `silent` に強制ダウングレード + 警告ログ
- `disabled` の場合はテンプレート生成自体をスキップ
- `mirror` の場合は本 Unit ではローカル記録 + フロー言及のみ（具体実装は Unit 005）

### Rule 3: 空ファイル禁止

- 自動生成された retrospective.md は最低 1 件の問題項目または「問題なし」明示を含む
- 0 件の場合は generate スクリプトで「問題なし」エントリを自動補完

### Rule 4: skill 起因判定の 3 問自問

- `q1_answer` / `q2_answer` / `q3_answer` のいずれか 1 つ以上が `yes` で対応する `q*_quote` が valid → `skill_caused = true`
- 全て `no` → `skill_caused = false`（retrospective ローカル記録のみ）

### Rule 5: skill 起因判定の不正値ダウングレード

- `q*_answer == yes` のキーに対応する `q*_quote` が以下のいずれかなら **`skill_caused = false` に強制ダウングレード**:
  - 空文字列
  - 10 文字未満（`quote_min_length`）
  - 禁止語単独 + 10 文字以下（`quote_forbidden_words`: 該当 / あり / 該当箇所 / あります）

### Rule 6: マージ前完結契約との整合

- retrospective.md の書き込みは Operations Phase の **5. PR マージ後の手順より前**で完結
- マージ後は `write-history.sh` の exit 3 ガード相当で拒否される（同契約に従う）

### Rule 7: 単一ソース契約（schema-driven）

- 検証ルール（quote_min_length / 禁止語 / 6 キー / 質問文 / 許容 feedback_mode 値）は `retrospective-schema.yml` に集約
- テンプレートのコメント文 / validate スクリプト / Unit 005 / Unit 006 は全てこのスキーマを参照
- テンプレート文言変更は schema-contract.bats（観点 K2）で検出可能（一字一句一致テスト）

## 用語集

| 用語 | 定義 |
|------|------|
| retrospective | サイクル振り返り文書（`.aidlc/cycles/{{cycle}}/operations/retrospective.md`） |
| skill 起因判定 | 問題が AI-DLC スキル定義の不備に起因するかを 3 問自問で判定するフレーム |
| feedback_mode | retrospective フローの動作モード（silent / mirror / disabled） |
| 空ファイル禁止 | retrospective.md に最低 1 件の問題項目（または「問題なし」明示）を要求する NFR |
| 単一ソース原則 | テンプレート / 検証 / 下流 Unit が同一の契約スキーマファイルを参照する設計原則 |
| マージ前完結契約 | PR マージ後の `.aidlc/cycles/{{cycle}}/**` 配下の改変を禁止する契約（v2.3.5 / Unit 002） |
