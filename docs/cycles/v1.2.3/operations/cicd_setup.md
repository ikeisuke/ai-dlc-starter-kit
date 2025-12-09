# CI/CD設定

## 概要
- **CI/CDツール**: GitHub Actions
- **設定ファイル**: `.github/workflows/auto-tag.yml`
- **v1.2.3での変更**: なし（前サイクルの設定を継続）

## 自動タグ付けワークフロー

### トリガー
- mainブランチへのpush

### 処理フロー
1. `version.txt` からバージョン番号を読み取り
2. 既存タグの存在確認
3. タグが存在しなければ `v{VERSION}` タグを作成・push

### 設定内容確認
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
1. サイクルブランチで `version.txt` を更新（例: 1.2.3）
2. PRを作成してmainブランチへマージ
3. GitHub Actionsが自動で `v1.2.3` タグを作成

## 将来の検討事項（バックログ）
- Markdownリンター追加
- テンプレート整合性チェック
- PR時の自動レビュー

## 確認結果
- [x] auto-tag.ymlが正常に設定されている
- [x] version.txt → タグ名変換が正しい
- [x] 変更不要
