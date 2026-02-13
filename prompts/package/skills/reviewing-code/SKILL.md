---
name: reviewing-code
description: Reviews code for quality issues including readability, maintainability, performance, and test quality. Use when performing code reviews, checking code quality, or when the user mentions code review, code quality, or refactoring suggestions.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Code

コード品質に特化したレビューを実行するスキル。

## レビュー観点

以下の観点でコードをレビューする。

### 可読性

- 命名規則が一貫しているか（変数名、関数名、クラス名）
- 関数/メソッドが適切な長さか（単一責任）
- ネストが深すぎないか
- コメントが適切か（なぜを説明、何をは自明にする）
- コードの意図が読み手に明確か

### 保守性

- 単一責任原則を遵守しているか
- DRY原則に従っているか（重複コードがないか）
- 疎結合・高凝集か
- 将来の変更に対して拡張しやすいか
- 依存関係が明確で管理されているか

### パフォーマンス

- アルゴリズムの計算量は適切か
- 不要な再計算やループがないか
- メモリリークの可能性はないか
- I/O操作が効率的か
- N+1問題などのデータアクセスパターンの問題がないか

### テスト品質

- テストカバレッジが十分か
- 境界値テストが含まれているか
- テスト名が何をテストしているか明確か
- 各テストが独立しているか
- アサーションが適切で意味のあるエラーメッセージを含むか

## 実行コマンド

### Codex

```bash
codex exec -s read-only -C . "<レビュー指示>"
```

### Claude Code

```bash
claude -p --output-format stream-json "<レビュー指示>"
```

### Gemini

```bash
gemini -p "<レビュー指示>" --sandbox
```

## セッション継続

反復レビュー時は前回のセッションを継続する。

- **Codex**: `codex exec resume <session-id> "<指示>"`
- **Claude**: `claude --session-id <uuid> -p --output-format stream-json "<指示>"`
- **Gemini**: `gemini --resume <session_index> -p "<指示>"`

詳細は [references/session-management.md](references/session-management.md) を参照。
