# Unit: バックログ用Issueテンプレート

## 概要
GitHub Issuesを使ったバックログ管理を可能にするため、Issueテンプレートを整備する。

## 含まれるユーザーストーリー
- ストーリー 2-1: バックログ用Issueテンプレートの整備

## 責務
- `prompts/package/.github/ISSUE_TEMPLATE/` ディレクトリの作成
- バックログ用テンプレート（`backlog.md`）の作成
- バグ報告用テンプレート（`bug.md`）の作成
- 機能要望用テンプレート（`feature.md`）の作成
- スターターキットセットアップ時に `.github/` をプロジェクトルートへコピーする処理追加
- 既存の `.github/` がある場合の保護処理（上書き防止、マージまたはユーザー確認）

## 境界
- Issue作成の自動化は対象外
- サイクル・フェーズ管理のIssue連携は対象外（将来検討）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub（Issueテンプレート機能）

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: テンプレート作成・コピーはGitHub CLI非依存（Issue作成/連携はUnit 005でGitHub CLI依存）

## 技術的考慮事項
- テンプレートはスターターキットの `prompts/package/.github/ISSUE_TEMPLATE/` に配置
- セットアップ時にプロジェクトルートの `.github/ISSUE_TEMPLATE/` へ別途コピー（既存のrsyncとは別処理）
- **既存ファイルの保護**: プロジェクトに既存の `.github/` や `.github/ISSUE_TEMPLATE/` がある場合、上書きしないよう注意（マージまたはユーザー確認）

## 参考ファイル
- `prompts/setup-prompt.md`（スターターキットセットアップ - コピー処理追加対象）
- `prompts/package/prompts/inception.md`（Inception Phase - 既存のIssue確認処理を参考）
- `docs/cycles/backlog/deferred-unit-5-issue-driven-integration.md`（バックログ）

## 実装優先度
Medium

## 見積もり
中（テンプレート3種作成 + セットアッププロンプト修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
