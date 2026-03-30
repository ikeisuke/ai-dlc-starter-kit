# Unit 003 計画: テンプレート形式統一・スクリプト出力標準化

## 概要

テンプレートのプレースホルダ形式統一とrun-markdownlint.shの出力フォーマット標準化。

## Source of Truth

| 修正対象 | Source of Truth | 修正方向 |
|---------|-----------------|---------|
| implementation_record_template.md プレースホルダ | 他テンプレートの `{{PLACEHOLDER}}` 形式 | `<unit>` → `{{UNIT_SLUG}}` に統一 |
| run-markdownlint.sh 出力 | 他スクリプトの `key:value` 出力規約 | `markdownlint:success/skipped/error` 形式に標準化 |

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc/templates/implementation_record_template.md` | `<unit>` を `{{UNIT_SLUG}}` に置換（#475） |
| `skills/aidlc/scripts/run-markdownlint.sh` | 出力を `markdownlint:success/skipped/error` 形式に標準化（#476） |
| `skills/aidlc/steps/operations/operations-release.md` | ステップ7.5に出力形式を追記（consumer整合） |

## 完了条件チェックリスト

- [ ] implementation_record_template.md のプレースホルダが `{{PLACEHOLDER}}` 形式に統一されている（#475）
- [ ] run-markdownlint.sh の出力が `markdownlint:success/skipped/error` 形式で標準化されている（#476）
- [ ] operations-release.md ステップ7.5に出力形式が記述されている
