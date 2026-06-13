#!/usr/bin/env bash
#
# work-item-next.sh - select the next actionable work item by dependency resolution
#
# work-items ディレクトリ内の全 work item（*.md）の frontmatter（status / size /
# dependencies）を走査し、docs/v3/data-model.md §5.2 の依存解決規則 + resume 優先方針で
# 次に着手すべき work item を決定論的に 1 件選定する読み取り専用スクリプト。
# develop フロー（Unit 003）の Step 1（work item 選定）が本スクリプトの出力を消費する。
# 状態（state.json / work item frontmatter）は一切変更しない。
#
# 選定規則（data-model §5.2 + 設計 D2）:
#   1. resume 優先: status が in_progress の work item があれば最小 id を返す（中断再開）。
#      複数 in_progress は異常として WARN（stderr）を出しつつ最小 id を返す。
#   2. 新規候補: in_progress が無ければ、status が pending かつ全 dependencies が done の
#      work item を候補とする。
#      - 非 done 依存（pending/in_progress/blocked）を持つ pending は候補外。
#      - withdrawn 依存は done と異なり自動充足しない（§5.2）→ 候補外（blocked 相当）。
#      - 不在 dependency ID 参照は WARN（stderr）+ 当該 item を候補外。
#   3. 複数候補は id 昇順で先頭 1 件（決定的選定）。
#
# 注: 新規着手候補の対象 status は pending のみ。in_progress は resume 候補。
#     done / withdrawn / blocked は新規候補から除外。
#
# Usage:
#   work-item-next.sh <work-items-dir>
#
# 出力（stdout）:
#   選定あり : next:<id>:<size>:<path>
#              <path> = <work-items-dir 引数>/<filename>（呼び出し時 cwd 基準 /
#              スクリプトは正規化・絶対化しない。引数が絶対パスなら出力も絶対）
#   候補なし : next:none
#   WARN     : stderr に warning:...（stdout は汚さない）
#
# 終了コード（AI-DLC 終了コード規約準拠 / 既存 state-*.sh・work-item-validate.sh と一致）:
#   0 = 正常（選定あり / 候補なし next:none の両方。候補なしはエラーにしない）
#   1 = 入力エラー（引数不足 / ディレクトリ不在 / work item 0 件）
#   2 = システムエラー（ディレクトリ読み取り不可 等）
#
set -euo pipefail

err() { echo "$@" >&2; }

# id_lt <a> <b> : id a が b より小さければ return 0。
#   両者が数字のみなら数値昇順（10#... で先頭ゼロを base-10 として解釈 / 001 < 010 < 100）、
#   それ以外は文字列昇順（フォールバック）。glob 辞書順に依存せず「id 昇順」を一意化する
#   （data-model の id は 3 桁ゼロ埋め推奨だが必須でないため、2 < 10 を正しく扱う）。
id_lt() {
    local _idlt_a="$1" _idlt_b="$2"
    if [[ "$_idlt_a" =~ ^[0-9]+$ && "$_idlt_b" =~ ^[0-9]+$ ]]; then
        (( 10#$_idlt_a < 10#$_idlt_b ))
    else
        [[ "$_idlt_a" < "$_idlt_b" ]]
    fi
}

# wi_scalar <frontmatter> <key> : スカラー値を抽出して stdout 出力。
#   inline コメント・前後空白を除去。両端引用符付きなら外側を剥がす。
#   （next は validate 済み work-items を入力前提とするため最小限の抽出）
#   dynamic scope shadowing 回避のため内部 local は _wis_ プレフィックスで namespace 化。
wi_scalar() {
    local _wis_fm="$1" _wis_key="$2" _wis_line _wis_val
    _wis_line="$(echo "$_wis_fm" | grep -E "^${_wis_key}:" | head -n1)"
    _wis_val="$(echo "$_wis_line" | sed -nE "s/^${_wis_key}:[[:space:]]*([^#]*[^#[:space:]])[[:space:]]*(#.*)?\$/\1/p")"
    if [[ "$_wis_val" == \"*\" ]]; then
        _wis_val="${_wis_val#\"}"; _wis_val="${_wis_val%\"}"
    fi
    printf '%s' "$_wis_val"
}

# wi_deps <frontmatter> : dependencies 配列の ID を空白区切りで stdout 出力（空配列は空）。
wi_deps() {
    local _wid_fm="$1" _wid_line _wid_inner
    _wid_line="$(echo "$_wid_fm" | grep -E '^dependencies:' | head -n1)"
    _wid_inner="$(echo "$_wid_line" | sed -nE 's/^dependencies:[[:space:]]*\[([^]]*)\].*/\1/p')"
    echo "$_wid_inner" | grep -oE '[0-9A-Za-z]+' | tr '\n' ' ' || true
}

# --- 引数チェック ---
if [[ $# -lt 1 ]]; then
    err "error: work-items directory is required"
    err "usage: work-item-next.sh <work-items-dir>"
    exit 1
fi

dir="$1"

if [[ ! -d "$dir" ]]; then
    err "invalid: work-items directory not found: $dir"
    exit 1
fi
if [[ ! -r "$dir" || ! -x "$dir" ]]; then
    err "error: work-items directory not readable: $dir"
    exit 2
fi

# --- work item の収集 ---
shopt -s nullglob
files=("$dir"/*.md)
shopt -u nullglob

if [[ "${#files[@]}" -eq 0 ]]; then
    err "invalid: no work items found in $dir"
    exit 1
fi

# 並列インデックス配列（macOS bash 3.2 互換: 連想配列を使わない）。
# glob 展開は辞書順ソート済みのため、配列順 = id 昇順（ゼロ埋め id 前提）。
declare -a ids=() statuses=() sizes=() deps_list=() paths=()
for f in "${files[@]}"; do
    if [[ ! -r "$f" ]]; then
        err "error: work item not readable: $f"
        exit 2
    fi
    base="$(basename "$f" .md)"
    fm="$(awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f{print}' "$f")"
    ids+=("${base%%-*}")
    statuses+=("$(wi_scalar "$fm" status)")
    sizes+=("$(wi_scalar "$fm" size)")
    deps_list+=("$(wi_deps "$fm")")
    paths+=("$dir/$base.md")
done

# status_of_id <id> : 該当 id の status を stdout 出力（不在は return 1）。
status_of_id() {
    local _soi_needle="$1" _soi_i
    for _soi_i in "${!ids[@]}"; do
        if [[ "${ids[$_soi_i]}" == "$_soi_needle" ]]; then
            printf '%s' "${statuses[$_soi_i]}"
            return 0
        fi
    done
    return 1
}

# --- resume 優先（D2）: in_progress があれば最小 id を返す（id_lt で数値昇順） ---
ip_count=0
ip_sel=-1
for i in "${!ids[@]}"; do
    [[ "${statuses[$i]}" == "in_progress" ]] || continue
    ip_count=$((ip_count + 1))
    if [[ "$ip_sel" -lt 0 ]] || id_lt "${ids[$i]}" "${ids[$ip_sel]}"; then
        ip_sel="$i"
    fi
done
if [[ "$ip_count" -ge 1 ]]; then
    if [[ "$ip_count" -ge 2 ]]; then
        err "warning: multiple in_progress work items (anomaly)"
    fi
    echo "next:${ids[$ip_sel]}:${sizes[$ip_sel]}:${paths[$ip_sel]}"
    exit 0
fi

# --- 新規候補（pending + 全依存 done）から最小 id を返す（id_lt / glob 順非依存） ---
sel=-1
for i in "${!ids[@]}"; do
    [[ "${statuses[$i]}" == "pending" ]] || continue
    ok=1
    for dep in ${deps_list[$i]}; do
        if ! depst="$(status_of_id "$dep")"; then
            err "warning: dependency '$dep' not found (in ${ids[$i]})"
            ok=0
            break
        fi
        if [[ "$depst" != "done" ]]; then
            ok=0
            break
        fi
    done
    if [[ "$ok" == "1" ]]; then
        if [[ "$sel" -lt 0 ]] || id_lt "${ids[$i]}" "${ids[$sel]}"; then
            sel="$i"
        fi
    fi
done
if [[ "$sel" -ge 0 ]]; then
    echo "next:${ids[$sel]}:${sizes[$sel]}:${paths[$sel]}"
    exit 0
fi

echo "next:none"
exit 0
