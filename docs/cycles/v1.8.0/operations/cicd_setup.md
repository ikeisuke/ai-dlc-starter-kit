# CI/CD設定

## 概要

このプロジェクトではGitHub Actionsを使用してCI/CDを実現しています。

## ワークフロー一覧

| ワークフロー | ファイル | トリガー | 目的 |
|-------------|---------|---------|------|
| Auto Tag on Main | `.github/workflows/auto-tag.yml` | main push | 自動タグ作成 |
| PR Check | `.github/workflows/pr-check.yml` | PR (main向け) | Markdownlint |

## 自動タグ付け（auto-tag.yml）

### 動作

1. mainブランチにpushされる
2. `version.txt` からバージョンを読み取る
3. 同名タグが存在しない場合、`v{VERSION}` タグを作成・push

### 設定ポイント

- `fetch-depth: 0` で全履歴を取得（タグ存在確認のため）
- github-actions[bot] ユーザーでタグ作成
- 冪等性: 既存タグがある場合はスキップ

## PRチェック（pr-check.yml）

### 動作

1. main向けのPRで、Markdownファイルに変更がある場合に実行
2. markdownlint-cli2-action を使用してLint実行

### チェック対象

- `docs/translations/**/*.md`
- `prompts/**/*.md`
- `*.md`（ルート直下）

### 除外対象

- `docs/cycles/` 配下（過去サイクルのファイル）
- `docs/aidlc/` 配下（同期されるファイル）

## v1.8.0での変更

- 変更なし（既存設定で問題なし）

## 今後の検討事項

- テンプレート整合性チェック
- セットアップテストの自動化
- リリースノート自動生成
