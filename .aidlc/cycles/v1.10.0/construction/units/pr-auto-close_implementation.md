# 実装記録: PRによるIssue自動Close機能

## 概要

Operations PhaseのPR作成時に `Closes #xx` を自動記載し、PRマージ時に対応Issueが自動でCloseされるようにした。

## 実装内容

### 変更ファイル

- `prompts/package/prompts/operations.md`

### 変更内容

1. **Issue番号取得ルールの追加**:
   - intent.md の「対象Issue」セクションから取得
   - なければ setup-context.md を確認
   - 見つからない場合は Closes セクションを省略

2. **PR本文テンプレートの更新**:
   - `## Closes` セクションを追加
   - 複数Issue対応（各行に `Closes #xx` 形式）

## テスト結果

- プロンプト修正のため、コードテストは対象外
- 構文エラーなし

## 完了状態

- **状態**: 完了
- **完了日**: 2026-01-27
