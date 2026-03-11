# Unit: その他ガイドの事実誤記確認

## 概要

残りのガイドファイル（glossary.md、error-handling.md、backlog-registration.md、config-merge.md、ios-version-update.md、plan-mode.md、subagent-usage.md）の事実誤記を確認し、必要に応じて修正する。

## 含まれるユーザーストーリー

- ストーリー 5: その他ガイドの事実誤記確認

## 責務

- glossary.md の用語定義と rules.md の定義の照合
- error-handling.md の復旧手順の充実度確認
- backlog-registration.md と backlog-management.md の整合確認
- config-merge.md と read-config.sh の実装整合確認
- ios-version-update.md、plan-mode.md、subagent-usage.md の事実誤記確認

## 境界

- Unit 001〜003 で対応するファイルは対象外
- Unit 004 で対応するスクリプト参照チェックは対象外

## 依存関係

### 依存する Unit

- Unit 004（依存理由: Unit 004 が backlog-management.md を修正した場合、本Unitでの backlog-registration.md との整合確認に影響するため）

### 外部依存

- なし

## 非機能要件（NFR）

- 該当なし（ドキュメント修正のみ）

## 技術的考慮事項

- 各ファイルの精査は `prompts/package/guides/` 配下（正本）で実施
- 照合元: glossary→rules.md、backlog-registration→backlog-management.md、config-merge→read-config.sh

## 実装優先度

Medium

## 見積もり

中規模（対象7ファイル + 照合元3ファイル。照合点数が多い）

## 完了条件

- glossary.mdの用語定義がrules.mdの定義と一致（用語名・定義文の差異0件）
- error-handling.mdの復旧手順に前提条件・実行手順・失敗時対応の3項目が記載されている
- backlog-registration.mdとbacklog-management.mdの手順・用語が一致（差異0件）
- config-merge.mdの記述がread-config.shの実装と一致（引数・出力形式・処理順序の差異0件）
- ios-version-update.md、plan-mode.md、subagent-usage.mdの各ファイルについて照合チェック完了

## 関連Issue

なし

---

## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-12
- **完了日**: 2026-03-12
- **担当**: -
