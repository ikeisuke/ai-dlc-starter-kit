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
#   - 副作用なし停止: invalid_size(23) / risky_minimal(24) / invalid_artifact_path(25) / テンプレート不在(27) / Step1 read 異常(22)
#   - design 必須セル（Unit 002/003）: design 生成 + review routing（Step 5）+ 完走（rc=0 / done / reviews 生成）
#     - decide_review_routing 写像（matrix_review_mode → perspective:focus:section / code,code_security,code_security_design,none）
#     - reviews_path の perspective 別セクション（## Code Review / ## Design Review）と status=complete マーカー
#     - review_required=false（tiny_* / normal+minimal）は reviews 非生成
#   - resume: in_progress の継続（status 二重遷移しない / design・review 必須セル含む）
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
# design テンプレート（Unit 002 / Step 2 生成の起点 / Step 1 preflight の存在検証対象）
readonly DESIGN_TMPL="$SCRIPTS_DIR/../templates/design.md"

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

# section_nonempty <file> <heading> : 指定見出しから次の `## ` 見出し（または EOF）までに
# 非空行が 1 行以上あれば exit 0、なければ exit 1（design の条件付きセクション非空検証用 / 罫線・空行のみは空扱い）。
section_nonempty() {
    awk -v h="$2" '$0==h{f=1;next} /^## /{f=0} f&&NF{c=1} END{exit !c}' "$1"
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

# ---- review routing 写像（Unit 003 / develop.md Step 5.1 の materialized view） ----
# decide_review_routing <matrix_review_mode> -> stdout:
#   route を `;` 区切りで列挙。各 route = `<perspective>:<focus>:<記録セクション見出し>`
#   route なし（none）は空行。未知値は `unknown`（純粋写像 / decide_matrix と同様に停止しない）
# 設計（ドメインモデル ReviewRoutingDecision）の不変条件と厳密一致:
#   - reviewing-construction-code は code+security 複合スキル。code_security を security-only に縮約しない
#     （code / code_security はいずれも focus=code,security。security 重点は呼び出しコンテキストの質的注記）
#   - code_security_design のみ design review（focus=architecture / 対象 designs_path）を追加
# 純粋関数（mutation なし）。run_develop の Step 5 模擬と routing assert の双方が本関数を単一の真実として参照する。
# 注: assert/間接呼び出しのため shellcheck からは未使用に見える。
# shellcheck disable=SC2329
decide_review_routing() {
    local rmode="$1"
    case "$rmode" in
        none)                 echo "" ;;
        code)                 echo "code:code,security:## Code Review" ;;
        code_security)        echo "code:code,security:## Code Review" ;;
        code_security_design) echo "code:code,security:## Code Review;design:architecture:## Design Review" ;;
        *)                    echo "unknown" ;;
    esac
}

# ---- reviews_path セクション冪等 upsert（Unit 003 / develop.md Step 5.3 の upsert 規則の materialized 実装） ----
# upsert_review_section <file> <perspective> <status> <body>
#   既存区間が status=complete → スキップ（保持 / 再追記・上書きしない）
#   既存区間が status!=complete（in_progress 等）→ 行頭 start〜end をまるごと置換
#   区間なし → 末尾に新規追加
# マーカー検出は行頭完全一致のみ（^<!-- aidlc-review:<persp>:(start|end)）。本文混入マーカーは region 判定に使わない
# （develop.md Step 5.3 の injection 無害化契約と一致）。冪等性の単一の真実として upsert テストが本関数を参照する。
# 注: assert 経由で間接呼び出しされるため shellcheck からは未使用に見える。
# shellcheck disable=SC2329
upsert_review_section() {
    local file="$1" persp="$2" status="$3" body="$4" heading
    case "$persp" in code) heading="## Code Review" ;; design) heading="## Design Review" ;; *) heading="## Review" ;; esac
    [[ -f "$file" ]] || : > "$file"
    local existing
    existing="$(awk -v p="$persp" '
        $0 ~ ("^<!-- aidlc-review:" p ":start status=") {
            match($0, /status=[a-z_]+/); print substr($0, RSTART+7, RLENGTH-7); exit }' "$file")"
    if [[ "$existing" == "complete" ]]; then return 0; fi
    if [[ -n "$existing" ]]; then
        awk -v p="$persp" '
            $0 ~ ("^<!-- aidlc-review:" p ":start status=") {drop=1; next}
            drop && $0 ~ ("^<!-- aidlc-review:" p ":end -->$") {drop=0; next}
            drop {next}
            {print}' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    fi
    {
        printf -- '<!-- aidlc-review:%s:start status=%s -->\n\n' "$persp" "$status"
        printf -- '%s\n\n%s\n\n' "$heading" "$body"
        printf -- '<!-- aidlc-review:%s:end -->\n' "$persp"
    } >> "$file"
}

# ---- develop フロードライバ（develop.md Step1-6 の決定的 mutation を模擬 / size×depth_level 分岐） ----
# AI 判断（実装内容そのもの・Design 承認ゲートの対話）はテストせず、§8 判定・status 遷移・design 生成・
# journal 追記・commit を再現する。§8 判定は decide_matrix（単一の真実）に委譲する。depth_level は引数で
# 与える（実フローは read-config.sh で config.toml から解決。本ハーネスは外部依存 dasel を避けるため
# 「解決済み depth_level」を入力とする。depth_level 解決の正規化契約の網羅検証は Unit 004 の範囲）。
# design テンプレートは第 4 引数で与える（既定 = 実テンプレート $DESIGN_TMPL / 不在検証は専用パスを渡す）。
# 戻り値:
#   0  = 完了（design/review 不要セル: tiny_* / normal_minimal。tiny_comprehensive は理由記録付き）
#   20 = next:none（停止）
#   22 = read 異常 / 想定外（副作用なし停止）
#   23 = invalid_size（size enum 外 / 副作用なし停止）
#   24 = risky_minimal（risky+minimal 不可 / 副作用なし停止）
#   25 = invalid_artifact_path（成果物ファイル名が <id>- prefix 不一致 / 副作用なし停止）
#   27 = design テンプレート不在（Step 1 preflight / 副作用なし停止 / status 未遷移 / Unit 002）
#   注: rc=26（Unit 002 の review 境界停止）は Unit 003 で解除済み。design 必須セルは Step 3-6 まで完走（rc=0）し
#       Step 5 で reviews_path に perspective 別セクションを生成する（AI レビュー実行・反復・承認は非模擬 = approved 前提）
# 注: assert 経由で間接呼び出しされるため shellcheck からは未使用に見える。
# shellcheck disable=SC2329
run_develop() {
    local repo="$1" cycle="$2" depth="$3" tmpl="${4:-$DESIGN_TMPL}"
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
        # Step1-2 〜 1-4: §8 写像（decide_matrix）。判定は mutation を伴わない。
        # design 生成（Unit 002）で design_mode / risk_analysis / test_plan / rollback_note を消費する。
        local dec mcase d_req dmode ra tp rn r_req rmode rrec err
        dec="$(decide_matrix "$size" "$depth")"
        IFS='|' read -r mcase d_req dmode ra tp rn r_req rmode rrec err <<<"$dec"
        case "$err" in
            invalid_size) exit 23 ;;
            risky_minimal) exit 24 ;;
            none) ;;
            *) exit 22 ;;  # unknown_depth 等（実フローは解決契約で standard へ正規化済みのはず）
        esac
        # 成果物パス導出 + invalid_artifact_path(25)（design または review が必要なセルで実行 / status 遷移前 = 副作用なし）。
        # review_required=1 は現行 §8 上 design_required=1 を含意するが、将来 review 単独セルが追加されても
        # Step 5 で fname が未定義（set -u unbound）にならないよう d_req||r_req の共通ブロックで初期化する。
        local fname=""
        if [[ "$d_req" == "1" || "$r_req" == "1" ]]; then
            fname="$(basename "$path")"
            case "$fname" in "${id}-"*) ;; *) exit 25 ;; esac
        fi
        # design 必須セル（Unit 002）: design preflight(27) → status 遷移 → Step 2 design 生成。
        # 27 は status 遷移より前 = 副作用なし。design 生成は in_progress 化（副作用あり）。
        if [[ "$d_req" == "1" ]]; then
            # design preflight（status 遷移前 / テンプレート不在は副作用なし停止）
            [[ -f "$tmpl" ]] || exit 27
            # Step1-5: status 読取 + 遷移（pending→in_progress / resume は in_progress 維持）
            st="$("$WISTATUS" --read "$path" 2>/dev/null)" || exit 22
            st="${st#status:}"
            case "$st" in
                pending) "$WISTATUS" "$path" pending in_progress >/dev/null 2>&1 || exit 22 ;;
                in_progress) : ;;  # resume: 遷移せず継続
                *) exit 22 ;;
            esac
            # Step2: designs_path に design 生成（条件付きセクションをフラグ通り充足/省略）
            local designs_dir=".aidlc/cycles/$cycle/designs"
            mkdir -p "$designs_dir"
            {
                printf '# Design %s\n\n- matrix_case: %s\n- design_mode: %s\n\n' "$id" "$mcase" "$dmode"
                printf '## Goal\n\ng\n\n## Context\n\nc\n\n## Design\n\nd\n'
                [[ "$ra" == "1" ]] && printf '\n## Risk Analysis\n\nra\n'
                [[ "$tp" == "1" ]] && printf '\n## Test Plan\n\ntp\n'
                [[ "$rn" == "1" ]] && printf '\n## Rollback Note\n\nrollback steps\n'
            } > "$designs_dir/$fname"
            # Step2.2: Design 承認ゲートは harness では模擬しない（approved 前提）
            # Step2.3: review 境界ガードは Unit 003 で解除済み → Step 3 へ fall-through（design 必須セルも完走）。
            #          status は in_progress 化済みのため、以下共通パスの status 読取では in_progress（resume）扱いとなる。
        fi
        # design 不要セル（tiny_* / normal_minimal）= end-to-end 完走 / design 必須セル（Unit 003）も以下を完走
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
        # Step5: review routing 模擬（review_required=1 のみ / AI レビュー実行・反復・承認は非模擬 = approved 前提 / Unit 003）。
        #        fname は上の d_req||r_req 共通ブロックで初期化済み（review 単独セル将来追加時も set -u 安全）。
        #        decide_review_routing（単一の真実）の route に従い reviews_path に perspective 別セクション（status=complete
        #        マーカー区間）を生成する。冪等 upsert（complete スキップ / incomplete 置換）は実フロー責務 / 本模擬は初回生成を検証。
        if [[ "$r_req" == "1" ]]; then
            local reviews_dir=".aidlc/cycles/$cycle/reviews" routes route persp
            mkdir -p "$reviews_dir"
            routes="$(decide_review_routing "$rmode")"
            local oldifs="$IFS"; IFS=';'
            for route in $routes; do
                [[ -z "$route" ]] && continue
                persp="${route%%:*}"
                # 冪等 upsert（develop.md Step 5.3）。初回 develop はファイル不在 → 新規追加。
                upsert_review_section "$reviews_dir/$fname" "$persp" complete "review result for $id ($persp)"
            done
            IFS="$oldifs"
        fi
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

echo "== Unit 003: normal+standard → design 生成 + review(code) + 完走（rc=0 / done / reviews 生成） =="
r4="$TMPROOT/design-normal-std"; make_sandbox "$r4" v3.0.0-alpha.t
put_work_item "$r4/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 n pending normal ""
( cd "$r4" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r4" v3.0.0-alpha.t standard; rc=$?
assert_cond "normal+standard は Step 3-6 まで完走（rc=0 / 境界ガード解除）" "$([[ "$rc" == "0" ]] && echo 0 || echo 1)"
d4="$r4/.aidlc/cycles/v3.0.0-alpha.t/designs/001-n.md"
rv4="$r4/.aidlc/cycles/v3.0.0-alpha.t/reviews/001-n.md"
assert_cond "normal+standard で design 成果物が生成される" "$([[ -f "$d4" ]] && echo 0 || echo 1)"
assert_out "status:done" "normal+standard 完走後 status=done" -- "$WISTATUS" --read "$r4/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-n.md"
assert_cond "normal+standard で実装副作用あり（src/001.txt 生成 = Step 3 到達）" "$([[ -f "$r4/src/001.txt" ]] && echo 0 || echo 1)"
assert_cond "normal+standard は design_mode: simple" "$(grep -q 'design_mode: simple' "$d4" && echo 0 || echo 1)"
assert_cond "normal+standard(simple) は Risk Analysis を含まない" "$(grep -q '## Risk Analysis' "$d4" && echo 1 || echo 0)"
assert_cond "normal+standard は Test Plan を含まない" "$(grep -q '## Test Plan' "$d4" && echo 1 || echo 0)"
assert_cond "normal+standard は Rollback Note を含まない" "$(grep -q '## Rollback Note' "$d4" && echo 1 || echo 0)"
assert_cond "normal+standard は reviews/001-n.md を生成（Step 5）" "$([[ -f "$rv4" ]] && echo 0 || echo 1)"
assert_cond "normal+standard reviews は ## Code Review を含む" "$(grep -q '^## Code Review' "$rv4" && echo 0 || echo 1)"
assert_cond "normal+standard reviews は ## Design Review を含まない（code のみ）" "$(grep -q '^## Design Review' "$rv4" && echo 1 || echo 0)"
assert_cond "normal+standard reviews の code マーカーは行頭 + status=complete（検出は行頭完全一致契約）" "$(grep -q '^<!-- aidlc-review:code:start status=complete -->$' "$rv4" && echo 0 || echo 1)"
assert_cond "normal+standard reviews の code end マーカーが行頭に存在（区間 start-end 整合）" "$(grep -q '^<!-- aidlc-review:code:end -->$' "$rv4" && echo 0 || echo 1)"
grep -q '^- develop completed: 001$' "$r4/.aidlc/cycles/v3.0.0-alpha.t/journal.md"; assert_cond "normal+standard journal に完了追記" "$?"

echo "== Unit 003: resume された in_progress normal+standard → design + review + 完走（二重遷移なし） =="
r5="$TMPROOT/design-resume-normal"; make_sandbox "$r5" v3.0.0-alpha.t
put_work_item "$r5/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 rn in_progress normal ""
( cd "$r5" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r5" v3.0.0-alpha.t standard; rc=$?
assert_cond "resume normal+standard は完走（rc=0）" "$([[ "$rc" == "0" ]] && echo 0 || echo 1)"
assert_out "status:done" "resume normal+standard 完走後 status=done（二重遷移なし）" -- "$WISTATUS" --read "$r5/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-rn.md"
assert_cond "resume normal+standard で design 成果物が生成される" "$([[ -f "$r5/.aidlc/cycles/v3.0.0-alpha.t/designs/001-rn.md" ]] && echo 0 || echo 1)"
assert_cond "resume normal+standard で reviews 成果物が生成される" "$([[ -f "$r5/.aidlc/cycles/v3.0.0-alpha.t/reviews/001-rn.md" ]] && echo 0 || echo 1)"

echo "== Unit 003: risky+standard → design + rollback + review(code,security) + 完走（rc=0） =="
r4b="$TMPROOT/design-risky-std"; make_sandbox "$r4b" v3.0.0-alpha.t
put_work_item "$r4b/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 rk pending risky ""
( cd "$r4b" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r4b" v3.0.0-alpha.t standard; rc=$?
assert_cond "risky+standard は完走（rc=0）" "$([[ "$rc" == "0" ]] && echo 0 || echo 1)"
d4b="$r4b/.aidlc/cycles/v3.0.0-alpha.t/designs/001-rk.md"
rv4b="$r4b/.aidlc/cycles/v3.0.0-alpha.t/reviews/001-rk.md"
assert_out "status:done" "risky+standard 完走後 status=done" -- "$WISTATUS" --read "$r4b/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-rk.md"
assert_cond "risky+standard は design_mode: full" "$(grep -q 'design_mode: full' "$d4b" && echo 0 || echo 1)"
assert_cond "risky+standard は Rollback Note 見出しを含む" "$(grep -q '## Rollback Note' "$d4b" && echo 0 || echo 1)"
assert_cond "risky+standard の Rollback Note は非空（次見出しまでに非空行あり）" "$(section_nonempty "$d4b" '## Rollback Note'; echo $?)"
assert_cond "risky+standard は Risk Analysis を含まない" "$(grep -q '## Risk Analysis' "$d4b" && echo 1 || echo 0)"
assert_cond "risky+standard は Test Plan を含まない" "$(grep -q '## Test Plan' "$d4b" && echo 1 || echo 0)"
assert_cond "risky+standard reviews は ## Code Review を含む（code_security）" "$(grep -q '^## Code Review' "$rv4b" && echo 0 || echo 1)"
assert_cond "risky+standard reviews は ## Design Review を含まない（code_security は design なし）" "$(grep -q '^## Design Review' "$rv4b" && echo 1 || echo 0)"

echo "== Unit 003: resume された in_progress risky+standard → design + review + 完走 =="
r5b="$TMPROOT/design-resume-risky"; make_sandbox "$r5b" v3.0.0-alpha.t
put_work_item "$r5b/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 rrk in_progress risky ""
( cd "$r5b" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r5b" v3.0.0-alpha.t standard; rc=$?
assert_cond "resume risky+standard は完走（rc=0）" "$([[ "$rc" == "0" ]] && echo 0 || echo 1)"
assert_out "status:done" "resume risky+standard 完走後 status=done" -- "$WISTATUS" --read "$r5b/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-rrk.md"

echo "== Unit 003: normal+comprehensive → design + Risk Analysis + review(code) + 完走 =="
r4c="$TMPROOT/design-normal-comp"; make_sandbox "$r4c" v3.0.0-alpha.t
put_work_item "$r4c/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 nc pending normal ""
( cd "$r4c" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r4c" v3.0.0-alpha.t comprehensive; rc=$?
assert_cond "normal+comprehensive は完走（rc=0）" "$([[ "$rc" == "0" ]] && echo 0 || echo 1)"
d4c="$r4c/.aidlc/cycles/v3.0.0-alpha.t/designs/001-nc.md"
rv4c="$r4c/.aidlc/cycles/v3.0.0-alpha.t/reviews/001-nc.md"
assert_cond "normal+comprehensive は design_mode: full" "$(grep -q 'design_mode: full' "$d4c" && echo 0 || echo 1)"
assert_cond "normal+comprehensive は Risk Analysis を含む" "$(grep -q '## Risk Analysis' "$d4c" && echo 0 || echo 1)"
assert_cond "normal+comprehensive は Test Plan を含まない" "$(grep -q '## Test Plan' "$d4c" && echo 1 || echo 0)"
assert_cond "normal+comprehensive は Rollback Note を含まない" "$(grep -q '## Rollback Note' "$d4c" && echo 1 || echo 0)"
assert_cond "normal+comprehensive reviews は ## Code Review を含む（code）" "$(grep -q '^## Code Review' "$rv4c" && echo 0 || echo 1)"
assert_cond "normal+comprehensive reviews は ## Design Review を含まない" "$(grep -q '^## Design Review' "$rv4c" && echo 1 || echo 0)"

echo "== Unit 003: risky+comprehensive → design 全部 + review(code,security)+design + 完走 =="
r4d="$TMPROOT/design-risky-comp"; make_sandbox "$r4d" v3.0.0-alpha.t
put_work_item "$r4d/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 rc2 pending risky ""
( cd "$r4d" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r4d" v3.0.0-alpha.t comprehensive; rc=$?
assert_cond "risky+comprehensive は完走（rc=0）" "$([[ "$rc" == "0" ]] && echo 0 || echo 1)"
d4d="$r4d/.aidlc/cycles/v3.0.0-alpha.t/designs/001-rc2.md"
rv4d="$r4d/.aidlc/cycles/v3.0.0-alpha.t/reviews/001-rc2.md"
assert_cond "risky+comprehensive は Risk Analysis を含む" "$(grep -q '## Risk Analysis' "$d4d" && echo 0 || echo 1)"
assert_cond "risky+comprehensive は Test Plan を含む" "$(grep -q '## Test Plan' "$d4d" && echo 0 || echo 1)"
assert_cond "risky+comprehensive は Rollback Note を含む" "$(grep -q '## Rollback Note' "$d4d" && echo 0 || echo 1)"
assert_cond "risky+comprehensive の Rollback Note は非空" "$(section_nonempty "$d4d" '## Rollback Note'; echo $?)"
assert_cond "risky+comprehensive reviews は ## Code Review を含む（code_security_design）" "$(grep -q '^## Code Review' "$rv4d" && echo 0 || echo 1)"
assert_cond "risky+comprehensive reviews は ## Design Review を含む（code_security_design のみ design 追加）" "$(grep -q '^## Design Review' "$rv4d" && echo 0 || echo 1)"
assert_cond "risky+comprehensive の design マーカーは行頭 start + status=complete" "$(grep -q '^<!-- aidlc-review:design:start status=complete -->$' "$rv4d" && echo 0 || echo 1)"
assert_cond "risky+comprehensive の design end マーカーが行頭に存在（区間整合）" "$(grep -q '^<!-- aidlc-review:design:end -->$' "$rv4d" && echo 0 || echo 1)"

echo "== Unit 002: design テンプレート不在 → rc=27 副作用なし（status 未遷移 / design 未生成） =="
r4e="$TMPROOT/design-no-tmpl"; make_sandbox "$r4e" v3.0.0-alpha.t
put_work_item "$r4e/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 nt pending normal ""
( cd "$r4e" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
snap_before="$(snapshot "$r4e" v3.0.0-alpha.t)"
run_develop "$r4e" v3.0.0-alpha.t standard "$TMPROOT/no-such-design-template.md"; rc=$?
assert_cond "design テンプレート不在は停止コード 27" "$([[ "$rc" == "27" ]] && echo 0 || echo 1)"
assert_out "status:pending" "テンプレート不在時 status=pending（status 未遷移 / preflight）" -- "$WISTATUS" --read "$r4e/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-nt.md"
assert_cond "テンプレート不在時は design 未生成" "$([[ ! -f "$r4e/.aidlc/cycles/v3.0.0-alpha.t/designs/001-nt.md" ]] && echo 0 || echo 1)"
snap_after="$(snapshot "$r4e" v3.0.0-alpha.t)"
assert_cond "テンプレート不在で副作用なし（状態不変）" "$([[ "$snap_before" == "$snap_after" ]] && echo 0 || echo 1)"

echo "== Unit 001 e2e: normal+minimal → end-to-end 完走（design/review 不要） =="
r8="$TMPROOT/e2e-normal-minimal"; make_sandbox "$r8" v3.0.0-alpha.t
put_work_item "$r8/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 nm pending normal ""
( cd "$r8" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r8" v3.0.0-alpha.t minimal; assert_cond "normal+minimal 完走（rc=0）" "$?"
assert_out "status:done" "normal+minimal 完了後 status=done" -- "$WISTATUS" --read "$r8/.aidlc/cycles/v3.0.0-alpha.t/work-items/001-nm.md"
grep -q '^- develop completed: 001$' "$r8/.aidlc/cycles/v3.0.0-alpha.t/journal.md"; assert_cond "normal+minimal journal に完了追記" "$?"
assert_cond "normal+minimal は reviews 非生成（review_required=false）" "$([[ ! -d "$r8/.aidlc/cycles/v3.0.0-alpha.t/reviews" ]] && echo 0 || echo 1)"
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

echo "== review routing 写像（decide_review_routing / Unit 003 / develop.md Step 5.1 と一致） =="
# matrix_review_mode → route（perspective:focus:section）。code/code_security は同一 routing（code 複合スキル / security-only に縮約しない）、
# code_security_design のみ design route を追加。none は空、未知値は unknown（純粋写像 / 停止しない）。
assert_out "" "routing none → route なし（Step 5 スキップ）" -- decide_review_routing none
assert_out "code:code,security:## Code Review" "routing code → code review（focus code,security）" -- decide_review_routing code
assert_out "code:code,security:## Code Review" "routing code_security → code review（security 重点 / focus 同一 / security-only 非縮約）" -- decide_review_routing code_security
assert_out "code:code,security:## Code Review;design:architecture:## Design Review" "routing code_security_design → code + design review" -- decide_review_routing code_security_design
assert_out "unknown" "routing 未知値 → unknown（停止しない）" -- decide_review_routing bogus

echo "== Unit 003: reviews セクション冪等 upsert（complete 保持 / in_progress 置換 / 区間なし追加） =="
up="$TMPROOT/upsert"; mkdir -p "$up"
# 1. 区間なし → 新規追加
uf="$up/001-x.md"; : > "$uf"
upsert_review_section "$uf" code in_progress "first body"
assert_cond "upsert: 新規 code 区間が追加される（start 行頭）" "$(grep -q '^<!-- aidlc-review:code:start status=in_progress -->$' "$uf" && echo 0 || echo 1)"
assert_cond "upsert: 新規 code 区間に本文が入る" "$(grep -q '^first body$' "$uf" && echo 0 || echo 1)"
# 2. in_progress → 置換（complete 化 + 本文差し替え）
upsert_review_section "$uf" code complete "second body"
assert_cond "upsert: in_progress は置換され status=complete になる" "$(grep -q '^<!-- aidlc-review:code:start status=complete -->$' "$uf" && echo 0 || echo 1)"
assert_cond "upsert: 置換後は新本文" "$(grep -q '^second body$' "$uf" && echo 0 || echo 1)"
assert_cond "upsert: 置換後は旧本文を残さない" "$(grep -q '^first body$' "$uf" && echo 1 || echo 0)"
assert_cond "upsert: 置換後も code 区間は 1 つ（duplicate なし）" "$([[ "$(grep -c '^<!-- aidlc-review:code:start' "$uf")" == "1" ]] && echo 0 || echo 1)"
# 3. complete → スキップ（保持 / 再upsert で本文不変）
upsert_review_section "$uf" code complete "third body should be ignored"
assert_cond "upsert: complete は保持され再追記しない（本文不変）" "$(grep -q '^second body$' "$uf" && echo 0 || echo 1)"
assert_cond "upsert: complete スキップで third body は入らない" "$(grep -q 'third body' "$uf" && echo 1 || echo 0)"
# 4. 別 perspective（design）は独立に追加される
upsert_review_section "$uf" design complete "design body"
assert_cond "upsert: design 区間が独立に追加（code は保持）" "$(grep -q '^<!-- aidlc-review:design:start status=complete -->$' "$uf" && echo 0 || echo 1)"
assert_cond "upsert: code 区間は依然 1 つ（design 追加で増えない）" "$([[ "$(grep -c '^<!-- aidlc-review:code:start' "$uf")" == "1" ]] && echo 0 || echo 1)"

echo "== Unit 003: review_required=false（tiny_* / normal+minimal）は reviews 非生成 =="
r13="$TMPROOT/no-review-tiny"; make_sandbox "$r13" v3.0.0-alpha.t
put_work_item "$r13/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 nrt pending tiny ""
( cd "$r13" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
run_develop "$r13" v3.0.0-alpha.t standard; assert_cond "tiny+standard 完走（rc=0）" "$?"
assert_cond "tiny+standard は reviews ディレクトリ非生成（review_required=false）" "$([[ ! -d "$r13/.aidlc/cycles/v3.0.0-alpha.t/reviews" ]] && echo 0 || echo 1)"

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

# ---- Unit 004: §8 全マトリクス conformance（データ駆動 / run_develop 観測結果を §8 期待値ビューと照合） ----
# conformance_case <size> <depth> <exp_rc> <exp_status> <exp_design(0/1)> <exp_reviews(0/1)> <exp_persp(-/Code/Code+Design)>
#   run_develop を隔離 sandbox で実行し、観測 rc / status / design 生成有無 / reviews 生成有無 / perspective を assert。
#   期待値は docs/v3/data-model.md §8 / decide_matrix のビュー（テスト内で §8 を再判定しない / 二重定義回避）。
# 注: while ループから間接呼び出しされるため shellcheck からは未使用に見える。
# shellcheck disable=SC2329
conformance_case() {
    local size="$1" depth="$2" exp_rc="$3" exp_status="$4" exp_design="$5" exp_reviews="$6" exp_persp="$7"
    local slug="${size}-${depth}" repo="$TMPROOT/conf-${size}-${depth}"
    make_sandbox "$repo" v3.0.0-alpha.t
    put_work_item "$repo/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 "$slug" pending "$size" ""
    ( cd "$repo" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
    run_develop "$repo" v3.0.0-alpha.t "$depth"; local rc=$?
    local cbase="$repo/.aidlc/cycles/v3.0.0-alpha.t"
    assert_cond "[§8 $size+$depth] rc=$exp_rc" "$([[ "$rc" == "$exp_rc" ]] && echo 0 || echo 1)"
    local st; st="$("$WISTATUS" --read "$cbase/work-items/001-$slug.md" 2>/dev/null)"; st="${st#status:}"
    assert_cond "[§8 $size+$depth] status=$exp_status" "$([[ "$st" == "$exp_status" ]] && echo 0 || echo 1)"
    # design 生成有無
    if [[ "$exp_design" == "1" ]]; then
        assert_cond "[§8 $size+$depth] design 生成" "$([[ -f "$cbase/designs/001-$slug.md" ]] && echo 0 || echo 1)"
    else
        assert_cond "[§8 $size+$depth] design 非生成" "$([[ ! -f "$cbase/designs/001-$slug.md" ]] && echo 0 || echo 1)"
    fi
    # reviews 生成有無（非生成は reviews/ ディレクトリ不存在まで確認 = 空ディレクトリ副作用も検出 / 設計レビュー #1）
    if [[ "$exp_reviews" == "1" ]]; then
        local rf="$cbase/reviews/001-$slug.md"
        assert_cond "[§8 $size+$depth] reviews 生成" "$([[ -f "$rf" ]] && echo 0 || echo 1)"
        local has_code=1 has_design=1
        grep -q '^## Code Review' "$rf" 2>/dev/null || has_code=0
        grep -q '^## Design Review' "$rf" 2>/dev/null || has_design=0
        case "$exp_persp" in
            Code)        assert_cond "[§8 $size+$depth] reviews perspective=Code のみ" "$([[ "$has_code" == "1" && "$has_design" == "0" ]] && echo 0 || echo 1)" ;;
            Code+Design) assert_cond "[§8 $size+$depth] reviews perspective=Code+Design" "$([[ "$has_code" == "1" && "$has_design" == "1" ]] && echo 0 || echo 1)" ;;
        esac
    else
        assert_cond "[§8 $size+$depth] reviews ディレクトリ非生成" "$([[ ! -d "$cbase/reviews" ]] && echo 0 || echo 1)"
    fi
}

echo "== Unit 004: §8 全マトリクス conformance（全 8 有効 + risky_minimal / データ駆動） =="
# size depth exp_rc exp_status exp_design exp_reviews exp_persp（期待値は §8 / decide_matrix のビュー）
# c_overflow はテーブル破損検出用（8 列目以降が入ったら非空になる / コードレビュー #1）。
while read -r c_size c_depth c_rc c_status c_design c_reviews c_persp c_overflow; do
    [[ -z "$c_size" || "$c_size" == \#* ]] && continue
    # テーブル整合性: 必須 7 列ちょうど（余剰列なし / exp_persp 非空）+ perspective enum 整合
    assert_cond "[CONFTABLE $c_size+$c_depth] 行は 7 列ちょうど（余剰列なし / exp_persp 充足）" "$([[ -z "$c_overflow" && -n "$c_persp" ]] && echo 0 || echo 1)"
    # persp_ok: 0=整合（assert_cond の pass）/ 1=不整合（fail）
    persp_ok=0
    if [[ "$c_reviews" == "1" ]]; then
        [[ "$c_persp" == "Code" || "$c_persp" == "Code+Design" ]] || persp_ok=1
    else
        [[ "$c_persp" == "-" ]] || persp_ok=1
    fi
    assert_cond "[CONFTABLE $c_size+$c_depth] exp_persp enum 整合（reviews=${c_reviews}）" "$persp_ok"
    conformance_case "$c_size" "$c_depth" "$c_rc" "$c_status" "$c_design" "$c_reviews" "$c_persp"
done <<'CONFTABLE'
tiny minimal 0 done 0 0 -
tiny standard 0 done 0 0 -
tiny comprehensive 0 done 0 0 -
normal minimal 0 done 0 0 -
normal standard 0 done 1 1 Code
normal comprehensive 0 done 1 1 Code
risky standard 0 done 1 1 Code
risky comprehensive 0 done 1 1 Code+Design
risky minimal 24 pending 0 0 -
CONFTABLE

echo "== Unit 004: 外部レビュー CLI 非依存（poison PATH 回帰アンカー / 全 conformance 行を poison PATH 下で実行） =="
# 現状 run_develop は実 CLI 呼び出し経路を持たず review も upsert_review_section で模擬する。本ガードは
# 「模擬 run_develop が実 CLI に依存しない（将来 codex/claude/gemini 呼び出しがハーネスに混入したら検出する）」
# ことを保証する poison PATH 回帰アンカーである。スタブ・PATH 変更は TMPROOT sandbox に閉じ実行後に PATH を復元する。
poison_bin="$TMPROOT/poison-bin"; mkdir -p "$poison_bin"
poison_trace="$TMPROOT/poison-trace"
for cli in codex claude gemini; do
    {
        printf '#!/usr/bin/env bash\n'
        printf 'echo %s >> "%s"\n' "$cli" "$poison_trace"
        printf 'exit 0\n'
    } > "$poison_bin/$cli"
    chmod +x "$poison_bin/$cli"
done
saved_path="$PATH"
PATH="$poison_bin:$PATH"
while read -r p_size p_depth; do
    [[ -z "$p_size" || "$p_size" == \#* ]] && continue
    prepo="$TMPROOT/poison-${p_size}-${p_depth}"
    make_sandbox "$prepo" v3.0.0-alpha.t
    put_work_item "$prepo/.aidlc/cycles/v3.0.0-alpha.t/work-items" 001 "${p_size}-${p_depth}" pending "$p_size" ""
    ( cd "$prepo" && git add -A && git -c user.email=t@example.com -c user.name=t commit -q -m "init wi" )
    run_develop "$prepo" v3.0.0-alpha.t "$p_depth" >/dev/null 2>&1 || true
done <<'POISONTABLE'
tiny minimal
tiny standard
tiny comprehensive
normal minimal
normal standard
normal comprehensive
risky standard
risky comprehensive
risky minimal
POISONTABLE
PATH="$saved_path"
assert_cond "poison PATH 下の全 conformance 実行で実 CLI（codex/claude/gemini）未呼出（痕跡空）" "$([[ ! -s "$poison_trace" ]] && echo 0 || echo 1)"

echo ""
echo "== 結果 =="
echo "PASS=$PASS FAIL=$FAIL"
if [[ "$FAIL" -gt 0 ]]; then exit 1; fi
exit 0
