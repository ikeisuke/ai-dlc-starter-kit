---
name: reviewing-construction-integration
description: Reviews integration completeness including design-implementation consistency, review/test coverage, and completion criteria. Use when performing integration review in Construction Phase.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Construction Integration

統合レビューを実行するスキル。設計との乖離確認とレビュー/テスト実施状況を検証する。

## レビュー観点

### 設計乖離確認

- ドメインモデルで定義したエンティティが実装に存在するか
- 論理設計で定義したインターフェースが実装されているか
- 設計で定義した依存関係が実装で守られているか
- 実装中に設計変更があった場合、設計ドキュメントが更新されているか

### レビュー・テスト実施確認

- コードレビューが実施済みか（履歴記録を確認）
- テストが実施済みでパスしているか
- ビルドが成功しているか

### 完了条件チェック

- 計画ファイルの完了条件チェックリストの達成状況
- Unit定義の責務が全て実装されているか

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
