# Unit 002: main最新化チェック判定ロジック - 実装計画

## 概要
setup-branch.shにmainブランチの最新化チェック機能を追加する。`git fetch origin`後に`origin/main`との差分を検出し、`main_status:up-to-date|behind|fetch-failed`のステータス行を出力する。

## 変更対象ファイル
- `prompts/package/bin/setup-branch.sh` — main最新化チェック機能の追加

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: MainFreshnessStatus値オブジェクト、チェックロジック
2. **論理設計**: 具体的な実装手順

### Phase 2: 実装

1. `check_main_freshness()`関数を**独立関数**として追加（ブランチ/worktree作成処理とは分離）:
   - `git fetch origin`を実行（失敗時は`main_status:fetch-failed`を出力して**即座にreturn 0**。処理は続行）
   - mainブランチ名を検出: `git rev-parse --verify origin/main`成功なら`main`、失敗なら`origin/master`を試行。両方なければ`main_status:fetch-failed`
   - 検出したリモート基準ブランチを変数`$remote_main`に格納（例: `origin/main` or `origin/master`）
   - **判定ロジック**: `git merge-base --is-ancestor "$remote_main" HEAD` — `$remote_main`がHEADの祖先かを判定
     - exit 0: `$remote_main`はHEADの祖先 → mainの全コミットが含まれている → `main_status:up-to-date`
     - exit 1: `$remote_main`はHEADの祖先でない → mainに未取り込みコミットがある → `main_status:behind`
     - exit 128等: git error → `main_status:fetch-failed`

2. `main()`関数内の`case`文による`handle_branch_mode`/`handle_worktree_mode`呼び出し**後**（成功時のみ）に`check_main_freshness`を呼び出す。作成処理の成否には影響しない。

3. `main_status:`は`output()`関数の外で独立出力する（既存の`output()`の引数・出力フォーマットは変更しない）

## 後方互換性

- `main_status:`行は既存の`status:`/`branch:`/`message:`行の**後に追加**される
- 既存の`output()`関数は変更しない。`main_status:`は独立した`echo`で出力
- **利用側確認済み**: inception.md（L573-579）がsetup-branch.shの出力を読んでいるが、`status:`/`branch:`/`message:`等のキーで行を識別しており、行番号やキー集合を固定するパースは行っていない。キーベースパース前提で問題なし
- `main_status:`行が存在しない場合も既存のパースに影響しない（新規追加行のため）

## 完了条件チェックリスト
- [ ] setup-branch.shにmain最新化チェックロジックが追加されている
- [ ] `main_status:up-to-date` / `main_status:behind` / `main_status:fetch-failed` のステータス行が出力される
- [ ] fetch失敗時はチェックをスキップして処理が続行される
- [ ] 既存のブランチ/worktree作成機能に影響を与えない
- [ ] `check_main_freshness()`がブランチ作成処理と責務分離されている
