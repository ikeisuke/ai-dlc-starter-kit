#!/usr/bin/env bash
# retrospective-human-review.sh - Unit 003 人間確認運用 hook 実装
#
# 提供する公開関数:
#   retrospective_update_hook <issue_url> <cycle>
#       -> stdout 任意 / stderr に状態通知
#       -> exit 0=成功（gh 失敗 warn 含む / 冪等 skip / no-op skip） / 1=ランタイム異常 / 2=引数エラー
#
# 環境変数（main agent 前段手順）:
#   AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH - 人間確認後の最終 YAML（未設定時は「差分なし」扱い）
#
# 順序不変条件（plan §「リスク R3 緩和」/ ドメインサービス HumanReviewIssueWriter 準拠）:
#   差分あり: gh issue comment → gh issue edit --body-file → gh issue edit --add-label
#   差分なし: gh issue edit --body-file（human_reviewed: false → true のみ）→ gh issue edit --add-label
#   前段失敗時は後段スキップ（exit 0 + stderr warn）
#
# stderr フォーマット: <level>\t<code>\t<detail>  (level=info|warn|error)

# 多重 source ガード
if [[ "${__AIDLC_RETROSPECTIVE_HUMAN_REVIEW_SH_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi
__AIDLC_RETROSPECTIVE_HUMAN_REVIEW_SH_LOADED=1

# ─── 診断出力ヘルパ ─────────
__retro_hr_diag() {
    # $1: level, $2: code, $3: detail
    printf '%s\t%s\t%s\n' "$1" "$2" "$3" >&2
}

# ─── URL 検証（GitHub Issue URL 厳密形式）─────────
# 戻り値: 0=ok / 1=invalid
__retro_hr_validate_url() {
    local url="$1"
    [[ "$url" =~ ^https://github\.com/[A-Za-z0-9._-]+/[A-Za-z0-9._-]+/issues/[0-9]+/?$ ]]
}

# ─── Issue 番号抽出（URL から最後の /<N> を取る）─────────
__retro_hr_issue_number() {
    local url="$1"
    local trimmed="${url%/}"
    printf '%s\n' "${trimmed##*/}"
}

# ─── 本文取得（gh issue view）─────────
# stdout: 本文（成功時）
# 戻り値: 0=成功 / 1=失敗
__retro_hr_fetch_body() {
    local issue_number="$1"
    local body
    if ! body=$(gh issue view "$issue_number" --json body --jq '.body' 2>&1); then
        return 1
    fi
    printf '%s\n' "$body"
    return 0
}

# ─── 本文 YAML から human_reviewed 抽出 ─────────
# stdout: "true" / "false" / "missing"
__retro_hr_parse_human_reviewed() {
    local body="$1"
    local line
    line=$(printf '%s\n' "$body" | grep -E '^human_reviewed:' | head -1)
    if [[ -z "$line" ]]; then
        printf 'missing\n'
        return 0
    fi
    if printf '%s\n' "$line" | grep -qE '^human_reviewed:[[:space:]]*true[[:space:]]*$'; then
        printf 'true\n'
    else
        printf 'false\n'
    fi
    return 0
}

# ─── 本文 update（human_reviewed: false → true 置換）─────────
# stdin: 既存本文
# stdout: 新本文
__retro_hr_update_body_marker() {
    local body="$1"
    # human_reviewed: false / human_reviewed: ... を human_reviewed: true に置換
    # sed で複数パターンに対応
    printf '%s\n' "$body" | sed -E 's/^(human_reviewed:[[:space:]]*).*$/\1true/'
}

# ─── 本文 update ロジック ─────────
# Plan §「変更対象ファイル」は「本文 update（`human_reviewed: false → true`）+ 差分検出 + コメント追記」を分離した責務として定義。
# 実 Issue 本文は Markdown 展開（`## 問題項目（Problem）`）で `problem_drafts:` を直接保持しないため、
# hook では本文 update を `human_reviewed` 更新に限定し、final_path の内容差分は [llm-diff] コメントで記録する。
# （final_path 内容の本文反映は将来サイクルで Markdown 再生成も含めて検討）
__retro_hr_apply_final_drafts() {
    local current_body="$1"
    # final_yaml_path は [llm-diff] コメント側で活用済（呼出元 retrospective_update_hook 参照）
    __retro_hr_update_body_marker "$current_body"
}

# ─── 差分判定（FINAL_PATH 未設定/不在/空 → 差分なし）─────────
# 戻り値: 0=差分あり / 1=差分なし（bash convention に整合）
__retro_hr_has_diff() {
    local final_path="$1"
    [[ -z "$final_path" ]] && return 1  # FINAL_PATH 未設定 = 差分なし
    [[ ! -f "$final_path" ]] && return 1  # ファイル不在 = 差分なし
    [[ -s "$final_path" ]] && return 0    # ファイル非空 = 差分あり
    return 1
}

# ─── [llm-diff] コメント生成 ─────────
# 引数: $1=cycle / $2=original_yaml_text / $3=final_yaml_text
# stdout: Markdown コメント本文
__retro_hr_compose_diff_comment() {
    local cycle="$1"
    local original_text="$2"
    local final_text="$3"

    {
        printf '[llm-diff] LLM 推論結果と人間確認後の差分（cycle: %s）\n\n' "$cycle"
        printf '## LLM 推論結果\n\n'
        printf '```yaml\n'
        printf '%s\n' "$original_text"
        printf '```\n\n'
        printf '## 人間確認後の最終結果\n\n'
        printf '```yaml\n'
        printf '%s\n' "$final_text"
        printf '```\n\n'
        printf '## 差分一覧\n\n'
        printf '（diff の詳細は本文 YAML の差分を参照してください）\n'
    }
}

# ─── 公開関数: retrospective_update_hook ─────────
retrospective_update_hook() {
    # 引数検証
    if [[ $# -lt 2 ]]; then
        __retro_hr_diag "error" "human_review_missing_args" \
            "expected: retrospective_update_hook <issue_url> <cycle>"
        return 2
    fi

    local issue_url="$1"
    local cycle="$2"

    if [[ -z "$cycle" ]]; then
        __retro_hr_diag "error" "human_review_missing_args" "cycle is empty"
        return 2
    fi

    # issue_url == "" は no-op skip
    if [[ -z "$issue_url" ]]; then
        __retro_hr_diag "info" "human_review_skip_no_issue" "issue_url is empty (no-op)"
        return 0
    fi

    # URL 形式検証
    if ! __retro_hr_validate_url "$issue_url"; then
        __retro_hr_diag "error" "human_review_invalid_url" \
            "issue_url does not match https://github.com/<owner>/<repo>/issues/<N>: $issue_url"
        return 2
    fi

    local issue_number
    issue_number=$(__retro_hr_issue_number "$issue_url")

    # 本文取得
    local current_body
    if ! current_body=$(__retro_hr_fetch_body "$issue_number"); then
        __retro_hr_diag "warn" "human_review_gh_edit_failed" \
            "failed to fetch issue body for $issue_url"
        return 0
    fi

    # human_reviewed 抽出
    local current_marker
    current_marker=$(__retro_hr_parse_human_reviewed "$current_body")

    # 既に true なら冪等 skip
    if [[ "$current_marker" == "true" ]]; then
        __retro_hr_diag "info" "human_review_already_done" \
            "human_reviewed: true already set on $issue_url"
        return 0
    fi

    # FINAL_PATH 取得
    local final_path="${AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH:-}"

    # FINAL_PATH 設定済 + ファイル存在確認
    if [[ -n "$final_path" && ! -f "$final_path" ]]; then
        __retro_hr_diag "error" "human_review_io_error" \
            "AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH file not found: $final_path"
        return 1
    fi

    # 差分判定（0=差分あり / 1=差分なし: bash convention）
    local has_diff=0
    if __retro_hr_has_diff "$final_path"; then
        has_diff=1
    fi

    # ───── 順序不変条件: comment → edit --body-file → edit --add-label ─────

    if [[ "$has_diff" -eq 1 ]]; then
        # コメント追記
        local original_yaml_text=""
        local final_yaml_text=""
        # problem_drafts: 行から次のトップレベルキー直前までを抽出（POSIX 互換: sed '$d' で末尾削除）
        original_yaml_text=$(printf '%s\n' "$current_body" | sed -n '/^problem_drafts:/,/^[a-z_]*:/p' | sed '$d')
        if [[ -n "$final_path" ]] && [[ -f "$final_path" ]]; then
            final_yaml_text=$(cat "$final_path")
        fi

        local comment_body
        comment_body=$(__retro_hr_compose_diff_comment "$cycle" "$original_yaml_text" "$final_yaml_text")

        if ! printf '%s\n' "$comment_body" | gh issue comment "$issue_number" --body-file - >/dev/null 2>&1; then
            __retro_hr_diag "warn" "human_review_gh_comment_failed" \
                "gh issue comment failed for $issue_url (skipping body update / label)"
            return 0
        fi
    fi

    # 本文 update
    local new_body
    if [[ "$has_diff" -eq 1 && -n "$final_path" ]]; then
        new_body=$(__retro_hr_apply_final_drafts "$current_body" "$final_path")
    else
        new_body=$(__retro_hr_update_body_marker "$current_body")
    fi

    local tmp_body_file
    tmp_body_file=$(mktemp -t aidlc-retro-update-body.XXXXXX) || {
        __retro_hr_diag "error" "human_review_io_error" "mktemp failed"
        return 1
    }

    printf '%s\n' "$new_body" > "$tmp_body_file"

    local edit_rc=0
    if ! gh issue edit "$issue_number" --body-file "$tmp_body_file" >/dev/null 2>&1; then
        edit_rc=1
    fi
    rm -f -- "$tmp_body_file"

    if [[ "$edit_rc" -ne 0 ]]; then
        __retro_hr_diag "warn" "human_review_gh_edit_failed" \
            "gh issue edit --body-file failed for $issue_url (skipping label add)"
        return 0
    fi

    # ラベル付与
    if ! gh issue edit "$issue_number" --add-label human-reviewed >/dev/null 2>&1; then
        __retro_hr_diag "warn" "human_review_label_failed" \
            "gh issue edit --add-label human-reviewed failed for $issue_url (continuing)"
    fi

    if [[ "$has_diff" -eq 1 ]]; then
        __retro_hr_diag "info" "human_review_diff_recorded" \
            "diff recorded + body updated + label added for $issue_url"
    else
        __retro_hr_diag "info" "human_review_skip_no_diff" \
            "no diff / body marker updated for $issue_url"
    fi
    return 0
}
