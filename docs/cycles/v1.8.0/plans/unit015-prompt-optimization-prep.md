# Unit 015: プロンプト最適化準備 - 実行計画

## 対象Unit

- **名称**: プロンプト最適化準備
- **定義ファイル**: `docs/cycles/v1.8.0/story-artifacts/units/015-prompt-optimization-prep.md`
- **関連Issue**: #45

## 目的

プロンプト指示の現状を分析し、次サイクルでの最適化作業の土台を作る。

## 実行フェーズ

### Phase 1: 設計（ドキュメント分析）

このUnitは実装コードを伴わない分析タスクのため、設計フェーズで分析方針を決定する。

#### ステップ1: プロンプト現状分析（ドメインモデル設計相当）

**目的**: 各プロンプトファイルの現状を定量的・定性的に把握する

**対象ファイル**:

- `prompts/package/prompts/setup.md`
- `prompts/package/prompts/inception.md`
- `prompts/package/prompts/construction.md`
- `prompts/package/prompts/operations.md`
- `prompts/package/prompts/AGENTS.md`
- `prompts/package/prompts/CLAUDE.md`

**分析項目**:

1. 行数・文字数の計測
2. 重複指示の特定
3. 冗長指示の特定
4. 削除候補の洗い出し
5. 統合候補の洗い出し

**成果物**: `docs/cycles/v1.8.0/design-artifacts/domain-models/015-prompt-optimization-prep_domain_model.md`

#### ステップ2: 改善提案（論理設計相当）

**目的**: 分析結果に基づき、次サイクルで実施すべき改善タスクを整理する

**成果物**: `docs/cycles/v1.8.0/design-artifacts/logical-designs/015-prompt-optimization-prep_logical_design.md`

#### ステップ3: 設計レビュー

設計内容をユーザーに提示し、承認を得る。

### Phase 2: 実装

#### ステップ4: 分析レポート作成

**成果物**: `docs/cycles/v1.8.0/requirements/prompt-analysis.md`

#### ステップ5: バックログIssue作成

次サイクル向けの具体的なタスクをGitHub Issueとして作成:

- 重複指示の統合
- 冗長指示の簡素化
- Operations Phaseでのサイズチェック機能追加

#### ステップ6: 統合とレビュー

- 成果物の最終確認
- 実装記録の作成
- Unit完了処理

## 完了基準

- [ ] プロンプト分析レポートが作成されている
- [ ] 次サイクル向けのバックログIssueが作成されている
- [ ] 実装記録に「完了」が記録されている
- [ ] Unit定義ファイルの実装状態が「完了」に更新されている
