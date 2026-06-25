#!/usr/bin/env bash
#
# test-develop-flow.sh - work-item-status.sh 単体 + develop tiny フローの自己完結テスト
#
# 外部テストフレームワークに依存しない（git のみ前提。jq は不要 = frontmatter はテキスト）。
# v2 の `.aidlc/` を一切触らず、隔離サンドボックス（mktemp -d）内で検証する。
#
# 検証対象:
#   - work-item-status.sh: read / write 2 モード（正常遷移 / enum / 期待現在 status 不一致 /
#     status 行 0・重複 / 引用符・inline コメント / 本文 status: 非変更 / atomic / 終了コード 0/1/2）
#   - develop tiny e2e: 選定 → in_progress → 実装模擬 → done → journal → work item 単位 commit、
#     完了後フェーズ導出（develop 継続 / release 可能 / 全 status 走査）
#   - 副作用なし停止: normal/risky 選定（新規 pending / resume in_progress）、Step1 read 異常
#   - resume: in_progress tiny の継続（status 二重遷移しない）
#   - release 誤判定防止: blocked + next:none で release 可能としない（develop 継続）
#
# Usage: test-develop-flow.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（git 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SCRIPT_DIR SCRIPTS_DIR
readonly WISTATUS="$SCRIPTS_DIR/work-item-status.sh"
readonly WINEXT="$SCRIPTS_DIR/work-item-next.sh"
readonly WIVALIDATE="$SCRIPTS_DIR/work-item-validate.sh"

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

# assert_cond <説明> <条件の真偽（0/1）>
assert_cond() {
    local desc="$1" rc="$2"
    if [[ "$rc" == "0" ]]; then
        PASS=$((PASS + 1)); echo "  ok   : $desc"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc"
    fi
}

# ---- フィクスチャ: work item を任意の status / size / deps で配置 ----
put_work_item() {
    local dir="$1" id="$2" slug="$3" status="$4" size="$5" deps="$6"
    mkdir -p "$dir"
    cat > "$dir/${id}-${slug}.md" <<EOF
---
id: "$id"
status: $status
size: $size
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

- Size: $size
- Risk: low
- Reason: trivial

## Dependencies

- $( [[ -z "$deps" ]] && echo none || echo "$deps" )
EOF
}

# ---- 隔離サンドボックス git リポジトリ（work item フィクスチャを初期 commit） ----
make_sandbox() {
    local repo="$1" cycle="$2"
    mkdir -p "$repo/.aidlc/cycles/$cycle/work-items"
    (
        cd "$repo" || exit 9
        git init -q
        git config user.email t@example.com
        git config user.name t
        printf '%s\n' '# stub config' > .aidlc/config.toml
        printf '{\n  "schema_version": "3.0",\n  "current_cycle": "%s",\n  "define_completed": true,\n  "release": {"pr_number": null, "ready": false, "merge_approved": false},\n  "updated_at": "2026-06-14T00:00:00Z"\n}\n' "$cycle" > .aidlc/state.json
    )
}

# state.json + 全 work item status 走査でフェーズ導出（§5.1 評価順 3/4 のうち本 Unit 範囲）。
# 出力: develop | release | define（複雑な complete 判定は本 Unit 範囲外）。
# 注: assert_out 経由（"$@"）で間接呼び出しされるため shellcheck からは未使用に見える。
# shellcheck disable=SC2329
derive_phase() {
    local repo="$1" cycle="$2"
    local widir="$repo/.aidlc/cycles/$cycle/work-items"
    local f st all_done=1 define_completed
    define_completed="$(grep -E '"define_completed"' "$repo/.aidlc/state.json" | grep -oE 'true|false' | head -n1)"
    if [[ "$define_completed" != "true" ]]; then echo "define"; return 0; fi
    shopt -s nullglob
    for f in "$widir"/*.md; do
        st="$("$WISTATUS" --read "$f" 2>/dev/null)"; st="${st#status:}"
        if [[ "$st" != "done" && "$st" != "withdrawn" ]]; then all_done=0; fi
    done
    shopt -u nullglob
    if [[ "$all_done" == "1" ]]; then echo "release"; else echo "develop"; fi
}

# ---- §8 マトリクス写像（docs/v3/data-model.md §8 の materialized view / develop.md Step1 step4 の表と一致） ----
# decide_matrix <size> <depth> -> stdout:
#   matrix_case|design_required|design_mode|risk_analysis|test_plan|rollback_note|review_required|review_mode|reason_record|error
#   bool フィールドは 0/1。error ∈ {none, invalid_size, risky_minimal, unknown_depth}
# 設計（ドメインモデル MatrixDecision）の論理フィールド対応:
#   - matrix_case = <normalized_size>_<normalized_depth_level>（正規化済み入力）
#   - error       = §8 size×depth 写像由来の error_reason（is_error = (error != none) を導出）
#   - 残りの列     = 同名の派生要件（design_mode / review_mode 等）
# 注: invalid_artifact_path は §8 写像由来ではなく Step 1 の成果物パス導出ガードに由来する別系統の
#     error_reason のため、本純粋写像（decide_matrix）の error enum には含めない。run_develop 側の
#     path 検証で別段の停止コード（rc 25）として扱う。
# 純粋関数（mutation なし）。run_develop と 9 セル assert の双方が本関数を単一の真実として参照する。
# 注: assert/間接呼び出しのため shellcheck からは未使用に見える。
# shellcheck disable=SC2329
decide_matrix() {
    local size="$1" depth="$2"
    case "$size" in tiny|normal|risky) ;; *) echo "invalid|0|none|0|0|0|0|none|0|invalid_size"; return 0 ;; esac
    if [[ "$size" == "risky" && "$depth" == "minimal" ]]; then
        echo "risky_minimal|0|none|0|0|0|0|none|0|risky_minimal"; return 0
    fi
    case "${size}_${depth}" in
        tiny_minimal)         echo "tiny_minimal|0|none|0|0|0|0|none|0|none" ;;
        tiny_standard)        echo "tiny_standard|0|none|0|0|0|0|none|0|none" ;;
        tiny_comprehensive)   echo "tiny_comprehensive|0|none|0|0|0|0|none|1|none" ;;
        normal_minimal)       echo "normal_minimal|0|none|0|0|0|0|none|0|none" ;;
        normal_standard)      echo "normal_standard|1|simple|0|0|0|1|code|0|none" ;;
        normal_comprehensive) echo "normal_comprehensive|1|full|1|0|0|1|code|0|none" ;;
        risky_standard)       echo "risky_standard|1|full|0|0|1|1|code_security|0|none" ;;
        risky_comprehensive)  echo "risky_comprehensive|1|full|1|1|1|1|code_security_design|0|none" ;;
        *)                    echo "unknown|0|none|0|0|0|0|none|0|unknown_depth" ;;
    esac
}

# ---- develop フロードライバ（develop.md Step1-6 の決定的 mutation を模擬 / size×depth_level 分岐） ----
# AI 判断（実装内容そのもの）はテストせず、§8 判定・status 遷移・journal 追記・commit を再現する。
# §8 判定は decide_matrix（単一の真実）に委譲する。depth_level は引数で与える（実フローは
# read-config.sh で config.toml から解決する。本ハーネスは外部依存 dasel を避けるため
# 「解決済み depth_level」を入力とする。depth_level 解決の正規化契約の網羅検証は Unit 004 の範囲）。
# 戻り値:
#   0  = 完了（design/review 不要セル: tiny_* / normal_minimal。tiny_comprehensive は理由記録付き）
#   20 = next:none（停止）
#   21 = design または review が必要（normal/risky standard 以上 = Unit 002/003 未実装 / 副作用なし停止）
#   22 = read 異常 / 想定外（副作用なし停止）
#   23 = invalid_size（size enum 外 / 副作用なし停止）
#   24 = risky_minimal（risky+minimal 不可 / 副作用なし停止）
#   25 = invalid_artifact_path（成果物ファイル名が <id>- prefix 不一致 / 副作用なし停止）
# 注: assert 経由で間接呼び出しされるため shellcheck からは未使用に見える。
# shellcheck disable=SC2329
run_develop() {
    local repo="$1" cycle="$2" depth="$3"
    local widir=".aidlc/cycles/$cycle/work-items"
    (
        cd "$repo" || exit 9
        local nx id size path st
        nx="$("$WINEXT" "$widir" 2>/dev/null)" || exit 22
        if [[ "$nx" == "next:none" ]]; then exit 20; fi
        # next:<id>:<size>:<path>
        id="$(printf '%s' "$nx" | cut -d: -f2)"
        size="$(printf '%s' "$nx" | cut -d: -f3)"
        path="$(printf '%s' "$nx" | cut -d: -f4-)"
        # Step1-2 〜 1-4: §8 写像（decide_matrix）。判定は mutation を伴わない
        # 本ドライバが消費するのは design_required / review_required / reason_record / error のみ。
        # 他の派生フィールド（design_mode / risk_analysis / test_plan / rollback_note / review_mode）は
        # decide_matrix の 9 セル assert 側で検証する（ここでは `_` で読み捨てる）。
        local dec d_req r_req rrec err
        dec="$(decide_matrix "$size" "$depth")"
        IFS='|' read -r _ d_req _ _ _ _ r_req _ rrec err <<<"$dec"
        case "$err" in
            invalid_size) exit 23 ;;
            risky_minimal) exit 24 ;;
            none) ;;
            *) exit 22 ;;  # unknown_depth 等（実フローは解決契約で standard へ正規化済みのはず）
        esac
        # design/review 必須セル: 成果物パス導出 + invalid_artifact_path 検証 → スコープ境界ガード
        # （いずれも status 遷移より前 = 副作用なし。生成本体は Unit 002/003）
        if [[ "$d_req" == "1" || "$r_req" == "1" ]]; then
            local fname; fname="$(basename "$path")"
            case "$fname" in "${id}-"*) ;; *) exit 25 ;; esac
            exit 21
        fi
        # ここに到達するのは design/review 不要セル（tiny_* / normal_minimal）= end-to-end 完走
        # Step1-5: 現在 status 読取 + 遷移
        st="$("$WISTATUS" --read "$path" 2>/dev/null)" || exit 22
        st="${st#status:}"
        case "$st" in
            pending) "$WISTATUS" "$path" pending in_progress >/dev/null 2>&1 || exit 22 ;;
            in_progress) : ;;  # resume: 遷移せず継続
            *) exit 22 ;;
        esac
        # Step3: 実装模擬（acceptance criteria を満たす変更を 1 つ作る）
        mkdir -p "src"
        printf 'done by %s\n' "$id" > "src/${id}.txt"
        # Step4: 検証（ここでは省略 / 実フローは AC チェック）
        # Step6: done 遷移 + journal 追記 + （条件付き）理由記録 + work item 単位 commit 集約
        "$WISTATUS" "$path" in_progress "done" >/dev/null 2>&1 || exit 22
        local journal=".aidlc/cycles/$cycle/journal.md"
        if [[ ! -f "$journal" ]]; then
            printf '# Journal: %s\n\n## 2026-06-14\n\n' "$cycle" > "$journal"
        fi
        printf -- '- develop completed: %s\n' "$id" >> "$journal"
        if [[ "$rrec" == "1" ]]; then
            printf -- '- develop reason (tiny+comprehensive): %s\n' "$id" >> "$journal"
        fi
        git add -A >/dev/null 2>&1
        git -c user.email=t@example.com -c user.name=t commit -q -m "develop: $id 完了" || exit 9
    )
}

# work-items ディレクトリ + journal の状態スナップショット（副作用検出用）。
snapshot() {
    local repo="$1" cycle="$2"
    local base="$repo/.aidlc/cycles/$cycle"
    ( cd "$repo" && git rev-parse HEAD 2>/dev/null; git status --porcelain 2>/dev/null )
    cat "$base"/work-items/*.md 2>/dev/null
    cat "$base/journal.md" 2>/dev/null
}

echo "== 静的検査（bash -n / shellcheck） =="
assert_rc 0 "bash -n: work-item-status.sh" -- bash -n "$WISTATUS"
assert_rc 0 "bash -n: test-develop-flow.sh" -- bash -n "$SCRIPT_DIR/test-develop-flow.sh"
if command -v shellcheck >/dev/null 2>&1; then
    assert_rc 0 "shellcheck: work-item-status.sh" -- shellcheck "$WISTATUS"
    assert_rc 0 "shellcheck: test-develop-flow.sh" -- shellcheck "$SCRIPT_DIR/test-develop-flow.sh"
else
    echo "  skip : shellcheck 未インストール"
fi

# markdownlint（利用可能時のみ）: develop tiny フローの恒久成果物 Markdown を検証する。
# cycle 成果物（設計ドキュメント）は cycle 固有のため本恒久ハーネスの対象外。
DEVELOP_MD="$SCRIPTS_DIR/../steps/develop.md"
SKILL_MD="$SCRIPTS_DIR/../SKILL.md"
if command -v markdownlint-cli2 >/dev/null 2>&1; then
    assert_rc 0 "markdownlint: develop.md / SKILL.md" -- markdownlint-cli2 "$DEVELOP_MD" "$SKILL_MD"
elif command -v npx >/dev/null 2>&1; then
    echo "  skip : markdownlint-cli2 未インストール（npx 経由は環境依存のため本ハーネスでは skip / 完了処理で別途実行）"
else
    echo "  skip : markdownlint 未インストール"
fi

echo "== work-item-status.sh: read / write 正常系 =="
su="$TMPROOT/status-unit"; mkdir -p "$su/work-items"
put_work_item "$su/work-items" 001 foo pending tiny ""
assert_out "status:pending" "read: pending" -- "$WISTATUS" --read "$su/work-items/001-foo.md"
assert_out "status:written" "write: pending->in_progress" -- "$WISTATUS" "$su/work-items/001-foo.md" pending in_progress
assert_out "status:in_progress" "read: in_progress 反映" -- "$WISTATUS" --read "$su/work-items/001-foo.md"
assert_out "status:written" "write: in_progress->done" -- "$WISTATUS" "$su/work-items/001-foo.md" in_progress "done"
"$WIVALIDATE" "$su/work-items" >/dev/null 2>&1; assert_cond "write 後も frontmatter が valid（atomic 整合）" "$?"

echo "== work-item-status.sh: 引用符 / inline コメント =="
sq="$TMPROOT/status-quote"; mkdir -p "$sq/work-items"
put_work_item "$sq/work-items" 001 q pending tiny ""
# status をクオート + inline コメントに書き換える
sed -i.bak 's/^status: pending$/status: "pending" # note/' "$sq/work-items/001-q.md" && rm -f "$sq/work-items/001-q.md.bak"
assert_out "status:pending" "read: 引用符 + inline コメント" -- "$WISTATUS" --read "$sq/work-items/001-q.md"
assert_out "status:written" "write: 引用符付き現在値でも遷移" -- "$WISTATUS" "$sq/work-items/001-q.md" pending in_progress
# 片側引用符（balanced quote のみ許容 / 開き・閉じ単独は enum 不一致で exit 1）。
# read 異常 = 副作用なしの契約を明文化（codex premerge R2 偽陽性に対する回帰防止テスト）。
oq="$TMPROOT/status-openquote"; mkdir -p "$oq/work-items"
put_work_item "$oq/work-items" 001 oq pending tiny ""
sed -i.bak 's/^status: pending$/status: "pending/' "$oq/work-items/001-oq.md" && rm -f "$oq/work-items/001-oq.md.bak"
assert_rc 1 "read: 片側引用符（開き）status: \"pending は exit 1" -- "$WISTATUS" --read "$oq/work-items/001-oq.md"
assert_rc 1 "write: 片側引用符（開き）は遷移せず exit 1" -- "$WISTATUS" "$oq/work-items/001-oq.md" pending in_progress
cq="$TMPROOT/status-closequote"; mkdir -p "$cq/work-items"
put_work_item "$cq/work-items" 001 cq pending tiny ""
sed -i.bak 's/^status: pending$/status: pending"/' "$cq/work-items/001-cq.md" && rm -f "$cq/work-items/001-cq.md.bak"
assert_rc 1 "read: 片側引用符（閉じ）status: pending\" は exit 1" -- "$WISTATUS" --read "$cq/work-items/001-cq.md"
# 閉じ frontmatter delimiter 欠落（先頭 --- のみ）は read/write とも exit 1（malformed file 改変防止 / codex R7）
ncd="$TMPROOT/status-noclose"; mkdir -p "$ncd/work-items"
cat > "$ncd/work-items/001-nc.md" <<'EOF'
---
id: "001"
status: pending
size: tiny
risk: low
assigned: null
dependencies: []

# body without closing frontmatter delimiter
EOF
assert_rc 1 "read: 閉じ --- 欠落は exit 1" -- "$WISTATUS" --read "$ncd/work-items/001-nc.md"
assert_rc 1 "write: 閉じ --- 欠落は遷移せず exit 1" -- "$WISTATUS" "$ncd/work-items/001-nc.md" pending in_progress

echo "== work-item-status.sh: 本文 status: 非変更 =="
sb="$TMPROOT/status-body"; mkdir -p "$sb/work-items"
put_work_item "$sb/work-items" 001 b pending tiny ""
# 本文に status: を含む行を追加
printf '\nstatus: this body line must stay\n' >> "$sb/work-items/001-b.md"
"$WISTATUS" "$sb/work-items/001-b.md" pending in_progress >/dev/null 2>&1
grep -q '^status: this body line must stay$' "$sb/work-items/001-b.md"; assert_cond "本文 status: 行は変更されない" "$?"
fmstatus="$("$WISTATUS" --read "$sb/work-items/001-b.md")"
assert_cond "frontmatter status のみ遷移" "$([[ "$fmstatus" == "status:in_progress" ]] && echo 0 || echo 1)"

echo "== work-item-status.sh: 異常系（終了コード規約） =="
se="$TMPROOT/status-err"; mkdir -p "$se/work-items"
put_work_item "$se/work-items" 001 e pending tiny ""
assert_rc 1 "引数不足（0 個）は exit 1" -- "$WISTATUS"
assert_rc 1 "write 引数不足（2 個）は exit 1" -- "$WISTATUS" "$se/work-items/001-e.md" pending
assert_rc 1 "--read 引数過多は exit 1" -- "$WISTATUS" --read a b
assert_rc 1 "ファイル不在は exit 1" -- "$WISTATUS" --read "$se/work-items/none.md"
assert_rc 1 "enum 不正（next）は exit 1" -- "$WISTATUS" "$se/work-items/001-e.md" pending nope
assert_rc 1 "enum 不正（expected）は exit 1" -- "$WISTATUS" "$se/work-items/001-e.md" nope in_progress
assert_rc 1 "期待現在 status 不一致は exit 1" -- "$WISTATUS" "$se/work-items/001-e.md" in_progress "done"
# status 行 0
nostatus="$se/work-items/002-n.md"
cat > "$nostatus" <<'EOF'
---
id: "002"
size: tiny
---

# body
EOF
assert_rc 1 "frontmatter に status 行なしは exit 1" -- "$WISTATUS" --read "$nostatus"
# status 行 2 つ（曖昧）
dupstatus="$se/work-items/003-d.md"
cat > "$dupstatus" <<'EOF'
---
id: "003"
status: pending
status: done
size: tiny
---

# body
EOF
assert_rc 1 "frontmatter に status 行 2 つは exit 1（曖昧）" -- "$WISTATUS" --read "$dupstatus"

echo "== develop e2e: 単一 tiny+standard → 完了 → release 可能 =="
r1="$TMPROOT/e2e-single"; make_sandbox "$r1" v3.0.0-alpha.t
put_work_item "$r1/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 only pending tiny ""
( cd "$r1" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r1" v3.0.0-alpha.t standard; assert_cond "run_develop tiny+standard 完了（rc=0）" "$?"
assert_out "status:done" "完了後 status=done" -- "$WISTATUS" --read "$r1/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-only.md"
grep -q '^- develop completed: 001$' "$r1/.aidlc/cycles/v3.0.0-alpha.t/journal.md"; assert_cond "journal に完了追記" "$?"
assert_out "release" "完了後フェーズ導出 = release 可能（全 done）" -- derive_phase "$r1" v3.0.0-alpha.t

echo "== develop e2e: 複数 tiny → 1 件完了で develop 継続 =="
r2="$TMPROOT/e2e-multi"; make_sandbox "$r2" v3.0.0-alpha.t
put_work_item "$r2/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 a pending tiny ""
put_work_item "$r2/.aidlc/cycles/v3.0.0-alpha.t/work-items" 002 b pending tiny ""
( cd "$r2" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r2" v3.0.0-alpha.t standard; assert_cond "1 件目 tiny 完了（rc=0）" "$?"
assert_out "status:done" "001 done" -- "$WISTATUS" --read "$r2/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-a.md"
assert_out "status:pending" "002 は未着手のまま" -- "$WISTATUS" --read "$r2/.aidlc/cycles/v3.0.0-alpha.t/work-items/002-b.md"
assert_out "develop" "1 件残でフェーズ導出 = develop 継続" -- derive_phase "$r2" v3.0.0-alpha.t

echo "== develop e2e: resume（in_progress tiny）継続 =="
r3="$TMPROOT/e2e-resume"; make_sandbox "$r3" v3.0.0-alpha.t
put_work_item "$r3/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 res in_progress tiny ""
( cd "$r3" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r3" v3.0.0-alpha.t standard; assert_cond "resume tiny 完了（rc=0 / 二重遷移せず done）" "$?"
assert_out "status:done" "resume 後 status=done" -- "$WISTATUS" --read "$r3/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-res.md"

echo "== 副作用なし停止: normal+standard（design/review 必須 = Unit 002/003 未実装 / 新規 pending） =="
r4="$TMPROOT/noop-normal"; make_sandbox "$r4" v3.0.0-alpha.t
put_work_item "$r4/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 n pending normal ""
( cd "$r4" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
snap_before="$(snapshot "$r4" v3.0.0-alpha.t)"
run_develop "$r4" v3.0.0-alpha.t standard; rc=$?
assert_cond "normal+standard は design/review 必須で停止コード 21" "$([[ "$rc" == "21" ]] && echo 0 || echo 1)"
snap_after="$(snapshot "$r4" v3.0.0-alpha.t)"
assert_cond "normal+standard 選定で副作用なし（status 遷移前停止 / 状態不変）" "$([[ "$snap_before" == "$snap_after" ]] && echo 0 || echo 1)"

echo "== 副作用なし停止: resume された in_progress normal+standard =="
r5="$TMPROOT/noop-resume-normal"; make_sandbox "$r5" v3.0.0-alpha.t
put_work_item "$r5/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 rn in_progress normal ""
( cd "$r5" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
snap_before="$(snapshot "$r5" v3.0.0-alpha.t)"
run_develop "$r5" v3.0.0-alpha.t standard; rc=$?
assert_cond "resume normal+standard は停止コード 21" "$([[ "$rc" == "21" ]] && echo 0 || echo 1)"
snap_after="$(snapshot "$r5" v3.0.0-alpha.t)"
assert_cond "resume normal+standard で副作用なし（状態不変）" "$([[ "$snap_before" == "$snap_after" ]] && echo 0 || echo 1)"

echo "== 副作用なし停止: risky+standard（design/review 必須 = Unit 002/003 未実装 / 新規 pending） =="
r4b="$TMPROOT/noop-risky"; make_sandbox "$r4b" v3.0.0-alpha.t
put_work_item "$r4b/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 rk pending risky ""
( cd "$r4b" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
snap_before="$(snapshot "$r4b" v3.0.0-alpha.t)"
run_develop "$r4b" v3.0.0-alpha.t standard; rc=$?
assert_cond "risky+standard は design/review 必須で停止コード 21" "$([[ "$rc" == "21" ]] && echo 0 || echo 1)"
snap_after="$(snapshot "$r4b" v3.0.0-alpha.t)"
assert_cond "risky+standard 選定で副作用なし（状態不変）" "$([[ "$snap_before" == "$snap_after" ]] && echo 0 || echo 1)"

echo "== 副作用なし停止: resume された in_progress risky+standard =="
r5b="$TMPROOT/noop-resume-risky"; make_sandbox "$r5b" v3.0.0-alpha.t
put_work_item "$r5b/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 rrk in_progress risky ""
( cd "$r5b" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
snap_before="$(snapshot "$r5b" v3.0.0-alpha.t)"
run_develop "$r5b" v3.0.0-alpha.t standard; rc=$?
assert_cond "resume risky+standard は停止コード 21" "$([[ "$rc" == "21" ]] && echo 0 || echo 1)"
snap_after="$(snapshot "$r5b" v3.0.0-alpha.t)"
assert_cond "resume risky+standard で副作用なし（状態不変）" "$([[ "$snap_before" == "$snap_after" ]] && echo 0 || echo 1)"

echo "== Unit 001 e2e: normal+minimal → end-to-end 完走（design/review 不要） =="
r8="$TMPROOT/e2e-normal-minimal"; make_sandbox "$r8" v3.0.0-alpha.t
put_work_item "$r8/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 nm pending normal ""
( cd "$r8" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r8" v3.0.0-alpha.t minimal; assert_cond "normal+minimal 完走（rc=0）" "$?"
assert_out "status:done" "normal+minimal 完了後 status=done" -- "$WISTATUS" --read "$r8/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-nm.md"
grep -q '^- develop completed: 001$' "$r8/.aidlc/cycles/v3.0.0-alpha.t/journal.md"; assert_cond "normal+minimal journal に完了追記" "$?"
assert_out "release" "normal+minimal 完了後フェーズ導出 = release 可能" -- derive_phase "$r8" v3.0.0-alpha.t

echo "== Unit 001 エラー停止: risky+minimal（不可）→ 副作用なし =="
r9="$TMPROOT/risky-minimal"; make_sandbox "$r9" v3.0.0-alpha.t
put_work_item "$r9/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 rm pending risky ""
( cd "$r9" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
snap_before="$(snapshot "$r9" v3.0.0-alpha.t)"
run_develop "$r9" v3.0.0-alpha.t minimal; rc=$?
assert_cond "risky+minimal は不可で停止コード 24" "$([[ "$rc" == "24" ]] && echo 0 || echo 1)"
snap_after="$(snapshot "$r9" v3.0.0-alpha.t)"
assert_cond "risky+minimal で副作用なし（状態不変）" "$([[ "$snap_before" == "$snap_after" ]] && echo 0 || echo 1)"

echo "== Unit 001 非回帰: tiny+comprehensive → 完走 + 理由記録 / tiny+minimal は理由記録なし =="
r10="$TMPROOT/tiny-comp"; make_sandbox "$r10" v3.0.0-alpha.t
put_work_item "$r10/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 tc pending tiny ""
( cd "$r10" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r10" v3.0.0-alpha.t comprehensive; assert_cond "tiny+comprehensive 完走（rc=0）" "$?"
grep -q '^- develop reason (tiny+comprehensive): 001$' "$r10/.aidlc/cycles/v3.0.0-alpha.t/journal.md"; assert_cond "tiny+comprehensive は理由記録を追記" "$?"
r10b="$TMPROOT/tiny-min"; make_sandbox "$r10b" v3.0.0-alpha.t
put_work_item "$r10b/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 tm pending tiny ""
( cd "$r10b" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r10b" v3.0.0-alpha.t minimal; assert_cond "tiny+minimal 完走（rc=0 / Phase 3 非回帰）" "$?"
if grep -q 'develop reason' "$r10b/.aidlc/cycles/v3.0.0-alpha.t/journal.md"; then rr_min=1; else rr_min=0; fi
assert_cond "tiny+minimal は理由記録を追記しない（非回帰）" "$rr_min"

echo "== Unit 001 エラー停止: invalid size（enum 外）→ 副作用なし =="
r11="$TMPROOT/invalid-size"; make_sandbox "$r11" v3.0.0-alpha.t
put_work_item "$r11/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 iv pending bogus ""
( cd "$r11" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
snap_before="$(snapshot "$r11" v3.0.0-alpha.t)"
run_develop "$r11" v3.0.0-alpha.t standard; rc=$?
assert_cond "invalid size は停止コード 23" "$([[ "$rc" == "23" ]] && echo 0 || echo 1)"
snap_after="$(snapshot "$r11" v3.0.0-alpha.t)"
assert_cond "invalid size で副作用なし（状態不変）" "$([[ "$snap_before" == "$snap_after" ]] && echo 0 || echo 1)"

echo "== §8 マトリクス写像（decide_matrix の 9 有効セル + エラーセル） =="
# docs/v3/data-model.md §8 / develop.md Step1 step4 の表と一致することを全フィールドで固定する。
# review_mode の risky_standard=code_security と risky_comprehensive=code_security_design の差分を含む。
assert_out "tiny_minimal|0|none|0|0|0|0|none|0|none" "§8 tiny+minimal" -- decide_matrix tiny minimal
assert_out "tiny_standard|0|none|0|0|0|0|none|0|none" "§8 tiny+standard" -- decide_matrix tiny standard
assert_out "tiny_comprehensive|0|none|0|0|0|0|none|1|none" "§8 tiny+comprehensive（理由記録）" -- decide_matrix tiny comprehensive
assert_out "normal_minimal|0|none|0|0|0|0|none|0|none" "§8 normal+minimal（実装+テストのみ）" -- decide_matrix normal minimal
assert_out "normal_standard|1|simple|0|0|0|1|code|0|none" "§8 normal+standard（簡易 design + code review）" -- decide_matrix normal standard
assert_out "normal_comprehensive|1|full|1|0|0|1|code|0|none" "§8 normal+comprehensive（design + risk + code review）" -- decide_matrix normal comprehensive
assert_out "risky_standard|1|full|0|0|1|1|code_security|0|none" "§8 risky+standard（design + rollback + code(security)）" -- decide_matrix risky standard
assert_out "risky_comprehensive|1|full|1|1|1|1|code_security_design|0|none" "§8 risky+comprehensive（複数 review = code(security)+design）" -- decide_matrix risky comprehensive
assert_out "risky_minimal|0|none|0|0|0|0|none|0|risky_minimal" "§8 risky+minimal（不可）" -- decide_matrix risky minimal
assert_out "invalid|0|none|0|0|0|0|none|0|invalid_size" "§8 invalid size（enum 外）" -- decide_matrix bogus standard

echo "== Unit 001 エラー停止: invalid_artifact_path（ファイル名が <id>- prefix 不一致 / design 必須セル）→ 副作用なし =="
# work-item-next は id をファイル名から導出する（<id>-<slug>.md の <id> 部）。ハイフン無しの
# `001.md` は id=001 だが basename `001.md` は `001-` で始まらないため invalid_artifact_path 経路に到達する。
# normal+standard は design 必須セル = 成果物パス導出が走る経路。
r12="$TMPROOT/invalid-path"; make_sandbox "$r12" v3.0.0-alpha.t
mkdir -p "$r12/.aidlc/cycles/v3.0.0-alpha.t/work-items"
cat > "$r12/.aidlc/cycles/v3.0.0-alpha.t/work-items/001.md" <<'EOF'
---
id: "001"
status: pending
size: normal
risk: low
assigned: null
dependencies: []
---

# Work Item 001: noslug

## Goal

g

## Scope

- x

## Acceptance Criteria

- [ ] c

## Traceability

- Intent refs: scope:x
- Acceptance refs: AC-001
- Verification: manual
- Release note required: no

## Size / Risk

- Size: normal
- Risk: low
- Reason: r

## Dependencies

- none
EOF
( cd "$r12" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
snap_before="$(snapshot "$r12" v3.0.0-alpha.t)"
run_develop "$r12" v3.0.0-alpha.t standard; rc=$?
assert_cond "invalid_artifact_path（001.md）は停止コード 25" "$([[ "$rc" == "25" ]] && echo 0 || echo 1)"
snap_after="$(snapshot "$r12" v3.0.0-alpha.t)"
assert_cond "invalid_artifact_path で副作用なし（status 遷移前停止 / 状態不変）" "$([[ "$snap_before" == "$snap_after" ]] && echo 0 || echo 1)"

echo "== release 誤判定防止: blocked 残存 + next:none → develop 継続 =="
r6="$TMPROOT/blocked"; make_sandbox "$r6" v3.0.0-alpha.t
# 001 blocked, 002 pending depends on 001（withdrawn でない / done でもない）→ next:none だが未完了残
put_work_item "$r6/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 blk blocked tiny ""
put_work_item "$r6/.aidlc/cycles/v3.0.0-alpha.t/work-items" 002 dep pending tiny '"001"'
( cd "$r6" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
assert_out "next:none" "blocked 残存 + 依存未充足は next:none" -- "$WINEXT" "$r6/.aidlc/cycles/v3.0.0-alpha.t/work-items"
assert_out "develop" "next:none でも未完了残ありは develop 継続（release 誤判定なし）" -- derive_phase "$r6" v3.0.0-alpha.t

echo "== Step1 read 異常で副作用なし =="
r7="$TMPROOT/readerr"; make_sandbox "$r7" v3.0.0-alpha.t
# status 行を 2 つにして read を exit 1 にする（next は status を見ず id/size を返すため選定はされる）
badwi="$r7/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-bad.md"
cat > "$badwi" <<'EOF'
---
id: "001"
status: pending
status: in_progress
size: tiny
risk: low
assigned: null
dependencies: []
---

# Work Item 001: bad

## Goal

g

## Scope

- x

## Acceptance Criteria

- [ ] c

## Traceability

- Intent refs: scope:x
- Acceptance refs: AC-001
- Verification: manual
- Release note required: no

## Size / Risk

- Size: tiny
- Risk: low
- Reason: r

## Dependencies

- none
EOF
( cd "$r7" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
snap_before="$(snapshot "$r7" v3.0.0-alpha.t)"
run_develop "$r7" v3.0.0-alpha.t standard; rc=$?
assert_cond "read 異常（status 重複）で停止コード 22" "$([[ "$rc" == "22" ]] && echo 0 || echo 1)"
snap_after="$(snapshot "$r7" v3.0.0-alpha.t)"
assert_cond "read 異常で副作用なし（状態不変）" "$([[ "$snap_before" == "$snap_after" ]] && echo 0 || echo 1)"

echo ""
echo "== 結果 =="
echo "PASS=$PASS FAIL=$FAIL"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
