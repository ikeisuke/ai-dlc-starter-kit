# Unit: setup_claude_permissions exit status修正

## 概要
`setup_claude_permissions` 関数が失敗時に非ゼロexit statusを返すように修正し、`aidlc-setup.sh` がエラーを検出できるようにする。

## 含まれるユーザーストーリー
- ストーリー 1: setup_claude_permissions失敗時のexit status伝播

## 責務
- `setup_claude_permissions` 関数の終了コードを `result` 変数に応じて適切に設定する
- `aidlc-setup.sh` 側で非ゼロ終了コードを検出しエラーメッセージを表示する

## 境界
- `setup_claude_permissions` 関数内部のロジック変更は行わない（exit statusの伝播のみ）
- 他のセットアップ関数のexit status修正は対象外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 影響なし
- **セキュリティ**: 影響なし
- **スケーラビリティ**: 影響なし
- **可用性**: 影響なし

## 技術的考慮事項
- `echo "result:${result}"` の後に `[[ "$result" == "failed" ]] && return 1` のようなreturn文を追加
- `aidlc-setup.sh` 側での呼び出し箇所の確認が必要

## 実装優先度
High

## 見積もり
小規模（数行の修正）

## 関連Issue
- #343

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
