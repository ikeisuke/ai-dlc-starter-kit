# ドメインモデル: GitHub Actions permissions追加

## 概要
GitHub Actionsワークフローの権限モデル。最小権限原則に基づくpermissions定義の業務概念を整理する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### WorkflowPermission
- **属性**: scope: `contents`, access: `read`
- **不変性**: ワークフロー定義時に確定。本Unitでは固定値 `contents: read`
- **等価性**: scope + access の組み合わせで判定
- **制約**: 最小権限原則 - 対象ワークフローの全ジョブは読み取りのみ操作のため `read` で必要十分

## 設計判断

### WorkflowPermissionsPolicy
- **ポリシー**: 対象2ワークフロー（pr-check.yml, migration-tests.yml）にworkflow-levelで `contents: read` を付与する
- **根拠**: 全ジョブがcheckout + lint/check/test実行のみで書き込み操作なし
- **制約**: workflow-level定義のみ（DR-003決定事項。job-level個別定義は不要）
- **参考モデル**: `skill-reference-check.yml`（同一パターン）

## ユビキタス言語

- **最小権限原則**: 必要最小限の権限のみを付与するセキュリティ原則
- **workflow-level permissions**: ワークフロー全体に適用され、全ジョブに継承されるpermissions定義
- **code-scanningアラート**: GitHubのセキュリティ機能が検出したpermissions未定義の警告
