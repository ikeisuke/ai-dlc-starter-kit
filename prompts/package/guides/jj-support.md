# jj（Jujutsu）サポートガイド

> **実験的機能**: このガイドは実験的な機能として提供しています。jjはGitと互換性がありますが、AI-DLCのプロンプト本体はGitコマンドを使用しています。このガイドはjjを試したい開発者向けの補助資料です。

## 概要

jj（Jujutsu）は、Gitと互換性のある次世代バージョン管理システムです。自動コミット、操作の簡単な取り消し、安全なrebaseなど、開発者体験を向上させる機能を備えています。

**対象読者**: jjを試したい開発者、Gitに慣れているがjjの利点に興味がある人

---

## 前提条件

### jjのインストール

jjのインストール方法は公式ドキュメントを参照してください。

```bash
# macOS (Homebrew)
brew install jj

# その他のプラットフォーム
# https://martinvonz.github.io/jj/latest/install-and-setup/
```

### Gitリポジトリとの共存設定（colocate）

AI-DLCプロジェクトでjjを使用する場合は、colocateモードを推奨します。これによりGitとjjが同じリポジトリで共存できます。

```bash
# 既存のGitリポジトリでjjを初期化
cd your-project
jj git init --git-repo=.
```

```bash
# 新規リポジトリの場合
jj git init --colocate
```

---

## jjの特徴と利点

AI-DLC開発に関連するjjの主要な特徴:

| 特徴 | 説明 | AI-DLCでの利点 |
|------|------|---------------|
| **自動コミット** | ワーキングコピーの変更が自動的に追跡される | stash不要、作業中断が容易 |
| **操作の取り消し** | `jj undo` であらゆる操作を簡単に取り消せる | 実験的な変更が安全にできる |
| **Git互換** | colocateモードで既存Gitリポジトリで使用可能 | 段階的な導入が可能、チームの一部だけが使用可能 |
| **コンフリクトの保存** | マージコンフリクトを解決せずにコミットとして保存可能 | 複雑なマージ作業を中断可能 |
| **匿名ブランチ** | ブランチ名を考えずに作業開始可能 | サイクルごとのブランチ管理が簡素化 |
| **安全なrebase** | 履歴書き換えが安全に行える、元に戻しやすい | 履歴整理が容易 |

---

## Git/jjコマンド対照表

> **注意**: jj 0.22以降では `branch` コマンドが `bookmark` に改名されています。古いバージョンを使用している場合は `branch` を使用してください。

### 状態確認系

| 用途 | Git コマンド | jj コマンド | 備考 |
|------|-------------|------------|------|
| 状態確認 | `git status` | `jj status` または `jj st` | |
| 差分表示 | `git diff` | `jj diff` | |
| 履歴表示 | `git log` | `jj log` | デフォルトでグラフ表示 |

### ブックマーク操作系

| 用途 | Git コマンド | jj コマンド | 備考 |
|------|-------------|------------|------|
| ブックマーク一覧 | `git branch` | `jj bookmark list` | |
| 現在リビジョンのブックマーク | `git branch --show-current` | `jj bookmark list -r @` | |
| ブックマーク作成・切替 | `git checkout -b <name>` | `jj new` + `jj bookmark create <name>` | 2ステップで実行 |
| リビジョン切替 | `git checkout <name>` | `jj edit <revision>` | |
| ブックマーク削除 | `git branch -d <name>` | `jj bookmark delete <name>` | |

### コミット操作系

| 用途 | Git コマンド | jj コマンド | 備考 |
|------|-------------|------------|------|
| ステージング | `git add` | (自動) | jjでは自動追跡 |
| コミット | `git commit -m "msg"` | `jj commit -m "msg"` | |
| コミットメッセージ編集 | `git commit --amend` | `jj describe -m "msg"` | 現在のリビジョンを編集 |
| 変更退避 | `git stash` | (不要) | ワーキングコピーが自動保存 |
| 操作取り消し | `git reset` | `jj undo` | より安全 |

### リモート操作系

| 用途 | Git コマンド | jj コマンド | 備考 |
|------|-------------|------------|------|
| リモートへプッシュ | `git push` | `jj git push` | |
| 特定ブックマークをプッシュ | `git push -u origin <branch>` | `jj git push --bookmark <name>` | |
| リモートから取得 | `git pull` | `jj git fetch` + `jj rebase` | 2ステップで実行 |
| タグ作成 | `git tag -a <tag> -m "msg"` | `git tag -a <tag> -m "msg"` | colocateでGit直接使用 |
| タグプッシュ | `git push --tags` | `jj git push --all` | |

---

## AI-DLCワークフローでの使用方法

### Setup Phase

サイクルブックマークの作成:

```bash
# mainから新しいリビジョンを作成
jj new main

# サイクルブックマークを作成
jj bookmark create cycle/vX.X.X

# リモートにプッシュ
jj git push --bookmark cycle/vX.X.X
```

### Inception Phase

ブックマークの確認と切り替え:

```bash
# ブックマーク一覧を確認
jj bookmark list

# サイクルブックマークに切り替え
jj edit cycle/vX.X.X
# または新しいリビジョンとして作業開始
jj new cycle/vX.X.X
```

### Construction Phase

コミットの作成とプッシュ:

```bash
# 作業を行った後、コミットメッセージを設定
jj describe -m "chore: [vX.X.X] レビュー前 - 成果物名"

# 新しいリビジョンを作成（次の作業用）
jj new

# リモートにプッシュ
jj git push
```

レビュー後の修正:

```bash
# 修正を行った後
jj describe -m "chore: [vX.X.X] レビュー反映 - 成果物名"
jj new
jj git push
```

### Operations Phase

タグの作成（colocateモードでGitを直接使用）:

```bash
# Gitでタグを作成
git tag -a vX.X.X -m "Release vX.X.X"

# jjでプッシュ
jj git push --all
```

mainへのマージ（GitHub PR経由を推奨）:

```bash
# PRが承認された後、GitHub上でマージ

# または jj でリベース後プッシュ（直接マージする場合）
jj rebase -d main
jj bookmark set main -r @
jj git push --bookmark main
```

---

## 注意事項と制限

### 実験的機能について

- このガイドは実験的な機能として提供しています
- AI-DLCのプロンプト本体（`prompts/package/prompts/`）のGitコマンドは変更されません
- jjを使用する場合は、このガイドを参照してGitコマンドを読み替えてください

### Git互換性に関する注意

- colocateモードを使用することで、Gitユーザーとjjユーザーが同じリポジトリで作業できます
- タグ操作など一部の機能はGitを直接使用します
- チーム全員がjjを使う必要はありません

### バージョン差異

- jj 0.22以降: `branch` → `bookmark` に改名
- 古いバージョンを使用している場合は `bookmark` を `branch` に読み替えてください

### AI-DLCプロンプトとの関係

- プロンプト内のGitコマンドはそのまま残ります（自動変換なし）
- このガイドはあくまで補助資料として、jjユーザーが読み替えるために使用します

---

## 参考リンク

- [jj 公式ドキュメント](https://martinvonz.github.io/jj/latest/)
- [jj GitHub リポジトリ](https://github.com/martinvonz/jj)
- [Git comparison - jjでのGitコマンド対応](https://martinvonz.github.io/jj/latest/git-comparison/)
