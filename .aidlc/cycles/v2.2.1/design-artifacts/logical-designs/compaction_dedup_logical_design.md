# 論理設計: compaction二重ロード解消

## 概要
SKILL.mdのステップ3からcompaction.mdロード指示を削除し、session-continuity.mdに統一する。

## 変更箇所

### SKILL.md ステップ3

**変更前**:
```
`steps/common/session-continuity.md` を読み込み、前回セッションの継続かを判定。
コンパクション復帰の場合は `steps/common/compaction.md` を読み込む。
```

**変更後**:
```
`steps/common/session-continuity.md` を読み込み、前回セッションの継続かを判定。
```

### session-continuity.md

末尾に以下のセクションを追加:

```markdown
## コンパクション復帰

コンパクション復帰と判定された場合は `steps/common/compaction.md` を読み込む。
```

## 実装手順

1. SKILL.md ステップ3の「コンパクション復帰の場合は...」行を削除
2. session-continuity.md の末尾にコンパクション復帰セクションを追加
3. compaction.md が変更されていないことを `diff` で検証
4. session-continuity.md の既存セクションが変更されていないことを確認
