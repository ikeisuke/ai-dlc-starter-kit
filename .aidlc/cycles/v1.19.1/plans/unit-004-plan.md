# Unit 004 計画: post-merge-cleanup.sh運用組み込み

## 概要

Operations PhaseのPRマージ後手順（`operations.md` セクション5「PRマージ後の手順」）にworktree環境判定を追加し、worktree環境では `post-merge-cleanup.sh` を使用したクリーンアップフローを提供する。

## 変更対象ファイル

- `prompts/package/prompts/operations.md` — PRマージ後手順セクション（ステップ5）を修正

## 実装計画

### 変更内容

`operations.md` のセクション「5. PRマージ後の手順」にworktree環境分岐を追加する。

1. **ステップ0（未コミット変更の確認）の後にworktree環境判定を追加**
   - `git rev-parse --git-dir` の結果で判定（`.git` ディレクトリパスなら通常環境、`.git/worktrees/` を含むパスならworktree環境）
   - worktree環境 → worktree専用フローへ（ステップ1-4を代替するためスキップ）
   - 通常環境 → 従来の手順（ステップ1-4）を維持

2. **worktree環境フロー**（新規追加、ステップ1-4を完全代替）
   - スクリプトパスを探索（`prompts/package/bin/post-merge-cleanup.sh` → `docs/aidlc/bin/post-merge-cleanup.sh`）
   - dry-run を先に実行: `post-merge-cleanup.sh --cycle {{CYCLE}} --dry-run`
   - **失敗判定基準**: 終了コード `!= 0` で失敗と判定（`status:error` 出力を伴う）。終了コード `0` かつ `status:warning` は成功扱い
   - dry-run 成功時のみ本実行: `post-merge-cleanup.sh --cycle {{CYCLE}}`
   - dry-run 失敗時は本実行をスキップし、エラー内容を表示して手動対応を案内
   - **実行責務**: `post-merge-cleanup.sh` がmain pull、fetch、detached HEAD切り替え、ローカル/リモートブランチ削除をすべて実行するため、既存ステップ1（mainチェックアウト+pull）、ステップ4（ブランチ削除）に相当する処理は重複実行しない
   - 完了後はステップ3（バージョンタグ付け）へ合流（ステップ4はスクリプトが実行済みのためスキップ）

3. **非worktree環境フロー**
   - 既存のステップ1-4（mainチェックアウト → pull → タグ付け → ブランチ削除）をそのまま維持

### 実行責務マトリクス

| ステップ | 通常環境 | worktree環境 |
|---------|---------|-------------|
| 0. 未コミット変更確認 | 手動（既存） | 手動（既存）+ スクリプト内で再確認 |
| 1. mainチェックアウト+pull | 手動（既存） | スクリプトが実行（スキップ） |
| 2. fetch | N/A | スクリプトが実行 |
| 3. タグ付け | 手動（既存） | 手動（既存）※合流点 |
| 4. ブランチ削除 | 手動（既存） | スクリプトが実行（スキップ） |

## 完了条件チェックリスト

- [ ] `operations.md` のPRマージ後手順にworktree環境判定を追加
- [ ] worktree環境時の `post-merge-cleanup.sh` 呼び出しフロー（dry-run → 本実行）を追加
- [ ] 非worktree環境での従来手順を維持
