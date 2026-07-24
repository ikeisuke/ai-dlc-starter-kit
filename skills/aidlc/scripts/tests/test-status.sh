#!/usr/bin/env bash
#
# test-status.sh - status 出力仕様（steps/status.md）の構造・契約の静的検証
#
# status は実行スクリプトを持たない手順ベース仕様のため、steps/status.md の構造・契約と
# docs/v3/workflow.md §3.5 出力例とのフィールド整合を静的に検証する（ネットワーク非依存）:
#   (1) §3.5 全 7 フィールドがこの順序で記載 / (2) No active cycle 案内 exact string /
#   (3) §3.5 ブロックとのフィールド構造一致 / (4) launch prefix /aidlc 統一 /
#   (5) frontmatter 委譲（work-item-status.sh status:<value> / fm_extract_block / fm_scalar）/
#   (6) 状態非変更（コマンド位置の state-write.sh なし）/ (7) Step 0 分離（不在/読取失敗/cycle dir 不在）/
#   (8) data-model §5 SoT 参照 / (9) stale 注記なし（skeleton / Phase 3）
#
# 外部テストフレームワークに依存しない自己完結型ハーネス（jq のみ前提 / 既存テストと同方式）。
#
# Usage: test-status.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（jq 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"     # skills/aidlc/scripts
V3_DIR="$(cd "$SKILL_DIR/.." && pwd)"         # skills/aidlc
REPO_ROOT="$(cd "$V3_DIR/../.." && pwd)"      # リポジトリルート
readonly SCRIPT_DIR SKILL_DIR V3_DIR REPO_ROOT
readonly STATUS_MD="$V3_DIR/steps/status.md"
readonly WORKFLOW_MD="$REPO_ROOT/docs/v3/workflow.md"

if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not found (前提不備)" >&2
    exit 2
fi

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); echo "  ok   : $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL : $1"; }

# grep_q <file> <fixed-string> : 固定文字列の存在確認
grep_q() { grep -qF -- "$2" "$1"; }

echo "== 静的検査（bash -n / shellcheck） =="
if bash -n "$SCRIPT_DIR/test-status.sh" 2>/dev/null; then pass "bash -n: test-status.sh"; else fail "bash -n: test-status.sh"; fi
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck "$SCRIPT_DIR/test-status.sh" >/dev/null 2>&1; then pass "shellcheck: test-status.sh"; else fail "shellcheck: test-status.sh"; fi
else
    echo "  skip : shellcheck 未導入のため静的検査をスキップ"
fi

echo "== 成果物の存在 =="
for f in "$STATUS_MD" "$WORKFLOW_MD"; do
    if [[ -f "$f" ]]; then pass "存在: ${f#"$REPO_ROOT"/}"; else fail "不在: ${f#"$REPO_ROOT"/}"; fi
done

echo "== §3.5 全 7 フィールドが status.md に記載 =="
FIELDS=("Cycle" "Phase" "Current work item" "Completed" "Blocked" "Remaining" "Suggested command")
for fld in "${FIELDS[@]}"; do
    if grep_q "$STATUS_MD" "$fld"; then pass "フィールド記載: $fld"; else fail "フィールド欠落: $fld"; fi
done

echo "== フィールド順序（active cycle 出力例ブロック内で §3.5 順） =="
# 'Cycle: v3.0.0' で始まる active cycle 出力例ブロックを抽出し、その中で 7 フィールドの順序を検証する
# （doc 全体ではブロック外の見出し・表・Step 0 にもフィールド名が現れるため、ブロックに限定する）。
block="$(awk '/^Cycle: v3\.0\.0/{f=1} f{print} f&&/^Suggested command:/{exit}' "$STATUS_MD")"
order_ok=1
prev=0
for fld in "${FIELDS[@]}"; do
    ln="$(printf '%s\n' "$block" | grep -nF "$fld:" | head -n1 | cut -d: -f1)"
    if [[ -z "$ln" || "$ln" -lt "$prev" ]]; then order_ok=0; fi
    prev="$ln"
done
if [[ "$order_ok" -eq 1 ]]; then pass "7 フィールドが出力例ブロック内で §3.5 順序"; else fail "出力例ブロックのフィールド順序が §3.5 と不一致"; fi

echo "== No active cycle 案内 exact string =="
if grep_q "$STATUS_MD" "No active cycle found."; then pass "No active cycle found. 記載"; else fail "No active cycle found. 欠落"; fi
if grep_q "$STATUS_MD" "Suggested command: /aidlc define"; then pass "define 案内 exact string"; else fail "define 案内 exact string 欠落"; fi

echo "== §3.5 出力例ブロックのフィールド列 exact 比較（workflow.md ↔ status.md） =="
# active 出力例ブロック（Cycle: 〜 Suggested command:）から「ラベル:」列を順序付きで抽出する。
# フィールドラベルは launch prefix 非依存のため、ラベル列の exact 一致で
# フィールド構造・順序を検証する（指摘#1）。
extract_field_labels() {
    awk '/^Cycle:/{f=1} f{ if (match($0, /^[A-Za-z][^:]*:/)) print substr($0, RSTART, RLENGTH) } f&&/^Suggested command:/{exit}' "$1"
}
wf_labels="$(extract_field_labels "$WORKFLOW_MD")"
st_labels="$(extract_field_labels "$STATUS_MD")"
expected_labels="$(printf 'Cycle:\nPhase:\nCurrent work item:\nCompleted:\nBlocked:\nRemaining:\nSuggested command:')"
if [[ "$wf_labels" == "$expected_labels" ]]; then pass "workflow.md §3.5 のフィールド列が 7 フィールド順"; else fail "workflow.md §3.5 のフィールド列が期待と不一致"; fi
if [[ "$st_labels" == "$wf_labels" ]]; then pass "status.md の出力例フィールド列が §3.5 と exact 一致（順序含む）"; else fail "status.md の出力例フィールド列が §3.5 と不一致"; fi
if grep_q "$WORKFLOW_MD" "No active cycle found."; then pass "workflow.md §3.5 も No active cycle found. を持つ"; else fail "workflow.md §3.5 の No active cycle 不一致"; fi

echo "== launch prefix /aidlc 統一（Suggested command） =="
# status.md の Suggested command 行はすべて /aidlc を使う（旧 prefix /aidlc-v3 を残さない）。
sugg_bad="$(grep -F "Suggested command:" "$STATUS_MD" | grep -cF "/aidlc-v3" || true)"
if [[ "$sugg_bad" -eq 0 ]]; then pass "Suggested command はすべて /aidlc（旧 /aidlc-v3 残存なし）"; else fail "Suggested command に旧 /aidlc-v3 が残存（${sugg_bad} 件）"; fi

echo "== frontmatter 安全境界委譲 =="
for c in "work-item-status.sh --read" "status:<value>" "fm_extract_block" "fm_scalar"; do
    if grep_q "$STATUS_MD" "$c"; then pass "委譲参照: $c"; else fail "委譲参照欠落: $c"; fi
done
# status:<value> から <value> のみ使う契約（指摘#2）。
if grep_q "$STATUS_MD" "を剥がした"; then pass "status: prefix を剥がした <value> のみ使用契約"; else fail "<value> のみ使用契約欠落"; fi
# frontmatter 生パース禁止の明記 + 存在しない fm_size/fm_risk を前提にしていないこと（指摘#2）。
if grep_q "$STATUS_MD" "直接 grep/sed/awk でパースしない"; then pass "frontmatter 生パース禁止の明記"; else fail "生パース禁止の明記欠落"; fi
if grep_q "$STATUS_MD" "は実在しないため使わない"; then pass "fm_size/fm_risk は実在しない旨の注意書きあり（誤用防止）"; else fail "fm_size/fm_risk 非実在の注意書き欠落"; fi

echo "== 状態非変更（変更系手順の混入なし / 指摘#3） =="
if grep -qE '^[[:space:]]*(scripts/)?state-write\.sh' "$STATUS_MD"; then
    fail "state-write.sh のコマンド呼び出しが存在する（status は読み取り専用のはず）"
else
    pass "state-write.sh のコマンド呼び出し不在"
fi
# 他の変更系スクリプトのコマンド位置呼び出しが無いこと。
if grep -qE '^[[:space:]]*(scripts/)?state-init\.sh' "$STATUS_MD"; then
    fail "state-init.sh のコマンド呼び出しが存在する（変更系）"
else
    pass "state-init.sh のコマンド呼び出し不在"
fi
# work-item-status.sh は --read のみ許容（write mode = --set 等が無いこと）。
if grep -qE 'work-item-status\.sh[^\n]*--(set|write|transition)' "$STATUS_MD"; then
    fail "work-item-status.sh の write mode（--set/--write/--transition）が混入している"
else
    pass "work-item-status.sh は --read のみ（write mode なし）"
fi

echo "== Step 0 分離（不在 / 読取失敗 / cycle dir 不在） =="
if grep_q "$STATUS_MD" "state read error"; then pass "state read error 診断案内（読取失敗を No active cycle と分離）"; else fail "state read error 案内欠落"; fi
if grep_q "$STATUS_MD" "state-validate.sh"; then pass "schema 検証委譲（state-validate.sh）"; else fail "schema 検証委譲欠落"; fi
if grep_q "$STATUS_MD" "Suggested command: /aidlc doctor"; then pass "読取失敗時 doctor 案内"; else fail "doctor 案内欠落"; fi
if grep_q "$STATUS_MD" ".aidlc/cycles/<cycle>"; then pass "cycle dir 存在チェック記載"; else fail "cycle dir 存在チェック欠落"; fi

echo "== data-model §5 SoT 参照 =="
if grep_q "$STATUS_MD" "data-model.md"; then pass "data-model.md 参照（フェーズ導出 SoT）"; else fail "data-model.md 参照欠落"; fi

echo "== stale 注記なし =="
if grep_q "$STATUS_MD" "skeleton"; then fail "stale: 'skeleton' が残存"; else pass "stale 'skeleton' なし"; fi
if grep_q "$STATUS_MD" "実行実装は Phase 3"; then fail "stale: '実行実装は Phase 3' が残存"; else pass "stale '実行実装は Phase 3' なし"; fi

echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
