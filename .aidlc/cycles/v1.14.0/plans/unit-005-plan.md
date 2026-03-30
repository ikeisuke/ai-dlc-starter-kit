# Unit 005 計画: 旧レビュースキル削除

## 概要

codex-review、claude-review、gemini-reviewの3つの旧スキルディレクトリとシンボリックリンクを削除する。

## 変更対象ファイル

### 削除対象

- `prompts/package/skills/codex-review/` ディレクトリ全体
- `prompts/package/skills/claude-review/` ディレクトリ全体
- `prompts/package/skills/gemini-review/` ディレクトリ全体
- `.claude/skills/codex-review` シンボリックリンク
- `.claude/skills/claude-review` シンボリックリンク
- `.claude/skills/gemini-review` シンボリックリンク

### 参照残存（確認事項）

削除後、以下のファイルに旧スキル名への参照が残る:

- `prompts/package/guides/skill-usage-guide.md`
- `prompts/package/prompts/AGENTS.md`

**注意**: Unit定義の「境界」セクションでは「AGENTS.md等のドキュメント更新はUnit 009で対応」と明記されているが、受け入れ基準では `grep` でヒットしないことを求めている。この矛盾の扱いをユーザーに確認する。

## 実装計画

1. 旧スキルディレクトリの削除（`prompts/package/skills/` から3ディレクトリ）
2. 旧シンボリックリンクの削除（`.claude/skills/` から3リンク）
3. `grep` で残存参照の確認
4. 受け入れ基準の検証

## 完了条件チェックリスト

- [ ] `prompts/package/skills/codex-review` ディレクトリが存在しない
- [ ] `prompts/package/skills/claude-review` ディレクトリが存在しない
- [ ] `prompts/package/skills/gemini-review` ディレクトリが存在しない
- [ ] `.claude/skills/codex-review` シンボリックリンクが存在しない
- [ ] `.claude/skills/claude-review` シンボリックリンクが存在しない
- [ ] `.claude/skills/gemini-review` シンボリックリンクが存在しない
- [ ] `grep -r "codex-review\|claude-review\|gemini-review" prompts/package/` がヒットしない（CHANGELOG・Unit 009対象のドキュメント除く）
