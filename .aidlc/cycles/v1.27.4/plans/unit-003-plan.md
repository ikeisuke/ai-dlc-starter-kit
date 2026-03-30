# Unit 003 計画: semi_autoゲートにレビュー実施済み前提条件を追加

## 概要
semi_autoモードのフォールバック条件テーブルに`review_not_executed`条件を最優先（優先度0）で追加し、AIレビュー未実施のまま自動承認されることを防止する。

## 変更対象ファイル
1. `prompts/package/prompts/common/rules.md` — フォールバック条件テーブル（L429〜）および構造化シグナルスキーマ（L438〜）

## 実装計画

### 1. フォールバック条件テーブルに`review_not_executed`を追加
- 優先度0（最優先）として新行を挿入
- 条件: 該当承認ポイントに対応するAIレビューフロー（review-flow.md）が未実施
- メッセージ方針: AIレビューが未実施である旨を通知し、レビュー実行を促す

### 2. 構造化シグナルスキーマの`reason_code`有効値に追加
- `review_not_executed`を有効な`reason_code`として認識されるようにする

## 完了条件チェックリスト
- [ ] フォールバック条件テーブルに`review_not_executed`が優先度0で追加されている
- [ ] 既存条件（error, review_issues, incomplete_conditions, decision_required）の優先度・動作が維持されている
- [ ] 構造化シグナルスキーマで`review_not_executed`が有効な`reason_code`として定義されている
- [ ] 判定基準が明確に記述されている
