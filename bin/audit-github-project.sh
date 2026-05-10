#!/usr/bin/env bash
#
# bin/audit-github-project.sh - read-only 評価（probe-evidence + spec 整合）
#
# 設計参照: .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md §audit-github-project.sh
#
# Usage:
#   bin/audit-github-project.sh --check {workflow-item-closed|spec-conformance|all} [--strict|--soft]
#
# 注意: read-only のため --dry-run 非対応（指定時 exit 1 + args_invalid）

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SCRIPT_DIR}/lib"
_REPO_ROOT="${AIDLC_REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
_RUNTIME_TOML="${AIDLC_RUNTIME_TOML:-${_REPO_ROOT}/.aidlc/config.toml}"
_SPEC_PATH="${AIDLC_GH_PROJECT_SPEC:-${_REPO_ROOT}/config/github-project-spec.yaml}"

# shellcheck source=lib/gh-scope-check.sh
source "${_LIB_DIR}/gh-scope-check.sh"
# shellcheck source=lib/gh-project-spec.sh
source "${_LIB_DIR}/gh-project-spec.sh"
# shellcheck source=lib/gh-project-state.sh
source "${_LIB_DIR}/gh-project-state.sh"
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

CHECK="all"
MODE="soft"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --check)
            # R2 #4: オプション値欠落の検証
            if [[ $# -lt 2 ]] || [[ "${2:-}" == --* ]]; then
                _emit_error "args_invalid" "missing_value_for_option:--check"
                exit 1
            fi
            CHECK="$2"; shift 2 ;;
        --strict) MODE="strict"; shift ;;
        --soft)   MODE="soft"; shift ;;
        --dry-run)
            _emit_error "args_invalid" "audit_dry_run_not_supported" \
                "audit is read-only; --dry-run is meaningless"
            exit 1 ;;
        *) _emit_error "args_invalid" "unknown_option:$1"; exit 1 ;;
    esac
done

case "$CHECK" in
    workflow-item-closed|spec-conformance|all) ;;
    *)
        _emit_error "args_invalid" "check_unknown:${CHECK}"
        exit 1 ;;
esac

if ! gh_scope_check_require "--${MODE}" project read:org; then
    exit 2
fi

# helper: Project number 取得
get_project_number() {
    if [[ -f "$_RUNTIME_TOML" ]] && command -v dasel >/dev/null 2>&1; then
        dasel -f "$_RUNTIME_TOML" "github_projects.project_number" 2>/dev/null || echo ""
    else
        echo ""
    fi
}
get_project_owner() {
    if [[ -f "$_RUNTIME_TOML" ]] && command -v dasel >/dev/null 2>&1; then
        dasel -f "$_RUNTIME_TOML" "github_projects.owner" 2>/dev/null || echo "@me"
    else
        echo "@me"
    fi
}

audit_workflow_item_closed() {
    local probe_evidence
    if ! probe_evidence="$(gh_project_evidence_load_probe 2>/dev/null)"; then
        printf '{"workflow_item_closed":{"status":"fail","details":"probe_evidence_missing"}}'
        return 5
    fi
    local dry_run sandbox_number project_item_id project_number owner closed_at
    dry_run="$(printf '%s' "$probe_evidence" | jq -r '.dry_run')"
    if [[ "$dry_run" == "true" ]]; then
        printf '{"workflow_item_closed":{"status":"fail","details":"probe_was_dry_run"}}'
        return 7
    fi
    sandbox_number="$(printf '%s' "$probe_evidence" | jq -r '.sandbox_issue')"
    project_item_id="$(printf '%s' "$probe_evidence" | jq -r '.project_item_id')"
    project_number="$(printf '%s' "$probe_evidence" | jq -r '.project_number')"
    owner="$(printf '%s' "$probe_evidence" | jq -r '.project_owner')"
    closed_at="$(printf '%s' "$probe_evidence" | jq -r '.closed_at')"

    # 実環境の Item Status を取得
    local items_json
    items_json="$(gh_project_state_get_items "$owner" "$project_number" 2>/dev/null || echo '{"items":[]}')"
    local status
    status="$(printf '%s' "$items_json" | jq -r --arg id "$project_item_id" '.items[]? | select(.id==$id) | .status // empty' 2>/dev/null || echo "")"

    # R1 #6 / R2 #1 #2: closed_at から 30 秒以内の SLA 判定
    # R2 #1 (高 / security): python3 への code injection を排除するため、
    #   ISO 8601 (`YYYY-MM-DDTHH:MM:SSZ`) を bash 純正パースで epoch に変換する。
    #   不正フォーマットは elapsed_sec=-1（unknown）扱い。
    # R2 #2 (高 / code): python3 非依存。Status=Done && sla=unknown は warn 扱い（fail に降格しない）。
    local now_iso elapsed_sec sla_status
    now_iso="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    sla_status="unknown"
    elapsed_sec="-1"
    # ISO 8601 を bash 内でパース（外部コマンド経由しないため code injection なし）
    _parse_iso_to_epoch() {
        local ts="$1"
        # 期待形式: YYYY-MM-DDTHH:MM:SSZ
        if [[ ! "$ts" =~ ^([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2})Z$ ]]; then
            echo "-1"; return
        fi
        local y="${BASH_REMATCH[1]}" m="${BASH_REMATCH[2]}" d="${BASH_REMATCH[3]}"
        local hh="${BASH_REMATCH[4]}" mm="${BASH_REMATCH[5]}" ss="${BASH_REMATCH[6]}"
        # date コマンドで epoch 変換（macOS BSD date / GNU date 両対応）
        local ep
        ep="$(TZ=UTC date -j -f "%Y-%m-%dT%H:%M:%SZ" "${y}-${m}-${d}T${hh}:${mm}:${ss}Z" "+%s" 2>/dev/null)" \
            || ep="$(date -u -d "${y}-${m}-${d}T${hh}:${mm}:${ss}Z" "+%s" 2>/dev/null)" \
            || ep="-1"
        echo "$ep"
    }
    if [[ -n "$closed_at" ]] && [[ "$closed_at" != "null" ]]; then
        local closed_epoch now_epoch
        closed_epoch="$(_parse_iso_to_epoch "$closed_at")"
        now_epoch="$(_parse_iso_to_epoch "$now_iso")"
        if [[ "$closed_epoch" != "-1" ]] && [[ "$now_epoch" != "-1" ]]; then
            elapsed_sec=$(( now_epoch - closed_epoch ))
            if [[ "$elapsed_sec" -ge 0 ]] && [[ "$elapsed_sec" -le 30 ]]; then
                sla_status="within_sla"
            elif [[ "$elapsed_sec" -gt 30 ]]; then
                sla_status="sla_exceeded"
            fi
        fi
    fi

    if [[ "$status" == "Done" ]] && [[ "$sla_status" == "within_sla" ]]; then
        jq -n --arg s "$status" --argjson sn "$sandbox_number" --arg ca "$closed_at" --arg now "$now_iso" --argjson el "$elapsed_sec" --arg sla "$sla_status" \
            '{workflow_item_closed:{status:"pass", sandbox:$sn, observed_status:$s, closed_at:$ca, evaluated_at:$now, elapsed_sec:$el, sla:$sla}}'
        return 0
    elif [[ "$status" == "Done" ]] && [[ "$sla_status" == "sla_exceeded" ]]; then
        jq -n --arg s "$status" --argjson sn "$sandbox_number" --arg ca "$closed_at" --arg now "$now_iso" --argjson el "$elapsed_sec" --arg sla "$sla_status" \
            '{workflow_item_closed:{status:"warn", sandbox:$sn, observed_status:$s, closed_at:$ca, evaluated_at:$now, elapsed_sec:$el, sla:$sla, details:"transition_observed_but_sla_exceeded"}}'
        return 7
    elif [[ "$status" == "Done" ]] && [[ "$sla_status" == "unknown" ]]; then
        # R2 #2: SLA 計測不能だが Status=Done なら warn（fail に降格しない）
        jq -n --arg s "$status" --argjson sn "$sandbox_number" --arg ca "$closed_at" --arg now "$now_iso" --argjson el "$elapsed_sec" --arg sla "$sla_status" \
            '{workflow_item_closed:{status:"warn", sandbox:$sn, observed_status:$s, closed_at:$ca, evaluated_at:$now, elapsed_sec:$el, sla:$sla, details:"status_done_but_sla_unmeasurable"}}'
        return 0
    else
        jq -n --arg s "$status" --argjson sn "$sandbox_number" --arg ca "$closed_at" --arg now "$now_iso" --argjson el "$elapsed_sec" --arg sla "$sla_status" \
            '{workflow_item_closed:{status:"fail", sandbox:$sn, observed_status:$s, closed_at:$ca, evaluated_at:$now, elapsed_sec:$el, sla:$sla, details:"status_not_done"}}'
        return 7
    fi
}

audit_spec_conformance() {
    local spec_json
    if ! spec_json="$(gh_project_spec_load "$_SPEC_PATH")"; then
        printf '{"spec_conformance":{"status":"fail","details":"spec_load_failed"}}'
        return 4
    fi
    if ! gh_project_spec_validate "$spec_json"; then
        printf '{"spec_conformance":{"status":"fail","details":"spec_validate_failed"}}'
        return 4
    fi

    local owner project_number
    owner="$(get_project_owner)"
    project_number="$(get_project_number)"
    if [[ -z "$project_number" ]]; then
        printf '{"spec_conformance":{"status":"drift","details":"runtime_binding_missing"}}'
        return 7
    fi

    # 簡易整合チェック: spec.fields[*].name が実 Project にすべて存在
    local fields_json
    fields_json="$(gh_project_state_get_fields "$owner" "$project_number" 2>/dev/null || echo '{"fields":[]}')"
    local desired_field_count actual_field_count drifts
    desired_field_count="$(printf '%s' "$spec_json" | jq '.fields | length')"
    actual_field_count="$(printf '%s' "$fields_json" | jq '.fields | length')"
    drifts="[]"

    local i=0
    while [[ $i -lt $desired_field_count ]]; do
        local desired_name
        desired_name="$(printf '%s' "$spec_json" | jq -r ".fields[$i].name")"
        local found
        found="$(printf '%s' "$fields_json" | jq -r --arg n "$desired_name" '.fields[]? | select(.name==$n) | .name // empty' | head -1)"
        if [[ -z "$found" ]]; then
            drifts="$(printf '%s' "$drifts" | jq --arg n "$desired_name" '. + [{type:"field_missing", name:$n}]')"
        fi
        i=$((i + 1))
    done

    local drift_count
    drift_count="$(printf '%s' "$drifts" | jq 'length')"
    if [[ "$drift_count" -eq 0 ]]; then
        printf '{"spec_conformance":{"status":"pass","fields_desired":%d,"fields_actual":%d}}' \
            "$desired_field_count" "$actual_field_count"
        return 0
    else
        printf '{"spec_conformance":{"status":"drift","drifts":%s}}' "$drifts"
        return 7
    fi
}

# main
results=()
overall_exit=0

if [[ "$CHECK" == "workflow-item-closed" ]] || [[ "$CHECK" == "all" ]]; then
    rc=0
    out="$(audit_workflow_item_closed)" || rc=$?
    results+=("$out")
    if [[ "$rc" -ne 0 ]]; then overall_exit="$rc"; fi
    # R3 #1: status を JSON から取り出して stdout 契約を整合
    inner_status="$(printf '%s' "$out" | jq -r '.workflow_item_closed.status // "unknown"')"
    case "$inner_status" in
        pass) printf 'audit:workflow-item-closed:pass\n' ;;
        warn) printf 'audit:workflow-item-closed:warn:exit=%d\n' "$rc" ;;
        *)    printf 'audit:workflow-item-closed:fail:exit=%d\n' "$rc" ;;
    esac
fi

if [[ "$CHECK" == "spec-conformance" ]] || [[ "$CHECK" == "all" ]]; then
    rc=0
    out="$(audit_spec_conformance)" || rc=$?
    results+=("$out")
    if [[ "$rc" -ne 0 ]] && [[ "$overall_exit" -eq 0 ]]; then overall_exit="$rc"; fi
    inner_status="$(printf '%s' "$out" | jq -r '.spec_conformance.status // "unknown"')"
    case "$inner_status" in
        pass)  printf 'audit:spec-conformance:pass\n' ;;
        drift) printf 'audit:spec-conformance:drift:exit=%d\n' "$rc" ;;
        *)     printf 'audit:spec-conformance:fail:exit=%d\n' "$rc" ;;
    esac
fi

# audit-summary.json 生成
summary_json="$(printf '%s\n' "${results[@]}" | jq -s 'add // {}' | jq --arg t "$(date -u +%Y-%m-%dT%H:%M:%SZ)" '. + {evaluated_at:$t}')"
saved="$(gh_project_evidence_save_summary "$summary_json")"
printf 'audit-summary:%s\n' "$saved"

# soft モードでは exit 0（warn のみ）
if [[ "$MODE" == "soft" ]] && [[ "$overall_exit" -ne 0 ]]; then
    printf 'audit:soft-mode:overall-warn:exit=%d\n' "$overall_exit"
    exit 0
fi
exit "$overall_exit"
