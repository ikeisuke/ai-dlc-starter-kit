# Unit 004: Construction Phase Unit PR作成・マージ - 実行計画

## 概要

各Unit完了時にサイクルブランチへのPRを作成し、レビュー後にマージする機能を `prompts/package/prompts/construction.md` に追加する。

## 対象ファイル

**編集対象**（rules.md に従い `docs/aidlc/` ではなく `prompts/package/` を編集）:
- `prompts/package/prompts/construction.md`

**関連バックログ**:
- `docs/cycles/backlog/feature-draft-pr-workflow.md`

## 実装方針

### Phase 1: 設計

#### ステップ1: ドメインモデル設計
プロンプト改善のため、簡易なドメインモデル（概念定義）を作成:
- Unit完了後のPRワークフローに関わる概念の整理
- ブランチ命名規則の定義
- PRライフサイクルの定義

#### ステップ2: 論理設計
construction.md への追記箇所と内容を設計:
- 「Unit完了時の必須作業」セクションへのPR作成ステップ追加
- ブランチ操作手順の定義
- エラーハンドリング（GitHub CLI利用不可時のスキップ）

#### ステップ3: 設計レビュー
ユーザーに設計内容を提示し、承認を得る

### Phase 2: 実装

#### ステップ4: コード生成
`prompts/package/prompts/construction.md` を編集:
- 「Unit完了時の必須作業」セクションにPR作成ステップを追加
- ブランチ命名規則: `cycle/vX.X.X/unit-NNN`
- `gh pr create` コマンドの使用例
- PRマージ後のブランチ削除手順

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

1. `docs/cycles/v1.5.2/design-artifacts/domain-models/construction-unit-pr_domain_model.md`
2. `docs/cycles/v1.5.2/design-artifacts/logical-designs/construction-unit-pr_logical_design.md`
3. `prompts/package/prompts/construction.md`（編集）
4. `docs/cycles/v1.5.2/construction/units/construction-unit-pr_implementation.md`

## 依存関係

- Unit 003（Inception Phase ドラフトPR作成）が完了していること ✓
