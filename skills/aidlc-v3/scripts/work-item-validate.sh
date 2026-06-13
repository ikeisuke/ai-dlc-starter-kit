#!/usr/bin/env bash
#
# work-item-validate.sh - validate work item *.md files against docs/v3/data-model.md §4
#
# 指定ディレクトリ内の全 work item（*.md）が data-model §4 の schema に適合するかを
# 検証する（読み取り専用 / 状態は変更しない）。define Step 4-2 の検証ゲート実体であり、
# 後続フェーズ（develop / doctor）からも再利用できる。state-validate.sh が state.json を
# 検証するのと対称な、work item frontmatter / 本文の schema validator。
#
# 検証項目（data-model §4）:
#   - frontmatter 必須 6 キー（id / status / size / risk / assigned / dependencies）
#   - enum 値域（status / size / risk）※値トークン完全一致（prefix 偽陽性を排除）
#   - assigned の型（string or null / 配列・マップ・空値は違反）
#   - dependencies の型（array 形式 [...] 必須 / 非配列・壊れた配列は違反）
#   - id とファイル名（<id>-<slug>.md の <id> 部）の整合
#   - 本文必須 6 セクション（Goal / Scope / Acceptance Criteria / Traceability / Size / Risk / Dependencies）
#   - dependencies が実在する work item ID のみを参照（§6 trace 整合）
#   - [任意] expected_status 指定時、全 work item の status がその値であること（define 初期値 pending 用）
#
# Usage:
#   work-item-validate.sh <work-items-dir> [expected_status]
#     work-items-dir : work item *.md を格納するディレクトリ
#     expected_status: 指定時、全 work item の status がこの値であることを追加検証
#                      （define Step 4-2 では "pending" を渡す）
#
# 終了コード（AI-DLC 終了コード規約準拠 / state-*.sh と一致）:
#   0 = 全 work item が valid（status:valid）
#   1 = バリデーションエラー（引数不足 / ディレクトリ不在 / work item 0 件 /
#       必須キー欠落 / enum 不正 / id 不整合 / 必須セクション欠落 / 依存先不在 / status 不一致）
#   2 = システムエラー（ディレクトリ読み取り不可 等）
#
set -euo pipefail

readonly STATUS_ENUM='pending in_progress blocked done withdrawn'
readonly SIZE_ENUM='tiny normal risky'
readonly RISK_ENUM='low medium high'
readonly -a REQUIRED_SECTIONS=("Goal" "Scope" "Acceptance Criteria" "Traceability" "Size / Risk" "Dependencies")

err() { echo "$@" >&2; }

# in_list <value> <space-separated-list> : value がリストに含まれれば 0
in_list() {
    local needle="$1" item
    for item in $2; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# read_scalar <frontmatter> <key> <token-atom> : frontmatter から key のスカラー値を抽出して stdout 出力。
#   token-atom は ERE の単一アトム（ブラケット式 / 例 '[A-Za-z_]'・'[^"#[:space:]]'）。1 個以上の繰り返しが
#   トークン全体に一致することを要求する。値は「引用符なし or 両端引用符付き」のみ許容し、
#   片側だけの引用符（"pending / pending"）・空値・余分な記号は return 1（呼び出し側で exit 1 にする）。
#   inline コメント（# ...）・前後空白は除去する。外側の引用符のみ剥がして返す。
#   dynamic scope shadowing 回避のため内部 local は _rs_ プレフィックスで namespace 化する。
read_scalar() {
    local _rs_fm="$1" _rs_key="$2" _rs_class="$3" _rs_line _rs_val _rs_re
    _rs_line="$(echo "$_rs_fm" | grep -E "^${_rs_key}:" | head -n1)"
    _rs_val="$(echo "$_rs_line" | sed -nE "s/^${_rs_key}:[[:space:]]*([^#]*[^#[:space:]])[[:space:]]*(#.*)?\$/\1/p")"
    _rs_re="^(${_rs_class}+|\"${_rs_class}+\")$"
    [[ "$_rs_val" =~ $_rs_re ]] || return 1
    _rs_val="${_rs_val#\"}"; _rs_val="${_rs_val%\"}"
    printf '%s' "$_rs_val"
    return 0
}

# --- 引数チェック ---
if [[ $# -lt 1 ]]; then
    err "error: work-items directory is required"
    err "usage: work-item-validate.sh <work-items-dir> [expected_status]"
    exit 1
fi

dir="$1"
expected_status="${2:-}"

if [[ ! -d "$dir" ]]; then
    err "invalid: work-items directory not found: $dir"
    exit 1
fi
if [[ ! -r "$dir" || ! -x "$dir" ]]; then
    err "error: work-items directory not readable: $dir"
    exit 2
fi

# --- work item の収集（id 集合 = 依存実在チェック用） ---
shopt -s nullglob
files=("$dir"/*.md)
shopt -u nullglob

if [[ "${#files[@]}" -eq 0 ]]; then
    err "invalid: no work items found in $dir"
    exit 1
fi

declare -a ids=()
for f in "${files[@]}"; do
    base="$(basename "$f" .md)"
    ids+=("${base%%-*}")
done

# --- 各 work item の検証 ---
for f in "${files[@]}"; do
    base="$(basename "$f" .md)"

    if [[ ! -r "$f" ]]; then
        err "error: work item not readable: $f"
        exit 2
    fi

    # frontmatter（先頭 --- 〜 次の ---）と本文を抽出
    fm="$(awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f{print}' "$f")"
    body="$(awk 'c==2{print} $0=="---"{c++}' "$f")"

    # (1) 必須 6 キー
    for k in id status size risk assigned dependencies; do
        echo "$fm" | grep -Eq "^${k}:" || { err "invalid: missing frontmatter key '$k' in $base"; exit 1; }
    done

    # (2) enum（read_scalar で値トークン抽出 = 引用符なし/両端引用符のみ許容・prefix 偽陽性排除・
    #     inline コメント許容・片側引用符は弾く）→ enum 完全一致
    status_v="$(read_scalar "$fm" status '[A-Za-z_]')" \
        || { err "invalid: malformed/quoted status value in $base"; exit 1; }
    size_v="$(read_scalar "$fm" size '[A-Za-z_]')" \
        || { err "invalid: malformed/quoted size value in $base"; exit 1; }
    risk_v="$(read_scalar "$fm" risk '[A-Za-z_]')" \
        || { err "invalid: malformed/quoted risk value in $base"; exit 1; }
    in_list "$status_v" "$STATUS_ENUM" || { err "invalid: bad status enum '$status_v' in $base"; exit 1; }
    in_list "$size_v"   "$SIZE_ENUM"   || { err "invalid: bad size enum '$size_v' in $base"; exit 1; }
    in_list "$risk_v"   "$RISK_ENUM"   || { err "invalid: bad risk enum '$risk_v' in $base"; exit 1; }

    # (3) expected_status（任意 / define 初期値 pending 用）
    if [[ -n "$expected_status" && "$status_v" != "$expected_status" ]]; then
        err "invalid: status '$status_v' != expected '$expected_status' in $base"
        exit 1
    fi

    # (4) id とファイル名整合（read_scalar で片側引用符 "001 / 001" を弾く）
    id_v="$(read_scalar "$fm" id '[^"#[:space:]]')" \
        || { err "invalid: malformed/quoted id value in $base"; exit 1; }
    [[ "${base%%-*}" == "$id_v" ]] || { err "invalid: id '$id_v' != filename prefix '${base%%-*}' in $base"; exit 1; }

    # (5) assigned の型（string or null / §4.1）。値トークンを抽出し null / "..." / bare scalar のみ許容。
    # 配列 [..] / マップ {..} / 空値は string|null 違反として exit 1。
    assigned_v="$(echo "$fm" | sed -nE 's/^assigned:[[:space:]]*([^#]*[^#[:space:]])[[:space:]]*(#.*)?$/\1/p')"
    case "$assigned_v" in
        null) ;;                                                   # null 許容
        '"'*'"') ;;                                                # "..." quoted string
        \[*|\{*|'') err "invalid: assigned must be string or null in $base"; exit 1 ;;
        *) [[ "$assigned_v" =~ ^[A-Za-z0-9._@/-]+$ ]] \
               || { err "invalid: assigned must be string or null in $base"; exit 1; } ;;
    esac

    # (6) 本文必須 6 セクション
    for sec in "${REQUIRED_SECTIONS[@]}"; do
        echo "$body" | grep -Eq "^## ${sec}\$" || { err "invalid: missing section '$sec' in $base"; exit 1; }
    done

    # (7) dependencies は array 形式（[...]）必須。非配列（dependencies: 999 等）・壊れた配列は exit 1。
    deps_line="$(echo "$fm" | grep -E '^dependencies:' | head -n1)"
    echo "$deps_line" | grep -Eq '^dependencies:[[:space:]]*\[[^]]*\][[:space:]]*(#.*)?$' \
        || { err "invalid: dependencies must be an array '[...]' in $base"; exit 1; }
    # (8) 配列内要素をカンマ区切りで厳密検証（各要素は work item ID トークン）。
    # 空配列は許容。空白区切り（[001 002]）・ハイフン結合（[001-002]）・空要素・余分な記号は exit 1。
    deps_inner="$(echo "$deps_line" | sed -nE 's/^dependencies:[[:space:]]*\[([^]]*)\].*/\1/p')"
    deps_compact="$(echo "$deps_inner" | tr -d '[:space:]')"
    declare -a dep_list=()
    if [[ -n "$deps_compact" ]]; then
        saved_ifs="$IFS"; IFS=','; read -ra raw_deps <<< "$deps_inner"; IFS="$saved_ifs"
        for raw in "${raw_deps[@]}"; do
            # 前後空白を除去（要素内部の空白・記号は許容しない = 完全一致検証）
            elem="$(echo "$raw" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
            # 引用符なし or 両端引用符付きのみ許容（片側だけの ["001] / [001"] は弾く）
            [[ "$elem" =~ ^([A-Za-z0-9]+|\"[A-Za-z0-9]+\")$ ]] \
                || { err "invalid: malformed dependency element '$elem' in $base"; exit 1; }
            # 外側の引用符のみ除去（両端そろっている前提）
            elem="${elem#\"}"; elem="${elem%\"}"
            dep_list+=("$elem")
        done
    fi
    # (9) dependencies が実在 id のみ
    for dep in "${dep_list[@]+"${dep_list[@]}"}"; do
        in_list "$dep" "${ids[*]}" || { err "invalid: dependency '$dep' not found (in $base)"; exit 1; }
    done
done

echo "status:valid"
exit 0
