# Unit 003 計画: Construction Phaseバックログチェック改善

## 概要

Construction Phaseのステップ8（バックログ確認）を、全バックログ一覧表示からUnit関連Issueの詳細確認に変更する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/steps/construction/01-setup.md` | ステップ8のバックログ確認ロジック変更 |
| `prompts/package/prompts/construction.md` | 同等の変更 |
| `docs/aidlc/prompts/construction.md` | sync-package.shで自動反映 |

## 実装計画

ステップ8を以下に変更:
1. Unit定義ファイルの「関連Issue」セクションからIssue番号を抽出
2. 各Issueの詳細を`gh issue view`で確認
3. バックログIssueも確認（`gh issue list --label backlog`でUnit関連のものをフィルタ）

## 完了条件チェックリスト

- [ ] construction/01-setup.mdのステップ8プロンプト変更
- [ ] Unit定義ファイルの「関連Issue」セクションからIssue番号を抽出する方式への変更
- [ ] 正常系・異常系のエラーハンドリング記述
- [ ] prompts/package/正本ファイル同等変更
