---
name: reviewing-inception
description: Reviews Inception Phase artifacts including Intent clarity, user story quality (INVEST), and Unit definition completeness. Use when reviewing inception artifacts, checking requirements quality, or when the user mentions inception review, requirements review, or unit definition review.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Inception

Inception Phase成果物に特化したレビューを実行するスキル。

## レビュー観点

以下の観点でInception Phase成果物をレビューする。

### Intent品質

- 目的・狙いが明確で妥当か
- スコープが明確に定義されているか（含まれるもの・除外されるもの）
- 曖昧な表現や解釈の余地がないか
- 期待する成果が具体的か
- 既存機能への影響が考慮されているか

### ユーザーストーリー品質

- INVEST原則（Independent, Negotiable, Valuable, Estimable, Small, Testable）への準拠
- 受け入れ基準が具体的で検証可能か
- ユーザー視点で価値が明確か
- 正常系・異常系が網羅されているか
- ストーリー間の重複・矛盾がないか

### Unit定義品質

- Unit分割が適切か（独立性、凝集性）
- 依存関係が正しく定義されているか
- 見積もりが妥当か
- 実装順序に矛盾がないか
- 責務と境界が明確に定義されているか

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
