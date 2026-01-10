# Unit: Issue駆動バックログフロー

## 概要
バックログとGitHub Issueの連携フローを定義し、Issue駆動でのバックログ管理をAI-DLCに統合する。ローカルファイル管理との選択制を提供する。

## 含まれるユーザーストーリー
- ストーリー 2-2: Issue駆動バックログフロー定義

## 責務
- `prompts/package/guides/issue-driven-backlog.md` の作成
- バックログ管理方式の選択肢を提供（Issue駆動 / ローカルファイル / 併用）
- 新規バックログ作成時のIssue作成フロー定義
- バックログ対応完了時のIssueクローズフロー定義
- ローカル `docs/cycles/backlog/` との併用方法の説明
- サイクル・フェーズ管理へのIssue連携を将来検討事項として記載

## 境界
- サイクル・フェーズ管理のIssue連携実装は対象外
- Issue自動作成機能の実装は対象外

## 依存関係

### 依存する Unit
- Unit 003: バックログ用Issueテンプレート（依存理由: Issue駆動を選択した場合にテンプレートが必要）

### 外部依存
- GitHub CLI（Issue駆動を選択した場合、認証済みであること）
- GitHubリポジトリへの書き込み権限（Issue駆動を選択した場合）

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: GitHub CLI未認証時はローカルファイル管理にフォールバック可能

## 技術的考慮事項
- **バックログ管理方式の選択**: `docs/aidlc.toml` に設定項目を追加し、以下から選択可能にする
  - `issue`: GitHub Issue駆動（ローカルファイルは使わない）
  - `local`: ローカルファイル管理（従来方式）
  - `hybrid`: 両方を併用（デフォルト）
- 既存のプロンプトへのフック追加は将来検討
- ローカルファイル管理との併用を前提とした設計

## 参考ファイル
- `prompts/package/prompts/inception.md`（Inception Phase - バックログ確認処理を参考）
- `prompts/package/prompts/construction.md`（Construction Phase - 将来のフック追加候補）
- `prompts/package/prompts/operations.md`（Operations Phase - 将来のフック追加候補）
- `docs/aidlc.toml`（設定ファイル - 管理方式選択の設定追加対象）
- `docs/cycles/backlog/deferred-unit-5-issue-driven-integration.md`（バックログ）

## 実装優先度
Low

## 見積もり
中（フロードキュメント作成 + toml設定追加）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
