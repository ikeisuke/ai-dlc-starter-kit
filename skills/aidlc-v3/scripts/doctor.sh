#!/usr/bin/env bash
#
# doctor.sh - v3 環境の診断（11 領域 / 診断のみ・自動修正しない）
#
# v3 環境の 11 領域（config / state / cycle / work-items / git / gh / pr / phase /
# trace / scripts / parse-guard）を順に診断し、各領域の severity（OK / WARN / ERROR /
# SKIP）を stdout に表示する。最後に総合 exit code を導出して終了する。
#
# 本スクリプトは **診断のみ** を行う:
#   - state.json / work item / config を一切変更しない（read-only）。
#   - 問題を検出・案内するが自動修正はしない。
#
# 設計の正本:
#   .aidlc/cycles/<cycle>/design-artifacts/logical-designs/unit_003_doctor_v1_logical_design.md
#   .aidlc/cycles/<cycle>/design-artifacts/domain-models/unit_003_doctor_v1_domain_model.md
#
# Usage:
#   doctor.sh
#     カレントリポジトリの .aidlc/ を診断対象とする（引数なし / v1）。
#
# 領域別 wrap 契約（exit code → severity 写像）:
#   [config]      .aidlc/config.toml 不在→ERROR / read-config.sh rc0→OK / rc1→WARN /
#                 rc2 かつ config あり（dasel 不在）→診断不能(exit2)
#   [state]       state.json 不在→WARN（No active cycle）/ state-validate.sh stdout
#                 status:valid→OK / status:warn:*→WARN / rc1→ERROR / rc2→exit2
#   [cycle]       state なし→SKIP / current_cycle 取得 + dir 存在→OK / 取得不能・dir 不在→WARN
#   [work-items]  state なし→SKIP / cycle dir 不在→（[cycle] で WARN）/ work-items dir 不在→WARN /
#                 dir あり+0件→WARN / dir あり+1件以上+rc0→OK / rc1→ERROR / rc2→exit2
#   [git]         git status --porcelain clean→OK / dirty→WARN / repo 外→exit2
#   [gh]          gh auth status 認証→OK / 未認証・gh 不在→WARN（[pr] を skip）
#   [pr]          gh 不可→SKIP / open PR あり→OK（番号表示）/ 0件→OK（未作成）
#   [phase]       data-model §5.1 first-match 導出（complete→define→develop→release 可能）。
#                 state なし→OK（define フォールバック）/ work-items invalid→WARN /
#                 complete は merge_approved=true + pr_number 非 null + gh で PR merged 確認成功時のみ→OK /
#                 矛盾・確認不能（merge_approved×未 merged / define_completed 矛盾 等）→安全側導出 + WARN
#   [trace]       data-model §8 size×depth_level で design 要否判定 + designs/<id>-<slug>.md 存在確認。
#                 state/cycle/work-items 前提不足→SKIP / work-items invalid→WARN /
#                 design 欠落・risky×minimal・depth_level enum 外→WARN（exit 0 維持）/ 充足→OK
#   [scripts]     必須集合 全存在→OK / 欠落→ERROR
#   [parse-guard] check-frontmatter-parse-guard.sh rc0→OK / rc1→ERROR / rc2→exit2
#
# 総合 exit code（exit-code-convention.md 準拠 / 2 > 1 > 0 優先）:
#   2 = 診断不能（jq 欠落 / dasel 欠落で [config] 依存不足 / git repo 外）
#   1 = ERROR 領域あり（state 破損 / work-items 不正 / 必須スクリプト不在 / parse-guard 違反）
#   0 = OK / WARN / SKIP のみ（No active cycle / git dirty / gh 未認証 / schema warn 等）
#
set -uo pipefail

# --- パス解決（スクリプト配置基準 / cwd 非依存 / bash 3.2 互換） ---
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"        # skills/aidlc-v3/scripts
V3_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"                            # skills/aidlc-v3
SKILLS_ROOT="$(cd "$V3_DIR/.." && pwd)"                           # skills
REPO_ROOT_GUESS="$(cd "$SKILLS_ROOT/.." && pwd)"                  # リポジトリルート（配置基準の推定）
readonly SCRIPT_DIR V3_DIR SKILLS_ROOT REPO_ROOT_GUESS

readonly STATE_VALIDATE="$SCRIPT_DIR/state-validate.sh"
readonly STATE_READ="$SCRIPT_DIR/state-read.sh"
readonly WORK_ITEM_VALIDATE="$SCRIPT_DIR/work-item-validate.sh"
readonly READ_CONFIG="$SKILLS_ROOT/aidlc/scripts/read-config.sh"
readonly PARSE_GUARD="$REPO_ROOT_GUESS/bin/check-frontmatter-parse-guard.sh"

# 診断対象パス（カレントリポジトリの .aidlc/）。
readonly STATE_FILE=".aidlc/state.json"
readonly CONFIG_FILE=".aidlc/config.toml"

# [scripts] 必須集合（doctor v1 の正本 / SoT / domain-model ScriptPresenceChecker）。
# スキルベース scripts/ 相対の 8 件。
readonly REQUIRED_SCRIPTS=(
    "state-read.sh"
    "state-write.sh"
    "state-validate.sh"
    "state-init.sh"
    "work-item-next.sh"
    "work-item-validate.sh"
    "work-item-status.sh"
    "lib/frontmatter.sh"
)

# frontmatter パーサ（[phase]/[trace] が work item の status/size を新規パースせず読むために source）。
# 不在時は [scripts] が ERROR を出す。set -e 無効のため source 失敗しても継続し、[phase]/[trace]
# 側が declare -f fm_scalar で不在を検知して WARN に degrade する（新規 grep/sed 禁止規約: frontmatter.sh:24-30）。
# shellcheck source=lib/frontmatter.sh disable=SC1091
[[ -f "$SCRIPT_DIR/lib/frontmatter.sh" ]] && . "$SCRIPT_DIR/lib/frontmatter.sh"

# --- 総合 exit code 集計フラグ ---
HAS_UNDIAGNOSABLE=0   # 2 系（診断不能）
HAS_ERROR=0           # 1 系（バリデーションエラー）

err() { echo "$@" >&2; }

# 1 領域の診断行を整形して出力する。
#   report <name> <severity> [detail...]
report() {
    local name="$1"; shift
    local severity="$1"; shift
    local detail="$*"
    # 領域名は固定幅で揃える（[parse-guard] が最長 = 13 文字）。
    printf '%-14s%-6s%s\n' "[$name]" "$severity" "$detail"
}

# --- 前提: jq 存在確認（診断不能 / exit 2） ---
if ! command -v jq >/dev/null 2>&1; then
    err "error: jq が見つかりません。doctor は jq を必須とします（診断不能 / exit 2）。"
    err "       jq をインストールしてから再実行してください。"
    exit 2
fi

# ============================================================
# [config]
# ============================================================
diagnose_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        report config ERROR ".aidlc/config.toml が見つかりません（aidlc setup を実行してください）"
        HAS_ERROR=1
        return
    fi
    local rc=0
    "$READ_CONFIG" rules.depth_level.level >/dev/null 2>&1 || rc=$?
    case "$rc" in
        0) report config OK "rules.depth_level.level 取得 OK" ;;
        1) report config WARN "rules.depth_level.level が未設定（キー不在）" ;;
        *)
            # rc2: config.toml は存在するので dasel 不在 = 依存不足（診断不能）。
            report config ERROR "dasel が見つかりません（[config] 依存不足 / 診断不能）"
            HAS_UNDIAGNOSABLE=1
            ;;
    esac
}

# ============================================================
# [state]
# state.json 不在 → WARN。あり → state-validate.sh の stdout prefix で分岐
# （rc だけで判定しない: warn:* は rc0 のため）。
# 戻り値で「state あり/なし」を後続領域へ伝える: 0=state あり / 1=state なし。
# ============================================================
STATE_PRESENT=0
diagnose_state() {
    if [[ ! -f "$STATE_FILE" ]]; then
        report state WARN "No active cycle（/aidlc-v3 define で開始）"
        STATE_PRESENT=0
        return
    fi
    STATE_PRESENT=1
    local out rc=0
    out="$("$STATE_VALIDATE" "$STATE_FILE" 2>/dev/null)" || rc=$?
    if [[ "$rc" -eq 2 ]]; then
        report state ERROR "state.json の検証で読み取りエラー（jq 不在 等 / 診断不能）"
        HAS_UNDIAGNOSABLE=1
        return
    fi
    case "$out" in
        status:valid)
            report state OK "state.json は valid"
            ;;
        status:warn:*)
            report state WARN "未対応 schema_version（migration / 手動対応が必要 / data-model.md §6）"
            ;;
        *)
            # rc1（破損 / schema 不正）または想定外出力。
            report state ERROR "state.json が破損または schema 不正（修正してから再実行してください）"
            HAS_ERROR=1
            ;;
    esac
}

# ============================================================
# [cycle]
# state なし → SKIP。current_cycle 取得 + .aidlc/cycles/<cycle> dir 存在 → OK。
# 戻り値経由で cycle dir を後続 [work-items] へ伝える。
# ============================================================
CYCLE_DIR=""
diagnose_cycle() {
    if [[ "$STATE_PRESENT" -eq 0 ]]; then
        report cycle SKIP "（state なし）"
        CYCLE_DIR=""
        return
    fi
    local cycle rc=0
    cycle="$("$STATE_READ" current_cycle "$STATE_FILE" 2>/dev/null)" || rc=$?
    if [[ "$rc" -ne 0 || -z "$cycle" ]]; then
        report cycle WARN "current_cycle を取得できません（state.json を確認してください）"
        CYCLE_DIR=""
        return
    fi
    # cycle identifier の安全検証（state-validate.sh は string としか検証しないため、
    # パストラバーサル `..` / `/` / 制御文字・空白・単独 `.` を含む値で診断境界が
    # .aidlc/cycles/<cycle> から外れる・コンテナ自体を指すのを防ぐ）。
    # state-init.sh と同じ「先頭は英数、以降 英数 . _ -」+ `..` 禁止を適用する。
    if [[ "$cycle" == *..* || ! "$cycle" =~ ^[A-Za-z0-9][A-Za-z0-9._-]*$ ]]; then
        report cycle WARN "current_cycle が不正な識別子です（パス安全でない値 / state.json を確認してください）"
        CYCLE_DIR=""
        return
    fi
    local dir=".aidlc/cycles/$cycle"
    if [[ -d "$dir" ]]; then
        report cycle OK "$cycle"
        CYCLE_DIR="$dir"
    else
        report cycle WARN "cycle ディレクトリが見つかりません: $dir"
        CYCLE_DIR=""
    fi
}

# ============================================================
# [work-items]
# 前提ゲート（state・cycle・dir）を doctor 側で判定してから validator を呼ぶ。
# dir 不在・0件は validator に渡さず WARN にする（validator はそれを rc1 にするため）。
# ERROR（rc1/rc2）時は WORK_ITEMS_INVALID=1 を立て、後段 [phase]/[trace] のゲートに使う。
# ============================================================
WORK_ITEMS_INVALID=0
diagnose_work_items() {
    if [[ "$STATE_PRESENT" -eq 0 ]]; then
        report work-items SKIP "（state なし / define 前）"
        return
    fi
    if [[ -z "$CYCLE_DIR" ]]; then
        # cycle dir 不在は [cycle] が WARN 済み。work-items は前提を満たさないため SKIP。
        report work-items SKIP "（cycle ディレクトリ未解決）"
        return
    fi
    local wi_dir="$CYCLE_DIR/work-items"
    if [[ ! -d "$wi_dir" ]]; then
        report work-items WARN "work-items ディレクトリが未作成（/aidlc-v3 define 前）"
        return
    fi
    # 0 件は WARN（validator に渡すと rc1 になるため doctor 側ゲート）。
    local count=0 f
    shopt -s nullglob
    local md_files=("$wi_dir"/*.md)
    shopt -u nullglob
    for f in "${md_files[@]}"; do
        [[ -e "$f" ]] && count=$((count + 1))
    done
    if [[ "$count" -eq 0 ]]; then
        report work-items WARN "work item が 0 件（define 前）"
        return
    fi
    local rc=0
    "$WORK_ITEM_VALIDATE" "$wi_dir" >/dev/null 2>&1 || rc=$?
    case "$rc" in
        0) report work-items OK "$count item(s) valid" ;;
        1)
            report work-items ERROR "work item の検証に失敗（schema 違反 / 詳細は work-item-validate.sh を直接実行）"
            HAS_ERROR=1
            WORK_ITEMS_INVALID=1
            ;;
        *)
            report work-items ERROR "work-items ディレクトリ読み取りエラー（診断不能）"
            HAS_UNDIAGNOSABLE=1
            WORK_ITEMS_INVALID=1
            ;;
    esac
}

# ============================================================
# [git]
# git status --porcelain clean → OK / dirty → WARN / repo 外 → exit2（診断不能）。
# ============================================================
diagnose_git() {
    if ! command -v git >/dev/null 2>&1; then
        report git ERROR "git が見つかりません（診断不能）"
        HAS_UNDIAGNOSABLE=1
        return
    fi
    local out rc=0
    out="$(git status --porcelain 2>/dev/null)" || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        report git ERROR "git リポジトリ外です（診断不能）"
        HAS_UNDIAGNOSABLE=1
        return
    fi
    if [[ -z "$out" ]]; then
        report git OK "clean"
    else
        report git WARN "未コミットの変更があります（commit / stash を検討）"
    fi
}

# ============================================================
# [gh]
# gh auth status 認証 → OK / 未認証・gh 不在 → WARN（[pr] を skip）。
# 戻り値で gh 可用性を [pr] へ伝える。
# ============================================================
GH_AVAILABLE=0
diagnose_gh() {
    if ! command -v gh >/dev/null 2>&1; then
        report gh WARN "gh が見つかりません（[pr] を skip）"
        GH_AVAILABLE=0
        return
    fi
    local rc=0
    gh auth status >/dev/null 2>&1 || rc=$?
    if [[ "$rc" -eq 0 ]]; then
        report gh OK "認証済み"
        GH_AVAILABLE=1
    else
        report gh WARN "未認証（gh auth status を確認 / [pr] を skip）"
        GH_AVAILABLE=0
    fi
}

# ============================================================
# [pr]
# gh 不可 → SKIP / open PR あり → OK（番号表示）/ 0件 → OK（未作成）。
# ============================================================
diagnose_pr() {
    if [[ "$GH_AVAILABLE" -eq 0 ]]; then
        report pr SKIP "（gh 不可用）"
        return
    fi
    local out rc=0
    out="$(gh pr list --state open --json number --jq 'map(.number) | join(", ")' 2>/dev/null)" || rc=$?
    if [[ "$rc" -ne 0 ]]; then
        # gh は認証済みだが list に失敗（リポジトリ未紐付け 等）。診断は継続（WARN）。
        report pr WARN "open PR を取得できません（リポジトリ未紐付け 等）"
        return
    fi
    if [[ -n "$out" ]]; then
        report pr OK "open PR: #$out"
    else
        report pr OK "open PR なし（未作成）"
    fi
}

# ============================================================
# [phase]
# data-model.md §5.1 の first-match 導出（complete → define → develop → release 可能）。
# 前段の STATE_PRESENT / CYCLE_DIR / WORK_ITEMS_INVALID / GH_AVAILABLE を参照する。
# read-only。complete は merge_approved=true + pr_number 非 null + gh で PR merged 確認成功時のみ。
# 矛盾・確認不能は安全側（define/develop 継続側）に倒して WARN（§6）。ERROR/診断不能は立てない。
# ============================================================
diagnose_phase() {
    if ! declare -f fm_scalar >/dev/null 2>&1; then
        report phase WARN "lib/frontmatter.sh 不在のため phase 判定不能"
        return
    fi
    # work-items invalid ゲート（壊れた入力で導出しない）。
    if [[ "$WORK_ITEMS_INVALID" -eq 1 ]]; then
        report phase WARN "work item が invalid のため phase 導出不能（[work-items] を解消してください）"
        return
    fi
    # state 不在 → define フォールバック（§5.1 評価順 2 / §6）。
    if [[ "$STATE_PRESENT" -eq 0 ]]; then
        report phase OK "define（state.json 不在 → define フォールバック）"
        return
    fi
    # state フィールド取得（read-only / 欠落は空文字扱い = 安全側）。
    local define_completed merge_approved pr_number warn_note=""
    define_completed="$("$STATE_READ" define_completed "$STATE_FILE" 2>/dev/null)" || define_completed=""
    merge_approved="$("$STATE_READ" release.merge_approved "$STATE_FILE" 2>/dev/null)" || merge_approved=""
    pr_number="$("$STATE_READ" release.pr_number "$STATE_FILE" 2>/dev/null)" || pr_number=""

    # work item status 集合の走査（done / withdrawn 以外を open とみなす）。
    local has_open=0 has_done=0 wi_count=0
    if [[ -n "$CYCLE_DIR" && -d "$CYCLE_DIR/work-items" ]]; then
        shopt -s nullglob
        local wi_files=("$CYCLE_DIR"/work-items/*.md)
        shopt -u nullglob
        local f fm st
        for f in "${wi_files[@]}"; do
            [[ -e "$f" ]] || continue
            wi_count=$((wi_count + 1))
            fm="$(fm_extract_block "$f")" || continue
            st="$(fm_scalar "$fm" status)" || st=""
            case "$st" in
                done) has_done=1 ;;
                withdrawn|"") : ;;
                *) has_open=1 ;;
            esac
        done
    fi

    # 評価順 1: complete（merge_approved=true + pr_number が正整数 + PR merged 確認成功）。
    # pr_number は既知 schema では integer/null だが、doctor は state 破損時も継続するため gh へ
    # 渡す前に正整数を必須検証する（gh 引数注入余地の排除 / 不一致は complete 非導出 + WARN）。
    if [[ "$merge_approved" == "true" ]]; then
        if [[ "$pr_number" =~ ^[1-9][0-9]*$ && "$GH_AVAILABLE" -eq 1 ]]; then
            local merged
            merged="$(gh pr view "$pr_number" --json merged --jq '.merged' 2>/dev/null)" || merged=""
            if [[ "$merged" == "true" ]]; then
                report phase OK "complete（merge_approved=true + PR #${pr_number} merged）"
                return
            fi
        fi
        # complete 非導出（§6）。実フェーズを導出しつつ WARN 併記。
        warn_note="merge_approved=true だが PR merged 未確認（pr_number 非正整数/gh 不可/未 merged）"
    fi

    # 評価順 2: define（define_completed != true / 取得不能）。
    if [[ "$define_completed" != "true" ]]; then
        if [[ "$has_done" -eq 1 ]]; then
            report phase WARN "矛盾: define_completed!=true だが done の work item あり → 安全側 define 継続（§6）"
            return
        fi
        if [[ -z "$define_completed" ]]; then
            report phase WARN "define（define_completed 取得不能 → 安全側 define）"
            return
        fi
        if [[ -n "$warn_note" ]]; then
            report phase WARN "define（${warn_note}）"
        else
            report phase OK "define"
        fi
        return
    fi

    # define_completed == true。
    # work item 集合を確認できない（cycle dir 未解決 / work-items 未作成 / 0 件）のに
    # define_completed=true は矛盾。work item 全件を確認できない状態を release 可能扱いしない（§6 安全側）。
    if [[ "$wi_count" -eq 0 ]]; then
        report phase WARN "矛盾: define_completed=true だが work item を確認できず（0 件 / 未解決）→ phase 導出不能（[work-items] を確認 / §6）"
        return
    fi
    # 評価順 3: develop（done/withdrawn 以外の work item がある）。
    if [[ "$has_open" -eq 1 ]]; then
        if [[ -n "$warn_note" ]]; then
            report phase WARN "develop（${warn_note}）"
        else
            report phase OK "develop"
        fi
        return
    fi
    # 評価順 4: release 可能（全 work item が done/withdrawn）。
    if [[ -n "$warn_note" ]]; then
        report phase WARN "release 可能（${warn_note}）"
    else
        report phase OK "release 可能"
    fi
}

# ============================================================
# [trace]
# data-model.md §8 の size×depth_level マトリクスで design 要否を判定し、design 必須 work item に
# 対応する designs/<id>-<slug>.md の存在を確認する（read-only）。
# 欠落 / risky×minimal / depth_level enum 外は WARN（exit 0 維持）。ERROR/診断不能は立てない。
# size enum 不正は上流 work-item-validate が ERROR 化 → WORK_ITEMS_INVALID ゲートで捕捉済み。
# ============================================================
diagnose_trace() {
    if ! declare -f fm_scalar >/dev/null 2>&1; then
        report trace WARN "lib/frontmatter.sh 不在のため trace 判定不能"
        return
    fi
    if [[ "$STATE_PRESENT" -eq 0 ]]; then
        report trace SKIP "（state なし）"
        return
    fi
    if [[ -z "$CYCLE_DIR" ]]; then
        report trace SKIP "（cycle ディレクトリ未解決）"
        return
    fi
    if [[ "$WORK_ITEMS_INVALID" -eq 1 ]]; then
        report trace WARN "work item が invalid のため trace 判定不能（[work-items] を解消してください）"
        return
    fi
    local wi_dir="$CYCLE_DIR/work-items"
    if [[ ! -d "$wi_dir" ]]; then
        report trace SKIP "（work-items 未作成）"
        return
    fi
    shopt -s nullglob
    local wi_files=("$wi_dir"/*.md)
    shopt -u nullglob
    if [[ "${#wi_files[@]}" -eq 0 ]]; then
        report trace SKIP "（work item 0 件）"
        return
    fi
    # depth_level 取得（rc1/rc2 → standard フォールバック / enum 外 → standard + WARN）。
    local depth rc=0 warn_depth=0
    depth="$("$READ_CONFIG" rules.depth_level.level 2>/dev/null)" || rc=$?
    if [[ "$rc" -ne 0 || -z "$depth" ]]; then
        depth="standard"
    fi
    case "$depth" in
        minimal|standard|comprehensive) ;;
        *) warn_depth=1; depth="standard" ;;
    esac
    # 各 work item の design 要否判定（design ファイルは work item と同じ basename）。
    local designs_dir="$CYCLE_DIR/designs"
    local f base fm size required invalid_combo checked=0
    local missing_list="" invalid_list=""
    for f in "${wi_files[@]}"; do
        [[ -e "$f" ]] || continue
        checked=$((checked + 1))
        base="$(basename "$f")"
        fm="$(fm_extract_block "$f")" || continue
        size="$(fm_scalar "$fm" size)" || size=""
        required=0
        invalid_combo=0
        case "$size" in
            risky)
                if [[ "$depth" == "minimal" ]]; then invalid_combo=1; else required=1; fi
                ;;
            normal)
                if [[ "$depth" == "standard" || "$depth" == "comprehensive" ]]; then required=1; fi
                ;;
            *) : ;;  # tiny は design 不要 / size は上流 gate で valid 前提
        esac
        if [[ "$invalid_combo" -eq 1 ]]; then
            invalid_list="$invalid_list $base"
        elif [[ "$required" -eq 1 && ! -f "$designs_dir/$base" ]]; then
            missing_list="$missing_list $base"
        fi
    done
    if [[ -n "$missing_list" || -n "$invalid_list" || "$warn_depth" -eq 1 ]]; then
        local detail="design 整合 WARN:"
        [[ -n "$missing_list" ]] && detail="$detail design 欠落[${missing_list# }]"
        [[ -n "$invalid_list" ]] && detail="$detail risky×minimal[${invalid_list# }]"
        [[ "$warn_depth" -eq 1 ]] && detail="$detail depth_level enum 外→standard"
        report trace WARN "$detail"
    else
        report trace OK "design 要否充足（${checked} item(s)）"
    fi
}

# ============================================================
# [scripts]
# 必須集合の存在確認。全存在 → OK / 欠落 → ERROR。
# ============================================================
diagnose_scripts() {
    local missing=() s present=0 total=0
    for s in "${REQUIRED_SCRIPTS[@]}"; do
        total=$((total + 1))
        if [[ -f "$SCRIPT_DIR/$s" ]]; then
            present=$((present + 1))
        else
            missing+=("$s")
        fi
    done
    if [[ "${#missing[@]}" -eq 0 ]]; then
        report scripts OK "$present/$total present"
    else
        report scripts ERROR "$present/$total present（欠落: ${missing[*]}）"
        HAS_ERROR=1
    fi
}

# ============================================================
# [parse-guard]
# check-frontmatter-parse-guard.sh rc0 → OK / rc1 → ERROR / rc2 → exit2。
# ============================================================
diagnose_parse_guard() {
    if [[ ! -f "$PARSE_GUARD" ]]; then
        # ガードスクリプト自体が無い（consumer プロジェクト 等）→ SKIP（診断対象外）。
        report parse-guard SKIP "（check-frontmatter-parse-guard.sh 不在）"
        return
    fi
    local rc=0
    "$PARSE_GUARD" >/dev/null 2>&1 || rc=$?
    case "$rc" in
        0) report parse-guard OK "違反なし" ;;
        1)
            report parse-guard ERROR "frontmatter パース禁止パターンを検出（bin/check-frontmatter-parse-guard.sh を実行）"
            HAS_ERROR=1
            ;;
        *)
            report parse-guard ERROR "parse-guard 実行エラー（git repo 外 等 / 診断不能）"
            HAS_UNDIAGNOSABLE=1
            ;;
    esac
}

# --- 11 領域を順に診断 ---
# [phase] は complete 確認で GH_AVAILABLE を参照するため diagnose_gh/diagnose_pr の後に配置する。
diagnose_config
diagnose_state
diagnose_cycle
diagnose_work_items
diagnose_git
diagnose_gh
diagnose_pr
diagnose_phase
diagnose_trace
diagnose_scripts
diagnose_parse_guard

# --- ExitCodeResolver: 総合 exit code（2 > 1 > 0 優先） ---
if [[ "$HAS_UNDIAGNOSABLE" -eq 1 ]]; then
    exit 2
fi
if [[ "$HAS_ERROR" -eq 1 ]]; then
    exit 1
fi
exit 0
