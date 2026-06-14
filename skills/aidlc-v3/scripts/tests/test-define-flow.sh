#!/usr/bin/env bash
#
# test-define-flow.sh - state-init.sh 単体 + define Step 4 実行フローの自己完結テスト
#
# 外部テストフレームワークに依存しない（jq / git のみ前提）。v2 の `.aidlc/` を一切
# 触らず、隔離サンドボックス（mktemp -d）内で define Step 4 の決定的部分を検証する。
#
# 検証対象:
#   - state-init.sh: 正常系 / create-only ガード / current_cycle 入力健全性 /
#     race 代替（validate 後 target 先行作成）/ 終了コード 0/1/2
#   - define Step 4 e2e: 成果物生成 + state-init + work item 検証ゲート + state-write +
#     branch/commit、および同一値整合（dir名 = current_cycle = branch suffix）
#   - work item 検証ゲート: 不正 frontmatter では define_completed を立てない
#
# Usage: test-define-flow.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（jq / git 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SCRIPT_DIR SCRIPTS_DIR
readonly INIT="$SCRIPTS_DIR/state-init.sh"
readonly WRITE="$SCRIPTS_DIR/state-write.sh"
readonly VALIDATE="$SCRIPTS_DIR/state-validate.sh"
readonly READ="$SCRIPTS_DIR/state-read.sh"
readonly WIVALIDATE="$SCRIPTS_DIR/work-item-validate.sh"

if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not found (前提不備)" >&2
    exit 2
fi
if ! command -v git >/dev/null 2>&1; then
    echo "SKIP: git not found (前提不備)" >&2
    exit 2
fi

PASS=0
FAIL=0
TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# assert_rc <期待rc> <説明> -- <コマンド...>
assert_rc() {
    local expected="$1"; shift
    local desc="$1"; shift
    [[ "$1" == "--" ]] && shift
    "$@" >/dev/null 2>&1
    local rc=$?
    if [[ "$rc" == "$expected" ]]; then
        PASS=$((PASS + 1)); echo "  ok   : $desc (rc=$rc)"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc (expected rc=$expected, got rc=$rc)"
    fi
}

# assert_out <期待文字列> <説明> -- <コマンド...>
assert_out() {
    local expected="$1"; shift
    local desc="$1"; shift
    [[ "$1" == "--" ]] && shift
    local out
    out="$("$@" 2>/dev/null)"
    if [[ "$out" == "$expected" ]]; then
        PASS=$((PASS + 1)); echo "  ok   : $desc (out=$out)"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc (expected out='$expected', got out='$out')"
    fi
}

# assert_cond <説明> <条件式の真偽（0/1）>
assert_cond() {
    local desc="$1"; local rc="$2"
    if [[ "$rc" == "0" ]]; then
        PASS=$((PASS + 1)); echo "  ok   : $desc"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc"
    fi
}

# assert_gate_pass <説明> <work-items dir>: ゲート通過を期待
# define Step 4-2 と同条件（expected_status=pending）で実体スクリプトを呼ぶ。
assert_gate_pass() {
    local desc="$1" dir="$2"
    if "$WIVALIDATE" "$dir" pending >/dev/null 2>&1; then
        PASS=$((PASS + 1)); echo "  ok   : $desc"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc (gate failed unexpectedly)"
    fi
}

# assert_gate_fail <説明> <work-items dir>: ゲート失敗（exit 非0）を期待
assert_gate_fail() {
    local desc="$1" dir="$2"
    if "$WIVALIDATE" "$dir" pending >/dev/null 2>&1; then
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc (gate passed unexpectedly)"
    else
        PASS=$((PASS + 1)); echo "  ok   : $desc"
    fi
}

# ---- define Step 4 の決定的レシピ（非対話部分のドライバ） ----
# define.md Step 4-1（cycle dir + journal 生成）〜 4-5（branch + commit）を実行する。
# 承認済み Intent / Work Item の内容のみ呼び出し側が事前配置（Step 2/3 の人間承認出力）。
# journal 生成・dir 作成・branch 作成・state 操作・commit は本ドライバが実行する。
# 成功時 0 / 検証ゲート失敗時 1。state-init / state-write / branch / commit はゲート通過時のみ。
run_define_step4() {
    local repo="$1" cycle="$2" cur
    (
        cd "$repo" || exit 9
        # 4-1 cycle ディレクトリ（承認済み intent/work-items は配置済み）
        mkdir -p ".aidlc/cycles/$cycle/work-items"
        # 4-1.4 journal 生成（テンプレート相当 / 日付は決定的に固定）
        printf '# Journal: %s\n\n## 2026-06-13\n\n- define completed: intent and work items created\n' \
            "$cycle" > ".aidlc/cycles/$cycle/journal.md"
        # 4-2 検証ゲート（define.md Step 4-2 の実体スクリプトを呼ぶ / expected_status=pending）
        "$WIVALIDATE" ".aidlc/cycles/$cycle/work-items" pending >/dev/null 2>&1 || exit 1
        # 4-3 初期 state.json
        AIDLC_STATE_NOW="2026-06-13T00:00:00Z" "$INIT" "$cycle" ".aidlc/state.json" >/dev/null || exit 2
        # 4-4 define 完了マーク
        AIDLC_STATE_NOW="2026-06-13T00:00:01Z" "$WRITE" define_completed true ".aidlc/state.json" >/dev/null || exit 2
        # 4-5 branch 作成（define.md: 既に対象ブランチ上なら skip）+ commit
        cur="$(git rev-parse --abbrev-ref HEAD)"
        if [[ "$cur" != "cycle/$cycle" ]]; then
            git checkout -q -b "cycle/$cycle" || exit 3
        fi
        git add -A >/dev/null 2>&1
        git -c user.email=t@example.com -c user.name=t commit -q -m "define: $cycle 初期化" || exit 3
    )
}

# 隔離サンドボックス git リポジトリを作る（cycle ブランチは作らない / Step 4-5 で作成させる）。
# 第 3 引数 yes で事前に cycle ブランチを作成（既存ブランチ skip 経路の検証用）。
make_sandbox() {
    local repo="$1" cycle="$2" precreate="${3:-no}"
    mkdir -p "$repo"
    (
        cd "$repo" || exit 9
        git init -q
        git config user.email t@example.com
        git config user.name t
        mkdir -p .aidlc
        printf '%s\n' '# stub config' > .aidlc/config.toml
        git add -A >/dev/null 2>&1
        git -c user.email=t@example.com -c user.name=t commit -q -m "init" >/dev/null 2>&1
        if [[ "$precreate" == "yes" ]]; then
            git checkout -q -b "cycle/$cycle"
        fi
    )
}

# 有効な work item フィクスチャを置く
put_valid_work_item() {
    local repo="$1" cycle="$2" id="$3" slug="$4" deps="$5"
    local f="$repo/.aidlc/cycles/$cycle/work-items/${id}-${slug}.md"
    mkdir -p "$(dirname "$f")"
    cat > "$f" <<EOF
---
id: "$id"
status: pending
size: tiny
risk: low
assigned: null
dependencies: [$deps]
---

# Work Item $id: $slug

## Goal

example goal.

## Scope

- 含むもの: x
- 含まないもの: y

## Acceptance Criteria

- [ ] cond 1

## Traceability

- Intent refs: scope:example
- Acceptance refs: AC-001
- Verification: manual
- Release note required: no

## Size / Risk

- Size: tiny
- Risk: low
- Reason: trivial

## Dependencies

- none
EOF
}

# 承認済み Intent（Step 2 の人間承認出力）を入力フィクスチャとして配置する。
# journal は Step 4-1 の生成物のため run_define_step4 が作る（ここでは置かない）。
put_approved_intent() {
    local repo="$1" cycle="$2"
    mkdir -p "$repo/.aidlc/cycles/$cycle"
    printf '# Intent: %s\n' "$cycle" > "$repo/.aidlc/cycles/$cycle/intent.md"
}

echo "== 静的検査（bash -n / shellcheck） =="
assert_rc 0 "bash -n: state-init.sh" -- bash -n "$INIT"
assert_rc 0 "bash -n: test-define-flow.sh" -- bash -n "$SCRIPT_DIR/test-define-flow.sh"
if command -v shellcheck >/dev/null 2>&1; then
    assert_rc 0 "shellcheck: state-init.sh（重大警告なし）" -- shellcheck "$INIT"
else
    echo "  skip : shellcheck 未導入のため静的検査をスキップ"
fi

echo "== state-init.sh 単体 =="
si="$TMPROOT/si"; mkdir -p "$si"
assert_out "status:initialized" "正常生成は status:initialized" -- \
    env AIDLC_STATE_NOW="2026-06-13T00:00:00Z" "$INIT" v3.0.0 "$si/state.json"
assert_rc 0 "生成された state は valid" -- "$VALIDATE" "$si/state.json"
assert_out "3.0" "schema_version=3.0" -- "$READ" schema_version "$si/state.json"
assert_out "v3.0.0" "current_cycle 反映" -- "$READ" current_cycle "$si/state.json"
assert_out "false" "define_completed 初期 false" -- "$READ" define_completed "$si/state.json"
assert_out "null" "release.pr_number 初期 null" -- "$READ" release.pr_number "$si/state.json"
assert_out "2026-06-13T00:00:00Z" "updated_at は AIDLC_STATE_NOW" -- "$READ" updated_at "$si/state.json"
# ハイフン入り cycle（v3.0.0-alpha.3）も許容
assert_out "status:initialized" "ハイフン入り cycle 許容" -- \
    env AIDLC_STATE_NOW="2026-06-13T00:00:00Z" "$INIT" v3.0.0-alpha.3 "$si/state-alpha.json"

echo "== state-init.sh 異常系（終了コード規約） =="
assert_rc 1 "引数なしは exit 1" -- "$INIT"
assert_rc 1 "空 current_cycle は exit 1" -- "$INIT" "" "$si/empty.json"
assert_rc 1 "slash 含み current_cycle は exit 1" -- "$INIT" "a/b" "$si/slash.json"
assert_rc 1 "空白含み current_cycle は exit 1" -- "$INIT" "a b" "$si/space.json"
# create-only: 既存ファイルは exit 1
existing="$si/exists.json"; printf '%s' '{}' > "$existing"
assert_rc 1 "既存ファイルへの生成は exit 1（create-only）" -- "$INIT" v3.0.0 "$existing"
assert_out "{}" "create-only 違反時に既存ファイルが保持される" -- cat "$existing"
# race 代替: validate を通った後に target が存在しても上書きしない（早期 + ln 二重ガード）
race="$si/race.json"; printf '%s' 'PRE-EXISTING' > "$race"
assert_rc 1 "race 代替: target 先行作成済みは exit 1" -- "$INIT" v3.0.0 "$race"
assert_out "PRE-EXISTING" "race 代替: 既存内容が保持される（mv で上書きされない）" -- cat "$race"
# 依存 state-validate.sh の不備（実行不可 / 不在）→ exit 2
# 注: state-init.sh は SCRIPT_DIR 解決に外部コマンド dirname を使うため、PATH="" による
# jq 不在テストは不適（jq チェック前に dirname が失敗する）。jq 不在の振る舞いは
# test-state-scripts.sh の state-validate / state-read で担保済み。ここでは依存不備の exit 2 を検証する。
depdir="$si/dep"; mkdir -p "$depdir"
cp "$INIT" "$VALIDATE" "$depdir/"
chmod +x "$depdir/state-init.sh" "$depdir/state-validate.sh"
chmod 000 "$depdir/state-validate.sh"
assert_rc 2 "依存 state-validate.sh 実行不可は exit 2" -- "$depdir/state-init.sh" v3.0.0 "$depdir/s.json"
chmod 644 "$depdir/state-validate.sh"; rm -f "$depdir/state-validate.sh"
assert_rc 2 "依存 state-validate.sh 不在は exit 2" -- "$depdir/state-init.sh" v3.0.0 "$depdir/s2.json"

echo "== work item 検証ゲート（work-item-validate.sh） =="
assert_rc 0 "bash -n: work-item-validate.sh" -- bash -n "$WIVALIDATE"
if command -v shellcheck >/dev/null 2>&1; then
    assert_rc 0 "shellcheck: work-item-validate.sh（重大警告なし）" -- shellcheck "$WIVALIDATE"
fi
gate="$TMPROOT/gate/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$gate"
# 正常: pending + 全キー + 全セクション
put_valid_work_item "$TMPROOT/gate" v3.0.0 001 example ""
assert_gate_pass "正常 work item はゲート通過" "$gate"
# 依存（実在）
put_valid_work_item "$TMPROOT/gate" v3.0.0 002 second '"001"'
assert_gate_pass "実在依存はゲート通過" "$gate"
# 不正: status が pending でない
sed 's/^status: pending/status: in_progress/' "$gate/001-example.md" > "$gate/001-example.md.tmp" \
    && mv "$gate/001-example.md.tmp" "$gate/001-example.md"
assert_gate_fail "status!=pending はゲート失敗" "$gate"
# enum 不正（size）
bad="$TMPROOT/gate2/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$bad"
put_valid_work_item "$TMPROOT/gate2" v3.0.0 001 example ""
sed 's/^size: tiny/size: huge/' "$bad/001-example.md" > "$bad/001-example.md.tmp" \
    && mv "$bad/001-example.md.tmp" "$bad/001-example.md"
assert_gate_fail "size enum 逸脱はゲート失敗" "$bad"
# 本文セクション欠落
sec="$TMPROOT/gate3/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$sec"
put_valid_work_item "$TMPROOT/gate3" v3.0.0 001 example ""
grep -v '^## Traceability$' "$sec/001-example.md" > "$sec/001-example.md.tmp" \
    && mv "$sec/001-example.md.tmp" "$sec/001-example.md"
assert_gate_fail "必須セクション欠落はゲート失敗" "$sec"
# 存在しない依存 ID
dep="$TMPROOT/gate4/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$dep"
put_valid_work_item "$TMPROOT/gate4" v3.0.0 001 example '"999"'
assert_gate_fail "存在しない依存 ID はゲート失敗" "$dep"
# inline コメント付き enum 値（テンプレート由来）は通過する
cmt="$TMPROOT/gate5/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$cmt"
put_valid_work_item "$TMPROOT/gate5" v3.0.0 001 example ""
sed -e 's/^status: pending/status: pending        # pending | in_progress/' \
    -e 's/^size: tiny/size: tiny           # tiny | normal | risky/' \
    -e 's/^risk: low/risk: low            # low | medium | high/' \
    "$cmt/001-example.md" > "$cmt/001-example.md.tmp" && mv "$cmt/001-example.md.tmp" "$cmt/001-example.md"
assert_gate_pass "inline コメント付き enum 値は通過（テンプレート互換）" "$cmt"
# prefix 偽陽性: status: pendingx / pending-foo / pending123 は失敗（値トークン完全一致 + 後続限定）
for badval in pendingx pending-foo pending123; do
    fp="$TMPROOT/gate_fp_${badval}/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$fp"
    put_valid_work_item "$TMPROOT/gate_fp_${badval}" v3.0.0 001 example ""
    sed "s/^status: pending/status: ${badval}/" "$fp/001-example.md" > "$fp/001-example.md.tmp" \
        && mv "$fp/001-example.md.tmp" "$fp/001-example.md"
    assert_gate_fail "prefix 偽陽性 status: ${badval} は失敗" "$fp"
done
# 片側引用符スカラー（status/size/risk/id）はゲート失敗（read_scalar の balanced-quote 統一）
# 開き引用符のみ
oq_idx=0
for spec in 'status: pending|status: "pending' 'size: tiny|size: "tiny' 'risk: low|risk: "low' 'id: "001"|id: "001'; do
    oq_idx=$((oq_idx + 1))
    from="${spec%%|*}"; to="${spec#*|}"
    oqroot="$TMPROOT/gate_openquote_${oq_idx}"
    oq="$oqroot/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$oq"
    put_valid_work_item "$oqroot" v3.0.0 001 example ""
    sed "s|^${from}\$|${to}|" "$oq/001-example.md" > "$oq/001-example.md.tmp" \
        && mv "$oq/001-example.md.tmp" "$oq/001-example.md"
    assert_gate_fail "片側引用符（開き）[${to}] はゲート失敗" "$oq"
done
# 閉じ引用符のみ
cq_idx=0
for spec in 'status: pending|status: pending"' 'size: tiny|size: tiny"' 'risk: low|risk: low"' 'id: "001"|id: 001"'; do
    cq_idx=$((cq_idx + 1))
    from="${spec%%|*}"; to="${spec#*|}"
    cqroot="$TMPROOT/gate_closequote_${cq_idx}"
    cq="$cqroot/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$cq"
    put_valid_work_item "$cqroot" v3.0.0 001 example ""
    sed "s|^${from}\$|${to}|" "$cq/001-example.md" > "$cq/001-example.md.tmp" \
        && mv "$cq/001-example.md.tmp" "$cq/001-example.md"
    assert_gate_fail "片側引用符（閉じ）[${to}] はゲート失敗" "$cq"
done
# 両端引用符付きスカラー（status/id）は通過（balanced quote 許容）
bq="$TMPROOT/gate_bothquote/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$bq"
put_valid_work_item "$TMPROOT/gate_bothquote" v3.0.0 001 example ""
sed -e 's/^status: pending/status: "pending"/' "$bq/001-example.md" > "$bq/001-example.md.tmp" \
    && mv "$bq/001-example.md.tmp" "$bq/001-example.md"
assert_gate_pass "両端引用符 status: \"pending\" は通過" "$bq"
# 必須キー欠落（assigned 行を除去）
mk="$TMPROOT/gate_misskey/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$mk"
put_valid_work_item "$TMPROOT/gate_misskey" v3.0.0 001 example ""
grep -v '^assigned:' "$mk/001-example.md" > "$mk/001-example.md.tmp" \
    && mv "$mk/001-example.md.tmp" "$mk/001-example.md"
assert_gate_fail "必須キー（assigned）欠落はゲート失敗" "$mk"
# risk enum 逸脱
rk="$TMPROOT/gate_riskenum/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$rk"
put_valid_work_item "$TMPROOT/gate_riskenum" v3.0.0 001 example ""
sed 's/^risk: low/risk: extreme/' "$rk/001-example.md" > "$rk/001-example.md.tmp" \
    && mv "$rk/001-example.md.tmp" "$rk/001-example.md"
assert_gate_fail "risk enum 逸脱はゲート失敗" "$rk"
# id とファイル名不整合（frontmatter id を 999 に書き換え / ファイル名 prefix は 001）
mm="$TMPROOT/gate_idmismatch/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$mm"
put_valid_work_item "$TMPROOT/gate_idmismatch" v3.0.0 001 example ""
sed 's/^id: "001"/id: "999"/' "$mm/001-example.md" > "$mm/001-example.md.tmp" \
    && mv "$mm/001-example.md.tmp" "$mm/001-example.md"
assert_gate_fail "id とファイル名 prefix 不整合はゲート失敗" "$mm"
# dependencies 非配列（dependencies: 999）はゲート失敗（§4.1 array 型）
dna="$TMPROOT/gate_depnonarray/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$dna"
put_valid_work_item "$TMPROOT/gate_depnonarray" v3.0.0 001 example ""
sed 's/^dependencies: \[\]/dependencies: 999/' "$dna/001-example.md" > "$dna/001-example.md.tmp" \
    && mv "$dna/001-example.md.tmp" "$dna/001-example.md"
assert_gate_fail "dependencies 非配列（999）はゲート失敗" "$dna"
# dependencies 壊れた配列（閉じ括弧なし）はゲート失敗
dba="$TMPROOT/gate_depbroken/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$dba"
put_valid_work_item "$TMPROOT/gate_depbroken" v3.0.0 001 example ""
sed 's/^dependencies: \[\]/dependencies: [001/' "$dba/001-example.md" > "$dba/001-example.md.tmp" \
    && mv "$dba/001-example.md.tmp" "$dba/001-example.md"
assert_gate_fail "dependencies 壊れた配列（閉じ括弧なし）はゲート失敗" "$dba"
# dependencies 配列要素の区切り構文検証（実在 ID を前提に malformed 区切りを弾く）
# 正常: カンマ区切り [001, 002] は通過
dcsv="$TMPROOT/gate_depcsv/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$dcsv"
put_valid_work_item "$TMPROOT/gate_depcsv" v3.0.0 001 first ""
put_valid_work_item "$TMPROOT/gate_depcsv" v3.0.0 002 second ""
put_valid_work_item "$TMPROOT/gate_depcsv" v3.0.0 003 third '"001", "002"'
assert_gate_pass "カンマ区切り依存 [001, 002] は通過" "$dcsv"
# 不正: ハイフン結合 [001-002]
dhyp="$TMPROOT/gate_dephyphen/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$dhyp"
put_valid_work_item "$TMPROOT/gate_dephyphen" v3.0.0 001 first ""
put_valid_work_item "$TMPROOT/gate_dephyphen" v3.0.0 002 second ""
put_valid_work_item "$TMPROOT/gate_dephyphen" v3.0.0 003 third ""
sed 's/^dependencies: \[\]/dependencies: [001-002]/' "$dhyp/003-third.md" > "$dhyp/003-third.md.tmp" \
    && mv "$dhyp/003-third.md.tmp" "$dhyp/003-third.md"
assert_gate_fail "ハイフン結合依存 [001-002] はゲート失敗" "$dhyp"
# 不正: 空白区切り [001 002]
dspc="$TMPROOT/gate_depspace/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$dspc"
put_valid_work_item "$TMPROOT/gate_depspace" v3.0.0 001 first ""
put_valid_work_item "$TMPROOT/gate_depspace" v3.0.0 002 second ""
put_valid_work_item "$TMPROOT/gate_depspace" v3.0.0 003 third ""
sed 's/^dependencies: \[\]/dependencies: [001 002]/' "$dspc/003-third.md" > "$dspc/003-third.md.tmp" \
    && mv "$dspc/003-third.md.tmp" "$dspc/003-third.md"
assert_gate_fail "空白区切り依存 [001 002] はゲート失敗" "$dspc"
# 不正: 片側のみ引用符 ["001] / [001"]
dq_idx=0
for badq in '["001]' '[001"]'; do
    dq_idx=$((dq_idx + 1))
    dqroot="$TMPROOT/gate_depquote_${dq_idx}"
    dq="$dqroot/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$dq"
    put_valid_work_item "$dqroot" v3.0.0 001 first ""
    put_valid_work_item "$dqroot" v3.0.0 003 third ""
    # 003 の dependencies を片側引用符に書き換え（sed 区切りは | を使い " の干渉を避ける）
    sed "s|^dependencies: \[\]|dependencies: ${badq}|" "$dq/003-third.md" > "$dq/003-third.md.tmp" \
        && mv "$dq/003-third.md.tmp" "$dq/003-third.md"
    assert_gate_fail "片側引用符依存 ${badq} はゲート失敗" "$dq"
done
# assigned 不正型（配列）はゲート失敗（§4.1 string or null）
ainv="$TMPROOT/gate_assignedarr/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$ainv"
put_valid_work_item "$TMPROOT/gate_assignedarr" v3.0.0 001 example ""
sed 's/^assigned: null/assigned: [foo]/' "$ainv/001-example.md" > "$ainv/001-example.md.tmp" \
    && mv "$ainv/001-example.md.tmp" "$ainv/001-example.md"
assert_gate_fail "assigned 不正型（配列）はゲート失敗" "$ainv"
# assigned 文字列値（quoted）は通過（§4.1 string 許容）
astr="$TMPROOT/gate_assignedstr/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$astr"
put_valid_work_item "$TMPROOT/gate_assignedstr" v3.0.0 001 example ""
sed 's/^assigned: null/assigned: "alice"/' "$astr/001-example.md" > "$astr/001-example.md.tmp" \
    && mv "$astr/001-example.md.tmp" "$astr/001-example.md"
assert_gate_pass "assigned 文字列値（\"alice\"）は通過" "$astr"
# 重複 frontmatter キー（status を 2 回指定）はゲート失敗（presence-only → 曖昧解決防止 / codex premerge P2）
dupk="$TMPROOT/gate_dupkey/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$dupk"
put_valid_work_item "$TMPROOT/gate_dupkey" v3.0.0 001 example ""
# status 行の直後に status: done を挿入（先頭一致では pending、reader は曖昧拒否）
awk '{print} /^status: pending/ && !done {print "status: done"; done=1}' \
    "$dupk/001-example.md" > "$dupk/001-example.md.tmp" && mv "$dupk/001-example.md.tmp" "$dupk/001-example.md"
assert_gate_fail "重複 frontmatter キー（status 2 回）はゲート失敗" "$dupk"
# 重複 work item ID（001-a.md / 001-b.md が同一 id prefix）はゲート失敗（依存解決の非決定性防止 / codex premerge P2）
dupid="$TMPROOT/gate_dupid/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$dupid"
put_valid_work_item "$TMPROOT/gate_dupid" v3.0.0 001 alpha ""
put_valid_work_item "$TMPROOT/gate_dupid" v3.0.0 001 beta ""
assert_gate_fail "重複 work item ID（001 が複数ファイル）はゲート失敗" "$dupid"
# 本文に水平線 `---` を含んでも必須セクションを誤欠落判定しない（body 抽出を打ち切らない / codex premerge R3 P2）
hr="$TMPROOT/gate_bodyhr/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$hr"
put_valid_work_item "$TMPROOT/gate_bodyhr" v3.0.0 001 example ""
# 先頭セクション（## Goal）直後に水平線 --- を挿入（後続必須セクションが --- の後ろに来る）
awk '{print} /^## Goal$/ && !ins {print ""; print "---"; ins=1}' \
    "$hr/001-example.md" > "$hr/001-example.md.tmp" && mv "$hr/001-example.md.tmp" "$hr/001-example.md"
assert_gate_pass "本文中の水平線 --- があっても通過（後続セクション欠落判定しない）" "$hr"
# 閉じ frontmatter delimiter 欠落（先頭 --- のみ）はゲート失敗（codex R7）
ncf="$TMPROOT/gate_noclose/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$ncf"
put_valid_work_item "$TMPROOT/gate_noclose" v3.0.0 001 example ""
# 2 つ目の --- を削除して frontmatter を未終端にする
awk 'BEGIN{c=0} /^---$/{c++; if(c==2) next} {print}' \
    "$ncf/001-example.md" > "$ncf/001-example.md.tmp" && mv "$ncf/001-example.md.tmp" "$ncf/001-example.md"
assert_gate_fail "閉じ frontmatter delimiter 欠落はゲート失敗" "$ncf"
# work item 0 件（空ディレクトリ）
empty="$TMPROOT/gate_empty/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$empty"
assert_gate_fail "work item 0 件はゲート失敗" "$empty"
# ディレクトリ不在
assert_rc 1 "work-items ディレクトリ不在は exit 1" -- "$WIVALIDATE" "$TMPROOT/gate_nodir" pending
# 引数なしは exit 1
assert_rc 1 "引数なしは exit 1" -- "$WIVALIDATE"
# expected_status を渡さない場合は enum 内なら status 不問（in_progress 通過）
nostatus="$TMPROOT/gate_nostatus/.aidlc/cycles/v3.0.0/work-items"; mkdir -p "$nostatus"
put_valid_work_item "$TMPROOT/gate_nostatus" v3.0.0 001 example ""
sed 's/^status: pending/status: in_progress/' "$nostatus/001-example.md" > "$nostatus/001-example.md.tmp" \
    && mv "$nostatus/001-example.md.tmp" "$nostatus/001-example.md"
assert_rc 0 "expected_status 未指定なら in_progress も valid（enum 内）" -- "$WIVALIDATE" "$nostatus"
assert_rc 1 "expected_status=pending 指定で in_progress は exit 1" -- "$WIVALIDATE" "$nostatus" pending

echo "== define Step 4 e2e（正常系 / 新規ブランチ作成経路） =="
repo="$TMPROOT/e2e"; cycle="v3.0.0-alpha.3"
make_sandbox "$repo" "$cycle"              # cycle ブランチは未作成（Step 4-5 で作成させる）
put_approved_intent "$repo" "$cycle"
put_valid_work_item "$repo" "$cycle" 001 define-flow ""
run_define_step4 "$repo" "$cycle"; rc=$?
assert_cond "Step 4 が成功（exit 0）" "$rc"
assert_cond "state.json が生成される" "$([[ -f "$repo/.aidlc/state.json" ]] && echo 0 || echo 1)"
assert_rc 0 "生成 state は valid" -- "$VALIDATE" "$repo/.aidlc/state.json"
assert_out "true" "define_completed=true" -- "$READ" define_completed "$repo/.aidlc/state.json"
assert_out "$cycle" "current_cycle = e2e cycle" -- "$READ" current_cycle "$repo/.aidlc/state.json"
assert_cond "intent.md 生成" "$([[ -f "$repo/.aidlc/cycles/$cycle/intent.md" ]] && echo 0 || echo 1)"
assert_cond "work item 生成" "$([[ -f "$repo/.aidlc/cycles/$cycle/work-items/001-define-flow.md" ]] && echo 0 || echo 1)"
assert_cond "journal.md 生成" "$([[ -f "$repo/.aidlc/cycles/$cycle/journal.md" ]] && echo 0 || echo 1)"
# 同一値整合: dir名 = current_cycle = branch suffix
dirname_cycle="$(basename "$(dirname "$repo/.aidlc/cycles/$cycle/intent.md")")"
state_cycle="$("$READ" current_cycle "$repo/.aidlc/state.json" 2>/dev/null)"
branch="$(cd "$repo" && git rev-parse --abbrev-ref HEAD)"
branch_suffix="${branch#cycle/}"
assert_cond "同一値整合（dir=${dirname_cycle} / state=${state_cycle} / branch=${branch_suffix}）" \
    "$([[ "$dirname_cycle" == "$state_cycle" && "$state_cycle" == "$branch_suffix" ]] && echo 0 || echo 1)"
assert_cond "初回 commit が存在する" "$(cd "$repo" && git log --oneline -1 >/dev/null 2>&1 && echo 0 || echo 1)"

echo "== define Step 4 e2e（既存ブランチ skip 経路） =="
repo3="$TMPROOT/e2e_skip"; cycle3="v3.0.0"
make_sandbox "$repo3" "$cycle3" yes        # 事前に cycle ブランチ作成済み（skip 経路）
put_approved_intent "$repo3" "$cycle3"
put_valid_work_item "$repo3" "$cycle3" 001 foo ""
run_define_step4 "$repo3" "$cycle3"; rc=$?
assert_cond "既存ブランチ上でも Step 4 成功（checkout skip）" "$rc"
assert_out "true" "skip 経路でも define_completed=true" -- "$READ" define_completed "$repo3/.aidlc/state.json"
branch3="$(cd "$repo3" && git rev-parse --abbrev-ref HEAD)"
assert_cond "skip 経路で branch=cycle/${cycle3} を維持" \
    "$([[ "$branch3" == "cycle/$cycle3" ]] && echo 0 || echo 1)"

echo "== define Step 4 e2e（検証ゲート失敗 → define 未完了） =="
repo2="$TMPROOT/e2e_bad"; cycle2="v3.0.0"
make_sandbox "$repo2" "$cycle2"
put_approved_intent "$repo2" "$cycle2"
# 不正 work item（status が pending でない）
put_valid_work_item "$repo2" "$cycle2" 001 bad ""
sed 's/^status: pending/status: done/' "$repo2/.aidlc/cycles/$cycle2/work-items/001-bad.md" > "$repo2/x.tmp" \
    && mv "$repo2/x.tmp" "$repo2/.aidlc/cycles/$cycle2/work-items/001-bad.md"
run_define_step4 "$repo2" "$cycle2"; rc=$?
assert_cond "ゲート失敗で Step 4 が exit 1" "$([[ "$rc" -eq 1 ]] && echo 0 || echo 1)"
assert_cond "ゲート失敗時 state.json は生成されない（define 未完了）" \
    "$([[ ! -f "$repo2/.aidlc/state.json" ]] && echo 0 || echo 1)"
assert_cond "ゲート失敗時 cycle ブランチも作成されない" \
    "$([[ "$(cd "$repo2" && git rev-parse --abbrev-ref HEAD)" != "cycle/$cycle2" ]] && echo 0 || echo 1)"

echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
