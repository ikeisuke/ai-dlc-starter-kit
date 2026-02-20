# Unit 001 計画: シェルスクリプトバグ修正

## 概要

`aidlc-git-info.sh` のworktree VCS検出バグと `suggest-version.sh` のSemVerバリデーション不足を修正する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/bin/aidlc-git-info.sh` | `detect_vcs()` 関数の `.git` 判定を `-d` から `-e` に変更、`command -v git` チェック追加 |
| `prompts/package/bin/suggest-version.sh` | `get_latest_cycle()` 関数にSemVerバリデーション（grep -E）を追加 |

## 実装計画

### Bug 1: `aidlc-git-info.sh` の `detect_vcs()` 修正

**問題**: 30行目で `-d ".git"` を使用しているが、worktree環境では `.git` はディレクトリではなくファイル（メインリポジトリの `.git` ディレクトリへのパスを記載したファイル）になる。そのため `-d` テストが失敗し、VCSが `unknown` として検出される。

**修正内容**:

1. `-d ".git"` を `-e ".git"` に変更し、ファイル/ディレクトリの両方に対応する
2. jjの判定と一貫性を保つため、`command -v git` チェックも追加する

```bash
# Before
if [[ -d ".git" ]]; then

# After
if [[ -e ".git" ]] && command -v git >/dev/null 2>&1; then
```

### Bug 2: `suggest-version.sh` の `get_latest_cycle()` 修正

**問題**: `ls -d docs/cycles/v*/` でディレクトリを列挙する際、SemVerに準拠しないディレクトリ名（例: `v1.0.0-beta`, `vtest` 等）も含まれてしまう。`sort -V` と `tail -1` で最新を取得する際に不正な値が選択される可能性がある。

**修正内容**: `grep -E` でSemVerパターンフィルタを追加する。既存の `ls` パイプラインにフィルタを挿入する最小変更とする。

```bash
# Before
cycles=$(ls -d docs/cycles/v*/ 2>/dev/null | sort -V | tail -1 || echo "")

# After
cycles=$(ls -d docs/cycles/v*/ 2>/dev/null | grep -E '/v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)/$' | sort -V | tail -1 || echo "")
```

## 完了条件チェックリスト

- [ ] `aidlc-git-info.sh` の `detect_vcs()` 関数を修正し、worktree環境でVCSを正しく検出する
- [ ] `aidlc-git-info.sh` の `detect_vcs()` でgitコマンド存在チェックを追加し、jjとの一貫性を確保する
- [ ] `suggest-version.sh` の `get_latest_cycle()` 関数にSemVerバリデーションを追加する
- [ ] worktree環境で `vcs_type:git` が正しく検出されることを確認する
- [ ] 通常clone環境でも既存の挙動が維持されることを確認する
- [ ] SemVer非準拠ディレクトリが混在する場合に正しくフィルタされることを確認する
