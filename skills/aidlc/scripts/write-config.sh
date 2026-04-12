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
source "${SCRIPT_DIR}/lib/key-aliases.sh"

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

# --- ユーティリティ ---

# 正規表現メタ文字をエスケープ（grep/sed パターン用）
escape_regex() {
    printf '%s' "$1" | sed 's/\./\\./g; s/\[/\\[/g; s/\]/\\]/g; s/\*/\\*/g; s/\^/\\^/g; s/\$/\\$/g'
}

# sed 置換文字列のエスケープ（\, &, / を無害化）
escape_sed_replacement() {
    printf '%s' "$1" | sed -e 's/[\/&\\]/\\&/g'
}

# TOML 基本文字列としてエスケープ（" と \ を無害化）
escape_toml_value() {
    local v="$1"
    v="${v//\\/\\\\}"
    v="${v//\"/\\\"}"
    printf '%s' "$v"
}

# --- セクション範囲内でリーフキーが存在するか判定 ---
# 引数: $1=file, $2=section, $3=leaf
# 戻り値: 0=存在, 1=不在
key_exists_in_section() {
    local file="$1"
    local section="$2"
    local leaf="$3"

    [[ -f "$file" ]] || return 1

    local esc_section
    esc_section=$(escape_regex "$section")
    local esc_leaf
    esc_leaf=$(escape_regex "$leaf")

    # セクションヘッダーの行番号を取得
    local section_line
    section_line=$(grep -n "^\\[${esc_section}\\]$" "$file" 2>/dev/null | head -1 | cut -d: -f1)
    [[ -n "$section_line" ]] || return 1

    # 次のセクションヘッダーの行番号を取得（なければファイル末尾）
    local total_lines
    total_lines=$(wc -l < "$file" | tr -d ' ')
    local next_section_line
    next_section_line=$(tail -n +"$((section_line + 1))" "$file" | grep -n "^\\[" | head -1 | cut -d: -f1)

    local end_line
    if [[ -n "$next_section_line" ]]; then
        end_line=$((section_line + next_section_line - 1))
    else
        end_line="$total_lines"
    fi

    # セクション範囲内でリーフキーを検索
    sed -n "$((section_line + 1)),${end_line}p" "$file" | grep -q "^${esc_leaf} *= *"
}

# --- セクション範囲内の既存キーの値を更新する関数 ---
# 引数: $1=file, $2=section, $3=leaf, $4=value
update_existing_key() {
    local file="$1"
    local section="$2"
    local leaf="$3"
    local val="$4"

    local esc_section
    esc_section=$(escape_regex "$section")
    local esc_leaf
    esc_leaf=$(escape_regex "$leaf")
    local safe_val
    safe_val=$(escape_toml_value "$val")
    local sed_val
    sed_val=$(escape_sed_replacement "$safe_val")

    # セクションヘッダーの行番号を取得
    local section_line
    section_line=$(grep -n "^\\[${esc_section}\\]$" "$file" | head -1 | cut -d: -f1)

    # 次のセクションヘッダーの行番号を取得
    local total_lines
    total_lines=$(wc -l < "$file" | tr -d ' ')
    local next_section_line
    next_section_line=$(tail -n +"$((section_line + 1))" "$file" | grep -n "^\\[" | head -1 | cut -d: -f1)

    local end_line
    if [[ -n "$next_section_line" ]]; then
        end_line=$((section_line + next_section_line - 1))
    else
        end_line="$total_lines"
    fi

    # セクション範囲内のみ sed 置換
    local start=$((section_line + 1))
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "${start},${end_line}s/^${esc_leaf} *= *\".*\"/${leaf} = \"${sed_val}\"/" "$file"
        sed -i '' "${start},${end_line}s/^${esc_leaf} *= *[^\"]*$/${leaf} = \"${sed_val}\"/" "$file"
    else
        sed -i "${start},${end_line}s/^${esc_leaf} *= *\".*\"/${leaf} = \"${sed_val}\"/" "$file"
        sed -i "${start},${end_line}s/^${esc_leaf} *= *[^\"]*$/${leaf} = \"${sed_val}\"/" "$file"
    fi
}

# --- 書き込み先決定 ---
# 引数: $1=input_key, $2=file
# stdout: section\tleaf\taction\tcanonical_key\tlegacy_key (タブ区切り)
# 戻り値: 0=成功
resolve_write_target() {
    local input_key="$1"
    local file="$2"

    # 正規化
    local canonical_key
    canonical_key=$(aidlc_normalize_key "$input_key")
    local legacy_key
    legacy_key=$(aidlc_get_legacy_key "$canonical_key")

    # canonical key を分解
    local canonical_section="${canonical_key%.*}"
    local canonical_leaf="${canonical_key##*.}"

    # 1. canonical key がファイル内に存在するか
    if [[ -f "$file" ]] && key_exists_in_section "$file" "$canonical_section" "$canonical_leaf"; then
        printf '%s\t%s\t%s\t%s\t%s\n' "$canonical_section" "$canonical_leaf" "update" "$canonical_key" "$legacy_key"
        return 0
    fi

    # 2. legacy key が存在する場合、ファイル内にlegacy keyがあるか確認
    if [[ -n "$legacy_key" ]]; then
        local legacy_section="${legacy_key%.*}"
        local legacy_leaf="${legacy_key##*.}"
        if [[ -f "$file" ]] && key_exists_in_section "$file" "$legacy_section" "$legacy_leaf"; then
            printf '%s\t%s\t%s\t%s\t%s\n' "$legacy_section" "$legacy_leaf" "update_legacy" "$canonical_key" "$legacy_key"
            return 0
        fi
    fi

    # 3. どちらも不在 → canonical key で新規作成
    printf '%s\t%s\t%s\t%s\t%s\n' "$canonical_section" "$canonical_leaf" "create" "$canonical_key" "$legacy_key"
    return 0
}

# --- 書き込み先解決 ---
WRITE_RESULT=$(resolve_write_target "$KEY" "$TARGET_FILE")
IFS=$'\t' read -r WRITE_SECTION WRITE_LEAF WRITE_ACTION WRITE_CANONICAL WRITE_LEGACY <<< "$WRITE_RESULT"
SECTION_HEADER="[${WRITE_SECTION}]"

# --- dry-run ---
if [[ "$DRY_RUN" == "true" ]]; then
    echo "config:dry-run:${TARGET_FILE}:${KEY}=${VALUE}:action=${WRITE_ACTION}:canonical=${WRITE_CANONICAL}:legacy=${WRITE_LEGACY}"
    exit 0
fi

# --- ファイル準備 ---
if [[ ! -f "$TARGET_FILE" ]]; then
    touch "$TARGET_FILE"
    if [[ "$SCOPE" == "local" ]]; then
        chmod 600 "$TARGET_FILE"
    fi
fi

# --- 書き込み ---
SAFE_VALUE=$(escape_toml_value "$VALUE")

case "$WRITE_ACTION" in
    update|update_legacy)
        update_existing_key "$TARGET_FILE" "$WRITE_SECTION" "$WRITE_LEAF" "$VALUE"
        ;;
    create)
        esc_ws=$(escape_regex "$WRITE_SECTION")
        if grep -q "^\\[${esc_ws}\\]$" "$TARGET_FILE" 2>/dev/null; then
            # セクションは存在するがキーがない → セクションの直後に追加
            if [[ "$(uname)" == "Darwin" ]]; then
                sed -i '' "/^\\[${esc_ws}\\]$/a\\
${WRITE_LEAF} = \"${SAFE_VALUE}\"
" "$TARGET_FILE"
            else
                sed -i "/^\\[${esc_ws}\\]$/a\\${WRITE_LEAF} = \"${SAFE_VALUE}\"" "$TARGET_FILE"
            fi
        else
            # セクションもキーもない → ファイル末尾に追加
            {
                echo ""
                echo "${SECTION_HEADER}"
                echo "${WRITE_LEAF} = \"${SAFE_VALUE}\""
            } >> "$TARGET_FILE"
        fi
        ;;
esac

echo "config:written:${TARGET_FILE}:${KEY}=${VALUE}"
exit 0
