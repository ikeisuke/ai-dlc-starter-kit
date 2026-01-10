# Unit: ルール責務分離

## 概要
rules.md の汎用ルールを AGENTS.md テンプレートに移動し、責務を分離する。

## 含まれるユーザーストーリー
- ストーリー1: 共通ルールの分離

## 責務
- AGENTS.md テンプレートに共通ルールセクションを追加
- rules_template.md からAI-DLC共通ルールを削除
- 既存の docs/cycles/rules.md を更新
- AskUserQuestionツールの使用ルール追加（不明点がなくなるまで繰り返し質問すること）

## 境界
- `prompts/package/templates/AGENTS.md.template`
- `prompts/setup/templates/rules_template.md`
- `docs/cycles/rules.md`

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- `docs/aidlc/` は直接編集禁止（`prompts/package/` を編集）
- Operations Phase で rsync により反映される

## 実装優先度
High

## 見積もり
30分

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
