# ドメインモデル: レビューサマリファイル生成

## 概要

AIレビュー実施時にレビューサマリファイルを生成・蓄積する仕組みの構造と責務を定義する。対象はMarkdownドキュメントであり、コード実装は含まない。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### ReviewSummaryFile（レビューサマリファイル）

レビュー実施結果を蓄積するMarkdownファイル。セット単位で追記される。

- **ID**: ファイルパス（保存先ルールで一意に決定）
- **属性**:
  - filePath: String - 保存先パス（フェーズとUnit/ステップから決定）
  - reviewSets: ReviewSet[] - レビューセットの追記一覧（時系列順）
- **振る舞い**:
  - appendSet(reviewSet): 新しいレビューセットを末尾に追記する
  - create(initialSet): テンプレートからファイルを新規作成し、初回セットを記録する

### ReviewSet（レビューセット）

1回のAIレビュー反復サイクル（最大3回）の結果をまとめた単位。

- **ID**: セット番号（ファイル内で連番、例: Set 1, Set 2）
- **属性**:
  - reviewTypes: String[] - 実行したレビュー種別（例: code, security）
  - toolName: String - 使用ツール（例: codex, self-review(subagent)）
  - iterationCount: Integer - 反復回数（1〜3）
  - findings: Finding[] - 指摘一覧
  - conclusion: String - 結論（「指摘0件」/「指摘対応判断完了」）
- **振る舞い**:
  - なし（記録のみ、振る舞いを持たない）

## 値オブジェクト（Value Object）

### Finding（指摘）

個別のレビュー指摘とその対応結果。

- **属性**:
  - index: Integer - セット内連番（#1, #2, ...）
  - severity: Enum(高/中/低) - 重要度
  - content: String - 指摘内容の要約
  - response: FindingResponse - 対応結果
- **不変性**: 一度記録された指摘は変更しない（セットは追記のみ）
- **等価性**: セット番号 + index の組み合わせで一意

### FindingResponse（指摘対応結果）

各指摘への対応を記録する値。

- **属性**:
  - status: Enum(修正済み/TECHNICAL_BLOCKER/OUT_OF_SCOPE) - 対応状態
    - 修正済み: 指摘に対して修正を実施
    - TECHNICAL_BLOCKER: 技術的理由で対応不可（先送り）
    - OUT_OF_SCOPE: スコープ外として次サイクルで対応（先送り）
  - reason: String? - 先送りの場合の理由（修正済みの場合はnull）
- **不変性**: 記録時に確定し変更しない

## 集約（Aggregate）

### ReviewSummaryAggregate

- **集約ルート**: ReviewSummaryFile
- **含まれる要素**: ReviewSet, Finding, FindingResponse
- **境界**: 1つのUnit（Construction）またはステップ（Inception）に対するレビュー結果全体
- **不変条件**:
  - セット番号は連番で一意
  - 各セット内のFindingのindexは連番で一意
  - セットは時系列順に追記される（挿入・編集不可）

## ドメインサービス

### ReviewSummaryWriter

- **責務**: レビューセット完了時にサマリファイルを生成・追記する
- **操作**:
  - writeSet(context, reviewSet): コンテキスト（フェーズ、サイクル、Unit/ステップ）とレビュー結果からサマリファイルを更新
    - ファイルが存在しない場合: テンプレートから新規作成
    - ファイルが存在する場合: 末尾にセットを追記

## ファイルパス決定ルール

### 対象外コンテキスト

以下の呼び出し元コンテキストではサマリファイルを生成しない:
- **計画承認前**: Construction Phaseの計画レビューは設計前段階であり、サマリ蓄積の対象外

### Construction Phase

- パス: `docs/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md`
- NNN: Unit番号（3桁ゼロパディング）
- 例: `docs/cycles/v1.17.0/construction/units/004-review-summary.md`
- 対象コンテキスト: Phase 1 ステップ3（設計レビュー）、Phase 2 ステップ4（コード生成後）、Phase 2 ステップ6（統合とレビュー）

### Inception Phase

- パス: `docs/cycles/{{CYCLE}}/inception/{step-name}-review-summary.md`
- step-name: 成果物のステップ名
- マッピング:
  - Intent承認前 → `intent-review-summary.md`
  - ユーザーストーリー承認前 → `user-stories-review-summary.md`
  - Unit定義承認前 → `unit-definition-review-summary.md`

## 更新契約

- **書き込み方式**: 追記のみ（既存セットの上書き・編集は禁止）
- **追記タイミング**:
  1. 全種別で指摘0件に到達した時点
  2. 指摘対応判断フロー完了後、ユーザーレビューへ進む場合（全て先送り）
- **セット間の独立性**: 各セットは独立。同一指摘が再検出された場合も新セットの新指摘として記録する
- **生成条件**: AIレビュー（外部ツールまたはセルフレビュー）が実施された場合のみ生成。レビュー未実施時はファイルを作成しない

## ユビキタス言語

- **レビューサマリファイル**: AIレビュー結果を蓄積するMarkdownファイル
- **レビューセット**: 1回のAIレビュー反復サイクルの結果単位
- **指摘（Finding）**: AIレビューで検出された個別の問題点
- **先送り**: 技術的理由またはスコープ外として修正しない判断
- **追記**: ファイル末尾に新しいセットを追加する操作（上書きではない）

## 不明点と質問（設計中に記録）

（なし - Unit定義と技術的考慮事項で要件が明確）
