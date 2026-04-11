#!/usr/bin/env bash
#
# write-config.sh - 設定値を書き込み
#
# 使用方法:
#   ./write-config.sh <key> <value> [--scope <project|local>] [--dry-run]
#
# パラメータ:
#   key       - ドット区切りの設定キー（例: rules.git.merge_method）
#   value     - 設定値（文字列）
#   --scope   - 書き込み先スコープ（project / local、デフォルト: local）
#   --dry-run - 書き込みせず、対象ファイル・キー・値を表示
#
# 終了コード:
#   0 - 成功（値を書き込み）
#   1 - 書き込み失敗
#   2 - 引数エラー
#
# 書き込み先:
#   project: .aidlc/config.toml（プロジェクト共有設定）
#   local:   .aidlc/config.local.toml（個人設定）
#

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

# --- 引数パース ---
KEY=""
VALUE=""
SCOPE="local"
DRY_RUN="false"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --scope)
            shift
            if [[ $# -eq 0 ]]; then
                echo "config:error:missing-scope:--scope requires a value" >&2
                exit 2
            fi
            SCOPE="$1"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -*)
            echo "config:error:unknown-option:Unknown option: $1" >&2
            exit 2
            ;;
        *)
            if [[ -z "$KEY" ]]; then
                KEY="$1"
            elif [[ -z "$VALUE" ]]; then
                VALUE="$1"
            else
                echo "config:error:too-many-args:Too many positional arguments" >&2
                exit 2
            fi
            shift
            ;;
    esac
done

# --- バリデーション ---
if [[ -z "$KEY" ]]; then
    echo "config:error:missing-key:Key is required" >&2
    echo "Usage: $0 <key> <value> [--scope <project|local>] [--dry-run]" >&2
    exit 2
fi

if [[ -z "$VALUE" ]]; then
    echo "config:error:missing-value:Value is required" >&2
    exit 2
fi

if [[ ! "$KEY" =~ ^[A-Za-z_][A-Za-z0-9_.-]*$ ]]; then
    echo "config:error:invalid-key:Invalid key format: $KEY" >&2
    exit 2
fi

if [[ "$SCOPE" != "project" && "$SCOPE" != "local" ]]; then
    echo "config:error:invalid-scope:Scope must be 'project' or 'local', got: $SCOPE" >&2
    exit 2
fi

# --- ファイルパス決定 ---
if [[ "$SCOPE" == "project" ]]; then
    TARGET_FILE="$AIDLC_CONFIG"
else
    TARGET_FILE="$AIDLC_LOCAL_CONFIG"
fi

# --- dry-run ---
if [[ "$DRY_RUN" == "true" ]]; then
    echo "config:dry-run:${TARGET_FILE}:${KEY}=${VALUE}"
    exit 0
fi

# --- ファイル準備 ---
if [[ ! -f "$TARGET_FILE" ]]; then
    touch "$TARGET_FILE"
    if [[ "$SCOPE" == "local" ]]; then
        chmod 600 "$TARGET_FILE"
    fi
fi

# --- キー分解 ---
# rules.git.merge_method → section=rules.git, leaf=merge_method
# rules.reviewing.mode → section=rules.reviewing, leaf=mode
LEAF_KEY="${KEY##*.}"
SECTION_KEY="${KEY%.*}"

# TOML セクションヘッダー形式に変換
# rules.git → [rules.git]
SECTION_HEADER="[${SECTION_KEY}]"

# --- 書き込み ---

# 既存キーの値を更新する関数
update_existing_key() {
    local file="$1"
    local leaf="$2"
    local val="$3"

    # macOS/Linux 互換の sed -i
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "s/^${leaf} *= *\".*\"/${leaf} = \"${val}\"/" "$file"
        sed -i '' "s/^${leaf} *= *[^\"]*$/${leaf} = \"${val}\"/" "$file"
    else
        sed -i "s/^${leaf} *= *\".*\"/${leaf} = \"${val}\"/" "$file"
        sed -i "s/^${leaf} *= *[^\"]*$/${leaf} = \"${val}\"/" "$file"
    fi
}

# キーが既に存在するか確認
if grep -q "^${LEAF_KEY} *= *" "$TARGET_FILE" 2>/dev/null; then
    update_existing_key "$TARGET_FILE" "$LEAF_KEY" "$VALUE"
elif grep -q "^\\[${SECTION_KEY}\\]" "$TARGET_FILE" 2>/dev/null; then
    # セクションは存在するがキーがない → セクションの直後に追加
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "/^\\[${SECTION_KEY}\\]/a\\
${LEAF_KEY} = \"${VALUE}\"
" "$TARGET_FILE"
    else
        sed -i "/^\\[${SECTION_KEY}\\]/a\\${LEAF_KEY} = \"${VALUE}\"" "$TARGET_FILE"
    fi
else
    # セクションもキーもない → ファイル末尾に追加
    {
        echo ""
        echo "${SECTION_HEADER}"
        echo "${LEAF_KEY} = \"${VALUE}\""
    } >> "$TARGET_FILE"
fi

echo "config:written:${TARGET_FILE}:${KEY}=${VALUE}"
exit 0
