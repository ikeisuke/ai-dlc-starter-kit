# Unit: compaction二重ロード解消

## 概要
compaction.mdの二重ロード（SKILL.mdとsession-continuity.md経由）を解消し、ロード指示を1箇所に統一する。

## 含まれるユーザーストーリー
- ストーリー 3: compaction二重ロード解消

## 責務
- SKILL.mdからcompaction.mdへのロード指示を削除
- session-continuity.mdのコンパクション復帰判定時にのみcompaction.mdをロードする形に統一
- 通常起動時にcompaction.mdがロードされないことを保証

## 境界
- compaction.md本文は一切変更しない
- session-continuity.md内のcompaction復帰判定ロジック自体は変更しない

## 依存関係

### 依存する Unit
- Unit 001: ベースライン計測（依存理由: 変更前のサイズを記録しておく必要がある）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 通常起動時にcompaction.md(6,528B)分のコンテキスト消費を削減
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: compaction復帰フローが劣化しないこと

## 技術的考慮事項
- compaction.mdのautomation_mode復元手順は品質劣化リスクマトリクスで「変更禁止」
- `diff` でcompaction.md本文が変更なしであることを検証

## 関連Issue
- #519

## 実装優先度
High

## 見積もり
小

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-07
- **完了日**: 2026-04-07
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
