# 論理設計: operations.mdの構成整理

## 概要

`.aidlc/operations.md` のメタ開発固有セクションに `<!-- META-DEV -->` マーキングを追加し、共通/固有の境界を明示する。

## 変更箇所

### `.aidlc/operations.md`

1. 「メタ開発特有のOperations Phase手順」セクション見出しの直前に `<!-- META-DEV: ここからメタ開発固有セクション -->` を追加
2. 「運用時の注意点」内のメタ開発言及（「メタ開発の意識」項目）を「メタ開発特有」セクションに移動
3. ファイル末尾に `<!-- /META-DEV -->` 閉じマーキングを追加

### マーキング方式

```markdown
<!-- META-DEV: ここからメタ開発固有セクション -->
## メタ開発特有のOperations Phase手順【重要】
...
<!-- /META-DEV -->
```

## ステップファイル参照の確認結果

- `skills/aidlc/steps/operations/01-setup.md` L94: `.aidlc/operations.md` を読み込み → パス変更なし
- `skills/aidlc/steps/operations/operations-release.md` L34: `.aidlc/operations.md` 参照 → パス変更なし
- ステップファイルの変更不要

## テンプレート整合の確認結果

- `skills/aidlc/templates/operations_handover_template.md`: 共通セクションのみで構成、メタ開発固有セクションなし → 整合OK
