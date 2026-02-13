# Git/jjコマンド対照表

## 状態確認系

| 用途 | Git | jj |
|------|-----|-----|
| 状態確認 | `git status` | `jj status` |
| 差分表示 | `git diff` | `jj diff` |
| 履歴表示 | `git log` | `jj log` |

## コミット操作系

| 用途 | Git | jj |
|------|-----|-----|
| ステージング | `git add` | (自動) |
| コミット | `git commit -m "msg"` | `jj describe -m "msg"` + `jj new` |
| メッセージ修正 | `git commit --amend` | `jj describe -m "msg"` |
| 変更退避 | `git stash` | (不要) |
| 操作取り消し | `git reset` | `jj undo` |

## ブックマーク操作系

| 用途 | Git | jj |
|------|-----|-----|
| ブランチ一覧 | `git branch` | `jj bookmark list` |
| ブランチ作成 | `git branch <name>` | `jj bookmark create <name>` |
| 切り替え | `git checkout <name>` | `jj edit <revision>` |
| ブランチ削除 | `git branch -d <name>` | `jj bookmark delete <name>` |

## リモート操作系

| 用途 | Git | jj |
|------|-----|-----|
| フェッチ | `git fetch` | `jj git fetch` |
| プッシュ | `git push` | `jj git push` |
| プル | `git pull` | `jj git fetch` + `jj rebase -d <bookmark>@origin` |
