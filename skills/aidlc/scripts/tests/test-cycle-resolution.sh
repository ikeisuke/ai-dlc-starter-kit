#!/usr/bin/env bash
#
# test-cycle-resolution.sh - v3 cycle 解決の明示指定優先 / gitlog 非依存の回帰テスト
#
# v3 の cycle 解決入口は state-read.sh の current_cycle 読取（.aidlc/state.json）であり、
# git 履歴・周辺ファイル名・ディレクトリ走査順に影響されない（明示指定一本化 / RFC DG-6）。
# 本テストはその仕様を回帰テストとして固定し、#733 P4 クラス（古い cycle 値を返す退行）の
# v3 における再発を防止する（Unit 003 / T6）。
#
# production code は変更しない。既存仕様が既に明示指定一本化のため、本テストは
# 「現仕様が壊れていないこと」を恒久的に固定する。将来 gitlog 推定が混入したら赤になる。
#
# 外部テストフレームワークに依存しない自己完結型ハーネス（jq / git / mktemp 前提）。
#
# Usage: test-cycle-resolution.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（jq / git 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
readonly SCRIPT_DIR SCRIPTS_DIR
readonly READ="$SCRIPTS_DIR/state-read.sh"
readonly VALIDATE="$SCRIPTS_DIR/state-validate.sh"

if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not found (前提不備)" >&2
    exit 2
fi
if ! command -v git >/dev/null 2>&1; then
    echo "SKIP: git not found (前提不備)" >&2
    exit 2
fi

PASS=0
FAIL=0
TMPDIR_TEST="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_TEST"' EXIT

# current_cycle を指定した有効な state.json を生成する
write_state_with_cycle() {
    local path="$1"
    local cycle="$2"
    cat > "$path" <<JSON
{
  "schema_version": "3.0",
  "current_cycle": "$cycle",
  "define_completed": false,
  "release": {
    "pr_number": null,
    "ready": false,
    "merge_approved": false
  },
  "updated_at": "2026-06-04T00:00:00Z"
}
JSON
}

# current_cycle="v3.0.0" の有効な state.json を生成する
make_valid_state() {
    write_state_with_cycle "$1" "v3.0.0"
}

# gitlog 誤誘導サンドボックスを構築する。
#   引数: <state に書く current_cycle 値>
#   出力: サンドボックスディレクトリのパス（stdout / state.json は <sandbox>/.aidlc/state.json）
#
# current_cycle と異なる cycle 名（v2.6.6 / v1.0.0）を git 履歴・周辺ファイル/ディレクトリに
# 仕込み、それでも解決結果が state.json の current_cycle 値に一致することを検証するための環境。
# git 操作は AGENTS.md 規約に従いサブシェル cd 内で実行し、git -C は使わない。
# user.email / user.name / commit.gpgsign=false を明示し環境非依存にする。
make_gitlog_decoy_sandbox() {
    local cycle="$1"
    local sb
    sb="$(mktemp -d "$TMPDIR_TEST/decoy.XXXXXX")" || return 2
    (
        cd "$sb" || exit 2
        git init -q || exit 2
        mkdir -p .aidlc/cycles/v2.6.6 .aidlc/cycles/v1.0.0
        printf 'decoy marker for v2.6.6\n' > .aidlc/cycles/v2.6.6/marker.md
        printf 'decoy marker for v1.0.0\n' > .aidlc/cycles/v1.0.0/marker.md
        git add -A
        git -c user.email=test@example.com -c user.name=test -c commit.gpgsign=false \
            commit -q -m "work on v2.6.6 cycle"
        printf 'release notes for v1.0.0\n' > .aidlc/cycles/v1.0.0/notes.md
        git add -A
        git -c user.email=test@example.com -c user.name=test -c commit.gpgsign=false \
            commit -q -m "release v1.0.0"
    ) || return 2
    write_state_with_cycle "$sb/.aidlc/state.json" "$cycle"
    printf '%s\n' "$sb"
}

# サンドボックスのカレントディレクトリで state-read.sh を実行し current_cycle を出力する。
#   引数: <サンドボックスディレクトリ>
# 被テストをサンドボックス cwd 内で動かすことで、将来 cwd 基準の git 推定（git log 等）が
# 混入した場合に誤誘導履歴を踏ませ、テストが空振りせず退行を検知できるようにする。
# git -C は使わずサブシェル cd で実行する（AGENTS.md 規約）。
# shellcheck disable=SC2329  # assert_out の "$@" 経由で間接的に呼び出される（直接呼び出しなし）
read_cycle_in_sandbox() {
    local sb="$1"
    ( cd "$sb" || exit 2; "$READ" current_cycle .aidlc/state.json )
}

# assert_rc <期待rc> <説明> -- <コマンド...>
assert_rc() {
    local expected="$1"; shift
    local desc="$1"; shift
    [[ "$1" == "--" ]] && shift
    "$@" >/dev/null 2>&1
    local rc=$?
    if [[ "$rc" == "$expected" ]]; then
        PASS=$((PASS + 1))
        echo "  ok   : $desc (rc=$rc)"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL : $desc (expected rc=$expected, got rc=$rc)"
    fi
}

# assert_out <期待文字列> <説明> -- <コマンド...>
# stdout が期待値と一致し、かつ終了コードが 0 であることの両方を要求する
# （値を出力後に非 0 終了する退行も検知するため / コードレビュー指摘 #2）。
assert_out() {
    local expected="$1"; shift
    local desc="$1"; shift
    [[ "$1" == "--" ]] && shift
    local out rc
    out="$("$@" 2>/dev/null)"
    rc=$?
    if [[ "$out" == "$expected" && "$rc" == "0" ]]; then
        PASS=$((PASS + 1))
        echo "  ok   : $desc (out=$out, rc=0)"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL : $desc (expected out='$expected' rc=0, got out='$out' rc=$rc)"
    fi
}

echo "== 静的検査（bash -n / shellcheck） =="
for s in "$READ" "$VALIDATE"; do
    assert_rc 0 "bash -n: $(basename "$s")" -- bash -n "$s"
done
if command -v shellcheck >/dev/null 2>&1; then
    assert_rc 0 "shellcheck: state-read.sh / state-validate.sh（重大警告なし）" -- shellcheck "$READ" "$VALIDATE"
else
    echo "  skip : shellcheck 未導入のため静的検査をスキップ"
fi

echo "== cycle 解決: 明示指定優先 =="
# current_cycle に設定された値がそのまま解決される
a1="$TMPDIR_TEST/explicit_default.json"; make_valid_state "$a1"
assert_out "v3.0.0" "current_cycle=v3.0.0 が解決される" -- "$READ" current_cycle "$a1"

# 任意の値でも state.json の値がそのまま返る（解決は state.json driven）
a2="$TMPDIR_TEST/explicit_arbitrary.json"; write_state_with_cycle "$a2" "v9.9.9"
assert_out "v9.9.9" "current_cycle=v9.9.9（任意値）が解決される" -- "$READ" current_cycle "$a2"

echo "== cycle 解決: gitlog 非依存（中核） =="
# git 履歴・周辺ファイル名が v2.6.6 / v1.0.0 でも、state.json の current_cycle=v3.0.0 が返る
sb="$(make_gitlog_decoy_sandbox "v3.0.0")"
if [[ -n "$sb" && -f "$sb/.aidlc/state.json" ]]; then
    # 被テストをサンドボックス cwd 内で実行する（read_cycle_in_sandbox）。
    # これにより、将来 cwd 基準の git 推定が混入した場合は誤誘導履歴（v2.6.6）を踏み、
    # テストが赤になる（指摘 #1: 外側 cwd からの実行では空振りするため）。
    assert_out "v3.0.0" "gitlog 誤誘導（v2.6.6/v1.0.0）下でも current_cycle=v3.0.0 が解決される" \
        -- read_cycle_in_sandbox "$sb"
    # 誤誘導 git 環境が実際に別 cycle 名を含むことを確認（テストの実効性担保 / git -C 不使用）
    decoy_log="$( ( cd "$sb" || exit 1; git log --oneline ) 2>/dev/null )"
    case "$decoy_log" in
        *v2.6.6*) PASS=$((PASS + 1)); echo "  ok   : 誤誘導 git 履歴に別 cycle 名（v2.6.6）が実在する" ;;
        *) FAIL=$((FAIL + 1)); echo "  FAIL : 誤誘導 git 履歴に別 cycle 名が含まれていない（テスト前提不成立）" ;;
    esac

    # 同サンドボックスで state.json を v9.9.9 に書き換えると、その値が返る（git 履歴は不変）
    write_state_with_cycle "$sb/.aidlc/state.json" "v9.9.9"
    assert_out "v9.9.9" "同 git 履歴下で state.json 変更後は current_cycle=v9.9.9 が解決される" \
        -- read_cycle_in_sandbox "$sb"
else
    FAIL=$((FAIL + 1)); echo "  FAIL : gitlog 誤誘導サンドボックスの構築に失敗"
fi

echo "== cycle 解決: 未設定/欠落・明示 null =="
# current_cycle キー欠落時、state-read.sh は明示エラー（exit 1）で拒否する
miss="$TMPDIR_TEST/missing_cycle.json"; make_valid_state "$miss"
jq 'del(.current_cycle)' "$miss" > "$miss.tmp" && mv "$miss.tmp" "$miss"
assert_rc 1 "current_cycle 欠落時 state-read は exit 1（明示エラー）" -- "$READ" current_cycle "$miss"

# current_cycle 欠落時、state-validate.sh も無効判定（exit 1）する
assert_rc 1 "current_cycle 欠落時 state-validate は無効（exit 1）" -- "$VALIDATE" "$miss"

# 明示 null は欠落と区別し、"null" を出力して exit 0
nullc="$TMPDIR_TEST/null_cycle.json"; make_valid_state "$nullc"
jq '.current_cycle = null' "$nullc" > "$nullc.tmp" && mv "$nullc.tmp" "$nullc"
assert_out "null" "current_cycle 明示 null は \"null\" を出力（欠落と区別）" -- "$READ" current_cycle "$nullc"
# state-validate.sh は current_cycle string 必須のため、明示 null は無効判定（null 許容退行の検知 / 指摘 #3）
assert_rc 1 "current_cycle 明示 null は state-validate で無効（exit 1）" -- "$VALIDATE" "$nullc"

echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
