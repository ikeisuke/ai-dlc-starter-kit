# jj Skill ドメインモデル

## 概要

jj (Jujutsu) の操作をAIスキルとして定義し、AIとの協調作業でバージョン管理を効率化する。

## エンティティ

### JJSkill（値オブジェクト）

jjスキルの定義ファイル。

| 属性 | 型 | 説明 |
|------|------|------|
| name | string | スキル名: "jj" |
| description | string | スキルの説明 |
| argument-hint | string | 引数のヒント |
| allowed-tools | string | 許可されるツール |

## コマンドカテゴリ

スキルでカバーするjjコマンドのカテゴリ。

### 1. 状態確認系（必須）

| コマンド | 説明 | 対応gitコマンド |
|---------|------|-----------------|
| `jj status` | 作業状態確認 | `git status` |
| `jj log` | 履歴表示 | `git log` |
| `jj diff` | 差分表示 | `git diff` |

### 2. コミット操作系（必須）

| コマンド | 説明 | 対応gitコマンド |
|---------|------|-----------------|
| `jj describe` | コミットメッセージ設定 | `git commit --amend` |
| `jj new` | 新しいリビジョン作成 | `git commit` |
| `jj split` | 変更を分離 | `git add -p` |

### 3. ブックマーク操作系（必須）

| コマンド | 説明 | 対応gitコマンド |
|---------|------|-----------------|
| `jj bookmark list` | ブックマーク一覧 | `git branch` |
| `jj bookmark create` | ブックマーク作成 | `git branch <name>` |
| `jj bookmark set` | ブックマーク移動 | - |
| `jj edit` | リビジョン切替 | `git checkout` |

### 4. リモート操作系（必須）

| コマンド | 説明 | 対応gitコマンド |
|---------|------|-----------------|
| `jj git fetch` | リモートから取得 | `git fetch` |
| `jj git push` | リモートへプッシュ | `git push` |

### 5. その他操作（オプション）

| コマンド | 説明 |
|---------|------|
| `jj undo` | 直前の操作を取り消し |
| `jj restore` | ファイル復元 |

## スコープ外

初回スコープでは以下を対象外とする：

- 高度な操作（rebase、squash等）
- コンフリクト解決の詳細
- jj固有の高度な機能（evolog、obslog等）

## 重要な概念

### bookmarkは自動で進まない

jjの最大の特徴として、bookmarkはコミット時に自動で移動しない。Unit完了時に手動で `jj bookmark set` を実行する必要がある。

### co-locationモード

GitとjjがリポジトリLevelで共存するモード。AI-DLCではこのモードを推奨。
