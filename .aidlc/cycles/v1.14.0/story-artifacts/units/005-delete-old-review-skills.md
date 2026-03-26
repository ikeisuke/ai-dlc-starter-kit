# Unit: 旧レビュースキル削除

## 概要
codex-review、claude-review、gemini-reviewの3スキルを削除し、関連するシンボリックリンクも削除する。旧スキル名への参照が残っていないことを確認する。

## 含まれるユーザーストーリー
- ストーリー 5: 旧レビュースキルの削除

## 責務
- `prompts/package/skills/` から codex-review、claude-review、gemini-review ディレクトリの削除
- `.claude/skills/` から codex-review、claude-review、gemini-review シンボリックリンクの削除
- `grep -r "codex-review\|claude-review\|gemini-review" prompts/package/` で旧スキル名の残存がないことを確認（CHANGELOG除く）

## 境界
- 新スキルの作成は含まない（Unit 001-003で完了済み）
- review-flow.mdの更新は含まない（Unit 004で完了済み）
- AGENTS.md等のドキュメント更新は含まない（Unit 009で対応）

## 依存関係

### 依存する Unit
- Unit 004: レビューフロー更新（依存理由: review-flow.mdが新スキルを呼び出すように更新された後でないと、旧スキル削除でフローが壊れる。Unit 004はUnit 001-003に依存するため、001-003の完了も推移的に保証される）

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- 削除前に `grep` で旧スキル名の参照箇所を最終確認
- `docs/aidlc/` は `prompts/package/` のrsyncコピーのため、次回rsync時に自動反映される

## 受け入れ基準
- [ ] `test -d prompts/package/skills/codex-review` が失敗する（ディレクトリが存在しない）
- [ ] `test -d prompts/package/skills/claude-review` が失敗する
- [ ] `test -d prompts/package/skills/gemini-review` が失敗する
- [ ] `test -L .claude/skills/codex-review` が失敗する（シンボリックリンクが存在しない）
- [ ] `test -L .claude/skills/claude-review` が失敗する
- [ ] `test -L .claude/skills/gemini-review` が失敗する
- [ ] `grep -r "codex-review\|claude-review\|gemini-review" prompts/package/` がヒットしない（CHANGELOG除く）

## 実装優先度
High

## 見積もり
0.25日（ディレクトリ・シンボリックリンク削除 + grep確認のみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-13
- **完了日**: 2026-02-14
- **担当**: @ikeisuke
