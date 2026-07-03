#!/usr/bin/env bash
# frontmatter パース禁止パターン検出スクリプト（Unit 002 / T4 / #733）
#
# skills/aidlc-v3/scripts/ の個別 consumer スクリプト（lib/ と tests/ を除く）に、
# frontmatter 構造解釈の禁止パターン（生の grep / sed / awk / permissive jq）が
# 混入していないかを機械検出する。Unit 001 で確立した共有 parser 境界
# （lib/frontmatter.sh の fm_* 関数）からの逸脱を CI で自動的に弾く。
#
# 検出方針（候補 C / 論理設計参照）:
#   - トークンベース検出: frontmatter フィールドトークン（^status: 等の ^key: / --- delimiter）を
#     参照する生 grep/sed/awk を違反とする。^## markdown 見出し（C1）や .json への jq（B）は
#     トークンに該当せず自然に除外される。
#   - 論理コマンド単位スキャン: backslash / pipe 継続・awk プログラムを 1 単位に連結してから判定
#     （変数経由・複数行・関数経由の取りこぼしを防ぐ）。
#   - 限定 allow マーカー: 非構造 write idiom（atomic write 等）のみ
#     `# parse-guard: allow=<理由> (issue: #NNN, ref: <根拠>)` で除外。構造解釈の READ には付与不可。
#
# opt-in シグナル（CLAUDE.md ドッグフーディング原則）:
#   走査対象ディレクトリが存在しなければ違反 0 件で exit 0。本スクリプトは consumer プロジェクトに
#   配布されない bin/ 配下のリポジトリツールであり、「starter kit 判定」分岐は持たない。
#
# Usage: check-frontmatter-parse-guard.sh [target_dir] [options]
#
# Exit codes:
#   0  違反なし（走査対象不在の opt-in skip を含む）
#   1  違反検出（+ 違反箇所報告）
#   2  スクリプトエラー（git repo 外 / find 失敗 / 必須コマンド不在 等）

set -euo pipefail

DEFAULT_TARGET_DIR="skills/aidlc-v3/scripts"

REPO_ROOT=""
VERBOSE=false
TARGET_DIR=""
VIOLATION_COUNT=0
FILE_COUNT=0
SELF_REL="bin/check-frontmatter-parse-guard.sh"
AWK_PROG=""

show_usage() {
    cat <<EOF
Usage: $(basename "$0") [target_dir] [options]

skills/aidlc-v3/scripts/ の個別 consumer スクリプト（lib/ と tests/ を除く）に
frontmatter 構造解釈の禁止パターン（生 grep/sed/awk/permissive jq）が混入していないか検出します。

Arguments:
  target_dir    走査ルート (デフォルト: ${DEFAULT_TARGET_DIR})

Options:
  -v, --verbose    詳細出力モード
  -h, --help       このヘルプを表示

Exit codes:
  0  違反なし（走査対象不在の opt-in skip を含む）
  1  違反検出
  2  スクリプトエラー

違反報告フォーマット (1 件 1 行):
  <file>:<line>: forbidden frontmatter parse pattern (<command>): use shared parser (fm_* in lib/frontmatter.sh) instead. <detail>
EOF
}

# 検出ロジックの awk プログラムを一時ファイルに書き出す（単一引用符エスケープ回避のため -f 方式）。
write_awk_program() {
    AWK_PROG="$(mktemp "${TMPDIR:-/tmp}/check-fm-guard.XXXXXX")" || {
        echo "Error: mktemp failed" >&2
        exit 2
    }
    cat > "$AWK_PROG" <<'AWK_EOF'
function trim(s) { gsub(/^[[:space:]]+/, "", s); gsub(/[[:space:]]+$/, "", s); return s }

# 簡易 lexer: 単一/二重引用符状態を追跡し、クォート外の行コメント（先頭または空白直後の #）以降を除去する。
# これにより末尾インラインコメント中のアポストロフィ（# don't 等）が引用符パリティを狂わせない（R-code#1）。
function strip_comment(s,   i, c, inS, inD, out, prev) {
    inS = 0; inD = 0; out = ""; prev = ""
    for (i = 1; i <= length(s); i++) {
        c = substr(s, i, 1)
        if (c == SQ && !inD) { inS = !inS; out = out c; prev = c; continue }
        if (c == "\"" && !inS) { inD = !inD; out = out c; prev = c; continue }
        if (c == "#" && !inS && !inD && (out == "" || prev == " " || prev == "\t")) break
        out = out c; prev = c
    }
    return out
}

# frontmatter フィールドトークン / --- delimiter を参照しているか
function is_fm_token(u) {
    # ^key: 形式の既知 frontmatter フィールドキー抽出（regex リテラル内）
    if (u ~ /\^(status|id|dependencies|size|risk|assigned|complexity|title|created|updated)[A-Za-z0-9_]*:/) return 1
    # --- delimiter をブロック境界として参照（awk 比較 / sed・grep アンカー）
    if (u ~ /==[[:space:]]*"?---"?/) return 1
    if (u ~ /\^---/) return 1
    # 汎用 ^key: 抽出（未知キー / 将来キー）— frontmatter 文脈シグナルがある場合のみ違反扱い（R-code#3 / R-code-r2 / 誤検出抑制）
    # 文脈シグナル: .md リテラル / fm 系 here-string / --- delimiter / work item パス変数（$file $f $wi $item $md 等）。
    # work item パス変数は語境界で判定するため $logfile 等は誤一致しない。
    # .md リテラル境界は引用符（" '）・閉じ括弧 ) ]・空白・行末を許容（R-code-r3）
    if (u ~ /\^[A-Za-z_][A-Za-z0-9_]*:/ && \
        (u ~ /\.md([]"')]|[[:space:]]|$)/ || u ~ /<<<[[:space:]]*"?\$(fm|block|frontmatter|fm_block|fmtext)/ || u ~ /==[[:space:]]*"?---"?/ || u ~ /\^---/ || \
         u ~ /\$\{?(file|f|wi|item|md|work_item|workitem)([^A-Za-z0-9_]|$)/)) return 1
    return 0
}

# raw grep/sed/awk がコマンド語として現れるか（fm_* 関数呼び出しは語境界で除外される）
function has_raw_cmd(u) {
    if (u ~ /(^|[^A-Za-z0-9_.\/-])grep([^A-Za-z0-9_]|$)/) return "grep"
    if (u ~ /(^|[^A-Za-z0-9_.\/-])sed([^A-Za-z0-9_]|$)/)  return "sed"
    if (u ~ /(^|[^A-Za-z0-9_.\/-])awk([^A-Za-z0-9_]|$)/)  return "awk"
    return ""
}

# 引用符プログラム継続の対象コマンド（grep/sed/awk に加え jq を含む / R-code#2）
function has_quote_cmd(u) {
    if (has_raw_cmd(u) != "") return 1
    if (u ~ /(^|[^A-Za-z0-9_.\/-])jq([^A-Za-z0-9_]|$)/) return 1
    return 0
}

# 論理コマンド単位が未完成か（クォート状態追跡のスタックベース字句解析 / R-int#1-r2）。
# 単一引用符（リテラル）/ 二重引用符 / $( コマンド置換を文脈管理し、引用符内の括弧 ) を
# command substitution 終端と誤認しない。$( に入る際は外側のクォート文脈をスタックに退避し、
# 対応する ) で復元する。末尾で開いたクォート or 未閉じ $( が残れば未完成。
# q: 現在のクォート文脈（"" / SQ=単一 / "D"=二重）, depth: 未閉じ $( 数, qstack: 退避クォート列。
function unit_incomplete(s,   i, c, n, prev, q, depth, qstack, lc) {
    q = ""; depth = 0; qstack = ""; prev = ""
    n = length(s)
    for (i = 1; i <= n; i++) {
        c = substr(s, i, 1)
        if (q == SQ) { if (c == SQ) q = ""; prev = c; continue }
        if (q == "D") {
            if (c == "\"") { q = ""; prev = c; continue }
            if (c == "(" && prev == "$") { qstack = qstack "D"; q = ""; depth++; prev = c; continue }
            prev = c; continue
        }
        # q == "" （クォート外）
        if (c == SQ) { q = SQ; prev = c; continue }
        if (c == "\"") { q = "D"; prev = c; continue }
        if (c == "(" && prev == "$") { qstack = qstack "N"; q = ""; depth++; prev = c; continue }
        if (c == ")") {
            if (depth > 0) {
                depth--
                lc = substr(qstack, length(qstack), 1); qstack = substr(qstack, 1, length(qstack) - 1)
                q = (lc == "D") ? "D" : ""
            }
            prev = c; continue
        }
        prev = c
    }
    return (depth > 0 || q != "")
}

# permissive jq（frontmatter テキストを入力 + // または ? coerce）か
function has_jq_coerce(u) {
    if (u !~ /(^|[^A-Za-z0-9_.\/-])jq([^A-Za-z0-9_]|$)/) return 0
    # frontmatter 入力: fm 系変数へのヒアストリング、または .md ファイル引数
    # .md 境界は is_fm_token と同型（引用符・閉じ括弧・空白・行末を許容 / R-code-r4）
    if (u ~ /<<<[[:space:]]*"?\$(fm|block|frontmatter|fm_block|fmtext)/ || u ~ /\.md([]"')]|[[:space:]]|$)/) {
        if (u ~ /\/\// || u ~ /\?/) return 1
    }
    return 0
}

# 抽出（READ）idiom か: コマンド置換で値を捕捉 / 変数代入で捕捉
function is_extraction(u) {
    if (u ~ /\$\(/) return 1
    if (u ~ /`/) return 1
    if (u ~ /[A-Za-z_][A-Za-z0-9_]*\+?=[^=].*(grep|sed|awk)/) return 1
    return 0
}

# 既知の atomic write idiom（in-place 書き換え）か。以下の両方を要求する（R-int#2-r2 / r3）:
#   (1) 全行 passthrough の既定ルール `{ print }`（マッチしない行をそのまま出力 = ファイル全体の rewrite）
#   (2) リテラル "key: " prefix を伴う key 書き換え print（status.sh の `print "status: " newstatus` 等）
# 片方のみ（例: `/^status:/{print "status: " $2}` は passthrough を持たない status 行のみの変換/抽出）は
# atomic write idiom ではなく、marker で除外しない。
function is_atomic_write(u) {
    # (2) リテラル "key: " 書き換え print
    if (u !~ /print[[:space:]]*"[A-Za-z_][A-Za-z0-9_]*:[[:space:]]/) return 0
    # (1) 無条件の既定ルール { print }（直前が } / ; / プログラム開始 ' のいずれか）。
    #     条件付き /^title:/{print} 等（直前が pattern）は passthrough ではないため除外。
    if (u !~ /[};'][[:space:]]*\{[[:space:]]*print[[:space:]]*\}/) return 0
    return 1
}

# allow マーカーの妥当性: allow=<非空> かつ issue: #NNN かつ ref: を含む
function marker_valid(m) {
    if (m !~ /parse-guard:[[:space:]]*allow=[^[:space:]]/) return 0
    if (m !~ /issue:[[:space:]]*#[0-9]+/) return 0
    if (m !~ /ref:/) return 0
    return 1
}
function is_marker_line(s) { return (s ~ /#[[:space:]]*parse-guard:[[:space:]]*allow=/) }

function emit(lineno, cmd, detail) {
    printf "%s:%d: forbidden frontmatter parse pattern (%s): use shared parser (fm_* in lib/frontmatter.sh) instead. %s\n", relfile, lineno, cmd, detail > "/dev/stderr"
    vcount++
}

# 組み立て済みの論理コマンド単位 acc を評価する
function evaluate(acc, startline, marked, marker_text,   cmd) {
    # フルラインコメントは対象外（マーカー行は呼び出し側で別処理済み）
    if (trim(acc) ~ /^#/) return

    cmd = has_raw_cmd(acc)
    if (cmd != "" && is_fm_token(acc)) {
        if (marked) {
            if (!marker_valid(marker_text)) {
                emit(startline, cmd, "invalid allow marker (require allow=<reason>, issue: #NNN, ref:)")
                return
            }
            # 許可対象は「awk の atomic write idiom（全行 passthrough + key 書き換え print）」のみ（R-int#2 / r2）。
            # grep/sed は本質的に READ。awk でも単なる抽出（is_extraction）や atomic write シグネチャを持たない
            # 行フィルタ（/^status:/{print} 等の redirect READ）は marker では除外しない。
            if (cmd == "awk" && !is_extraction(acc) && is_atomic_write(acc)) return
            emit(startline, cmd, "allow marker is only permitted on the awk atomic write idiom (all-line passthrough + literal key rewrite); not on reads/extractions")
            return
        }
        emit(startline, cmd, "raw frontmatter token referenced")
        return
    }
    if (has_jq_coerce(acc)) {
        # jq on frontmatter text は常に違反（frontmatter に対する正当な jq write idiom は存在しない）。
        # marker でも除外しない（R-int#2 / r2）。
        if (marked && !marker_valid(marker_text)) {
            emit(startline, "jq", "invalid allow marker (require allow=<reason>, issue: #NNN, ref:)")
            return
        }
        if (marked) {
            emit(startline, "jq", "allow marker is not permitted on frontmatter jq (no legitimate jq write idiom for frontmatter)")
            return
        }
        emit(startline, "jq", "permissive jq coerce on frontmatter text")
        return
    }
}

function unit_marked() { return (pend_marker || umark) }
function unit_marker_text() { if (umark) return umark_text; return pend_marker_text }

BEGIN { acc=""; startline=0; pend_marker=0; pend_marker_text=""; umark=0; umark_text=""; vcount=0; in_heredoc=0; htag=""; SQ=sprintf("%c", 39) }
{
    line=$0

    # heredoc 本文はデータとして除外
    if (in_heredoc) {
        if (trim(line) == htag) in_heredoc=0
        next
    }

    # マーカー行（フルラインコメント）: 次の論理単位へ適用予約（strip 前の原文で判定）
    if (acc == "" && trim(line) ~ /^#/ && is_marker_line(trim(line))) {
        pend_marker=1; pend_marker_text=line
        next
    }

    # inline marker（コード行末尾に付随する marker）を単位に記録（strip でコメントが消える前に検出）
    if (is_marker_line(line)) { umark=1; umark_text=line }

    # heredoc 開始検出（原文で判定 / 行内コマンド評価後にデータ行をスキップするため tag を控える）
    # 引用符付きタグ <<"EOF" / <<'EOF' / <<-'EOF'（dash 変種）の両クォートを扱う（R-code-r5）。
    detected_heredoc=0; cand_tag=""
    if (match(line, /<<-?[[:space:]]*["']?[A-Za-z_][A-Za-z0-9_]*["']?/)) {
        cand_tag=substr(line, RSTART, RLENGTH)
        gsub(/^<<-?[[:space:]]*["']?/, "", cand_tag); gsub(/["'].*$/, "", cand_tag); cand_tag=trim(cand_tag)
        detected_heredoc=1
    }

    # クォート考慮でコメントを除去（インラインコメント中のアポストロフィでパリティを崩さない / R-code#1）
    code=strip_comment(line)

    # 純コメント行（非マーカー）は論理単位を生成しない
    if (acc == "" && trim(code) == "") {
        umark=0; umark_text=""
        next
    }

    # 論理コマンド単位の組み立て（コメント除去後のコードで）
    if (acc == "") { startline=FNR; acc=code }
    else { acc=acc " " code }

    t=trim(acc)
    # 継続判定（acc はコメント除去済みなのでアポストロフィ汚染なし）:
    # (a) 未閉じのクォート / $( コマンド置換が残る → 複数行プログラム（単一引用符 awk / 二重引用符 sed・jq /
    #     $(...) ネスト）の途中なので連結（unit_incomplete のスタックベース字句解析。引用符内の ) を誤認しない / R-int#1-r2）
    if (unit_incomplete(acc)) { next }
    # (b) 行末 backslash 継続（クォート外の明示継続）
    if (t ~ /\\$/) { sub(/\\[[:space:]]*$/, " ", acc); next }
    # (c) 行末 pipe 継続
    if (t ~ /\|$/) { next }

    # 単位完成 → 評価
    evaluate(acc, startline, unit_marked(), unit_marker_text())

    # heredoc 開始していたら本文スキップへ
    if (detected_heredoc && cand_tag != "") { in_heredoc=1; htag=cand_tag }

    acc=""; startline=0; pend_marker=0; pend_marker_text=""; umark=0; umark_text=""
}
END {
    # 未閉じ / 末尾の論理単位を取りこぼさず評価（R-code#1）
    if (acc != "") evaluate(acc, startline, unit_marked(), unit_marker_text())
    print vcount
}
AWK_EOF
}

# 1 ファイルを論理コマンド単位でスキャンし違反を検出する。
# 違反行は stderr へ <rel_file>:<line>: <message> 形式で出力。stdout には検出件数を返す。
scan_file() {
    local file="$1"
    local rel_file="${file#"${REPO_ROOT}/"}"
    local count

    count=$(awk -v relfile="$rel_file" -f "$AWK_PROG" "$file")
    if [ -z "$count" ]; then count=0; fi
    VIOLATION_COUNT=$((VIOLATION_COUNT + count))
    FILE_COUNT=$((FILE_COUNT + 1))
    if $VERBOSE && [ "$count" -eq 0 ]; then
        echo "  [OK] $rel_file"
    fi
}

cleanup() {
    [ -n "$AWK_PROG" ] && rm -f "$AWK_PROG"
}

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_usage
                exit 0
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -*)
                echo "Error: Unknown option: $1" >&2
                show_usage >&2
                exit 2
                ;;
            *)
                if [ -z "$TARGET_DIR" ]; then
                    TARGET_DIR="$1"
                else
                    echo "Error: Unexpected argument: $1" >&2
                    show_usage >&2
                    exit 2
                fi
                shift
                ;;
        esac
    done

    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "Error: Not a git repository. Run this script from within a git repository." >&2
        exit 2
    }

    if [ -z "$TARGET_DIR" ]; then
        TARGET_DIR="$DEFAULT_TARGET_DIR"
    fi
    if [[ "$TARGET_DIR" != /* ]]; then
        TARGET_DIR="${REPO_ROOT}/${TARGET_DIR}"
    fi

    # opt-in シグナル: 走査対象が無ければ違反 0 で正常終了（consumer プロジェクトで自然に skip）
    if [ ! -d "$TARGET_DIR" ]; then
        if $VERBOSE; then
            echo "Scan target not present (${TARGET_DIR#"${REPO_ROOT}/"}); skipping (opt-in)."
        fi
        exit 0
    fi

    trap cleanup EXIT
    write_awk_program

    local rel_target="${TARGET_DIR#"${REPO_ROOT}/"}"
    if $VERBOSE; then
        echo "Checking forbidden frontmatter parse patterns in ${rel_target}..."
        echo ""
    fi

    # 走査対象: target_dir 配下（lib/ と tests/ ディレクトリを除く）の *.sh。
    # find はプロセス置換だと終了コードが捕捉できないため、結果を一時ファイルに保存して exit を確認する（R-code#4）。
    local list
    list="$(mktemp "${TMPDIR:-/tmp}/check-fm-guard-list.XXXXXX")" || {
        echo "Error: mktemp failed" >&2
        exit 2
    }
    if ! find "$TARGET_DIR" \( -type d \( -name lib -o -name tests \) -prune \) -o \( -type f -name '*.sh' -print0 \) > "$list"; then
        echo "Error: find failed while scanning $rel_target" >&2
        rm -f "$list"
        exit 2
    fi
    while IFS= read -r -d '' file; do
        local rel="${file#"${REPO_ROOT}/"}"
        if [ "$rel" = "$SELF_REL" ]; then continue; fi
        scan_file "$file"
    done < "$list"
    rm -f "$list"

    if $VERBOSE; then echo ""; fi
    if [ "$VIOLATION_COUNT" -eq 0 ]; then
        echo "Frontmatter parse guard: no violations, $FILE_COUNT file(s) checked in ${rel_target}"
    elif [ "$VIOLATION_COUNT" -eq 1 ]; then
        echo "Frontmatter parse guard: $VIOLATION_COUNT violation, $FILE_COUNT file(s) checked in ${rel_target}" >&2
    else
        echo "Frontmatter parse guard: $VIOLATION_COUNT violations, $FILE_COUNT file(s) checked in ${rel_target}" >&2
    fi

    if [ "$VIOLATION_COUNT" -gt 0 ]; then
        exit 1
    fi
    exit 0
}

main "$@"
