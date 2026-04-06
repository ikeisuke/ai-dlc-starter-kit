---
name: reviewing-operations-deploy
description: Reviews deployment plans for completeness, rollback procedures, and monitoring setup. Use when reviewing deployment plans before approval in Operations Phase.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Operations Deploy

デプロイ計画承認前のレビューを実行するスキル。

## レビュー観点

### デプロイ計画

- デプロイ手順が明確に定義されているか
- ロールバック手順が用意されているか
- 環境設定（環境変数、設定ファイル等）が文書化されているか

### 監視・アラート

- 監視設定が適切か
- アラート条件が定義されているか
- ログ出力が十分か

### リスク管理

- デプロイに伴うリスクが洗い出されているか
- リスク緩和策が用意されているか
- 影響を受けるユーザー/サービスが特定されているか

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
