# shellcheck shell=bash
#
# frontmatter.sh - shared safety boundary for work item Markdown frontmatter parsing
#
# work item（*.md）の YAML frontmatter の「構造解釈」を 1 箇所に集約する共有ライブラリ。
# work-item-validate.sh / work-item-next.sh / work-item-status.sh（および将来の
# release / reflect / doctor 等の consumer）が source して利用する。
# 寛容な line ベース regex が malformed YAML を通すバリデーションクラス（#733）の
# 反復再発を、重複実装の解消と境界の一元化によって構造的に断つ。
#
# 責務境界（重要）:
#   本ライブラリは「frontmatter の構造解釈」のみを担う:
#     - frontmatter ブロック終端ガード / ブロック抽出 / body 抽出（fail-closed）
#     - スカラー抽出（strict / loose / raw）
#     - dependencies 配列パース（fail-closed）
#     - キー出現回数カウント（一意性検証ヘルパ）
#   以下は consumer の責務であり、本ライブラリは扱わない:
#     - enum 値（status/size/risk）の妥当性検証
#     - 必須キー集合・一意性の「解釈」（カウントは提供、合否判定は consumer）
#     - dependencies の実在検証 / status 遷移規則 / atomic write
#     - ユーザー向けエラーメッセージ文言 / exit code
#   parser は拒否を `return 1` でシグナルするのみ（理由コード文字列は返さない）。
#
# 個別 consumer での frontmatter 構造解釈の禁止規約:
#   個別 consumer スクリプト（lib/ と tests/ を除く）で frontmatter の構造解釈
#   （スカラー抽出 / 配列パース / ブロック抽出 / malformed guard）に
#   grep / sed / awk / permissive jq を直接書くことを禁止する。新たに構造データを
#   読む場合は本ライブラリの fm_* 関数を使い、conformance fixture
#   （tests/test-frontmatter-parser.sh）にケースを追加すること。
#   ※ 本規約の対象は frontmatter 構造解釈。state-*.sh の JSON / jq（schema 検証は
#     state-validate.sh に集約済み / #731）は対象外。ログ整形等の非構造用途も対象外。
#
# 設計・契約:
#   - 全関数は stdout 返却 + return code でシグナルする（result-out / printf -v は不使用 =
#     dynamic scope shadowing を原理回避）。
#   - 公開関数は fm_ prefix、内部 local は _fm_<fn>_ prefix で namespace 化する。
#   - グローバル定数（STATUS_ENUM 等）は定義しない（consumer の readonly 宣言との
#     二重宣言 / 再代入エラーを回避）。
#   - bash 3.2/4.0+ 互換（連想配列を使わない）。
#   - 本ファイルは source される前提。`set -e` の有無に関わらず安全に動作するよう、
#     関数は非ゼロ return を返すのみで exit しない（consumer が受ける）。
#
# 参照: docs/v3/data-model.md §4 / Intent v3.0.0-alpha.4（#733 T1/T2'）
#

# _fm_valid_key <key> : key が YAML キー名として安全な文字種（^[A-Za-z_][A-Za-z0-9_]*$）なら return 0。
#   key は grep / sed の ERE にそのまま埋め込まれるため、不正な key（regex メタ文字・sed 区切り破壊）を
#   弾いて regex 注入 / sed 構文破壊を防ぐ（公開 safety boundary API のハードニング）。
#   現 consumer は固定キーのみを渡すため通常は常に true。将来 caller が外部入力由来 key を渡す経路の防御。
_fm_valid_key() {
    [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]
}

# fm_has_closing_frontmatter <file> : 先頭行 --- かつ 2 番目の --- が存在すれば return 0。
#   先頭が --- でない / 閉じ --- が無い（frontmatter ブロック未終端）malformed は return 1。
fm_has_closing_frontmatter() {
    awk 'NR==1 && $0!="---"{exit 1} NR>1 && $0=="---"{f=1; exit 0} END{exit f?0:1}' "$1"
}

# fm_extract_block <file> : 先頭 --- 〜 次の --- の間の行を stdout 出力（fail-closed）。
#   閉じ --- が無い malformed file は partial parse させず return 1（安全境界）。
#   呼び出し規約: if ! fm="$(fm_extract_block "$f")"; then ...（local fm="$(...)" は
#   return code をマスクするため避ける）。
fm_extract_block() {
    fm_has_closing_frontmatter "$1" || return 1
    awk 'NR==1 && $0=="---"{f=1; next} f && $0=="---"{exit} f{print}' "$1"
}

# fm_extract_body <file> : 2 番目の ---（frontmatter 終端）以降の全行を stdout 出力。
#   本文中の水平線 --- で打ち切らない（c>=2 で 2 番目以降のみ出力）。閉じ --- が無い
#   malformed file は return 1（fm_extract_block と同じ fail-closed 契約）。
fm_extract_body() {
    fm_has_closing_frontmatter "$1" || return 1
    awk 'c>=2{print} $0=="---"{c++}' "$1"
}

# fm_scalar <fm> <key> [token_atom] : frontmatter から key のスカラー値を抽出して stdout 出力。
#   inline コメント（# ...）・前後空白を除去する。
#   - token_atom 指定あり（strict）: token_atom は ERE 単一アトム（例 '[A-Za-z_]' /
#     '[^"#[:space:]]'）。値が (atom+|"atom+") に一致しなければ return 1（片側引用符・空値・
#     余分記号を拒否）。一致時は両端引用符を剥がして返す。
#   - token_atom 省略（loose）: 検証なし最小抽出。両端引用符付きなら剥がす。値が無ければ空。
fm_scalar() {
    local _fm_scalar_fm="$1" _fm_scalar_key="$2" _fm_scalar_atom="${3:-}"
    local _fm_scalar_line _fm_scalar_val _fm_scalar_re
    _fm_valid_key "$_fm_scalar_key" || return 1
    # grep 非一致（キー不在）を明示吸収（set -euo pipefail 下でも loose は空文字 return 0 に倒す。
    # strict は後続の regex 判定で return 1 となる）。head の SIGPIPE 由来非ゼロも吸収。
    _fm_scalar_line="$(printf '%s\n' "$_fm_scalar_fm" | grep -E "^${_fm_scalar_key}:" | head -n1 || true)"
    _fm_scalar_val="$(printf '%s\n' "$_fm_scalar_line" | sed -nE "s/^${_fm_scalar_key}:[[:space:]]*([^#]*[^#[:space:]])[[:space:]]*(#.*)?\$/\1/p")"
    if [[ -n "$_fm_scalar_atom" ]]; then
        _fm_scalar_re="^(${_fm_scalar_atom}+|\"${_fm_scalar_atom}+\")$"
        [[ "$_fm_scalar_val" =~ $_fm_scalar_re ]] || return 1
        _fm_scalar_val="${_fm_scalar_val#\"}"; _fm_scalar_val="${_fm_scalar_val%\"}"
    else
        if [[ "$_fm_scalar_val" == \"*\" ]]; then
            _fm_scalar_val="${_fm_scalar_val#\"}"; _fm_scalar_val="${_fm_scalar_val%\"}"
        fi
    fi
    printf '%s' "$_fm_scalar_val"
    return 0
}

# fm_scalar_raw <fm> <key> : key の値を raw で抽出して stdout 出力（外側引用符を剥がさない）。
#   inline コメント・前後空白のみ除去。fm_scalar(loose) が "a b" と a b を同一値に潰すのに対し、
#   本関数は引用符・括弧の構造を保持する（assigned の null/quoted/bare/array/map/空 判定用）。
fm_scalar_raw() {
    local _fm_scalarraw_fm="$1" _fm_scalarraw_key="$2" _fm_scalarraw_val
    _fm_valid_key "$_fm_scalarraw_key" || return 1
    _fm_scalarraw_val="$(printf '%s\n' "$_fm_scalarraw_fm" | sed -nE "s/^${_fm_scalarraw_key}:[[:space:]]*([^#]*[^#[:space:]])[[:space:]]*(#.*)?\$/\1/p")"
    printf '%s' "$_fm_scalarraw_val"
    return 0
}

# fm_key_count <fm> <key> : frontmatter 内で ^<key>: に一致する行数を stdout 出力（整数）。
#   一意性の合否解釈（0=不在 / 1=正常 / 複数=曖昧）は consumer の責務。
fm_key_count() {
    local _fm_keycount_fm="$1" _fm_keycount_key="$2"
    _fm_valid_key "$_fm_keycount_key" || { printf '0'; return 1; }
    printf '%s\n' "$_fm_keycount_fm" | grep -Ec "^${_fm_keycount_key}:" || true
}

# fm_deps <fm> : dependencies 配列の ID を空白区切りで stdout 出力（空配列は空出力）。
#   dependencies 行が不在 / array 形式 [...] でない / 要素構文が不正（ハイフン結合 [001-002]・
#   空白区切り [001 002]・片側引用符等）の場合は return 1（fail-closed）。
#   要素は引用符なし or 両端引用符付きの ID トークン（[A-Za-z0-9]+）のみ許容。
fm_deps() {
    local _fm_deps_fm="$1" _fm_deps_line _fm_deps_inner _fm_deps_compact
    local _fm_deps_raw _fm_deps_elem _fm_deps_ifs
    local -a _fm_deps_out=() _fm_deps_raws=()
    _fm_deps_line="$(printf '%s\n' "$_fm_deps_fm" | grep -E '^dependencies:' | head -n1 || true)"
    [[ -n "$_fm_deps_line" ]] || return 1
    printf '%s\n' "$_fm_deps_line" | grep -Eq '^dependencies:[[:space:]]*\[[^]]*\][[:space:]]*(#.*)?$' || return 1
    _fm_deps_inner="$(printf '%s\n' "$_fm_deps_line" | sed -nE 's/^dependencies:[[:space:]]*\[([^]]*)\].*/\1/p')"
    _fm_deps_compact="$(printf '%s\n' "$_fm_deps_inner" | tr -d '[:space:]')"
    if [[ -n "$_fm_deps_compact" ]]; then
        _fm_deps_ifs="$IFS"; IFS=','; read -ra _fm_deps_raws <<< "$_fm_deps_inner"; IFS="$_fm_deps_ifs"
        for _fm_deps_raw in "${_fm_deps_raws[@]}"; do
            _fm_deps_elem="$(printf '%s\n' "$_fm_deps_raw" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')"
            [[ "$_fm_deps_elem" =~ ^([A-Za-z0-9]+|\"[A-Za-z0-9]+\")$ ]] || return 1
            _fm_deps_elem="${_fm_deps_elem#\"}"; _fm_deps_elem="${_fm_deps_elem%\"}"
            _fm_deps_out+=("$_fm_deps_elem")
        done
    fi
    if [[ "${#_fm_deps_out[@]}" -gt 0 ]]; then
        printf '%s ' "${_fm_deps_out[@]}"
    fi
    return 0
}
