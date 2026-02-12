# Unit: ghスキル削除

## 概要
ghスキルを削除し、関連するシンボリックリンクとドキュメント参照を整理する。ghスキルはAIが既に知っている知識の冗長なスキルであるため、削除してスキル一覧をシンプルにする。

## 含まれるユーザーストーリー
- ストーリー 6: ghスキルの削除

## 責務
- `prompts/package/skills/gh/` ディレクトリの削除
- `.claude/skills/gh` シンボリックリンクの削除
- ghスキルを呼び出すロジックが `prompts/package/prompts/` に残っていないことを確認（`gh:available` 判定はスキル非依存のため影響なし）

**注意**: `skill-usage-guide.md` や `AGENTS.md` のghスキル参照削除はUnit 009（ドキュメント・リンク整合）で一括対応する。ストーリー6の受け入れ基準のうち `skill-usage-guide.md` のgh参照確認（`grep -r '"gh"' prompts/package/guides/skill-usage-guide.md`）は、Unit 009完了時に検証する。

## 境界
- AI-DLCプロンプト内の `gh:available` 判定フローの変更は含まない（スキル非依存のため影響なし）
- AGENTS.md等のドキュメント更新は含まない（Unit 009で対応）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- `gh:available` 判定ロジックはghスキルに依存していないため、プロンプト側の変更は不要
- 既存分析で確認済み: inception.md、construction.md、operations.md内のgh関連コマンドはスキル経由ではなく直接使用

## 受け入れ基準
- [ ] `test -d prompts/package/skills/gh` が失敗する（ディレクトリが存在しない）
- [ ] `test -L .claude/skills/gh` が失敗する（シンボリックリンクが存在しない）
- [ ] `grep -r 'skill.*gh' prompts/package/prompts/` でghスキルを呼び出すロジックがヒットしない

## 実装優先度
High

## 見積もり
0.25日（ディレクトリ・シンボリックリンク削除のみ）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
