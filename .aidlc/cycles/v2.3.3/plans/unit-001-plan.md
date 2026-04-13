# Unit 001 計画: SKILL.mdパス解決ルール修正

## 概要
SKILL.mdの「パス解決」セクションに `config/`, `templates/`, `guides/`, `references/` を追加。

## 修正対象
- `skills/aidlc/SKILL.md` L238付近のパス解決セクション

## 修正内容
現在: `steps/` および `scripts/` で始まるパス
修正後: `steps/`, `scripts/`, `config/`, `templates/`, `guides/`, `references/` で始まるパス

## 完了条件チェックリスト
- [ ] SKILL.mdのパス解決ルールに6プレフィックスすべて明記
- [ ] `config/` パスがスキルベースディレクトリから解決可能
- [ ] `templates/` パスがスキルベースディレクトリから解決可能
- [ ] `guides/` パスがスキルベースディレクトリから解決可能
- [ ] `references/` パスがスキルベースディレクトリから解決可能
- [ ] 既存 `steps/` / `scripts/` 解決挙動 不変
- [ ] SKILL.md 500行以内制約 維持
