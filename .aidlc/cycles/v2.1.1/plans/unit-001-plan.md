# Unit 001 計画: レビューフロー信頼性向上

## 概要

AIレビュー工程の確実な実施を保証する。タスクリスト駆動の強化（#493）、review-summary.md作成の必須化（#495）、意思決定記録ステップの確実な実行（#496）を対応する。

## 設計方針

### 責務分離の原則

- **共通層（`steps/common/*`）が規約の唯一の定義源（Single Source of Truth）**
- 各フェーズのステップファイルは共通層への**参照のみ**を追加する（定義の重複禁止）
- 既存の参照パターン（例: `steps/common/task-management.md` の「タスクテンプレート」に従い作成）を踏襲

### 成果物契約（既存定義の参照）

- **review-summary.md**: review-flow.mdの「レビューサマリファイル更新手順」セクションに作成タイミング・保存先・必須セクション・完了判定が定義済み。本Unitは「必須」としての強調を強化するのみ
- **意思決定記録（decisions.md）**: inception/05-completion.mdの「4. 意思決定記録」セクションが定義のオーナー（正本）
  - 作成条件: 2つ以上の明確な選択肢からユーザーが選択した場面がある場合
  - 保存先: `.aidlc/cycles/{{CYCLE}}/inception/decisions.md`
  - テンプレート: `templates/decision_record_template.md`
  - 記録単位: 連番ID（DR-001, DR-002, ...）
  - 未作成許容条件: 記録対象の意思決定がなければスキップ（ファイル未作成で問題なし）
  - 完了判定: 記録対象の有無を確認し、該当があれば記録済み/なければスキップ済みであること
  - construction/04-completion.mdは参照のみ追加

## 変更対象ファイル

| ファイル | 変更内容 | 対応Issue | 役割 |
|---------|---------|----------|------|
| `steps/common/review-flow.md` | レビューサマリ更新の必須化強調 | #495 | 定義強化 |
| `steps/common/task-management.md` | レビュー工程を含むチェック項目の強化 | #493 | 定義強化 |
| `steps/construction/01-setup.md` | task-management.mdへの参照強化 | #493 | 参照追加 |
| `steps/construction/02-design.md` | タスクステータス更新指示の参照追加 | #493 | 参照追加 |
| `steps/construction/03-implementation.md` | タスクステータス更新指示の参照追加 | #493 | 参照追加 |
| `steps/construction/04-completion.md` | 意思決定記録（inception正本）への参照追加 | #493 | 参照追加 |
| `steps/inception/05-completion.md` | 意思決定記録ステップの確実な実行を明確化（オーナー） | #496 | 定義強化 |
| `steps/operations/01-setup.md` | task-management.mdへの参照強化 | #493 | 参照追加 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: プロンプトファイルの修正のみのため、軽量な設計で対応
2. **論理設計**: 各ファイルの修正箇所と追加テキストの具体的な内容を定義

### Phase 2: 実装

1. **#495 対応**: review-flow.mdのレビューステップ完了時の共通処理でサマリ更新指示を「必須」として強化
2. **#493 対応**: task-management.mdの定義を強化し、各フェーズのステップファイルから参照を追加
3. **#496 対応**: inception/05-completion.mdの意思決定記録ステップを「オプション」から「必須チェック」に変更

## 完了条件チェックリスト

- [ ] review-flow.mdのレビュー完了時共通処理でサマリ更新指示を強化
- [ ] Inception/Construction/Operationsの各ステップファイルにタスク管理参照を追加
- [ ] inception/05-completion.mdの完了処理で意思決定記録ステップを明確化（オーナー）
- [ ] construction/04-completion.mdにinception/05-completion.md（decisions.md正本）への参照を追加
- [ ] task-management.mdのタスクテンプレートにレビュー工程を含むチェック項目を追加
