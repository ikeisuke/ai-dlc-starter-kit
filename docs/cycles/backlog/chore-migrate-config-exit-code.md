# migrate-config.sh の警告時終了コード修正

- **発見日**: 2026-03-24
- **発見フェーズ**: Construction
- **発見サイクル**: v1.27.3
- **優先度**: 低

## 概要

migrate-config.sh は警告時に `exit 2` を使用しているが、終了コード規約（v1.27.3 で策定）の「処理完了したら exit 0」原則に反する。

## 詳細

現在の動作:
- `_has_warnings=true` の場合 `exit 2`

規約に準拠した動作:
- `_has_warnings=true` でも `exit 0`
- 警告内容は stdout の出力（既存の `status:warning` 等）で通知

## 対応案

1. スクリプト末尾の `exit 2` を削除し `exit 0` に統一
2. 呼び出し元（rules.md 等）の終了コード記述を確認・更新
