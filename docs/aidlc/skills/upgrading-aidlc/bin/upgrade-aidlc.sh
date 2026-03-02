#!/usr/bin/env bash
#
# upgrade-aidlc.sh - AI-DLCアップグレードオーケストレーションスクリプト
#
# バージョン更新・設定マイグレーション・rsync同期を一括実行する。
# プロジェクトルートをカレントディレクトリとして実行すること。
#
# 使用方法:
#   ./upgrade-aidlc.sh [OPTIONS]
#
# オプション:
#   --dry-run       実際の変更を行わず差分を表示
#   --config PATH   aidlc.tomlのパス（デフォルト: docs/aidlc.toml）
#   --no-sync       パッケージ同期をスキップ
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

# === デフォルト値 ===
DRY_RUN=false
CONFIG_PATH="docs/aidlc.toml"
NO_SYNC=false
NO_MIGRATE=false
FORCE=false

# === ヘルプ ===
show_help() {
    cat <<'HELP'
Usage: upgrade-aidlc.sh [OPTIONS]

AI-DLCアップグレードオーケストレーションスクリプト。
バージョン更新・設定マイグレーション・rsync同期を一括実行します。

Options:
  --dry-run       実際の変更を行わず差分を表示
  --config PATH   aidlc.tomlのパス（デフォルト: docs/aidlc.toml）
  --no-sync       パッケージ同期をスキップ
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
        --config)
            if [[ -z "${2:-}" ]]; then
                echo "error:missing-config-value" >&2
                exit 1
            fi
            CONFIG_PATH="$2"
            shift 2
            ;;
        --no-sync)
            NO_SYNC=true
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

# === 一時ファイル管理 ===
_cleanup_files=()
_cleanup() {
    for f in "${_cleanup_files[@]}"; do
        [[ -f "$f" ]] && \rm -f "$f"
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
            return 1
        fi
        cd "$AIDLC_STARTER_KIT_PATH" && pwd
        return 0
    fi

    # 2. メタ開発モード: */prompts/package/skills/*/bin
    if [[ "$SCRIPT_DIR" == */prompts/package/skills/*/bin ]]; then
        # 5階層上: bin/ → skill-name/ → skills/ → package/ → prompts/ → root
        cd "$SCRIPT_DIR/../../../../.." && pwd
        return 0
    fi

    # 3. 利用プロジェクトモード: */docs/aidlc/skills/*/bin
    if [[ "$SCRIPT_DIR" == */docs/aidlc/skills/*/bin ]]; then
        # ghqフォールバック: read-config.sh + ghq root でパス解決
        local project_root
        # 5階層上: bin/ → skill-name/ → skills/ → aidlc/ → docs/ → project-root
        project_root="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

        local read_config="${project_root}/docs/aidlc/bin/read-config.sh"
        if [[ ! -x "$read_config" ]]; then
            echo "error:starter-kit-not-found:read-config.sh not available" >&2
            return 1
        fi

        local raw_repo
        raw_repo=$("$read_config" project.starter_kit_repo --default "ghq:github.com/ikeisuke/ai-dlc-starter-kit" 2>/dev/null || true)

        if [[ -z "$raw_repo" ]]; then
            echo "error:starter-kit-not-found:cannot read starter_kit_repo" >&2
            return 1
        fi

        # ghq:プレフィックスを除去
        local repo="${raw_repo#ghq:}"

        # ghqが利用可能か確認
        if ! command -v ghq >/dev/null 2>&1; then
            echo "error:starter-kit-not-found:ghq not available, set AIDLC_STARTER_KIT_PATH" >&2
            return 1
        fi

        local ghq_root
        ghq_root=$(ghq root 2>/dev/null || true)
        if [[ -z "$ghq_root" ]]; then
            echo "error:starter-kit-not-found:ghq root failed" >&2
            return 1
        fi

        local kit_path="${ghq_root}/${repo}"
        if [[ ! -d "$kit_path" ]]; then
            echo "error:starter-kit-not-found:${kit_path}" >&2
            return 1
        fi

        echo "$kit_path"
        return 0
    fi

    # 4. 上記以外
    echo "error:starter-kit-not-found:unknown script location: $SCRIPT_DIR" >&2
    return 1
}

STARTER_KIT_ROOT=$(resolve_starter_kit_root) || exit 1
echo "starter_kit_path:${STARTER_KIT_ROOT}"

# === Step 2: aidlc.toml存在確認 ===
if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "error:config-not-found:${CONFIG_PATH}" >&2
    exit 1
fi

# === Step 3: セットアップ種別判定 ===
CHECK_SETUP_TYPE="${STARTER_KIT_ROOT}/prompts/setup/bin/check-setup-type.sh"

if [[ ! -x "$CHECK_SETUP_TYPE" ]]; then
    echo "warn:check-setup-type-not-found"
    SETUP_TYPE=""
else
    SETUP_TYPE_RAW=$("$CHECK_SETUP_TYPE" 2>/dev/null || true)
    SETUP_TYPE="${SETUP_TYPE_RAW#setup_type:}"
fi

echo "setup_type:${SETUP_TYPE}"

# セットアップ種別に基づく分岐
case "$SETUP_TYPE" in
    upgrade:*)
        # 正常系: アップグレード実行を続行
        ;;
    cycle_start)
        if [[ "$FORCE" != "true" ]]; then
            # バージョン同じ、強制なし → スキップ
            _current_ver=$(grep "^starter_kit_version" "$CONFIG_PATH" 2>/dev/null | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "unknown")
            echo "skip:already-current:${_current_ver}"
            exit 0
        fi
        # --force: 強制実行
        ;;
    warning_newer:*)
        echo "warn:project-newer:${SETUP_TYPE#warning_newer:}"
        ;;
    initial|migration)
        echo "error:not-upgrade-target:${SETUP_TYPE}" >&2
        exit 1
        ;;
    "")
        # dasel未インストールまたはcheck-setup-type.sh不在
        echo "warn:dasel-not-found"
        # version.txt直接比較で続行
        ;;
    *)
        echo "warn:unknown-setup-type:${SETUP_TYPE}"
        ;;
esac

# === Step 4: バージョン情報取得 ===
VERSION_FILE="${STARTER_KIT_ROOT}/version.txt"
if [[ -f "$VERSION_FILE" ]]; then
    KIT_VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
else
    KIT_VERSION="unknown"
fi

# バージョン形式バリデーション（semver: 数字とドットのみ）
if [[ "$KIT_VERSION" != "unknown" ]] && ! echo "$KIT_VERSION" | grep -qE '^[0-9]+(\.[0-9]+){0,2}$'; then
    echo "warn:invalid-kit-version:${KIT_VERSION}"
    KIT_VERSION="unknown"
fi

PROJECT_VERSION=$(grep "^starter_kit_version" "$CONFIG_PATH" 2>/dev/null | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "unknown")

echo "version_from:${PROJECT_VERSION}"
echo "version_to:${KIT_VERSION}"

# === Step 5: 設定マイグレーション ===
if [[ "$NO_MIGRATE" == "true" ]]; then
    echo "migrate:skipped"
else
    MIGRATE_CONFIG="${STARTER_KIT_ROOT}/prompts/package/bin/migrate-config.sh"

    if [[ ! -x "$MIGRATE_CONFIG" ]]; then
        echo "warn:migrate-config-not-found"
    else
        MIGRATE_ARGS=("--config" "$CONFIG_PATH")
        if [[ "$DRY_RUN" == "true" ]]; then
            MIGRATE_ARGS+=("--dry-run")
        fi

        set +e
        "$MIGRATE_CONFIG" "${MIGRATE_ARGS[@]}"
        MIGRATE_EXIT=$?
        set -e

        case $MIGRATE_EXIT in
            0)
                # 正常完了
                ;;
            2)
                echo "warn:migrate-warnings"
                ;;
            *)
                echo "error:migrate-failed" >&2
                exit 1
                ;;
        esac
    fi
fi

# === Step 6: パッケージ同期 ===
if [[ "$NO_SYNC" == "true" ]]; then
    echo "sync:skipped"
else
    SYNC_PACKAGE="${STARTER_KIT_ROOT}/prompts/package/bin/sync-package.sh"

    if [[ ! -x "$SYNC_PACKAGE" ]]; then
        echo "error:sync-package-not-found" >&2
        exit 1
    fi

    # 6ディレクトリの同期
    declare -a SYNC_DIRS=(
        "prompts"
        "templates"
        "guides"
        "bin"
        "skills"
        "kiro"
    )

    for subdir in "${SYNC_DIRS[@]}"; do
        local_source="${STARTER_KIT_ROOT}/prompts/package/${subdir}/"
        local_dest="docs/aidlc/${subdir}/"

        # 宛先ディレクトリが存在しない場合は作成
        if [[ ! -d "$local_dest" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "sync_mkdir:${local_dest}(dry-run)"
            else
                mkdir -p "$local_dest"
            fi
        fi

        # ソースディレクトリが存在しない場合はスキップ
        if [[ ! -d "$local_source" ]]; then
            echo "sync_skip:${subdir}(source-not-found)"
            continue
        fi

        SYNC_ARGS=("--source" "$local_source" "--dest" "$local_dest" "--delete")
        if [[ "$DRY_RUN" == "true" ]]; then
            SYNC_ARGS+=("--dry-run")
        fi

        set +e
        "$SYNC_PACKAGE" "${SYNC_ARGS[@]}"
        SYNC_EXIT=$?
        set -e

        if [[ "$SYNC_EXIT" -ne 0 ]]; then
            echo "error:sync-failed:${subdir}" >&2
            exit 1
        fi
    done
fi

# === Step 7: AIツール設定 ===
SETUP_AI_TOOLS="docs/aidlc/bin/setup-ai-tools.sh"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "setup_ai_tools:skipped(dry-run)"
elif [[ ! -x "$SETUP_AI_TOOLS" ]]; then
    echo "warn:setup-ai-tools-not-found"
else
    set +e
    "$SETUP_AI_TOOLS" >/dev/null 2>&1
    AI_TOOLS_EXIT=$?
    set -e

    if [[ "$AI_TOOLS_EXIT" -ne 0 ]]; then
        echo "error:setup-ai-tools-failed" >&2
        exit 1
    fi
    echo "setup_ai_tools:success"
fi

# === Step 8: バージョン更新 ===
if [[ "$DRY_RUN" == "true" ]]; then
    echo "version_updated:skipped(dry-run)"
elif [[ "$KIT_VERSION" == "unknown" ]]; then
    echo "warn:version-update-skipped:kit-version-unknown"
else
    if grep -q "^starter_kit_version" "$CONFIG_PATH"; then
        # 既存の行を更新（区切り文字 | で sed インジェクション防止）
        TMP=$(mktemp)
        _cleanup_files+=("$TMP")
        sed "s|^starter_kit_version = .*|starter_kit_version = \"${KIT_VERSION}\"|" "$CONFIG_PATH" > "$TMP"
        \mv "$TMP" "$CONFIG_PATH"
    else
        # 先頭に追加
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
