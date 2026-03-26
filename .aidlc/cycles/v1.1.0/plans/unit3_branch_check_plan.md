# Unit 3: ブランチ確認機能 - 実装計画

## 概要

セットアップ時に現在のGitブランチ名がサイクル名と一致しているか確認し、不一致の場合は切り替えを提案する機能を実装する。

## 対象ファイル

- `prompts/setup-prompt.md` - 「実行環境の確認」セクションに追加

## Phase 1: 設計

### ステップ1: ドメインモデル設計

このUnitは主にプロンプト（ドキュメント）の修正であり、複雑なドメインモデルは不要。
ただし、以下の概念を明確にする：

- **BranchCheck**: ブランチ確認の責務
  - 現在のブランチ取得
  - サイクル名との比較
  - 警告・提案の表示

成果物: `docs/cycles/v1.1.0/design-artifacts/domain-models/unit3_branch_check_domain_model.md`

### ステップ2: 論理設計

確認ロジックのフロー：
1. `git branch --show-current` で現在のブランチを取得
2. `CYCLE` がブランチ名に含まれているか確認
3. 含まれていない場合、警告を表示
4. `cycle/{CYCLE}` 形式のブランチへの切り替えを提案

成果物: `docs/cycles/v1.1.0/design-artifacts/logical-designs/unit3_branch_check_logical_design.md`

### ステップ3: 設計レビュー

設計内容をユーザーに提示し、承認を得る

## Phase 2: 実装

### ステップ4: コード生成

`prompts/setup-prompt.md` の「実行環境の確認」セクションに以下を追加：
- ブランチ確認の指示
- 不一致時の警告メッセージ
- ブランチ切り替え提案の手順

### ステップ5: テスト生成

プロンプトファイルの変更のため、自動テストは不要。
手動検証項目を実装記録に記載。

### ステップ6: 統合とレビュー

- 変更内容の確認
- 実装記録の作成

成果物: `docs/cycles/v1.1.0/construction/units/unit3_branch_check_implementation.md`

## 完了基準

- [x] setup-prompt.md にブランチ確認機能が追加されている
- [ ] 確認ロジックが正しく記述されている
- [ ] 不一致時の警告と提案が含まれている
- [ ] Gitリポジトリでない場合のスキップ処理がある
- [ ] 実装記録が作成されている

## 見積もり

1時間

## 作成日時

2025-11-30
