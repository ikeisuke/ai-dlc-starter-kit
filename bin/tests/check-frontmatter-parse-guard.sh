#!/usr/bin/env bash
# check-frontmatter-parse-guard.sh の自己完結型 conformance テスト（Unit 002 / T4 / #733）
#
# 論理設計のテストマトリクス T-01〜T-17 を検証する。
# - 合格 fixture（C1/C2/C3/B 等）が検出されないこと
# - 違反 fixture（①〜⑤ / 変数経由・複数行・関数経由）が全て検出されること（R2: 全て RC=違反 必須）
# - allow マーカー統制（READ への付与不可 / reason・issue 必須 / stale 検出）
# - opt-in skip / システムエラー / 既知 marker 集合固定
#
# 外部フレームワーク非依存（bash + 検出スクリプト本体のみ）。

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUARD="$SCRIPT_DIR/../check-frontmatter-parse-guard.sh"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0

# テスト用サンドボックス（trap で安全削除）
TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/test-fm-guard.XXXXXX")"
trap 'rm -rf "$TMPROOT"' EXIT

# 各呼び出しで一意なサンドボックスを返す。
# 注: d="$(fresh_dir)" のコマンド置換はサブシェルで動くためカウンタ変数は親へ伝播しない。
# mktemp -d で一意性を保証し、サブシェル非依存にする（fixture の case 間混入を防ぐ）。
fresh_dir() {
    local base d
    base="$(mktemp -d "$TMPROOT/case.XXXXXX")"
    d="$base/scripts"
    mkdir -p "$d"
    printf '%s' "$d"
}

# assert_rc <期待rc> <説明> <target_dir>
assert_rc() {
    local expected="$1"; local desc="$2"; local target="$3"
    bash "$GUARD" "$target" >/dev/null 2>&1
    local rc=$?
    if [ "$rc" = "$expected" ]; then
        PASS=$((PASS + 1)); echo "  ok   : $desc (rc=$rc)"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : $desc (expected rc=$expected, got rc=$rc)"
    fi
}

# put <dir> <filename> <line...> : fixture スクリプトを書き出す
put() {
    local dir="$1"; local name="$2"; shift 2
    local f="$dir/$name"
    printf '#!/usr/bin/env bash\n' > "$f"
    local l
    for l in "$@"; do
        printf '%s\n' "$l" >> "$f"
    done
}

echo "== check-frontmatter-parse-guard conformance =="

# --- T-01: 共有 parser のみ利用 → 合格 ---
d="$(fresh_dir)"
put "$d" "ok-shared.sh" \
    'fm="$(fm_extract_block "$f")"' \
    'status_v="$(fm_scalar "$fm" status)"' \
    'deps="$(fm_deps "$fm")"'
assert_rc 0 "T-01 共有 parser 利用のみ" "$d"

# --- T-02: C1 markdown 見出し（変数 + ^##）→ 合格 ---
d="$(fresh_dir)"
put "$d" "ok-c1.sh" 'if echo "$body" | grep -Eq "^## ${sec}$"; then :; fi'
assert_rc 0 "T-02 C1 markdown 見出し grep" "$d"

# --- T-03: C2 atomic write awk + 有効 allow マーカー → 合格 ---
d="$(fresh_dir)"
put "$d" "ok-c2.sh" \
    '# parse-guard: allow=atomic frontmatter status write (issue: #733, ref: Unit 001 carve-out)' \
    'awk -v ns="$n" '\''NR==1 && $0=="---"{print;next} $0=="---"{print;next} /^status:/{print "status: " ns;next} {print}'\'' "$f" > "$tmp"'
assert_rc 0 "T-03 C2 atomic write awk + 有効マーカー" "$d"

# --- T-04: C3 tr サニタイズ → 合格 ---
d="$(fresh_dir)"
put "$d" "ok-c3.sh" 'safe="$(printf "%s" "$v" | tr -d "[:cntrl:]")"'
assert_rc 0 "T-04 C3 tr サニタイズ" "$d"

# --- T-05: B .json への jq（coerce 有り）→ 合格（frontmatter 文脈外） ---
d="$(fresh_dir)"
put "$d" "ok-b.sh" \
    'v="$(jq -r ".schema_version // empty" "$file")"' \
    'jq --argjson p "$p" "setpath(\$p; \$v)" "$state" > "$tmp"'
assert_rc 0 "T-05 B .json への jq coerce" "$d"

# --- T-06: 違反① ファイル直接 grep 抽出 → 検出 ---
d="$(fresh_dir)"
put "$d" "bad-1.sh" 'status="$(grep "^status:" "$f" | sed "s/^status:[[:space:]]*//")"'
assert_rc 1 "T-06 違反① ファイル直接抽出" "$d"

# --- T-07: 違反② dependencies 生 sed パース → 検出 ---
d="$(fresh_dir)"
put "$d" "bad-2.sh" 'deps="$(sed -nE "s/^dependencies:[[:space:]]*\[([^]]*)\].*/\1/p" "$f")"'
assert_rc 1 "T-07 違反② dependencies 生 sed" "$d"

# --- T-08: 違反③ frontmatter テキストへの permissive jq → 検出 ---
d="$(fresh_dir)"
put "$d" "bad-3.sh" 'a="$(jq -r ".assigned // empty" <<< "$fm")"'
assert_rc 1 "T-08 違反③ frontmatter への permissive jq" "$d"

# --- T-09: 違反④ 変数経由 READ → 検出 ---
d="$(fresh_dir)"
put "$d" "bad-4.sh" \
    'block="$(fm_extract_block "$f")"' \
    's="$(echo "$block" | sed -n "s/^status:.*//p")"'
assert_rc 1 "T-09 違反④ 変数経由 READ" "$d"

# --- T-10: 違反⑤ 複数行（backslash 継続 / pipe 継続）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-5a.sh" \
    'x="$(sed -nE \' \
    '"s/^dependencies:[[:space:]]*\[([^]]*)\].*/\1/p" "$f")"'
assert_rc 1 "T-10a 違反⑤ backslash 継続" "$d"

d="$(fresh_dir)"
put "$d" "bad-5b.sh" \
    'grep "^id:" "$f" |' \
    '  sed "s/^id://"'
assert_rc 1 "T-10b 違反⑤ pipe 継続" "$d"

# --- T-10c: 関数内での生抽出 → 検出 ---
d="$(fresh_dir)"
put "$d" "bad-5c.sh" \
    'read_status() {' \
    '  local s' \
    '  s="$(grep "^status:" "$1")"' \
    '  printf "%s" "$s"' \
    '}'
assert_rc 1 "T-10c 違反 関数内生抽出" "$d"

# --- T-11: allow マーカーを READ idiom に付与 → 検出（marker 誤用） ---
d="$(fresh_dir)"
put "$d" "bad-marker-read.sh" \
    '# parse-guard: allow=trying to bypass (issue: #733, ref: x)' \
    'status="$(grep "^status:" "$f")"'
assert_rc 1 "T-11 marker を READ に付与（誤用）" "$d"

# --- T-12: reason 空 / issue 欠落の allow マーカー → 検出（無効） ---
d="$(fresh_dir)"
put "$d" "bad-marker-noissue.sh" \
    '# parse-guard: allow=some reason without issue (ref: x)' \
    'awk '\''/^status:/{print}'\'' "$f" > "$tmp"'
assert_rc 1 "T-12 marker issue 欠落（無効）" "$d"

# --- T-13: 走査対象ディレクトリ不在 → opt-in skip（exit 0） ---
assert_rc 0 "T-13 走査対象不在 opt-in skip" "$TMPROOT/does-not-exist-dir"

# --- T-14: 新規 consumer ファイル追加（違反含む）→ 自動的に対象化し検出 ---
d="$(fresh_dir)"
put "$d" "ok-shared.sh" 'fm="$(fm_extract_block "$f")"'
put "$d" "newly-added-consumer.sh" 'v="$(grep "^risk:" "$f")"'
assert_rc 1 "T-14 新規ファイル自動対象化" "$d"

# --- T-15: システムエラー（git repo 外）→ exit 2 ---
nonrepo="$TMPROOT/nonrepo"
mkdir -p "$nonrepo/scripts"
put "$nonrepo/scripts" "x.sh" 'fm="$(fm_extract_block "$f")"'
(cd "$nonrepo" && bash "$GUARD" "$nonrepo/scripts" >/dev/null 2>&1)
rc=$?
if [ "$rc" = "2" ]; then
    PASS=$((PASS + 1)); echo "  ok   : T-15 git repo 外 → exit 2 (rc=$rc)"
else
    FAIL=$((FAIL + 1)); echo "  FAIL : T-15 git repo 外 → exit 2 (expected 2, got $rc)"
fi

# --- T-16: lib/ と tests/ は走査対象外（allowlist ディレクトリ） ---
d="$(fresh_dir)"
mkdir -p "$d/lib" "$d/tests"
put "$d/lib" "frontmatter.sh" 'v="$(grep "^status:" "$f")"'
put "$d/tests" "fixture.sh" 'v="$(sed -nE "s/^id://p" "$f")"'
put "$d" "ok.sh" 'fm="$(fm_extract_block "$f")"'
assert_rc 0 "T-16 lib/ tests/ 除外" "$d"

# --- T-17: stale 検出 — 既知 marker から marker を除去すると違反検出される ---
# 実リポジトリの work-item-status.sh に付与された唯一の許可 marker が、marker 無しでは
# 違反として検出されること（= marker が対応する検出候補に依然対応している）を検証する。
status_src="$REPO_ROOT/skills/aidlc/scripts/work-item-status.sh"
if [ -f "$status_src" ]; then
    d="$(fresh_dir)"
    # marker 行を除去したコピーを作る
    grep -v 'parse-guard: allow=' "$status_src" > "$d/work-item-status.sh"
    bash "$GUARD" "$d" >/dev/null 2>&1
    rc=$?
    if [ "$rc" = "1" ]; then
        PASS=$((PASS + 1)); echo "  ok   : T-17 stale 検出（marker 除去で違反再現） (rc=$rc)"
    else
        FAIL=$((FAIL + 1)); echo "  FAIL : T-17 stale 検出（marker 除去で違反再現） (expected 1, got $rc)"
    fi
    # marker 付きの元ファイルは検出されないこと（既知集合の確認）
    d2="$(fresh_dir)"
    cp "$status_src" "$d2/work-item-status.sh"
    assert_rc 0 "T-17b 許可 marker 付き status.sh は除外" "$d2"
else
    echo "  skip : T-17 work-item-status.sh 不在"
fi

# --- T-18: 末尾インラインコメント中のアポストロフィ（R-code#1）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-inline-comment.sh" 'status="$(grep "^status:" "$f")" # we dont need this but with apostrophe doesn'\''t'
assert_rc 1 "T-18 末尾インラインコメント apostrophe で取りこぼさない" "$d"

# --- T-18b: 末尾コメントに frontmatter token があっても合格（コメントは除外） ---
d="$(fresh_dir)"
put "$d" "ok-comment-token.sh" 'echo "done" # uses grep "^status:" historically, now via fm_*'
assert_rc 0 "T-18b コメント内の token は検出しない" "$d"

# --- T-19: 複数行 jq（単一引用符プログラムが行をまたぐ / R-code#2）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-mljq.sh" \
    'a="$(jq -r '\''' \
    '  .assigned // empty'\'' <<< "$fm")"'
assert_rc 1 "T-19 複数行 jq permissive coerce" "$d"

# --- T-19b: jq permissive coerce + 単一引用符 .md リテラル（R-code-r4）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-jq-mdsingle.sh" 'v="$(jq -r ".owner // empty" '\''foo.md'\'')"'
assert_rc 1 "T-19b jq coerce（単一引用符 .md）" "$d"

# --- T-19c: jq permissive coerce + 未引用符 .md リテラル（R-code-r4）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-jq-mdbare.sh" 'jq -r ".owner // empty" foo.md'
assert_rc 1 "T-19c jq coerce（未引用符 .md）" "$d"

# --- T-20: 未知/汎用キーの生抽出（frontmatter 文脈あり / R-code#3）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-generic-key.sh" 'v="$(grep "^owner:" "$wi.md")"'
assert_rc 1 "T-20 汎用キー生抽出（.md 文脈）" "$d"

# --- T-20b: 汎用キーでも frontmatter 文脈がなければ誤検出しない（$logfile は work item 変数でない） ---
d="$(fresh_dir)"
put "$d" "ok-generic-nocontext.sh" 'logline="$(grep "^level:" "$logfile")"'
assert_rc 0 "T-20b 汎用キー（frontmatter 文脈なし）は検出しない" "$d"

# --- T-20c: 汎用キー + work item パス変数 $file（R-code-r2）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-generic-file.sh" 'v="$(grep "^owner:" "$file")"'
assert_rc 1 "T-20c 汎用キー（work item 変数 \$file 文脈）" "$d"

# --- T-20d: 汎用キー + 単一引用符付き .md リテラル（R-code-r3）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-generic-mdsingle.sh" 'v="$(grep "^owner:" '\''foo.md'\'')"'
assert_rc 1 "T-20d 汎用キー（単一引用符 .md リテラル）" "$d"

# --- T-20e: 汎用キー + 未引用符 .md リテラル（行末終端 / R-code-r3）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-generic-mdbare.sh" 'grep "^owner:" foo.md'
assert_rc 1 "T-20e 汎用キー（未引用符 .md リテラル）" "$d"

# --- T-22: single-quoted heredoc 本文は除外（R-code-r5 / false positive 防止）---
d="$(fresh_dir)"
{
    printf '#!/usr/bin/env bash\n'
    printf "cat <<'EOF'\n"
    printf '%s\n' 'example usage: grep "^status:" "$f"   # これは説明文（heredoc本文）'
    printf 'EOF\n'
} > "$d/ok-heredoc-single.sh"
assert_rc 0 "T-22 single-quoted heredoc 本文は除外" "$d"

# --- T-22b: dash 付き single-quoted heredoc (<<-'EOF') も除外 ---
d="$(fresh_dir)"
{
    printf '#!/usr/bin/env bash\n'
    printf "\tcat <<-'EOF'\n"
    printf '\t%s\n' 'doc: sed -nE "s/^dependencies://p" "$wi.md"'
    printf '\tEOF\n'
} > "$d/ok-heredoc-dash.sh"
assert_rc 0 "T-22b <<-'EOF' heredoc 本文は除外" "$d"

# --- T-23: 二重引用符複数行 sed プログラム（R-int#1）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-dq-multiline-sed.sh" \
    'status="$(sed -nE "' \
    's/^status:[[:space:]]*//p' \
    '" "$f")"'
assert_rc 1 "T-23 二重引用符複数行 sed" "$d"

# --- T-23b: 二重引用符複数行 jq → 検出 ---
d="$(fresh_dir)"
put "$d" "bad-dq-multiline-jq.sh" \
    'a="$(jq -r "' \
    '.assigned // empty' \
    '" <<< "$fm")"'
assert_rc 1 "T-23b 二重引用符複数行 jq" "$d"

# --- T-23c: 複数行 jq で 1 行目にプログラム内括弧 ) を含む（regex-paren で誤完成しない / R-int#1-r2）→ 検出 ---
d="$(fresh_dir)"
put "$d" "bad-mljq-paren.sh" \
    'a="$(jq -r "(.assigned // empty)' \
    '" <<< "$fm")"'
assert_rc 1 "T-23c 複数行 jq（プログラム内括弧）" "$d"

# --- T-24: redirect 型 READ (grep > tmp) + 有効 marker → 検出（marker は awk write 限定 / R-int#2）---
d="$(fresh_dir)"
put "$d" "bad-redirect-read-marker.sh" \
    '# parse-guard: allow=looks like write but is a read (issue: #733, ref: x)' \
    'grep "^status:" "$f" > "$tmp"'
assert_rc 1 "T-24 redirect 型 grep READ + marker は除外不可" "$d"

# --- T-24b: sed redirect + 有効 marker → 検出（grep/sed は marker 付きでも違反）---
d="$(fresh_dir)"
put "$d" "bad-sed-marker.sh" \
    '# parse-guard: allow=x (issue: #733, ref: x)' \
    'sed -nE "s/^id://p" "$f" > "$tmp"'
assert_rc 1 "T-24b sed + marker は除外不可" "$d"

# --- T-25: awk の単純 READ 抽出（行フィルタ）+ marker → 検出（atomic write idiom でない / R-int#2-r2）---
d="$(fresh_dir)"
put "$d" "bad-awk-read-marker.sh" \
    '# parse-guard: allow=looks like write but is read (issue: #733, ref: x)' \
    'awk '\''/^status:/{print}'\'' "$f" > "$tmp"'
assert_rc 1 "T-25 awk 行フィルタ READ + marker は除外不可" "$d"

# --- T-25b: jq redirect READ + marker → 検出（jq に正当な write idiom なし）---
d="$(fresh_dir)"
put "$d" "bad-jq-read-marker.sh" \
    '# parse-guard: allow=x (issue: #733, ref: x)' \
    'jq -r ".assigned // empty" <<< "$fm" > "$tmp"'
assert_rc 1 "T-25b jq READ + marker は除外不可" "$d"

# --- T-25c: 正当な awk atomic write idiom（passthrough + key 書き換え）+ marker → 除外（合格維持）---
d="$(fresh_dir)"
put "$d" "ok-awk-atomicwrite.sh" \
    '# parse-guard: allow=atomic status write (issue: #733, ref: x)' \
    'awk -v ns="$n" '\''/^status:/{print "status: " ns; next} {print}'\'' "$f" > "$tmp"'
assert_rc 0 "T-25c awk atomic write idiom + marker は除外" "$d"

# --- T-25d: passthrough なしの awk 変換（status 行のみ）+ marker → 検出（atomic write でない / R-int#2-r3）---
d="$(fresh_dir)"
put "$d" "bad-awk-transform-marker.sh" \
    '# parse-guard: allow=not atomic write (issue: #733, ref: review)' \
    'awk '\''/^status:/{print "status: " $2}'\'' "$f" > "$tmp_out"'
assert_rc 1 "T-25d passthrough なし awk 変換 + marker は除外不可" "$d"

# --- T-25e: 条件付き {print}（/^title:/{print}）は passthrough でない + marker → 検出（R-int#2-r4）---
d="$(fresh_dir)"
put "$d" "bad-awk-cond-print-marker.sh" \
    '# parse-guard: allow=not atomic write (issue: #733, ref: review)' \
    'awk '\''/^title:/{print} /^status:/{print "status: " $2}'\'' "$f" > "$tmp"'
assert_rc 1 "T-25e 条件付き {print} + marker は除外不可" "$d"

# --- T-21: リポジトリ全体の許可 marker 集合固定（R-code#5）---
# 現行で許可される allow marker は work-item-status.sh の 1 件のみ。それ以外が現れたら fail。
expected_marker_file="skills/aidlc/scripts/work-item-status.sh"
marker_files="$(cd "$REPO_ROOT" && grep -rl 'parse-guard: allow=' skills bin 2>/dev/null | grep -v 'bin/tests/check-frontmatter-parse-guard.sh' | grep -v 'bin/check-frontmatter-parse-guard.sh' | sort || true)"
if [ "$marker_files" = "$expected_marker_file" ]; then
    PASS=$((PASS + 1)); echo "  ok   : T-21 リポジトリ全体の許可 marker 集合固定（status.sh の 1 件のみ）"
else
    FAIL=$((FAIL + 1)); echo "  FAIL : T-21 許可 marker 集合が想定外: [$marker_files]（期待: $expected_marker_file）"
fi

echo ""
echo "== result: PASS=$PASS FAIL=$FAIL =="
if [ "$FAIL" -ne 0 ]; then
    exit 1
fi
exit 0
