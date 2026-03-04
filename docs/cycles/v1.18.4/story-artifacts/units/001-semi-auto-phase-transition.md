# Unit: セミオートモードPhase遷移改善

## 概要
Operations Phase開始時の「全Unit完了確認」ステップにセミオートゲート判定を追加し、Construction→Operations遷移時の不要な停止を解消する。

## 含まれるユーザーストーリー
- ストーリー 1: セミオートモードでのPhase遷移改善（#267）

## 関連Issue
- #267

## 責務
- operations.mdの「6. 全Unit完了確認」セクションへのセミオートゲート判定追加
- 全Unit完了済み時のauto_approved処理
- 未完了Unit/判定不能時のfallback処理
- 履歴記録フォーマットの定義

## 境界
- Construction Phase側のフロー変更は行わない
- Operations Phaseの他のステップ（ステップ0以降）は変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし（プロンプト修正のみ）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- セミオートゲート仕様（common/rules.md）に準拠した実装
- 承認ポイントID: `operations.startup.unit_verification`
- 修正対象: `prompts/package/prompts/operations.md`

## 実装優先度
High

## 見積もり
小（プロンプトファイル1箇所の修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
