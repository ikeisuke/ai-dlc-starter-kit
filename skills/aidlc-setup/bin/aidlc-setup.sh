#!/usr/bin/env bash
#
# aidlc-setup.sh - AI-DLCアップグレードオーケストレーションスクリプト（v2）
#
# バージョン更新・設定マイグレーションを一括実行する。
# プロジェクトルートをカレントディレクトリとして実行すること。
#
# 使用方法:
#   ./aidlc-setup.sh [OPTIONS]
#
# オプション:
#   --dry-run       実際の変更を行わず差分を表示
#   --no-migrate    設定マイグレーションをスキップ
#   --force         アップグレード不要でも強制実行
#   --help          ヘルプを表示
#
# 出力形式:
#   key:value形式（サブスクリプト出力は透過転送）
#
# 終了コード:
#   0: 正常終了（成功またはスキップ）
#   1: エラー
#

set -euo pipefail

# === 共通ライブラリ読み込み ===
_SETUP_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SETUP_SCRIPT_DIR}/../../aidlc/scripts/lib"
if [[ -f "${_LIB_DIR}/version.sh" ]]; then
    source "${_LIB_DIR}/version.sh"
else
    echo "error:version-lib-not-found" >&2
    exit 1
fi

# === デフォルト値 ===
DRY_RUN=false
NO_MIGRATE=false
FORCE=false

# === 設定ファイルパス ===
CONFIG_PATH=".aidlc/config.toml"

# === ヘルプ ===
show_help() {
    cat <<'HELP'
Usage: aidlc-setup.sh [OPTIONS]

AI-DLCアップグレードオーケストレーションスクリプト（v2）。
バージョン更新・設定マイグレーションを一括実行します。

Options:
  --dry-run       実際の変更を行わず差分を表示
  --no-migrate    設定マイグレーションをスキップ
  --force         アップグレード不要でも強制実行
  --help          ヘルプを表示
HELP
}

# === 引数解析 ===
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --no-migrate)
            NO_MIGRATE=true
            shift
            ;;
        --force)
            FORCE=true
            shift
            ;;
        --help)
            show_help
            exit 0
            ;;
        *)
            echo "error:unknown-option:$1" >&2
            exit 1
            ;;
    esac
done

# === dasel必須チェック ===
if ! command -v dasel >/dev/null 2>&1; then
    echo "error:dasel-required" >&2
    echo "daselがインストールされていません。以下の方法でインストールしてください:" >&2
    echo "  macOS:  brew install dasel" >&2
    echo "  Linux:  https://github.com/TomWright/dasel#installation" >&2
    exit 1
fi

# === 出力サニタイズ（制御文字除去） ===
_sanitize() {
    printf '%s' "$1" | tr -d '\r\n\t'
}

# === 一時ファイル管理 ===
_cleanup_files=()
_cleanup() {
    for f in "${_cleanup_files[@]}"; do
        \rm -f "$f" 2>/dev/null || true
    done
}
trap _cleanup EXIT

# === mode出力 ===
if [[ "$DRY_RUN" == "true" ]]; then
    echo "mode:dry-run"
else
    echo "mode:execute"
fi

# === スクリプトディレクトリ解決（symlink対応） ===
resolve_script_dir() {
    local source="${BASH_SOURCE[0]:-$0}"
    while [[ -L "$source" ]]; do
        local dir
        dir="$(cd "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ "$source" != /* ]] && source="$dir/$source"
    done
    cd "$(dirname "$source")" && pwd
}

SCRIPT_DIR=$(resolve_script_dir)

# === Step 1: スターターキットパス解決 ===
resolve_starter_kit_root() {
    # 1. 環境変数が設定されていればそれを使用
    if [[ -n "${AIDLC_STARTER_KIT_PATH:-}" ]]; then
        if [[ ! -d "$AIDLC_STARTER_KIT_PATH" ]]; then
            echo "error:starter-kit-path-not-directory:$AIDLC_STARTER_KIT_PATH" >&2
            echo "detail:action:verify the path exists and is a directory" >&2
            return 1
        fi
        cd "$AIDLC_STARTER_KIT_PATH" && pwd
        return 0
    fi

    # 2. SCRIPT_DIR ベース解決: */skills/aidlc-setup/bin → 3階層上がルート
    if [[ "$SCRIPT_DIR" == */skills/aidlc-setup/bin ]]; then
        local candidate_root
        candidate_root="$(cd "$SCRIPT_DIR/../../.." && pwd)"
        # 算出したルートにスターターキットの既知ファイルが存在するか検証
        if [[ -f "$candidate_root/skills/aidlc/config/defaults.toml" ]]; then
            echo "$candidate_root"
            return 0
        fi
        # フォールバック: git リポジトリルートを試行
        local git_root
        git_root="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null)" || git_root=""
        if [[ -n "$git_root" && -f "$git_root/skills/aidlc/config/defaults.toml" ]]; then
            echo "$git_root"
            return 0
        fi
        echo "error:starter-kit-not-found:candidate root does not contain expected files" >&2
        echo "detail:candidate-root:$(_sanitize "$candidate_root")" >&2
        echo "detail:action:export AIDLC_STARTER_KIT_PATH=/path/to/ai-dlc-starter-kit" >&2
        return 1
    fi

    # 3. 上記以外
    echo "error:starter-kit-not-found:unknown script location" >&2
    echo "detail:script-dir:$(_sanitize "${SCRIPT_DIR}")" >&2
    echo "detail:action:export AIDLC_STARTER_KIT_PATH=/path/to/ai-dlc-starter-kit" >&2
    return 1
}

STARTER_KIT_ROOT=$(resolve_starter_kit_root) || exit 1
echo "starter_kit_path:${STARTER_KIT_ROOT}"

# === Step 2: 設定ファイル存在確認 ===
# v2プラグインモデルでは、config.toml が存在すればセットアップ済み。
# アップグレードは `claude update` で行う。
if [[ -f "$CONFIG_PATH" ]]; then
    if [[ "$FORCE" != "true" ]]; then
        echo "setup_type:already_configured"
        echo "config_path:${CONFIG_PATH}"
        echo "status:success"
        exit 0
    fi
    echo "config_path:${CONFIG_PATH}"
    echo "info:force-mode:continuing despite existing config"
else
    echo "error:config-not-found:${CONFIG_PATH}" >&2
    echo "detail:action:run /aidlc setup to initialize" >&2
    exit 1
fi

# === Step 4: バージョン情報取得 ===
VERSION_FILE="${STARTER_KIT_ROOT}/version.txt"
if [[ -f "$VERSION_FILE" ]]; then
    KIT_VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
    KIT_VERSION="$(strip_v_prefix "$KIT_VERSION")"
else
    KIT_VERSION="unknown"
fi

# バージョン形式バリデーション（共通関数使用）
if [[ "$KIT_VERSION" != "unknown" ]] && ! validate_semver "$KIT_VERSION"; then
    echo "warn:invalid-kit-version:${KIT_VERSION}"
    KIT_VERSION="unknown"
fi

PROJECT_VERSION="$(read_starter_kit_version "$CONFIG_PATH" 2>/dev/null)" || PROJECT_VERSION="unknown"

echo "version_from:${PROJECT_VERSION}"
echo "version_to:${KIT_VERSION}"

# === Step 5: 設定マイグレーション ===
if [[ "$NO_MIGRATE" == "true" ]]; then
    echo "migrate:skipped"
else
    MIGRATE_CONFIG="${STARTER_KIT_ROOT}/skills/aidlc/scripts/migrate-config.sh"

    if [[ ! -x "$MIGRATE_CONFIG" ]]; then
        echo "warn:migrate-config-not-found"
    else
        MIGRATE_ARGS=("--config" "$CONFIG_PATH")
        if [[ "$DRY_RUN" == "true" ]]; then
            MIGRATE_ARGS+=("--dry-run")
        fi

        set +e
        MIGRATE_OUTPUT="$("$MIGRATE_CONFIG" "${MIGRATE_ARGS[@]}")"
        MIGRATE_EXIT=$?
        set -e

        if [[ $MIGRATE_EXIT -ne 0 ]]; then
            echo "error:migrate-failed" >&2
            exit 1
        fi

        if printf '%s\n' "$MIGRATE_OUTPUT" | grep -q '^warn:'; then
            echo "warn:migrate-warnings"
        fi
    fi
fi

# === Step 6: AIツール設定 ===
_run_setup_ai_tools() {
    local script_path="$1"
    set +e
    "$script_path" >/dev/null 2>&1
    local exit_code=$?
    set -e
    if [[ "$exit_code" -ne 0 ]]; then
        echo "error:setup-ai-tools-failed" >&2
        exit 1
    fi
    echo "setup_ai_tools:success"
}

SETUP_AI_TOOLS="skills/aidlc/scripts/setup-ai-tools.sh"
SETUP_AI_TOOLS_FALLBACK="${STARTER_KIT_ROOT}/skills/aidlc/scripts/setup-ai-tools.sh"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "setup_ai_tools:skipped(dry-run)"
elif [[ -x "$SETUP_AI_TOOLS" ]]; then
    _run_setup_ai_tools "$SETUP_AI_TOOLS"
elif [[ -x "$SETUP_AI_TOOLS_FALLBACK" ]]; then
    echo "info:setup-ai-tools-fallback:${SETUP_AI_TOOLS_FALLBACK}"
    _run_setup_ai_tools "$SETUP_AI_TOOLS_FALLBACK"
else
    echo "warn:setup-ai-tools-not-found"
fi

# === Step 7: バージョン更新 ===
if [[ "$DRY_RUN" == "true" ]]; then
    echo "version_updated:skipped(dry-run)"
elif [[ "$KIT_VERSION" == "unknown" ]]; then
    echo "warn:version-update-skipped:kit-version-unknown"
else
    if grep -q "^starter_kit_version" "$CONFIG_PATH"; then
        TMP=$(mktemp)
        _cleanup_files+=("$TMP")
        sed "s|^starter_kit_version = .*|starter_kit_version = \"${KIT_VERSION}\"|" "$CONFIG_PATH" > "$TMP"
        \mv "$TMP" "$CONFIG_PATH"
    else
        TMP=$(mktemp)
        _cleanup_files+=("$TMP")
        echo "starter_kit_version = \"${KIT_VERSION}\"" > "$TMP"
        cat "$CONFIG_PATH" >> "$TMP"
        \mv "$TMP" "$CONFIG_PATH"
    fi
    echo "version_updated:true"
fi

# === 完了 ===
echo "status:success"
exit 0
