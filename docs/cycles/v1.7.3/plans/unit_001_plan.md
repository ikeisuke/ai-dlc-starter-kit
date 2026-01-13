# Unit 001: ドキュメント整合性修正 - 計画

## 概要

バックログに蓄積されたドキュメントの整合性問題（6つのIssue）を一括で修正する。

## 対象Issue

| Issue | タイトル | 対応方針 |
|-------|----------|----------|
| #55 | setup.mdのステップ番号を連番に整理 | ステップ番号を1から連番に修正 |
| #54 | post_release_operations.mdに記載漏れ | Issueテンプレート追加を追記 |
| #53 | deployment_checklist.mdのlint対象がCIと不整合 | チェックリストをCIに合わせる |
| #52 | cicd_setup.mdのYAML抜粋が実ファイルと不一致 | 「抜粋」であることを明示 |
| #51 | aidlc.tomlのコメント内バージョン番号が古い | コメント行を削除 |
| #50 | ドラフトPR表記の簡素化 | [Draft]プレフィックス削除、説明文簡素化 |

## 重要な制約

**メタ開発の意識**: このプロジェクトは「AI-DLCスターターキットを使って、AI-DLCスターターキット自体を開発している」

- `docs/aidlc/` は `prompts/package/` の rsync コピー（直接編集禁止）
- プロンプト・テンプレートの修正は必ず `prompts/package/` を編集すること
- 変更は Operations Phase の rsync で反映される

## Phase 1: 設計

### ステップ1: ドメインモデル設計

このUnitはドキュメント修正のみであり、ドメインロジックを含まないため、ドメインモデル設計は省略可能。

### ステップ2: 論理設計

各Issueの修正内容を論理的に整理する。

**修正対象ファイルの整理**:

| Issue | 修正対象（ソース） | 備考 |
|-------|-------------------|------|
| #55 | `prompts/package/prompts/setup.md` | ステップ番号の連番化 |
| #55 | `prompts/package/prompts/inception.md` | 完了時作業のステップ番号整理 |
| #54 | `docs/cycles/v1.7.2/operations/post_release_operations.md` | 過去サイクル成果物（直接編集可） |
| #53 | `prompts/package/templates/deployment_checklist_template.md` | テンプレート修正 |
| #52 | `prompts/package/templates/cicd_setup_template.md` | テンプレート修正（存在確認必要） |
| #51 | `prompts/package/prompts/setup-prompt.md` | テンプレート生成部分修正 |
| #50 | `prompts/package/prompts/inception.md` | ドラフトPR作成セクション修正 |
| #50 | `prompts/package/prompts/operations.md` | Ready化セクション修正 |

### ステップ3: 設計レビュー

設計内容をユーザーに提示し、承認を得る。

## Phase 2: 実装

### ステップ4: コード生成

各Issueに対応するドキュメント修正を実施。

### ステップ5: テスト生成

Markdownlint実行で構文エラーがないことを確認。

### ステップ6: 統合とレビュー

- ビルド/lint実行
- 実装記録作成
- AIレビュー実施

## 完了条件

- [ ] #55: setup.mdのステップ番号が連番になっている
- [ ] #55: inception.mdの完了時作業のステップ番号が連番になっている
- [ ] #54: post_release_operations.mdにIssueテンプレート追加が記載されている
- [ ] #53: deployment_checklist.mdのlint対象がCIと一致している
- [ ] #52: cicd_setup.mdに「抜粋」表記が追加されている
- [ ] #51: aidlc.tomlのコメント行が削除されている
- [ ] #50: inception.mdのドラフトPR作成から[Draft]プレフィックスが削除されている
- [ ] #50: operations.mdのReady化セクションからタイトル変更処理が削除されている
- [ ] Markdownlintがパスする
- [ ] 関連する6つのIssueがCloseされている
