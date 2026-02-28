# Unit: Operations PhaseのIssueクローズ確認改善

## 概要
Operations Phaseのステップ6.7でIssueクローズ確認を行う際に、PRのClosesセクションに含まれるIssueを自動クローズ対象として手動確認をスキップする。

## 含まれるユーザーストーリー
- ストーリー 7: Operations PhaseのIssueクローズ確認改善 (#242)

## 関連Issue
- #242

## 責務
- ステップ6.7のIssueクローズ確認フロー改善
- `gh pr view`でClosesに含まれるIssue番号を取得し、自動クローズ対象を判別
- 自動クローズ対象外のIssueのみ手動クローズ確認
- 全Issueが自動クローズ対象の場合のスキップ表示
- 異常系: `gh pr view`失敗時の従来フローへのフォールバック
- 異常系: Closesセクション不在時の全Issue手動確認

## 境界
- ステップ6.7以外のOperations Phase手順の変更は含まない
- pr-ops.shの機能追加は含まない（既存機能の活用のみ）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- gh CLI（PR情報の取得に使用）

## 非機能要件（NFR）
- なし

## 技術的考慮事項
- 既存の`pr-ops.sh get-related-issues`を活用可能
- 変更対象: prompts/package/docs/operations.md

## 実装優先度
Medium

## 見積もり
小規模（operations.mdのステップ6.7変更）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-28
- **完了日**: 2026-02-28
- **担当**: @ai
