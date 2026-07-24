#!/usr/bin/env bash
#
# work-item-validate.sh - validate work item *.md files against docs/v3/data-model.md §4
#
# 指定ディレクトリ内の全 work item（*.md）が data-model §4 の schema に適合するかを
# 検証する（読み取り専用 / 状態は変更しない）。define Step 4-2 の検証ゲート実体であり、
# 後続フェーズ（develop / doctor）からも再利用できる。state-validate.sh が state.json を
# 検証するのと対称な、work item frontmatter / 本文の schema validator。
#
# frontmatter の構造解釈（ブロック抽出 / body 抽出 / スカラー抽出 / 配列パース /
# malformed guard）は共有ライブラリ lib/frontmatter.sh に集約済み（#733 T1）。本スクリプトは
# 構造解釈を共有 parser へ委譲し、enum 検証 / 必須キー一意性 / assigned 型 / 本文セクション /
# 依存実在 / expected_status の意味検証を担う。
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

# 共有 frontmatter parser ライブラリを source（スクリプト配置基準 / cwd 非依存 / bash 3.2 互換）
_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/frontmatter.sh disable=SC1091
. "$_SCRIPT_DIR/lib/frontmatter.sh"

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
declare -a seen_ids=()
for f in "${files[@]}"; do
    base="$(basename "$f" .md)"
    id_prefix="${base%%-*}"
    # 重複 id 検出（依存は ID 参照のみ / §6）。同一 ID prefix のファイルが複数あると
    # work-item-next.sh の status_of_id が先頭一致で曖昧解決するため、検証ゲートで弾く。
    if in_list "$id_prefix" "${seen_ids[*]}"; then
        err "invalid: duplicate work item id '$id_prefix' (multiple files share this id)"
        exit 1
    fi
    seen_ids+=("$id_prefix")
    ids+=("$id_prefix")
done

# --- 各 work item の検証 ---
for f in "${files[@]}"; do
    base="$(basename "$f" .md)"

    if [[ ! -r "$f" ]]; then
        err "error: work item not readable: $f"
        exit 2
    fi

    # frontmatter ブロック抽出（共有 parser / fail-closed）。閉じ delimiter が無い malformed は
    # fm_extract_block が return 1 する（partial parse 防止 / codex premerge R7 P2）。
    if ! fm="$(fm_extract_block "$f")"; then
        err "invalid: malformed frontmatter (missing closing '---') in $base"
        exit 1
    fi
    # body は 2 番目の区切り（frontmatter 終端）以降（本文中 --- で打ち切らない / 共有 parser）。
    body="$(fm_extract_body "$f")"

    # (1) 必須 6 キー（各キーは「ちょうど 1 回」出現を要求）。
    #     重複出現（例: status: pending / status: done の二重指定）は黙って曖昧解決されるため、
    #     検証ゲートで弾いて非決定的 state を防ぐ。出現回数は共有 parser でカウント。
    for k in id status size risk assigned dependencies; do
        kc="$(fm_key_count "$fm" "$k")"
        if [[ "$kc" -eq 0 ]]; then
            err "invalid: missing frontmatter key '$k' in $base"; exit 1
        elif [[ "$kc" -gt 1 ]]; then
            err "invalid: duplicate frontmatter key '$k' ($kc occurrences) in $base"; exit 1
        fi
    done

    # (2) enum（fm_scalar strict で値トークン抽出 = 引用符なし/両端引用符のみ許容・prefix 偽陽性排除・
    #     inline コメント許容・片側引用符は弾く）→ enum 完全一致（enum 値域は consumer 責務）
    status_v="$(fm_scalar "$fm" status '[A-Za-z_]')" \
        || { err "invalid: malformed/quoted status value in $base"; exit 1; }
    size_v="$(fm_scalar "$fm" size '[A-Za-z_]')" \
        || { err "invalid: malformed/quoted size value in $base"; exit 1; }
    risk_v="$(fm_scalar "$fm" risk '[A-Za-z_]')" \
        || { err "invalid: malformed/quoted risk value in $base"; exit 1; }
    in_list "$status_v" "$STATUS_ENUM" || { err "invalid: bad status enum '$status_v' in $base"; exit 1; }
    in_list "$size_v"   "$SIZE_ENUM"   || { err "invalid: bad size enum '$size_v' in $base"; exit 1; }
    in_list "$risk_v"   "$RISK_ENUM"   || { err "invalid: bad risk enum '$risk_v' in $base"; exit 1; }

    # (3) expected_status（任意 / define 初期値 pending 用）
    if [[ -n "$expected_status" && "$status_v" != "$expected_status" ]]; then
        err "invalid: status '$status_v' != expected '$expected_status' in $base"
        exit 1
    fi

    # (4) id とファイル名整合（fm_scalar strict で片側引用符 "001 / 001" を弾く）
    id_v="$(fm_scalar "$fm" id '[^"#[:space:]]')" \
        || { err "invalid: malformed/quoted id value in $base"; exit 1; }
    [[ "${base%%-*}" == "$id_v" ]] || { err "invalid: id '$id_v' != filename prefix '${base%%-*}' in $base"; exit 1; }

    # (5) assigned の型（string or null / §4.1）。raw 値トークンを抽出し null / "..." / bare scalar のみ許容。
    # 配列 [..] / マップ {..} / 空値は string|null 違反として exit 1。raw 抽出（引用符非剥離）で
    # quoted と bare を区別する（共有 parser fm_scalar_raw）。
    assigned_v="$(fm_scalar_raw "$fm" assigned)"
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

    # (7)(8) dependencies は array 形式（[...]）必須 + 要素は work item ID トークン（共有 parser fm_deps）。
    # 非配列（dependencies: 999 等）・壊れた配列（空白区切り [001 002]・ハイフン結合 [001-002]・
    # 片側引用符・空要素）は fm_deps が return 1（fail-closed）。空配列は許容。
    if ! deps_str="$(fm_deps "$fm")"; then
        err "invalid: dependencies must be an array '[...]' of ID tokens in $base"; exit 1
    fi
    # (9) dependencies が実在 id のみ（実在検証は consumer 責務）
    for dep in $deps_str; do
        in_list "$dep" "${ids[*]}" || { err "invalid: dependency '$dep' not found (in $base)"; exit 1; }
    done
done

echo "status:valid"
exit 0
