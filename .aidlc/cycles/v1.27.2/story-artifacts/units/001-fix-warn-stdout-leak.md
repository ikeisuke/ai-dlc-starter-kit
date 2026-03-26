# Unit: warn メッセージ stdout 混入修正

## 概要
`aidlc-setup.sh` の `resolve_starter_kit_root` 関数で warn メッセージが stdout に出力されるバグを修正する。

## 含まれるユーザーストーリー
- ストーリー1: resolve_starter_kit_root の warn メッセージ修正

## 関連Issue
- #394
- #391

## 責務
- 226行目の `echo "warn:..."` を stderr にリダイレクト（`>&2` 追加）

## 境界
- warn メッセージ体系全体の見直しは対象外
- aidlc-setup.sh のその他の機能改善は対象外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 実装優先度
High

## 見積もり
極小（1行の修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-24
- **完了日**: 2026-03-24
- **担当**: AI
