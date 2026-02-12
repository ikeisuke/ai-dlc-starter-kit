# Unit: ドキュメント・リンク整合

## 概要
スキル再編・削除の完了を受けて、シンボリックリンク、AGENTS.md、skill-usage-guide.md、setup-prompt.md、rules.mdを新スキル構成と一致するように更新する。

## 含まれるユーザーストーリー
- ストーリー 9: シンボリックリンクとドキュメントの更新

## 責務
- `.claude/skills/` に reviewing-code、reviewing-architecture、reviewing-security、jj、aidlc-upgrade の5つのシンボリックリンクが存在し、それぞれ `docs/aidlc/skills/` 配下を指していることを確認
- `prompts/package/prompts/AGENTS.md` のスキル一覧テーブルに新スキル3つを記載し、旧スキル4つ（codex-review, claude-review, gemini-review, gh）を削除
- `prompts/package/guides/skill-usage-guide.md` のスキル構成説明を新構成（5スキル）に更新
- `prompts/setup-prompt.md` のシンボリックリンク作成処理を新スキル名（5スキル）に更新
- `docs/cycles/rules.md` の `skill="codex"` を新スキル名に更新

## 境界
- スキルのSKILL.md内容の変更は含まない（Unit 001-003, 007, 008で完了済み）
- review-flow.mdの変更は含まない（Unit 004で完了済み）

## 依存関係

### 依存する Unit
- Unit 004: レビューフロー更新（依存理由: review-flow.mdの新スキル名が確定している必要がある）
- Unit 005: 旧レビュースキル削除（依存理由: 旧スキルが削除済みであることが前提）
- Unit 006: ghスキル削除（依存理由: ghスキルが削除済みであることが前提）

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし

## 技術的考慮事項
- `docs/aidlc/` は `prompts/package/` のrsyncコピーのため、AGENTS.md等の編集は `prompts/package/` 側で行う
- setup-prompt.mdのシンボリックリンク作成処理は新旧スキル名の差し替え
- rules.mdの `skill="codex"` は新しいレビュースキル呼び出し方法に更新

## 実装優先度
High

## 見積もり
中規模（5ファイルの更新）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
