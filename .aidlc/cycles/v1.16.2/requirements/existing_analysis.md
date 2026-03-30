# 既存コード分析

## 1. aidlc.toml の [backlog] セクション参照箇所

現在 `[backlog]` は `[rules]` 配下ではなくトップレベルに配置されている。

### 参照箇所一覧

| ファイル | 参照方法 | 参照キー |
|---------|--------|---------|
| `docs/aidlc/bin/check-backlog-mode.sh` | dasel直接読み取り | `backlog.mode` |
| `docs/aidlc/bin/env-info.sh` | dasel経由 | `backlog.mode` |
| `docs/aidlc/bin/init-cycle-dir.sh` | check-backlog-mode.sh呼び出し | 間接参照 |
| `prompts/package/prompts/inception.md` | check-backlog-mode.sh呼び出し | 間接参照 |
| `prompts/package/prompts/construction.md` | check-backlog-mode.sh呼び出し | 間接参照 |
| `prompts/package/prompts/operations.md` | check-backlog-mode.sh呼び出し | 間接参照 |

### 影響分析

- 直接 `backlog.mode` を読んでいるのは `check-backlog-mode.sh` と `env-info.sh` の2箇所のみ
- 他は全て `check-backlog-mode.sh` 経由のため、スクリプト修正で一括対応可能

## 2. read-config.sh の --default 使用箇所

### 現在の --default 指定一覧

| 呼び出し元 | キー | デフォルト値 |
|-----------|------|-----------|
| commit-flow.md | `rules.squash.enabled` | `"false"` |
| commit-flow.md | `rules.jj.enabled` | `"false"` |
| rules.md | `rules.jj.enabled` | `"false"` |
| feedback.md | `rules.feedback.enabled` | `"true"` |
| upgrading-aidlc/SKILL.md | `project.starter_kit_repo` | `"ghq:github.com/ikeisuke/ai-dlc-starter-kit"` |

### 集中管理への移行方針

- デフォルト値定義ファイル（例: `defaults.toml`）を作成し、read-config.shが自動参照
- 呼び出し側の `--default` 指定を段階的に不要にする
- 後方互換: `--default` が指定されていれば従来通り優先する

## 3. Operations Phase の手動手順（スクリプト化対象）

### バージョンファイル更新（#204）
- `version.txt` と `docs/aidlc.toml` の `starter_kit_version` を手動で更新
- `rules.md` に手順が記載されている

### rsync同期（#203）
- `prompts/package/` から `docs/aidlc/` へのrsync同期
- `/upgrading-aidlc` スキルが実行しているが、スタンドアロンスクリプトは未整備

### Issueテンプレート差分確認（#205）
- `.github/ISSUE_TEMPLATE/` のローカルとリモートの差分確認
- 現在は手動確認のみ

## 4. v1.16.1 フェーズスキル化の設計成果物

### 既存設計ドキュメント
- `docs/cycles/v1.16.1/design-artifacts/domain-models/skill-design_domain_model.md`
- `docs/cycles/v1.16.1/design-artifacts/logical-designs/skill-design_logical_design.md`

### スキル化候補（10スキル・優先度別）

| 優先度 | スキル名 | カテゴリ |
|-------|---------|---------|
| High | issue-management, backlog-management, pr-operations | 操作系 |
| Medium | version-management, setup-initialization, progress-tracking | フロー制御系 |
| Low | dialogue-planning, completion-validation, code-quality-check, unit-squash | ユーティリティ系 |

→ 今回のv1.16.2では、スキル化に加えてサブエージェント方式も含めた設計検討を行う

## 5. 既存binスクリプト一覧（24個）

`docs/aidlc/bin/` と `prompts/package/bin/` は同一内容（rsyncでコピー）。

| スクリプト | 責務 |
|-----------|------|
| check-backlog-mode.sh | バックログモード確認 |
| check-gh-status.sh | GitHub CLIステータス確認 |
| check-open-issues.sh | 未解決Issue確認 |
| cycle-label.sh | サイクルラベル操作 |
| env-info.sh | 依存ツール状態出力 |
| get-default-branch.sh | デフォルトブランチ取得 |
| init-cycle-dir.sh | サイクルディレクトリ初期化 |
| ios-build-check.sh | iOSビルド確認 |
| issue-ops.sh | Issue操作 |
| label-cycle-issues.sh | Issue一括ラベル付け |
| migrate-backlog.sh | バックログ形式マイグレーション |
| pr-ops.sh | PR操作 |
| read-config.sh | 設定値読み込み（3階層マージ） |
| run-markdownlint.sh | Markdownlint実行 |
| setup-ai-tools.sh | AIツール設定 |
| setup-branch.sh | ブランチセットアップ |
| squash-unit.sh | Unitコミットsquash |
| suggest-version.sh | バージョン提案 |
| validate-remote-sync.sh | リモート同期確認 |
| validate-uncommitted.sh | コミット未済ファイル確認 |
| write-history.sh | 履歴記録書き込み |
| aidlc-cycle-info.sh | サイクル情報取得 |
| aidlc-env-check.sh | 環境チェック |
| aidlc-git-info.sh | Git情報取得 |
