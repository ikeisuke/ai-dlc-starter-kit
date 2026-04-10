#!/usr/bin/env bash
# 初回ロード tok 数計測スクリプト
# v2.2.3 ベースラインと v2.3.0 現状の Inception / Construction / Operations
# 各フェーズ初回ロード tok 数を tiktoken (cl100k_base) で決定論的に計測する。
#
# 計測対象ファイルリストの正本は本スクリプト内の bash 配列。
# 計画書 (.aidlc/cycles/v2.3.0/plans/unit-006-plan.md) および
# レポート (.aidlc/cycles/v2.3.0/measurement-report.md) は参考表示のみ。
#
# Usage: bin/measure-initial-load.sh [--help]

set -euo pipefail
export LANG=C LC_ALL=C

# ===== 定数 =====

# v2.2.3 を指す commit hash（タグ差し替え・lightweight tag 揺れを防ぐため固定）
# v2.2.3 タグはマージコミット 56c64637... を指す。マージ元の最終コミット d88b0074 と
# skills/aidlc/ 配下のツリー内容は完全一致するが、ここでは git rev-parse v2.2.3^{commit}
# が返す値（実際のタグコミット）を BASELINE_REF とする。
readonly BASELINE_REF="56c6463747b41ab74108055a933cdfe29781fb43"

# tiktoken を持つ Python インタプリタ
readonly PYTHON_BIN="/tmp/anthropic-venv/bin/python3"

# 計測対象ファイルリスト（正本）— skills/aidlc/ ルート相対パス
readonly -a COMMON_FILES=(
    "SKILL.md"
    "steps/common/rules-core.md"
    "steps/common/preflight.md"
    "steps/common/session-continuity.md"
)

readonly -a INCEPTION_BASELINE_FILES=(
    "steps/inception/01-setup.md"
    "steps/inception/02-preparation.md"
    "steps/inception/03-intent.md"
    "steps/inception/04-stories-units.md"
    "steps/inception/05-completion.md"
)

readonly -a CONSTRUCTION_BASELINE_FILES=(
    "steps/construction/01-setup.md"
    "steps/construction/02-design.md"
    "steps/construction/03-implementation.md"
    "steps/construction/04-completion.md"
)

readonly -a OPERATIONS_BASELINE_FILES=(
    "steps/operations/01-setup.md"
    "steps/operations/02-deploy.md"
    "steps/operations/03-release.md"
    "steps/operations/04-completion.md"
)

readonly -a INCEPTION_CURRENT_FILES=(
    "steps/inception/index.md"
)

readonly -a CONSTRUCTION_CURRENT_FILES=(
    "steps/construction/index.md"
)

readonly -a OPERATIONS_CURRENT_FILES=(
    "steps/operations/index.md"
)

# skills/aidlc ディレクトリへのリポジトリルート相対プレフィックス
readonly SKILL_PREFIX="skills/aidlc"

# ===== ヘルプ =====

show_help() {
    cat <<'EOF'
Usage: bin/measure-initial-load.sh [--help]

v2.2.3 ベースラインと v2.3.0 現状の Inception / Construction / Operations 各フェーズ
初回ロード tok 数を tiktoken (cl100k_base) で決定論的に計測する。

引数なしで全フェーズ・全バリアントを計測する。

計測対象ファイルリストはスクリプト内の bash 配列が正本。

Exit codes:
  0  正常終了
  1  BASELINE_REF と git rev-parse v2.2.3^{commit} 不一致
  2  tiktoken が import できない
  3  git show 失敗（v2.2.3 ファイル取得不能）
  4  mktemp -d または mkdir -p 失敗
  5  tiktoken による計測実行失敗
EOF
}

# ===== ユーティリティ =====

err() {
    echo "ERROR: $*" >&2
}

# ===== BASELINE_REF 検証 =====

verify_baseline_ref() {
    local actual_hash
    if ! actual_hash="$(git rev-parse "v2.2.3^{commit}" 2>/dev/null)"; then
        err "git rev-parse v2.2.3^{commit} に失敗しました（タグ v2.2.3 が存在しない可能性があります）"
        exit 1
    fi
    if [[ "$actual_hash" != "$BASELINE_REF" ]]; then
        err "BASELINE_REF と v2.2.3 タグが不一致です"
        err "  expected (BASELINE_REF): $BASELINE_REF"
        err "  actual   (v2.2.3 tag): $actual_hash"
        exit 1
    fi
}

# ===== tiktoken 検証 =====

verify_tiktoken() {
    if [[ ! -x "$PYTHON_BIN" ]]; then
        err "Python インタプリタが見つかりません: $PYTHON_BIN"
        exit 2
    fi
    if ! "$PYTHON_BIN" -c "import tiktoken" >/dev/null 2>&1; then
        err "tiktoken が import できません ($PYTHON_BIN)"
        exit 2
    fi
}

# ===== v2.2.3 ベースラインファイル展開 =====
# 引数: $1 = 展開先ディレクトリ
expand_baseline_files() {
    local dest="$1"
    local rel_path
    local all_files=(
        "${COMMON_FILES[@]}"
        "${INCEPTION_BASELINE_FILES[@]}"
        "${CONSTRUCTION_BASELINE_FILES[@]}"
        "${OPERATIONS_BASELINE_FILES[@]}"
    )
    for rel_path in "${all_files[@]}"; do
        local src_path="${SKILL_PREFIX}/${rel_path}"
        local dst_path="${dest}/${rel_path}"
        if ! mkdir -p "$(dirname "$dst_path")" 2>/dev/null; then
            err "mkdir -p $(dirname "$dst_path") に失敗しました"
            exit 4
        fi
        if ! git show "${BASELINE_REF}:${src_path}" > "$dst_path" 2>/dev/null; then
            err "git show ${BASELINE_REF}:${src_path} に失敗しました"
            exit 3
        fi
    done
}

# ===== tiktoken 計測 =====
# 引数: $@ = 計測対象ファイルパスのペア（"display_path::real_path" 形式の文字列を複数）
# 標準出力に <N> tok  <display_path> 形式 + TOTAL 行を出す。
# 決定論性のため、表示パスは display_path（固定文字列）を使う。
# 失敗時は exit 5（tiktoken 計測失敗）に正規化する。
measure_files() {
    if ! "$PYTHON_BIN" -c '
import sys
import tiktoken

enc = tiktoken.get_encoding("cl100k_base")
total = 0
for spec in sys.argv[1:]:
    display_path, _, real_path = spec.partition("::")
    with open(real_path, "r", encoding="utf-8") as f:
        text = f.read()
    n = len(enc.encode(text))
    total += n
    sys.stdout.write(f"{n:>6} tok  {display_path}\n")
sys.stdout.write(f"{total:>6} tok  TOTAL\n")
' "$@"; then
        err "tiktoken 計測に失敗しました"
        exit 5
    fi
}

# ===== 1 フェーズ計測 =====
# 引数: $1 = ヘッダ文字列, $2... = "display_path::real_path" ペア
measure_phase() {
    local header="$1"
    shift
    echo "=== ${header} ==="
    measure_files "$@"
    echo
}

# ===== メイン処理 =====

main() {
    if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        show_help
        exit 0
    fi

    verify_baseline_ref
    verify_tiktoken

    if ! TMPDIR_MEASURE="$(mktemp -d)"; then
        err "mktemp -d に失敗しました"
        exit 4
    fi
    trap 'rm -rf "${TMPDIR_MEASURE:-}"' EXIT
    local tmpdir="$TMPDIR_MEASURE"

    expand_baseline_files "$tmpdir"

    # ----- v2.2.3 BASELINE -----
    # display_path = リポジトリ相対の skills/aidlc/<rel>、real_path = $tmpdir/<rel>
    local -a inception_baseline=()
    local rel_path
    for rel_path in "${COMMON_FILES[@]}" "${INCEPTION_BASELINE_FILES[@]}"; do
        inception_baseline+=("${SKILL_PREFIX}/${rel_path}::${tmpdir}/${rel_path}")
    done
    measure_phase "v2.2.3 BASELINE: Inception" "${inception_baseline[@]}"

    local -a construction_baseline=()
    for rel_path in "${COMMON_FILES[@]}" "${CONSTRUCTION_BASELINE_FILES[@]}"; do
        construction_baseline+=("${SKILL_PREFIX}/${rel_path}::${tmpdir}/${rel_path}")
    done
    measure_phase "v2.2.3 BASELINE: Construction" "${construction_baseline[@]}"

    local -a operations_baseline=()
    for rel_path in "${COMMON_FILES[@]}" "${OPERATIONS_BASELINE_FILES[@]}"; do
        operations_baseline+=("${SKILL_PREFIX}/${rel_path}::${tmpdir}/${rel_path}")
    done
    measure_phase "v2.2.3 BASELINE: Operations" "${operations_baseline[@]}"

    # ----- v2.3.0 CURRENT -----
    # display_path = real_path（ワーキングツリーのリポジトリ相対パス）
    local -a inception_current=()
    for rel_path in "${COMMON_FILES[@]}" "${INCEPTION_CURRENT_FILES[@]}"; do
        inception_current+=("${SKILL_PREFIX}/${rel_path}::${SKILL_PREFIX}/${rel_path}")
    done
    measure_phase "v2.3.0 CURRENT: Inception" "${inception_current[@]}"

    local -a construction_current=()
    for rel_path in "${COMMON_FILES[@]}" "${CONSTRUCTION_CURRENT_FILES[@]}"; do
        construction_current+=("${SKILL_PREFIX}/${rel_path}::${SKILL_PREFIX}/${rel_path}")
    done
    measure_phase "v2.3.0 CURRENT: Construction" "${construction_current[@]}"

    local -a operations_current=()
    for rel_path in "${COMMON_FILES[@]}" "${OPERATIONS_CURRENT_FILES[@]}"; do
        operations_current+=("${SKILL_PREFIX}/${rel_path}::${SKILL_PREFIX}/${rel_path}")
    done
    measure_phase "v2.3.0 CURRENT: Operations" "${operations_current[@]}"
}

main "$@"
