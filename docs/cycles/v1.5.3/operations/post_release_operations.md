# リリース後の運用計画

## リリース情報
- **バージョン**: v1.5.3
- **リリース予定日**: 2026-01-03
- **リリース内容**: シェル互換性改善、後方互換性強化、AIレビュー機能強化、CI/CD構築、監視ガイド作成

## v1.5.3の主な変更点

### 機能追加・改善
| Unit | 内容 |
|------|------|
| 001 | シェル互換性の改善（zsh/bashでの動作保証） |
| 002 | 後方互換性の強化（v1.5.0以前のプロジェクト対応） |
| 003 | サイクル名自動検出機能 |
| 004 | アップグレードフローの改善 |
| 005 | worktree機能の改善 |
| 006 | AIレビュー機能の強化 |
| 007 | CI/CD構築（Markdownリンター） |
| 008 | 監視・分析ガイドの作成 |

### 対応したバックログ
- `feature-cicd-setup.md` - CI/CD構築
- `feature-monitoring-analysis.md` - 監視・分析
- `feature-ai-review-before-human-approval.md` - AIレビュー優先
- `bug-zsh-compatibility-setup-script.md` - zsh互換性
- `bug-v151-breaking-change-setup-cycle-removed.md` - 後方互換性
- `bug-setup-prompt-auto-cycle-start.md` - アップグレードフロー

## 運用状況（リリース後に更新）

### 利用状況（GitHub Insights）
- **Views**: （リリース後に確認）
- **Unique visitors**: （リリース後に確認）
- **Forks**: （リリース後に確認）

### インシデント
（リリース後に記録）

## 未対応バックログ（次サイクル候補）

| バックログ | 優先度 | 備考 |
|----------|--------|------|
| bug-ai-review-not-triggered-when-required.md | 高 | AIレビュー関連 |
| bug-unit-branch-pr-not-created.md | 中 | PR作成関連 |
| chore-backlog-migration-duplicate-handling.md | 低 | バックログ管理 |
| deferred-home-directory-user-settings.md | 低 | 延期済み |
| deferred-unit-5-issue-driven-integration.md | 低 | 延期済み |
| feature-agents-md-integration.md | 中 | 新機能 |
| feature-ask-user-question-for-qa.md | 中 | QA改善 |
| feature-commit-around-review.md | 中 | レビューフロー |

## 次期バージョンの計画

### 対象バージョン
v1.6.0（次回メジャー機能追加時）または v1.5.4（バグ修正のみ）

### 主要な改善候補
1. AIレビューが required でも発火しない問題の修正
2. Unit ブランチ PR 作成の改善
3. agents.md 統合機能

## 備考

- ドキュメントプロジェクトのため、稼働率・レスポンスタイム等のメトリクスは該当なし
- GitHub Insightsを活用した利用状況把握（`docs/monitoring.md` 参照）
