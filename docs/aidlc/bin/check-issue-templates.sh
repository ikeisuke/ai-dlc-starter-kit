#!/usr/bin/env bash
#
# check-issue-templates.sh - ローカルとリモートのIssueテンプレート差分を検出
#
# 使用方法:
#   ./check-issue-templates.sh [--ref <branch>]
#
# パラメータ:
#   --ref <branch>: 比較対象ブランチ（デフォルト: リポジトリのデフォルトブランチ）
#
# 出力形式:
#   - 差分なし: "template_diff:none"
#   - 差分あり: "template_diff:found" + 後続行に詳細
#     - "template_diff_local_only:<files>"
#     - "template_diff_remote_only:<files>"
#     - "template_diff_modified:<files>"
#   - エラー: "error:<エラー種別>[:<コンテキスト>]"
#
# 終了コード:
#   0: 正常終了（差分の有無に関わらず）
#   1: エラー（gh/git未インストール、API失敗等）
#

set -euo pipefail

# デフォルト値
REF=""

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --ref)
            if [[ $# -lt 2 ]]; then
                echo "error:missing-ref-value"
                exit 1
            fi
            REF="$2"
            shift 2
            ;;
        *)
            echo "error:unknown-option:$1"
            exit 1
            ;;
    esac
done

# GitHub CLIの存在確認
if ! command -v gh >/dev/null 2>&1; then
    echo "error:gh-not-installed"
    exit 1
fi

# gitの存在確認
if ! command -v git >/dev/null 2>&1; then
    echo "error:git-not-installed"
    exit 1
fi

# 認証確認
if ! gh auth status >/dev/null 2>&1; then
    echo "error:gh-not-authenticated"
    exit 1
fi

# gitリポジトリ確認
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "error:no-repo"
    exit 1
fi

# 一時ディレクトリ作成
_tmp_dir=$(mktemp -d) || { echo "error:mktemp-failed"; exit 1; }
trap '\rm -rf "$_tmp_dir"' EXIT
_tmp_stderr="$_tmp_dir/stderr.log"

# base64デコード（BSD/GNU互換）
_base64_decode() {
    base64 --decode 2>/dev/null || base64 -d 2>/dev/null || base64 -D 2>/dev/null
}

# リポジトリ情報取得
_repo_info=$(gh repo view --json owner,name --jq '.owner.login + "/" + .name' 2>"$_tmp_stderr") || {
    echo "error:gh-api-failed:repo-info"
    cat "$_tmp_stderr" >&2
    exit 1
}

# 比較対象ブランチ決定
if [[ -z "$REF" ]]; then
    REF=$(gh repo view --json defaultBranchRef --jq '.defaultBranchRef.name' 2>"$_tmp_stderr") || {
        echo "error:gh-api-failed:default-branch"
        cat "$_tmp_stderr" >&2
        exit 1
    }
fi

# REFのURLエンコード（&や特殊文字のクエリ改変を防止）
_url_encode() {
    local _input="$1" _i _c _encoded=""
    for (( _i=0; _i<${#_input}; _i++ )); do
        _c="${_input:_i:1}"
        case "$_c" in
            [a-zA-Z0-9._~/-]) _encoded+="$_c" ;;
            *) _encoded+=$(printf '%%%02X' "'$_c") ;;
        esac
    done
    printf '%s' "$_encoded"
}
_encoded_ref=$(_url_encode "$REF")

# リモートテンプレート一覧取得（HTTPステータスで判定）
_remote_response_file="$_tmp_dir/remote_response.txt"
# gh api -iは404等でも非0終了するため、set +eで一時的にエラー無視
set +e
gh api -i "/repos/${_repo_info}/contents/.github/ISSUE_TEMPLATE?ref=${_encoded_ref}" >"$_remote_response_file" 2>"$_tmp_stderr"
_api_exit=$?
set -e

_http_status=$(head -1 "$_remote_response_file" | sed -n 's/.*\([0-9]\{3\}\).*/\1/p' | head -1)

if [[ "$_http_status" == "404" ]]; then
    echo "error:remote-template-path-not-found"
    exit 1
elif [[ "$_http_status" != "200" ]] || [[ $_api_exit -ne 0 && -z "$_http_status" ]]; then
    echo "error:gh-api-failed:contents"
    cat "$_tmp_stderr" >&2
    exit 1
fi

# リモートファイル名一覧抽出（.ymlファイルのみ、--jqでフィルタ）
_remote_files_file="$_tmp_dir/remote_files.txt"
_remote_names=$(gh api "/repos/${_repo_info}/contents/.github/ISSUE_TEMPLATE?ref=${_encoded_ref}" --jq '[.[] | select(.name | test("\\.yml$")) | .name] | sort | .[]' 2>"$_tmp_stderr") || {
    echo "error:gh-api-failed:contents"
    cat "$_tmp_stderr" >&2
    exit 1
}
printf '%s\n' "$_remote_names" | grep -v '^$' | sort > "$_remote_files_file" || true

# ローカルテンプレート一覧取得
_local_files_file="$_tmp_dir/local_files.txt"
_template_dir=".github/ISSUE_TEMPLATE"
if [[ -d "$_template_dir" ]]; then
    find "$_template_dir" -maxdepth 1 -type f -name '*.yml' | while IFS= read -r _path; do
        echo "${_path##*/}"
    done | sort > "$_local_files_file"
else
    touch "$_local_files_file"
fi

# 差分比較
_local_only_file="$_tmp_dir/local_only.txt"
_remote_only_file="$_tmp_dir/remote_only.txt"
_common_file="$_tmp_dir/common.txt"

# ローカルのみ存在
comm -23 "$_local_files_file" "$_remote_files_file" > "$_local_only_file"
# リモートのみ存在
comm -13 "$_local_files_file" "$_remote_files_file" > "$_remote_only_file"
# 両方に存在
comm -12 "$_local_files_file" "$_remote_files_file" > "$_common_file"

# 内容差分確認（両方に存在するファイル）
_modified_files=""
while IFS= read -r _filename; do
    # リモートファイル内容取得（Base64デコード）
    _remote_content_file="$_tmp_dir/remote_${_filename}"
    _api_content=$(gh api "/repos/${_repo_info}/contents/.github/ISSUE_TEMPLATE/${_filename}?ref=${_encoded_ref}" --jq '.content' 2>"$_tmp_stderr") || {
        echo "error:gh-api-failed:file:${_filename}"
        cat "$_tmp_stderr" >&2
        exit 1
    }
    printf '%s' "$_api_content" | _base64_decode > "$_remote_content_file" 2>/dev/null || {
        echo "error:gh-api-failed:file:${_filename}"
        exit 1
    }

    # ローカルファイルとの差分比較
    if ! diff -q "$_template_dir/${_filename}" "$_remote_content_file" >/dev/null 2>&1; then
        if [[ -n "$_modified_files" ]]; then
            _modified_files="${_modified_files},${_filename}"
        else
            _modified_files="${_filename}"
        fi
    fi
done < "$_common_file"

# 結果出力
_local_only_list=$(paste -sd, "$_local_only_file" 2>/dev/null || true)
_remote_only_list=$(paste -sd, "$_remote_only_file" 2>/dev/null || true)

if [[ -z "$_local_only_list" && -z "$_remote_only_list" && -z "$_modified_files" ]]; then
    echo "template_diff:none"
else
    echo "template_diff:found"
    if [[ -n "$_local_only_list" ]]; then
        echo "template_diff_local_only:${_local_only_list}"
    fi
    if [[ -n "$_remote_only_list" ]]; then
        echo "template_diff_remote_only:${_remote_only_list}"
    fi
    if [[ -n "$_modified_files" ]]; then
        echo "template_diff_modified:${_modified_files}"
    fi
fi
