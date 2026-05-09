#!/bin/bash
# cycle-resolver.sh
#
# 振り返り対象サイクル特定の独立公開コンポーネント（v2.6.0 Unit 005 で新設）
#
# 4 つの Strategy を実行し、優先順位 + fail-safe ガードを適用して対象サイクルを返す。
#
# 設計参照:
#   .aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_005_aidlc_retrospective_skill_extraction_logical_design.md
#
# 公開関数: cycle_resolver_resolve <additional_context>
#   stdout: 4 行 + summary（key=value 形式）
#       candidate=<cycle>
#       source_id=<arg|branch|gitlog|cycledir|user_input>
#       confidence=<high|medium|low>
#       evidence=<人間可読の決定根拠>
#   exit:
#       0=成功（user_input でも 0）
#       1=全 Strategy 解決失敗（候補ゼロ + 対話モードで応答なし）
#       2=fatal（将来の内部 cross-check 不整合用に予約。現行実装では未到達）
#
# Strategy 内の return code 規約（現行実装）:
#   0=候補確定（stdout 出力あり）
#   1=候補なし（command -v 不在 / 非 git リポ / 出力空 / 形式不一致 等の想定内エラーを集約）
#
# 将来 Strategy が rc=2 を返す拡張に備え、resolve() 側では各 Strategy の rc=2 を
# 即時 fatal として伝播する分岐を持つ。現行実装ではいずれの Strategy も rc=2 を
# 返さないため、resolve() の rc=2 path は実質予約状態である。

# 多重 source ガード
if [[ -n "${CYCLE_RESOLVER_SOURCED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
CYCLE_RESOLVER_SOURCED=1

# ─── ユーティリティ ────────────────────────────────────────────────

# vX.Y.Z 形式の検証
_cycle_resolver_is_semver() {
    [[ "$1" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

# semver の降順比較用キー（vX.Y.Z → "X.Y.Z" の sort -V 入力）
_cycle_resolver_strip_v() {
    printf '%s\n' "$1" | sed 's/^v//'
}

# ─── Strategy 実装 ────────────────────────────────────────────────

# S1 ArgStrategy: additional_context が vX.Y.Z 形式
# stdout: candidate=<v>\nsource_id=arg\nconfidence=high\nevidence=...
_cycle_resolver_strategy_arg() {
    local arg="$1"
    if [[ -z "$arg" ]]; then
        return 1
    fi
    if _cycle_resolver_is_semver "$arg"; then
        printf 'candidate=%s\nsource_id=arg\nconfidence=high\nevidence=additional_context "%s" (semver 形式一致)\n' \
            "$arg" "$arg"
        return 0
    fi
    return 1
}

# S2 BranchStrategy: カレントブランチが cycle/vX.Y.Z
_cycle_resolver_strategy_branch() {
    if ! command -v git >/dev/null 2>&1; then
        return 1
    fi
    local branch rc
    branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
    rc=$?
    # rc != 0: 非 git リポジトリ等の想定内エラー → 候補なし扱い
    if [[ $rc -ne 0 ]] || [[ -z "$branch" ]]; then
        return 1
    fi
    if [[ "$branch" =~ ^cycle/(v[0-9]+\.[0-9]+\.[0-9]+)$ ]]; then
        local cycle="${BASH_REMATCH[1]}"
        printf 'candidate=%s\nsource_id=branch\nconfidence=high\nevidence=current branch "%s"\n' \
            "$cycle" "$branch"
        return 0
    fi
    return 1
}

# S3a GitLogStrategy: git log でマージ済 cycle/* の最新を検出
# 第一: git log（オフライン可）/ 第二: gh pr list（fallback）
_cycle_resolver_strategy_gitlog() {
    local found=""
    # 第一: git log の merge commit メッセージから cycle/v* を抽出
    if command -v git >/dev/null 2>&1; then
        local git_log_out git_rc
        # main ブランチが存在しない / 非 git リポジトリ等は想定内エラー → 候補なし扱い
        git_log_out=$(git log --merges --first-parent main --pretty=format:'%s' 2>/dev/null)
        git_rc=$?
        if [[ $git_rc -eq 0 && -n "$git_log_out" ]]; then
            local raw
            raw=$(printf '%s\n' "$git_log_out" \
                | grep -oE 'cycle/v[0-9]+\.[0-9]+\.[0-9]+' \
                | sed 's|cycle/||' \
                | head -100 \
                | sed 's/^v//' \
                | sort -V \
                | tail -1) || raw=""
            if [[ -n "$raw" ]]; then
                found="v$raw"
            fi
        fi
    fi
    # 第二: gh pr list（git log で空かつ gh available）
    if [[ -z "$found" ]] && command -v gh >/dev/null 2>&1; then
        local gh_out gh_rc
        gh_out=$(gh pr list --state merged --base main --limit 100 --json headRefName 2>/dev/null)
        gh_rc=$?
        # gh の認証エラー / ネットワーク不通は想定内エラー → 候補なし扱い
        if [[ $gh_rc -eq 0 && -n "$gh_out" ]]; then
            local pr_raw
            pr_raw=$(printf '%s\n' "$gh_out" \
                | grep -oE 'cycle/v[0-9]+\.[0-9]+\.[0-9]+' \
                | sed 's|cycle/||' \
                | sed 's/^v//' \
                | sort -V \
                | tail -1) || pr_raw=""
            if [[ -n "$pr_raw" ]]; then
                found="v$pr_raw"
            fi
        fi
    fi
    if [[ -z "$found" ]]; then
        return 1
    fi
    printf 'candidate=%s\nsource_id=gitlog\nconfidence=medium\nevidence=git log の merge commits から最新 cycle/%s を検出\n' \
        "$found" "$found"
    return 0
}

# S3b CycleDirStrategy: .aidlc/cycles/v*/ から semver 最大値
# git toplevel 解決必須（pwd フォールバックなし。リポジトリ外実行時は候補なしを返す）
_cycle_resolver_strategy_cycledir() {
    if ! command -v git >/dev/null 2>&1; then
        return 1
    fi
    local toplevel rc
    toplevel=$(git rev-parse --show-toplevel 2>/dev/null)
    rc=$?
    # 非 git リポジトリ等の想定内エラー → 候補なし扱い（pwd フォールバックは行わない）
    if [[ $rc -ne 0 ]] || [[ -z "$toplevel" ]]; then
        return 1
    fi
    local cycles_dir="$toplevel/.aidlc/cycles"
    if [[ ! -d "$cycles_dir" ]]; then
        return 1
    fi
    local found
    found=$(ls -1 "$cycles_dir" 2>/dev/null \
        | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$' \
        | sed 's/^v//' \
        | sort -V \
        | tail -1) || found=""
    if [[ -z "$found" ]]; then
        return 1
    fi
    printf 'candidate=v%s\nsource_id=cycledir\nconfidence=low\nevidence=.aidlc/cycles/ ディレクトリから semver 最大値 v%s を検出\n' \
        "$found" "$found"
    return 0
}

# ─── 公開関数 ──────────────────────────────────────────────────────

# cycle_resolver_resolve <additional_context>
cycle_resolver_resolve() {
    local arg="${1:-}"
    local s1_out="" s2_out="" s3a_out="" s3b_out=""
    local rc

    # 各 Strategy 呼び出し: rc=0 候補確定 / rc=1 候補なし（想定内）
    # rc=2（fatal）は将来拡張用の予約 path。現行実装の Strategy はいずれも 0/1 のみ返す。
    # 将来 Strategy が rc=2 を返す変更が入った際に即座に伝播できるよう、ここで分岐を保持。
    s1_out=$(_cycle_resolver_strategy_arg "$arg" 2>/dev/null) ; rc=$?
    if [[ $rc -eq 2 ]]; then
        printf 'candidate=\nsource_id=fatal\nconfidence=none\nevidence=strategy_arg fatal\n' >&2
        return 2
    fi
    [[ $rc -ne 0 ]] && s1_out=""

    s2_out=$(_cycle_resolver_strategy_branch 2>/dev/null) ; rc=$?
    if [[ $rc -eq 2 ]]; then
        printf 'candidate=\nsource_id=fatal\nconfidence=none\nevidence=strategy_branch fatal\n' >&2
        return 2
    fi
    [[ $rc -ne 0 ]] && s2_out=""

    s3a_out=$(_cycle_resolver_strategy_gitlog 2>/dev/null) ; rc=$?
    if [[ $rc -eq 2 ]]; then
        printf 'candidate=\nsource_id=fatal\nconfidence=none\nevidence=strategy_gitlog fatal\n' >&2
        return 2
    fi
    [[ $rc -ne 0 ]] && s3a_out=""

    s3b_out=$(_cycle_resolver_strategy_cycledir 2>/dev/null) ; rc=$?
    if [[ $rc -eq 2 ]]; then
        printf 'candidate=\nsource_id=fatal\nconfidence=none\nevidence=strategy_cycledir fatal\n' >&2
        return 2
    fi
    [[ $rc -ne 0 ]] && s3b_out=""

    # 優先順位: S1 > S2 > S3a > S3b
    local primary=""
    local primary_source=""
    local primary_conf=""
    if [[ -n "$s1_out" ]]; then
        primary="$s1_out"
        primary_source="arg"
        primary_conf="high"
    elif [[ -n "$s2_out" ]]; then
        primary="$s2_out"
        primary_source="branch"
        primary_conf="high"
    elif [[ -n "$s3a_out" ]]; then
        primary="$s3a_out"
        primary_source="gitlog"
        primary_conf="medium"
    elif [[ -n "$s3b_out" ]]; then
        primary="$s3b_out"
        primary_source="cycledir"
        primary_conf="low"
    fi

    # 候補ゼロ → exit 1（呼出側で AskUserQuestion フォールバック）
    if [[ -z "$primary" ]]; then
        printf 'candidate=\nsource_id=none\nconfidence=none\nevidence=no candidate resolved\n'
        return 1
    fi

    # fail-safe: confidence != high かつ S3a/S3b 不一致なら conflict 通知
    # （呼出側で AskUserQuestion を行う / 本関数は通知のみ）
    if [[ "$primary_conf" != "high" && -n "$s3a_out" && -n "$s3b_out" ]]; then
        local s3a_cand s3b_cand
        s3a_cand=$(printf '%s\n' "$s3a_out" | grep '^candidate=' | cut -d= -f2)
        s3b_cand=$(printf '%s\n' "$s3b_out" | grep '^candidate=' | cut -d= -f2)
        if [[ "$s3a_cand" != "$s3b_cand" ]]; then
            printf '%s\n' "$primary"
            printf 'conflict=true\nconflict_s3a=%s\nconflict_s3b=%s\n' "$s3a_cand" "$s3b_cand"
            return 0
        fi
    fi

    printf '%s\n' "$primary"
    return 0
}
