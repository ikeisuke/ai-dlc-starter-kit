#!/usr/bin/env bash
# check-defaults-sync.sh - defaults.toml の正本とコピーの同期チェック (2 段階比較)
#
# 正本 (skills/aidlc/config/defaults.toml) と
# コピー (skills/aidlc-setup/config/defaults.toml) の
# TOML 設定値部分が一致することを検証する。
#
# Phase 1 (diagnostic): コメント・空行を除外した行ベース diff (人間可読補助表示のみ、gate には使わない)
# Phase 2 (gate): dasel + jq による構造比較 (キーパス集合 + 値型 + 値そのものの一致を判定し exit code を決定)
#
# 終了コード:
#   0 - sync:ok (Phase 2 一致)
#   1 - sync:mismatch (Phase 2 で key-missing / type-mismatch / value-mismatch 検出)
#   2 - error:not-found (ファイル不在)
#   3 - error:parse-error (dasel TOML パース失敗)
#   4 - error:tool-missing (dasel / jq 不在)
#
# 失敗時 stderr (machine-readable failure contract):
#   error:key-missing-in-source:<path>
#   error:key-missing-in-copy:<path>
#   error:type-mismatch:<path>:<source_type>:<copy_type>
#   error:value-mismatch:<path>:<source_value_json>:<copy_value_json>
#   error:parse-error:<file>:<message>
#   error:tool-missing:<tool>
#
# 仕様 SoT: .aidlc/cycles/v2.6.5/design-artifacts/logical-designs/unit_004_defaults_toml_sync_guard_logical_design.md
# v2.6.5 / #714 / Unit 004

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
# テスト時の override 用環境変数 (Unit 004 ドッグフーディング検証 / 通常運用では未設定)
SOURCE="${AIDLC_DEFAULTS_SYNC_SOURCE_OVERRIDE:-${REPO_ROOT}/skills/aidlc/config/defaults.toml}"
COPY="${AIDLC_DEFAULTS_SYNC_COPY_OVERRIDE:-${REPO_ROOT}/skills/aidlc-setup/config/defaults.toml}"

# ファイル存在チェック
if [ ! -f "$SOURCE" ]; then
    echo "error:not-found:$SOURCE"
    exit 2
fi

if [ ! -f "$COPY" ]; then
    echo "error:not-found:$COPY"
    exit 2
fi

# ============================================================
# Phase 1: 行ベース diff (diagnostic / 人間可読補助表示のみ)
# ============================================================
diff_result=$(diff <(grep -v '^[[:space:]]*#' "$SOURCE" | grep -v '^[[:space:]]*$') \
                   <(grep -v '^[[:space:]]*#' "$COPY" | grep -v '^[[:space:]]*$') || true)

if [ -z "$diff_result" ]; then
    phase1_status="sync:ok"
else
    phase1_status="sync:mismatch"
fi

echo "$phase1_status"

if [ -n "$diff_result" ]; then
    echo ""
    echo "[Phase 1 diagnostic] 以下の行差分があります (コメント・整形差分含む / gate には使わない):"
    echo "$diff_result"
fi

# ============================================================
# Phase 2: 構造比較 (gate / exit code を決定する正規ガード)
# ============================================================

# 依存ツール存在チェック (依存解決の二次防御)
for tool in dasel jq; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo ""
        echo "正本: $SOURCE"
        echo "コピー: $COPY"
        echo "修復方法: $tool をインストールしてください (CI: pr-check.yml の defaults-sync-check ジョブで dasel は sha256 検証つき curl ダウンロード / jq は ubuntu-latest preinstalled)"
        echo "error:tool-missing:$tool" >&2
        exit 4
    fi
done

# TOML を JSON 化してキーパスを列挙する関数
# 出力: "<path>\t<type>\t<value_json>" の行 (LC_ALL=C sort 済み)
# value_json は jq の tojson 形式 (例: 文字列は `"foo"`、数値は `3`、真偽値は `true`)
extract_keys_with_types() {
    local file="$1"
    local json_output
    if ! json_output=$(cat "$file" | dasel -i toml -o json 2>&1); then
        echo "error:parse-error:$file:$json_output" >&2
        return 3
    fi
    # jq の tostream で末端 scalar の (path, type, value) を抽出
    # leaf 行のみ (length == 2) を選択、空のオブジェクト/配列は除外
    # 配列インデックスは文字列化される (例: rules.reviewing.tools.0)
    printf '%s' "$json_output" | jq -r 'tostream | select(length == 2) | "\(.[0] | map(tostring) | join("."))\t\(.[1] | type)\t\(.[1] | tojson)"' 2>/dev/null | LC_ALL=C sort -u
}

# キー + 型 + 値を抽出
source_keys=$(extract_keys_with_types "$SOURCE") || exit 3
copy_keys=$(extract_keys_with_types "$COPY") || exit 3

# 一時ファイルに保存
source_tmp=$(mktemp)
copy_tmp=$(mktemp)
trap 'rm -f "$source_tmp" "$copy_tmp"' EXIT
printf '%s\n' "$source_keys" > "$source_tmp"
printf '%s\n' "$copy_keys" > "$copy_tmp"

# キーパス集合 (型情報除く) を抽出
source_paths=$(cut -f1 "$source_tmp" | LC_ALL=C sort -u)
copy_paths=$(cut -f1 "$copy_tmp" | LC_ALL=C sort -u)

source_paths_tmp=$(mktemp)
copy_paths_tmp=$(mktemp)
trap 'rm -f "$source_tmp" "$copy_tmp" "$source_paths_tmp" "$copy_paths_tmp"' EXIT
printf '%s\n' "$source_paths" > "$source_paths_tmp"
printf '%s\n' "$copy_paths" > "$copy_paths_tmp"

# 対称差を計算
missing_in_copy=$(LC_ALL=C comm -23 "$source_paths_tmp" "$copy_paths_tmp")
missing_in_source=$(LC_ALL=C comm -13 "$source_paths_tmp" "$copy_paths_tmp")

mismatch_count=0

# Phase 2 failure contract を stderr 出力
if [ -n "$missing_in_copy" ]; then
    while IFS= read -r path; do
        [ -z "$path" ] && continue
        echo "error:key-missing-in-copy:$path" >&2
        mismatch_count=$((mismatch_count + 1))
    done <<< "$missing_in_copy"
fi

if [ -n "$missing_in_source" ]; then
    while IFS= read -r path; do
        [ -z "$path" ] && continue
        echo "error:key-missing-in-source:$path" >&2
        mismatch_count=$((mismatch_count + 1))
    done <<< "$missing_in_source"
fi

# 両方にあるキーの型 + 値を比較
common_paths=$(LC_ALL=C comm -12 "$source_paths_tmp" "$copy_paths_tmp")
if [ -n "$common_paths" ]; then
    while IFS= read -r path; do
        [ -z "$path" ] && continue
        source_type=$(awk -v p="$path" -F'\t' '$1 == p { print $2; exit }' "$source_tmp")
        copy_type=$(awk -v p="$path" -F'\t' '$1 == p { print $2; exit }' "$copy_tmp")
        if [ "$source_type" != "$copy_type" ]; then
            echo "error:type-mismatch:$path:$source_type:$copy_type" >&2
            mismatch_count=$((mismatch_count + 1))
            continue
        fi
        source_value=$(awk -v p="$path" -F'\t' '$1 == p { print $3; exit }' "$source_tmp")
        copy_value=$(awk -v p="$path" -F'\t' '$1 == p { print $3; exit }' "$copy_tmp")
        if [ "$source_value" != "$copy_value" ]; then
            echo "error:value-mismatch:$path:$source_value:$copy_value" >&2
            mismatch_count=$((mismatch_count + 1))
        fi
    done <<< "$common_paths"
fi

# 修復方法表示
echo ""
echo "正本: $SOURCE"
echo "コピー: $COPY"

if [ "$mismatch_count" -eq 0 ]; then
    echo "[Phase 2 gate] 構造比較: ok (キー集合 + 型 + 値 一致)"
    exit 0
else
    echo "[Phase 2 gate] 構造比較: mismatch ($mismatch_count 件、stderr の error: 行参照)"
    echo ""
    echo "修復方法:"
    echo "  1. 正本側で意図した変更の場合: aidlc-setup 側に同セクションを追加 (手動 Edit)"
    echo "  2. コピー側に余分なキーがある場合: 正本に合わせて削除"
    echo "  3. 詳細差分: 上記 Phase 1 diagnostic + stderr の error: 行を参照"
    echo "コマンド例:"
    echo "  diff skills/aidlc/config/defaults.toml skills/aidlc-setup/config/defaults.toml"
    exit 1
fi
