---
name: reviewing-inception-units
description: Reviews Unit definitions for appropriate decomposition, dependency clarity, and estimation quality. Use when reviewing Unit definitions before approval.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Inception Units

Unit定義承認前のレビューを実行するスキル。

## レビュー観点

### Unit定義品質

- Unit分割が適切か（独立性、凝集性）
- 依存関係が正しく定義されているか
- 見積もりが妥当か
- 実装順序に矛盾がないか
- 責務と境界が明確に定義されているか

### Intent-Unit整合性

- Intentの「含まれるもの」に対応するUnitが存在するか
- Unitの責務がIntentのスコープを逸脱していないか
- Intentの「除外されるもの」に該当する作業がUnitに含まれていないか
- 全Unitの責務の合計がIntentのスコープをカバーしているか（漏れがないか）

### 意思決定記録の充足性

- 意思決定記録ファイル（`decisions.md`）が存在するか（意思決定があった場合）
- 各記録に必須項目（背景、選択肢、決定、トレードオフと判断根拠）が含まれているか
- 選択肢のメリット・デメリットが記載されているか
- トレードオフ（得たもの・犠牲にしたもの）と判断根拠が具体的に記載されているか
- 意思決定記録がない場合でも、セッション中に記録対象となる意思決定が本当になかったか確認する（記録漏れの検出）

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
