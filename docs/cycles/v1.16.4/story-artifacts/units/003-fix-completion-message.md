# Unit: サイクル完了メッセージ修正

## 概要
operations.md のサイクル完了メッセージで「start setup」を「start inception」に修正する。

## 含まれるユーザーストーリー
- ストーリー 4: サイクル完了メッセージの修正 (#229)

## 責務
- operations.md（通常版・Lite版）の完了メッセージ内の「start setup」を「start inception」に置換

## 境界
- operations.md の他の内容変更は含まない
- AGENTS.md のフェーズ簡略指示テーブルの変更は含まない（「start setup」はInceptionへのリダイレクトとして定義済みのため）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `prompts/package/prompts/operations.md` の2箇所を修正
- `prompts/package/prompts/lite/operations.md` の1箇所を修正
- `docs/aidlc/` への反映はOperations Phase時のrsyncで行われる

## 実装優先度
Low

## 見積もり
極小（テキスト置換3箇所）

## 関連Issue
- #229

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
