# Unit 004 計画: worktreeクリーンアップスクリプト

## 概要

PRマージ後の手動クリーンアップ作業（5ステップ）を自動化する`post-merge-cleanup.sh`を新規作成する。

## 変更対象ファイル

| ファイル | 操作 | 内容 |
|---------|------|------|
| `prompts/package/bin/post-merge-cleanup.sh` | 新規作成 | クリーンアップスクリプト |
| `prompts/package/guides/worktree-usage.md` | 編集 | スクリプト使用例の追加 |

## 実装計画

### Phase 1: 設計

1. 引数インターフェース: `--cycle <VERSION>` (必須), `--dry-run` (オプション), `-h|--help`
2. 出力形式: `status:`, `step:`, `step_result:`, `branch:`, `main_repo_path:`, `message:`（エラーは`step_result`に一本化）
3. エラーハンドリング戦略: 致命的（即中断）vs 非致命的（warning継続）

### Phase 2: 実装

1. `post-merge-cleanup.sh`を新規作成:
   - `set -euo pipefail`
   - ヘッダコメント（使用方法、引数、出力形式、終了コード）
   - `show_help()` 関数
   - 引数パース: `--cycle`, `--dry-run`, `-h|--help`
   - バージョン形式バリデーション: `^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$`（setup-branch.sh準拠）

2. 処理ステップ（7段階）:
   - **Step 0a: 実行環境検証**
     - worktree環境判定: `git rev-parse --git-dir`の結果が`<toplevel>/.git`と一致すれば通常リポジトリ（worktreeではない）。worktreeの場合、`--git-dir`は`.git/worktrees/<name>`形式のパスを返す
     - メインリポジトリのパスを`git worktree list --porcelain`から属性ベースで特定: `bare`でないルートworktreeを検出（順序依存しない）
     - サイクルブランチ`cycle/<VERSION>`がローカルに存在することを確認
     - 致命的エラー: `not-in-worktree`, `main-repo-detection-failed`, `branch-not-found`
   - **Step 0b: 作業状態検証**
     - 未コミット変更がないことを確認（`git status --porcelain`）
     - 未pushコミットがないことを確認（`git log @{u}..HEAD --oneline`、upstream未設定時はスキップ）
     - 致命的エラー: `uncommitted-changes`, `unpushed-commits`
   - **Step 1: メインリポジトリでpull**（データフロー: メインリポジトリ用remote/default_branch解決）
     - リモート名（`MAIN_REMOTE`）: メインリポジトリの`branch.main.remote`を優先解決、未設定時`origin`にフォールバック
     - デフォルトブランチ（`DEFAULT_BRANCH`）: `<MAIN_REMOTE>/HEAD`のシンボリック参照から解決、未設定時`main`にフォールバック
     - コマンド: `GIT_TERMINAL_PROMPT=0 git -C <main_repo> pull <MAIN_REMOTE> <DEFAULT_BRANCH>`
     - 致命的エラー: `pull-failed`
   - **Step 2: worktreeでfetch**（データフロー: worktree用remote解決）
     - リモート名（`WT_REMOTE`）: `branch.<current>.remote`を優先解決、未設定時`origin`にフォールバック
     - コマンド: `GIT_TERMINAL_PROMPT=0 git fetch <WT_REMOTE>`
     - 致命的エラー: `fetch-failed`
   - **Step 3: detached HEADに切り替え**（データフロー: Step 2の`WT_REMOTE`を使用）
     - `WT_REMOTE`のデフォルトブランチ（`WT_DEFAULT_BRANCH`）: `<WT_REMOTE>/HEAD`のシンボリック参照から解決、未設定時`main`にフォールバック
     - コマンド: `git checkout --detach <WT_REMOTE>/<WT_DEFAULT_BRANCH>`
     - 致命的エラー: `detach-failed`
   - **Step 4: ローカルブランチ削除** — `git branch -d cycle/<VERSION>`
     - 非致命的エラー: `local-branch-delete-failed`（warning扱いで継続、手動復旧手順を出力）
   - **Step 5: リモートブランチ削除**（データフロー: Step 2の`WT_REMOTE`を使用）
     - コマンド: `GIT_TERMINAL_PROMPT=0 git push <WT_REMOTE> --delete cycle/<VERSION>`
     - 非致命的エラー: `remote-branch-delete-failed`（warning扱いで継続、手動復旧手順を出力）

3. dry-runモード:
   - Step 0a/0bは通常通り実行（安全チェックのため）
   - Step 1-5で実行コマンドを`step:dry-run:<コマンド>`形式で出力
   - 実際のgitコマンドは実行しない

4. `GIT_TERMINAL_PROMPT=0`をfetch/pull/pushで使用（validate-git.sh準拠）

5. `worktree-usage.md`に使用例セクションを追加:
   - 「PRマージ後のクリーンアップ」セクション
   - 基本的な使い方（`post-merge-cleanup.sh --cycle v1.5.3`）
   - dry-runの使い方
   - 出力例

## 出力契約

### 出力キー一覧

| キー | 説明 | 出現タイミング |
|------|------|----------------|
| `step:<N>:<名前>` | ステップ開始 | 各ステップ開始時 |
| `step_result:<N>:ok` | ステップ成功 | ステップ正常完了時 |
| `step_result:<N>:warning:<code>` | ステップ警告 | 非致命的エラー時 |
| `step_result:<N>:error:<code>` | ステップ失敗 | 致命的エラー時 |
| `step:dry-run:<コマンド>` | dry-run表示 | dry-runモード時 |
| `main_repo_path:<パス>` | メインリポジトリパス | Step 0a成功時 |
| `branch:<ブランチ名>` | 対象ブランチ | Step 0a成功時 |
| `status:success\|warning\|error` | 最終結果 | 末尾 |
| `message:<テキスト>` | 説明メッセージ | 末尾 |

### エラーコード一覧

| コード | 種別 | ステップ | 説明 |
|--------|------|----------|------|
| `not-in-worktree` | fatal | 0a | worktree環境外で実行 |
| `main-repo-detection-failed` | fatal | 0a | メインリポジトリ特定失敗 |
| `branch-not-found` | fatal | 0a | サイクルブランチが存在しない |
| `uncommitted-changes` | fatal | 0b | 未コミット変更あり |
| `unpushed-commits` | fatal | 0b | 未pushコミットあり |
| `pull-failed` | fatal | 1 | メインリポジトリのpull失敗 |
| `fetch-failed` | fatal | 2 | fetch失敗 |
| `detach-failed` | fatal | 3 | detached HEAD切り替え失敗 |
| `local-branch-delete-failed` | non-fatal | 4 | ローカルブランチ削除失敗 |
| `remote-branch-delete-failed` | non-fatal | 5 | リモートブランチ削除失敗 |

以下の出力例では、リモート名=`origin`、デフォルトブランチ=`main`と仮定しています。実際の出力は動的解決の結果により変わります。

### 正常時

```text
step:0a:実行環境検証
main_repo_path:/path/to/main-repo
branch:cycle/v1.5.3
step_result:0a:ok
step:0b:作業状態検証
step_result:0b:ok
step:1:メインリポジトリpull
step_result:1:ok
step:2:worktreeでfetch
step_result:2:ok
step:3:detached HEAD切り替え
step_result:3:ok
step:4:ローカルブランチ削除
step_result:4:ok
step:5:リモートブランチ削除
step_result:5:ok
status:success
message:クリーンアップが完了しました
```

### warning時（非致命的エラー）

```text
step:0a:実行環境検証
main_repo_path:/path/to/main-repo
branch:cycle/v1.5.3
step_result:0a:ok
step:0b:作業状態検証
step_result:0b:ok
step:1:メインリポジトリpull
step_result:1:ok
step:2:worktreeでfetch
step_result:2:ok
step:3:detached HEAD切り替え
step_result:3:ok
step:4:ローカルブランチ削除
step_result:4:ok
step:5:リモートブランチ削除
step_result:5:warning:remote-branch-delete-failed
status:warning
message:リモートブランチ削除に失敗しました。手動で実行してください: git push origin --delete cycle/v1.5.3
```

### error時（致命的エラー）

```text
step:0a:実行環境検証
step_result:0a:error:not-in-worktree
status:error
message:このスクリプトはworktree環境でのみ実行できます
```

エラーは`step_result`に一本化し、独立した`error:`行は使用しない。

### dry-run時

```text
step:0a:実行環境検証
main_repo_path:/path/to/main-repo
branch:cycle/v1.5.3
step_result:0a:ok
step:0b:作業状態検証
step_result:0b:ok
step:dry-run:git -C /path/to/main-repo checkout main
step:dry-run:git -C /path/to/main-repo pull origin main
step:dry-run:git fetch origin
step:dry-run:git checkout --detach origin/main
step:dry-run:git branch -d cycle/v1.5.3
step:dry-run:git push origin --delete cycle/v1.5.3
status:success
message:dry-run完了（実際のコマンドは実行されていません）
```

## 終了コード

- 0: success / warning / dry-run success
- 1: error（致命的エラー）

## 完了条件チェックリスト

- [x] post-merge-cleanup.shが7ステップ（0a, 0b, 1-5）を実装
- [x] `--cycle`引数のバリデーション（バージョン形式チェック）
- [x] `--dry-run`サポート
- [x] worktree環境の属性ベース自動検出（`git worktree list --porcelain`）
- [x] メインリポジトリパスの自動特定
- [x] リモート名・デフォルトブランチの動的解決（`branch.<name>.remote`優先、フォールバック）
- [x] 作業状態検証（未コミット/未push検出）
- [x] 致命的/非致命的エラーの区別とエラーコード出力
- [x] worktree-usage.mdに使用例を追加
- [x] Markdownlintエラーなし
