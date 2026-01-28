---
name: gh
description: GitHub CLI (gh) を使用したIssue、PR、リリースの操作を実行する。使用場面: (1) Issue操作（作成、一覧、表示、クローズ）、(2) PR操作（作成、一覧、表示、マージ）、(3) リリース操作（作成、一覧）、(4) GitHub APIへのアクセス。トリガー: "gh", "github", "issue", "pr", "release", "/gh"
---

# GitHub CLI (gh)

GitHub CLI (gh) を使用してIssue、PR、リリースなどのGitHub操作を実行するスキル。

## 認証に関する注意事項

GitHub CLIを使用する前に、認証が完了していることを確認してください。

```bash
# 認証状態の確認
gh auth status

# 認証が必要な場合
gh auth login
```

## Issue操作

### Issue一覧の取得

```bash
# オープンなIssue一覧
gh issue list

# 特定のラベルでフィルタ
gh issue list --label "bug"

# 自分にアサインされたIssue
gh issue list --assignee "@me"

# 状態を指定（open/closed/all）
gh issue list --state all
```

### Issueの表示

```bash
# Issue番号で表示
gh issue view 123

# Web UIで開く
gh issue view 123 --web
```

### Issueの作成

```bash
# 対話形式で作成
gh issue create

# タイトルと本文を指定
gh issue create --title "タイトル" --body "本文"

# テンプレートを使用
gh issue create --template "bug_report.md"
```

### Issueのクローズ

```bash
# Issueをクローズ
gh issue close 123

# コメント付きでクローズ
gh issue close 123 --comment "対応完了"
```

## PR操作

### PR一覧の取得

```bash
# オープンなPR一覧
gh pr list

# 自分が作成したPR
gh pr list --author "@me"

# レビュー待ちのPR（レビューが必要なもの）
gh pr list --search "review:required"
```

### PRの表示

```bash
# PR番号で表示
gh pr view 456

# 現在のブランチに紐づくPR
gh pr view

# Web UIで開く
gh pr view 456 --web
```

### PRの作成

```bash
# 対話形式で作成
gh pr create

# タイトルと本文を指定
gh pr create --title "タイトル" --body "本文"

# ドラフトPRとして作成
gh pr create --draft

# ベースブランチを指定
gh pr create --base main

# レビュワーを指定
gh pr create --reviewer "username"
```

### PRのマージ

```bash
# 通常マージ
gh pr merge 456

# Squashマージ
gh pr merge 456 --squash

# Rebaseマージ
gh pr merge 456 --rebase

# マージ後にブランチを削除
gh pr merge 456 --delete-branch
```

### PRの状態変更

```bash
# ドラフトをレディに変更
gh pr ready 456

# PRをクローズ
gh pr close 456
```

## リリース操作

### リリース一覧の取得

```bash
# リリース一覧
gh release list

# 最新リリースの情報（タグ省略で最新を表示）
gh release view
```

### リリースの作成

```bash
# タグを指定してリリース作成
gh release create v1.0.0

# タイトルとノートを指定
gh release create v1.0.0 --title "リリース名" --notes "リリースノート"

# ドラフトとして作成
gh release create v1.0.0 --draft

# アセットを添付
gh release create v1.0.0 ./dist/*.zip
```

### リリースアセットのダウンロード

```bash
# 最新リリースのアセットをダウンロード（パターン指定が必要）
gh release download --pattern "*.zip"

# 特定のタグからダウンロード
gh release download v1.0.0
```

## API操作

```bash
# REST APIを直接呼び出し
gh api repos/{owner}/{repo}/issues

# GraphQL API
gh api graphql -f query='...'
```

## 使用例

### 新しいバグ報告Issueを作成

```bash
gh issue create --title "[Bug] ログイン画面でエラー" --body "再現手順: ..." --label "bug"
```

### PRを作成してレビュー依頼

```bash
gh pr create --title "feat: 新機能追加" --body "## 概要\n..." --reviewer "reviewer-name"
```

### リリースを作成してアセットを添付

```bash
gh release create v1.2.0 --title "v1.2.0" --notes "新機能と改善" ./dist/app.zip
```

## 実行手順

1. ユーザーから依頼内容を受け取る
2. リポジトリのディレクトリにいることを確認（または `--repo owner/repo` を指定）
3. 上記コマンド形式でghを実行
4. 結果をユーザーに報告
