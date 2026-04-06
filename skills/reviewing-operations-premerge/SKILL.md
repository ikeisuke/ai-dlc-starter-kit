---
name: reviewing-operations-premerge
description: Reviews pull requests for overall quality before merging. Combines code quality and security checks at PR level. Use when performing pre-merge review in Operations Phase.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Operations Premerge

PRマージ前の品質確認レビューを実行するスキル。

**focusメタデータ**: このスキルは `code` と `security` の2つのfocusを持つ。セキュリティ関連の指摘には `focus: security` を付与すること。

## レビュー観点

### PR品質（focus: code）

- PR全体の変更が一貫しているか
- コミットメッセージが適切か
- 不要な変更（デバッグコード、コメントアウト等）が含まれていないか
- ドキュメント更新が必要な変更にドキュメントが含まれているか

### セキュリティ最終チェック（focus: security）

- 機密情報（APIキー、トークン等）がコミットされていないか
- セキュリティに影響する変更にセキュリティレビューが実施されているか
- 依存パッケージの脆弱性チェックが実施されているか

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
