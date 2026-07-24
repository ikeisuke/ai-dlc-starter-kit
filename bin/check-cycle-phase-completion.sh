#!/usr/bin/env bash
# check-cycle-phase-completion.sh
#
# cycle/* PR の 3 Phase（Inception / Construction / Operations）完了状態を CI で検証する CLI。
# Unit 001 / Issue #672 / v2.5.6
# Issue #747 / v3.0.0-beta.2: v3-flat 構造（work-items/ + リポジトリ直下 state.json）の
#   完了判定を追加。構造判別は opt-in シグナル（<cycle>/work-items/ の存在）で行う。
#
# 入力契約: bare cycle ID（例: v2.5.6 / waf/v1.0.0）。`cycle/` prefix を含む値は reject。
# 詳細は .aidlc/cycles/v2.5.6/design-artifacts/logical-designs/unit_001_*.md および
# .aidlc/cycles/v3.0.0-beta.2/designs/002-cycle-check-v3-flat.md 参照。
set -eu

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# shellcheck source=../skills/aidlc/scripts/lib/validate.sh
. "${REPO_ROOT}/skills/aidlc/scripts/lib/validate.sh"

# v3 の state.json / work item frontmatter の読取は v3 の安全境界スクリプトへ委譲する
# （生 jq / grep / sed / awk パースを本 CLI に足さない）。
readonly V3_STATE_READ="${REPO_ROOT}/skills/aidlc/scripts/state-read.sh"
readonly V3_WORK_ITEM_STATUS="${REPO_ROOT}/skills/aidlc/scripts/work-item-status.sh"

usage() {
    cat <<'USAGE'
Usage: check-cycle-phase-completion.sh <cycle> [--pr-number N] [--help]

Verify that the given cycle is complete before merging its PR.

Structure detection (opt-in signal):
  <cycle_dir>/work-items/ exists  -> v3-flat evaluation (state.json +
                                     work item frontmatter + release.md)
  otherwise                       -> v2 evaluation (Inception / Construction /
                                     Operations progress artifacts)
  both work-items/ and inception/ -> ambiguous structure, exit 2

Arguments:
  <cycle>           bare cycle ID (e.g. v2.5.6, waf/v1.0.0)
                    NOTE: must NOT include the leading 'cycle/' prefix
  --pr-number N     expected PR number (positive integer); when given, the
                    Operations phase (v2) / release record (v3) additionally
                    verifies pr_number value match
  --help            print this message and exit 0

Environment:
  AIDLC_CYCLES_BASE cycles base directory override (tests)
  AIDLC_STATE_FILE  v3 state.json path override (tests);
                    default: <repo>/.aidlc/state.json

Exit codes:
  0  all 3 phases complete
  1  any phase incomplete (machine-readable status on stdout)
  2  input invalid (cycle name, pr-number, or cycle directory not found)

Examples:
  # CI usage (with PR number)
  check-cycle-phase-completion.sh "${GITHUB_HEAD_REF#cycle/}" --pr-number "${PR_NUMBER}"

  # local dry-run (no pr_number value match check)
  check-cycle-phase-completion.sh v2.5.6
USAGE
}

# Validate the cycle CLI argument.
# Rejects the 'cycle/' prefix, then delegates to shared validate_cycle().
# stdout: error message on failure
# return: 0 valid, 2 invalid
validate_cycle_input() {
    local value="$1"

    if [[ "${value}" == cycle/* ]]; then
        echo "error:cycle-prefix-not-allowed:${value}:hint=strip-cycle-prefix-before-passing"
        return 2
    fi

    if ! validate_cycle "${value}" >/dev/null 2>&1; then
        echo "error:invalid-cycle:${value}"
        return 2
    fi

    return 0
}

# Evaluate Inception phase completion.
# $1: inception/progress.md path
# stdout: PhaseCompletionStatus message
# return: 0 complete, 1 incomplete
evaluate_inception() {
    local progress_md="$1"

    if [[ ! -f "${progress_md}" ]]; then
        echo "inception:incomplete:reason=progress_md_missing"
        return 1
    fi

    # Single awk: enter `## ステップ一覧` section, exit on next `## ` heading.
    # Within the section, only data rows matching `^|<spaces><digits>.` are processed.
    # Status column = $3 of `|`-delimited row, trimmed.
    # Structural validity: emit sentinel via END if section absent or no data rows
    # (prevents malformed progress.md from being silently treated as complete).
    local first_pending
    first_pending="$(awk '
        BEGIN { in_section = 0; section_entered = 0; data_row_seen = 0; emitted = 0 }
        /^## ステップ一覧/ { in_section = 1; section_entered = 1; next }
        in_section && /^## / { in_section = 0 }
        in_section && /^\|[[:space:]]*[0-9]+\./ {
            data_row_seen = 1
            n = split($0, fields, "|")
            if (n < 4) next
            status = fields[3]
            sub(/^[[:space:]]+/, "", status)
            sub(/[[:space:]]+$/, "", status)
            # Accept the canonical "完了" / "スキップ" or those followed by
            # an annotation block delimited by "（" / "(" / whitespace
            # (e.g. "完了（AIレビュー2R 0件→auto_approved）"). Rejects
            # near-match values like "完了予定" or "スキップ検討中" so the
            # release gate is not weakened.
            if (status !~ /^完了([[:space:]（(]|$)/ && status !~ /^スキップ([[:space:]（(]|$)/) {
                step = fields[2]
                sub(/^[[:space:]]+/, "", step)
                sub(/[[:space:]]+$/, "", step)
                # extract the leading number "<n>." from the step label
                if (match(step, /^[0-9]+/)) {
                    step_num = substr(step, RSTART, RLENGTH)
                } else {
                    step_num = step
                }
                printf "%s|%s\n", step_num, status
                emitted = 1
                exit
            }
        }
        END {
            if (emitted) exit
            if (!section_entered) print "__MISSING_SECTION__"
            else if (!data_row_seen) print "__NO_DATA_ROWS__"
        }
    ' "${progress_md}")"

    case "${first_pending}" in
        __MISSING_SECTION__)
            echo "inception:incomplete:reason=structurally_invalid:detail=missing_section"
            return 1
            ;;
        __NO_DATA_ROWS__)
            echo "inception:incomplete:reason=structurally_invalid:detail=no_data_rows"
            return 1
            ;;
        "")
            echo "inception:complete"
            return 0
            ;;
        *)
            local step="${first_pending%%|*}"
            local status="${first_pending#*|}"
            echo "inception:incomplete:reason=step_incomplete:step=${step}:status=${status}"
            return 1
            ;;
    esac
}

# Evaluate Construction phase completion.
# $1: cycle directory path
# stdout: PhaseCompletionStatus message
# return: 0 complete, 1 incomplete
evaluate_construction() {
    local cycle_dir="$1"
    local units_dir="${cycle_dir}/story-artifacts/units"

    # 0-unit detection (bash 3.2 compatible, no nullglob).
    if [[ ! -d "${units_dir}" ]] || [[ -z "$(find "${units_dir}" -maxdepth 1 -type f -name '*.md' -print -quit 2>/dev/null)" ]]; then
        echo "construction:incomplete:reason=no_units_defined"
        return 1
    fi

    local unit_file unit_basename status first_pending=""
    while IFS= read -r unit_file; do
        unit_basename="$(basename "${unit_file}" .md)"
        status="$(awk '
            BEGIN { in_section = 0 }
            /^## 実装状態/ { in_section = 1; next }
            in_section && /^## / { exit }
            in_section && /^- \*\*状態\*\*:/ {
                line = $0
                sub(/^- \*\*状態\*\*:[[:space:]]*/, "", line)
                sub(/[[:space:]]+$/, "", line)
                print line
                exit
            }
        ' "${unit_file}")"

        # Accept the canonical "完了" / "取り下げ" or those followed by an
        # annotation block delimited by "（" / "(" / whitespace
        # (e.g. "完了（AIレビュー2R 0件→auto_approved）"). Rejects
        # near-match values like "完了予定" or "取り下げ検討中" so the
        # release gate is not weakened.
        case "${status}" in
            "完了"|"取り下げ") status_ok=1 ;;
            "完了（"*|"完了("*|"完了 "*) status_ok=1 ;;
            "取り下げ（"*|"取り下げ("*|"取り下げ "*) status_ok=1 ;;
            *) status_ok=0 ;;
        esac
        if [[ "${status_ok}" != "1" ]]; then
            first_pending="${unit_basename}|${status}"
            break
        fi
    done < <(find "${units_dir}" -maxdepth 1 -type f -name '*.md' | sort)

    if [[ -n "${first_pending}" ]]; then
        local unit="${first_pending%%|*}"
        local status_value="${first_pending#*|}"
        echo "construction:incomplete:reason=unit_status_pending:unit=${unit}:status=${status_value}"
        return 1
    fi

    echo "construction:complete"
    return 0
}

# Parse fixed slot values from operations/progress.md per grammar v1.
# $1: progress.md path
# stdout: up to 3 lines of `key=value` (release_gate_ready / completion_gate_ready / pr_number)
# Marker `<!-- fixed-slot-grammar: v1 -->` is required; otherwise no output.
parse_fixed_slots() {
    local progress_md="$1"

    awk '
        BEGIN {
            in_grammar = 0
            seen_release = 0
            seen_completion = 0
            seen_pr = 0
        }
        /<!-- fixed-slot-grammar: v1 -->/ { in_grammar = 1; next }
        in_grammar == 0 { next }
        # skip HTML comment lines
        /^[[:space:]]*<!--/ { next }
        # skip headings
        /^##/ { next }
        # skip blank lines
        /^[[:space:]]*$/ { next }
        {
            line = $0
            # strip "#" comments
            sub(/#.*$/, "", line)
            # split by comma for inline multi key=value
            n = split(line, pairs, ",")
            for (i = 1; i <= n; i++) {
                pair = pairs[i]
                # split key=value
                eq = index(pair, "=")
                if (eq == 0) continue
                key = substr(pair, 1, eq - 1)
                val = substr(pair, eq + 1)
                # trim
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", key)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", val)
                if (key == "release_gate_ready" && seen_release == 0) {
                    print "release_gate_ready=" val
                    seen_release = 1
                } else if (key == "completion_gate_ready" && seen_completion == 0) {
                    print "completion_gate_ready=" val
                    seen_completion = 1
                } else if (key == "pr_number" && seen_pr == 0) {
                    print "pr_number=" val
                    seen_pr = 1
                }
            }
        }
    ' "${progress_md}"
}

# Evaluate Operations phase completion.
# $1: cycle directory path
# $2: expected_pr_number (empty = not specified)
# stdout: PhaseCompletionStatus message
# return: 0 complete, 1 incomplete
evaluate_operations() {
    local cycle_dir="$1"
    local expected_pr="${2:-}"
    local progress_md="${cycle_dir}/operations/progress.md"

    if [[ ! -f "${progress_md}" ]]; then
        echo "operations:incomplete:reason=progress_md_missing"
        return 1
    fi

    # Extract step 7 row (data row limited match, header/separator excluded).
    local step7_row
    step7_row="$(awk '
        BEGIN { in_section = 0 }
        /^## ステップ一覧/ { in_section = 1; next }
        in_section && /^## / { exit }
        in_section && /^\|[[:space:]]*7\./ { print; exit }
    ' "${progress_md}")"

    if [[ -z "${step7_row}" ]]; then
        echo "operations:incomplete:reason=step7_not_complete:status=row_missing"
        return 1
    fi

    # Extract status column ($3) and trim.
    local step7_status
    step7_status="$(echo "${step7_row}" | awk -F'|' '{
        s = $3
        sub(/^[[:space:]]+/, "", s)
        sub(/[[:space:]]+$/, "", s)
        print s
    }')"

    if [[ "${step7_status}" != "完了" && "${step7_status}" != "PR準備完了" ]]; then
        echo "operations:incomplete:reason=step7_not_complete:status=${step7_status}"
        return 1
    fi

    # Parse fixed slots (grammar v1).
    local slot_release="" slot_completion="" slot_pr=""
    local line key val
    while IFS= read -r line; do
        key="${line%%=*}"
        val="${line#*=}"
        case "${key}" in
            release_gate_ready) slot_release="${val}" ;;
            completion_gate_ready) slot_completion="${val}" ;;
            pr_number) slot_pr="${val}" ;;
        esac
    done < <(parse_fixed_slots "${progress_md}")

    if [[ -z "${slot_release}" ]]; then
        echo "operations:incomplete:reason=fixed_slot_missing:slot=release_gate_ready"
        return 1
    fi
    if [[ -z "${slot_completion}" ]]; then
        echo "operations:incomplete:reason=fixed_slot_missing:slot=completion_gate_ready"
        return 1
    fi
    if [[ -z "${slot_pr}" ]]; then
        echo "operations:incomplete:reason=fixed_slot_missing:slot=pr_number"
        return 1
    fi

    if [[ "${slot_release}" != "true" ]]; then
        echo "operations:incomplete:reason=fixed_slot_unmet:slot=release_gate_ready:expected=true:actual=${slot_release}"
        return 1
    fi
    if [[ "${slot_completion}" != "true" ]]; then
        echo "operations:incomplete:reason=fixed_slot_unmet:slot=completion_gate_ready:expected=true:actual=${slot_completion}"
        return 1
    fi
    if [[ ! "${slot_pr}" =~ ^[1-9][0-9]*$ ]]; then
        echo "operations:incomplete:reason=fixed_slot_unmet:slot=pr_number:expected=positive_integer:actual=${slot_pr}"
        return 1
    fi

    if [[ -n "${expected_pr}" ]] && [[ "${slot_pr}" != "${expected_pr}" ]]; then
        echo "operations:incomplete:reason=pr_number_mismatch:expected=${expected_pr}:actual=${slot_pr}"
        return 1
    fi

    echo "operations:complete"
    return 0
}

# Evaluate v3-flat cycle completion (opt-in signal: work-items/ directory).
# CI gate semantics: "release-ready + release record" (data-model.md §5.1
# evaluation order 4, plus release.md / release.pr_number). Merged state is NOT
# required because this check runs before merge; merged verification belongs to
# the release Step 3-4 hard gate and doctor [phase].
# $1: cycle ID
# $2: cycle directory path
# $3: expected_pr_number (empty = not specified)
# stdout: PhaseCompletionStatus message
# return: 0 complete, 1 incomplete, 2 system error
evaluate_v3_flat() {
    local cycle="$1" cycle_dir="$2" expected_pr="${3:-}"
    local state_file="${AIDLC_STATE_FILE:-${REPO_ROOT}/.aidlc/state.json}"

    if [[ ! -f "${state_file}" ]]; then
        echo "v3:incomplete:reason=state_json_missing"
        return 1
    fi

    local rc value

    rc=0
    value="$("${V3_STATE_READ}" current_cycle "${state_file}" 2>/dev/null)" || rc=$?
    case "${rc}" in
        0) ;;
        2)
            echo "error:v3-state-read-failed:field=current_cycle:detail=system"
            return 2
            ;;
        *)
            echo "v3:incomplete:reason=state_unreadable:field=current_cycle"
            return 1
            ;;
    esac
    if [[ "${value}" != "${cycle}" ]]; then
        echo "v3:incomplete:reason=current_cycle_mismatch:expected=${cycle}:actual=${value}"
        return 1
    fi

    rc=0
    value="$("${V3_STATE_READ}" define_completed "${state_file}" 2>/dev/null)" || rc=$?
    case "${rc}" in
        0) ;;
        2)
            echo "error:v3-state-read-failed:field=define_completed:detail=system"
            return 2
            ;;
        *)
            echo "v3:incomplete:reason=state_unreadable:field=define_completed"
            return 1
            ;;
    esac
    if [[ "${value}" != "true" ]]; then
        echo "v3:incomplete:reason=define_not_completed:actual=${value}"
        return 1
    fi

    # All work items must be done / withdrawn (data-model.md §5.1 order 4).
    local wi_dir="${cycle_dir}/work-items"
    if [[ -z "$(find "${wi_dir}" -maxdepth 1 -type f -name '*.md' -print -quit 2>/dev/null)" ]]; then
        echo "v3:incomplete:reason=no_work_items"
        return 1
    fi

    local wi_file wi_basename status_out status
    while IFS= read -r wi_file; do
        wi_basename="$(basename "${wi_file}" .md)"
        rc=0
        status_out="$("${V3_WORK_ITEM_STATUS}" --read "${wi_file}" 2>/dev/null)" || rc=$?
        case "${rc}" in
            0) ;;
            2)
                echo "error:v3-work-item-read-failed:item=${wi_basename}:detail=system"
                return 2
                ;;
            *)
                echo "v3:incomplete:reason=work_item_malformed:item=${wi_basename}"
                return 1
                ;;
        esac
        status="${status_out#status:}"
        case "${status}" in
            done|withdrawn) ;;
            *)
                echo "v3:incomplete:reason=item_status_pending:item=${wi_basename}:status=${status}"
                return 1
                ;;
        esac
    done < <(find "${wi_dir}" -maxdepth 1 -type f -name '*.md' | sort)

    # Release record: release.md artifact + recorded PR number.
    if [[ ! -f "${cycle_dir}/release.md" ]]; then
        echo "v3:incomplete:reason=release_md_missing"
        return 1
    fi

    rc=0
    value="$("${V3_STATE_READ}" release.pr_number "${state_file}" 2>/dev/null)" || rc=$?
    case "${rc}" in
        0) ;;
        2)
            echo "error:v3-state-read-failed:field=release.pr_number:detail=system"
            return 2
            ;;
        *)
            echo "v3:incomplete:reason=state_unreadable:field=release.pr_number"
            return 1
            ;;
    esac
    if [[ ! "${value}" =~ ^[1-9][0-9]*$ ]]; then
        echo "v3:incomplete:reason=pr_number_not_recorded:actual=${value}"
        return 1
    fi
    if [[ -n "${expected_pr}" ]] && [[ "${value}" != "${expected_pr}" ]]; then
        echo "v3:incomplete:reason=pr_number_mismatch:expected=${expected_pr}:actual=${value}"
        return 1
    fi

    echo "v3:complete"
    return 0
}

main() {
    local cycle="" expected_pr=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --help)
                usage
                return 0
                ;;
            --pr-number)
                shift
                if [[ $# -eq 0 ]]; then
                    echo "error:invalid-pr-number::detail=missing-value"
                    return 2
                fi
                expected_pr="$1"
                if [[ ! "${expected_pr}" =~ ^[1-9][0-9]*$ ]]; then
                    echo "error:invalid-pr-number:${expected_pr}"
                    return 2
                fi
                shift
                ;;
            --pr-number=*)
                expected_pr="${1#--pr-number=}"
                if [[ ! "${expected_pr}" =~ ^[1-9][0-9]*$ ]]; then
                    echo "error:invalid-pr-number:${expected_pr}"
                    return 2
                fi
                shift
                ;;
            -*)
                echo "error:unknown-option:$1"
                return 2
                ;;
            *)
                if [[ -z "${cycle}" ]]; then
                    cycle="$1"
                else
                    echo "error:unexpected-argument:$1"
                    return 2
                fi
                shift
                ;;
        esac
    done

    if [[ -z "${cycle}" ]]; then
        echo "error:missing-cycle-argument::detail=required"
        return 2
    fi

    if ! validate_cycle_input "${cycle}"; then
        return 2
    fi

    # Cycles base directory; override-able for tests via AIDLC_CYCLES_BASE.
    local cycles_base="${AIDLC_CYCLES_BASE:-${REPO_ROOT}/.aidlc/cycles}"
    local cycle_dir="${cycles_base}/${cycle}"
    if [[ ! -d "${cycle_dir}" ]]; then
        echo "error:cycle-not-found:${cycle_dir}"
        return 2
    fi

    # Structure detection (opt-in signal): a v3-flat cycle carries work-items/.
    # Ambiguity (both v3 work-items/ and v2 inception/ present) is fail-closed.
    if [[ -d "${cycle_dir}/work-items" ]]; then
        if [[ -d "${cycle_dir}/inception" ]]; then
            echo "error:ambiguous-cycle-structure:${cycle_dir}:detail=both-v2-and-v3-signals-present"
            return 2
        fi
        local v3_rc=0
        evaluate_v3_flat "${cycle}" "${cycle_dir}" "${expected_pr}" || v3_rc=$?
        return "${v3_rc}"
    fi

    # Fail-fast: stop on first incomplete phase.
    if ! evaluate_inception "${cycle_dir}/inception/progress.md"; then
        return 1
    fi

    if ! evaluate_construction "${cycle_dir}"; then
        return 1
    fi

    if ! evaluate_operations "${cycle_dir}" "${expected_pr}"; then
        return 1
    fi

    return 0
}

main "$@"
