# CI/CD設定

## 概要

サイクル v1.5.2 では、既存の CI/CD 設定を継続使用します。

## 現在の設定

### 自動タグ付けワークフロー

**ファイル**: `.github/workflows/auto-tag.yml`

**トリガー**: main ブランチへの push

**動作**:
1. version.txt からバージョン番号を読み取り
2. 同名タグが存在するか確認
3. 存在しなければ `v{VERSION}` タグを作成・push

**設定内容**:
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
      - Checkout (fetch-depth: 0)
      - Read version from version.txt
      - Check if tag exists
      - Create and push tag (if not exists)
```

## リリースフロー

1. サイクルブランチ（cycle/v1.5.2）で開発
2. version.txt を `1.5.2` に更新（完了済み）
3. Operations Phase 完了コミット
4. main ブランチへの PR を作成
5. PR をマージ
6. GitHub Actions が自動で `v1.5.2` タグを作成

## v1.5.2 での変更

なし（既存設定を継続使用）

## 将来の検討事項

運用引き継ぎ情報より:
- Markdown リンター（markdownlint）
- テンプレート整合性チェック
- PR 時の自動レビュー

これらは今後のサイクルで検討予定。
