# Unit 006 計画: ghスキル削除

## 概要

ghスキルを削除する。AIが既に知っている知識の冗長なスキルであるため、削除してスキル一覧をシンプルにする。

## 変更対象ファイル

- `prompts/package/skills/gh/` ディレクトリ（削除）

## 実装計画

1. `prompts/package/skills/gh/` ディレクトリを削除
2. `prompts/package/prompts/` 内にghスキルを呼び出すロジックがないことを確認（確認済み）

**対象外**:
- `.claude/skills/gh` シンボリックリンク: Operations PhaseのAIDLCアップグレード時に自動削除されるため本Unitでは対応しない
- AGENTS.md、skill-usage-guide.md等のドキュメント更新: Unit 009で対応

## 完了条件チェックリスト

- [ ] `test -d prompts/package/skills/gh` が失敗する（ディレクトリが存在しない）
- [ ] `grep -r 'skill.*gh' prompts/package/prompts/` でghスキルを呼び出すロジックがヒットしない
