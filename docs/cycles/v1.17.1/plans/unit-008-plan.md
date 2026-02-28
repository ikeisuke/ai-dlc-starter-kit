# Unit 008 計画: アップグレード処理スクリプト化

## 概要

setup-prompt.mdのセクション7.4（設定マイグレーション）・7.5（廃止設定移行）のbashスニペットをスクリプト化し、
セクション8.2（rsync同期）は既存の`sync-package.sh`呼び出しに置換する。

## 分析

### 現状
- セクション7.4: ~190行のインラインbash（aidlc.tomlのセクション追加・リネーム・キー追加）
- セクション7.5: ~40行のインラインbash（廃止設定のrules.mdへの移行）
- セクション8.2: 6つのrsync操作が各セクションで生のrsyncコマンドを使用
- `sync-package.sh`は既に存在し、`--source`/`--dest`/`--dry-run`/`--delete`オプションを持つ

### スクリプト化対象
1. **migrate-config.sh（新規）**: 7.4 + 7.5を統合
2. **setup-prompt.md更新**: 8.2.xを`sync-package.sh`呼び出しに置換

## 実装計画

### 1. migrate-config.sh 作成
- [x] スクリプト作成: `prompts/package/bin/migrate-config.sh`
- [x] 終了コード: 0（成功）、1（エラー）、2（ユーザー判断必要）
- [x] 出力形式: key:value形式（既存スクリプトの慣例に合わせる）
- [x] 処理内容:
  - `[rules.mcp_review]` → `[rules.reviewing]` リネーム移行
  - 不足セクション追加（reviewing, worktree, history, backlog, jj, linting, commit）
  - `[rules.reviewing]`へのtools追加
  - 廃止設定移行（inception.dependabot → rules.md）
  - オーバーライドファイルの旧キー警告

### 2. setup-prompt.md 更新
- [x] セクション7.4: インラインbashを`migrate-config.sh`呼び出しに置換
- [x] セクション7.5: インラインbashを`migrate-config.sh`呼び出しに置換（統合）
- [x] セクション8.2.1〜8.2.2.5: 各rsyncコマンドを`sync-package.sh`呼び出しに置換

### 3. レビュー
- [x] コードレビュー
- [x] セキュリティレビュー
