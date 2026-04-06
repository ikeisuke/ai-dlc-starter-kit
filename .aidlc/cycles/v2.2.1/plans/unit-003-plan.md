# Unit 003: compaction二重ロード解消 - 実装計画

## 背景

SKILL.mdステップ3に「コンパクション復帰の場合は compaction.md を読み込む」というロード指示がある。SKILL.mdは常時ロードされるため、通常起動時にもこの指示が常にコンテキストに存在する。compaction.md(6,528B)自体は条件付きでしかロードされないが、ロード指示の位置をsession-continuity.mdに移すことで、責務の所在を明確にする。

## 変更内容

1. **SKILL.md ステップ3**: 「コンパクション復帰の場合は `steps/common/compaction.md` を読み込む。」の行を削除
2. **session-continuity.md**: コンパクション復帰時のcompaction.mdロード指示を追加（新セクション「コンパクション復帰」）

## 変更しないもの（境界）

- compaction.md本文: 一切変更しない
- session-continuity.md内の既存ロジック: session-state.mdの生成・復元フローは変更しない

## 完了条件チェックリスト

- [ ] SKILL.mdステップ3からcompaction.mdのロード指示が削除されている
- [ ] session-continuity.mdにコンパクション復帰時のcompaction.mdロード指示が追加されている
- [ ] compaction.md本文が変更されていない（diff確認）
- [ ] session-continuity.mdの既存セクション（session-state.mdの生成・復元）が変更されていない
