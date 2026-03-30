# Unit: CI/CD構築

## 概要
GitHub ActionsでCI/CDパイプラインを構築し、PRに対してMarkdownリンターを自動実行する。

## 含まれるユーザーストーリー
- ストーリー 3.1: CI/CD構築

## 責務
- GitHub Actionsワークフローの作成
- Markdownリンターの設定
- PRへのリンター結果コメント

## 境界
- デプロイ自動化は含まない
- テスト自動化は含まない（ドキュメントプロジェクトのため）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub Actions
- markdownlint または同等のリンター

## 非機能要件（NFR）
- **パフォーマンス**: PRごとに数秒〜数十秒で完了
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: GitHub Actions の可用性に依存

## 技術的考慮事項

### ワークフロー構成
```yaml
name: PR Check

on:
  pull_request:
    branches: [main]

jobs:
  markdown-lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run markdownlint
        uses: DavidAnson/markdownlint-cli2-action@v14
        with:
          globs: '**/*.md'
```

### リンター設定
- .markdownlint.json または .markdownlint.yaml で設定
- プロジェクト固有のルールを設定可能

### PRコメント
- リンターエラーがある場合、PRにコメントとして結果を投稿
- エラーがない場合は成功ステータスのみ

## 対象ファイル
- .github/workflows/pr-check.yml (新規作成)
- .markdownlint.json (新規作成)

## 実装優先度
Medium

## 見積もり
GitHub Actionsワークフローとリンター設定の作成

---
## 実装状態

- **状態**: 完了
- **開始日**: 2025-12-31
- **完了日**: 2025-12-31
- **担当**: -
