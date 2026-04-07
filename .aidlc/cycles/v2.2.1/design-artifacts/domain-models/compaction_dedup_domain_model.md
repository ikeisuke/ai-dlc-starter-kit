# ドメインモデル: compaction二重ロード解消

## 概要
compaction.mdのロード指示をSKILL.mdからsession-continuity.mdに移動し、ロード責務を1箇所に統一する。

## エンティティ

### SKILL.md（変更対象）
- **変更内容**: ステップ3からcompaction.mdのロード指示行を削除

### session-continuity.md（変更対象）
- **変更内容**: コンパクション復帰時のcompaction.mdロード指示セクションを追加
- **制約**: 既存のsession-state.md生成・復元ロジックは変更しない

### compaction.md（変更禁止）
- **制約**: 本文一切変更禁止

## 不変条件
- コンパクション復帰フロー: session-continuity.md経由でcompaction.mdがロードされる
- 通常起動時: compaction.mdはロードされない
