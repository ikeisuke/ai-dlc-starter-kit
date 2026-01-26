# Unit 001 計画: ドキュメント修正一括

## 概要

jj-support.md のリモートブックマーク表記修正、codex skill の resume 説明追加、アップグレード指示へのパス参照追加を一括で実施する。

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/guides/jj-support.md` | リモートブックマーク表記修正 |
| `prompts/package/skills/codex/SKILL.md` | resume機能の説明を強調・統合 |
| `docs/cycles/rules.md` | メタ開発時のパス参照を追記 |

## 実装計画

### ステップ1: jj-support.md 修正（Issue #89）

- 226行目: 表のプレースホルダを `<bookmark>@<remote>` に修正
- 235行目: 例を `main@origin` に修正

### ステップ2: codex SKILL.md 修正（Issue #121）

- 既存の「セッション引き継ぎ」使用例を「セッション継続」セクションに昇格・統合

### ステップ3: rules.md 修正（Issue #87）

- 「メタ開発の意識」セクションにスターターキットのパス参照方法を追記

## 完了条件チェックリスト

- [ ] jj-support.md のリモートブックマーク表記を修正
- [ ] codex skill に resume 機能の説明を追加
- [ ] アップグレード指示にメタ開発用パスを追記

## 備考

- Issue #89 の指摘1（未追跡ファイル記述）は誤りだったため対象外
