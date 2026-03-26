# Unit: Issue駆動バックログフロー

## 概要
バックログとGitHub Issueの連携フローを定義し、Issue駆動でのバックログ管理をAI-DLCに統合する。ローカルファイル管理との選択制を提供する。

## 含まれるユーザーストーリー
- ストーリー 2-2: Issue駆動バックログフロー定義

## 責務
- `prompts/package/guides/issue-driven-backlog.md` の作成
- バックログ保存先の選択肢を提供（`issue` / `git`）
- `docs/aidlc.toml` に `[backlog].mode` 設定項目を追加
- 新規バックログ作成時のIssue作成フロー定義
- バックログ対応完了時のIssueクローズフロー定義
- 参照時の両方確認（Issue + ローカルファイル）のフロー説明
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
- **バックログ管理方式の選択**: `docs/aidlc.toml` の `[backlog].mode` で「保存先」を選択
  - `issue`: GitHub Issueに保存
  - `git`: ローカルファイルに保存（従来方式、デフォルト）
- **参照は両方**: どちらのモードでも、参照時はGitHub IssueとローカルファイルをBoth確認する
- 既存のプロンプトへのフック追加は将来検討

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

- **状態**: 完了
- **開始日**: 2026-01-11
- **完了日**: 2026-01-11
- **担当**: AI
