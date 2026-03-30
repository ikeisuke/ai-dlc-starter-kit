# Unit 4: サイクル管理基盤 - Phase 2（次サイクルへのタスクリスト管理）実装計画

## 概要
次のサイクルに引き継ぐべきタスクを管理する仕組みを構築する。Operations Phase完了時に、未完了のタスクや改善点を次サイクルのタスクリストとして記録し、次のサイクル開始時にそれを読み込める仕組みを提供する。

## 対象範囲
Unit 4の後半として、**次サイクルへのタスクリスト管理**を実装する。

### Phase 2（今回実装）
- 次サイクルタスクリストの設計
- Operations Phaseでのタスク記録フローの追加
- 次サイクルInception Phaseでのタスク読み込みフローの追加

## Phase 2: 設計（対話形式）

### ステップ1: ドメインモデル設計
**成果物**: `docs/cycles/v1.0.1/design-artifacts/domain-models/unit4_phase2_next_cycle_tasks_domain_model.md`

**内容**:
- 次サイクルタスクの概念定義
- タスクの記録時期と読み込み時期
- タスクの優先度とカテゴリ

### ステップ2: 論理設計
**成果物**: `docs/cycles/v1.0.1/design-artifacts/logical-designs/unit4_phase2_next_cycle_tasks_logical_design.md`

**内容**:
- タスクリストのファイル構造（`docs/cycles/{CYCLE}/next_cycle_tasks.md`）
- Operations Phase完了時のタスク記録フロー
- Inception Phase開始時のタスク読み込みフロー
- setup-prompt.mdとoperations.md、inception.mdの修正箇所

### ステップ3: 設計レビュー
ユーザーに設計内容を提示し、承認を得る。

## Phase 2: 実装

### ステップ4: プロンプトファイルの修正

**修正対象**:
1. `prompts/setup-prompt.md` - operations.md生成部分
   - Operations Phase完了時に次サイクルタスクリストを作成する指示を追加

2. `prompts/setup-prompt.md` - inception.md生成部分
   - Inception Phase開始時に前サイクルのタスクリストを確認する指示を追加

### ステップ5: テンプレート作成

**作成対象**:
- `docs/aidlc/templates/next_cycle_tasks_template.md` - 次サイクルタスクリストのテンプレート

### ステップ6: テスト
- タスクリストテンプレートの確認
- プロンプト修正内容の確認

### ステップ7: 統合とレビュー
- 修正内容の確認
- テスト結果の確認
- 実装記録の作成: `docs/cycles/v1.0.1/construction/units/unit4_phase2_next_cycle_tasks_implementation.md`

## 完了基準
- [ ] 次サイクルタスクリストのテンプレートが作成されている
- [ ] Operations Phase完了時にタスクを記録するフローが追加されている
- [ ] Inception Phase開始時にタスクを読み込むフローが追加されている
- [ ] テストが成功している
- [ ] 実装記録に「完了」が明記されている
- [ ] `progress.md` が更新されている（Unit 4全体完了として記録）
- [ ] `history.md` に記録されている
- [ ] Gitコミットが作成されている

## 見積もり
- Phase 2（次サイクルへのタスクリスト管理）: 5時間
  - 設計: 1時間
  - 実装: 3時間
  - テスト: 1時間

## 備考
- Phase 1（サイクル指定方法の改善）完了後に実施
- Phase 2完了でUnit 4全体が完了
