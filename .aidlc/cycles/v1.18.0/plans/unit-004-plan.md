# Unit 004 計画: スクリプトバグ修正

## 概要

issue-ops.sh、squash-unit.sh、resolve-starter-kit-path.sh の3つのスクリプトのバグ修正・改善を行う。

## 変更対象ファイル

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `prompts/package/bin/issue-ops.sh` | 修正 | `parse_gh_error()` にラベル未作成エラーの識別追加 |
| `prompts/package/bin/squash-unit.sh` | 修正 | ルートコミット検出・代替処理の追加 |
| `prompts/package/bin/resolve-starter-kit-path.sh` | 新規作成 | スターターキットパス解決スクリプト |

## 実装計画

### 修正1: issue-ops.sh（#250）

**現状**: `parse_gh_error()` はエラー出力を `not-found` / `auth-error` / `unknown` の3種に分類しているが、ラベルが未作成の場合のエラーを個別に識別できない。

**修正内容**:
- `parse_gh_error()` に `label-not-found` エラーの識別パターンを追加
- GitHubのラベル関連エラーメッセージ（`"label" ... "not found"` 等）をパターンマッチ

### 修正2: squash-unit.sh（#251）

**現状**: `find_base_commit_git()` と事後squash処理で、baseがリポジトリのルートコミット（親コミットなし）の場合に `git rebase -i` の基点設定が失敗する。

**修正内容**:
- ルートコミット検出ロジックの追加（`git rev-list --max-parents=0 HEAD` で取得したルートコミットとの比較）
- ルートコミット時の影響箇所（3点）を修正:
  1. `squash_retroactive_git()` のrebase基点: `git rebase -i --root` を使用する分岐を追加
  2. `extract_co_authors_for_range()`: `${first_full}^..` 参照をルートコミット対応に変更
  3. dry-run表示: `${UNIT_FIRST_COMMIT_FULL}^..` 参照をルートコミット対応に変更
- 通常squash（`git reset --soft`方式）でもルートコミットに対応

### 新規作成: resolve-starter-kit-path.sh（#252）

**現状**: スクリプトが存在しない。

**作成内容**:
- スクリプト実行位置からスターターキットのルートパスを解決するユーティリティスクリプト
- `docs/aidlc/bin/` から実行された場合（利用プロジェクト）と `prompts/package/bin/` から実行された場合（メタ開発）の両方に対応
- シンボリックリンク・worktree環境での正確なパス解決
- bash 3.x互換を維持

## 完了条件チェックリスト

- [x] issue-ops.sh: 存在しないラベルを付与しようとした場合に `label-not-found` が出力される
- [x] squash-unit.sh: baseがルートコミットの場合にsquashが正常完了する
- [x] resolve-starter-kit-path.sh: `docs/aidlc/bin/` と `prompts/package/bin/` の両方から正しいパスが解決される
