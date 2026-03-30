# CI/CD設定 - v1.8.1

## 概要

このプロジェクトのCI/CDはGitHub Actionsで構築されています。v1.8.1では既存の設定をそのまま使用します。

## 現状のCI/CDワークフロー

### 1. 自動タグ付け（auto-tag.yml）

**ファイル**: `.github/workflows/auto-tag.yml`

**トリガー**: mainブランチへのpush

**処理内容**:
1. version.txt からバージョン番号を読み取り
2. 同名タグの存在確認
3. 存在しなければ `v{VERSION}` タグを作成・push

**フロー**:
```
mainブランチにマージ
    ↓
version.txt を読み取り（例: 1.8.1）
    ↓
v1.8.1 タグが存在するか確認
    ↓
存在しない → v1.8.1 タグを作成・push
存在する → スキップ
```

### 2. PRチェック（pr-check.yml）

**ファイル**: `.github/workflows/pr-check.yml`

**トリガー**: mainブランチへのPRで、以下のファイルが変更された場合
- `**.md`
- `.markdownlint.json`
- `.github/workflows/pr-check.yml`

**処理内容**:
- Markdownlintによる自動チェック

**対象ファイル**:
- `docs/translations/**/*.md`
- `prompts/**/*.md`
- `*.md`

## v1.8.1での変更

**変更なし** - 既存のCI/CD設定をそのまま使用

## 将来検討事項

- テンプレート整合性チェックの自動化
- セットアップテストの自動化
