# Unit 004 計画: GitHub Actions permissions追加

## 概要
pr-check.ymlとmigration-tests.ymlにワークフローレベルのpermissionsブロックを追加し、code-scanningアラートを解消する。

## 背景
code-scanning アラート #1, #3, #5, #6: permissions未定義のワークフローが最小権限原則に違反。

## 修正対象
- `.github/workflows/pr-check.yml`
- `.github/workflows/migration-tests.yml`

## 修正内容

### 1. pr-check.ymlにpermissionsブロック追加
- `on:` ブロックの後に `permissions:` ブロックを追加
- 3ジョブ（markdown-lint, bash-substitution-check, defaults-sync-check）は全て読み取りのみのため `contents: read` を設定
- 参考モデル: `skill-reference-check.yml`（同様に `contents: read`）

### 2. migration-tests.ymlにpermissionsブロック追加
- `on:` ブロックの後に `permissions:` ブロックを追加
- migration-testsジョブは読み取りのみのため `contents: read` を設定

## 設計方針
- **最小権限原則**: 必要最小限のpermissionsのみ付与
- **workflow-level定義**: job-level個別定義は不要（workflowレベルをjobが継承）
- **既存パターン踏襲**: `skill-reference-check.yml` の定義形式に合わせる

## 完了条件チェックリスト
- [ ] pr-check.ymlにworkflow-levelのpermissionsブロックが追加されている
- [ ] migration-tests.ymlにworkflow-levelのpermissionsブロックが追加されている
- [ ] 両ファイルとも `contents: read` が設定されている
- [ ] 既存ジョブのロジック・内容が変更されていない
- [ ] 既存のpermissions定義済みワークフロー（auto-tag.yml, skill-reference-check.yml）が変更されていない
