#!/usr/bin/env bash
#
# aidlc-setup.sh - AI-DLCアップグレードオーケストレーションスクリプト（v2）
#
# バージョン更新・設定マイグレーション・rsync同期を一括実行する。
# プロジェクトルートをカレントディレクトリとして実行すること。
#
# 使用方法:
#   ./aidlc-setup.sh [OPTIONS]
#
# オプション:
#   --dry-run       実際の変更を行わず差分を表示
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
NO_SYNC=false
NO_MIGRATE=false
FORCE=false

# === 設定ファイルパス（v2優先、v1フォールバック） ===
CONFIG_PATH=".aidlc/config.toml"
if [[ ! -f "$CONFIG_PATH" ]] && [[ -f "docs/aidlc.toml" ]]; then
    CONFIG_PATH="docs/aidlc.toml"
fi

# === 同期対象ディレクトリ（source と dest は同じ相対パス） ===
declare -a SYNC_DIRS=(
    "skills/aidlc/steps"
    "skills/aidlc/templates"
    "skills/aidlc/scripts"
    "skills/aidlc/config"
    "skills/aidlc-setup"
    "docs/aidlc/guides"
    "docs/aidlc/kiro"
    "docs/aidlc/lib"
)

# === 同期対象ファイル（個別ファイル） ===
declare -a SYNC_FILES=(
    "skills/aidlc/SKILL.md"
    "skills/aidlc/AGENTS.md"
    "skills/aidlc/CLAUDE.md"
)

# === ヘルプ ===
show_help() {
    cat <<'HELP'
Usage: aidlc-setup.sh [OPTIONS]

AI-DLCアップグレードオーケストレーションスクリプト（v2）。
バージョン更新・設定マイグレーション・rsync同期を一括実行します。

Options:
  --dry-run       実際の変更を行わず差分を表示
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

# === rsync dry-runによるファイル差分チェック ===
# STARTER_KIT_ROOT が設定済みの前提で呼び出すこと
# 出力: has_diff=差分あり, no_diff=差分なし, has_error=エラー（常にexit 0）
_has_file_diff() {
    local starter_root="$1"
    local sync_path source_dir dest_dir diff_output rsync_exit

    # ディレクトリの差分チェック
    for sync_path in "${SYNC_DIRS[@]}"; do
        source_dir="${starter_root}/${sync_path}/"
        dest_dir="${sync_path}/"

        # ソースが存在しない場合はスキップ
        [[ ! -d "$source_dir" ]] && continue

        # デストが存在しない場合は差分あり
        if [[ ! -d "$dest_dir" ]]; then
            echo "has_diff" && return 0
        fi

        # rsync dry-run + itemize-changesで差分を検出
        diff_output=$(rsync -ani --delete "$source_dir" "$dest_dir" 2>/dev/null) && rsync_exit=0 || rsync_exit=$?
        # ディレクトリのみの変更（.d で始まる行）を除外して実質的な差分を判定
        diff_output=$(echo "$diff_output" | grep -v '^\.d' || true)

        if [[ "$rsync_exit" -ne 0 ]]; then
            echo "error:rsync-dry-run-failed:${sync_path}" >&2
            echo "detail:rsync-exit-code:${rsync_exit}" >&2
            echo "has_error" && return 0
        fi

        if [[ -n "$diff_output" ]]; then
            echo "has_diff" && return 0
        fi
    done

    # 個別ファイルの差分チェック
    for sync_file in "${SYNC_FILES[@]}"; do
        local source_file="${starter_root}/${sync_file}"
        [[ ! -f "$source_file" ]] && continue

        if [[ ! -f "$sync_file" ]]; then
            echo "has_diff" && return 0
        fi

        if ! diff -q "$source_file" "$sync_file" >/dev/null 2>&1; then
            echo "has_diff" && return 0
        fi
    done

    echo "no_diff" && return 0
}

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

    # 2. v2スキル構造: */skills/aidlc-setup/bin
    if [[ "$SCRIPT_DIR" == */skills/aidlc-setup/bin ]]; then
        local candidate_root
        # 3階層上: bin/ → aidlc-setup/ → skills/ → root
        candidate_root="$(cd "$SCRIPT_DIR/../../.." && pwd)"

        # メタ開発環境検出: version.txt と prompts/package/ が存在
        if [[ -f "${candidate_root}/version.txt" ]] \
            && [[ -d "${candidate_root}/prompts/package" ]]; then
            echo "$candidate_root"
            return 0
        fi

        # 外部プロジェクト: ghqフォールバックでスターターキットパスを解決
        local read_config="${candidate_root}/skills/aidlc/scripts/read-config.sh"
        if [[ ! -x "$read_config" ]]; then
            echo "error:starter-kit-not-found:read-config.sh not available" >&2
            echo "detail:searched-path:$(_sanitize "${read_config}")" >&2
            echo "detail:project-root:$(_sanitize "${candidate_root}")" >&2
            echo "detail:action:export AIDLC_STARTER_KIT_PATH=/path/to/ai-dlc-starter-kit" >&2
            return 1
        fi

        local raw_repo
        raw_repo=$("$read_config" project.starter_kit_repo 2>/dev/null || true)

        if [[ -z "$raw_repo" ]]; then
            raw_repo="ghq:github.com/ikeisuke/ai-dlc-starter-kit"
            echo "warn:read-config-fallback:using default starter_kit_repo" >&2
        fi

        # ghq:プレフィックスを除去
        local repo="${raw_repo#ghq:}"

        # パストラバーサル防止
        if [[ "$repo" == *..* ]] || [[ "$repo" == /* ]]; then
            echo "error:invalid-repo-path:${repo}" >&2
            return 1
        fi

        # ghqが利用可能か確認
        if ! command -v ghq >/dev/null 2>&1; then
            echo "error:starter-kit-not-found:ghq not available, set AIDLC_STARTER_KIT_PATH" >&2
            echo "detail:project-root:$(_sanitize "${candidate_root}")" >&2
            echo "detail:action:export AIDLC_STARTER_KIT_PATH=/path/to/ai-dlc-starter-kit" >&2
            return 1
        fi

        local ghq_root
        ghq_root=$(ghq root 2>/dev/null || true)
        if [[ -z "$ghq_root" ]]; then
            echo "error:starter-kit-not-found:ghq root failed" >&2
            echo "detail:action:export AIDLC_STARTER_KIT_PATH=/path/to/ai-dlc-starter-kit" >&2
            return 1
        fi

        local kit_path="${ghq_root}/${repo}"
        if [[ ! -d "$kit_path" ]]; then
            echo "error:starter-kit-not-found:${kit_path}" >&2
            echo "detail:searched-path:$(_sanitize "${kit_path}")" >&2
            echo "detail:action:clone the starter kit or export AIDLC_STARTER_KIT_PATH" >&2
            return 1
        fi

        echo "$kit_path"
        return 0
    fi

    # 3. v1互換: */prompts/package/skills/*/bin or */docs/aidlc/skills/*/bin
    if [[ "$SCRIPT_DIR" == */prompts/package/skills/*/bin ]]; then
        cd "$SCRIPT_DIR/../../../../.." && pwd
        return 0
    fi

    if [[ "$SCRIPT_DIR" == */docs/aidlc/skills/*/bin ]]; then
        local project_root
        project_root="$(cd "$SCRIPT_DIR/../../../../.." && pwd)"

        # メタ開発環境検出
        if [[ -d "${project_root}/prompts/package" ]] \
            && [[ -f "${project_root}/version.txt" ]]; then
            echo "$project_root"
            return 0
        fi

        # 外部プロジェクト: v1パスでread-configを探す
        local read_config="${project_root}/skills/aidlc/scripts/read-config.sh"
        if [[ ! -x "$read_config" ]]; then
            read_config="${project_root}/docs/aidlc/bin/read-config.sh"
        fi

        if [[ ! -x "$read_config" ]]; then
            echo "error:starter-kit-not-found:read-config.sh not available" >&2
            echo "detail:action:export AIDLC_STARTER_KIT_PATH=/path/to/ai-dlc-starter-kit" >&2
            return 1
        fi

        local raw_repo
        raw_repo=$("$read_config" project.starter_kit_repo 2>/dev/null || true)
        [[ -z "$raw_repo" ]] && raw_repo="ghq:github.com/ikeisuke/ai-dlc-starter-kit"

        local repo="${raw_repo#ghq:}"
        if [[ "$repo" == *..* ]] || [[ "$repo" == /* ]]; then
            echo "error:invalid-repo-path:${repo}" >&2
            return 1
        fi

        if ! command -v ghq >/dev/null 2>&1; then
            echo "error:starter-kit-not-found:ghq not available" >&2
            echo "detail:action:export AIDLC_STARTER_KIT_PATH=/path/to/ai-dlc-starter-kit" >&2
            return 1
        fi

        local ghq_root
        ghq_root=$(ghq root 2>/dev/null || true)
        [[ -z "$ghq_root" ]] && { echo "error:starter-kit-not-found:ghq root failed" >&2; return 1; }

        local kit_path="${ghq_root}/${repo}"
        [[ ! -d "$kit_path" ]] && { echo "error:starter-kit-not-found:${kit_path}" >&2; return 1; }

        echo "$kit_path"
        return 0
    fi

    # 4. 上記以外
    echo "error:starter-kit-not-found:unknown script location" >&2
    echo "detail:script-dir:$(_sanitize "${SCRIPT_DIR}")" >&2
    echo "detail:action:export AIDLC_STARTER_KIT_PATH=/path/to/ai-dlc-starter-kit" >&2
    return 1
}

STARTER_KIT_ROOT=$(resolve_starter_kit_root) || exit 1
echo "starter_kit_path:${STARTER_KIT_ROOT}"

# === Step 2: 設定ファイル存在確認 ===
if [[ ! -f "$CONFIG_PATH" ]]; then
    echo "error:config-not-found:${CONFIG_PATH}" >&2
    exit 1
fi
echo "config_path:${CONFIG_PATH}"

# === Step 3: セットアップ種別判定 ===
# プロジェクトローカルのスクリプトを優先、なければスターターキットから探す
CHECK_SETUP_TYPE="skills/aidlc/scripts/check-setup-type.sh"
if [[ ! -x "$CHECK_SETUP_TYPE" ]]; then
    CHECK_SETUP_TYPE="${STARTER_KIT_ROOT}/skills/aidlc/scripts/check-setup-type.sh"
fi

if [[ ! -x "$CHECK_SETUP_TYPE" ]]; then
    echo "warn:check-setup-type-not-found"
    echo "info:searched-path:skills/aidlc/scripts/check-setup-type.sh"
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
            if [[ "$NO_SYNC" == "true" ]]; then
                _current_ver=$(grep "^starter_kit_version" "$CONFIG_PATH" 2>/dev/null | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "unknown")
                echo "skip:already-current:${_current_ver}"
                exit 0
            fi
            # バージョン同じ、強制なし → ファイル差分をチェック
            _diff_result=$(_has_file_diff "$STARTER_KIT_ROOT")

            case "$_diff_result" in
                has_diff)
                    echo "diff:detected"
                    ;;
                no_diff)
                    _current_ver=$(grep "^starter_kit_version" "$CONFIG_PATH" 2>/dev/null | sed 's/.*= *"\([^"]*\)".*/\1/' || echo "unknown")
                    echo "skip:already-current:${_current_ver}"
                    exit 0
                    ;;
                has_error)
                    exit 1
                    ;;
            esac
        fi
        ;;
    warning_newer:*)
        echo "warn:project-newer:${SETUP_TYPE#warning_newer:}"
        ;;
    initial|migration)
        echo "error:not-upgrade-target:${SETUP_TYPE}" >&2
        exit 1
        ;;
    "")
        echo "warn:setup-type-empty"
        ;;
    *)
        echo "warn:unknown-setup-type:${SETUP_TYPE}"
        ;;
esac

# === Step 4: バージョン情報取得 ===
VERSION_FILE="${STARTER_KIT_ROOT}/version.txt"
if [[ -f "$VERSION_FILE" ]]; then
    KIT_VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
    KIT_VERSION="${KIT_VERSION#v}"
else
    KIT_VERSION="unknown"
fi

# バージョン形式バリデーション
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
    # v2: スターターキットの migrate-config.sh を探す
    MIGRATE_CONFIG="${STARTER_KIT_ROOT}/skills/aidlc/scripts/migrate-config.sh"
    if [[ ! -x "$MIGRATE_CONFIG" ]]; then
        # v1フォールバック
        MIGRATE_CONFIG="${STARTER_KIT_ROOT}/prompts/package/bin/migrate-config.sh"
    fi

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

# === Step 6: パッケージ同期 ===
if [[ "$NO_SYNC" == "true" ]]; then
    echo "sync:skipped"
else
    # ディレクトリ同期
    for sync_path in "${SYNC_DIRS[@]}"; do
        local_source="${STARTER_KIT_ROOT}/${sync_path}/"
        local_dest="${sync_path}/"

        # ソースディレクトリが存在しない場合はスキップ
        if [[ ! -d "$local_source" ]]; then
            echo "sync_skip:${sync_path}(source-not-found)"
            continue
        fi

        # 宛先ディレクトリが存在しない場合
        if [[ ! -d "$local_dest" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "sync_mkdir:${local_dest}(dry-run)"
                echo "sync_new:${sync_path}(all files)"
                continue
            else
                mkdir -p "$local_dest"
            fi
        fi

        if [[ "$DRY_RUN" == "true" ]]; then
            # dry-run: rsyncで差分を表示
            RSYNC_OUTPUT=$(rsync -ani --delete "$local_source" "$local_dest" 2>/dev/null || true)
            # ディレクトリのみの行を除外
            RSYNC_OUTPUT=$(echo "$RSYNC_OUTPUT" | grep -v '^\.d' || true)

            if [[ -n "$RSYNC_OUTPUT" ]]; then
                # rsync itemize出力を解析して追加/更新/削除を分類
                while IFS= read -r line; do
                    if [[ -z "$line" ]]; then continue; fi
                    local action="${line:0:1}"
                    local filename="${line##* }"
                    case "$action" in
                        ">"|"c")
                            if [[ "$line" == *"f+++++++++"* ]]; then
                                echo "sync_added:${sync_path}/${filename}"
                            else
                                echo "sync_updated:${sync_path}/${filename}"
                            fi
                            ;;
                        "*")
                            echo "sync_deleted:${sync_path}/${filename}"
                            ;;
                    esac
                done <<< "$RSYNC_OUTPUT"
            fi
        else
            # 実行: rsyncで同期
            set +e
            rsync -a --delete "$local_source" "$local_dest" 2>/dev/null
            RSYNC_EXIT=$?
            set -e

            if [[ "$RSYNC_EXIT" -ne 0 ]]; then
                echo "error:sync-failed:${sync_path}" >&2
                exit 1
            fi
            echo "sync_done:${sync_path}"
        fi
    done

    # 個別ファイル同期
    for sync_file in "${SYNC_FILES[@]}"; do
        local_source="${STARTER_KIT_ROOT}/${sync_file}"
        local_dest="${sync_file}"

        if [[ ! -f "$local_source" ]]; then
            echo "sync_skip:${sync_file}(source-not-found)"
            continue
        fi

        # 宛先ディレクトリを確保
        dest_dir=$(dirname "$local_dest")
        if [[ ! -d "$dest_dir" ]]; then
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "sync_mkdir:${dest_dir}(dry-run)"
            else
                mkdir -p "$dest_dir"
            fi
        fi

        if [[ "$DRY_RUN" == "true" ]]; then
            if [[ ! -f "$local_dest" ]]; then
                echo "sync_added:${sync_file}"
            elif ! diff -q "$local_source" "$local_dest" >/dev/null 2>&1; then
                echo "sync_updated:${sync_file}"
            fi
        else
            cp "$local_source" "$local_dest"
            echo "sync_done:${sync_file}"
        fi
    done
fi

# === Step 7: AIツール設定 ===
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

# v2パス優先、v1フォールバック
SETUP_AI_TOOLS="skills/aidlc/scripts/setup-ai-tools.sh"
SETUP_AI_TOOLS_FALLBACK="${STARTER_KIT_ROOT}/skills/aidlc/scripts/setup-ai-tools.sh"
SETUP_AI_TOOLS_V1="${STARTER_KIT_ROOT}/prompts/package/bin/setup-ai-tools.sh"

if [[ "$DRY_RUN" == "true" ]]; then
    echo "setup_ai_tools:skipped(dry-run)"
elif [[ -x "$SETUP_AI_TOOLS" ]]; then
    _run_setup_ai_tools "$SETUP_AI_TOOLS"
elif [[ -x "$SETUP_AI_TOOLS_FALLBACK" ]]; then
    echo "info:setup-ai-tools-fallback:${SETUP_AI_TOOLS_FALLBACK}"
    _run_setup_ai_tools "$SETUP_AI_TOOLS_FALLBACK"
elif [[ -x "$SETUP_AI_TOOLS_V1" ]]; then
    echo "info:setup-ai-tools-fallback-v1:${SETUP_AI_TOOLS_V1}"
    _run_setup_ai_tools "$SETUP_AI_TOOLS_V1"
else
    echo "warn:setup-ai-tools-not-found"
fi

# === Step 8: バージョン更新 ===
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
