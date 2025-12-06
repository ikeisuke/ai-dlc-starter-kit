# Unit 2: バックログ完了項目移動 - 実装計画

## 概要
Operations Phaseの完了処理にバックログ完了項目のbacklog-completed.mdへの移動手順を追加する

## 実装ステップ

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
- バックログ項目の状態遷移を定義
- 完了判定の基準を明確化
- 移動時の記録フォーマットを定義

#### ステップ2: 論理設計
- operations.mdへの追加箇所を特定
- 手順の具体的な記述内容を設計

#### ステップ3: 設計レビュー
- 設計内容をユーザーに提示し承認を得る

### Phase 2: 実装

#### ステップ4: コード生成
- `docs/aidlc/prompts/operations.md` にバックログ完了項目移動手順を追加

#### ステップ5: テスト生成
- N/A（プロンプト変更のため自動テストなし）

#### ステップ6: 統合とレビュー
- 変更内容の確認
- 実装記録の作成

## 成果物
- `docs/cycles/v1.2.1/design-artifacts/domain-models/unit2_domain_model.md`
- `docs/cycles/v1.2.1/design-artifacts/logical-designs/unit2_logical_design.md`
- `docs/aidlc/prompts/operations.md`（更新）
- `docs/cycles/v1.2.1/construction/units/unit2_implementation.md`

## 見積もり
0.5時間
