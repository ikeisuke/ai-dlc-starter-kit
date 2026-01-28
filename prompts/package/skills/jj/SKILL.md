---
name: jj
description: Jujutsu (jj) でバージョン管理操作を実行。Git互換の次世代VCSで、自動追跡・安全なundo・bookmarkベースの管理を提供。
argument-hint: [subcommand] [args]
allowed-tools: Bash(jj:*)
---

# Jujutsu (jj)

Jujutsu (jj) を使用してバージョン管理操作を実行するスキル。

## 重要な注意事項

### bookmarkは自動で進まない

> **Gitとの最大の違い**: jjのbookmarkは手動で移動する必要があります。

| 比較 | Git | jj |
|------|-----|-----|
| ブランチ/bookmark | コミット時に自動でHEADに追従 | **手動で移動が必要** |

**Unit完了時に必ず実行**:

```bash
jj bookmark set cycle/vX.X.X -r @-
```

### co-locationモードの使用

GitとjjをリポジトリLevelで共存させるモードを推奨します。

```bash
# 既存Gitリポジトリでjjを初期化
jj git init --colocate
```

## 状態確認

### 作業状態の確認

```bash
# 現在の状態を確認
jj status
jj st  # 省略形

# 変更の差分を表示
jj diff
```

### 履歴の表示

```bash
# 履歴をグラフ表示
jj log

# 現在のリビジョンのみ
jj log -r @

# 特定のbookmarkを含む履歴
jj log -r 'cycle/vX.X.X'
```

## コミット操作

### コミットメッセージの設定

```bash
# 現在のリビジョンにメッセージを設定
jj describe -m "コミットメッセージ"

# エディタでメッセージを編集
jj describe
```

### 新しいリビジョンの作成

```bash
# 現在の変更を確定し、新しい空のリビジョンを開始
jj new

# 特定のリビジョンから新しいリビジョンを作成
jj new main
jj new cycle/vX.X.X
```

### 変更の分離

```bash
# 現在のリビジョンを対話的に分離
jj split

# 特定ファイルを分離
jj split <file>
```

### 操作の取り消し

```bash
# 直前の操作を取り消し
jj undo

# ファイルを復元
jj restore <file>
```

## ブックマーク操作

### ブックマーク一覧

```bash
# 全ブックマーク一覧
jj bookmark list

# 現在のリビジョンのブックマーク
jj bookmark list -r @
```

### ブックマークの作成・移動

```bash
# 新しいブックマークを作成
jj bookmark create <name>

# ブックマークを特定のリビジョンに移動
jj bookmark set <name> -r <revision>
jj bookmark set cycle/vX.X.X -r @-
```

### ブックマークの削除

```bash
# ローカルブックマークを削除
jj bookmark delete <name>

# 削除をリモートに反映
jj git push --deleted
```

### リビジョンの切り替え

```bash
# 特定のリビジョンを編集
jj edit <revision>

# bookmarkに切り替え
jj edit cycle/vX.X.X
```

## リモート操作

### フェッチ

```bash
# リモートから取得
jj git fetch
```

### プッシュ

```bash
# 現在のbookmarkをプッシュ
jj git push

# 特定のbookmarkをプッシュ
jj git push --bookmark <name>
jj git push --bookmark cycle/vX.X.X

# 削除をプッシュ
jj git push --deleted
```

## Git/jjコマンド対照表

### 状態確認系

| 用途 | Git | jj |
|------|-----|-----|
| 状態確認 | `git status` | `jj status` |
| 差分表示 | `git diff` | `jj diff` |
| 履歴表示 | `git log` | `jj log` |

### コミット操作系

| 用途 | Git | jj |
|------|-----|-----|
| ステージング | `git add` | (自動) |
| コミット | `git commit -m "msg"` | `jj describe -m "msg"` + `jj new` |
| メッセージ修正 | `git commit --amend` | `jj describe -m "msg"` |
| 変更退避 | `git stash` | (不要) |
| 操作取り消し | `git reset` | `jj undo` |

### ブックマーク操作系

| 用途 | Git | jj |
|------|-----|-----|
| ブランチ一覧 | `git branch` | `jj bookmark list` |
| ブランチ作成 | `git branch <name>` | `jj bookmark create <name>` |
| 切り替え | `git checkout <name>` | `jj edit <revision>` |
| ブランチ削除 | `git branch -d <name>` | `jj bookmark delete <name>` |

### リモート操作系

| 用途 | Git | jj |
|------|-----|-----|
| フェッチ | `git fetch` | `jj git fetch` |
| プッシュ | `git push` | `jj git push` |
| プル | `git pull` | `jj git fetch` + `jj rebase -d <bookmark>@origin` |

## 使用例

### 作業開始

```bash
# 状態確認
jj status
jj log -r @

# cycleブックマークから新しいリビジョンを開始
jj new cycle/vX.X.X
```

### 作業中

```bash
# 変更を確認
jj diff

# メッセージを設定
jj describe -m "feat: 新機能追加"
```

### 作業終了（Unit完了時）

```bash
# 1. メッセージを設定
jj describe -m "feat: [vX.X.X] Unit NNN完了"

# 2. 新しいリビジョンを作成
jj new

# 3. bookmarkを進める（重要）
jj bookmark set cycle/vX.X.X -r @-

# 4. プッシュ
jj git push --bookmark cycle/vX.X.X
```

### ワンライナー版

```bash
jj describe -m "feat: [vX.X.X] Unit NNN完了" && jj new && jj bookmark set cycle/vX.X.X -r @- && jj git push --bookmark cycle/vX.X.X
```

## 実行手順

1. ユーザーから依頼内容を受け取る
2. jjがインストールされていることを確認（`jj --version`）
3. リポジトリがjjで初期化されていることを確認（`.jj`ディレクトリの存在）
4. 上記コマンド形式でjjを実行
5. 結果をユーザーに報告

## 参考リンク

- [jj 公式ドキュメント](https://martinvonz.github.io/jj/latest/)
- [Git comparison](https://martinvonz.github.io/jj/latest/git-comparison/)
- 詳細ガイド: `docs/aidlc/guides/jj-support.md`
