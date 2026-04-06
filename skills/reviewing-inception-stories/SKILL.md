---
name: reviewing-inception-stories
description: Reviews user stories for INVEST compliance and acceptance criteria quality. Use when reviewing user stories before approval.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Inception Stories

ユーザーストーリー承認前のレビューを実行するスキル。

## レビュー観点

### ユーザーストーリー品質

- INVEST原則（Independent, Negotiable, Valuable, Estimable, Small, Testable）への準拠
- 受け入れ基準が具体的で検証可能か
- ユーザー視点で価値が明確か
- 正常系・異常系が網羅されているか
- ストーリー間の重複・矛盾がないか

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
