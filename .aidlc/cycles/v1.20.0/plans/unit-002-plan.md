# Unit 002 計画: 名前付きサイクルスクリプト対応

## 概要

名前付きサイクルの `[name]/vX.X.X` 形式に対応するため、5つのスクリプトの正規表現・パス処理を修正する。従来形式（`cycle/vX.X.X`）の後方互換を維持する。

## 変更対象ファイル

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `prompts/package/bin/setup-branch.sh` | 修正 | バージョンバリデーション（L137）を `[name]/vX.X.X` 形式に拡張、worktreeパス正規化 |
| `prompts/package/bin/aidlc-cycle-info.sh` | 修正 | ブランチ名パース（L42）を名前付き対応に拡張、`cycle_name` 出力追加、`cycle_dir` パス組み立て修正 |
| `prompts/package/bin/post-merge-cleanup.sh` | 修正 | バージョンバリデーション（L393）を名前付き形式に拡張 |
| `prompts/package/bin/init-cycle-dir.sh` | 修正 | スラッシュ含有チェック（L99-103）を緩和し、1レベルのスラッシュ（`[name]/vX.X.X`）を許可 |
| `prompts/package/bin/suggest-version.sh` | 修正 | ブランチパース（L24）とディレクトリスキャン（L34）を名前付き形式に対応 |

## バリデーション責務の方針

**スクリプト側の役割**: 構文チェックのみ（名前部分は `[^/]+` で非空・スラッシュ不含を確認）
**プロンプト側の役割（Unit 003）**: 厳格な名前バリデーション（`[a-z0-9][a-z0-9-]*` 等の文字制約）

スクリプトは入力値をそのまま使用し、渡された名前の文字種制約は行わない。これにより責務がUnit定義の境界（「サイクル名のバリデーションはプロンプト側の責務」）と整合する。

## prerelease互換性の方針

スクリプト間でprerelease（`-alpha.1`）の許容に既存の差異がある:
- 許可: `setup-branch.sh`、`post-merge-cleanup.sh`
- 不許可: `aidlc-cycle-info.sh`、`suggest-version.sh`

この差異は既存の設計判断であり、本Unitでは変更しない。名前付きサイクル対応はこの既存差異を維持したまま追加する。

## 実装計画

### 1. setup-branch.sh の修正

**L137**: バージョンバリデーション正規表現の拡張

```bash
# 変更前
if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then

# 変更後: 名前部分は [^/]+ で構文チェックのみ
if [[ ! "$version" =~ ^([^/]+/)?v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
```

**worktreeパスの正規化（L91）**: `version` にスラッシュが含まれる場合、worktreeパスが入れ子構造になる問題を回避。

```bash
# 変更前
local worktree_path=".worktree/cycle-${version}"

# 変更後: スラッシュをハイフンに正規化して1階層パスを維持
local worktree_path=".worktree/cycle-${version//\//-}"
```

ブランチ作成パス（`cycle/${version}`）は変更不要。`version` が `waf/v1.0.0` の場合、`cycle/waf/v1.0.0` が自然に生成される。

### 2. aidlc-cycle-info.sh の修正

**L42**: `extract_version()` のブランチ名パース拡張

```bash
# 変更前
if [[ "$branch" =~ ^cycle/(v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    echo "${BASH_REMATCH[1]}"
# BASH_REMATCH[1] = "v1.0.0"

# 変更後
if [[ "$branch" =~ ^cycle/(([^/]+/)?(v[0-9]+\.[0-9]+\.[0-9]+))$ ]]; then
    echo "${BASH_REMATCH[1]}"
# BASH_REMATCH[1] = "waf/v1.0.0" (全体) or "v1.0.0" (名前なし)
# BASH_REMATCH[2] = "waf/" or "" (名前部分+スラッシュ)
# BASH_REMATCH[3] = "v1.0.0" (バージョン部分のみ)
```

**出力契約の明確化**:

| 出力キー | 説明 | 名前なし例 | 名前付き例 |
|---------|------|-----------|-----------|
| `current_cycle` | 維持（全体パス） | `v1.0.0` | `waf/v1.0.0` |
| `cycle_name` | **新規追加** | `(空文字)` | `waf` |
| `cycle_version` | **新規追加** | `v1.0.0` | `v1.0.0` |
| `cycle_dir` | 維持（パス組み立て修正） | `docs/cycles/v1.0.0` | `docs/cycles/waf/v1.0.0` |

`current_cycle` は後方互換のため維持。呼び出し側が `cycle_name`/`cycle_version` を必要とする場合は新規キーを使用。

**L57**: `get_latest_cycle()` のディレクトリスキャンは変更不要。名前なし形式のみのlatest取得は既存動作を維持する。名前付きサイクルの走査はUnit 003以降で必要に応じて拡張。

### 3. post-merge-cleanup.sh の修正

**L393**: バージョンバリデーション正規表現の拡張

```bash
# 変更前
if ! printf '%s\n' "$CYCLE" | grep -qE '^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then

# 変更後: 名前部分は [^/]+ で構文チェックのみ
if ! printf '%s\n' "$CYCLE" | grep -qE '^([^/]+/)?v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$'; then
```

`BRANCH_NAME="cycle/${CYCLE}"` パスは変更不要。

### 4. init-cycle-dir.sh の修正

**L99-103**: スラッシュ含有チェックの緩和 + 構文バリデーション

```bash
# 変更前
if [[ "$version" == */* ]]; then
    echo "[error] ${version}: Version cannot contain slashes" >&2
    return 1
fi

# 変更後: パストラバーサル防止 + スラッシュ構文チェック
if [[ "$version" == *..* ]]; then
    echo "[error] ${version}: Version cannot contain path traversal (..)" >&2
    return 1
fi
if [[ "$version" == */*/*  ]]; then
    echo "[error] ${version}: Version cannot contain more than one slash" >&2
    return 1
fi
# 先頭・末尾スラッシュや空セグメント（/v1.0.0, name/, /）を拒否
if [[ "$version" == /* ]] || [[ "$version" == */ ]] || [[ "$version" == *"//"* ]]; then
    echo "[error] ${version}: Invalid format (leading/trailing slash or empty segment)" >&2
    return 1
fi
```

**注意**: `init-cycle-dir.sh` は既存仕様として任意の形式（SemVer以外含む）を受け付ける設計。スラッシュ制約の緩和のみ行い、SemVer構文チェック（`^([^/]+/)?v[0-9]+...`）はスクリプト呼び出し元（`setup-branch.sh` やプロンプト）が担保する。既存の後方互換（`feature-test` 等の非SemVer形式）を維持するため、ここではSemVer正規表現を追加しない。

パス生成（`base_path="docs/cycles/${version}"`）は変更不要。

### 5. suggest-version.sh の修正

**L24-25**: `get_branch_version()` のブランチパース拡張

```bash
# 変更前
if [[ "$branch" =~ ^cycle/v([0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
    echo "v${BASH_REMATCH[1]}"
# BASH_REMATCH[1] = "1.0.0" (数字部分のみ、vなし)
# 出力: "v1.0.0" (v付きで返却)

# 変更後
if [[ "$branch" =~ ^cycle/(([^/]+/)?(v([0-9]+\.[0-9]+\.[0-9]+)))$ ]]; then
    echo "${BASH_REMATCH[3]}"
# BASH_REMATCH[1] = "waf/v1.0.0" (全体) or "v1.0.0" (名前なし)
# BASH_REMATCH[2] = "waf/" or "" (名前部分+スラッシュ)
# BASH_REMATCH[3] = "v1.0.0" (v付きバージョン) ← 出力値
# BASH_REMATCH[4] = "1.0.0" (数字部分のみ、vなし)
# 出力: "v1.0.0" (既存と同等のv付き値)
```

**注意**: 既存コードは `echo "v${BASH_REMATCH[1]}"` でv接頭辞を付け直していた。変更後は `BASH_REMATCH[3]` が既にv付き（`v1.0.0`）のため `echo "${BASH_REMATCH[3]}"` でv付き出力を維持。

**名前部分の抽出**: `BASH_REMATCH[2]` から名前部分（末尾スラッシュ付き）を取得可能。名前なしの場合は空文字。

**L34**: `get_latest_cycle()` のディレクトリスキャン拡張

名前付きブランチの場合は該当名前のディレクトリ配下をスキャンする。

```bash
# 名前付きの場合（例: cycle_name=waf）
cycles=$(ls -d docs/cycles/waf/v*/ 2>/dev/null | grep -E '/v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)/$' | sort -V | tail -1 || echo "")

# 名前なしの場合（従来通り）
cycles=$(ls -d docs/cycles/v*/ 2>/dev/null | grep -E '/v(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)/$' | sort -V | tail -1 || echo "")
```

`get_branch_version()` からの戻り値に加え、名前部分を伝搬する方法（グローバル変数 or 関数引数）を実装時に決定する。

## 完了条件チェックリスト

- [ ] `setup-branch.sh`: `[name]/vX.X.X` 形式の入力を受け付け、`cycle/[name]/vX.X.X` ブランチを作成可能。worktreeパスはスラッシュをハイフンに正規化
- [ ] `aidlc-cycle-info.sh`: `cycle/[name]/vX.X.X` ブランチから `cycle_name`・`cycle_version`・`current_cycle` を正しく出力。`cycle_dir` が名前付きパスを正しく組み立て
- [ ] `post-merge-cleanup.sh`: `[name]/vX.X.X` 形式のバージョンを受け付け可能
- [ ] `init-cycle-dir.sh`: `[name]/vX.X.X` 形式を許可しつつ、2レベル以上のスラッシュとパストラバーサル（`..`）を拒否
- [ ] `suggest-version.sh`: 名前付きブランチからバージョン抽出（`BASH_REMATCH[3]`でv付き値を維持）、名前付きディレクトリのスキャンに対応
- [ ] 従来形式（`cycle/vX.X.X`、`docs/cycles/vX.X.X/`）の後方互換が維持されていること
