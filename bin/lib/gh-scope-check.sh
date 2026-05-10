#!/usr/bin/env bash
#
# bin/lib/gh-scope-check.sh - gh PAT 必須スコープ検証ライブラリ
#
# 設計参照: .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md §gh-scope-check.sh
#
# 公開関数:
#   gh_scope_check_require [--strict|--soft] <scope1> [scope2 ...]
#
# 終了コード（共通契約）:
#   0  : ok / soft 不足（warn のみ）
#   1  : args_invalid（引数フォーマット不正）
#   2  : scope_missing（strict 不足）
#   3  : gh_api_error（gh auth status 失敗）
#
# 副作用:
#   - .aidlc/cache/gh-project-last-run.json に構造化結果を書き出す（soft / 不足時）

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

# stderr に JSON エラーを出力（error_type 必須 / 共通契約 R1 #5）
# R1 #4: jq でエスケープして JSON 注入リスクを排除
_gh_scope_emit_error() {
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

_gh_scope_cache_dir() {
    local repo_root
    repo_root="${AIDLC_REPO_ROOT:-}"
    if [[ -z "$repo_root" ]]; then
        repo_root="$(git rev-parse --show-toplevel 2>/dev/null || echo .)"
    fi
    printf '%s/.aidlc/cache' "$repo_root"
}

# 現在の token scopes を抽出（カンマ区切り）。失敗時は空文字列
_gh_scope_extract_current() {
    local status_output
    if ! status_output="$(gh auth status 2>&1)"; then
        echo ""
        return 3
    fi
    # "Token scopes: 'a', 'b', 'c'" 行を抽出
    local scopes_line
    scopes_line="$(printf '%s\n' "$status_output" | grep -E "Token scopes:" | head -1 || true)"
    if [[ -z "$scopes_line" ]]; then
        echo ""
        return 0
    fi
    # 正規表現で 'xxx' をすべて抽出 → カンマ区切り
    printf '%s\n' "$scopes_line" \
        | grep -oE "'[^']+'" \
        | tr -d "'" \
        | paste -sd "," -
}

# 必須スコープ集合と現在のスコープ集合を比較し、不足リスト（カンマ区切り）を返す
_gh_scope_diff_missing() {
    local required="$1"  # space-separated
    local current="$2"   # comma-separated
    local missing=()
    local req
    for req in $required; do
        if ! printf ',%s,' "$current" | grep -qE ",${req}," ; then
            missing+=("$req")
        fi
    done
    local IFS=,
    printf '%s' "${missing[*]}"
}

# 公開関数: スコープ要求を検証
gh_scope_check_require() {
    local mode="soft"  # デフォルト soft
    if [[ $# -ge 1 ]]; then
        case "$1" in
            --strict) mode="strict"; shift ;;
            --soft)   mode="soft";   shift ;;
        esac
    fi

    if [[ $# -eq 0 ]]; then
        _gh_scope_emit_error "args_invalid" "required_scopes_empty" "Pass at least one scope name"
        return 1
    fi

    local required="$*"
    local current
    if ! current="$(_gh_scope_extract_current)"; then
        _gh_scope_emit_error "gh_api_error" "gh_auth_status_failed" "Run 'gh auth status' to diagnose"
        return 3
    fi

    local missing
    missing="$(_gh_scope_diff_missing "$required" "$current")"

    if [[ -z "$missing" ]]; then
        return 0
    fi

    # 不足あり: cache に記録
    local cache_dir
    cache_dir="$(_gh_scope_cache_dir)"
    mkdir -p "$cache_dir"
    local cache_file="${cache_dir}/gh-project-last-run.json"
    local timestamp
    timestamp="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
    local missing_json
    missing_json="$(printf '%s' "$missing" | tr ',' '\n' | sed 's/.*/"&"/' | paste -sd "," -)"
    printf '{"status":"scope_missing","missing":[%s],"mode":"%s","timestamp":"%s"}\n' \
        "$missing_json" "$mode" "$timestamp" > "$cache_file"

    if [[ "$mode" == "strict" ]]; then
        printf 'ERROR: missing gh token scopes: %s\n' "$missing" >&2
        printf "Run: gh auth refresh -s %s\n" "$missing" >&2
        _gh_scope_emit_error "scope_missing" "missing:${missing}" "gh auth refresh -s ${missing}"
        return 2
    else
        printf 'WARN: missing gh token scopes: %s\n' "$missing" >&2
        printf "Run: gh auth refresh -s %s\n" "$missing" >&2
        return 0
    fi
}

# CLI invocation
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
    gh_scope_check_require "$@"
fi
