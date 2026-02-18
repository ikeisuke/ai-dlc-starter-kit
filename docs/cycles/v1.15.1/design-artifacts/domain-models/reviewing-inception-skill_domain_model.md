# ドメインモデル: AIDLC専用レビュースキル

## 概要

Inception Phase成果物（Intent、ユーザーストーリー、Unit定義）に特化したAIレビュースキルの構造と責務を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### ReviewingInceptionSkill

- **ID**: `reviewing-inception`（スキル名）
- **属性**:
  - name: String - スキル識別名
  - description: String - スキルの説明（英語、トリガーフレーズ含む）
  - argument-hint: String - 引数のヒント
  - compatibility: String - 動作要件
  - allowed-tools: String - 許可ツール定義
- **振る舞い**:
  - レビュー実行: Inception Phase成果物を受け取り、レビュー観点に基づいて品質チェックを実行

### ReviewPerspective

- **ID**: カテゴリ名（Intent品質、ユーザーストーリー品質、Unit定義品質）
- **属性**:
  - category: String - レビュー観点のカテゴリ名
  - checkItems: List[String] - チェック項目一覧
- **振る舞い**:
  - チェック項目評価: 成果物に対して各項目の充足状態を判定

## 値オブジェクト（Value Object）

### CallerContextMapping

- **属性**:
  - callerStep: String - 呼び出し元ステップ。inception.mdの記述に合わせた正規化キーを使用（「Intent承認前」「ユーザーストーリー承認前」「Unit定義承認前」）
  - defaultReviewType: String - デフォルトのレビュー種別（`inception`）
- **不変性**: 呼び出し元ステップとレビュー種別の対応は固定
- **等価性**: callerStep が同一であれば同値

### SkillInvocation

- **属性**:
  - skillName: String - `reviewing-inception`
  - args: String - レビュー対象と優先ツールヒント
- **不変性**: 呼び出し形式は既存スキルと同一パターン

## 集約（Aggregate）

### InceptionReviewAggregate

- **集約ルート**: ReviewingInceptionSkill
- **含まれる要素**: ReviewPerspective（3カテゴリ）、CallerContextMapping（3マッピング）
- **境界**: Inception Phase成果物のレビューに関する全ての定義を包含
- **不変条件**:
  - 全てのCallerContextMappingのdefaultReviewTypeは `inception` であること
  - ReviewPerspectiveの全カテゴリがinception.mdの「Inception固有のレビュー観点」を包含すること（拡張許容: inception.mdの項目をベースに、レビュー品質向上のための追加項目を含めてよい。既存reviewing-*スキルも同様に呼び出し元の観点をベースに独自の拡張項目を持つ）
  - スキル形式（frontmatter + セクション構成）が既存reviewing-*スキルと一致すること

## ドメインサービス

### ReviewFlowIntegrationService

- **責務**: reviewing-inceptionスキルをreview-flow.mdのフレームワークに統合する
- **操作**:
  - CallerContextテーブル更新: Inception Phase 3タイミングをテーブルに追加
  - レビュー種別テーブル更新: `inception` → `skill="reviewing-inception"` の行追加
  - 履歴テンプレート汎化: `--phase` を変数化してフェーズ非依存にする

### DocumentCatalogUpdateService

- **責務**: ドキュメントカタログ（ai-tools.md、skill-usage-guide.md）にスキル情報を追加
- **操作**:
  - ai-tools.md テーブル更新: Inceptionレビュー行追加
  - skill-usage-guide.md テーブル更新: Inceptionレビュー行追加

## レビュー観点の定義（コアドメイン知識）

### Intent品質

inception.md ステップ1「Intent明確化」承認前のレビュー観点:

- 目的・狙いが明確で妥当か
- スコープが明確に定義されているか（含まれるもの・除外されるもの）
- 曖昧な表現や解釈の余地がないか
- 期待する成果が具体的か
- 既存機能への影響が考慮されているか

### ユーザーストーリー品質

inception.md ステップ3「ユーザーストーリー作成」承認前のレビュー観点:

- INVEST原則（Independent, Negotiable, Valuable, Estimable, Small, Testable）への準拠
- 受け入れ基準が具体的で検証可能か
- ユーザー視点で価値が明確か
- 正常系・異常系が網羅されているか
- ストーリー間の重複・矛盾がないか

### Unit定義品質

inception.md ステップ4「Unit定義」承認前のレビュー観点:

- Unit分割が適切か（独立性、凝集性）
- 依存関係が正しく定義されているか
- 見積もりが妥当か
- 実装順序に矛盾がないか
- 責務と境界が明確に定義されているか

## ユビキタス言語

- **Inception Phase成果物**: Intent、ユーザーストーリー、Unit定義の総称
- **レビュー観点**: レビュー時にチェックすべき品質基準の一覧
- **CallerContext**: review-flow.mdにおける呼び出し元ステップとレビュー種別の対応
- **INVEST原則**: ユーザーストーリーの品質基準（Independent, Negotiable, Valuable, Estimable, Small, Testable）

## 不明点と質問（設計中に記録）

（現時点でなし - inception.mdに定義済みの観点を体系化する方針のため）
