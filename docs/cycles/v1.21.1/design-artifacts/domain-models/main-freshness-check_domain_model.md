# ドメインモデル: main最新化チェック判定ロジック

## 値オブジェクト

### MainFreshnessStatus
mainブランチの最新化状態を表す列挙値:
- `up-to-date`: remote_mainの全コミットがtarget_refに含まれている
- `behind`: remote_mainにtarget_refに含まれていないコミットがある
- `fetch-failed`: fetchまたはリモートブランチ検出に失敗

### RemoteMainBranch
リモートのメインブランチ参照（get-default-branch.shと同じ検出ロジック）:
1. `git remote show origin`のHEAD branch（一次ソース、trunk等にも対応）
2. `origin/main`（フォールバック1）
3. `origin/master`（フォールバック2）

## ドメインサービス

### check_main_freshness()
独立関数。ブランチ/worktree作成処理とは完全に分離。

**責務**:
1. `git fetch origin`でリモートを更新
2. リモートのメインブランチ名を検出
3. `git merge-base --is-ancestor "$remote_main" "$target_ref"`で最新化を判定
4. `main_status:{status}`を標準出力

**入力**:
- `target_ref`（オプション）: 判定対象のgit参照。デフォルト`HEAD`。worktreeモードでは`cycle/${version}`を指定

**制約**:
- 常にreturn 0（処理を止めない）
- 既存のoutput()関数は変更しない
- `GIT_TERMINAL_PROMPT=0`で非対話実行（ハング防止）
- ネットワーク障害時は`fetch-failed`を出力して継続
