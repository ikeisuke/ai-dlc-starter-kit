---
name: reviewing-construction-plan
description: Reviews construction plans for architecture consistency and implementation feasibility. Use when reviewing implementation plans before approval.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Construction Plan

計画承認前のレビューを実行するスキル。

## レビュー観点

### 構造

- レイヤー間の責務が明確に分離されているか
- モジュール/パッケージの凝集度は適切か
- コンポーネント間のインターフェースが明確に定義されているか

### パターン

- 採用されたデザインパターンが問題に対して適切か
- アンチパターンが含まれていないか
- パターンの過剰適用がないか

### 依存関係

- 依存方向が適切か
- 循環依存が存在しないか
- 障害の伝播が適切に分離されているか

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
