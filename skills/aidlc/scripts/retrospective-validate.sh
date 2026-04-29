#!/usr/bin/env bash
#
# retrospective-validate.sh - retrospective.md 検証 + skill_caused ダウングレード（3 段責務）
#
# 使用方法:
#   retrospective-validate.sh extract <path>
#     → Markdown から 6 キーを抽出して TSV 中間表現を出力
#   retrospective-validate.sh validate <path>
#     → extract + 6 キー存在 / quote_min_length / forbidden_words を検証
#   retrospective-validate.sh validate <path> --apply
#     → extract + validate + 違反項目の q*_answer を yes → no に書き換え（backup + rollback）
#
# 出力:
#   stdout: extracted\t* / downgrade\t* / applied\t* / summary\t*
#   stderr: warn\t* / error\t*
#
# 終了コード:
#   0 - 正常 / 2 - fatal（rollback 完了時は error	apply-failed	rollback-completed）

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SCHEMA_PATH="${AIDLC_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/.." && pwd)}/config/retrospective-schema.yml"

# dasel 検出
if ! command -v dasel >/dev/null 2>&1; then
    echo "error	dasel-not-installed	install-required" >&2
    exit 2
fi

if [ ! -f "$SCHEMA_PATH" ]; then
    echo "error	schema-not-found	${SCHEMA_PATH}" >&2
    exit 2
fi

# 引数パース
SUBCOMMAND="${1:-}"
TARGET_PATH="${2:-}"
APPLY_FLAG=0
if [ "${3:-}" = "--apply" ]; then
    APPLY_FLAG=1
fi

if [ -z "$SUBCOMMAND" ] || [ -z "$TARGET_PATH" ]; then
    echo "error	usage	retrospective-validate.sh extract|validate <path> [--apply]" >&2
    exit 2
fi

if [ ! -f "$TARGET_PATH" ]; then
    echo "error	retrospective-not-found	${TARGET_PATH}" >&2
    exit 2
fi

# パストラバーサル対策: --apply 時は AIDLC_CYCLES 配下の retrospective.md のみ許可
# （誤操作 / 他スクリプト連携時の意図しないファイル書き換え防止 / fail-safe デフォルト）
if [ "$APPLY_FLAG" -eq 1 ]; then
    # AIDLC_CYCLES が未設定の場合は bootstrap 経由で取得
    if [ -z "${AIDLC_CYCLES:-}" ]; then
        # shellcheck source=lib/bootstrap.sh
        source "${SCRIPT_DIR}/lib/bootstrap.sh" 2>/dev/null || {
            echo "error	bootstrap-failed	cannot-resolve-AIDLC_CYCLES" >&2
            exit 2
        }
    fi
    # realpath 解決（symlink を辿る / cycle ディレクトリ脱出を防ぐ）
    if command -v realpath >/dev/null 2>&1; then
        _resolved_target="$(realpath "$TARGET_PATH" 2>/dev/null || true)"
        _resolved_root="$(realpath "$AIDLC_CYCLES" 2>/dev/null || true)"
    else
        # macOS の古い環境では python で代替
        _resolved_target="$(python3 -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$TARGET_PATH" 2>/dev/null || true)"
        _resolved_root="$(python3 -c "import os,sys;print(os.path.realpath(sys.argv[1]))" "$AIDLC_CYCLES" 2>/dev/null || true)"
    fi
    if [ -z "$_resolved_target" ] || [ -z "$_resolved_root" ]; then
        echo "error	path-resolution-failed	${TARGET_PATH}" >&2
        exit 2
    fi
    # AIDLC_CYCLES 配下チェック
    if [[ "$_resolved_target" != "$_resolved_root"/* ]]; then
        echo "error	apply-path-not-allowed	must-be-under-aidlc-cycles:${TARGET_PATH}" >&2
        exit 2
    fi
    # ファイル名は retrospective.md に限定
    if [ "$(basename "$_resolved_target")" != "retrospective.md" ]; then
        echo "error	apply-filename-not-allowed	must-be-retrospective.md:${TARGET_PATH}" >&2
        exit 2
    fi
fi

# スキーマから検証ルール読み込み（ハードコード回避 / dasel v3 syntax）
_dasel_query_yaml() {
    local query="$1"
    dasel query -i yaml "$query" <"$SCHEMA_PATH" 2>/dev/null || echo ""
}

QUOTE_MIN_LENGTH="$(_dasel_query_yaml 'retrospective_schema.skill_caused_judgment.quote_min_length')"
if [ -z "$QUOTE_MIN_LENGTH" ] || ! [[ "$QUOTE_MIN_LENGTH" =~ ^[0-9]+$ ]]; then
    QUOTE_MIN_LENGTH=10
fi

FORBIDDEN_WORDS_STR="$(_dasel_query_yaml 'retrospective_schema.skill_caused_judgment.quote_forbidden_words')"
FORBIDDEN_WORDS=()
while IFS= read -r line; do
    # YAML フロー形式 "- 該当" を処理
    line="${line#- }"
    line="${line//\"/}"
    line="$(echo "$line" | sed 's/^[ \t]*//; s/[ \t]*$//')"
    if [ -n "$line" ]; then
        FORBIDDEN_WORDS+=("$line")
    fi
done <<<"$FORBIDDEN_WORDS_STR"

readonly REQUIRED_KEYS=(q1_answer q1_quote q2_answer q2_quote q3_answer q3_quote)

# ─── extract: Markdown から YAML フロントマターを抽出 ─────────
_extract() {
    local path="$1"
    awk -v keys="q1_answer q1_quote q2_answer q2_quote q3_answer q3_quote" '
    BEGIN {
        problem_index = 0
        in_yaml = 0
    }
    /^### 問題 [0-9]+:/ {
        problem_index++
        in_yaml = 0
        next
    }
    /^### 問題なし/ {
        # 「問題なし」明示エントリは extract 対象外
        next
    }
    # コードブロック開始（yaml / yml / 末尾空白許容 / 大文字小文字非依存）
    /^```[Yy][Aa]?[Mm][Ll][[:space:]]*$/ && problem_index > 0 {
        in_yaml = 1
        next
    }
    /^```[[:space:]]*$/ && in_yaml == 1 {
        in_yaml = 0
        next
    }
    in_yaml == 1 {
        # skill_caused_judgment: 行はスキップ
        if ($0 ~ /^skill_caused_judgment:/) next
        # キー: 値 のパース（先頭スペース許容）
        line = $0
        sub(/^[ \t]+/, "", line)
        # コメント除去
        sub(/[ \t]+#.*$/, "", line)
        if (line == "") next
        # キー名抽出
        kv_pos = index(line, ":")
        if (kv_pos == 0) next
        key = substr(line, 1, kv_pos - 1)
        val = substr(line, kv_pos + 1)
        sub(/^[ \t]+/, "", val)
        # クォート除去（"..." / "..."）
        gsub(/^"|"$/, "", val)
        printf "extracted\t%d\t%s=%s\n", problem_index, key, val
    }
    END {
        printf "summary\textracted_keys\ttotal=%d\n", problem_index * 6
    }
    ' "$path"
}

# ─── validate: extract 結果を検証 ─────────
_validate() {
    local path="$1"
    local total_problems=0
    local downgraded=0
    local skill_caused_true_count=0

    # extract 出力を一時ファイルに（1 回だけ生成 / 単一スキャン化）
    local extract_tmp
    extract_tmp="$(mktemp /tmp/retrospective-extract.XXXXXX)"
    _extract "$path" >"$extract_tmp"

    # 単一の awk スキャンで問題ごとに集約 → missing/violation 判定 + skill_caused 計算まで完結
    # 入力: extract_tmp（extracted\t<idx>\t<key>=<val>）+ 検証定数（QUOTE_MIN_LENGTH / FORBIDDEN_WORDS）
    # 出力: downgrade 行 + summary 行
    # 禁止語を `|` 区切りで結合（個別単語に `|` が含まれない前提）
    local fw_joined=""
    local fw_count="${#FORBIDDEN_WORDS[@]}"
    if [ "$fw_count" -gt 0 ]; then
        local _i
        for _i in "${FORBIDDEN_WORDS[@]}"; do
            if [ -z "$fw_joined" ]; then
                fw_joined="$_i"
            else
                fw_joined="${fw_joined}|${_i}"
            fi
        done
    fi

    # awk 内で一括処理（外部プロセス起動を 1 回に削減）
    awk -F'\t' -v qmin="$QUOTE_MIN_LENGTH" -v fwords="$fw_joined" '
    BEGIN {
        # 禁止語を `|` 区切りでパース
        fw_n = split(fwords, fw_arr, "|")
        for (i = 1; i <= fw_n; i++) {
            forbidden[i] = fw_arr[i]
        }
        problem_total = 0
        downgraded = 0
        skill_caused_true = 0
    }
    $1 == "extracted" {
        idx = $2
        kv = $3
        eq_pos = index(kv, "=")
        if (eq_pos == 0) next
        key = substr(kv, 1, eq_pos - 1)
        val = substr(kv, eq_pos + 1)
        # POSIX awk は多次元配列非対応 → composite key で代用
        composite = idx SUBSEP key
        problems[composite] = val
        if (!(idx in seen)) {
            seen[idx] = 1
            problem_total++
            order[problem_total] = idx
        }
    }
    END {
        required[1] = "q1_answer"; required[2] = "q1_quote"
        required[3] = "q2_answer"; required[4] = "q2_quote"
        required[5] = "q3_answer"; required[6] = "q3_quote"

        for (i = 1; i <= problem_total; i++) {
            idx = order[i]
            # missing チェック
            missing = ""
            for (k = 1; k <= 6; k++) {
                ck = idx SUBSEP required[k]
                if (!(ck in problems)) {
                    missing = missing " " required[k]
                }
            }
            if (length(missing) > 0) {
                sub(/^ /, "", missing)
                printf "downgrade\t%s\tmissing-keys:%s\n", idx, missing
                downgraded++
                continue
            }

            # quote 検証
            violation = 0
            for (qn = 1; qn <= 3; qn++) {
                qprefix = "q" qn
                ans_key = qprefix "_answer"
                quote_key = qprefix "_quote"
                ans = problems[idx SUBSEP ans_key]
                quote = problems[idx SUBSEP quote_key]

                if (ans == "yes") {
                    if (length(quote) == 0) {
                        printf "downgrade\t%s\t%s_quote:empty\n", idx, qprefix
                        violation = 1
                        continue
                    }
                    if (length(quote) < qmin + 0) {
                        printf "downgrade\t%s\t%s_quote:length-below-%d\n", idx, qprefix, qmin
                        violation = 1
                        continue
                    }
                    # 禁止語単独 + qmin 以下チェック
                    if (length(quote) <= qmin + 0) {
                        for (j = 1; j <= fw_n; j++) {
                            if (quote == forbidden[j]) {
                                printf "downgrade\t%s\t%s_quote:forbidden-word-only:%s\n", idx, qprefix, forbidden[j]
                                violation = 1
                                break
                            }
                        }
                    }
                }
            }

            if (violation == 1) {
                downgraded++
            } else {
                if (problems[idx SUBSEP "q1_answer"] == "yes" || problems[idx SUBSEP "q2_answer"] == "yes" || problems[idx SUBSEP "q3_answer"] == "yes") {
                    skill_caused_true++
                }
            }
        }

        # 集計値を _SUMMARY タグで持ち上げる（後段でパース）
        printf "_SUMMARY\t%d\t%d\t%d\n", problem_total, downgraded, skill_caused_true
    }
    ' "$extract_tmp" > "${extract_tmp}.validate"

    # _SUMMARY 行から集計値を取り出して summary 行に変換、downgrade 行は出力
    while IFS= read -r line; do
        if [[ "$line" == _SUMMARY* ]]; then
            # _SUMMARY\ttotal\tdowngraded\tskill_caused_true
            local s_total s_down s_caused
            s_total="$(echo "$line" | cut -f2)"
            s_down="$(echo "$line" | cut -f3)"
            s_caused="$(echo "$line" | cut -f4)"
            total_problems="$s_total"
            downgraded="$s_down"
            skill_caused_true_count="$s_caused"
        else
            echo "$line"
        fi
    done < "${extract_tmp}.validate"
    rm -f "${extract_tmp}.validate"

    # extract を再出力（pipeline で apply に渡す）
    cat "$extract_tmp"
    rm -f "$extract_tmp"

    echo "summary	counts	total=${total_problems};downgraded=${downgraded};skill_caused_true=${skill_caused_true_count}"
}

# ─── apply: 違反項目の q*_answer を yes → no に書き換え ─────────
_apply() {
    local path="$1"
    # validate を実行してダウングレード対象を取得
    local validate_tmp
    validate_tmp="$(mktemp /tmp/retrospective-validate.XXXXXX)"
    _validate "$path" >"$validate_tmp"

    # downgrade 行を抽出
    local downgrade_lines
    downgrade_lines="$(grep "^downgrade	" "$validate_tmp" || true)"

    # validate 出力をそのまま流す（呼び出し側に提示）
    cat "$validate_tmp"

    if [ -z "$downgrade_lines" ]; then
        rm -f "$validate_tmp"
        return 0
    fi

    # backup 作成（mktemp で安全な path / 予測不能 / シンボリックリンク悪用防止）
    local backup
    backup="$(mktemp "${path}.bak.XXXXXX" 2>/dev/null)" || {
        echo "error	backup-mktemp-failed	${path}" >&2
        rm -f "$validate_tmp"
        return 2
    }
    if ! cp -p -- "$path" "$backup"; then
        rm -f -- "$backup"
        echo "error	backup-failed	${path}" >&2
        rm -f "$validate_tmp"
        return 2
    fi

    # トランザクション化: 失敗時は backup から復元
    local apply_failed=0
    local applied_count=0

    while IFS= read -r line; do
        # downgrade\t<idx>\t<reason>
        local idx_field="${line#downgrade$'\t'}"
        local idx="${idx_field%%	*}"
        local reason="${idx_field#*	}"
        local q="${reason%%_quote:*}"
        # missing-keys や forbidden-word-only:該当 等のケースに対応
        case "$reason" in
            "${q}_quote:empty"|"${q}_quote:length-below-"*|"${q}_quote:forbidden-word-only:"*)
                # q*_answer を yes → no に書き換え
                if ! _rewrite_answer_to_no "$path" "$idx" "$q"; then
                    apply_failed=1
                    break
                fi
                printf 'applied\t%s\t%s_answer\n' "$idx" "$q"
                applied_count=$((applied_count + 1))
                ;;
            missing-keys:*)
                # 6 キー欠落は書き換え対象外（テンプレート構造異常 / 警告のみ）
                ;;
        esac
    done <<<"$downgrade_lines"

    if [ "$apply_failed" -eq 1 ]; then
        # rollback
        if mv -- "$backup" "$path"; then
            echo "error	apply-failed	rollback-completed" >&2
        else
            echo "error	apply-failed	rollback-failed:${backup}" >&2
        fi
        rm -f "$validate_tmp"
        return 2
    fi

    rm -f -- "$backup" "$validate_tmp"
    return 0
}

# _rewrite_answer_to_no <path> <problem_index> <q>
# `### 問題 <idx>:` 直下の YAML ブロック内の `<q>_answer: yes` を `<q>_answer: no` に書き換える
_rewrite_answer_to_no() {
    local path="$1"
    local idx="$2"
    local q="$3"

    local tmp
    tmp="$(mktemp "${path}.tmp.XXXXXX")"

    awk -v idx="$idx" -v q="$q" '
    BEGIN {
        problem_count = 0
        in_target = 0
        in_yaml = 0
        rewritten = 0
    }
    /^### 問題 [0-9]+:/ {
        problem_count++
        if (problem_count == idx) {
            in_target = 1
        } else {
            in_target = 0
        }
        in_yaml = 0
        print; next
    }
    # コードブロック開始（extract と同一の緩い判定: yml / yaml / 末尾空白許容 / 大文字小文字非依存）
    in_target == 1 && /^```[Yy][Aa]?[Mm][Ll][[:space:]]*$/ {
        in_yaml = 1
        print; next
    }
    in_target == 1 && in_yaml == 1 && /^```[[:space:]]*$/ {
        in_yaml = 0
        print; next
    }
    in_target == 1 && in_yaml == 1 && rewritten == 0 {
        # `  q1_answer: "yes"` または `q1_answer: yes` を no に
        pattern = "^([ \\t]*)" q "_answer:[ \\t]+\"?yes\"?"
        if (match($0, pattern)) {
            indent = substr($0, RSTART, RLENGTH)
            sub(q "_answer:[ \\t]+\"?yes\"?", q "_answer: \"no\"", $0)
            rewritten = 1
            print; next
        }
    }
    { print }
    END {
        # rewritten == 1 を成功条件として exit code に反映
        if (rewritten == 1) {
            exit 0
        } else {
            exit 1
        }
    }
    ' "$path" >"$tmp"
    local awk_rc=$?

    if [ "$awk_rc" -ne 0 ]; then
        # rewritten==0（書き換え対象未検出 / コードブロック検出ミス等）→ fail-safe で rollback 起動
        rm -f -- "$tmp"
        return 1
    fi

    if mv -- "$tmp" "$path"; then
        return 0
    else
        rm -f -- "$tmp"
        return 1
    fi
}

# ─── メイン分岐 ─────────
case "$SUBCOMMAND" in
    extract)
        _extract "$TARGET_PATH"
        ;;
    validate)
        if [ "$APPLY_FLAG" -eq 1 ]; then
            _apply "$TARGET_PATH"
        else
            _validate "$TARGET_PATH"
        fi
        ;;
    *)
        echo "error	unknown-subcommand	${SUBCOMMAND}" >&2
        exit 2
        ;;
esac
