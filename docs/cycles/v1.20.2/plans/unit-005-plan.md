# Unit 005 計画: その他ガイドの事実誤記確認

## 概要

残りのガイドファイル7件の事実誤記を確認し、必要に応じて修正する。

## 変更対象ファイル

- `prompts/package/guides/config-merge.md`（修正あり）
- `prompts/package/guides/error-handling.md`（修正あり）
- `prompts/package/guides/glossary.md`（確認のみ、修正不要）
- `prompts/package/guides/backlog-registration.md`（確認のみ、修正不要）
- `prompts/package/guides/ios-version-update.md`（確認のみ、修正不要）
- `prompts/package/guides/plan-mode.md`（確認のみ、修正不要）
- `prompts/package/guides/subagent-usage.md`（確認のみ、修正不要）

## 実装計画

1. 7ファイルを照合元と比較して事実誤記を確認
2. config-merge.md: defaults.toml階層の追加（3階層→4階層）
3. error-handling.md: 復旧手順に前提条件・失敗時対応を構造化追加

## 完了条件チェックリスト

- [x] glossary.mdの用語定義がrules.mdの定義と一致
- [x] error-handling.mdの復旧手順に前提条件・実行手順・失敗時対応の3項目が記載
- [x] backlog-registration.mdとbacklog-management.mdの手順・用語が一致
- [x] config-merge.mdの記述がread-config.shの実装と一致
- [x] ios-version-update.md、plan-mode.md、subagent-usage.mdの照合チェック完了
