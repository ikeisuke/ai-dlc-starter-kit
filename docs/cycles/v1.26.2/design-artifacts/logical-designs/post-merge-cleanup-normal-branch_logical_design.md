# 論理設計: post-merge-cleanup.sh 通常ブランチ対応

## 概要
`post-merge-cleanup.sh` を通常ブランチ環境でも動作するよう拡張する。既存のworktreeフローを維持しつつ、`IS_WORKTREE` フラグによる条件分岐を各ステップに追加する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン
既存のステップベースパイプラインパターンを維持。各ステップ関数内に `IS_WORKTREE` による条件分岐を追加する「Strategy内包型」を採用。ステップ数やmain関数の構造は変更しない。

## コンポーネント構成

### スクリプト構成（変更後）

```text
post-merge-cleanup.sh
├── グローバル変数
│   ├── 既存変数（CYCLE, DRY_RUN, MAIN_REPO_PATH, BRANCH_NAME, ...）
│   └── 新規: IS_WORKTREE（Boolean文字列 "true"/"false"）
├── ユーティリティ関数（変更なし）
│   ├── fatal_error()
│   ├── validate_remote()
│   └── resolve_default_branch()
├── 処理ステップ
│   ├── step_0a() — 環境検証 ★変更あり
│   ├── step_0b() — 作業状態検証（変更なし）
│   ├── step_1() — デフォルトブランチ更新 ★変更あり
│   ├── step_2() — fetch ★変更あり
│   ├── step_3() — ブランチ状態整理 ★変更あり
│   ├── step_4() — ローカルブランチ削除（変更なし）
│   └── step_5() — リモートブランチ削除（変更なし）
├── 引数パース（変更なし）
├── ヘルプ・コメント ★変更あり
└── main()（変更なし）
```

### コンポーネント詳細

#### step_0a()（環境検証）★変更あり
- **責務**: 実行環境（worktree/通常ブランチ）を判定し、環境に応じた初期化を実行
- **依存**: git CLI（rev-parse, worktree list）
- **変更内容**:
  - L145-147の `fatal_error` を `IS_WORKTREE` フラグ設定に置換
  - `abs_git_dir == toplevel/.git` → `IS_WORKTREE=false`、それ以外 → `IS_WORKTREE=true`
  - `IS_WORKTREE=true` の場合: 既存のworktree list解析（L149-179）を実行
  - `IS_WORKTREE=false` の場合:
    - `MAIN_REPO_PATH` に `toplevel` を設定（worktree list解析をスキップ）
    - **WT_REMOTEプリフェッチ**: step_1でデフォルトブランチにcheckoutする前に、サイクルブランチ（`BRANCH_NAME`）のリモートを `WT_REMOTE` に退避する。これはstep_2でcurrent_branchベースの解決ができなくなるため（step_1のcheckoutでcurrent_branchが変わる副作用への対策）
    - プリフェッチロジック: `git config "branch.${BRANCH_NAME}.remote"` → validate_remote → フォールバック（origin or 最初のリモート）。既存step_2のリモート解決と同一ロジック
  - 両環境で `echo "main_repo_path:${MAIN_REPO_PATH}"` を出力

#### step_1()（デフォルトブランチ更新）★変更あり
- **責務**: デフォルトブランチに切り替えて最新状態にする
- **依存**: git CLI, resolve_default_branch(), validate_remote()
- **変更内容**:
  - ステップ名を `メインリポジトリpull` → `デフォルトブランチ更新` に変更
  - `IS_WORKTREE=true`: 既存ロジック維持（`git -C $MAIN_REPO_PATH` で操作）
  - `IS_WORKTREE=false`:
    - リモート解決: 同じロジック（`git -C` を使わず `git` で直接操作、ただし `MAIN_REPO_PATH` は自リポジトリなので `git -C $MAIN_REPO_PATH` でも動作する。一貫性のため既存コードをそのまま使用）
    - `git -C $MAIN_REPO_PATH checkout $DEFAULT_BRANCH` → `git -C $MAIN_REPO_PATH pull $MAIN_REMOTE $DEFAULT_BRANCH`
    - **重要**: 通常ブランチでもworktreeと同じコードパスで動作する（`MAIN_REPO_PATH` が自リポジトリを指すため）。分岐不要

  **設計判断**: step_1のリモート解決・checkout・pullロジックは `git -C $MAIN_REPO_PATH` を使用しており、通常ブランチでは `MAIN_REPO_PATH` が自リポジトリを指すため、**step_1のコマンド実行は分岐なしで動作する**。ただし、step_1のcheckoutにより `git branch --show-current` が返す値がデフォルトブランチに変わるため、**step_2のWT_REMOTE解決に副作用がある**。この副作用はstep_0aでのWT_REMOTEプリフェッチで解消する。

#### step_2()（fetch）★変更あり
- **責務**: リモートからfetchする
- **依存**: git CLI, validate_remote()
- **変更内容**:
  - ステップ名を `worktreeでfetch` → `fetch` に変更
  - `IS_WORKTREE=true`: 既存ロジック維持（current_branchベースでWT_REMOTE解決）
  - `IS_WORKTREE=false`: step_0aでWT_REMOTEがプリフェッチ済みのため、リモート解決ブロック（L266-285）をスキップし、既存のWT_REMOTE値をそのまま使用。fetchコマンド自体は共通

#### step_3()（ブランチ状態整理）★変更あり
- **責務**: worktreeではdetached HEADに切り替え、通常ブランチではスキップ
- **依存**: git CLI, resolve_default_branch()
- **変更内容**:
  - ステップ名を `detached HEAD切り替え` → `ブランチ状態整理` に変更
  - `IS_WORKTREE=true`: 既存ロジック維持（`git checkout --detach`）
  - `IS_WORKTREE=false`: step_1でデフォルトブランチにcheckout済みのため、スキップ
    - `echo "step:3:ブランチ状態整理"` を出力
    - `echo "step_result:3:ok"` を出力して即 return
    - dry-run時も同様にスキップ（`step:dry-run:skip (already on default branch)` を出力）

#### step_4(), step_5()（変更なし）
- ブランチ削除処理はworktree/通常ブランチ共通で動作する
- step_5の `WT_REMOTE` は、通常ブランチの場合はstep_0aでプリフェッチ済み、worktreeの場合はstep_2で設定済み

#### show_help()、スクリプトヘッダ ★変更あり
- worktree専用表現を除去し、両環境対応を反映
- ステップ名を更新

## スクリプトインターフェース設計

### post-merge-cleanup.sh

#### 概要
PRマージ後のクリーンアップを実行する（worktree環境・通常ブランチ環境の両方に対応）

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--cycle <VERSION>` | 必須 | サイクルバージョン（例: v1.5.3） |
| `--dry-run` | 任意 | コマンドを実行せず、実行予定を表示 |
| `-h, --help` | 任意 | ヘルプを表示 |

（引数変更なし）

#### 成功時出力（通常ブランチ環境の場合）
```text
step:0a:実行環境検証
main_repo_path:/path/to/repo
branch:cycle/v1.5.3
step_result:0a:ok
step:0b:作業状態検証
step_result:0b:ok
step:1:デフォルトブランチ更新
step_result:1:ok
step:2:fetch
step_result:2:ok
step:3:ブランチ状態整理
step_result:3:ok
step:4:ローカルブランチ削除
step_result:4:ok
step:5:リモートブランチ削除
step_result:5:ok
status:success
message:クリーンアップが完了しました
```

#### dry-run時出力（通常ブランチ環境の場合）
```text
step:0a:実行環境検証
main_repo_path:/path/to/repo
branch:cycle/v1.5.3
step_result:0a:ok
step:0b:作業状態検証
step_result:0b:ok
step:1:デフォルトブランチ更新
step:dry-run:git -C /path/to/repo checkout main
step:dry-run:git -C /path/to/repo pull origin main
step_result:1:ok
step:2:fetch
step:dry-run:git fetch origin
step_result:2:ok
step:3:ブランチ状態整理
step:dry-run:skip (already on default branch)
step_result:3:ok
step:4:ローカルブランチ削除
step:dry-run:git branch -d cycle/v1.5.3
step_result:4:ok
step:5:リモートブランチ削除
step:dry-run:git push origin --delete cycle/v1.5.3
step_result:5:ok
status:success
message:dry-run完了（実際のコマンドは実行されていません）
```

## 処理フロー概要

### 通常ブランチでのクリーンアップフロー

**ステップ**:
1. step_0a: `abs_git_dir == toplevel/.git` を検知 → `IS_WORKTREE=false`、`MAIN_REPO_PATH=toplevel`
2. step_0b: 未コミット変更・未pushコミットチェック（共通）
3. step_1: `git -C $MAIN_REPO_PATH checkout $DEFAULT_BRANCH` → `git -C $MAIN_REPO_PATH pull`（MAIN_REPO_PATHが自リポジトリを指すため、実質ローカル操作）
4. step_2: `git fetch $WT_REMOTE`（共通）
5. step_3: スキップ（`step_result:3:ok` のみ出力）
6. step_4: `git branch -d $BRANCH_NAME`（共通）
7. step_5: `git push $WT_REMOTE --delete $BRANCH_NAME`（共通）

**関与するコンポーネント**: step_0a, step_0b, step_1, step_2, step_3, step_4, step_5

### worktreeでのクリーンアップフロー（既存、変更なし）

**ステップ**: 従来通り。唯一の差異はステップ名の表示が変わること。

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 既存のworktreeフローと同等の実行速度
- **対応策**: 通常ブランチではworktree list解析をスキップし、step_3もスキップするため、むしろ高速化

### セキュリティ
- **要件**: 該当なし
- **対応策**: 既存のパストラバーサル防止・バージョン形式バリデーションはそのまま維持

## 技術選定
- **言語**: Bash（既存スクリプトと同一）
- **依存**: git CLI（既存と同一）

## 出力契約の定義

- **機械可読契約（変更禁止）**: `step_result:<N>:<status>[:<code>]`, `main_repo_path:<パス>`, `branch:<名前>`, `status:<結果>`, `message:<テキスト>` — 呼び出し元がパースする形式
- **表示用出力（変更可）**: `step:<N>:<名前>`, `step:dry-run:<コマンド>` — 人間向けの表示。呼び出し元はパースしない（operations.mdおよびguides確認済み）

## 実装上の注意事項
- `IS_WORKTREE` グローバル変数の初期値は空文字列。step_0aで必ず設定されるため、後続ステップで未設定になることはない
- step_1のコマンド実行は分岐不要（`git -C $MAIN_REPO_PATH` が通常ブランチでも正しく動作）。ただしstep_1のcheckoutでcurrent_branchが変わる副作用があるため、通常ブランチではstep_0aでWT_REMOTEをプリフェッチする
- step_5の `WT_REMOTE` は、worktreeではstep_2で設定、通常ブランチではstep_0aでプリフェッチ済み
- 出力契約（機械可読）の維持が最重要。呼び出し元がパースする形式を変更してはならない

## 不明点と質問（設計中に記録）

（不明点なし。計画段階のAIレビューで主要な設計判断は確定済み）
