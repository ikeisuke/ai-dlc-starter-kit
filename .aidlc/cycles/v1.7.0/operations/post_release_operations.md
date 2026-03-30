# リリース後の運用計画

## リリース情報
- **バージョン**: v1.7.0
- **リリース予定日**: 2026-01-11
- **リリース内容**: AI-DLCスターターキット v1.7.0

## v1.7.0の主な変更点

| Unit | 概要 |
|------|------|
| 001 | バックアップステップ削除 |
| 002 | AIエージェント許可リストガイド |
| 003 | バックログIssueテンプレート |
| 004 | setup-promptパス記録機能 |
| 005 | Issue駆動バックログフロー |
| 006 | jj基本ワークフローガイド |

## バックログ整理結果

### 対応済み（v1.7.0で完了）
| 項目 | 対応Unit/内容 |
|------|--------------|
| feature-setup-prompt-path-recording | Unit 004 |
| feature-jj-experimental-support | Unit 006 |
| feature-unit-branch-disable-setting | aidlc.toml設定追加 |

### 未対応（次サイクル以降）
| 項目 | 優先度 | 備考 |
|------|--------|------|
| chore-ai-review-iteration | 中 | AIレビュー反復プロセス明文化 |
| chore-reduce-compound-commands | 低 | 複合コマンド削減 |
| chore-sandbox-environment-guide | 中 | サンドボックス環境ガイド |
| chore-unit-branch-setting-integration | 低 | construction.md統合 |
| deferred-home-directory-user-settings | 中 | ユーザー共通設定 |
| deferred-unit-5-issue-driven-integration | 中 | Issue駆動統合 |
| feature-ai-agent-allowlist-recommendations | 中 | 許可リスト推奨機能 |
| feature-github-projects-integration | 低 | GitHub Projects連携 |
| feature-ios-version-inception-phase | 中 | iOSバージョン更新タイミング |

## 運用確認項目（リリース後）

- [ ] タグv1.7.0が正しく作成されている
- [ ] GitHub上でリリースが確認できる
- [ ] 新規クローンでのセットアップが成功する
- [ ] AIエージェント許可リストガイドが参照できる
- [ ] jjガイドが参照できる

## 次期バージョンの方向性

優先度の高いバックログ項目から検討：
1. AIレビュー反復プロセスの明文化
2. サンドボックス環境ガイドの作成
3. ユーザー共通設定の検討
4. Issue駆動統合の設計

## 備考

このプロジェクトはドキュメント・テンプレートプロジェクトのため、稼働率・パフォーマンスメトリクス等は不要。
