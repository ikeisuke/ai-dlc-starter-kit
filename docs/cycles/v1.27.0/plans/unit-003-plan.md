# Unit 003 計画: post-merge-cleanup.sh ブランチ不在耐性

## 概要

`post-merge-cleanup.sh` の step_0a でローカルブランチが存在しない場合に `fatal_error` で全ステップが中断される問題を修正。警告に変更して後続ステップ（リモートブランチ削除等）を続行可能にする。

## 変更対象ファイル

- `prompts/package/bin/post-merge-cleanup.sh` — step_0a と step_4 の修正

## 実装計画

### 1. グローバル変数の追加

`LOCAL_BRANCH_EXISTS` フラグをグローバル変数に追加（デフォルト: `true`）。

### 2. step_0a の修正（L224-228）

ブランチ不在時:
- `fatal_error` → 警告出力 + `LOCAL_BRANCH_EXISTS=false` に変更
- `BRANCH_NAME` は引き続き設定（step_5のリモート削除で使用）
- `step_result:0a:ok` で正常続行

### 3. step_4 の修正（L360-377）

`LOCAL_BRANCH_EXISTS=false` の場合:
- ブランチ削除をスキップ
- `step_result:4:ok:skipped-branch-not-found` を出力
- `--dry-run` モードでもスキップ理由をログ出力

### 4. step_0a 通常ブランチモードのプリフェッチ修正（L232-234）

`LOCAL_BRANCH_EXISTS=false` の場合、ブランチベースの `resolve_remote` は空文字を渡す（ブランチ設定が存在しないため）。

## 完了条件チェックリスト

- [ ] step_0aのブランチ不在時の`fatal_error`を警告に変更
- [ ] ブランチ不在フラグ（`LOCAL_BRANCH_EXISTS`）をstep_0aで設定
- [ ] step_4にブランチ不在フラグ参照を追加し、不在時はスキップ
- [ ] `--dry-run`モードでのブランチ不在時にスキップ理由をログ出力
