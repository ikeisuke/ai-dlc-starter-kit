#!/usr/bin/env bash
#
# bin/setup-github-project.sh - 薄い orchestrator
#
# bin/gh-project-cli.sh の各サブコマンドを順次呼び出す。失敗時は即時 exit。
# デフォルトモードは --strict（実環境 apply のため fail-fast / R3 指摘 #1 反映）。
#
# Usage:
#   bin/setup-github-project.sh [--dry-run] [--strict|--soft]

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_CLI="${_SCRIPT_DIR}/gh-project-cli.sh"

# R2 #5: 他スクリプトと同じ jq エスケープ統一の _emit_error ヘルパー
_emit_error() {
    local error_type="$1"; local details="$2"; local remediation="${3:-}"
    if command -v jq >/dev/null 2>&1; then
        jq -n --arg t "$error_type" --arg d "$details" --arg r "$remediation" \
            '{error_type:$t, details:$d, remediation:$r}' >&2
    else
        printf '{"error_type":"%s","details":"jq_unavailable","remediation":""}\n' "$error_type" >&2
    fi
}

if [[ ! -x "$_CLI" ]]; then
    _emit_error "evidence_missing" "gh_project_cli_not_executable:${_CLI}" \
        "Ensure bin/gh-project-cli.sh exists and is executable"
    exit 5
fi

_OPTS=("$@")

printf '== ensure-project ==\n'
"$_CLI" ensure-project "${_OPTS[@]}"

printf '\n== ensure-fields ==\n'
"$_CLI" ensure-fields "${_OPTS[@]}"

printf '\n== ensure-views ==\n'
"$_CLI" ensure-views "${_OPTS[@]}"

printf '\n== sync-items ==\n'
"$_CLI" sync-items "${_OPTS[@]}"

printf '\n== audit (spec-conformance) ==\n'
"$_CLI" audit --check spec-conformance "${_OPTS[@]/--dry-run/}"

printf '\nsetup-github-project: completed\n'
