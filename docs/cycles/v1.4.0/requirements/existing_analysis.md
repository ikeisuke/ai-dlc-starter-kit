# 既存コード分析

## 分析対象
バックログの低優先度タスク9件に関連する既存ファイル

## ファイル構成

### プロンプトファイル（編集対象: `prompts/package/prompts/`）
- `inception.md` - Inception Phase プロンプト
- `construction.md` - Construction Phase プロンプト
- `operations.md` - Operations Phase プロンプト
- `lite/` - Lite版プロンプト

### セットアップファイル（編集対象: `prompts/`）
- `setup-prompt.md` - セットアップ統合プロンプト
- `setup-init.md` - 初回セットアップ/アップグレード
- `setup-cycle.md` - サイクル開始セットアップ

## タスクとファイルの対応

| # | タスク | 対象ファイル | 概要 |
|---|--------|-------------|------|
| 1 | git worktree を活用したワークフローの提案 | `setup-cycle.md` | セットアップ時にworktree使用を提案 |
| 2 | history.mdの複数人開発時コンフリクト対策 | 全プロンプト、rules.md | 記録方式の見直しまたはルール追加 |
| 3 | サイクルバージョン提案ロジックの改善 | `setup-prompt.md`, `setup-cycle.md` | 既存サイクルからバージョン推測 |
| 4 | Operations Phaseでアプリバージョン更新確認 | `operations.md`, `operations.md`(運用引き継ぎ) | デプロイ準備で確認手順追加 |
| 5 | AI MCPレビュー活用の提案 | `inception.md`, `construction.md`, `operations.md` | 各フェーズでMCP検出・提案 |
| 6 | Operations Phase完了作業の構造改善 | `operations.md` | ステップ6としてリリース準備を独立 |
| 7 | 作業中の割り込み対応ルールの明確化 | `construction.md` | 割り込みフローをプロンプトに追加 |
| 8 | GitHub Issueチェック機能の追加 | `inception.md` | Dependabot PR確認の近くにIssue確認追加 |
| 9 | Inception Phaseにセットアップステップ統合 | `inception.md`, `setup-cycle.md` | ブランチ確認をInceptionに統合 |

## 依存関係の分析

### 独立して実装可能
- タスク1（git worktree）
- タスク2（history.mdコンフリクト対策）
- タスク3（サイクルバージョン提案）
- タスク4（アプリバージョン確認）
- タスク5（AI MCPレビュー）
- タスク6（Operations Phase構造改善）
- タスク7（割り込み対応ルール）
- タスク8（GitHub Issue確認）

### 依存関係あり
- タスク9（セットアップ統合）: タスク8完了後が望ましい（同じ「最初に必ず実行すること」セクションを編集するため）

## 推奨実装順序

1. タスク3: サイクルバージョン提案ロジックの改善
2. タスク8: GitHub Issueチェック機能の追加
3. タスク9: Inception Phaseにセットアップステップ統合（タスク8と関連）
4. タスク6: Operations Phase完了作業の構造改善
5. タスク4: Operations Phaseでアプリバージョン更新確認
6. タスク7: 作業中の割り込み対応ルールの明確化
7. タスク5: AI MCPレビュー活用の提案
8. タスク1: git worktree を活用したワークフローの提案
9. タスク2: history.mdの複数人開発時コンフリクト対策

## 注意事項

- **メタ開発**: `docs/aidlc/` は直接編集禁止、必ず `prompts/package/` を編集
- **後方互換性**: 既存のワークフローを壊さないこと
- **Operations Phase**: rsync でdocs/aidlc/へコピーされることを考慮
