---
name: reviewing-architecture
description: Reviews architecture for structural issues including layer separation, design patterns, API design, and dependency management. Use when performing architecture reviews, checking system design, or when the user mentions architecture review, design review, or structural analysis.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Architecture

アーキテクチャ・設計に特化したレビューを実行するスキル。

## レビュー観点

以下の観点でアーキテクチャをレビューする。

### 構造（Structure）

- レイヤー間の責務が明確に分離されているか
- モジュール/パッケージの凝集度は適切か
- コンポーネント間のインターフェースが明確に定義されているか
- ビジネスロジックがプレゼンテーション層やインフラ層に漏れ出していないか

### パターン（Patterns）

- 採用されたデザインパターンが問題に対して適切か
- アンチパターン（God Class、Spaghetti Code等）が含まれていないか
- パターンの過剰適用（Over-engineering）がないか
- プロジェクト内でパターンの適用が一貫しているか

### API設計（API Design）

- エンドポイント/インターフェースの命名が一貫しているか
- 入出力の型定義が明確か
- エラーハンドリングの方針が統一されているか
- バージョニング・後方互換性が考慮されているか

### 依存関係（Dependencies）

- 依存方向が適切か（上位レイヤーが下位に依存しない等）
- 循環依存が存在しないか
- コンポーネント間の境界（コンテキスト境界）が明確に定義されているか
- 障害の伝播が適切に分離されているか（障害分離）

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
