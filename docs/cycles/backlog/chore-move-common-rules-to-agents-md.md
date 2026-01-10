# rules.mdの汎用ルールをAGENTS.mdに移動

- **発見日**: 2026-01-09
- **発見フェーズ**: セットアップ
- **発見サイクル**: v1.5.4
- **優先度**: 中

## 概要

`docs/cycles/rules.md` にある汎用的なAI-DLCルールを `AGENTS.md` テンプレートに移動し、プロジェクト固有の内容のみを `rules.md` に残す。

## 詳細

現在 `rules.md` には以下の2種類の内容が混在している：

**AI-DLC共通ルール（AGENTS.mdへ移動すべき）:**
- 実行前の検証ルール（MCPレビュー、指示の妥当性検証）
- フェーズ固有のルール（Inception/Construction/Operations）
- 禁止事項（履歴削除禁止、承認なしの進行禁止、独自判断禁止等）

**プロジェクト固有（rules.mdに残す）:**
- メタ開発の意識（スターターキット固有）
- カスタムワークフロー（テンプレート）
- コーディング規約（テンプレート）
- ライブラリ制約（テンプレート）
- セキュリティ要件（テンプレート）
- パフォーマンス要件（テンプレート）

## 対応案

1. `prompts/package/templates/AGENTS.md.template` に共通ルールセクションを追加
2. `prompts/setup/templates/rules_template.md` からAI-DLC共通ルールを削除
3. テンプレート説明文を更新（AGENTS.md=共通、rules.md=固有）
