#!/usr/bin/env bash
#
# bin/lib/gh-project-evidence.sh - probe-evidence.json / audit-summary.json の I/O
#
# 設計参照: .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md §gh-project-evidence.sh
#
# 公開関数:
#   gh_project_evidence_save_probe <evidence_json> [path]    -> stdout に保存先パス
#   gh_project_evidence_load_probe [path]                    -> stdout に JSON
#   gh_project_evidence_save_summary <summary_json> [path]   -> stdout に保存先パス

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

_gh_evidence_default_dir() {
    local repo_root
    repo_root="${AIDLC_REPO_ROOT:-}"
    if [[ -z "$repo_root" ]]; then
        repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
    fi
    printf '%s/.aidlc/cache/audit' "$repo_root"
}

_gh_evidence_emit_error() {
    # R1 #4: jq でエスケープして JSON 注入リスクを排除
    local error_type="$1"; local details="$2"
    if command -v jq >/dev/null 2>&1; then
        jq -n --arg t "$error_type" --arg d "$details" \
            '{error_type:$t, details:$d}' >&2
    else
        printf '{"error_type":"%s","details":"jq_unavailable"}\n' "$error_type" >&2
    fi
}

gh_project_evidence_save_probe() {
    local evidence_json="${1:-}"
    local path="${2:-}"
    if [[ -z "$evidence_json" ]]; then
        _gh_evidence_emit_error "args_invalid" "evidence_json_missing"
        return 1
    fi
    if [[ -z "$path" ]]; then
        path="$(_gh_evidence_default_dir)/probe-evidence.json"
    fi
    mkdir -p "$(dirname "$path")"
    printf '%s\n' "$evidence_json" > "$path"
    printf '%s' "$path"
}

gh_project_evidence_load_probe() {
    local path="${1:-}"
    if [[ -z "$path" ]]; then
        path="$(_gh_evidence_default_dir)/probe-evidence.json"
    fi
    if [[ ! -f "$path" ]]; then
        _gh_evidence_emit_error "evidence_missing" "probe_evidence_not_found:${path}"
        return 5
    fi
    cat "$path"
}

gh_project_evidence_save_summary() {
    local summary_json="${1:-}"
    local path="${2:-}"
    if [[ -z "$summary_json" ]]; then
        _gh_evidence_emit_error "args_invalid" "summary_json_missing"
        return 1
    fi
    if [[ -z "$path" ]]; then
        path="$(_gh_evidence_default_dir)/audit-summary.json"
    fi
    mkdir -p "$(dirname "$path")"
    printf '%s\n' "$summary_json" > "$path"
    printf '%s' "$path"
}

# CLI invocation
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    case "${1:-}" in
        save-probe)   shift; gh_project_evidence_save_probe "$@" ;;
        load-probe)   shift; gh_project_evidence_load_probe "$@" ;;
        save-summary) shift; gh_project_evidence_save_summary "$@" ;;
        *)
            echo "usage: $0 {save-probe <json> [path] | load-probe [path] | save-summary <json> [path]}" >&2
            exit 1
            ;;
    esac
fi
