#!/usr/bin/env bash
#
# bin/lib/gh-project-spec.sh - github-project-spec.yaml ロード + validate + cycle_map 評価
#
# 設計参照: .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md §gh-project-spec.sh
#
# 公開関数:
#   gh_project_spec_load <path>                              -> stdout に JSON
#   gh_project_spec_validate <spec_json>                     -> 0 or exit 4
#   gh_project_spec_resolve_cycle <spec_json> <milestone>    -> stdout に cycle_label
#
# 終了コード（共通契約）:
#   0  : ok
#   1  : args_invalid
#   4  : spec_invalid

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

_gh_spec_emit_error() {
    # R1 #4: jq でエスケープして JSON 注入リスクを排除
    local error_type="$1"
    local details="$2"
    local remediation="${3:-}"
    if command -v jq >/dev/null 2>&1; then
        jq -n --arg t "$error_type" --arg d "$details" --arg r "$remediation" \
            '{error_type:$t, details:$d, remediation:$r}' >&2
    else
        printf '{"error_type":"%s","details":"jq_unavailable","remediation":""}\n' "$error_type" >&2
    fi
}

# yaml -> json 変換（yq v4 を使用）
gh_project_spec_load() {
    local path="${1:-}"
    if [[ -z "$path" ]]; then
        _gh_spec_emit_error "args_invalid" "path_missing"
        return 1
    fi
    if [[ ! -f "$path" ]]; then
        _gh_spec_emit_error "spec_invalid" "file_not_found:${path}"
        return 4
    fi
    if ! command -v yq >/dev/null 2>&1; then
        _gh_spec_emit_error "spec_invalid" "yq_not_installed" "Install yq v4: brew install yq"
        return 4
    fi
    yq -o=json eval '.' "$path"
}

# spec の構造バリデーション
# 必須キー: version / project.title / project.owner / project.visibility /
#           fields[*].name / cycle_map.fallback
# views の整合: project_field_axes ⊆ fields[*].name / label_axes[*].label_prefix 非空
gh_project_spec_validate() {
    local spec_json="${1:-}"
    if [[ -z "$spec_json" ]]; then
        _gh_spec_emit_error "args_invalid" "spec_json_missing"
        return 1
    fi

    local field_names
    field_names="$(printf '%s' "$spec_json" | jq -r '.fields[].name' 2>/dev/null || true)"
    if [[ -z "$field_names" ]]; then
        _gh_spec_emit_error "spec_invalid" "fields_missing_or_empty"
        return 4
    fi

    local title
    title="$(printf '%s' "$spec_json" | jq -r '.project.title // empty')"
    if [[ -z "$title" ]]; then
        _gh_spec_emit_error "spec_invalid" "project_title_missing"
        return 4
    fi

    local visibility
    visibility="$(printf '%s' "$spec_json" | jq -r '.project.visibility // empty')"
    case "$visibility" in
        public|private) ;;
        *)
            _gh_spec_emit_error "spec_invalid" "project_visibility_invalid:${visibility}"
            return 4
            ;;
    esac

    local fallback
    fallback="$(printf '%s' "$spec_json" | jq -r '.cycle_map.fallback // empty')"
    if [[ -z "$fallback" ]]; then
        _gh_spec_emit_error "spec_invalid" "cycle_map_fallback_missing"
        return 4
    fi

    # views 整合
    local view_count
    view_count="$(printf '%s' "$spec_json" | jq '.views | length')"
    local i=0
    while [[ $i -lt $view_count ]]; do
        local view_name
        view_name="$(printf '%s' "$spec_json" | jq -r ".views[$i].name // empty")"
        if [[ -z "$view_name" ]]; then
            _gh_spec_emit_error "spec_invalid" "view_name_missing:index=${i}"
            return 4
        fi
        # project_field_axes ⊆ fields[*].name
        local axes
        axes="$(printf '%s' "$spec_json" | jq -r ".views[$i].project_field_axes[]?" 2>/dev/null || true)"
        local axis
        for axis in $axes; do
            if ! printf '%s\n' "$field_names" | grep -qx "$axis"; then
                _gh_spec_emit_error "spec_invalid" \
                    "view_axis_dangling:view=${view_name}:axis=${axis}"
                return 4
            fi
        done
        # label_axes[*].label_prefix 非空 + ":" 含む
        local label_axis_count
        label_axis_count="$(printf '%s' "$spec_json" | jq ".views[$i].label_axes | length // 0")"
        local j=0
        while [[ $j -lt $label_axis_count ]]; do
            local prefix
            prefix="$(printf '%s' "$spec_json" | jq -r ".views[$i].label_axes[$j].label_prefix // empty")"
            if [[ -z "$prefix" ]] || [[ "$prefix" != *:* ]]; then
                _gh_spec_emit_error "spec_invalid" \
                    "view_label_prefix_invalid:view=${view_name}:index=${j}:value=${prefix}"
                return 4
            fi
            j=$((j + 1))
        done
        i=$((i + 1))
    done

    return 0
}

# Milestone title -> cycle_label への正規化
gh_project_spec_resolve_cycle() {
    local spec_json="${1:-}"
    local milestone="${2:-}"
    if [[ -z "$spec_json" ]]; then
        _gh_spec_emit_error "args_invalid" "spec_json_missing"
        return 1
    fi

    local fallback
    fallback="$(printf '%s' "$spec_json" | jq -r '.cycle_map.fallback // "Later"')"

    if [[ -z "$milestone" ]]; then
        printf '%s' "$fallback"
        return 0
    fi

    # patterns を順次照合
    local pattern_count
    pattern_count="$(printf '%s' "$spec_json" | jq '.cycle_map.patterns | length // 0')"
    local i=0
    while [[ $i -lt $pattern_count ]]; do
        local pattern
        pattern="$(printf '%s' "$spec_json" | jq -r ".cycle_map.patterns[$i].milestone_pattern // empty")"
        local label
        label="$(printf '%s' "$spec_json" | jq -r ".cycle_map.patterns[$i].cycle_label // empty")"
        if [[ -n "$pattern" ]] && printf '%s' "$milestone" | grep -qE "$pattern"; then
            # placeholder <milestone-title> 展開
            if [[ "$label" == "<milestone-title>" ]]; then
                printf '%s' "$milestone"
            else
                printf '%s' "$label"
            fi
            return 0
        fi
        i=$((i + 1))
    done

    printf '%s' "$fallback"
}

# CLI invocation
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    case "${1:-}" in
        load)
            shift
            gh_project_spec_load "$@" || exit $?
            ;;
        validate)
            shift
            gh_project_spec_validate "$@" || exit $?
            ;;
        resolve-cycle)
            shift
            gh_project_spec_resolve_cycle "$@" || exit $?
            ;;
        *)
            echo "usage: $0 {load <path> | validate <spec_json> | resolve-cycle <spec_json> <milestone>}" >&2
            exit 1
            ;;
    esac
fi
