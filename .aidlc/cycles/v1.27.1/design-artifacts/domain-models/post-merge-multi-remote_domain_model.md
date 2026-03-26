# ドメインモデル: post-merge-cleanup マルチリモート対応

## 概要

resolve_remote()関数のフォールバックロジックを改善し、ブランチ名が空またはgit configで解決できない場合に、refs/remotes/やgit ls-remoteを用いてマルチリモート環境でも正しいリモートを特定する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### resolve_remote 関数

- **責務**: ブランチ名からリモートを解決し、グローバル変数 WT_REMOTE に設定する
- **API契約**:
  - 引数 `branch_name`: ブランチ追跡設定（`git config`）の参照用。空文字の場合、追跡設定の参照をスキップし、グローバル変数 `BRANCH_NAME` を探索キーとして使用する
  - グローバル変数 `BRANCH_NAME`: refs/remotes および ls-remote 探索のブランチパス。`branch_name` が空の場合のフォールバック探索キーとして機能する
  - **入力優先順位**: `branch_name`（引数） > `BRANCH_NAME`（グローバル）
- **現在のフロー**:
  1. ブランチ名がある場合: `git config branch.<name>.remote` で解決
  2. 見つからない場合: origin があれば origin、なければ最初のリモート
- **改善後のフロー**:
  1. ブランチ名がある場合: `git config branch.<name>.remote` で解決 → 成功なら return
  2. **探索キー決定**: `effective_branch = branch_name || BRANCH_NAME`。空なら戦略4へ直行
  3. **refs/remotes 探索**: `git for-each-ref "refs/remotes/*/${effective_branch}"` でローカルキャッシュから探索
  4. **git ls-remote 探索**（refs/remotes で見つからない場合のみ）: 各リモートに対して `git ls-remote --heads <remote> "refs/heads/${effective_branch}"` で確認
  5. **フォールバック**: 上記すべて失敗時に origin → 最初のリモート → fatal_error

## 関数分割設計

### find_remote_by_branch（新規ヘルパー関数）

- **責務**: 探索キーを受け取り、リモート名候補を返す（探索のみ、副作用なし）
- **入力**: effective_branch（ブランチパス文字列）
- **出力**: stdout にリモート名を出力（見つからない場合は空）
- **探索順序**:
  1. refs/remotes 探索（ローカル、ネットワーク不要）
  2. ls-remote 探索（リモート問い合わせ、ネットワーク必要）

### resolve_remote（既存関数の修正）

- **責務**: 探索結果の検証（validate_remote）、WT_REMOTE への適用、警告出力
- **内部フロー**:
  1. 戦略1（git config）で解決を試行
  2. find_remote_by_branch を呼び出し
  3. 結果を validate_remote で検証
  4. 検証成功: WT_REMOTE に設定して return
  5. 検証失敗/候補なし: フォールバック + 警告出力

## ドメインサービス

### リモート探索サービス（find_remote_by_branch内のロジック）

- **責務**: 複数の探索戦略を優先順に実行し、最初に見つかったリモートを返す
- **入力型**: `effective_branch` — 常にブランチ短縮名（例: `cycle/v1.27.1`）。Git コマンド境界でのみ `refs/heads/` や `refs/remotes/` プレフィックスを付与する
- **探索戦略（優先順）**:
  1. `git for-each-ref "refs/remotes/*/${effective_branch}"` — ローカルrefキャッシュ（ネットワーク不要）
  2. `git ls-remote --heads <remote> "refs/heads/${effective_branch}"` — リモート直接確認（ネットワーク必要）

### 探索戦略の詳細

#### 戦略2: refs/remotes探索

- **入力**: effective_branch（例: `cycle/v1.27.1`）
- **コマンド**: `git for-each-ref --format='%(refname)' "refs/remotes/*/${effective_branch}"`
- **リモート名抽出**: `refs/remotes/` プレフィックスと `/${effective_branch}` サフィックスを除去
- **結果処理**:
  - 1件: そのリモートを返す
  - 複数件: **origin 優先タイブレーク** — 候補に `origin` が含まれていれば `origin` を採用。含まれていなければ最初の1件を採用。fork環境で push 権限のないリモートが選ばれるリスクを軽減するため
  - 0件: 戦略3へ
- **NFR**: ネットワークアクセス不要、高速

#### 戦略3: git ls-remote探索

- **前提**: 戦略2で見つからなかった場合のみ実行
- **入力**: effective_branch、全リモート一覧
- **コマンド**: 各リモートに対して `GIT_TERMINAL_PROMPT=0 git ls-remote --heads <remote> "refs/heads/${effective_branch}"`
- **タイムアウト制御（環境適応型）**:
  - **優先1**: `gtimeout 5`（macOS + Homebrew coreutils）または `timeout 5`（Linux）— プロトコル非依存、5秒保証
  - **優先2**（gtimeout/timeout いずれも利用不可の場合）: HTTP(S) は `GIT_HTTP_LOW_SPEED_LIMIT=1000 GIT_HTTP_LOW_SPEED_TIME=5`、SSH は `GIT_SSH_COMMAND='ssh -o BatchMode=yes -o ConnectTimeout=5'` で制限
  - **NFR**: 優先1（gtimeout/timeout）はプロトコル非依存で5秒保証。優先2は HTTP(S)/SSH それぞれ独立した環境変数で5秒を制限
- **結果処理（共通タイブレーク規則）**:
  - 全リモートを走査し、ヒットしたリモートを候補リストに収集する
  - **origin 優先タイブレーク**: 候補に `origin` が含まれれば `origin` を返す。含まれなければ最初の候補を返す（戦略2と同一のポリシー）
  - 全リモートで見つからない/失敗: 空を返す
- **障害分離**:
  - 各リモートへの ls-remote は独立して実行。1つのリモートの失敗が他に波及しない
  - タイムアウト超過: 当該リモートをスキップし次のリモートへ
  - 最初のリモートがタイムアウトした場合: 残りリモートも同様にネットワーク不達の可能性が高いが、異なるホストの可能性もあるため全リモートを試行する

### 共通タイブレーク規則

探索戦略（refs/remotes、ls-remote）によらず、複数のリモート候補が見つかった場合は以下の**同一ポリシー**で選択する:

1. 候補に `origin` が含まれる → `origin` を返す
2. 含まれない → 最初の候補を返す

**理由**: step_5（リモートブランチ削除）で `git push --delete` を実行するため、push 権限のある origin を優先する

#### 戦略4: フォールバック（既存ロジック + 警告）

- origin があれば origin、なければ最初のリモート
- **追加**: 探索を実行した（`searched=true`）にも関わらずフォールバックに到達した場合、警告メッセージを出力
  - 形式: `message:警告: ブランチ ${effective_branch} のリモートを特定できませんでした。${WT_REMOTE} にフォールバックします`

## セキュリティ考慮事項

### ls-remote 探索時の資格情報保護

戦略3（ls-remote）では全リモートURLへ接続するため、資格情報の漏洩を防ぐハードニングを実施する:

- **Git側**: `credential.helper=`（空）、`core.askPass=`（空）、`GIT_TERMINAL_PROMPT=0`
- **SSH側**: `BatchMode=yes`、`IdentityAgent=none`、`IdentitiesOnly=yes`、`-F /dev/null`

### 既知のリスク: 全リモートへの外向き接続

`git remote` で列挙される全URLへ接続を試行する動作は機能要件に内在する。refs/remotes探索の先行実行、資格情報の完全無効化、タイムアウト制御、リモートURLがユーザー管理である点から、受容可能なリスクと判断する。

## 呼び出しコンテキスト

### step_0a での呼び出し（通常ブランチ環境）

- `LOCAL_BRANCH_EXISTS=true`: `resolve_remote "$BRANCH_NAME" "0a" "no-remote"` → 戦略1で解決可能
- `LOCAL_BRANCH_EXISTS=false`: `resolve_remote "" "0a" "no-remote"` → 引数が空のため戦略1スキップ → `BRANCH_NAME`（`cycle/${CYCLE}`、常にセット済み）を探索キーとして戦略2, 3, 4 の新ロジックが活用される

### step_2 での呼び出し（worktree環境）

- `resolve_remote "${current_branch:-}" "2" "fetch-failed"` → current_branchで解決可能（通常は成功するが、detached HEAD等の場合に `BRANCH_NAME` を探索キーとして新ロジックが活用される）

### 前提条件

- resolve_remote() はカレントディレクトリのリポジトリコンテキストで動作する。validate_remote の repo_path は常に `"."` を使用する

## 不変条件

1. シングルリモート環境では従来のoriginフォールバックと同等の結果になること
2. オフライン時: 戦略3（ls-remote）は各リモートでタイムアウト/エラーとなりフォールバックへ進む。`gtimeout`/`timeout` 利用可能時は5秒/リモートで待ち時間を限定。利用不可時は HTTP(S) は `GIT_HTTP_LOW_SPEED_*`、SSH は `GIT_SSH_COMMAND` の `ConnectTimeout=5` でそれぞれ制限
3. 既存の呼び出し元（step_0a, step_2）のインターフェースは変更しない

## ユビキタス言語

- **リモート解決**: ブランチ名からそのブランチが追跡するリモートを特定するプロセス
- **探索キー（effective_branch）**: refs/remotes および ls-remote 探索で使用するブランチパス。引数 `branch_name` または グローバル `BRANCH_NAME` から決定
- **フォールバック**: 優先順の探索がすべて失敗した場合の最終手段（origin → 最初のリモート）
- **refs/remotes**: git がローカルにキャッシュしているリモートブランチの参照情報
- **ls-remote**: リモートサーバーに直接問い合わせてブランチの存在を確認するコマンド
