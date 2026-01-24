# CI/CD設定

## 概要

このプロジェクトはGitHub Actionsを使用してCI/CDを実装しています。

## ワークフロー一覧

### 1. 自動タグ付け（auto-tag.yml）

- **トリガー**: mainブランチへのpush
- **処理内容**:
  1. version.txtからバージョンを読み取り
  2. 同名タグが存在しなければ `v{VERSION}` タグを作成
  3. タグをリモートにpush

### 2. PRチェック（pr-check.yml）

- **トリガー**: PRの作成・更新
- **処理内容**:
  1. Markdownlintによる構文チェック
  2. 対象: `docs/translations/**/*.md`, `prompts/**/*.md`, `*.md`

## v1.9.1での変更

CI/CD設定に変更なし。既存の設定を継続使用。

## 確認事項

- [x] auto-tag.yml が存在する
- [x] pr-check.yml が存在する
- [x] 前回リリース（v1.9.0）でCI/CDが正常動作した
