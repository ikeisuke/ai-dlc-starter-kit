#!/usr/bin/env bash
#
# bin/lib/gh-project-state.sh - Project 現状取得 + プロセス内キャッシュ
#
# 設計参照: .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md §gh-project-state.sh
#
# 公開関数:
#   gh_project_state_get_project_by_title <owner> <title>     -> JSON or empty
#   gh_project_state_get_fields <owner> <project_number>      -> JSON
#   gh_project_state_get_views  <owner> <project_number>      -> JSON
#   gh_project_state_get_items  <owner> <project_number>      -> JSON
#
# キャッシュ:
#   AIDLC_GH_PROJECT_CACHE_DIR が未設定なら mktemp で作成。プロセス単位（プロセス終了時に消失）。

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

_gh_state_emit_error() {
    # R1 #4: jq でエスケープして JSON 注入リスクを排除
    local error_type="$1"
    local details="$2"
    if command -v jq >/dev/null 2>&1; then
        jq -n --arg t "$error_type" --arg d "$details" \
            '{error_type:$t, details:$d}' >&2
    else
        printf '{"error_type":"%s","details":"jq_unavailable"}\n' "$error_type" >&2
    fi
}

_gh_state_cache_init() {
    if [[ -z "${AIDLC_GH_PROJECT_CACHE_DIR:-}" ]]; then
        AIDLC_GH_PROJECT_CACHE_DIR="$(mktemp -d -t gh-project-state-cache.XXXXXX)"
        export AIDLC_GH_PROJECT_CACHE_DIR
    fi
}

# キャッシュキー（owner / number / kind から生成）
_gh_state_cache_key() {
    local kind="$1"
    local owner="$2"
    local id="${3:-}"
    local key="${kind}_${owner}_${id}"
    # 安全な文字に正規化
    printf '%s' "$key" | tr -c 'a-zA-Z0-9_-' '_'
}

# 取得 + キャッシュ
_gh_state_fetch_cached() {
    local kind="$1"
    local owner="$2"
    local id="${3:-}"
    shift 3
    _gh_state_cache_init
    local key
    key="$(_gh_state_cache_key "$kind" "$owner" "$id")"
    local cache_file="${AIDLC_GH_PROJECT_CACHE_DIR}/${key}.json"
    if [[ -f "$cache_file" ]]; then
        cat "$cache_file"
        return 0
    fi
    local output
    if ! output="$("$@" 2>&1)"; then
        _gh_state_emit_error "gh_api_error" "${kind}_fetch_failed"
        return 3
    fi
    printf '%s' "$output" > "$cache_file"
    printf '%s' "$output"
}

gh_project_state_get_project_by_title() {
    local owner="${1:-@me}"
    local title="${2:-}"
    if [[ -z "$title" ]]; then
        _gh_state_emit_error "args_invalid" "title_missing"
        return 1
    fi
    local list_json
    if ! list_json="$(_gh_state_fetch_cached "list" "$owner" "" gh project list --owner "$owner" --format json --limit 100)"; then
        return 3
    fi
    # title 一致を抽出
    printf '%s' "$list_json" | jq -c --arg t "$title" '.projects[] | select(.title == $t)' 2>/dev/null || true
}

gh_project_state_get_fields() {
    local owner="${1:-@me}"
    local number="${2:-}"
    if [[ -z "$number" ]]; then
        _gh_state_emit_error "args_invalid" "project_number_missing"
        return 1
    fi
    _gh_state_fetch_cached "fields" "$owner" "$number" \
        gh project field-list --owner "$owner" "$number" --format json
}

gh_project_state_get_views() {
    local owner="${1:-@me}"
    local number="${2:-}"
    if [[ -z "$number" ]]; then
        _gh_state_emit_error "args_invalid" "project_number_missing"
        return 1
    fi
    _gh_state_fetch_cached "views" "$owner" "$number" \
        gh project view-list --owner "$owner" "$number" --format json
}

gh_project_state_get_items() {
    local owner="${1:-@me}"
    local number="${2:-}"
    if [[ -z "$number" ]]; then
        _gh_state_emit_error "args_invalid" "project_number_missing"
        return 1
    fi
    _gh_state_fetch_cached "items" "$owner" "$number" \
        gh project item-list --owner "$owner" "$number" --format json --limit 1000
}

# CLI invocation
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    case "${1:-}" in
        get-project-by-title) shift; gh_project_state_get_project_by_title "$@" ;;
        get-fields) shift; gh_project_state_get_fields "$@" ;;
        get-views)  shift; gh_project_state_get_views "$@" ;;
        get-items)  shift; gh_project_state_get_items "$@" ;;
        *)
            echo "usage: $0 {get-project-by-title|get-fields|get-views|get-items} <args>" >&2
            exit 1
            ;;
    esac
fi
