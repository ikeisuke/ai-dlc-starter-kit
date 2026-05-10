#!/usr/bin/env bash
#
# bin/gh-project-cli.sh - GitHub Projects (ProjectsV2) サブコマンド分割 CLI
#
# 設計参照: .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md
#
# サブコマンド:
#   ensure-project [--dry-run] [--strict|--soft]
#   ensure-fields  [--dry-run] [--strict|--soft]
#   ensure-views   [--dry-run] [--strict|--soft]
#   sync-items     [--dry-run] [--strict|--soft]
#   audit          [--check workflow-item-closed|spec-conformance|all] [--strict|--soft]
#                  ※ audit は read-only のため --dry-run 非対応（指定時 exit 1 + args_invalid）
#
# 共通契約:
#   exit 0  : 成功
#   exit 1  : 引数不正
#   exit 2  : スコープ不足（strict）
#   exit 3  : gh API 失敗
#   exit 4  : spec 不正
#   exit 5  : evidence 不足
#   exit 6  : probe 副作用失敗
#   exit 7  : audit 失敗

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SCRIPT_DIR}/lib"

# shellcheck source=lib/gh-scope-check.sh
source "${_LIB_DIR}/gh-scope-check.sh"
# shellcheck source=lib/gh-project-spec.sh
source "${_LIB_DIR}/gh-project-spec.sh"
# shellcheck source=lib/gh-project-state.sh
source "${_LIB_DIR}/gh-project-state.sh"
# shellcheck source=lib/gh-project-repo.sh
source "${_LIB_DIR}/gh-project-repo.sh"

_REPO_ROOT="${AIDLC_REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
_SPEC_PATH="${AIDLC_GH_PROJECT_SPEC:-${_REPO_ROOT}/config/github-project-spec.yaml}"
_RUNTIME_TOML="${AIDLC_RUNTIME_TOML:-${_REPO_ROOT}/.aidlc/config.toml}"

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

_load_spec_or_exit() {
    # R1 #1: `if ! cmd; then exit $?` は失敗時 $? が 0 になるため使わず、`cmd || rc; exit $rc` の形式に統一
    local spec_json
    local rc=0
    spec_json="$(gh_project_spec_load "$_SPEC_PATH")" || rc=$?
    if [[ $rc -ne 0 ]]; then
        exit "$rc"
    fi
    gh_project_spec_validate "$spec_json" || exit 4
    printf '%s' "$spec_json"
}

# .aidlc/config.toml [github_projects] への runtime binding 書き込み（ensure-project 専用）
_write_runtime_binding() {
    local owner="$1"
    local number="$2"
    local url="$3"
    if [[ ! -f "$_RUNTIME_TOML" ]]; then
        printf 'WARN: %s not found, skipping runtime binding write\n' "$_RUNTIME_TOML" >&2
        return 0
    fi
    # dasel で更新（インストール済前提 / プリフライトで確認済）
    if ! command -v dasel >/dev/null 2>&1; then
        printf 'WARN: dasel not installed, skipping runtime binding write\n' >&2
        return 0
    fi
    # R3 #2: dasel put 失敗を握りつぶさず、いずれか失敗したら専用エラーで非0返却
    local rc=0
    dasel put -f "$_RUNTIME_TOML" -t string -v "$owner" "github_projects.owner" 2>/dev/null || rc=$?
    if [[ $rc -eq 0 ]]; then
        dasel put -f "$_RUNTIME_TOML" -t int -v "$number" "github_projects.project_number" 2>/dev/null || rc=$?
    fi
    if [[ $rc -eq 0 ]]; then
        dasel put -f "$_RUNTIME_TOML" -t string -v "$url" "github_projects.project_url" 2>/dev/null || rc=$?
    fi
    if [[ $rc -ne 0 ]]; then
        _emit_error "evidence_missing" "runtime_binding_write_failed:dasel_exit=${rc}" \
            "Inspect ${_RUNTIME_TOML} permissions and dasel availability"
        return 5
    fi
    return 0
}

# .aidlc/config.toml [github_projects] から runtime binding 読み取り
_read_runtime_binding() {
    local key="$1"
    if [[ ! -f "$_RUNTIME_TOML" ]]; then
        echo ""; return 0
    fi
    if ! command -v dasel >/dev/null 2>&1; then
        echo ""; return 0
    fi
    dasel -f "$_RUNTIME_TOML" "github_projects.${key}" 2>/dev/null || echo ""
}

# 共通オプションパース（--dry-run / --strict / --soft / --spec / --check）
_DRY_RUN=false
_MODE=""  # default は subcmd 別に設定（apply 系=strict / audit=soft）
_AUDIT_CHECK="all"
_MODE_EXPLICIT=false
_parse_common_opts() {
    local subcmd="$1"; shift
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                if [[ "$subcmd" == "audit" ]]; then
                    _emit_error "args_invalid" "audit_dry_run_not_supported" \
                        "audit is read-only; --dry-run is meaningless"
                    exit 1
                fi
                _DRY_RUN=true; shift ;;
            --strict) _MODE="strict"; _MODE_EXPLICIT=true; shift ;;
            --soft)   _MODE="soft";   _MODE_EXPLICIT=true; shift ;;
            --spec)
                # R2 #4: オプション値欠落の検証
                if [[ $# -lt 2 ]] || [[ "${2:-}" == --* ]]; then
                    _emit_error "args_invalid" "missing_value_for_option:--spec"
                    exit 1
                fi
                _SPEC_PATH="$2"; shift 2 ;;
            --check)
                if [[ $# -lt 2 ]] || [[ "${2:-}" == --* ]]; then
                    _emit_error "args_invalid" "missing_value_for_option:--check"
                    exit 1
                fi
                _AUDIT_CHECK="$2"; shift 2 ;;
            --)       shift; break ;;
            *)
                _emit_error "args_invalid" "unknown_option:$1"
                exit 1 ;;
        esac
    done
    # R1 #3: subcmd 別デフォルトモード（明示指定なきとき）
    if ! $_MODE_EXPLICIT; then
        if [[ "$subcmd" == "audit" ]]; then
            _MODE="soft"
        else
            _MODE="strict"
        fi
    fi
}

# 必須スコープ
_REQUIRED_SCOPES="project read:org read:project"

_check_scopes_or_exit() {
    if ! gh_scope_check_require "--${_MODE}" $_REQUIRED_SCOPES; then
        exit 2
    fi
}

# ====================================================================
# サブコマンド: ensure-project
# ====================================================================
_subcmd_ensure_project() {
    _parse_common_opts ensure-project "$@"
    _check_scopes_or_exit

    local spec_json
    spec_json="$(_load_spec_or_exit)"
    local title owner visibility
    title="$(printf '%s' "$spec_json" | jq -r '.project.title')"
    owner="$(printf '%s' "$spec_json" | jq -r '.project.owner')"
    visibility="$(printf '%s' "$spec_json" | jq -r '.project.visibility')"

    local existing
    existing="$(gh_project_state_get_project_by_title "$owner" "$title" || true)"
    if [[ -n "$existing" ]]; then
        local number url
        number="$(printf '%s' "$existing" | jq -r '.number')"
        url="$(printf '%s' "$existing" | jq -r '.url')"
        printf 'project:exists:%s\n' "$number"
        # 既存でも runtime binding は最新化
        if ! $_DRY_RUN; then
            local wb_rc=0
            _write_runtime_binding "$owner" "$number" "$url" || wb_rc=$?
            if [[ $wb_rc -ne 0 ]]; then
                exit "$wb_rc"
            fi
        fi
        return 0
    fi

    if $_DRY_RUN; then
        printf 'project:would-create:%s\n' "$title"
        return 0
    fi

    local number rc=0
    number="$(gh_project_repo_create_project "$owner" "$title" "$visibility")" || rc=$?
    if [[ $rc -ne 0 ]]; then
        exit "$rc"
    fi
    local owner_login
    owner_login="$(printf '%s' "$owner" | sed 's|@me|ikeisuke|')"
    local url="https://github.com/users/${owner_login}/projects/${number}"
    # R3 #2: runtime binding 書き込み失敗を握りつぶさない
    local wb_rc=0
    _write_runtime_binding "$owner" "$number" "$url" || wb_rc=$?
    if [[ $wb_rc -ne 0 ]]; then
        exit "$wb_rc"
    fi
    printf 'project:created:%s\n' "$number"
}

# ====================================================================
# サブコマンド: ensure-fields
# ====================================================================
_subcmd_ensure_fields() {
    _parse_common_opts ensure-fields "$@"
    _check_scopes_or_exit

    local spec_json
    spec_json="$(_load_spec_or_exit)"
    local owner number
    owner="$(printf '%s' "$spec_json" | jq -r '.project.owner')"
    number="$(_read_runtime_binding "project_number")"
    if [[ -z "$number" ]]; then
        _emit_error "evidence_missing" "runtime_binding_missing:project_number" \
            "Run 'gh-project-cli.sh ensure-project' first"
        exit 5
    fi

    local existing_fields
    existing_fields="$(gh_project_state_get_fields "$owner" "$number" 2>/dev/null || echo '{"fields":[]}')"

    local field_count
    field_count="$(printf '%s' "$spec_json" | jq '.fields | length')"
    local i=0
    while [[ $i -lt $field_count ]]; do
        local fname dtype
        fname="$(printf '%s' "$spec_json" | jq -r ".fields[$i].name")"
        dtype="$(printf '%s' "$spec_json" | jq -r ".fields[$i].data_type")"

        local exists
        exists="$(printf '%s' "$existing_fields" | jq -r --arg n "$fname" '.fields[] | select(.name==$n) | .id // empty' 2>/dev/null | head -1)"

        if [[ -n "$exists" ]]; then
            printf 'field:exists:%s\n' "$fname"
        else
            if $_DRY_RUN; then
                printf 'field:would-create:%s\n' "$fname"
            else
                local opts_csv
                if [[ "$dtype" == "single_select" ]]; then
                    # options が dynamic の場合は cycle_map で派生（Cycle field のみ）
                    local opts_kind
                    opts_kind="$(printf '%s' "$spec_json" | jq -r ".fields[$i].options")"
                    if [[ "$opts_kind" == "dynamic" ]]; then
                        opts_csv="Later"  # 初期値のみ。実 milestone 投入は sync-items で
                    else
                        opts_csv="$(printf '%s' "$spec_json" | jq -r ".fields[$i].options | join(\",\")")"
                    fi
                fi
                # R1 #2: API 失敗を握りつぶさず、失敗時は gh_api_error で exit 3
                local rc=0
                gh_project_repo_create_field "$owner" "$number" "$fname" "SINGLE_SELECT" "$opts_csv" >/dev/null 2>&1 || rc=$?
                if [[ $rc -ne 0 ]]; then
                    _emit_error "gh_api_error" "create_field_failed:${fname}"
                    exit 3
                fi
                printf 'field:created:%s\n' "$fname"
            fi
        fi
        i=$((i + 1))
    done
}

# ====================================================================
# サブコマンド: ensure-views
# ====================================================================
_subcmd_ensure_views() {
    _parse_common_opts ensure-views "$@"
    _check_scopes_or_exit

    local spec_json
    spec_json="$(_load_spec_or_exit)"
    local owner number
    owner="$(printf '%s' "$spec_json" | jq -r '.project.owner')"
    number="$(_read_runtime_binding "project_number")"
    if [[ -z "$number" ]]; then
        _emit_error "evidence_missing" "runtime_binding_missing:project_number" \
            "Run 'gh-project-cli.sh ensure-project' first"
        exit 5
    fi

    local existing_views
    existing_views="$(gh_project_state_get_views "$owner" "$number" 2>/dev/null || echo '{"views":[]}')"

    local view_count
    view_count="$(printf '%s' "$spec_json" | jq '.views | length')"
    local i=0
    while [[ $i -lt $view_count ]]; do
        local vname vlayout vstrategy
        vname="$(printf '%s' "$spec_json" | jq -r ".views[$i].name")"
        vlayout="$(printf '%s' "$spec_json" | jq -r ".views[$i].layout")"
        vstrategy="$(printf '%s' "$spec_json" | jq -r ".views[$i].apply_strategy // \"cli\"")"

        local exists
        exists="$(printf '%s' "$existing_views" | jq -r --arg n "$vname" '.views[]? | select(.name==$n) | .id // empty' 2>/dev/null | head -1)"

        if [[ -n "$exists" ]]; then
            printf 'view:exists:%s\n' "$vname"
        else
            if $_DRY_RUN; then
                printf 'view:would-create:%s:%s\n' "$vname" "$vstrategy"
            else
                # R1 #2: API 失敗を握りつぶさず、manual/graphql-not-implemented は正常パス、それ以外失敗は exit 3
                local out rc=0
                out="$(gh_project_repo_create_view "$owner" "$number" "$vname" "$vlayout" "$vstrategy" 2>&1)" || rc=$?
                if [[ "$out" == *"manual-required"* ]] || [[ "$out" == *"graphql-not-implemented"* ]]; then
                    # manual / graphql-not-implemented はリポジトリ層が意図的に返す正常パス（rc=0 想定）
                    printf 'view:manual-required:%s:see-docs:docs/development/github-projects-setup.md\n' "$vname"
                elif [[ $rc -ne 0 ]]; then
                    _emit_error "gh_api_error" "create_view_failed:${vname}"
                    exit 3
                else
                    printf 'view:created:%s:%s\n' "$vname" "$vstrategy"
                fi
            fi
        fi
        i=$((i + 1))
    done
}

# ====================================================================
# サブコマンド: sync-items
# ====================================================================
_subcmd_sync_items() {
    _parse_common_opts sync-items "$@"
    _check_scopes_or_exit

    local spec_json
    spec_json="$(_load_spec_or_exit)"
    local owner number
    owner="$(printf '%s' "$spec_json" | jq -r '.project.owner')"
    number="$(_read_runtime_binding "project_number")"
    if [[ -z "$number" ]]; then
        _emit_error "evidence_missing" "runtime_binding_missing:project_number" \
            "Run 'gh-project-cli.sh ensure-project' first"
        exit 5
    fi

    # 対象 Issue 集合を抽出（Issue #524 + backlog ラベル の union）
    local urls=()
    # 1. Issue #524 本文から URL 抽出
    local issue524_body
    issue524_body="$(gh issue view 524 --json body --jq '.body' 2>/dev/null || echo "")"
    while IFS= read -r url; do
        [[ -n "$url" ]] && urls+=("$url")
    done < <(printf '%s' "$issue524_body" | grep -oE 'https://github.com/[^ )]+/(issues|pull)/[0-9]+' | sort -u)

    # 2. backlog ラベル付き Open Issue
    while IFS= read -r url; do
        [[ -n "$url" ]] && urls+=("$url")
    done < <(gh issue list --label backlog --state open --json url --jq '.[].url' --limit 200 2>/dev/null || true)

    # union + Issue 番号昇順ソート
    local sorted_urls
    sorted_urls="$(printf '%s\n' "${urls[@]}" | sort -u -t / -k 7 -n)"

    local existing_items existing_fields
    existing_items="$(gh_project_state_get_items "$owner" "$number" 2>/dev/null || echo '{"items":[]}')"
    existing_fields="$(gh_project_state_get_fields "$owner" "$number" 2>/dev/null || echo '{"fields":[]}')"

    # 統合レビュー R1 #1 (B 案 / 最小実装): Status field の id と Backlog option id を解決
    # Priority / Cycle の派生は別 Issue (defer) で実装。
    local status_field_id="" status_backlog_option_id=""
    status_field_id="$(printf '%s' "$existing_fields" | jq -r '.fields[]? | select(.name=="Status") | .id // empty' | head -1)"
    if [[ -n "$status_field_id" ]]; then
        status_backlog_option_id="$(printf '%s' "$existing_fields" | jq -r '.fields[]? | select(.name=="Status") | .options[]? | select(.name=="Backlog") | .id // empty' | head -1)"
    fi

    local count_added=0 count_skipped=0 count_status_set=0
    while IFS= read -r url; do
        [[ -z "$url" ]] && continue
        local exists
        exists="$(printf '%s' "$existing_items" | jq -r --arg u "$url" '.items[]? | select(.content.url==$u) | .id // empty' 2>/dev/null | head -1)"
        if [[ -n "$exists" ]]; then
            printf 'item:exists:%s\n' "$url"
            count_skipped=$((count_skipped + 1))
        else
            if $_DRY_RUN; then
                printf 'item:would-add:%s\n' "$url"
                if [[ -n "$status_backlog_option_id" ]]; then
                    printf 'item:would-set-status:%s:Backlog\n' "$url"
                fi
            else
                # R1 #2: API 失敗を握りつぶさず、失敗時は gh_api_error で exit 3
                local item_id rc=0
                item_id="$(gh_project_repo_add_item "$owner" "$number" "$url" 2>&1)" || rc=$?
                if [[ $rc -ne 0 ]]; then
                    _emit_error "gh_api_error" "item_add_failed"
                    exit 3
                fi
                printf 'item:added:%s\n' "$url"
                # 統合レビュー R1 #1: Status=Backlog 初期値設定（Priority/Cycle は別 Issue defer）
                if [[ -n "$item_id" ]] && [[ -n "$status_field_id" ]] && [[ -n "$status_backlog_option_id" ]]; then
                    local set_rc=0
                    gh_project_repo_set_item_field_value "$owner" "$number" "$item_id" "$status_field_id" "$status_backlog_option_id" >/dev/null 2>&1 || set_rc=$?
                    if [[ $set_rc -eq 0 ]]; then
                        printf 'item:status-set:%s:Backlog\n' "$url"
                        count_status_set=$((count_status_set + 1))
                    else
                        printf 'item:status-set-failed:%s:exit=%d\n' "$url" "$set_rc"
                    fi
                fi
            fi
            count_added=$((count_added + 1))
        fi
    done <<< "$sorted_urls"

    printf 'sync-items:summary:added=%d:skipped=%d:status_set=%d\n' "$count_added" "$count_skipped" "$count_status_set"
}

# ====================================================================
# サブコマンド: audit (audit-github-project.sh への委譲)
# ====================================================================
_subcmd_audit() {
    _parse_common_opts audit "$@"
    local audit_script="${_SCRIPT_DIR}/audit-github-project.sh"
    if [[ ! -x "$audit_script" ]]; then
        _emit_error "evidence_missing" "audit_script_not_found:${audit_script}"
        exit 5
    fi
    "$audit_script" --check "$_AUDIT_CHECK" "--${_MODE}"
}

# ====================================================================
# ディスパッチ
# ====================================================================
_subcmd="${1:-}"
shift || true
case "$_subcmd" in
    ensure-project) _subcmd_ensure_project "$@" ;;
    ensure-fields)  _subcmd_ensure_fields "$@" ;;
    ensure-views)   _subcmd_ensure_views "$@" ;;
    sync-items)     _subcmd_sync_items "$@" ;;
    audit)          _subcmd_audit "$@" ;;
    ""|help|--help)
        cat <<USAGE
gh-project-cli.sh - GitHub Projects (ProjectsV2) declarative CLI

Usage:
  gh-project-cli.sh ensure-project [--dry-run] [--strict|--soft]
  gh-project-cli.sh ensure-fields  [--dry-run] [--strict|--soft]
  gh-project-cli.sh ensure-views   [--dry-run] [--strict|--soft]
  gh-project-cli.sh sync-items     [--dry-run] [--strict|--soft]
  gh-project-cli.sh audit          [--check workflow-item-closed|spec-conformance|all] [--strict|--soft]

Defaults:
  ensure-* / sync-items: --strict
  audit:                 --soft (CI should pass --strict explicitly)

See: docs/development/github-projects-setup.md
USAGE
        ;;
    *)
        _emit_error "args_invalid" "unknown_subcommand:${_subcmd}"
        exit 1
        ;;
esac
