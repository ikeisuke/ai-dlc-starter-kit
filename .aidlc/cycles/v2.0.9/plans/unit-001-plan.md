# Unit 001 計画: Inceptionステップファイル乖離修正

## 概要

Inception Phase ステップファイル（`skills/aidlc/steps/inception/01-setup.md`）の記述と、スクリプト実動作の乖離を3箇所修正する。スクリプト本体の変更は行わず、ドキュメント修正のみ。

## 変更対象ファイル

- `skills/aidlc/steps/inception/01-setup.md`（唯一の変更対象）

## 実装計画

### #471: check-open-issues.sh 出力形式の記述修正

**対象セクション**: 「10-1. コンテキスト表示」の `check-open-issues.sh` 説明部分
**現状**: `取得結果が0件の場合は「バックログ項目なし」と表示する`
**スクリプト実態**: 0件時は `open_issues:none` を出力する（`check-open-issues.sh` L74-75）
**修正**: 0件判定を `open_issues:none` 出力に合わせた記述に変更

### #472: init-cycle-dir.sh バックログディレクトリ記述の修正

**対象セクション**: 「13. サイクルディレクトリ作成」の `init-cycle-dir.sh` 説明部分
**現状**: `共通バックログディレクトリ（.aidlc/cycles/backlog/, .aidlc/cycles/backlog-completed/）` が作成対象として列挙されている
**スクリプト実態**: v2.0.3以降、`create_common_backlog_dirs()` は常に `skipped-issue-only` を出力しディレクトリ作成をスキップ（GitHub Issue固定のためローカルディレクトリは不要）
**修正内容**:
1. 説明文: バックログディレクトリが「作成される」ではなく「スキップされる」旨に変更
2. stdout出力例: `dir:.aidlc/cycles/backlog:skipped-issue-only` の状態値を明記
3. 状態値の説明: `skipped-issue-only` はGitHub Issue固定のためローカルディレクトリが不要であることを注記

### #473: setup-branch.sh worktree_path の名前付きサイクル形式の追記

**対象セクション**: 「11. ブランチ確認【推奨】」配下の `setup-branch.sh` 出力例部分
**現状**: 出力例が `v1.12.1` のみで、名前付きサイクル（スラッシュ含む）の例がない
**スクリプト実態**: `handle_worktree_mode()` で `${version//\//-}` によりスラッシュをハイフンに置換（例: `waf/v1.0.0` → `cycle-waf-v1.0.0`）
**修正**: 名前付きサイクル時の出力例を追記し、スラッシュ→ハイフン置換ルールを注記

## 完了条件チェックリスト

- [ ] check-open-issues.sh の出力例をステップファイルの記述に合わせて修正（#471）
- [ ] init-cycle-dir.sh のバックログディレクトリ記述を実態（skipped-issue-only）に合わせる（#472）
- [ ] setup-branch.sh の出力例に名前付きサイクル時のworktree_path形式を追記（#473）
