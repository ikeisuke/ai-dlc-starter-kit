# 実装記録: Operations Phase 全Unit完了確認とPR Ready化

## 概要
Operations Phase開始前に全Unitが完了していることを確認し、完了時にドラフトPRをReady for Reviewにする機能を実装。

## 実装日
2025-12-25

## 変更ファイル

### 編集
- `prompts/package/prompts/operations.md`

### 新規作成
- `docs/cycles/v1.5.2/design-artifacts/domain-models/operations_pr_ready_domain_model.md`
- `docs/cycles/v1.5.2/design-artifacts/logical-designs/operations_pr_ready_logical_design.md`
- `docs/cycles/v1.5.2/plans/unit-005-operations-pr-ready.md`
- `docs/cycles/v1.5.2/construction/units/operations-pr-ready_implementation.md`

## 実装内容

### 1. 全Unit完了確認ステップの追加

**変更箇所**: 「最初に必ず実行すること」セクション（5ステップ→6ステップ）

**追加内容**:
- ステップ6として「全Unit完了確認」を追加
- Unit定義ファイル群の「実装状態」セクションを確認
- 未完了Unitがある場合は警告表示し、続行or Construction Phaseへ戻りを選択

### 2. ドラフトPR Ready化への変更

**変更箇所**: 「ステップ6: リリース準備」の「6.4 PR作成」

**変更内容**:
- 「PR作成」から「ドラフトPR Ready化」に変更
- GitHub CLI利用可否チェックを追加
- 既存ドラフトPRの検索処理を追加
- `gh pr ready` コマンドでReady化
- ドラフトPRが存在しない場合は新規PR作成を提案
- GitHub CLI利用不可時の手動操作案内

### 3. 関連セクションの更新

- 「完了時の確認」セクション: 「PR作成」→「ドラフトPR Ready化」に更新

## テスト

プロンプトファイルのため、テストコードは不要。

## 関連ドキュメント

- Unit定義: `docs/cycles/v1.5.2/story-artifacts/units/005-operations-pr-ready.md`
- ドメインモデル: `docs/cycles/v1.5.2/design-artifacts/domain-models/operations_pr_ready_domain_model.md`
- 論理設計: `docs/cycles/v1.5.2/design-artifacts/logical-designs/operations_pr_ready_logical_design.md`
- 関連バックログ: `docs/cycles/backlog/feature-draft-pr-workflow.md`

## 備考

- `docs/aidlc/` は直接編集禁止（rules.md に従い `prompts/package/` を編集）
- Operations Phase の rsync で `prompts/package/` から `docs/aidlc/` にコピーされる
