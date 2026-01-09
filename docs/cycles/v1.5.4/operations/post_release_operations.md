# リリース後運用計画

## バックログ整理結果

### 対応済み（v1.5.4）

| ファイル | 内容 | 対応Unit |
|----------|------|---------|
| bug-ai-review-not-triggered-when-required.md | AIレビュー必須設定の修正 | Unit 003 |
| bug-macos-grep-compatibility.md | macOS grep互換性修正 | Unit 002 |
| bug-unit-branch-pr-not-created.md | Unitブランチ PR作成修正 | Unit 004 |
| chore-backlog-migration-duplicate-handling.md | バックログ重複警告 | Unit 006 |
| chore-markdownlint-rules-enablement.md | markdownlintルール有効化 | Unit 007 |
| chore-starter-kit-self-upgrade-flow.md | アップグレードフロー改善 | Unit 005 |
| feature-agents-md-integration.md | AGENTS.md/CLAUDE.md統合 | Unit 001 |

**移動先**: `docs/cycles/backlog-completed/v1.5.4/`

### 未対応（次サイクルへ引き継ぎ）

| ファイル | 内容 | 優先度 |
|----------|------|--------|
| deferred-home-directory-user-settings.md | ホームディレクトリ設定 | 低 |
| deferred-unit-5-issue-driven-integration.md | Issue駆動統合 | 低 |
| feature-ask-user-question-for-qa.md | AskUserQuestion活用 | 中 |
| feature-commit-around-review.md | レビュー前後コミット | 中 |

## リリース後の運用

### 監視項目

- GitHub Issues: ユーザーからのバグ報告・フィードバック
- GitHub Discussions: 質問・相談

### 対応フロー

1. **バグ報告受付時**
   - Issue内容を確認
   - 再現可能か検証
   - 緊急度を判定（高: 次パッチ、中: 次マイナー、低: バックログ）

2. **機能要望受付時**
   - バックログに記録
   - 次サイクルのInceptionで検討

### 次サイクルへの申し送り

- 未対応バックログ4件を次サイクルで検討
- 特に `feature-ask-user-question-for-qa.md` は開発者体験向上に寄与する可能性あり
