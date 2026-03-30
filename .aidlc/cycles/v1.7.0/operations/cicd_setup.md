# CI/CD設定

## 概要

v1.7.0では既存のCI/CD設定を継続使用。変更なし。

## 現在の設定

### 1. 自動タグ付け（auto-tag.yml）

- **トリガー**: mainブランチへのpush
- **動作**: version.txtからバージョンを読み取り、同名タグが存在しなければ作成・push

```yaml
on:
  push:
    branches:
      - main
```

### 2. PRチェック（pr-check.yml）

- **トリガー**: mainブランチへのPR（Markdownファイル変更時）
- **動作**: markdownlint-cli2でMarkdownリント実行

対象ファイル:
- `docs/translations/**/*.md`
- `prompts/**/*.md`
- `*.md`

## v1.7.0での変更

なし（既存設定を継続）

## 将来の検討事項

- テンプレート整合性チェックの自動化
- セットアップテストの自動化（別ディレクトリでクローン・セットアップ）
