# Unit 007 計画: mktempでの$()使用禁止の徹底

## 概要

テンポラリファイル規約とsetup-prompt.mdにおけるmktemp使用箇所から`$()`を排除し、一貫した手順に統一する。

## 変更対象ファイル

- `prompts/setup-prompt.md`
- `prompts/package/prompts/common/rules.md`

## 実装計画

1. setup-prompt.mdの`TEMP_FILE=$(mktemp)`パターン3件を手順説明方式に分割
2. rules.mdのテンポラリファイル規約にmktemp時の`$()`禁止を明記

## 完了条件チェックリスト

- [x] setup-prompt.md内に`$(mktemp)`パターンが0件
- [x] rules.mdのテンポラリファイル規約にmktemp時の`$()`禁止が明記されている
- [x] 手順説明が「Bashツールでmktempを単独実行→パス取得」の流れで統一されている
