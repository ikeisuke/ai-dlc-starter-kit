# jj（Jujutsu）サポートガイド

> **実験的機能**: このガイドは実験的な機能として提供しています。jjはGitと互換性がありますが、AI-DLCのプロンプト本体はGitコマンドを使用しています。このガイドはjjを試したい開発者向けの補助資料です。

## 概要

jj（Jujutsu）は、Gitと互換性のある次世代バージョン管理システムです。自動コミット、操作の簡単な取り消し、安全なrebaseなど、開発者体験を向上させる機能を備えています。

**対象読者**: jjを試したい開発者、Gitに慣れているがjjの利点に興味がある人

---

## ⚠️ 重要: bookmarkは自動で進まない

> **Gitとの最大の違い**: jjのbookmarkは手動で移動する必要があります。

| 比較 | Git | jj |
|------|-----|-----|
| ブランチ/bookmark | コミット時に自動でHEADに追従 | **手動で移動が必要** |

**AI-DLCでの影響**:

Unit完了時に `jj bookmark set` を忘れると、cycle bookmarkが古いままになり、次のUnit開始時やPR作成時に問題が発生します。

**必須対策**:

Unit完了時に **必ず** 以下のコマンドを実行してください:

```bash
jj bookmark set cycle/vX.X.X -r @-
```

**補助設定**:

`auto-local-bookmark` を有効にすると、リモート同期時の混乱を減らせます（下記「推奨設定」参照）。ただし、これはbookmark自動追従ではないため、上記コマンドは引き続き必要です。

---

## 推奨設定

jjをAI-DLCで使用する際の推奨設定です。

### auto-local-bookmark の有効化

`.jj/config.toml`（リポジトリローカル）または `~/.config/jj/config.toml`（グローバル）に以下を追加:

```toml
[git]
auto-local-bookmark = true
```

**効果**:

- `jj git fetch` 時にリモートブランチに対応するローカルbookmarkを自動作成
- リモートとの同期が容易になる

**注意**: この設定はbookmarkの自動作成であり、自動追従ではありません。Unit完了時の `jj bookmark set` は引き続き必要です。

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
# 既存のGitリポジトリでjjを初期化（jj 0.21以降）
cd your-project
jj git init --colocate

# または（古いバージョン）
jj git init --git-repo=.
```

```bash
# 新規リポジトリの場合
jj git init --colocate
```

> **ヒント**: jjのバージョンにより初期化コマンドが異なる場合があります。詳細は公式ドキュメントを参照してください。

---

## gitとjjの考え方の違い

jjを使い始める前に、gitとの根本的な考え方の違いを理解することが重要です。

### ワーキングコピーの扱い

| 項目 | Git | jj |
|------|-----|-----|
| 変更の追跡 | 明示的に `git add` が必要 | 自動的に追跡される |
| ステージング | ステージングエリアが存在 | ステージングエリアなし |
| 未追跡ファイル | 明示的に追加するまで無視 | 自動的にワーキングコピーに含まれる |

### コミットタイミングの違い

**Git のフロー**:
```text
[編集] → [git add] → [git commit] → [次の編集]
```

**jj のフロー**:
```text
[編集（自動追跡）] → [jj describe（メッセージ設定）] → [jj new（次のコミット開始）]
```

jjでは、ワーキングコピー自体が常に「コミット」状態です。`jj new` を実行すると、現在の状態が確定し、新しい空のコミットが作成されます。

### ブランチ vs ブックマークの概念

| 概念 | Git | jj |
|------|-----|-----|
| 名前付きポインタ | ブランチ（branch） | ブックマーク（bookmark） |
| HEAD の役割 | 現在のブランチを指す | 現在のリビジョンを指す（@で表記） |
| 作業開始時 | ブランチを作成してから作業 | 匿名で作業開始可能、後から名前付け |
| 切り替え | `git checkout` / `git switch` | `jj edit` / `jj new` |

### フロー比較図

```text
Git:
  ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
  │  編集   │ →  │ git add │ →  │ commit  │ →  │  編集   │
  └─────────┘    └─────────┘    └─────────┘    └─────────┘
       ↓              ↓              ↓
   (未追跡)      (ステージ済)     (確定)

jj:
  ┌─────────────────────┐    ┌──────────────┐    ┌──────────┐
  │ 編集（自動追跡）     │ →  │ jj describe  │ →  │ jj new   │
  └─────────────────────┘    └──────────────┘    └──────────┘
       ↓                           ↓                  ↓
   (ワーキングコピー=             (メッセージ        (新しい空の
    暫定コミット)                  設定)              コミット開始)
```

### 実践的な違いの例

**作業の中断**:
- Git: `git stash` で変更を退避
- jj: そのまま `jj new` で新しい作業を開始（前の変更は自動保存）

**間違いの修正**:
- Git: `git reset`、`git revert` など状況に応じて使い分け
- jj: `jj undo` で直前の操作を取り消し

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
| コミット | `git commit -m "msg"` | `jj describe -m "msg"` + `jj new` | 推奨フロー（下記参照） |
| コミットメッセージ編集 | `git commit --amend` | `jj describe -m "msg"` | 現在のリビジョンを編集 |
| 変更退避 | `git stash` | (不要) | ワーキングコピーが自動保存 |
| 操作取り消し | `git reset` | `jj undo` | 直前の操作を取り消し |
| 変更を分離 | `git add -p` + `git commit` | `jj split` | 対話的に変更を分離 |
| ファイル復元 | `git restore <file>` | `jj restore <file>` | ワーキングコピーから復元 |

> **コミットフローの推奨**:
> jjでは `jj describe` でメッセージを設定し、`jj new` で次のリビジョンを作成するフローを推奨します。
> `jj commit` も使用可能ですが、`jj describe` + `jj new` の方がワークフローに柔軟性があります。
>
> **git reset との違い**:
> `jj undo` は直前のjj操作を取り消します。Gitの `git reset --soft/--mixed/--hard` のような細かいモードはありません。
> より詳細な制御が必要な場合は `jj restore` や `jj abandon` を検討してください。

### リモート操作系

| 用途 | Git コマンド | jj コマンド | 備考 |
|------|-------------|------------|------|
| リモートへプッシュ | `git push` | `jj git push` | |
| 特定ブックマークをプッシュ | `git push -u origin <branch>` | `jj git push --bookmark <name>` | |
| リモートから取得 | `git pull` | `jj git fetch` + `jj rebase -d <bookmark>@<remote>` | 下記参照 |
| リモートbookmark削除 | `git push origin --delete <name>` | `jj bookmark delete <name>` + `jj git push --deleted` | 下記参照 |
| タグ作成 | `git tag -a <tag> -m "msg"` | `git tag -a <tag> -m "msg"` | colocateでGit直接使用 |
| タグプッシュ | `git push --tags` | `git push --tags` | colocateでGit直接使用 |

> **git pull との違い**:
> jjでは `git pull` に相当する操作は2ステップです:
> ```bash
> jj git fetch                    # リモートから取得
> jj rebase -d main@origin        # リモートブックマークにリベース（宛先を明示）
> ```
>
> **タグ操作について**:
> jjはGitタグをネイティブにサポートしていないため、colocateモードでGitコマンドを直接使用します。
>
> **リモートbookmark削除について**:
> jjでリモートbookmarkを削除するには2ステップが必要です:
> ```bash
> jj bookmark delete <name>    # ローカル削除（次回pushで削除が伝播）
> jj git push --deleted        # 削除をリモートに反映
> ```

---

## AI-DLCワークフローでの使用方法

### 作業開始時チェックリスト

Unit/フェーズを開始する前に確認してください。

- [ ] 現在のリビジョン（@）の位置を確認

  ```bash
  jj log -r @
  ```

- [ ] cycle bookmarkの位置を確認

  ```bash
  jj log -r 'cycle/vX.X.X'
  ```

- [ ] cycle bookmarkから新しいchangeを作成

  ```bash
  jj new cycle/vX.X.X
  ```

> **ヒント**: `jj log` で現在の状態を視覚的に確認できます。cycle bookmarkと@の位置関係を把握してから作業を開始しましょう。

---

### Setup Phase

cycle bookmarkの作成:

```bash
# mainから新しいリビジョンを作成
jj new main

# cycle bookmarkを作成
jj bookmark create cycle/vX.X.X

# リモートにプッシュ
jj git push --bookmark cycle/vX.X.X
```

### Inception Phase

ブックマークの確認と切り替え:

```bash
# ブックマーク一覧を確認
jj bookmark list

# cycle bookmarkに切り替え
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
jj git push --bookmark cycle/vX.X.X
```

レビュー後の修正:

```bash
# 修正を行った後
jj describe -m "chore: [vX.X.X] レビュー反映 - 成果物名"
jj new
jj git push --bookmark cycle/vX.X.X
```

### Operations Phase

タグの作成（colocateモードでGitを直接使用）:

```bash
# Gitでタグを作成
git tag -a vX.X.X -m "Release vX.X.X"

# Gitでタグをプッシュ
git push --tags
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

### 作業終了時チェックリスト

Unit/フェーズを完了する際に **必ず** 実行してください。

- [ ] コミットメッセージを設定

  ```bash
  jj describe -m "feat: [vX.X.X] Unit NNN完了 - 概要"
  ```

- [ ] 新しいリビジョンを作成（現在の変更を確定）

  ```bash
  jj new
  ```

- [ ] **cycle bookmarkを進める（重要）**

  ```bash
  jj bookmark set cycle/vX.X.X -r @-
  ```

- [ ] リモートにプッシュ

  ```bash
  jj git push --bookmark cycle/vX.X.X
  ```

**ワンライナー版**（上記をまとめて実行）:

```bash
jj describe -m "feat: [vX.X.X] Unit NNN完了" && jj new && jj bookmark set cycle/vX.X.X -r @- && jj git push --bookmark cycle/vX.X.X
```

> **注意**: `jj bookmark set` を忘れるとcycle bookmarkが古いままになります。必ず実行してください。

---

## よくあるミスと対処法

このセクションでは、AI-DLCでjjを使用する際によく遭遇する問題と解決策を説明します。

### `jj new` を忘れて作業を始めた

**症状**:

- 前のリビジョンに新しい変更が混ざってしまった
- `jj log` で見ると、意図しない変更が含まれている

**原因**:

作業開始前に `jj new` を実行せず、既存のリビジョンに変更を追加してしまった。

**解決策**:

`jj split` で変更を対話的に分離します：

```bash
# 現在のリビジョンを分離
jj split

# 対話的UIで、前のリビジョンに残す変更と新しいリビジョンに移す変更を選択
# 完了後、新しいリビジョンが作成される
```

**予防策**:

「[作業開始時チェックリスト](#作業開始時チェックリスト)」を活用し、作業前に必ず `jj new` を実行してください。

---

### bookmarkが進まない・リモートに反映されない

**症状**:

- `jj git push` してもリモートに変更が反映されない
- PRのdiffが空になる、または古いコミットしか含まれていない
- `jj log` でbookmarkが古いリビジョンを指している

**原因**:

`jj bookmark set` を実行していないため、bookmarkが古いリビジョンを指したままになっている。

**解決策**:

正しいリビジョンを指定して `jj bookmark set` を実行します：

```bash
# 現在の作業完了後、bookmarkを更新
jj bookmark set cycle/vX.X.X -r @-

# リモートにプッシュ
jj git push --bookmark cycle/vX.X.X
```

**予防策**:

「[作業終了時チェックリスト](#作業終了時チェックリスト)」を活用し、作業終了時に必ず `jj bookmark set` を実行してください。

詳細は「⚠️ 重要: bookmarkは自動で進まない」セクションも参照してください。

---

### 不要なbookmarkの削除

**症状**:

- 古いサイクルや作業用のbookmarkが残っている
- `jj bookmark list` の一覧が煩雑になっている

**解決策**:

ローカルbookmarkを削除し、リモートにも反映します：

```bash
# ローカルbookmarkを削除
jj bookmark delete old-cycle/v1.0.0

# 削除をリモートに反映
jj git push --deleted
```

> **注意**: `jj bookmark delete` は次回のpush時に削除をリモートに伝播する設定になります。すぐに反映したい場合は `jj git push --deleted` を実行してください。

---

### 作業開始前に未コミットの変更がある

**症状**:

- 新しい作業を始めようとしたら、前の作業の変更が残っている
- `jj status` で予期しない変更が表示される

**原因**:

前の作業を完了（`jj describe` + `jj new`）せずに新しい作業を開始しようとした。

**解決策**:

現在の変更にメッセージを付けて確定し、新しいリビジョンを作成します：

```bash
# 現在の変更状態を確認
jj status

# 現在の変更にメッセージを設定
jj describe -m "前の作業の内容を説明"

# 新しいリビジョンを作成して作業開始
jj new
```

**予防策**:

作業開始前に必ず `jj status` で状態を確認してください。

---

## 注意事項と制限

> **ヒント**: 問題が発生した場合は「[よくあるミスと対処法](#よくあるミスと対処法)」も参照してください。

### bookmarkの手動移動について（再強調）

**最も重要な注意点**: jjのbookmarkは自動で進みません。

Unit完了時には必ず以下を実行してください:

```bash
jj bookmark set cycle/vX.X.X -r @-
```

詳細は「[作業終了時チェックリスト](#作業終了時チェックリスト)」を参照してください。

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
