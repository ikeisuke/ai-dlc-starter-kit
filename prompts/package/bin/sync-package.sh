#!/usr/bin/env bash
#
# sync-package.sh - prompts/package/からdocs/aidlc/へのrsync同期
#
# 使用方法:
#   ./sync-package.sh [--source <path>] [--dest <path>] [--delete] [--dry-run]
#
# パラメータ:
#   --source <path>: ソースディレクトリ（デフォルト: prompts/package/）
#   --dest <path>: 宛先ディレクトリ（デフォルト: docs/aidlc/）
#   --delete: 宛先のみに存在するファイルを削除（明示指定時のみ有効）
#   --dry-run: 実際の同期を行わず、差分を表示
#
# 出力形式:
#   - 成功: "sync:success" + 詳細行
#   - dry-run: "sync:dry-run" + 詳細行
#   - エラー: "error:<エラー種別>"
#
# 終了コード:
#   0: 正常終了（同期成功またはdry-run）
#   1: エラー
#

set -euo pipefail

# デフォルト値
SOURCE="prompts/package/"
DEST="docs/aidlc/"
DELETE=false
DRY_RUN=false

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --source)
            if [[ $# -lt 2 ]]; then
                echo "error:missing-source-value"
                exit 1
            fi
            SOURCE="$2"
            shift 2
            ;;
        --dest)
            if [[ $# -lt 2 ]]; then
                echo "error:missing-dest-value"
                exit 1
            fi
            DEST="$2"
            shift 2
            ;;
        --delete)
            DELETE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "error:unknown-option:$1"
            exit 1
            ;;
    esac
done

# 末尾スラッシュ保証（rsyncの仕様上必要）
[[ "$SOURCE" != */ ]] && SOURCE="${SOURCE}/"
[[ "$DEST" != */ ]] && DEST="${DEST}/"

# rsync存在確認
if ! command -v rsync >/dev/null 2>&1; then
    echo "error:rsync-not-installed"
    exit 1
fi

# ソースディレクトリ存在確認
if [[ ! -d "$SOURCE" ]]; then
    echo "error:source-not-found"
    exit 1
fi

# 宛先ディレクトリ存在確認
if [[ ! -d "$DEST" ]]; then
    echo "error:destination-not-found"
    exit 1
fi

# rsyncオプション構築
_rsync_opts=(-a --checksum --itemize-changes --exclude '.DS_Store' --exclude '.github')

if [[ "$DELETE" == "true" ]]; then
    _rsync_opts+=(--delete)
fi

if [[ "$DRY_RUN" == "true" ]]; then
    _rsync_opts+=(--dry-run)
fi

# rsync実行（出力を一時ファイルに保存してストリーム処理）
_tmp_stdout=$(mktemp) || { echo "error:mktemp-failed"; exit 1; }
_tmp_stderr=$(mktemp) || { \rm -f "$_tmp_stdout"; echo "error:mktemp-failed"; exit 1; }
trap '\rm -f "$_tmp_stdout" "$_tmp_stderr"' EXIT

set +e
rsync "${_rsync_opts[@]}" "$SOURCE" "$DEST" >"$_tmp_stdout" 2>"$_tmp_stderr"
_rsync_exit=$?
set -e

if [[ "$_rsync_exit" -ne 0 ]]; then
    _stderr_content=$(cat "$_tmp_stderr" 2>/dev/null || true)
    if [[ -n "$_stderr_content" ]]; then
        echo "error:rsync-failed:${_stderr_content%%$'\n'*}"
    else
        echo "error:rsync-failed"
    fi
    exit 1
fi

# 状態行出力
if [[ "$DRY_RUN" == "true" ]]; then
    echo "sync:dry-run"
else
    echo "sync:success"
fi
echo "source:${SOURCE}"
echo "destination:${DEST}"

# itemize-changes出力をkey:value形式に変換
while IFS= read -r line; do
    [[ -z "$line" ]] && continue

    # 削除: *deleting で始まる（スペース数はrsyncバージョン依存のため正規表現で抽出）
    if [[ "$line" =~ ^\*deleting[[:space:]]+(.+)$ ]]; then
        _path="${BASH_REMATCH[1]}"
        # ディレクトリ（末尾/）はスキップ
        [[ "$_path" == */ ]] && continue
        echo "sync_deleted:${_path}"
        continue
    fi

    # ディレクトリ変更（cdで始まる）: スキップ
    if [[ "$line" == cd* ]]; then
        continue
    fi

    # ファイル変更を抽出（スペース区切りで2番目がパス）
    _itemize="${line%% *}"
    _path="${line#* }"

    # ディレクトリ（末尾/）はスキップ
    [[ "$_path" == */ ]] && continue

    # >f で始まるもののみ処理（ファイル転送）
    if [[ "$_itemize" == ">f"* ]]; then
        # 新規作成: >f の後が全て + のパターン（プラス数はrsyncバージョン依存）
        _attrs="${_itemize#>f}"
        if [[ "$_attrs" =~ ^\++$ ]]; then
            echo "sync_added:${_path}"
        else
            echo "sync_updated:${_path}"
        fi
    fi
done < "$_tmp_stdout"
