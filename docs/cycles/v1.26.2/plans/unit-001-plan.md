# Unit 001 計画: post-merge-cleanup.sh 通常ブランチ対応

## 概要
`post-merge-cleanup.sh` を拡張し、worktree環境と通常ブランチ環境の両方で動作するようにする。

## 変更対象ファイル
- `prompts/package/bin/post-merge-cleanup.sh` — メインの変更対象

## 実装計画

### 1. 環境判定の変更（step_0a）
- L145-147のworktree判定をエラー終了から環境フラグ設定に変更
- `IS_WORKTREE` グローバル変数を追加（`true`/`false`）
- worktree環境: `IS_WORKTREE=true`、従来のメインリポジトリパス特定処理を実行
- 通常ブランチ: `IS_WORKTREE=false`、`MAIN_REPO_PATH` に `git rev-parse --show-toplevel` を設定（出力契約 `main_repo_path:` を維持）
- 通常ブランチ: step_1のcheckoutでcurrent_branchが変わる前に `WT_REMOTE` をプリフェッチ（BRANCH_NAMEのブランチ設定からリモートを解決）
- `main_repo_path:` 出力は両環境で行う（通常ブランチ時は自リポジトリのパス）

### 2. step_1（デフォルトブランチ checkout + pull）
- コマンド的に分岐不要: `git -C $MAIN_REPO_PATH` は通常ブランチでも自リポジトリを指すため同一コードパスで動作
- ステップ名は「メインリポジトリpull」→「デフォルトブランチ更新」に変更
- 注意: step_1のcheckoutでcurrent_branchがデフォルトブランチに変わる副作用あり（step_2のWT_REMOTE解決に影響→step_0aのプリフェッチで対策済み）

### 3. step_2（fetch）
- worktree: 従来通り（current_branchベースでWT_REMOTE解決）
- 通常ブランチ: step_0aでWT_REMOTEプリフェッチ済みのため、リモート解決ブロックをスキップ
- ステップ名は「worktreeでfetch」→「fetch」に変更

### 4. step_3（detached HEAD / スキップ）の分岐
- worktree: 従来通り `git checkout --detach`
- 通常ブランチ: step_1で既にデフォルトブランチにcheckout済みのため、このステップをスキップ（`step_result:3:ok` を出力して終了）
- ステップ名は「detached HEAD切り替え」→「ブランチ状態整理」に変更

### 5. step_4, step_5（ブランチ削除）
- 変更不要（worktree/通常ブランチ共通の処理）

### 6. ヘルプ・コメント更新
- スクリプトヘッダのコメントからworktree専用表現を除去
- show_help()を更新して通常ブランチ対応を反映
- ステップ名の更新を反映

## 完了条件チェックリスト
- [ ] worktree/通常ブランチの環境自動判定が正しく動作する
- [ ] 通常ブランチ用のクリーンアップフロー（デフォルトブランチ checkout → pull → ブランチ削除）が正常に動作する
- [ ] 既存worktreeフローの後方互換性が維持される
- [ ] リモート名・デフォルトブランチ名がハードコードされず動的に解決される
- [ ] `main_repo_path:` 出力が両環境で維持される
- [ ] dry-runが両環境で正しく動作する
