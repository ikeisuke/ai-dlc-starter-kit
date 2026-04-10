# ドメインモデル: Unit 006 - 削減目標達成の計測レポートと #519 クローズ判断

## 概要

サイクル v2.3.0 の最終 Unit における計測ドメインのモデル。`bin/measure-initial-load.sh` を計測ロジックの正本とし、計測結果（`PhaseLoadMeasurement`）から達成判定（`ClosureDecision`）を導出し、Issue 操作と計測レポートを生成する責務を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2（コード生成ステップ）で行う。

## ドメインの位置づけ

本 Unit は計測・判定・記録という 3 段階の純粋関数的フローを持つ。副作用は最終段（Issue 操作・ファイル書き出し）に集約し、それまでは決定論的な値オブジェクトの導出に留める。

## エンティティ（Entity）

### `MeasurementSession`

本 Unit 全体の集約ルート。1 計測実行で v2.2.3 ベースラインと v2.3.0 現状の双方（合計 6 計測）を保持する。

- **ID**: 計測実行時の `BASELINE_REF` (commit hash) と計測時刻のペア（同一ブランチ上で時刻が異なる複数回実行を区別）
- **属性**:
  - `baseline_ref`: `CommitHash` - 比較元 ref の commit hash（不変条件: `56c6463747b41ab74108055a933cdfe29781fb43` と一致必須）
  - `target_ref`: `WorkingTree` - v2.3.0 計測対象（常に現在のワーキングツリー）
  - `tokenizer`: `TokenizerSpec` - 使用するトークナイザー（常に `cl100k_base`）
  - `baseline_measurements`: `PhaseLoadMeasurement[3]` - v2.2.3 ベースラインの 3 フェーズ計測（Inception / Construction / Operations 必須）
  - `current_measurements`: `PhaseLoadMeasurement[3]` - v2.3.0 現状の 3 フェーズ計測（同上）
  - `executed_at`: `DateTime` - 計測実行時刻
- **不変条件**:
  - `baseline_measurements` と `current_measurements` の各 `phase` 集合は完全一致
  - 合計 6 件の `PhaseLoadMeasurement` が必須
- **振る舞い**:
  - `validate_baseline()`: `BASELINE_REF` が `git rev-parse v2.2.3^{commit}` と一致するかを検証。不一致時は計測中止
  - `is_deterministic_with(other: MeasurementSession) → bool`: 同一 ref 上の 2 セッションが完全一致するかを判定（決定論性検証）
  - `pair_for(phase: PhaseName) → (PhaseLoadMeasurement, PhaseLoadMeasurement)`: 指定 phase の baseline/current ペアを取得

### `Issue519ClosureDecision`

- **ID**: 計測セッション ID + 評価時刻
- **属性**:
  - `stage1_result`: `Stage1MeasurementResult` - 段階 1（計測達成基準）の結果
  - `stage2_result`: `Stage2IntentCriteriaResult` - 段階 2（Intent 成功基準項目）の結果
  - `decision`: `ClosureAction` - 最終判定（`close` / `keep_open_with_backlog`）
  - `unmet_categories`: `UnmetCategory[]` - 未達カテゴリ（達成時は空配列）
- **振る舞い**:
  - `is_closeable() → bool`: 段階 1 と段階 2 の両方が達成済みかを判定（純粋関数）
  - `derive_unmet_categories() → UnmetCategory[]`: 段階 1/2 の未達項目から構造化バックログカテゴリを導出

## 値オブジェクト（Value Object）

### `PhaseLoadMeasurement`

- **属性**:
  - `phase`: `PhaseName` - `inception` / `construction` / `operations`
  - `variant`: `MeasurementVariant` - `v2_2_3_baseline` / `v2_3_0_current`
  - `file_tokens`: `FileTokenEntry[]` - ファイル別トークン数（順序保持）
  - `total`: `TokenCount` - 合計トークン数
- **不変性**: 同一 `phase` × `variant` × `tokenizer` × ファイル集合では常に同一値
- **等価性**: `phase` + `variant` + `total` + `file_tokens` のすべてが一致する場合に等価

### `Stage1MeasurementResult`

- **属性**:
  - `inception_total`: `TokenCount`
  - `construction_total`: `TokenCount`
  - `operations_total`: `TokenCount`
  - `inception_threshold`: `TokenCount` (= 15,000)
  - `construction_threshold`: `TokenCount` (= 17,980)
  - `operations_threshold`: `TokenCount` (= 17,209)
- **不変条件**: 各 phase の `total ≤ threshold` を満たすかどうかを `is_passed()` で純粋関数的に導出
- **等価性**: 6 値すべて一致

### `Stage2IntentCriteriaResult`

- **属性**:
  - `criteria_evaluations`: `IntentCriterionEvaluation[]` - Intent 成功基準項目ごとの評価
- **不変条件**: 全項目が `passed=true` の場合のみ `is_passed()=true`
- **等価性**: 全項目の評価結果リストが一致

### `IntentCriterionEvaluation`

- **属性**:
  - `criterion_id`: `string` - Intent 成功基準項目の識別子
  - `criterion_label`: `string` - Intent §成功基準の項目名
  - `expected_assertion`: `string` - その criterion で達成と見なす条件文（例: 「Inception 初回ロードが 15,000 tok 以下と verification 記録に明示されている」）。事前に固定する
  - `source_unit`: `UnitNumber[]` - 検証元 Unit 番号
  - `source_artifact_paths`: `Path[]` - 引用元の検証/実装記録パス（実在ファイルのみ。Unit 001 のみ `_implementation.md`、Unit 002-005 は `_verification.md`）
  - `quoted_text`: `string` - 引用元から引用した達成根拠の本文断片
  - `evidence_status`: `enum` - `satisfied` / `unsatisfied` / `not_found`（`expected_assertion` と `quoted_text` の整合性で導出）
  - `passed`: `bool` - `evidence_status == satisfied` のときのみ真
- **不変性**: `passed` は「引用が存在するか」ではなく「引用内容が `expected_assertion` を満たすか」で決定される。引用内容が失敗・未達を示す場合は `evidence_status=unsatisfied` となり、`passed=false`

### `UnmetCategory`

- **属性**:
  - `category_id`: `enum` - `tok-target-missed` / `behavior-regression` / `recovery-regression` / `tier2-incomplete` / `boilerplate-incomplete`
  - `summary`: `string` - 未達理由の要約
  - `related_unit`: `UnitNumber?` - 関連 Unit（任意）
  - `backlog_labels`: `string[]` - 付与する GitHub ラベル（`backlog,type:*,priority:*`）

### `StepFilesTokenComparison`（軸 1: ステップファイル群合計 tok 比較）

- **属性**:
  - `phase`: `PhaseName`
  - `v2_2_3_step_files_total_tok`: `TokenCount` - v2.2.3 のステップファイル群（`01-*.md` 〜 `04/05-*.md`）合計
  - `v2_3_0_step_files_total_tok`: `TokenCount` - v2.3.0 の同等ステップファイル群合計
  - `delta`: `int` - v2.3.0 - v2.2.3
  - `reduction_rate`: `float` - 削減率（負値が削減を表す）
- **不変性**: tok 数は同一 ref・同一 tokenizer で決定論的
- **判定**: `v2_3_0_step_files_total_tok ≤ v2_2_3_step_files_total_tok`

### `BoilerplateIndexAggregationCheck`（軸 2: index.md 集約証跡）

- **属性**:
  - `phase`: `PhaseName`
  - `pattern_name`: `BoilerplatePatternName` - 4 種類: `automation_mode` / `depth_level` / `review_flow_or_routing` / `express`
  - `applicable_to_phase`: `bool` - phase applicability（Operations × `express` のみ `false`）
  - `index_md_present`: `bool?` - applicability `true` の場合のみ意味を持つ（index.md にパターンが 1 件以上出現するか）
- **不変性**: applicability `false` のセルは `index_md_present=null` で N/A 表記
- **判定**: applicability `true` のセルすべてが `index_md_present=true`

> 旧 `BoilerplateComparisonCell` は本 2 軸構成に置き換えた。grep ベースの単純パターンカウントは「ロジック記述」と「`steps/{phase}/index.md` への参照記述」を区別できないため、計測は tok 数に統一する。

### `MeasurementReportSection`

派生成果物 `MeasurementReport` の章を構成する値オブジェクト（集約 `MeasurementSessionAggregate` には属さない）。

- **属性**:
  - `section_number`: `int` (1-9)
  - `title`: `string`
  - `content_kind`: `enum` - `script_output_transcribed` / `human_narrative` / `comparison_table`
- **不変性**: §3, §4 は常に `script_output_transcribed`（スクリプト出力のバイト単位転載）

### `CommitHash`

- **属性**: `value`: `string` (40 文字の十六進数)
- **不変性**: 一度設定したら変更不可
- **等価性**: 文字列比較

### `TokenCount`

- **属性**: `value`: `int` (≥ 0)
- **不変性**: 負値・非数値を許容しない
- **等価性**: 整数値の比較

## 集約（Aggregate）

### `MeasurementSessionAggregate`

- **集約ルート**: `MeasurementSession`
- **含まれる要素**:
  - 6 つの `PhaseLoadMeasurement`（baseline 3 件 + current 3 件、`MeasurementSession` の属性として保持）
  - 1 つの `Stage1MeasurementResult`
  - 1 つの `Stage2IntentCriteriaResult`
  - 1 つの `Issue519ClosureDecision`
  - 3 個（3 phases）の `StepFilesTokenComparison`（軸 1）
  - 12 個（3 phases × 4 patterns）の `BoilerplateIndexAggregationCheck`（軸 2）
- **派生成果物**: `MeasurementReport`（`MeasurementSessionAggregate` から導出されるドキュメント。集約には属さず、別レイヤで生成される）
- **境界**: 1 つの計測実行ごとに完結する。複数実行間で状態を共有しない
- **不変条件**:
  - `BASELINE_REF` の検証が成功している
  - 6 つの `PhaseLoadMeasurement` すべてが取得済み
  - 段階 1 と段階 2 の双方が評価済みの場合のみ `Issue519ClosureDecision` を生成可能
  - 派生する `MeasurementReport` の §3, §4 はスクリプト出力の文字列を改変せず転載

### `IssueOperationBatch`

- **集約ルート**: `Issue519ClosureDecision`
- **含まれる要素**:
  - クローズ判断コメント（必須、達成/未達ともに投稿）
  - 達成時: ラベル付与・削除・クローズの 3 操作
  - 未達時: 0 〜 5 個のバックログ Issue 作成
- **境界**: #519 のクローズ判断 1 回分の操作群
- **不変条件**:
  - `is_closeable()=true` のときのみクローズ操作を実行
  - 未達時は #519 をクローズしない
  - すべてのバックログ Issue は `#519` への参照を本文に含む

## ドメインサービス

### `MeasurementService`

- **責務**: `MeasurementSession` の生成と決定論性検証を担当
- **操作**:
  - `measure_phase(phase, variant, file_paths) → PhaseLoadMeasurement`: 1 フェーズ × 1 バリアントの計測を実行
  - `measure_all() → PhaseLoadMeasurement[6]`: 3 フェーズ × 2 バリアント = 6 計測を実行
  - `verify_determinism(session1, session2) → bool`: 2 セッションがバイト単位で完全一致するかを検証

### `ClosureDecisionService`

- **責務**: 計測結果と Intent 基準評価から `Issue519ClosureDecision` を導出
- **操作**:
  - `evaluate_stage1(measurements) → Stage1MeasurementResult`: 段階 1 評価
  - `evaluate_stage2(citations) → Stage2IntentCriteriaResult`: 段階 2 評価
  - `derive_decision(stage1, stage2) → Issue519ClosureDecision`: 2 段階を統合し最終判定を導出

### `BoilerplateAnalysisService`

- **責務**: 軸 1（ステップファイル群合計 tok 比較）と軸 2（index.md 集約証跡）の双方を生成
- **操作**:
  - `compare_step_files_tok(phase) → StepFilesTokenComparison`: 軸 1 の 1 行を生成（v2.2.3 と v2.3.0 のステップファイル群合計 tok を tiktoken で計測し差分算出）
  - `verify_index_aggregation(phase, pattern) → BoilerplateIndexAggregationCheck`: 軸 2 の 1 セルを生成。applicability `○` のときのみ `grep -l` で index.md にパターンが 1 件以上出現するかを確認

### `IssueOperationService`

- **責務**: `IssueOperationBatch` を実行する副作用境界
- **操作**:
  - `post_decision_comment(decision, body)`: クローズ判断コメント投稿
  - `apply_close_operations(decision)`: 達成時のラベル更新・クローズ
  - `create_backlog_issues(unmet_categories)`: 未達時のバックログ Issue 作成

## リポジトリインターフェース

ファイルシステムと git/gh CLI を抽象化した参照のみ存在する。新規スキーマは追加しない。

### `BaselineFileRepository`

- **対象集約**: `PhaseLoadMeasurement` (variant=`v2_2_3_baseline`)
- **操作**:
  - `read_at_ref(commit_hash, path) → string`: `git show <hash>:<path>` の薄いラッパー
  - `verify_ref_alias(alias, expected_hash) → bool`: `git rev-parse v2.2.3^{commit}` の結果と `BASELINE_REF` の一致確認

### `WorkingTreeFileRepository`

- **対象集約**: `PhaseLoadMeasurement` (variant=`v2_3_0_current`)
- **操作**:
  - `read(path) → string`: ファイル読み込み

### `GhIssueRepository`

- **対象集約**: `IssueOperationBatch`
- **操作**:
  - `view(issue_number) → IssueState`: `gh issue view --json state,labels` の結果取得
  - `comment(issue_number, body)`: コメント投稿
  - `edit_labels(issue_number, add[], remove[])`: ラベル操作
  - `close(issue_number, reason)`: クローズ
  - `create(title, body, labels[]) → IssueNumber`: 新規 Issue 作成

## ファクトリ（必要な場合のみ）

### `MeasurementSessionFactory`

- **生成対象**: `MeasurementSession`
- **生成ロジック概要**:
  1. `BASELINE_REF` 定数を読み込み
  2. `BaselineFileRepository.verify_ref_alias` で照合
  3. `MeasurementService.measure_all()` で 6 計測を実行
  4. 全計測結果を `MeasurementSession` に集約

## ユビキタス言語

このドメインで使用する共通用語:

- **初回ロード**: フェーズ開始時に必須となるファイル集合（SKILL.md + steps/common/{rules-core, preflight, session-continuity}.md + steps/{phase}/index.md）
- **ベースライン**: v2.2.3 時点のフェーズステップ全ロード方式での初回ロード
- **BASELINE_REF**: ベースラインの commit hash（`56c6463747b41ab74108055a933cdfe29781fb43`）
- **段階 1 / 段階 2**: #519 クローズ判断の 2 段階基準（計測達成 / Intent 成功基準項目）
- **phase applicability**: ある boilerplate パターンが特定フェーズで意味を持つかどうかの真偽値
- **正本**: `bin/measure-initial-load.sh` の出力。レポートはこれを転載するに過ぎない
- **構造化バックログ**: 未達カテゴリごとに作成される GitHub Issue 群（5 カテゴリ）

## 不変条件（ドメイン全体の整合性）

1. **計測値の決定論性**: 同一 `MeasurementSession` 入力（ref × tokenizer × ファイル集合）に対する出力は常に同一
2. **正本の単一性**: `PhaseLoadMeasurement` の値は常にスクリプト出力に従う。レポートは値を改変しない
3. **クローズの両段階必須**: `Issue519ClosureDecision.is_closeable()` は段階 1 ∧ 段階 2 が真の場合のみ真
4. **#519 への参照保持**: 未達時のバックログ Issue は必ず `#519` への参照を本文に含む

## 不明点と質問（設計中に記録）

設計中の不明点なし（事前計測で全目標達成済み・引用元ファイル実在確認済み・命名規約整理済み）。
