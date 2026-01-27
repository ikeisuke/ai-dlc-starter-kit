# Unit: Codex Skill反復レビューresume明確化

## 概要

Codex Skillの説明に反復レビュー時のresume使用ガイドを追加し、効率的なレビュー継続を支援する。

## 含まれるユーザーストーリー

- ストーリー3: Codex Skill反復レビュー時のresume使用を明確化 (#132)

## 責務

- 「反復レビュー時のルール」セクションの追加
- session idの確認・記録方法の明記
- resumeを使うべき場面の強調
- 反復レビューの流れの例示

## 境界

- Codex Skill以外のSkillsは対象外
- Codexの内部動作の変更は行わない

## 依存関係

### 依存する Unit

なし

### 外部依存

- Codex CLI (OpenAI)

## 非機能要件（NFR）

- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- 対象ファイル: `prompts/package/skills/codex/SKILL.md`
- 既存の反復レビューフロー（review-flow.md）との整合性を確認
- session id / thread id の取り扱いを明記

## 実装優先度

High

## 見積もり

小（ドキュメント追加）

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-01-28
- **完了日**: -
- **担当**: -
