#!/usr/bin/env bash
#
# bin/lib/gh-project-repo.sh - gh project CLI / GraphQL の薄いラッパ
#
# 設計参照: .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md §gh-project-repo.sh
#
# 公開関数:
#   gh_project_repo_create_project <owner> <title> <visibility> -> stdout に number / stderr にエラー
#   gh_project_repo_create_field <owner> <number> <name> <data_type>
#   gh_project_repo_add_field_option <owner> <number> <field_id> <option_name>
#   gh_project_repo_create_view <owner> <number> <name> <layout> <strategy> -> stdout に view_id or "manual"
#   gh_project_repo_add_item <owner> <number> <issue_url> -> stdout に project_item_id
#   gh_project_repo_set_item_field_value <owner> <number> <item_id> <field_id> <value>

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

_gh_repo_emit_error() {
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

gh_project_repo_create_project() {
    local owner="${1:-}"
    local title="${2:-}"
    local visibility="${3:-public}"
    if [[ -z "$owner" ]] || [[ -z "$title" ]]; then
        _gh_repo_emit_error "args_invalid" "owner_or_title_missing"
        return 1
    fi
    local create_output
    if ! create_output="$(gh project create --owner "$owner" --title "$title" --format json 2>&1)"; then
        # R1 #4: gh エラー本文をそのまま埋め込まず、要約のみに留める
        _gh_repo_emit_error "gh_api_error" "create_project_failed"
        return 3
    fi
    local number
    number="$(printf '%s' "$create_output" | jq -r '.number // empty')"
    if [[ -z "$number" ]]; then
        _gh_repo_emit_error "gh_api_error" "create_project_no_number"
        return 3
    fi
    # visibility 設定（public のみ明示、private はデフォルト）
    if [[ "$visibility" == "public" ]]; then
        gh project edit --owner "$owner" "$number" --visibility public >/dev/null 2>&1 || true
    fi
    printf '%s' "$number"
}

gh_project_repo_create_field() {
    local owner="${1:-}"
    local number="${2:-}"
    local name="${3:-}"
    local data_type="${4:-SINGLE_SELECT}"
    if [[ -z "$owner" ]] || [[ -z "$number" ]] || [[ -z "$name" ]]; then
        _gh_repo_emit_error "args_invalid" "missing_args"
        return 1
    fi
    # SINGLE_SELECT の場合は --single-select-option が必要だが、本ラッパは「フィールドのみ」を作る
    # オプションは別関数 add_field_option で追加（gh CLI の制約上 single_select は作成時にオプション必須なため、
    # 呼出側はオプション最小1件を渡して create する想定）
    local opts="${5:-Backlog}"
    gh project field-create "$number" --owner "$owner" --name "$name" \
        --data-type "$data_type" --single-select-options "$opts" 2>&1
}

gh_project_repo_add_field_option() {
    local owner="${1:-}"
    local number="${2:-}"
    local field_id="${3:-}"
    local option_name="${4:-}"
    if [[ -z "$field_id" ]] || [[ -z "$option_name" ]]; then
        _gh_repo_emit_error "args_invalid" "missing_args"
        return 1
    fi
    # gh project field-create は冪等でないため、既存 single_select に option 追加は GraphQL 必要
    # 本ラッパは GraphQL mutation を呼び出し
    # R2 #3: || true で握りつぶさず、失敗時は gh_api_error で return 3
    local rc=0
    gh api graphql -f query='
        mutation($fieldId: ID!, $option: String!) {
          updateProjectV2Field(input:{
            fieldId: $fieldId
            singleSelectOptions: [{name: $option, color: GRAY, description: ""}]
          }) {
            projectV2Field { ... on ProjectV2SingleSelectField { id name } }
          }
        }
    ' -f fieldId="$field_id" -f option="$option_name" >/dev/null 2>&1 || rc=$?
    if [[ $rc -ne 0 ]]; then
        _gh_repo_emit_error "gh_api_error" "add_field_option_failed:field=${field_id}:option=${option_name}"
        return 3
    fi
    return 0
}

gh_project_repo_create_view() {
    local owner="${1:-}"
    local number="${2:-}"
    local name="${3:-}"
    local layout="${4:-table_layout}"
    local strategy="${5:-cli}"
    if [[ -z "$owner" ]] || [[ -z "$number" ]] || [[ -z "$name" ]]; then
        _gh_repo_emit_error "args_invalid" "missing_args"
        return 1
    fi
    case "$strategy" in
        cli)
            # gh project view-create は v2 CLI で利用可能（layout は board / table / roadmap）
            local short_layout
            case "$layout" in
                board_layout) short_layout="board" ;;
                table_layout) short_layout="table" ;;
                roadmap_layout) short_layout="roadmap" ;;
                *) short_layout="table" ;;
            esac
            gh project view-create "$number" --owner "$owner" --name "$name" --layout "$short_layout" 2>&1
            ;;
        graphql)
            # GraphQL 経路（PVT_xxx Node ID 取得が必要、複雑なので manual 案内に降格）
            printf 'view:%s:graphql-not-implemented:falling-back-to-manual' "$name"
            return 0
            ;;
        manual)
            printf 'view:%s:manual-required' "$name"
            return 0
            ;;
        *)
            _gh_repo_emit_error "args_invalid" "unknown_strategy:${strategy}"
            return 1
            ;;
    esac
}

gh_project_repo_add_item() {
    local owner="${1:-}"
    local number="${2:-}"
    local issue_url="${3:-}"
    if [[ -z "$owner" ]] || [[ -z "$number" ]] || [[ -z "$issue_url" ]]; then
        _gh_repo_emit_error "args_invalid" "missing_args"
        return 1
    fi
    local output
    if ! output="$(gh project item-add "$number" --owner "$owner" --url "$issue_url" --format json 2>&1)"; then
        # R1 #4: gh エラー本文をそのまま埋め込まず、要約のみに留める
        _gh_repo_emit_error "gh_api_error" "item_add_failed"
        return 3
    fi
    printf '%s' "$output" | jq -r '.id // empty'
}

gh_project_repo_set_item_field_value() {
    local owner="${1:-}"
    local number="${2:-}"
    local item_id="${3:-}"
    local field_id="${4:-}"
    local value="${5:-}"
    if [[ -z "$item_id" ]] || [[ -z "$field_id" ]]; then
        _gh_repo_emit_error "args_invalid" "missing_args"
        return 1
    fi
    gh project item-edit --id "$item_id" --field-id "$field_id" --single-select-option-id "$value" 2>&1
}

gh_project_repo_create_sandbox_issue() {
    local title="${1:-AI-DLC sandbox audit}"
    local body="${2:-Auto-generated sandbox issue for workflow probe. Safe to delete.}"
    gh issue create --title "$title" --body "$body" --label "audit-sandbox" 2>&1 \
        | grep -oE 'https://github.com/[^/]+/[^/]+/issues/[0-9]+' || return 3
}

gh_project_repo_close_issue() {
    local issue_url="${1:-}"
    [[ -z "$issue_url" ]] && return 1
    gh issue close "$issue_url" 2>&1
}

gh_project_repo_delete_issue() {
    local issue_url="${1:-}"
    [[ -z "$issue_url" ]] && return 1
    gh issue delete "$issue_url" --yes 2>&1
}

# CLI invocation - mostly for testing
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    case "${1:-}" in
        create-project) shift; gh_project_repo_create_project "$@" ;;
        create-field)   shift; gh_project_repo_create_field "$@" ;;
        create-view)    shift; gh_project_repo_create_view "$@" ;;
        add-item)       shift; gh_project_repo_add_item "$@" ;;
        set-item-field) shift; gh_project_repo_set_item_field_value "$@" ;;
        *)
            echo "usage: $0 {create-project|create-field|create-view|add-item|set-item-field} <args>" >&2
            exit 1
            ;;
    esac
fi
