# ドメインモデル: レビュースキルのタイミングベース化

## 概要

レビュースキルを種別ベースからタイミングベースに再構成し、stage/focus分離モデルを導入する。

## エンティティ

### ReviewSkill

- **識別子**: スキル名（例: `reviewing-construction-code`）
- **属性**:
  - stage: タイミング（inception-intent, construction-code, operations-premerge等）
  - focusList: レビュー観点リスト（code, security, architecture, inception）
  - perspectives: タイミング固有のレビュー観点セクション
- **振る舞い**:
  - executeReview: 指定された対象に対してレビューを実行
  - tagFindings: 指摘にfocusメタデータを付与

### ReviewFinding

- **属性**:
  - focus: レビュー観点タグ（code/security/architecture/inception）
  - severity: 重要度（高/中/低）
  - content: 指摘内容
  - recommendation: 推奨修正

## 値オブジェクト

### ReviewResult

- **属性**:
  - status: approved / changes_requested
  - findings: ReviewFinding[]
  - focusTags: focus タグの集合

## ユビキタス言語

- **stage**: 実行タイミング。スキル名に反映
- **focus**: レビュー観点。指摘の分類に使用。review-flow.mdの分岐キー
- **approved**: レビュワーが指摘なしと判定した状態
- **changes_requested**: 修正が必要な指摘がある状態
