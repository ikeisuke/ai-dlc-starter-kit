# 実装記録: Unit 005 - Issue駆動バックログフロー

## 概要
バックログとGitHub Issueの連携フローを定義し、Issue駆動でのバックログ管理をAI-DLCに統合した。

## 実装日
2026-01-11

## 成果物

### 新規作成
| ファイル | 説明 |
|----------|------|
| `prompts/package/guides/issue-driven-backlog.md` | Issue駆動バックログ管理ガイド |
| `docs/cycles/v1.7.0/design-artifacts/domain-models/unit005_domain_model.md` | ドメインモデル設計 |
| `docs/cycles/v1.7.0/design-artifacts/logical-designs/unit005_logical_design.md` | 論理設計 |
| `docs/cycles/v1.7.0/plans/unit005_issue_driven_backlog_flow.md` | 実行計画 |

### 更新
| ファイル | 変更内容 |
|----------|----------|
| `prompts/setup-prompt.md` | `[backlog]`セクション追加（テンプレート・マイグレーション） |
| `docs/cycles/v1.7.0/story-artifacts/units/005-issue-driven-backlog-flow.md` | 実装状態を「完了」に更新 |

### バックログ追加
| ファイル | 説明 |
|----------|------|
| `docs/cycles/backlog/feature-github-projects-integration.md` | GitHub Projects連携（将来検討） |
| `docs/cycles/backlog/feature-unit-branch-disable-setting.md` | Unitブランチ無効化設定 |

## 機能概要

### バックログ管理モード
- `git`: ローカルファイルに保存（従来方式、デフォルト）
- `issue`: GitHub Issueに保存

### ラベル構成
- **作成時**: `backlog`, `type:*`, `priority:*`
- **対応開始時**: + `cycle:vX.X.X`
- **完了時**: Issueをclose
- **無効化時**: `gh issue close --reason "not planned"`

### フロー
1. 新規バックログ作成
2. バックログ完了（Issueクローズ or ファイル移動）
3. バックログ無効化（対応しない）
4. バックログ参照（両方確認）

## テスト結果
- ガイドドキュメントの整合性: OK
- テンプレート・マイグレーションの整合性: OK
- MCP AIレビュー: 指摘3件修正済み

## 備考
- GitHub CLI未認証時はGit駆動にフォールバック
- 参照時はIssue・ファイル両方を確認する設計
