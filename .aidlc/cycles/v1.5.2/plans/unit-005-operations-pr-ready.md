# Unit 005: Operations Phase 全Unit完了確認とPR Ready化 - 実行計画

## 概要

Operations Phase開始前に全Unitが完了していることを確認し、完了時にドラフトPRをReady for Reviewにする機能を `prompts/package/prompts/operations.md` に追加する。

## 対象ファイル

**編集対象**（rules.md に従い `docs/aidlc/` ではなく `prompts/package/` を編集）:
- `prompts/package/prompts/operations.md`

**関連バックログ**:
- `docs/cycles/backlog/feature-draft-pr-workflow.md`

## 実装方針

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
プロンプト改善のため、簡易なドメインモデル（概念定義）を作成:
- Operations Phase開始時の検証に関わる概念の整理
- Unit完了確認ロジックの定義
- ドラフトPR Ready化のライフサイクル定義

#### ステップ2: 論理設計
operations.md への追記箇所と内容を設計:
- 「最初に必ず実行すること」セクションに全Unit完了確認ステップを追加
- 「完了時の必須作業」セクションにドラフトPR Ready化ステップを追加
- エラーハンドリング（GitHub CLI利用不可時の手動操作案内）

#### ステップ3: 設計レビュー
ユーザーに設計内容を提示し、承認を得る

### Phase 2: 実装

#### ステップ4: コード生成
`prompts/package/prompts/operations.md` を編集:
- 全Unit完了確認ロジックを追加
- `gh pr ready` コマンドの使用例
- PR本文更新（サイクル成果追記）
- 未完了Unit警告表示

#### ステップ5: テスト生成
プロンプトファイルのため、テストコードは不要

#### ステップ6: 統合とレビュー
- 構文確認（Markdownの整合性）
- 実装記録の作成

## 見積もり

- Phase 1（設計）: 30分
- Phase 2（実装）: 30分
- 合計: 1時間

## 成果物

1. `docs/cycles/v1.5.2/design-artifacts/domain-models/operations-pr-ready_domain_model.md`
2. `docs/cycles/v1.5.2/design-artifacts/logical-designs/operations-pr-ready_logical_design.md`
3. `prompts/package/prompts/operations.md`（編集）
4. `docs/cycles/v1.5.2/construction/units/operations-pr-ready_implementation.md`

## 依存関係

- Unit 004（Construction Phase Unit PR作成・マージ）が完了していること ✓
