#!/usr/bin/env bash
# BATS テストの cwd 依存パターン静的解析スクリプト
# 検査対象関数（teardown / teardown_file / setup / setup_file / @test）内で
# `rm -rf` の前に安全な作業ディレクトリへの `cd` ガードがない場合を violation として検出する
# 致命パターン（rm -rf "$REPO_ROOT" / .aidlc/... / "$(pwd)" / $HOME/...）は severity:fatal
# Usage: check-test-isolation.sh [options]

set -euo pipefail

CHECK_NAME="check-test-isolation"
DEFAULT_TARGET_DIRS=("tests" "bin/tests")
ALLOWLIST_FILE="bin/check-test-isolation.allowlist"

REPO_ROOT=""
ALLOW_PARSE_WARN=false
VERBOSE=false
VIOLATION_COUNT=0
FATAL_COUNT=0
ALLOWED_COUNT=0
FILE_COUNT=0
INTEGRITY_VIOLATION_COUNT=0

show_usage() {
    cat <<EOF
Usage: $(basename "$0") [options]

BATS テストの cwd 依存パターンを静的解析で検出します。

検査対象:
  - tests/**/*.bats
  - bin/tests/**/*.bats

検査対象関数:
  - @test "..." ブロック
  - teardown / teardown_file / setup / setup_file 関数

Options:
  --allow-parse-warn   parse 失敗を warn として継続（既定: fail-closed exit 1）
  -v, --verbose        詳細出力
  -h, --help           このヘルプを表示

Exit codes:
  0  違反なし
  1  違反検出（通常 / 致命 / allowlist 期限切れ / stale / parse 失敗）
  2  スクリプトエラー（awk 不在 / リポジトリ外 / allowlist ファイル読み込み失敗）

出力フォーマット (4 カラム TSV、1 件 1 行):
  error\t<check_name>\t<file>:<line>\t<reason>
EOF
}

emit_violation() {
    local file="$1"
    local line="$2"
    local reason="$3"
    printf 'error\t%s\t%s:%s\t%s\n' "${CHECK_NAME}" "${file}" "${line}" "${reason}" >&2
}

emit_system_error() {
    local reason="$1"
    printf 'error\t%s\t%s\t%s\n' "${CHECK_NAME}" "system:0" "${reason}" >&2
}

# 日付の妥当性検証（YYYY-MM-DD + 月/日の範囲）
is_valid_date() {
    local d="$1"
    # フォーマット: YYYY-MM-DD
    case "$d" in
        [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]) ;;
        *) return 1 ;;
    esac
    local month="${d:5:2}"
    local day="${d:8:2}"
    # 範囲チェック (うるう年厳密判定までは行わないが、明らかに不正な値は弾く)
    if [ "$month" -lt 1 ] || [ "$month" -gt 12 ] 2>/dev/null; then return 1; fi
    if [ "$day" -lt 1 ] || [ "$day" -gt 31 ] 2>/dev/null; then return 1; fi
    return 0
}

# allowlist 読み込み (fail-closed: 1 行でも不正なら exit 1)
# 出力: TSV 形式の行を一時ファイルへ
# Returns: 0 = success, 1 = malformed, 2 = io error
load_allowlist() {
    local path="$1"
    local out_file="$2"

    : > "$out_file"

    if [ ! -f "$path" ]; then
        # ファイル未存在は OK（allowlist なし）
        return 0
    fi

    local line_no=0
    local line
    while IFS=$'\n' read -r line || [ -n "$line" ]; do
        line_no=$((line_no + 1))
        # コメント・空行スキップ
        case "$line" in
            \#*|"")
                continue
                ;;
        esac
        # タブ区切り 6 列を厳密に検証 (awk で列数チェック)
        local col_count
        col_count=$(printf '%s\n' "$line" | awk -F'\t' '{print NF}')
        if [ "$col_count" -ne 6 ]; then
            emit_violation "${path}" "${line_no}" "allowlist-malformed-column-count:expected-6-got-${col_count}"
            return 1
        fi
        # 各列を抽出
        local file_path function_name reason added_date tracking_issue expiry_date
        file_path=$(printf '%s\n' "$line" | awk -F'\t' '{print $1}')
        function_name=$(printf '%s\n' "$line" | awk -F'\t' '{print $2}')
        reason=$(printf '%s\n' "$line" | awk -F'\t' '{print $3}')
        added_date=$(printf '%s\n' "$line" | awk -F'\t' '{print $4}')
        tracking_issue=$(printf '%s\n' "$line" | awk -F'\t' '{print $5}')
        expiry_date=$(printf '%s\n' "$line" | awk -F'\t' '{print $6}')
        # 各列が空でないことを確認
        if [ -z "$file_path" ] || [ -z "$function_name" ] || [ -z "$reason" ] \
           || [ -z "$added_date" ] || [ -z "$tracking_issue" ] || [ -z "$expiry_date" ]; then
            emit_violation "${path}" "${line_no}" "allowlist-malformed-empty-column"
            return 1
        fi
        # 日付の妥当性検証
        if ! is_valid_date "$added_date"; then
            emit_violation "${path}" "${line_no}" "allowlist-malformed-added-date:${added_date}"
            return 1
        fi
        if ! is_valid_date "$expiry_date"; then
            emit_violation "${path}" "${line_no}" "allowlist-malformed-expiry-date:${expiry_date}"
            return 1
        fi
        printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${file_path}" "${function_name}" "${reason}" "${added_date}" "${tracking_issue}" "${expiry_date}" >> "$out_file"
    done < "$path"

    return 0
}

# allowlist の出口条件チェック (期限切れ + stale)
# stale 判定: 対象ファイル不在 OR 検査スクリプトを実行しても (file_path, function_name, reason) の violation が再現しない
check_allowlist_integrity() {
    local allowlist_tsv="$1"
    local repo_root="$2"
    local current_violations="$3"  # 検査スクリプトで検出された通常 violation の TSV: file\tfunction\treason
    local today
    today=$(date +%Y-%m-%d)

    local file_path function_name reason added_date tracking_issue expiry_date
    local entry_no=0
    while IFS=$'\t' read -r file_path function_name reason added_date tracking_issue expiry_date; do
        entry_no=$((entry_no + 1))
        # 期限切れ判定
        if [ "${expiry_date}" \< "${today}" ]; then
            emit_violation "${ALLOWLIST_FILE}" "${entry_no}" "allowlist-expired:${file_path}:${function_name}:${expiry_date}"
            INTEGRITY_VIOLATION_COUNT=$((INTEGRITY_VIOLATION_COUNT + 1))
            continue
        fi
        # stale 判定: 対象ファイル不在
        if [ ! -f "${repo_root}/${file_path}" ]; then
            emit_violation "${ALLOWLIST_FILE}" "${entry_no}" "allowlist-stale-file-missing:${file_path}"
            INTEGRITY_VIOLATION_COUNT=$((INTEGRITY_VIOLATION_COUNT + 1))
            continue
        fi
        # stale 判定: 該当 (file, function, reason) の violation が現在検出されていない
        # current_violations: file\tfunction\treason 形式で 1 行 1 件 (実タブ区切り)
        local match_line
        match_line=$(printf '%s\t%s\t%s' "${file_path}" "${function_name}" "${reason}")
        if ! grep -F -x -q -- "${match_line}" "${current_violations}"; then
            emit_violation "${ALLOWLIST_FILE}" "${entry_no}" "allowlist-stale-violation-resolved:${file_path}:${function_name}:${reason}"
            INTEGRITY_VIOLATION_COUNT=$((INTEGRITY_VIOLATION_COUNT + 1))
        fi
    done < "$allowlist_tsv"
}

# 致命パターン判定 (rm -rf のターゲット文字列チェック)
is_fatal_target() {
    local target="$1"
    case "$target" in
        *'$REPO_ROOT'*|*'${REPO_ROOT}'*) return 0 ;;
        *'.aidlc/'*) return 0 ;;
        *'$(pwd)'*|*'${PWD}'*|*'$PWD'*) return 0 ;;
        *'$HOME/'*|*'${HOME}/'*) return 0 ;;
    esac
    return 1
}

# 安全な cd ガード判定
is_safe_cd_target() {
    local target="$1"
    case "$target" in
        '"$BATS_TMPDIR"'|'"$BATS_TEST_TMPDIR"'|'"$BATS_FILE_TMPDIR"'|'"$TMP"') return 0 ;;
        '"$(mktemp '*) return 0 ;;
        '"$(mktemp'*) return 0 ;;
        *'mktemp -d'*) return 0 ;;
    esac
    return 1
}

# violation が allowlist にあるかチェック (3 つ組完全一致 / fatal は対象外)
is_in_allowlist() {
    local allowlist_tsv="$1"
    local file_path="$2"
    local function_name="$3"
    local reason="$4"
    local severity="$5"

    if [ "${severity}" = "fatal" ]; then
        # 致命は allowlist 対象外
        return 1
    fi

    local al_file al_func al_reason al_added al_track al_expiry
    while IFS=$'\t' read -r al_file al_func al_reason al_added al_track al_expiry; do
        if [ "${al_file}" = "${file_path}" ] && [ "${al_func}" = "${function_name}" ] && [ "${al_reason}" = "${reason}" ]; then
            return 0
        fi
    done < "$allowlist_tsv"
    return 1
}

# BATS 関数の検査本体
# awk で関数スコープを抽出し、各関数内の rm -rf と cd ガードの先後関係を判定
# 通常 violation を current_violations_file に file\tfunction\treason 形式で追記する
check_bats_file() {
    local file="$1"
    local rel_file="$2"
    local allowlist_tsv="$3"
    local current_violations_file="$4"

    FILE_COUNT=$((FILE_COUNT + 1))

    if ! awk -v file="$rel_file" '
        function flush_function() {
            if (current_func == "") return
            # この関数内の rm -rf と cd ガードを評価
            for (i = 1; i <= rm_count; i++) {
                rm_line = rm_lines[i]
                rm_target = rm_targets[i]
                # 同関数内で当該 rm の前に safe cd があったか
                guard_found = 0
                for (j = 1; j <= cd_count; j++) {
                    if (cd_lines[j] < rm_line && cd_safes[j]) {
                        guard_found = 1
                        break
                    }
                }
                # 致命パターン判定
                fatal = 0
                if (rm_target ~ /\$REPO_ROOT|\$\{REPO_ROOT\}|\.aidlc\/|\$\(pwd\)|\$\{PWD\}|\$PWD|\$HOME\/|\$\{HOME\}\//) {
                    fatal = 1
                }
                if (fatal) {
                    print "VIOLATION\tfatal\t" file "\t" rm_line "\t" current_func "\tfatal-rm-rf:" rm_target
                } else if (!guard_found) {
                    print "VIOLATION\tregular\t" file "\t" rm_line "\t" current_func "\trm-rf-without-cd-guard"
                }
            }
            current_func = ""; rm_count = 0; cd_count = 0; depth = 0
        }

        BEGIN { current_func = ""; depth = 0; rm_count = 0; cd_count = 0 }

        # 関数定義開始の検出
        # @test "name" { ... } / function foo() { ... } / foo() { ... } / teardown() { ... }
        current_func == "" && /^[[:space:]]*@test[[:space:]]+/ {
            # @test "name" { 形式
            match($0, /@test[[:space:]]+"[^"]*"/)
            func_name = substr($0, RSTART, RLENGTH)
            current_func = func_name
            # 同行の { を depth カウント
            depth = 0
            for (k = 1; k <= length($0); k++) {
                ch = substr($0, k, 1)
                if (ch == "{") depth++
                else if (ch == "}") depth--
            }
            next
        }
        current_func == "" && /^[[:space:]]*(function[[:space:]]+)?(setup|teardown|setup_file|teardown_file)[[:space:]]*\([[:space:]]*\)[[:space:]]*\{/ {
            match($0, /(setup_file|teardown_file|setup|teardown)/)
            func_name = substr($0, RSTART, RLENGTH)
            current_func = func_name
            depth = 0
            for (k = 1; k <= length($0); k++) {
                ch = substr($0, k, 1)
                if (ch == "{") depth++
                else if (ch == "}") depth--
            }
            next
        }

        # 関数内の処理
        current_func != "" {
            # depth カウント更新
            for (k = 1; k <= length($0); k++) {
                ch = substr($0, k, 1)
                if (ch == "{") depth++
                else if (ch == "}") depth--
            }

            # rm -rf 検出
            if ($0 ~ /rm[[:space:]]+-rf[[:space:]]+/) {
                # 行内で rm -rf 以降の文字列をターゲットとして抽出 (簡易)
                pos = index($0, "rm -rf")
                if (pos == 0) pos = match($0, /rm[[:space:]]+-rf/)
                if (pos > 0) {
                    rest = substr($0, pos + 6)
                    sub(/^[[:space:]]+/, "", rest)
                    rm_count++
                    rm_lines[rm_count] = NR
                    rm_targets[rm_count] = rest
                }
            }

            # cd 検出
            if ($0 ~ /^[[:space:]]*cd[[:space:]]+/) {
                pos = match($0, /^[[:space:]]*cd[[:space:]]+/)
                if (pos > 0) {
                    rest = substr($0, RSTART + RLENGTH)
                    sub(/[[:space:]].*$/, "", rest)
                    cd_count++
                    cd_lines[cd_count] = NR
                    safe = 0
                    if (rest == "\"$BATS_TMPDIR\"" || rest == "\"$BATS_TEST_TMPDIR\"" || rest == "\"$BATS_FILE_TMPDIR\"" || rest == "\"$TMP\"") {
                        safe = 1
                    } else if (rest ~ /^"\$\(mktemp/ || $0 ~ /cd[[:space:]]+"\$\(mktemp[[:space:]]+-d/) {
                        safe = 1
                    }
                    cd_safes[cd_count] = safe
                }
            }

            # 関数終端
            if (depth == 0) {
                flush_function()
            }
        }

        END {
            # depth 不整合検知: 関数の途中でファイル終端に達した場合のみ
            # (ファイル全体 depth は文字列リテラル内の括弧で誤カウントされるため使わない)
            if (current_func != "") {
                print "PARSE_ERROR\tunclosed-function\t" current_func "\t" depth
            }
            flush_function()
        }
    ' "$file" > "${TMP_VIOLATIONS_RAW}" 2>/dev/null; then
        if [ "$ALLOW_PARSE_WARN" = "true" ]; then
            echo "warn: parse failed: ${rel_file}" >&2
        else
            emit_violation "${rel_file}" "0" "parse-failed"
            VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
        fi
        return
    fi

    # PARSE_ERROR レコード検知 (関数の途中でファイル終端に達した場合のみ)
    # 注: awk の括弧カウントは文字列リテラル内も含むため誤検知が出る場合があり、
    # info レベルとして emit する (violation としてはカウントしない)。
    # 真の parse 失敗 (awk が non-zero で exit) は別途 fail-closed で扱う。
    if grep -q "^PARSE_ERROR" "${TMP_VIOLATIONS_RAW}" 2>/dev/null; then
        if [ "$VERBOSE" = "true" ]; then
            echo "info: possible unclosed function (may be a false positive due to string literal braces): ${rel_file}" >&2
        fi
        # PARSE_ERROR 行は除外して通常処理
        grep -v "^PARSE_ERROR" "${TMP_VIOLATIONS_RAW}" > "${TMP_VIOLATIONS_RAW}.filtered" || true
        mv "${TMP_VIOLATIONS_RAW}.filtered" "${TMP_VIOLATIONS_RAW}"
    fi

    # awk 出力を violation として処理
    local kind file_v line_v func_v reason
    while IFS=$'\t' read -r tag kind file_v line_v func_v reason; do
        [ "$tag" = "VIOLATION" ] || continue
        if is_in_allowlist "$3" "$file_v" "$func_v" "$reason" "$kind"; then
            ALLOWED_COUNT=$((ALLOWED_COUNT + 1))
            if [ "$VERBOSE" = "true" ]; then
                echo "  [ALLOWED] ${file_v}:${line_v} ${func_v} ${reason}" >&2
            fi
            continue
        fi
        if [ "$kind" = "fatal" ]; then
            FATAL_COUNT=$((FATAL_COUNT + 1))
            emit_violation "${file_v}" "${line_v}" "severity:fatal ${reason}"
        else
            VIOLATION_COUNT=$((VIOLATION_COUNT + 1))
            emit_violation "${file_v}" "${line_v}" "${reason}"
            # current_violations_file に記録 (allowlist stale 判定用)
            printf '%s\t%s\t%s\n' "${file_v}" "${func_v}" "${reason}" >> "${current_violations_file}"
        fi
    done < "${TMP_VIOLATIONS_RAW}"
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
            --allow-parse-warn)
                ALLOW_PARSE_WARN=true
                shift
                ;;
            *)
                emit_system_error "unknown-option:$1"
                show_usage >&2
                exit 2
                ;;
        esac
    done

    # awk 不在チェック
    if ! command -v awk >/dev/null 2>&1; then
        emit_system_error "awk-not-found"
        exit 2
    fi

    # リポジトリルート取得
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
        emit_system_error "not-in-git-repo"
        exit 2
    }

    cd "$REPO_ROOT" || {
        emit_system_error "cd-repo-root-failed"
        exit 2
    }

    # 安全な一時ディレクトリを mktemp で作成し trap で確実削除
    local tmpdir
    tmpdir=$(mktemp -d -t check-test-isolation.XXXXXX) || {
        emit_system_error "mktemp-failed"
        exit 2
    }
    trap 'rm -rf "$tmpdir"' EXIT INT TERM
    local allowlist_tsv="${tmpdir}/allowlist.tsv"
    local current_violations="${tmpdir}/current-violations.tsv"
    TMP_VIOLATIONS_RAW="${tmpdir}/violations-raw.tsv"
    : > "$current_violations"

    # allowlist 読み込み (fail-closed)
    if ! load_allowlist "$ALLOWLIST_FILE" "$allowlist_tsv"; then
        # malformed line 検出時の violation は emit 済み
        echo "${CHECK_NAME}: allowlist parse failed (fail-closed)" >&2
        exit 1
    fi

    # 検査対象 BATS ファイル列挙
    # 除外パス: bin/tests/check-test-isolation/fixtures/ (検出器自身のフィクスチャ)
    local bats_files=()
    local d
    for d in "${DEFAULT_TARGET_DIRS[@]}"; do
        if [ -d "${REPO_ROOT}/${d}" ]; then
            while IFS= read -r -d '' f; do
                case "$f" in
                    *"/bin/tests/check-test-isolation/fixtures/"*)
                        continue
                        ;;
                    *"/bin/tests/check-test-isolation/end_to_end_test.bats")
                        # end_to_end_test.bats は heredoc 内に検査対象パターンを含むため除外
                        continue
                        ;;
                esac
                bats_files+=("$f")
            done < <(find "${REPO_ROOT}/${d}" -type f -name '*.bats' -print0)
        fi
    done

    # 各ファイル検査 (current_violations に通常 violation を追記)
    local f rel_f
    for f in "${bats_files[@]}"; do
        rel_f="${f#${REPO_ROOT}/}"
        check_bats_file "$f" "$rel_f" "$allowlist_tsv" "$current_violations"
    done

    # allowlist 出口条件チェック (期限切れ + stale: 現在の通常 violation TSV を使用)
    check_allowlist_integrity "$allowlist_tsv" "$REPO_ROOT" "$current_violations"

    # サマリ
    local total_violations=$((VIOLATION_COUNT + FATAL_COUNT + INTEGRITY_VIOLATION_COUNT))
    if [ "$total_violations" -eq 0 ]; then
        echo "${CHECK_NAME}: no violations, ${FILE_COUNT} files checked, ${ALLOWED_COUNT} allowlist matches"
        exit 0
    else
        echo "${CHECK_NAME}: ${total_violations} violations (fatal:${FATAL_COUNT} regular:${VIOLATION_COUNT} integrity:${INTEGRITY_VIOLATION_COUNT}), ${FILE_COUNT} files checked, ${ALLOWED_COUNT} allowlist matches" >&2
        exit 1
    fi
}

main "$@"
