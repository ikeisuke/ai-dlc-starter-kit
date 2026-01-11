# ドメインモデル: jj基本ワークフロー

## 概要

jj（Jujutsu）を使用したAI-DLC開発ワークフローのガイドドキュメントの構成要素を定義する。

**重要**: このUnit はドキュメント作成タスクのため、エンティティ・集約等の従来のDDD要素ではなく、ドキュメントの構成要素として整理する。

---

## ドキュメント構成要素

### 1. jjの特徴と利点

AI-DLC開発に関連するjjの主要な特徴（5項目以上）:

| 特徴 | 説明 | AI-DLCでの利点 |
|------|------|---------------|
| 自動コミット（ワーキングコピー） | 変更が自動的にコミットとして追跡される | stash不要、作業中断が容易 |
| 操作の取り消し（`jj undo`） | あらゆる操作を簡単に取り消せる | 実験的な変更が安全にできる |
| Git互換（colocate） | 既存Gitリポジトリでそのまま使用可能 | 段階的な導入が可能 |
| コンフリクトの保存 | マージコンフリクトを解決せずに保存可能 | 複雑なマージ作業を中断可能 |
| 匿名ブランチ | ブランチ名を考えずに作業開始可能 | サイクルごとのブランチ管理が簡素化 |
| 安全なrebase | 履歴書き換えが安全に行える | 履歴整理が容易 |

### 2. Git/jjコマンド対照表

AI-DLCワークフローで使用するGitコマンドとjj対応（10件以上）:

**注意**: jj 0.22以降では `branch` が `bookmark` に改名されています。

| 用途 | Git コマンド | jj コマンド | 備考 |
|------|-------------|------------|------|
| 状態確認 | `git status` | `jj status` または `jj st` | |
| 差分表示 | `git diff` | `jj diff` | |
| 履歴表示 | `git log` | `jj log` | デフォルトでグラフ表示 |
| ブックマーク一覧 | `git branch` | `jj bookmark list` | |
| 現在リビジョンのブックマーク | `git branch --show-current` | `jj bookmark list -r @` | |
| ブックマーク作成・切替 | `git checkout -b <name>` | `jj new` + `jj bookmark create <name>` | 段階的に実行 |
| リビジョン切替 | `git checkout <name>` | `jj edit <revision>` | |
| 変更のステージング | `git add` | (自動) | jjでは自動追跡 |
| コミット | `git commit` | `jj commit` または `jj describe` | |
| 変更退避 | `git stash` | (不要) | ワーキングコピーが自動保存 |
| リモートへプッシュ | `git push` | `jj git push` | |
| リモートから取得 | `git pull` | `jj git fetch` + `jj rebase` | |
| タグ作成 | `git tag -a` | Git操作を使用 | colocateモードでgit tagを直接使用 |
| タグプッシュ | `git push --tags` | `jj git push --all` | |
| 操作取り消し | `git reset` | `jj undo` | より安全 |
| ブックマーク削除 | `git branch -d` | `jj bookmark delete` | |

### 3. AI-DLCワークフロー互換性

各フェーズでの使用方法:

#### Setup Phase
- サイクルブックマーク作成:
  ```text
  jj new main
  jj bookmark create cycle/vX.X.X
  jj git push --bookmark cycle/vX.X.X
  ```

#### Inception Phase
- ブックマーク存在確認: `jj bookmark list` で確認
- リビジョン切り替え: `jj edit <bookmark>` または `jj new <bookmark>`

#### Construction Phase
- コミット作成:
  ```text
  jj describe -m "chore: [vX.X.X] レビュー前 - 成果物名"
  jj new
  ```
- プッシュ: `jj git push`
- レビュー後の修正があった場合:
  ```text
  jj describe -m "chore: [vX.X.X] レビュー反映 - 成果物名"
  jj new
  jj git push
  ```

#### Operations Phase
- タグ作成: colocateモードでGitのタグ機能を直接使用
  ```text
  git tag -a vX.X.X -m "Release vX.X.X"
  jj git push --all
  ```
- mainへのマージ: GitHub PR経由でマージ（推奨）
  - または jj でリベース後プッシュ:
    ```text
    jj rebase -d main
    jj bookmark set main -r @
    jj git push --bookmark main
    ```

---

## ユビキタス言語

- **jj (Jujutsu)**: Gitと互換性のある次世代バージョン管理システム
- **colocate**: jjとGitが同じリポジトリで共存するモード
- **リビジョン (revision)**: jjにおけるコミットに相当する概念
- **ワーキングコピー (@)**: 現在編集中のリビジョン（自動保存される）
- **ブックマーク**: jjにおけるブランチに相当する概念

---

## 不明点と質問（設計中に記録）

（なし - バックログと参考資料から要件が明確）

---

作成日: 2026-01-11
