# Unit: レビューフロー更新

## 概要
review-flow.mdを更新し、新しいレビュースキル（reviewing-code, reviewing-architecture, reviewing-security）を呼び出すように変更する。レビュー種別の選択ロジックと、`docs/aidlc.toml` の `ai_tools` 設定を参照したツール選択の仕組みを実装する。

## 含まれるユーザーストーリー
- ストーリー 4: レビューフローからの新スキル呼び出し

## 責務
- `prompts/package/prompts/common/review-flow.md` 内の `skill="codex"` / `skill="claude"` / `skill="gemini"` を新スキル名に更新
- レビュー種別（code/architecture/security）の選択ロジック追加
- `docs/aidlc.toml` の `[rules.mcp_review].ai_tools` を参照してツールを選択する記述の追加

## 境界
- 新スキルのSKILL.md作成は含まない（Unit 001-003で完了済み）
- 旧スキルの削除は含まない（Unit 005で対応）
- AGENTS.mdやskill-usage-guide.mdの更新は含まない（Unit 009で対応）

## 依存関係

### 依存する Unit
- Unit 001: reviewing-code スキル作成（依存理由: 呼び出し先のスキルが存在している必要がある）
- Unit 002: reviewing-architecture スキル作成（依存理由: 呼び出し先のスキルが存在している必要がある）
- Unit 003: reviewing-security スキル作成（依存理由: 呼び出し先のスキルが存在している必要がある）

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし（プロンプトファイルの更新のみ）

## 技術的考慮事項
- 現在のreview-flow.mdはツール選択（codex/claude/gemini）のみ
- 新設計ではレビュー種別選択 → ツール選択の2段階になる
- 後方互換性: 既存の `docs/aidlc.toml` の `[rules.mcp_review]` 設定との整合性を保つ

## 受け入れ基準
- [ ] `grep -c 'skill="codex"' prompts/package/prompts/common/review-flow.md` が0である（旧スキル名が残っていない）
- [ ] `grep -c 'skill="claude"' prompts/package/prompts/common/review-flow.md` が0である
- [ ] `grep -c 'skill="gemini"' prompts/package/prompts/common/review-flow.md` が0である
- [ ] review-flow.mdにレビュー種別（code/architecture/security）の選択ロジックが記載されている
- [ ] review-flow.mdに `docs/aidlc.toml` の `[rules.mcp_review].ai_tools` 参照記述が存在する

## 実装優先度
High

## 見積もり
1日（review-flow.mdの設計変更。レビュー種別選択→ツール選択の2段階ロジック設計が主作業。不確実性: 既存フローとの整合性確認）

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-02-13
- **完了日**: -
- **担当**: @ikeisuke
