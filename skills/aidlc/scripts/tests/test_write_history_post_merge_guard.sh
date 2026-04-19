#!/usr/bin/env bash
#
# test_write_history_post_merge_guard.sh - Unit 002 post-merge ガードのテスト
#
# Story 1.2（#583-B）の受け入れ基準および境界・異常系ケースを検証する。
# 12 ケース: TC_POST_MERGE_REJECT_EXPLICIT / TC_POST_MERGE_REJECT_FALLBACK /
#          TC_PRE_MERGE_GATE_READY_PASS / TC_PRE_MERGE_PASS / TC_INCEPTION_PASS /
#          TC_POST_MERGE_REJECT_DRY_RUN / TC_FALLBACK_GH_FAILURE_PASS /
#          TC_FALLBACK_PROGRESS_MISSING_PASS / TC_INVALID_OPERATIONS_STAGE /
#          TC_GH_CALLED_ONCE / TC_FALLBACK_MERGED_AT_NULL_PASS /
#          TC_FALLBACK_NUMBER_MISMATCH_PASS
#
set -uo pipefail

PASS=0
FAIL=0

assert_eq() {
    local label="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $label"
        ((PASS++))
    else
        echo "  FAIL: $label (expected='$expected', actual='$actual')"
        ((FAIL++))
    fi
}

assert_contains() {
    local label="$1" needle="$2" haystack="$3"
    if [[ "$haystack" == *"$needle"* ]]; then
        echo "  PASS: $label"
        ((PASS++))
    else
        echo "  FAIL: $label (needle='$needle' not found in actual='$haystack')"
        ((FAIL++))
    fi
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# SCRIPT_DIR = .../skills/aidlc/scripts/tests
# ../.. = .../skills/aidlc/scripts
# write-history.sh はその直上の scripts/ にある
WRITE_HISTORY="$(cd "$SCRIPT_DIR/.." && pwd)/write-history.sh"

echo "=== write-history.sh post-merge guard tests ==="

TMPDIR_BASE=$(mktemp -d)
trap 'rm -rf "$TMPDIR_BASE"' EXIT

# ---- fake gh 生成ヘルパー ----
# 受け取った argv を argv-log に追記し、以下の呼び出し契約を検証する:
#   $1 == "pr" AND $2 == "view" AND $3 =~ ^[1-9][0-9]*$ AND --json 引数が期待どおり
# 逸脱した呼び出しは exit 2（契約違反）で fail させ、security 回帰でも検知可能にする。
#
# $1 = fixture dir
# $2 = JSON を返すか（0=成功, 1=失敗）
# $3 = JSON 本体（成功時のみ使用）
setup_fake_gh() {
    local fixture_dir="$1"
    local ret_code="$2"
    local json="${3:-}"
    mkdir -p "$fixture_dir"
    local counter_file="$fixture_dir/gh-call-count"
    local argv_log="$fixture_dir/gh-argv-log"
    echo "0" > "$counter_file"
    : > "$argv_log"

    cat > "$fixture_dir/gh" <<EOS
#!/usr/bin/env bash
# fake gh for guard tests（引数契約検証付き）
n=\$(cat "$counter_file")
echo \$((n + 1)) > "$counter_file"

# 全 argv を 1 行に記録（監査用）
printf '%s\\0' "\$@" >> "$argv_log"

# 呼び出し契約チェック: gh pr view <pr_number> --json isDraft,state,mergedAt,number
if [[ "\${1:-}" != "pr" || "\${2:-}" != "view" ]]; then
    echo "fake gh: unexpected subcommand: \$1 \$2" >&2
    exit 2
fi
if ! [[ "\${3:-}" =~ ^[1-9][0-9]*\$ ]]; then
    echo "fake gh: pr_number must be positive integer, got: \${3:-}" >&2
    exit 2
fi
if [[ "\${4:-}" != "--json" ]]; then
    echo "fake gh: expected --json, got: \${4:-}" >&2
    exit 2
fi
if [[ "\${5:-}" != "isDraft,state,mergedAt,number" ]]; then
    echo "fake gh: unexpected --json fields: \${5:-}" >&2
    exit 2
fi

if [[ "$ret_code" != "0" ]]; then
    echo "gh: fake failure" >&2
    exit 1
fi
cat <<'JSON'
$json
JSON
exit 0
EOS
    chmod +x "$fixture_dir/gh"
}

# ---- progress.md フィクスチャヘルパー ----
# $1 = project root（AIDLC_PROJECT_ROOT として使用）
# $2 = cycle name
# $3 = progress.md 内容
setup_progress_md() {
    local project_root="$1"
    local cycle="$2"
    local content="$3"
    mkdir -p "$project_root/.aidlc/cycles/$cycle/operations"
    printf '%s\n' "$content" > "$project_root/.aidlc/cycles/$cycle/operations/progress.md"
}

# ---- fake プロジェクトルート作成 ----
# bootstrap.sh が AIDLC_CYCLES を AIDLC_PROJECT_ROOT/.aidlc/cycles に再設定するため、
# テストでは AIDLC_PROJECT_ROOT を一時ディレクトリに向けて偽のプロジェクト構造を用意する
make_fake_project() {
    local project_root="$1"
    mkdir -p "$project_root/.aidlc/cycles"
}

# ============================================================
# Story 1.2 受け入れ基準 5 ケース
# ============================================================

# ヘルパー: 各ケースごとに fake プロジェクト + fake gh のセットアップ
# $1 = case label（tc1 等）
# $2 = gh ret code（0=成功, 1=失敗）
# $3 = gh JSON 本体
# 出力: FIX（fake gh 配置先）, PROJ（プロジェクトルート）
prepare_case() {
    local label="$1"
    local ret_code="$2"
    local json="$3"
    FIX="$TMPDIR_BASE/$label/fix"
    PROJ="$TMPDIR_BASE/$label/proj"
    make_fake_project "$PROJ"
    setup_fake_gh "$FIX" "$ret_code" "$json"
}

# ヘルパー: write-history.sh 実行（stdout + stderr 結合版）
# 引数は write-history.sh に渡す引数
# stdout に combined output を出力し、終了コードを関数の戻り値として返す
# （pass 系テストで history: 出力の存在を確認するのに使用）
run_guard_test() {
    local out
    local ec=0
    out=$(PATH="$FIX:$PATH" AIDLC_PROJECT_ROOT="$PROJ" "$WRITE_HISTORY" "$@" 2>&1) || ec=$?
    printf '%s\n' "$out"
    return "$ec"
}

# ヘルパー: write-history.sh 実行（stdout / stderr 分離版）
# $1 = 結果格納ディレクトリ（tc1 等の FIX と分ける）
# 残り: write-history.sh 引数
# 副作用: $FIX/stdout と $FIX/stderr に各チャネルを別々に保存
# 戻り値: write-history.sh の終了コード
# （reject 系テストで stdout/stderr 両チャネルの契約を個別に検証するのに使用）
run_guard_test_split() {
    local stdout_file="$FIX/stdout"
    local stderr_file="$FIX/stderr"
    local ec=0
    PATH="$FIX:$PATH" AIDLC_PROJECT_ROOT="$PROJ" "$WRITE_HISTORY" "$@" \
        >"$stdout_file" 2>"$stderr_file" || ec=$?
    return "$ec"
}

echo ""
echo "--- TC_POST_MERGE_REJECT_EXPLICIT ---"
prepare_case tc1 0 '{"isDraft": false, "state": "MERGED", "mergedAt": "2026-04-19T12:00:00Z", "number": 581}'
ec=0
run_guard_test_split --cycle v2.3.6 --phase operations --operations-stage post-merge \
    --step "マージ完了" --content "誤呼び出しテスト" || ec=$?
assert_eq "exit code 3" "3" "$ec"
stdout_content=$(cat "$FIX/stdout")
stderr_content=$(cat "$FIX/stderr")
assert_contains "stdout に機械可読エラー" "error:post-merge-history-write-forbidden:explicit_stage" "$stdout_content"
assert_contains "stderr に機械可読エラー（両チャネル契約）" "error:post-merge-history-write-forbidden:explicit_stage" "$stderr_content"

echo ""
echo "--- TC_POST_MERGE_REJECT_FALLBACK ---"
prepare_case tc2 0 '{"isDraft": false, "state": "MERGED", "mergedAt": "2026-04-19T12:00:00Z", "number": 581}'
setup_progress_md "$PROJ" v2.3.6 "release_gate_ready=true
completion_gate_ready=true
pr_number=581"
ec=0
run_guard_test_split --cycle v2.3.6 --phase operations \
    --step "誤操作" --content "fallback テスト" || ec=$?
assert_eq "exit code 3" "3" "$ec"
stdout_content=$(cat "$FIX/stdout")
stderr_content=$(cat "$FIX/stderr")
assert_contains "stdout に fallback 理由" "error:post-merge-history-write-forbidden:fallback_merged_confirmed" "$stdout_content"
assert_contains "stderr に fallback 理由（両チャネル契約）" "error:post-merge-history-write-forbidden:fallback_merged_confirmed" "$stderr_content"

echo ""
echo "--- TC_PRE_MERGE_GATE_READY_PASS ---"
prepare_case tc3 0 '{"isDraft": false, "state": "OPEN", "mergedAt": null, "number": 581}'
setup_progress_md "$PROJ" v2.3.6 "completion_gate_ready=true
pr_number=581"
out=$(run_guard_test --cycle v2.3.6 --phase operations \
    --step "pre-merge 時のログ" --content "テスト")
ec=$?
assert_eq "exit code 0" "0" "$ec"
assert_contains "appended or created" "history:" "$out"

echo ""
echo "--- TC_PRE_MERGE_PASS ---"
prepare_case tc4 0 '{"isDraft": false, "state": "OPEN", "mergedAt": null, "number": 581}'
out=$(run_guard_test --cycle v2.3.6 --phase operations --operations-stage pre-merge \
    --step "pre-merge 明示" --content "テスト")
ec=$?
assert_eq "exit code 0" "0" "$ec"
assert_contains "history output" "history:" "$out"

echo ""
echo "--- TC_INCEPTION_PASS ---"
prepare_case tc5 0 '{"isDraft": false, "state": "MERGED", "mergedAt": "2026-04-19T12:00:00Z", "number": 581}'
out=$(run_guard_test --cycle v2.3.6 --phase inception \
    --step "Inception 通常" --content "テスト")
ec=$?
assert_eq "exit code 0 (inception unaffected)" "0" "$ec"
assert_contains "history output" "history:" "$out"

# ============================================================
# 境界・異常系ケース
# ============================================================

echo ""
echo "--- TC_POST_MERGE_REJECT_DRY_RUN ---"
prepare_case tc6 0 '{"isDraft": false, "state": "MERGED", "mergedAt": "2026-04-19T12:00:00Z", "number": 581}'
ec=0
run_guard_test_split --cycle v2.3.6 --phase operations --operations-stage post-merge \
    --step "dry-run テスト" --content "テスト" --dry-run || ec=$?
assert_eq "dry-run でも exit 3" "3" "$ec"
stdout_content=$(cat "$FIX/stdout")
stderr_content=$(cat "$FIX/stderr")
assert_contains "dry-run でも stdout に機械可読エラー" "error:post-merge-history-write-forbidden" "$stdout_content"
assert_contains "dry-run でも stderr に機械可読エラー" "error:post-merge-history-write-forbidden" "$stderr_content"
if [[ ! -e "$PROJ/.aidlc/cycles/v2.3.6/history/operations.md" ]]; then
    echo "  PASS: dry-run でファイル未生成"
    ((PASS++))
else
    echo "  FAIL: dry-run でファイルが生成された"
    ((FAIL++))
fi

echo ""
echo "--- TC_FALLBACK_GH_FAILURE_PASS ---"
prepare_case tc7 1 ""
setup_progress_md "$PROJ" v2.3.6 "completion_gate_ready=true
pr_number=581"
out=$(run_guard_test --cycle v2.3.6 --phase operations \
    --step "gh 失敗時" --content "テスト")
ec=$?
assert_eq "gh 失敗 → undecidable → appended (exit 0)" "0" "$ec"
assert_contains "history output" "history:" "$out"

echo ""
echo "--- TC_FALLBACK_PROGRESS_MISSING_PASS ---"
prepare_case tc8 0 '{"isDraft": false, "state": "MERGED", "mergedAt": "2026-04-19T12:00:00Z", "number": 581}'
out=$(run_guard_test --cycle v2.3.6 --phase operations \
    --step "progress 不在" --content "テスト")
ec=$?
assert_eq "progress 不在 → pass (exit 0)" "0" "$ec"

echo ""
echo "--- TC_INVALID_OPERATIONS_STAGE ---"
prepare_case tc9 0 ""
out=$(run_guard_test --cycle v2.3.6 --phase operations --operations-stage unknown-value \
    --step "不正 stage" --content "テスト")
ec=$?
assert_eq "未定義値 → exit 1" "1" "$ec"
assert_contains "invalid-operations-stage error" "invalid-operations-stage" "$out"

echo ""
echo "--- TC_GH_CALLED_ONCE ---"
prepare_case tc10 0 '{"isDraft": false, "state": "MERGED", "mergedAt": "2026-04-19T12:00:00Z", "number": 581}'
setup_progress_md "$PROJ" v2.3.6 "completion_gate_ready=true
pr_number=581"
run_guard_test --cycle v2.3.6 --phase operations \
    --step "gh 1 回テスト" --content "テスト" >/dev/null || true
gh_calls=$(cat "$FIX/gh-call-count")
assert_eq "gh は 1 回だけ呼ばれる" "1" "$gh_calls"

echo ""
echo "--- TC_FALLBACK_MERGED_AT_NULL_PASS ---"
prepare_case tc11 0 '{"isDraft": false, "state": "MERGED", "mergedAt": null, "number": 581}'
setup_progress_md "$PROJ" v2.3.6 "completion_gate_ready=true
pr_number=581"
out=$(run_guard_test --cycle v2.3.6 --phase operations \
    --step "mergedAt null" --content "テスト")
ec=$?
assert_eq "mergedAt=null → pass (exit 0)" "0" "$ec"

echo ""
echo "--- TC_FALLBACK_NUMBER_MISMATCH_PASS ---"
prepare_case tc12 0 '{"isDraft": false, "state": "MERGED", "mergedAt": "2026-04-19T12:00:00Z", "number": 999}'
setup_progress_md "$PROJ" v2.3.6 "completion_gate_ready=true
pr_number=581"
out=$(run_guard_test --cycle v2.3.6 --phase operations \
    --step "number 不一致" --content "テスト")
ec=$?
assert_eq "number 不一致 → pass (exit 0)" "0" "$ec"

# ============================================================
# §5.3.5 grammar インラインコメント対応（統合レビュー指摘 #1）
# ============================================================

echo ""
echo "--- TC_POST_MERGE_REJECT_WITH_INLINE_COMMENT ---"
# progress.md の値に inline comment が混在していても正しく読めて第二条件が成立すること
prepare_case tc13 0 '{"isDraft": false, "state": "MERGED", "mergedAt": "2026-04-19T12:00:00Z", "number": 581}'
setup_progress_md "$PROJ" v2.3.6 "completion_gate_ready=true   # マージ前完結
pr_number=581 # PR 番号"
ec=0
run_guard_test_split --cycle v2.3.6 --phase operations \
    --step "inline comment テスト" --content "テスト" || ec=$?
assert_eq "inline comment 付きでも exit 3（§5.3.5 準拠）" "3" "$ec"
stdout_content=$(cat "$FIX/stdout")
assert_contains "fallback reason in stdout" "fallback_merged_confirmed" "$stdout_content"

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
exit 0
