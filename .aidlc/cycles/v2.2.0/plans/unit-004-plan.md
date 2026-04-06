# Unit 004 計画: 設定一貫性改善・情報提示ルール追加

## 概要

linting設定キーの不整合修正、defaults.toml先頭コメント更新、判断時の情報提示ルール追加。

## 作業内容

### タスク A: config.toml.templateのキー名統一（#530）

`skills/aidlc-setup/templates/config.toml.template` L71-76:
- `markdown_lint = false` → `enabled = false` に変更
- コメントも `enabled: true | false` 形式に更新

### タスク B: defaults.toml先頭コメント更新（#531）

2ファイルの先頭コメントを現行仕様に更新:
- `skills/aidlc/config/defaults.toml` L3: `docs/aidlc.toml` → `.aidlc/config.toml`
- `skills/aidlc-setup/config/defaults.toml` L3: 同上

### タスク C: agents-rules.mdに情報提示ルール追加（#534）

`skills/aidlc/steps/common/agents-rules.md` の「質問と深掘り」セクション末尾に情報提示ルールを簡潔に追加。

## 完了条件チェックリスト

- [ ] config.toml.templateのlintingキーが `enabled` に統一されている
- [ ] 両defaults.tomlの先頭コメントが `.aidlc/config.toml` を参照している
- [ ] agents-rules.mdに情報提示ルールが追加されている
- [ ] preflight.mdの旧キーフォールバックロジックは変更されていない
