#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/lib/bootstrap.sh"

# squash-unit.sh - Unit完了時に中間コミットを1つにまとめるsquashスクリプト
# git環境（git reset --soft方式）に対応

# --- グローバル変数 ---
CYCLE=""
UNIT=""  # オプション: 呼び出し元との契約として受け取るが、現在のロジックでは未使用
MESSAGE=""
MESSAGE_FILE=""
DRY_RUN=false
VCS_TYPE=""
BASE_COMMIT=""
TARGET_COUNT=0
CO_AUTHORS=""
SAVED_HEAD=""
RETROACTIVE=false
UNIT_FIRST_COMMIT=""
UNIT_FIRST_COMMIT_FULL=""
UNIT_LAST_COMMIT=""
UNIT_LAST_COMMIT_FULL=""
UNIT_COMMIT_HASHES=""
TREE_HASH_BEFORE=""
FROM_COMMIT=""
TO_COMMIT=""
TMPFILES=()

# 一時ファイルのクリーンアップ用trap
trap 'for f in "${TMPFILES[@]}"; do [[ -f "$f" ]] && \rm -f "$f"; done' EXIT

# --- ヘルプ・引数解析 ---

show_help() {
    cat <<'EOF'
Usage: squash-unit.sh [OPTIONS]

Unit完了時に中間コミットを1つにまとめるsquashスクリプト。

Required:
  --cycle <CYCLE>         サイクル名（例: v1.15.0）
  --message <MESSAGE>     squash後のコミットメッセージ（--message-fileと排他）。
                          複数回指定可（git commit -m 準拠: 1個目=件名、
                          2個目以降=空行区切りの本文段落として段落結合）。
  --message-file <PATH>   コミットメッセージをファイルから読み込み（--messageと排他）
  --vcs <git>              使用するVCS種類

Optional:
  --unit <UNIT_NUMBER>    Unit番号（例: 001）。--retroactive時は必須。
  --base <COMMIT>         起点コミット（gitハッシュ）を明示指定。
                          省略時はコミットメッセージのパターンから自動検出。
  --retroactive           事後squashモード。過去のUnit（HEAD以外）をrebase方式でsquash。
                          --vcs=git のみ対応。--unit 必須。
  --from <COMMIT>         retroactive時のUnit開始コミット（--to と同時指定必須、--baseと排他）
  --to <COMMIT>           retroactive時のUnit終了コミット（--from と同時指定必須、--baseと排他）
  --dry-run               実際のsquashを実行せず対象コミットの表示のみ
  -h, --help              このヘルプを表示

Examples:
  squash-unit.sh --cycle v1.15.0 --unit 001 --vcs git --message "feat: [v1.15.0] Unit 001完了 - squashスクリプト作成"
  squash-unit.sh --cycle v1.15.0 --vcs git --message "feat: ..." --base abc1234
  squash-unit.sh --cycle v1.15.0 --vcs git --message "feat: ..." --dry-run
  squash-unit.sh --cycle v1.17.0 --unit 003 --vcs git --retroactive --message "feat: [v1.17.0] Unit 003完了 - 説明"
  squash-unit.sh --cycle v1.17.0 --unit 003 --vcs git --retroactive --from abc1234 --to def5678 --message "feat: ..."
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --cycle)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --cycle requires a value" >&2
                    exit 1
                fi
                CYCLE="$2"
                shift 2
                ;;
            --unit)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --unit requires a value" >&2
                    exit 1
                fi
                UNIT="$2"
                shift 2
                ;;
            --message)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --message requires a value" >&2
                    exit 1
                fi
                # 複数 --message を git commit -m 準拠で段落結合（1 個目=件名、
                # 2 個目以降=空行区切りの本文段落）。単一指定は従来同値（後方互換）。
                if [[ -z "$MESSAGE" ]]; then
                    MESSAGE="$2"
                else
                    MESSAGE="${MESSAGE}"$'\n\n'"$2"
                fi
                shift 2
                ;;
            --message-file)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --message-file requires a value" >&2
                    exit 1
                fi
                MESSAGE_FILE="$2"
                shift 2
                ;;
            --vcs)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --vcs requires a value (git)" >&2
                    exit 1
                fi
                if [[ "$2" != "git" ]]; then
                    echo "Error: --vcs must be 'git', got: $2" >&2
                    exit 1
                fi
                VCS_TYPE="$2"
                shift 2
                ;;
            --base)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --base requires a value" >&2
                    exit 1
                fi
                BASE_COMMIT="$2"
                shift 2
                ;;
            --from)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --from requires a value" >&2
                    exit 1
                fi
                FROM_COMMIT="$2"
                shift 2
                ;;
            --to)
                if [[ -z "${2:-}" ]]; then
                    echo "Error: --to requires a value" >&2
                    exit 1
                fi
                TO_COMMIT="$2"
                shift 2
                ;;
            --retroactive)
                RETROACTIVE=true
                shift
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                echo "Error: unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    if [[ -z "$CYCLE" ]]; then
        echo "Error: --cycle is required" >&2
        exit 1
    fi
    # --message と --message-file の排他チェック・ファイル読み込み
    if [[ -n "$MESSAGE_FILE" ]]; then
        if [[ -n "$MESSAGE" ]]; then
            echo "Error: --message and --message-file are mutually exclusive" >&2
            exit 1
        fi
        if [[ ! -f "$MESSAGE_FILE" ]]; then
            echo "Error: file not found: $MESSAGE_FILE" >&2
            exit 1
        fi
        if [[ ! -s "$MESSAGE_FILE" ]]; then
            echo "Error: file is empty: $MESSAGE_FILE" >&2
            exit 1
        fi
        MESSAGE="$(cat "$MESSAGE_FILE")"
    fi
    if [[ "$DRY_RUN" != "true" ]] && [[ -z "$MESSAGE" ]]; then
        echo "Error: --message is required" >&2
        exit 1
    fi
    if [[ -z "$VCS_TYPE" ]]; then
        echo "Error: --vcs is required" >&2
        exit 1
    fi
}

# --- 入力バリデーション ---

# git commit hashの形式を検証（revset演算子の混入を防止）
validate_base_format() {
    local base="$1"
    local vcs_type="$2"
    # 英数字とハイフン・アンダースコアのみ許可（revset演算子 |&()~.. 等を拒否）
    if [[ ! "$base" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "Error: --base contains invalid characters: ${base}" >&2
        echo "Error: Only alphanumeric, hyphen, and underscore are allowed" >&2
        echo "squash:error:invalid-base-format"
        exit 1
    fi
}

validate_from_to_args() {
    # --from/--to は両方同時に指定する必要がある
    if [[ -n "$FROM_COMMIT" && -z "$TO_COMMIT" ]] || [[ -z "$FROM_COMMIT" && -n "$TO_COMMIT" ]]; then
        echo "Error: --from and --to must be specified together" >&2
        exit 1
    fi

    # --from/--to 未指定時は何もしない
    if [[ -z "$FROM_COMMIT" ]]; then
        return
    fi

    # --from/--to と --base は排他
    if [[ -n "$BASE_COMMIT" ]]; then
        echo "Error: --from/--to and --base are mutually exclusive in retroactive mode" >&2
        exit 1
    fi

    # 入力バリデーション（revset演算子混入防止）
    validate_base_format "$FROM_COMMIT" "$VCS_TYPE"
    validate_base_format "$TO_COMMIT" "$VCS_TYPE"

    # フルハッシュへ正規化（-- でオプション注入を防止）
    local from_full to_full
    if ! from_full=$(git rev-parse --verify "${FROM_COMMIT}^{commit}" 2>/dev/null); then
        echo "Error: --from ${FROM_COMMIT} is not a valid commit" >&2
        echo "squash:error:invalid-from"
        exit 1
    fi
    if ! to_full=$(git rev-parse --verify "${TO_COMMIT}^{commit}" 2>/dev/null); then
        echo "Error: --to ${TO_COMMIT} is not a valid commit" >&2
        echo "squash:error:invalid-to"
        exit 1
    fi
    FROM_COMMIT="$from_full"
    TO_COMMIT="$to_full"

    # --from が --to の祖先（またはイコール）であることを検証
    if [[ "$FROM_COMMIT" != "$TO_COMMIT" ]]; then
        if ! git merge-base --is-ancestor "$FROM_COMMIT" "$TO_COMMIT" 2>/dev/null; then
            echo "Error: --from ${FROM_COMMIT:0:7} is not an ancestor of --to ${TO_COMMIT:0:7}" >&2
            echo "squash:error:from-not-ancestor"
            exit 1
        fi
    fi
}

validate_retroactive_args() {
    if [[ -z "$UNIT" ]]; then
        echo "Error: --unit is required when using --retroactive" >&2
        exit 1
    fi
    if [[ ! "$UNIT" =~ ^[0-9]{3}$ ]]; then
        echo "Error: --unit must be a 3-digit number (e.g., 003), got: ${UNIT}" >&2
        exit 1
    fi
    if [[ "$((10#$UNIT))" -lt 1 ]]; then
        echo "Error: --unit must be 001 or greater, got: ${UNIT}" >&2
        exit 1
    fi
}

# --- ルートコミット判定 ---

# 指定コミットがルートコミット（親なし）かどうかを判定
# 引数: $1=コミットハッシュ（short or full）
# 戻り値: 0=ルートコミット, 1=ルートコミットではない（無効ハッシュ含む）
is_root_commit() {
    local hash="$1"
    # コミットの存在を確認（無効ハッシュの誤判定を防止）
    if ! git cat-file -e "${hash}^{commit}" 2>/dev/null; then
        return 1
    fi
    if ! git rev-parse "${hash}^" >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

# ルートコミット対応のgit log用範囲引数を構築
# 引数: $1=first_hash, $2=last_hash
# 出力: git log に渡す範囲引数（stdout）
# 通常時: first^..last（firstを含む）
# ルートコミット時: last（ルートからlastまで全コミットを含む）
safe_log_range() {
    local first="$1"
    local last="$2"
    if is_root_commit "$first"; then
        echo "$last"
    else
        echo "${first}^..${last}"
    fi
}

# ルートコミット対応のgit rebase起点引数を構築
# 引数: $1=first_hash
# 出力: git rebase -i に渡す引数（stdout）
# 通常時: first^ を出力、終了コード0
# ルートコミット時: --root を出力、終了コード0
rebase_base_args() {
    local first="$1"
    if is_root_commit "$first"; then
        echo "--root"
    else
        git rev-parse "${first}^" 2>/dev/null
    fi
}

# --- 起点特定 ---

find_base_commit_git() {
    local cycle="$1"
    local base_hash=""
    local line
    local log_output
    local merge_base=""

    # サイクルブランチの分岐点を特定し、その範囲内で検索
    merge_base=$(git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD 2>/dev/null || git merge-base origin/master HEAD 2>/dev/null || git merge-base master HEAD 2>/dev/null || true)

    local log_range=""
    local head_hash
    if ! head_hash=$(git rev-parse HEAD 2>&1); then
        echo "Error: no commits in this repository (unborn HEAD)" >&2
        echo "squash:error:no-head"
        exit 1
    fi
    if [[ -n "$merge_base" && "$merge_base" != "$head_hash" ]]; then
        log_range="${merge_base}..HEAD"
    else
        # mainブランチ上または分岐点が見つからない場合はエラー
        echo "Error: cannot determine branch range. Are you on a cycle branch? Use --base to specify explicitly." >&2
        echo "squash:error:no-branch-range"
        exit 1
    fi

    # git log の実行可否を先に確認
    if ! log_output=$(git log --format="%H %s" $log_range 2>&1); then
        echo "Error: git log failed: ${log_output}" >&2
        echo "squash:error:git-log-failed"
        exit 1
    fi

    # パターン: feat: [CYCLE] または chore: [CYCLE] ... Phase完了
    while IFS= read -r line; do
        local hash subject
        hash="${line%% *}"
        subject="${line#* }"
        if [[ "$subject" == "feat: [${cycle}]"* ]] || [[ "$subject" == "chore: [${cycle}]"*"Phase完了" ]]; then
            base_hash="$hash"
            break
        fi
    done <<< "$log_output"

    if [[ -z "$base_hash" ]]; then
        echo "Error: base commit not found for cycle ${cycle}. Expected 'feat: [${cycle}] ...' or 'chore: [${cycle}] ... Phase完了' pattern." >&2
        echo "squash:error:base-not-found"
        exit 1
    fi

    BASE_COMMIT="$base_hash"
    echo "base_commit:${BASE_COMMIT}"
}

# --- Unit範囲特定（retroactive用） ---

find_unit_commit_range_git() {
    local cycle="$1"
    local unit="$2"

    # === 戦略1: --from/--to 直接指定 ===
    if [[ -n "$FROM_COMMIT" && -n "$TO_COMMIT" ]]; then
        local log_output
        if ! log_output=$(git log --reverse --format="%h %H %s" "${FROM_COMMIT}^..${TO_COMMIT}" 2>&1); then
            echo "Error: git log failed for --from/--to range: ${log_output}" >&2
            echo "squash:error:git-log-failed"
            exit 1
        fi
        if [[ -z "$log_output" ]]; then
            echo "Error: no commits found in range ${FROM_COMMIT:0:7}..${TO_COMMIT:0:7}" >&2
            echo "squash:error:unit-not-found"
            exit 1
        fi
        local first_line last_line
        first_line=$(echo "$log_output" | head -1)
        last_line=$(echo "$log_output" | tail -1)
        UNIT_FIRST_COMMIT="${first_line%% *}"
        local rest="${first_line#* }"
        UNIT_FIRST_COMMIT_FULL="${rest%% *}"
        UNIT_LAST_COMMIT="${last_line%% *}"
        rest="${last_line#* }"
        UNIT_LAST_COMMIT_FULL="${rest%% *}"
        UNIT_COMMIT_HASHES=$(echo "$log_output" | awk '{print $1}')
        return
    fi

    # === 共通: 検索範囲の決定 ===
    local log_range=""
    if [[ -n "$BASE_COMMIT" ]]; then
        log_range="${BASE_COMMIT}..HEAD"
    else
        local merge_base=""
        merge_base=$(git merge-base origin/main HEAD 2>/dev/null || git merge-base main HEAD 2>/dev/null || git merge-base origin/master HEAD 2>/dev/null || git merge-base master HEAD 2>/dev/null || true)
        local head_hash
        if ! head_hash=$(git rev-parse HEAD 2>&1); then
            echo "Error: no commits in this repository (unborn HEAD)" >&2
            echo "squash:error:no-head"
            exit 1
        fi
        if [[ -n "$merge_base" && "$merge_base" != "$head_hash" ]]; then
            log_range="${merge_base}..HEAD"
        else
            echo "Error: cannot determine branch range. Use --base or --from/--to to specify explicitly." >&2
            echo "squash:error:no-branch-range"
            exit 1
        fi
    fi

    # === 戦略2: トレーラー検索 ===
    # subject + Unit-Number trailerを同時取得（Unit Separator 0x1F区切り）
    # 注: NUL(0x00)はコマンド置換で消失するため、0x1Fを使用
    local trailer_log
    if trailer_log=$(git log --reverse --format="%h %H %s%x1F%(trailers:key=Unit-Number,valueonly)" "$log_range" 2>/dev/null); then
        local prev_unit_num prev_unit
        prev_unit_num=$((10#$unit - 1))
        prev_unit=$(printf "%03d" "$prev_unit_num")

        # トレーラーの存在を確認
        local has_any_trailer=false
        local trailer_start_boundary="" trailer_end_boundary=""
        local trailer_end_subject=""
        local t_first_short="" t_first_full=""
        local t_last_short="" t_last_full=""
        local t_in_unit=false t_found_start=false
        local t_hashes=""
        local t_line t_subject_part t_trailer_part
        local target_unit_pattern_for_trailer="feat: [${cycle}] Unit ${unit}完了"

        while IFS= read -r t_line; do
            # 空行をスキップ（トレーラー出力の改行で生じる空レコード対策）
            [[ -z "$t_line" ]] && continue
            # Unit Separator(0x1F)区切りでsubject部とtrailer部を分離
            t_subject_part="${t_line%%$'\x1F'*}"
            t_trailer_part="${t_line#*$'\x1F'}"
            # trailer部の前後空白を除去
            t_trailer_part=$(echo "$t_trailer_part" | tr -d '[:space:]')

            local t_short t_rest t_full t_subject
            t_short="${t_subject_part%% *}"
            t_rest="${t_subject_part#* }"
            t_full="${t_rest%% *}"
            t_subject="${t_rest#* }"

            if [[ -n "$t_trailer_part" ]]; then
                has_any_trailer=true
            fi

            if [[ "$t_in_unit" == "false" ]]; then
                # 開始境界: 前Unitのトレーラーを検出
                if [[ "$unit" == "001" ]]; then
                    # Unit 001: Inception完了（トレーラーなし）→ subjectパターンで検出
                    local inception_pattern="feat: [${cycle}] Inception Phase完了"
                    if [[ "$t_subject" == "${inception_pattern}"* ]]; then
                        t_found_start=true
                        continue
                    fi
                else
                    # Unit 002+: 前Unitの最後のトレーラー付きコミットを検出
                    if [[ "$t_trailer_part" == "${prev_unit}" ]]; then
                        trailer_start_boundary="$t_short"
                        t_found_start=true
                        continue
                    fi
                fi
                if [[ "$t_found_start" == "true" ]]; then
                    t_in_unit=true
                    t_first_short="$t_short"
                    t_first_full="$t_full"
                    t_last_short="$t_short"
                    t_last_full="$t_full"
                    t_hashes="$t_short"
                    # 終端チェック: feat: パターン優先
                    if [[ "$t_subject" == "${target_unit_pattern_for_trailer}"* ]]; then
                        trailer_end_boundary="$t_short"
                        trailer_end_subject="$t_subject"
                        break
                    fi
                    if [[ "$t_trailer_part" == "${unit}" ]]; then
                        trailer_end_boundary="$t_short"
                        trailer_end_subject="$t_subject"
                    fi
                fi
            else
                # Unit内: 次Unitのトレーラーに到達したら終了
                local next_unit_num next_unit
                next_unit_num=$((10#$unit + 1))
                next_unit=$(printf "%03d" "$next_unit_num")
                if [[ "$t_trailer_part" == "${next_unit}" ]]; then
                    break
                fi
                t_last_short="$t_short"
                t_last_full="$t_full"
                t_hashes="${t_hashes}"$'\n'"${t_short}"
                # 終端チェック: feat: パターン優先、なければ最後のトレーラー付きコミット
                if [[ "$t_subject" == "${target_unit_pattern_for_trailer}"* ]]; then
                    trailer_end_boundary="$t_short"
                    trailer_end_subject="$t_subject"
                    break
                fi
                if [[ "$t_trailer_part" == "${unit}" ]]; then
                    trailer_end_boundary="$t_short"
                    trailer_end_subject="$t_subject"
                fi
            fi
        done <<< "$trailer_log"

        # トレーラー戦略の結果判定
        if [[ -n "$t_first_short" && -n "$trailer_end_boundary" ]]; then
            # トレーラーで両境界が確定
            UNIT_FIRST_COMMIT="$t_first_short"
            UNIT_FIRST_COMMIT_FULL="$t_first_full"
            UNIT_LAST_COMMIT="$t_last_short"
            UNIT_LAST_COMMIT_FULL="$t_last_full"
            UNIT_COMMIT_HASHES="$t_hashes"
            return
        fi

        if [[ "$has_any_trailer" == "true" ]]; then
            echo "Warning: partial Unit-Number trailers found, falling back to pattern matching" >&2
        fi
    fi

    # === 戦略3: パターンマッチ（既存ロジック、フォールバック） ===
    echo "Warning: Unit-Number trailer not found, using commit message pattern matching" >&2

    local log_output
    if ! log_output=$(git log --reverse --format="%h %H %s" "$log_range" 2>&1); then
        echo "Error: git log failed: ${log_output}" >&2
        echo "squash:error:git-log-failed"
        exit 1
    fi

    if [[ -z "$log_output" ]]; then
        echo "Error: no commits found in range ${log_range}" >&2
        echo "squash:error:unit-not-found"
        exit 1
    fi

    # Unit番号から前Unitを計算
    local prev_unit_num
    prev_unit_num=$((10#$unit - 1))
    local prev_unit
    prev_unit=$(printf "%03d" "$prev_unit_num")

    # 境界アンカーパターン
    local inception_pattern="feat: [${cycle}] Inception Phase完了"
    local prev_unit_pattern="feat: [${cycle}] Unit ${prev_unit}完了"
    local target_unit_pattern="feat: [${cycle}] Unit ${unit}完了"

    # 次Unitの完了パターン（対象Unitの完了コミットがない場合の終端検出用）
    local next_unit_num
    next_unit_num=$((10#$unit + 1))
    local next_unit
    next_unit=$(printf "%03d" "$next_unit_num")
    local next_unit_pattern="feat: [${cycle}] Unit ${next_unit}完了"

    # 状態変数
    local in_unit=false
    local found_start=false
    local first_short="" first_full=""
    local last_short="" last_full=""
    local hashes=""
    local line short_hash full_hash subject

    while IFS= read -r line; do
        short_hash="${line%% *}"
        local rest="${line#* }"
        full_hash="${rest%% *}"
        subject="${rest#* }"

        if [[ "$in_unit" == "false" ]]; then
            # 開始境界の検出
            if [[ "$unit" == "001" ]]; then
                # Unit 001: Inception完了の次から開始
                if [[ "$subject" == "${inception_pattern}"* ]]; then
                    found_start=true
                    continue
                fi
                if [[ "$found_start" == "true" ]]; then
                    in_unit=true
                    first_short="$short_hash"
                    first_full="$full_hash"
                    last_short="$short_hash"
                    last_full="$full_hash"
                    hashes="$short_hash"
                    # 単一コミットUnit: 最初のコミットが完了コミットなら即終了
                    if [[ "$subject" == "${target_unit_pattern}"* ]]; then
                        break
                    fi
                fi
            else
                # Unit 002+: 前Unitの完了コミットの次から開始
                if [[ "$subject" == "${prev_unit_pattern}"* ]]; then
                    found_start=true
                    continue
                fi
                if [[ "$found_start" == "true" ]]; then
                    in_unit=true
                    first_short="$short_hash"
                    first_full="$full_hash"
                    last_short="$short_hash"
                    last_full="$full_hash"
                    hashes="$short_hash"
                    # 単一コミットUnit: 最初のコミットが完了コミットなら即終了
                    if [[ "$subject" == "${target_unit_pattern}"* ]]; then
                        break
                    fi
                fi
            fi
        else
            # Unit内: 終了境界の検出
            if [[ "$subject" == "${next_unit_pattern}"* ]]; then
                # 次Unitの完了コミットに到達 → 対象Unit終了
                break
            fi
            last_short="$short_hash"
            last_full="$full_hash"
            hashes="${hashes}"$'\n'"${short_hash}"

            if [[ "$subject" == "${target_unit_pattern}"* ]]; then
                # 対象Unitの完了コミットに到達 → 対象Unit終了
                break
            fi
        fi
    done <<< "$log_output"

    if [[ -z "$first_short" ]]; then
        echo "Error: commits for Unit ${unit} not found in cycle ${cycle}" >&2
        echo "Hint: Ensure commit messages follow the pattern 'feat: [${cycle}] Unit ${unit}完了 - ...'" >&2
        echo "Hint: Or add 'Unit-Number: ${unit}' trailer to commit messages" >&2
        echo "Hint: Or use --from/--to to specify the commit range explicitly" >&2
        echo "squash:error:unit-not-found"
        exit 1
    fi

    UNIT_FIRST_COMMIT="$first_short"
    UNIT_FIRST_COMMIT_FULL="$first_full"
    UNIT_LAST_COMMIT="$last_short"
    UNIT_LAST_COMMIT_FULL="$last_full"
    UNIT_COMMIT_HASHES="$hashes"
}

# --- Co-Authored-By抽出 ---

extract_co_authors() {
    local vcs_type="$1"
    local base="$2"
    local raw_authors=""

    if [[ "$vcs_type" == "git" ]]; then
        raw_authors=$(git log --format="%b" "${base}..HEAD" 2>/dev/null | grep -i "^Co-Authored-By:" || true)
    fi

    # 重複排除（raw行全体で比較）
    if [[ -n "$raw_authors" ]]; then
        CO_AUTHORS=$(echo "$raw_authors" | sort -u)
    else
        CO_AUTHORS=""
    fi
}

extract_co_authors_for_range() {
    local first_full="$1"
    local last_full="$2"
    local raw_authors=""
    local log_range

    log_range=$(safe_log_range "$first_full" "$last_full")
    raw_authors=$(git log --format="%b" $log_range 2>/dev/null | grep -i "^Co-Authored-By:" || true)

    if [[ -n "$raw_authors" ]]; then
        CO_AUTHORS=$(echo "$raw_authors" | sort -u)
    else
        CO_AUTHORS=""
    fi
}

# --- コミットメッセージ合成（複数 --message 段落結合 / Co-Authored-By 重複排除） ---

# normalize_coauthor_key: Co-Authored-By 行を dedup 比較キーへ正規化する純関数。
# 引数: $1 = 1 行
# 出力: stdout に正規化キー。Co-Authored-By 行でなければ空文字を出力。
# 正規化: ①行全体 trim ②トレーラ名 'Co-Authored-By:' を case-insensitive 化
#         ③コロン直後の連続空白を単一空白に畳む ④値部は前後 trim。
# 注: bash 3.2 互換のため小文字化は tr を使用（${var,,} は使わない）。
normalize_coauthor_key() {
    local line="$1"
    # 前後 trim
    line="${line#"${line%%[![:space:]]*}"}"
    line="${line%"${line##*[![:space:]]}"}"
    # Co-Authored-By: 行判定（case-insensitive）
    local lower
    lower=$(printf '%s' "$line" | tr '[:upper:]' '[:lower:]')
    if [[ "$lower" != co-authored-by:* ]]; then
        return 0
    fi
    # 値部（最初のコロン以降）を trim
    local value="${line#*:}"
    value="${value#"${value%%[![:space:]]*}"}"
    value="${value%"${value##*[![:space:]]}"}"
    printf 'co-authored-by: %s' "$value"
}

# compose_full_message: message 本文に co_authors を結合し Co-Authored-By 重複を排除する純関数。
# 通常経路（squash_git）と retroactive 経路（build_commit_message_file）の唯一の合成点。
# 引数: $1 = message（段落結合済みコミット本文）, $2 = co_authors（改行区切りの
#       Co-Authored-By 行群 / 空文字可）
# 出力: stdout に最終コミットメッセージ（末尾改行なし）。
# 契約: グローバル変数を読まない・書かない（純関数）。ファイル出力時の末尾改行付与は
#       呼び出し側責務。message 側既出 + co_authors 内部重複を dedup 比較キーで一意化し、
#       出力は採用行の原文を保持する。
compose_full_message() {
    local message="$1"
    local co_authors="$2"

    if [[ -z "$co_authors" ]]; then
        printf '%s' "$message"
        return 0
    fi

    # message 側に既出の Co-Authored-By 正規化キーを seen に収集（前後を改行で囲んで保持）
    local seen=$'\n'
    local line key
    while IFS= read -r line; do
        key=$(normalize_coauthor_key "$line")
        [[ -z "$key" ]] && continue
        seen="${seen}${key}"$'\n'
    done <<< "$message"

    # co_authors を走査し、未出のみ残余に採用（採用と同時に seen へ蓄積 → 内部重複も排除）
    local remainder=""
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        key=$(normalize_coauthor_key "$line")
        if [[ -n "$key" ]]; then
            if [[ "$seen" == *$'\n'"$key"$'\n'* ]]; then
                continue
            fi
            seen="${seen}${key}"$'\n'
        fi
        if [[ -z "$remainder" ]]; then
            remainder="$line"
        else
            remainder="${remainder}"$'\n'"${line}"
        fi
    done <<< "$co_authors"

    if [[ -z "$remainder" ]]; then
        printf '%s' "$message"
    else
        printf '%s\n\n%s' "$message" "$remainder"
    fi
}

# --- コミット数取得（pipefail安全） ---

get_target_count() {
    local vcs_type="$1"
    local base="$2"
    local count_output

    if [[ "$vcs_type" == "git" ]]; then
        if ! count_output=$(git rev-list --count "${base}..HEAD" 2>&1); then
            echo "Error: failed to count commits: ${count_output}" >&2
            echo "squash:error:count-failed"
            exit 1
        fi
    fi

    TARGET_COUNT="$count_output"
}

# --- squash実行 ---

squash_git() {
    local base="$1"
    local message="$2"
    local co_authors="$3"
    local target_count="$4"

    # 最終コミットメッセージの組み立て（唯一の合成点 compose_full_message へ委譲）
    local full_message
    full_message=$(compose_full_message "$message" "$co_authors")

    if [[ "$target_count" -eq 1 ]]; then
        # 1件: メッセージ整形のみ（amend）
        if ! git commit --amend -m "$full_message" >/dev/null 2>&1; then
            echo "Error: git commit --amend failed" >&2
            echo "squash:error:amend-failed"
            exit 1
        fi
        local new_hash
        new_hash=$(git rev-parse HEAD 2>/dev/null)
        echo "squash:success:${new_hash}"
        return
    fi

    # 2件以上: reset --soft + commit
    SAVED_HEAD=$(git rev-parse HEAD 2>/dev/null)

    if ! git reset --soft "$base" 2>/dev/null; then
        echo "Error: git reset --soft ${base} failed" >&2
        echo "squash:error:reset-failed"
        exit 1
    fi

    if ! git commit -m "$full_message" >/dev/null 2>&1; then
        echo "Error: git commit failed after reset --soft. Working tree is in intermediate state." >&2
        echo "squash:error:commit-failed"
        echo "recovery:git reset --soft ${SAVED_HEAD}"
        exit 1
    fi

    local new_hash
    new_hash=$(git rev-parse HEAD 2>/dev/null)
    echo "squash:success:${new_hash}"
}

# --- retroactive squash用関数群 ---

cleanup_tmpfiles() {
    local f
    for f in "${TMPFILES[@]}"; do
        [[ -f "$f" ]] && \rm -f "$f"
    done
}

build_sequence_editor_script() {
    local first_commit="$1"
    local commit_hashes="$2"
    local script_file
    script_file=$(mktemp)
    TMPFILES+=("$script_file")

    # コミットハッシュをパイプ区切りの正規表現パターンに変換
    local hashes_for_script
    hashes_for_script=$(echo "$commit_hashes" | tr '\n' '|' | sed 's/|$//')

    cat > "$script_file" << SCRIPT_EOF
#!/usr/bin/env bash
set -euo pipefail
TODO_FILE="\$1"
FIRST_COMMIT="${first_commit}"
TMP_FILE=\$(mktemp)
while IFS= read -r line; do
    if [[ "\$line" == "#"* ]] || [[ "\$line" == "break"* ]] || [[ -z "\$line" ]]; then
        echo "\$line" >> "\$TMP_FILE"
        continue
    fi
    hash=\$(echo "\$line" | awk '{print \$2}')
    rest=\$(echo "\$line" | cut -d' ' -f3-)
    if [[ "\$hash" == "\$FIRST_COMMIT" ]]; then
        echo "reword \${hash} \${rest}" >> "\$TMP_FILE"
    elif echo "\$hash" | grep -qE "^(${hashes_for_script})\$"; then
        echo "fixup \${hash} \${rest}" >> "\$TMP_FILE"
    else
        echo "\$line" >> "\$TMP_FILE"
    fi
done < "\$TODO_FILE"
\\mv "\$TMP_FILE" "\$TODO_FILE"
SCRIPT_EOF

    chmod +x "$script_file"
    echo "$script_file"
}

build_commit_message_file() {
    local message="$1"
    local co_authors="$2"
    local msg_file
    msg_file=$(mktemp)
    TMPFILES+=("$msg_file")

    # 唯一の合成点 compose_full_message へ委譲（通常経路と挙動を統一）。
    # ファイル出力のため末尾改行は本関数側で付与する。
    local composed
    composed=$(compose_full_message "$message" "$co_authors")
    printf '%s\n' "$composed" > "$msg_file"

    echo "$msg_file"
}

build_editor_script() {
    local msg_file="$1"
    local editor_script
    editor_script=$(mktemp)
    TMPFILES+=("$editor_script")

    cat > "$editor_script" << EDITOR_EOF
#!/usr/bin/env bash
cat -- "${msg_file}" > "\$1"
EDITOR_EOF

    chmod +x "$editor_script"
    echo "$editor_script"
}

capture_tree_hash() {
    TREE_HASH_BEFORE=$(git rev-parse HEAD^{tree} 2>/dev/null)
}

verify_tree_hash() {
    local tree_hash_after
    tree_hash_after=$(git rev-parse HEAD^{tree} 2>/dev/null)
    if [[ "$TREE_HASH_BEFORE" != "$tree_hash_after" ]]; then
        echo "Warning: tree hash mismatch after retroactive squash. Before: ${TREE_HASH_BEFORE}, After: ${tree_hash_after}" >&2
    fi
}

squash_retroactive_git() {
    # 1. Unit コミット範囲特定
    find_unit_commit_range_git "$CYCLE" "$UNIT"

    local commit_count
    commit_count=$(echo "$UNIT_COMMIT_HASHES" | wc -l | tr -d ' ')
    echo "unit_range:${UNIT_FIRST_COMMIT}..${UNIT_LAST_COMMIT}"
    echo "unit_commit_count:${commit_count}"

    # 対象0件チェック
    if [[ -z "$UNIT_COMMIT_HASHES" ]]; then
        echo "squash:skipped:no-commits"
        return
    fi

    # ドライラン
    if [[ "$DRY_RUN" == "true" ]]; then
        local dry_run_range
        dry_run_range=$(safe_log_range "$UNIT_FIRST_COMMIT_FULL" "$UNIT_LAST_COMMIT_FULL")
        git log --oneline $dry_run_range >&2
        echo "squash:dry-run:${commit_count}"
        return
    fi

    # 1件の場合: rewordのみ（rebaseで処理）
    # 2件以上の場合: reword + fixup

    # 2. ツリーハッシュ記録
    capture_tree_hash

    # 3. Co-Authored-By抽出（対象Unit範囲のみ）
    extract_co_authors_for_range "$UNIT_FIRST_COMMIT_FULL" "$UNIT_LAST_COMMIT_FULL"

    # 4. rebaseスクリプト生成
    local seq_editor_script
    seq_editor_script=$(build_sequence_editor_script "$UNIT_FIRST_COMMIT" "$UNIT_COMMIT_HASHES")

    # 5. コミットメッセージファイル生成
    local msg_file
    msg_file=$(build_commit_message_file "$MESSAGE" "$CO_AUTHORS")

    # 6. GIT_EDITOR用ラッパースクリプト生成
    local editor_script
    editor_script=$(build_editor_script "$msg_file")

    # 7. rebase起点（対象Unitの最初のコミットの親、ルートコミット時は--root）
    local rebase_base
    rebase_base=$(rebase_base_args "$UNIT_FIRST_COMMIT_FULL")

    # 8. git rebase -i 実行
    local rebase_result=0
    GIT_SEQUENCE_EDITOR="bash \"${seq_editor_script}\"" \
    GIT_EDITOR="bash \"${editor_script}\"" \
    git rebase -i $rebase_base 2>/dev/null || rebase_result=$?

    if [[ "$rebase_result" -ne 0 ]]; then
        # rebase進行中（conflict）か否かを判定
        if [[ -d "$(git rev-parse --git-dir)/rebase-merge" ]] || [[ -d "$(git rev-parse --git-dir)/rebase-apply" ]]; then
            echo "Error: rebase failed due to conflict. Aborting rebase." >&2
            git rebase --abort 2>/dev/null || true
            cleanup_tmpfiles
            echo "squash:error:conflict"
            exit 1
        else
            echo "Error: rebase failed (editor script or other error)." >&2
            cleanup_tmpfiles
            echo "squash:error:rebase-failed"
            exit 1
        fi
    fi

    # 8. 一時ファイルクリーンアップ
    cleanup_tmpfiles

    # 9. ツリーハッシュ検証
    verify_tree_hash

    # 10. 結果出力
    local new_hash
    new_hash=$(git rev-parse HEAD 2>/dev/null)
    echo "squash:success:${new_hash}"
}

# --- 内部 CI 構造チェック（設定駆動 + opt-in シグナル方式）---
# `.aidlc/config.toml` の [rules.squash.internal_ci_checks].scripts 設定キーから
# `read-config.sh` 経由で実行対象スクリプトのリストを動的に解決する。
# 本体スクリプトに starter kit 固有のチェックスクリプト名・配置の知識を持たない。
# CLAUDE.md「設計原則」§ ドッグフーディング特殊処理を本体に埋めない 準拠。
# 詳細: v2.6.1 Unit 005 / Issue #687

# parse_config_array: read-config.sh の Python 風 list literal 出力 (`['a', 'b']`) を
# 改行区切りの行配列にデコードする局所ヘルパ（純粋関数）。
# 引数: $1 = read-config.sh の生 stdout
# 出力: 改行区切り行配列（stdout）
# 終了コード: 0 = 正常 / 1 = 想定外フォーマット入力
# 将来 read-config.sh 側に --format=lines 等が追加されたら本ヘルパは削除可能
parse_config_array() {
    local raw="$1"
    # 前後空白の trim
    raw="${raw#"${raw%%[![:space:]]*}"}"
    raw="${raw%"${raw##*[![:space:]]}"}"
    # 空文字: 防御的に 0 行で正常終了
    if [[ -z "$raw" ]]; then
        return 0
    fi
    # 制御文字（NUL を除く 0x01-0x08, 0x0B-0x0C, 0x0E-0x1F）混入を拒否
    # （\t/\n/\r は許容）。LC_ALL=C で 1-byte ロケールに固定して LANG 干渉を避ける
    if LC_ALL=C printf '%s' "$raw" | LC_ALL=C grep -qE $'[\x01-\x08\x0b\x0c\x0e-\x1f]'; then
        return 1
    fi
    # フォーマット検証: [ で始まり ] で終わること
    if [[ "${raw:0:1}" != "[" || "${raw: -1}" != "]" ]]; then
        return 1
    fi
    # 空配列
    if [[ "$raw" == "[]" ]]; then
        return 0
    fi
    # 厳密フォーマット検証（コードレビュー Round 1 指摘 #1 反映）:
    # `read-config.sh` の正規出力は `[<quoted_elem>(, <quoted_elem>)*]` の形式。
    # quoted_elem は `'<chars>'` または `"<chars>"`（クオート種類は要素ごとに混在可、
    # 内部にクオート文字含まず）。区切りはカンマ + 任意空白。
    # クオート欠落・区切り不正はフォーマットエラー（exit 1）として扱う。
    local body="${raw#[}"
    body="${body%]}"
    # 前後空白の trim
    body="${body#"${body%%[![:space:]]*}"}"
    body="${body%"${body##*[![:space:]]}"}"
    # 要素列の正規表現検証: 各要素は ' or " で囲まれ、カンマ + 任意空白で区切られる
    local elem_re="('[^']*'|\"[^\"]*\")"
    local list_re="^${elem_re}([[:space:]]*,[[:space:]]*${elem_re})*$"
    if [[ ! "$body" =~ $list_re ]]; then
        return 1
    fi
    # 各要素を取り出して出力
    # 注: `for elem in $body` での glob 展開を避けるため `read -ra` を使用
    local arr=()
    IFS=',' read -ra arr <<< "$body"
    local elem
    for elem in "${arr[@]}"; do
        # 前後空白 trim
        elem="${elem#"${elem%%[![:space:]]*}"}"
        elem="${elem%"${elem##*[![:space:]]}"}"
        # 外側のクオート 1 文字を剥がす
        if [[ "${elem:0:1}" == "'" || "${elem:0:1}" == '"' ]]; then
            elem="${elem:1:${#elem}-2}"
        fi
        if [[ -n "$elem" ]]; then
            printf '%s\n' "$elem"
        fi
    done
    return 0
}

# is_invalid_check_path: パス正規化バリデーション（4 条件 OR）
# 引数: $1 = 設定リスト由来のパス文字列
# 戻り値: 0 = 不正（reject）、1 = 妥当（accept）
# 設計レビュー Round 1 指摘 #3 反映: 許容文字セット OR + 独立条件 4 個
is_invalid_check_path() {
    local entry="$1"
    # (1) 空エントリ reject
    [[ -z "$entry" ]] && return 0
    # (2) 絶対パス reject
    [[ "$entry" == /* ]] && return 0
    # (3) traversal reject（'..' を含む）
    [[ "$entry" == *".."* ]] && return 0
    # (4) 許容文字セット外 reject
    [[ ! "$entry" =~ ^[A-Za-z0-9_./-]+$ ]] && return 0
    return 1
}

# emit_aggregate_skip: 集約 skip の 2 行契約出力（既存トークン互換 + reason 別行）
# 引数: $1 = reason 値
emit_aggregate_skip() {
    local reason="$1"
    echo "squash:info:internal-ci-checks-skipped"
    echo "squash:info:internal-ci-checks-skipped:reason=${reason}"
}

run_internal_ci_checks_or_skip() {
    local repo_root="$1"
    local script_dir
    script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

    # 設定読取（公開 API スクリプト層 / Unit 004 で確立）
    local raw_value
    local read_exit=0
    raw_value=$(bash "${script_dir}/read-config.sh" rules.squash.internal_ci_checks.scripts 2>/dev/null) || read_exit=$?

    case "$read_exit" in
        0)
            ;;
        1)
            # キー不在（consumer プロジェクト想定）
            echo "info: [rules.squash.internal_ci_checks].scripts not configured (skipping)" >&2
            emit_aggregate_skip "no-config"
            return 0
            ;;
        *)
            # 実行系エラー（dasel 未インストール / TOML 破損等）
            echo "Warning: failed to read [rules.squash.internal_ci_checks].scripts (exit=${read_exit}); skipping internal CI checks" >&2
            emit_aggregate_skip "config-read-error"
            return 0
            ;;
    esac

    # 配列パース
    local entries_raw
    local parse_exit=0
    entries_raw=$(parse_config_array "$raw_value") || parse_exit=$?

    if [[ "$parse_exit" -ne 0 ]]; then
        echo "Warning: [rules.squash.internal_ci_checks].scripts has invalid format; skipping internal CI checks" >&2
        emit_aggregate_skip "invalid-config-format"
        return 0
    fi

    # 空配列チェック
    if [[ -z "$entries_raw" ]]; then
        echo "info: [rules.squash.internal_ci_checks].scripts is empty (skipping)" >&2
        emit_aggregate_skip "empty-config"
        return 0
    fi

    # エントリ評価ループ
    local entry
    local executed_count=0
    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        # パス正規化チェック
        if is_invalid_check_path "$entry"; then
            echo "Warning: invalid script path in [rules.squash.internal_ci_checks].scripts: ${entry}" >&2
            echo "squash:warn:internal-ci-check-skipped:reason=invalid-path:script=${entry}"
            continue
        fi
        # 実体存在チェック（opt-in シグナル）
        if [[ ! -f "${repo_root}/${entry}" ]]; then
            echo "squash:info:internal-ci-check-skipped:reason=script-not-found:script=${entry}"
            continue
        fi
        # 実行
        local basename_no_ext
        basename_no_ext=$(basename "$entry" .sh)
        executed_count=$((executed_count + 1))
        if ! bash "${repo_root}/${entry}" >&2; then
            echo "squash:error:${basename_no_ext}-failed"
            return 2
        fi
    done <<< "$entries_raw"

    if [[ "$executed_count" -eq 0 ]]; then
        echo "info: no executable internal CI check scripts present (all entries skipped)" >&2
        emit_aggregate_skip "no-script-present"
    fi
    return 0
}

# --- メイン処理 ---

main() {
    parse_args "$@"

    # retroactive バリデーション
    if [[ "$RETROACTIVE" == "true" ]]; then
        validate_retroactive_args
    fi

    # --from/--to は retroactive モードでのみ使用可能
    if [[ "$RETROACTIVE" != "true" ]] && [[ -n "$FROM_COMMIT" || -n "$TO_COMMIT" ]]; then
        echo "Error: --from/--to can only be used with --retroactive" >&2
        exit 1
    fi

    echo "vcs_type:${VCS_TYPE}"
    if [[ "$RETROACTIVE" == "true" ]]; then
        echo "retroactive:true"
    fi

    # 事前チェック: working tree がcleanであること
    local porcelain
    if ! porcelain=$(git status --porcelain 2>&1); then
        echo "Error: git status failed (not a git repository?): ${porcelain}" >&2
        echo "squash:error:not-a-repository"
        exit 1
    fi
    if [[ -n "$porcelain" ]]; then
        echo "Error: working tree is not clean. Please commit or stash changes first." >&2
        echo "squash:error:dirty-working-tree"
        exit 1
    fi

    # mainブランチ保護: サイクルブランチ以外での実行を拒否
    local current_branch
    current_branch=$(git symbolic-ref --short HEAD 2>/dev/null || true)
    if [[ "$current_branch" == "main" || "$current_branch" == "master" ]]; then
        echo "Error: squash-unit.sh should not be run on the main/master branch. Use a cycle branch." >&2
        echo "squash:error:on-main-branch"
        exit 1
    fi

    # 内部 CI 構造チェック（Unit 完了時必須実行 / cwd 非依存 / violation で squash 中止）
    # 検査対象は `.aidlc/config.toml` の [rules.squash.internal_ci_checks].scripts で動的解決
    # script dir 起点で repo root を解決し絶対パスで実行
    local repo_root_for_checks
    repo_root_for_checks=$(git rev-parse --show-toplevel 2>/dev/null) || {
        echo "Error: not in a git repository" >&2
        echo "squash:error:not-a-repository"
        exit 1
    }
    # 内部 CI 構造チェック（設定駆動 + opt-in シグナル方式）
    # 詳細は run_internal_ci_checks_or_skip() のヘッダコメント参照。
    if ! run_internal_ci_checks_or_skip "${repo_root_for_checks}"; then
        exit 1
    fi

    # retroactive モード: 専用フローへ分岐
    if [[ "$RETROACTIVE" == "true" ]]; then
        # --from/--to バリデーション（排他チェック、フルハッシュ正規化、祖先検証）
        validate_from_to_args
        if [[ -n "$FROM_COMMIT" ]]; then
            echo "from_commit:${FROM_COMMIT:0:7}"
            echo "to_commit:${TO_COMMIT:0:7}"
        fi
        # --base 指定時のバリデーション（--from/--to 未指定時のみ）
        if [[ -n "$BASE_COMMIT" ]]; then
            validate_base_format "$BASE_COMMIT" "$VCS_TYPE"
            if ! git merge-base --is-ancestor "$BASE_COMMIT" HEAD 2>/dev/null; then
                echo "Error: --base ${BASE_COMMIT} is not an ancestor of HEAD" >&2
                echo "squash:error:base-not-ancestor"
                exit 1
            fi
            echo "base_commit:${BASE_COMMIT}"
        fi
        squash_retroactive_git
        exit 0
    fi

    # --- 以下、通常（非retroactive）フロー ---

    # 起点コミット特定（--base 指定時はバリデーション＋祖先チェック）
    if [[ -n "$BASE_COMMIT" ]]; then
        # 入力バリデーション（revset演算子の混入防止）
        validate_base_format "$BASE_COMMIT" "$VCS_TYPE"

        if ! git merge-base --is-ancestor "$BASE_COMMIT" HEAD 2>/dev/null; then
            echo "Error: --base ${BASE_COMMIT} is not an ancestor of HEAD" >&2
            echo "squash:error:base-not-ancestor"
            exit 1
        fi
        echo "base_commit:${BASE_COMMIT}"
    else
        find_base_commit_git "$CYCLE"
    fi

    # 対象コミット数の取得（pipefail安全）
    get_target_count "$VCS_TYPE" "$BASE_COMMIT"
    echo "target_count:${TARGET_COUNT}"

    # 対象0件: スキップ
    if [[ "$TARGET_COUNT" -eq 0 ]]; then
        echo "squash:skipped:no-commits"
        exit 0
    fi

    # ドライラン: 対象一覧を表示して終了
    if [[ "$DRY_RUN" == "true" ]]; then
        git log --oneline "${BASE_COMMIT}..HEAD" >&2
        echo "squash:dry-run:${TARGET_COUNT}"
        exit 0
    fi

    # Co-Authored-By抽出（squash前に実行）
    extract_co_authors "$VCS_TYPE" "$BASE_COMMIT"

    # squash実行
    squash_git "$BASE_COMMIT" "$MESSAGE" "$CO_AUTHORS" "$TARGET_COUNT"
}

# bats テストから `source` で関数定義のみ拾えるようにガード
# 直接実行時（`bash squash-unit.sh ...`）はガード true で main を起動
# `source` 時はガード false で main を起動しない
# 注: `set -e` 下では `[[ ]] && cmd` 形式は `[[ ]]` が false で全体が
# 失敗扱いになるため、`if`/`fi` で明示的に条件分岐させる
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
