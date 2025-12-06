# CI/CD設定

## 概要

このプロジェクトでは GitHub Actions を使用した CI/CD を構築しています。

## 既存のワークフロー

### 自動タグ付け（auto-tag.yml）

- **ファイル**: `.github/workflows/auto-tag.yml`
- **トリガー**: mainブランチへのpush
- **動作**:
  1. `version.txt` からバージョンを読み取り
  2. 同名のタグが存在しなければ `v{VERSION}` タグを作成・push

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
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Read version
        id: version
        run: |
          VERSION=$(cat version.txt | tr -d '\n\r ')
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "tag=v$VERSION" >> $GITHUB_OUTPUT

      - name: Check if tag exists
        id: check
        run: |
          if git tag -l "${{ steps.version.outputs.tag }}" | grep -q .; then
            echo "exists=true" >> $GITHUB_OUTPUT
          else
            echo "exists=false" >> $GITHUB_OUTPUT
          fi

      - name: Create and push tag
        if: steps.check.outputs.exists == 'false'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git tag ${{ steps.version.outputs.tag }}
          git push origin ${{ steps.version.outputs.tag }}
```

## リリースフロー

1. サイクルブランチで開発
2. `version.txt` を新バージョンに更新
3. mainブランチへマージ（PRまたはローカルマージ）
4. GitHub Actionsが自動で `v{VERSION}` タグを作成
5. 必要に応じてGitHub Releasesでリリースノート作成

## 将来の拡張検討

| 項目 | 説明 | 優先度 |
|------|------|--------|
| Markdownリンター | markdownlint によるフォーマットチェック | 低 |
| テンプレート整合性チェック | prompts/ と docs/aidlc/ の同期確認 | 中 |
| PR自動レビュー | 変更ファイルの自動チェック | 低 |

## 備考

- 現時点ではドキュメントプロジェクトのため、自動タグ付けのみで十分
- 必要に応じて拡張を検討
