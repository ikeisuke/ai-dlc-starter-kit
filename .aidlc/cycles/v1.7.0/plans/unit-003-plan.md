# Unit 003 計画: バックログ用Issueテンプレート

作成日時: 2026-01-11 01:11:43 JST

## 概要

GitHub Issuesを使ったバックログ管理を可能にするため、Issueテンプレートを整備する。

## 責務

1. `prompts/package/.github/ISSUE_TEMPLATE/` ディレクトリの作成
2. バックログ用テンプレート（`backlog.md`）の作成
3. バグ報告用テンプレート（`bug.md`）の作成
4. 機能要望用テンプレート（`feature.md`）の作成
5. スターターキットセットアップ時に `.github/` をプロジェクトルートへコピーする処理追加
6. 既存の `.github/` がある場合の保護処理（上書き防止、マージまたはユーザー確認）

## Phase 1: 設計（コードは書かない）

### ステップ1: ドメインモデル設計

- **成果物**: `docs/cycles/v1.7.0/design-artifacts/domain-models/003-backlog-issue-templates_domain_model.md`
- **内容**:
  - Issueテンプレートの構成要素定義
  - 各テンプレートの責務と関係性
  - セットアップフローとの統合点

### ステップ2: 論理設計

- **成果物**: `docs/cycles/v1.7.0/design-artifacts/logical-designs/003-backlog-issue-templates_logical_design.md`
- **内容**:
  - テンプレートファイルの配置設計
  - セットアッププロンプトへの追加処理設計
  - 既存ファイル保護ロジック設計

### ステップ3: 設計レビュー

- ユーザー承認を得る

## Phase 2: 実装

### ステップ4: コード生成

- `prompts/package/.github/ISSUE_TEMPLATE/backlog.md` 作成
- `prompts/package/.github/ISSUE_TEMPLATE/bug.md` 作成
- `prompts/package/.github/ISSUE_TEMPLATE/feature.md` 作成
- `prompts/setup-prompt.md` に `.github/` コピー処理追加

### ステップ5: テスト生成

- このUnitはMarkdownテンプレートとシェルスクリプトのみのため、コード単体テストは不要
- 動作確認はドライラン形式で実施

### ステップ6: 統合とレビュー

- 成果物の整合性確認
- ユーザーレビュー
- 実装記録作成

## 成果物一覧

| フェーズ | 成果物 |
|---------|--------|
| 設計 | ドメインモデル設計書 |
| 設計 | 論理設計書 |
| 実装 | `prompts/package/.github/ISSUE_TEMPLATE/backlog.md` |
| 実装 | `prompts/package/.github/ISSUE_TEMPLATE/bug.md` |
| 実装 | `prompts/package/.github/ISSUE_TEMPLATE/feature.md` |
| 実装 | `prompts/setup-prompt.md` 更新（コピー処理追加） |
| 実装 | 実装記録 |
