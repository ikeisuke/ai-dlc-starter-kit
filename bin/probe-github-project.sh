#!/usr/bin/env bash
#
# bin/probe-github-project.sh - write 副作用ありの sandbox 操作 + cleanup + evidence 出力
#
# 設計参照: .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md §probe-github-project.sh
#
# Usage:
#   bin/probe-github-project.sh --probe workflow-item-closed [--dry-run] [--strict|--soft]

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SCRIPT_DIR}/lib"
_REPO_ROOT="${AIDLC_REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
_RUNTIME_TOML="${AIDLC_RUNTIME_TOML:-${_REPO_ROOT}/.aidlc/config.toml}"

# shellcheck source=lib/gh-scope-check.sh
source "${_LIB_DIR}/gh-scope-check.sh"
# shellcheck source=lib/gh-project-repo.sh
source "${_LIB_DIR}/gh-project-repo.sh"
# shellcheck source=lib/gh-project-evidence.sh
source "${_LIB_DIR}/gh-project-evidence.sh"

_emit_error() {
    # R1 #4: jq でエスケープして JSON 注入リスクを排除
    local error_type="$1"; local details="$2"; local remediation="${3:-}"
    if command -v jq >/dev/null 2>&1; then
        jq -n --arg t "$error_type" --arg d "$details" --arg r "$remediation" \
            '{error_type:$t, details:$d, remediation:$r}' >&2
    else
        printf '{"error_type":"%s","details":"jq_unavailable","remediation":""}\n' "$error_type" >&2
    fi
}

PROBE=""
DRY_RUN=false
MODE="strict"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --probe)
            # R2 #4: オプション値欠落の検証
            if [[ $# -lt 2 ]] || [[ "${2:-}" == --* ]]; then
                _emit_error "args_invalid" "missing_value_for_option:--probe"
                exit 1
            fi
            PROBE="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        --strict)  MODE="strict"; shift ;;
        --soft)    MODE="soft"; shift ;;
        *) _emit_error "args_invalid" "unknown_option:$1"; exit 1 ;;
    esac
done

if [[ -z "$PROBE" ]]; then
    _emit_error "args_invalid" "probe_kind_missing" "Pass --probe workflow-item-closed"
    exit 1
fi

if [[ "$PROBE" != "workflow-item-closed" ]]; then
    _emit_error "args_invalid" "probe_kind_unsupported:${PROBE}"
    exit 1
fi

if ! gh_scope_check_require "--${MODE}" project read:org repo; then
    exit 2
fi

# Project number 取得
project_number=""
if [[ -f "$_RUNTIME_TOML" ]] && command -v dasel >/dev/null 2>&1; then
    project_number="$(dasel -f "$_RUNTIME_TOML" "github_projects.project_number" 2>/dev/null || echo "")"
fi
project_owner=""
if [[ -f "$_RUNTIME_TOML" ]] && command -v dasel >/dev/null 2>&1; then
    project_owner="$(dasel -f "$_RUNTIME_TOML" "github_projects.owner" 2>/dev/null || echo "@me")"
fi
if [[ -z "$project_number" ]]; then
    _emit_error "evidence_missing" "runtime_binding_missing:project_number" \
        "Run 'bin/gh-project-cli.sh ensure-project' first"
    exit 5
fi

timestamp_iso() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

sandbox_title="AI-DLC sandbox audit ($(timestamp_iso))"

if $DRY_RUN; then
    # R1 #5: heredoc 直書きをやめ、jq -n で evidence JSON を組み立て（注入リスク排除）
    evidence_json="$(jq -n \
        --arg t "$sandbox_title" \
        --arg owner "$project_owner" \
        --argjson num "$project_number" \
        '{
            probe: "workflow-item-closed",
            dry_run: true,
            sandbox_issue: null,
            project_item_id: null,
            closed_at: null,
            cleanup_status: null,
            would_create: {sandbox_issue_title: $t, project_owner: $owner, project_number: $num}
        }')"
    saved_path="$(gh_project_evidence_save_probe "$evidence_json")"
    printf 'probe:workflow-item-closed:would-run:%s\n' "$sandbox_title"
    printf 'evidence:%s\n' "$saved_path"
    exit 0
fi

# Apply 経路: sandbox 作成 → Project 追加 → close → cleanup
sandbox_url=""
project_item_id=""
cleanup_status="failed"
closed_at=""

# create sandbox
if ! sandbox_url="$(gh_project_repo_create_sandbox_issue "$sandbox_title")"; then
    _emit_error "probe_side_effect_failed" "sandbox_create_failed"
    exit 6
fi
sandbox_number="$(printf '%s' "$sandbox_url" | grep -oE '[0-9]+$')"

# add to project
if ! project_item_id="$(gh_project_repo_add_item "$project_owner" "$project_number" "$sandbox_url" 2>&1)"; then
    # cleanup attempt before exit
    gh_project_repo_delete_issue "$sandbox_url" >/dev/null 2>&1 || true
    _emit_error "probe_side_effect_failed" "sandbox_add_to_project_failed"
    exit 6
fi

# close sandbox
closed_at="$(timestamp_iso)"
if ! gh_project_repo_close_issue "$sandbox_url" >/dev/null 2>&1; then
    gh_project_repo_delete_issue "$sandbox_url" >/dev/null 2>&1 || true
    _emit_error "probe_side_effect_failed" "sandbox_close_failed"
    exit 6
fi

# cleanup（成功/失敗どちらでも probe 自体は完了扱い）
if gh_project_repo_delete_issue "$sandbox_url" >/dev/null 2>&1; then
    cleanup_status="succeeded"
fi

# R1 #5: heredoc 直書きをやめ、jq -n で evidence JSON を組み立て（注入リスク排除）
evidence_json="$(jq -n \
    --argjson sn "$sandbox_number" \
    --arg surl "$sandbox_url" \
    --arg pid "$project_item_id" \
    --arg owner "$project_owner" \
    --argjson num "$project_number" \
    --arg ca "$closed_at" \
    --arg cs "$cleanup_status" \
    '{
        probe: "workflow-item-closed",
        dry_run: false,
        sandbox_issue: $sn,
        sandbox_url: $surl,
        project_item_id: $pid,
        project_owner: $owner,
        project_number: $num,
        closed_at: $ca,
        cleanup_status: $cs,
        cleanup_evidence: {action: "delete", result: $cs}
    }')"
saved_path="$(gh_project_evidence_save_probe "$evidence_json")"

if [[ "$cleanup_status" == "succeeded" ]]; then
    printf 'probe:workflow-item-closed:completed:%s\n' "$sandbox_number"
else
    printf 'probe:workflow-item-closed:cleanup-failed:%s\n' "$sandbox_number"
fi
printf 'evidence:%s\n' "$saved_path"
