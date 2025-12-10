# CI/CD設定

## 概要

v1.3.0 では既存のCI/CD設定をそのまま使用する。変更は不要。

## 現状のCI/CD設定

### 自動タグ付けワークフロー

- **ファイル**: `.github/workflows/auto-tag.yml`
- **トリガー**: mainブランチへのpush
- **処理内容**:
  1. `version.txt` からバージョンを読み取り
  2. 同名タグが存在しなければ `v{VERSION}` タグを作成・push

### ワークフロー詳細

```yaml
name: Auto Tag on Main
on:
  push:
    branches:
      - main
permissions:
  contents: write
jobs:
  auto-tag:
    runs-on: ubuntu-latest
    steps:
      - Checkout（fetch-depth: 0）
      - Read version（version.txtから読み取り）
      - Check if tag exists（既存タグ確認）
      - Create and push tag（タグ作成・push）
```

## リリースフロー

1. サイクルブランチで `version.txt` を更新（例: 1.3.0）
2. Operations Phase完了コミット
3. PRを作成（`gh pr create`）
4. PRをマージ
5. GitHub Actionsが自動で `v1.3.0` タグを作成

## 将来検討事項

operations.md に記載の将来検討事項:
- Markdownリンター（markdownlint）
- テンプレート整合性チェック
- PR時の自動レビュー

v1.3.0 ではこれらは対象外。

## 備考

- 前回サイクル（v1.2.2）で構築済み
- 正常に動作していることを確認済み
