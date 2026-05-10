#!/usr/bin/env bash
#
# bin/migrate-issue-524.sh - Issue #524 を Project URL リダイレクトに置換
#
# 設計参照: .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md
#
# Usage:
#   bin/migrate-issue-524.sh [--dry-run] [--strict|--soft]

set -euo pipefail
IFS=$'\n\t'  # R1 #8: 単語分割事故防止 (改行 + tab のみで分割)

_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
_LIB_DIR="${_SCRIPT_DIR}/lib"
_REPO_ROOT="${AIDLC_REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || echo .)}"
_RUNTIME_TOML="${AIDLC_RUNTIME_TOML:-${_REPO_ROOT}/.aidlc/config.toml}"
_BACKUP_DIR="${_REPO_ROOT}/.aidlc/cycles/v2.6.0/operations"
_BACKUP_FILE="${_BACKUP_DIR}/issue-524-backup.md"

# shellcheck source=lib/gh-scope-check.sh
source "${_LIB_DIR}/gh-scope-check.sh"

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

DRY_RUN=false
MODE="strict"
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        --strict)  MODE="strict"; shift ;;
        --soft)    MODE="soft"; shift ;;
        *) _emit_error "args_invalid" "unknown_option:$1"; exit 1 ;;
    esac
done

if ! gh_scope_check_require "--${MODE}" project read:org; then
    exit 2
fi

# Project URL を runtime binding から取得
_project_url=""
if [[ -f "$_RUNTIME_TOML" ]] && command -v dasel >/dev/null 2>&1; then
    _project_url="$(dasel -f "$_RUNTIME_TOML" "github_projects.project_url" 2>/dev/null || echo "")"
fi
if [[ -z "$_project_url" ]]; then
    _emit_error "evidence_missing" "project_url_missing" \
        "Run 'bin/gh-project-cli.sh ensure-project' first to set runtime binding"
    exit 5
fi

# 旧本文を取得・バックアップ
_current_body=""
_view_rc=0
_current_body="$(gh issue view 524 --json body --jq '.body' 2>&1)" || _view_rc=$?
if [[ $_view_rc -ne 0 ]]; then
    # R1 #4: gh エラー本文をそのまま埋め込まず、要約のみに留める
    _emit_error "gh_api_error" "issue_view_failed:exit=${_view_rc}" \
        "Run 'gh issue view 524' manually to diagnose"
    exit 3
fi

mkdir -p "$_BACKUP_DIR"
if [[ ! -f "$_BACKUP_FILE" ]]; then
    printf '%s' "$_current_body" > "$_BACKUP_FILE"
    printf 'issue-524:backup-saved:%s\n' "$_BACKUP_FILE"
fi

# 新本文テンプレート
_new_body="$(cat <<EOF
# ロードマップ管理は GitHub Projects へ移行しました（v2.6.0〜）

このリポジトリのバックログ管理は **GitHub Projects (ProjectsV2)** に移行しました。
本 Issue は既存リンクの後方互換のために残置されています。

## 参照先

- **Project**: ${_project_url}
- **運用ルール**: [docs/development/github-projects-setup.md](../blob/main/docs/development/github-projects-setup.md)
- **AI-DLC 統合**: \`/aidlc i\` 起動時のバックログ確認ステップに Project 参照が組み込まれています

## 移行履歴

- **〜v2.5.x**: 本 Issue 本文に手動チェックリストでバックログを管理
- **v2.6.0**: GitHub Projects (ProjectsV2) に移行、本 Issue はリダイレクト化
- 旧本文は \`.aidlc/cycles/v2.6.0/operations/issue-524-backup.md\` に保管

完了済セクションの手動削除運用は廃止されました。Project の自動化 workflow（\`Item closed → Status=Done\`）で自動管理されます。
EOF
)"

if $DRY_RUN; then
    diff_path="${_BACKUP_DIR}/issue-524-new-body.dryrun.md"
    printf '%s' "$_new_body" > "$diff_path"
    printf 'issue-524:would-edit:%s\n' "$diff_path"
    exit 0
fi

# 一時ファイルに新本文を書き出して edit
tmp_body="$(mktemp -t issue-524-body.XXXXXX)"
trap 'rm -f "$tmp_body"' EXIT
printf '%s' "$_new_body" > "$tmp_body"

if ! gh issue edit 524 --body-file "$tmp_body" 2>&1; then
    _emit_error "gh_api_error" "issue_edit_failed"
    exit 3
fi

printf 'issue-524:edited\n'
