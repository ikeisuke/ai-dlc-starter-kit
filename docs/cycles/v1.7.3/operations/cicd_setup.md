# CI/CD設定 - v1.7.3

## 概要

このプロジェクトはGitHub Actionsを使用してCI/CDを実現しています。

## ワークフロー一覧

| ワークフロー | ファイル | トリガー | 目的 |
|-------------|---------|---------|------|
| Auto Tag on Main | auto-tag.yml | mainへのpush | 自動タグ付け |
| PR Check | pr-check.yml | PRオープン・更新 | Markdownlint |

## 自動タグ付け（auto-tag.yml）

### 動作

1. mainブランチにpush
2. `version.txt` からバージョンを読み取り
3. 同名タグが存在しなければ `v{VERSION}` タグを作成・push

### 設定詳細

```yaml
on:
  push:
    branches:
      - main
```

### 注意事項

- version.txtの更新を忘れるとタグが作成されない
- 既存タグと同名の場合はスキップされる

## PRチェック（pr-check.yml）

### 動作

1. PRがオープン・更新される
2. 対象ファイルが変更されている場合のみ実行
3. Markdownlintでチェック

### 対象ファイル

```yaml
paths:
  - '**.md'
  - '.markdownlint.json'
  - '.github/workflows/pr-check.yml'

globs:
  - docs/translations/**/*.md
  - prompts/**/*.md
  - *.md
```

### 除外されるファイル

- `docs/aidlc/**/*.md` - AI-DLCプロンプト・テンプレート（rsyncで同期）
- `docs/cycles/**/*.md` - サイクル成果物（過去履歴含む）

### 注意事項

- lintエラーがあるとPRがマージできない
- ローカルでの事前チェック推奨: `npx markdownlint-cli2 "docs/**/*.md" "prompts/**/*.md" "*.md"`

## v1.7.3での変更

- なし（既存設定を維持）

## 将来検討事項

- テンプレート整合性チェックの追加
- セットアップテストの自動化
