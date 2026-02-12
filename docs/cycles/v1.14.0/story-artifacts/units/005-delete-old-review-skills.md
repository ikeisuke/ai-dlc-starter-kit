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
- Unit 004: レビューフロー更新（依存理由: review-flow.mdが新スキルを呼び出すように更新された後でないと、旧スキル削除でフローが壊れる）

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- 削除前に `grep` で旧スキル名の参照箇所を最終確認
- `docs/aidlc/` は `prompts/package/` のrsyncコピーのため、次回rsync時に自動反映される

## 実装優先度
High

## 見積もり
小規模（ディレクトリ・シンボリックリンク削除のみ）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
