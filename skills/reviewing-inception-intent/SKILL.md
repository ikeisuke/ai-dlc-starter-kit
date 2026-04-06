---
name: reviewing-inception-intent
description: Reviews Intent artifacts for clarity, scope definition, and feasibility. Use when reviewing Intent documents before approval.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Inception Intent

Intent承認前のレビューを実行するスキル。

## レビュー観点

### Intent品質

- 目的・狙いが明確で妥当か
- スコープが明確に定義されているか（含まれるもの・除外されるもの）
- 曖昧な表現や解釈の余地がないか
- 期待する成果が具体的か
- 既存機能への影響が考慮されているか

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
