# Unit: ルール責務分離とフェーズ簡略指示

## 概要
rules.md の汎用ルールを AGENTS.md テンプレートに移動し、責務を分離する。
また、フェーズ簡略指示機能を追加し、シンプルな指示でフェーズを開始できるようにする。

## 含まれるユーザーストーリー
- ストーリー1: 共通ルールの分離
- ストーリー2: フェーズ簡略指示

## 責務
- AGENTS.md テンプレートに共通ルールセクションを追加
- rules_template.md からAI-DLC共通ルールを削除
- 既存の docs/cycles/rules.md を更新
- AskUserQuestionツールの使用ルール追加（不明点がなくなるまで繰り返し質問すること）
- フェーズ簡略指示機能を AGENTS.md に追加
  - 「インセプション進めて」等のキーワードでプロンプト自動読み込み
  - ブランチ名からサイクル自動判定
  - mainブランチ時はセットアップを促す
  - コンテキストなしで「続けて」はユーザーに確認
- 各フェーズプロンプトの完了時メッセージを簡略指示形式に更新
  - 例: 「コンストラクション進めて」と指示してください

## 境界
- `prompts/package/prompts/AGENTS.md` - フェーズ簡略指示機能
- `prompts/package/prompts/inception.md` - 完了時メッセージ更新
- `prompts/package/prompts/construction.md` - 完了時メッセージ更新
- `prompts/package/prompts/operations.md` - 完了時メッセージ更新
- `prompts/package/prompts/setup.md` - 完了時メッセージ更新
- `prompts/package/templates/AGENTS.md.template` - 共通ルールテンプレート
- `prompts/setup/templates/rules_template.md` - プロジェクト固有ルールテンプレート
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
