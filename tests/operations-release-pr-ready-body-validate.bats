#!/usr/bin/env bats
bats_require_minimum_version 1.5.0
# v2.6.2 Unit 001 / Issue #678
# cmd_pr_ready --body-file の事前検証（_pr_ready_validate_body_file）の Primary 経路テスト。
# 0 バイト / 不在 / 非 regular file を実行前検出し、外部副作用ゼロ（gh / pr-ops.sh / git 系を呼ばない）で停止する。

setup() {
    REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
    # 既存 gh shim を流用（call log 機能つき）
    SHIM_DIR="${REPO_ROOT}/tests/fixtures/gh-pr-edit-fallback"
    PATH="${SHIM_DIR}:${PATH}"
    export PATH

    # operations-release.sh を source
    # shellcheck disable=SC1091
    source "${REPO_ROOT}/skills/aidlc/scripts/operations-release.sh"

    GH_MOCK_CALL_LOG="$(mktemp -t aidlc-unit001-ghcalls.XXXXXX)"
    export GH_MOCK_CALL_LOG
    : > "$GH_MOCK_CALL_LOG"
}

teardown() {
    rm -f "$GH_MOCK_CALL_LOG"
    unset GH_MOCK_CALL_LOG
    unset GH_MOCK_MODE
}

# --- _pr_ready_validate_body_file() 単体テスト ---

@test "validator: Valid - 通常ファイル（サイズ >= 1）は exit 0 で stderr 出力なし" {
    local f
    f="$(mktemp -t aidlc-unit001-valid.XXXXXX)"
    printf '## body\n' > "$f"

    run _pr_ready_validate_body_file "$f"
    rm -f "$f"

    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "validator: Empty - 0 バイトファイルは exit 1 で機械可読エラー + 人間可読案内" {
    local f
    f="$(mktemp -t aidlc-unit001-empty.XXXXXX)"
    : > "$f"

    run _pr_ready_validate_body_file "$f"
    rm -f "$f"

    [ "$status" -eq 1 ]
    # 機械可読: error<TAB>pr-ready:body-file-empty<TAB><path>
    [[ "$output" == *"error"*"pr-ready:body-file-empty"* ]]
    [[ "$output" == *"$f"* ]]
    # 人間可読
    [[ "$output" == *"本文が空です"* ]]
}

@test "validator: Missing - 不在パスは exit 1 で machine-readable missing エラー" {
    local missing_path="/tmp/aidlc-unit001-missing-${RANDOM}-${RANDOM}.txt"
    rm -f "$missing_path"

    run _pr_ready_validate_body_file "$missing_path"

    [ "$status" -eq 1 ]
    [[ "$output" == *"error"*"pr-ready:body-file-missing"* ]]
    [[ "$output" == *"$missing_path"* ]]
    # Empty 案内行は出力されない
    [[ "$output" != *"本文が空です"* ]]
}

@test "validator: Missing - ディレクトリは非 regular file として missing 扱い" {
    local d
    d="$(mktemp -d -t aidlc-unit001-dir.XXXXXX)"

    run _pr_ready_validate_body_file "$d"
    rmdir "$d"

    [ "$status" -eq 1 ]
    [[ "$output" == *"error"*"pr-ready:body-file-missing"* ]]
}

@test "validator: tab 区切りフォーマット - 機械可読 1 行目が 3 フィールド tab 区切り" {
    local missing_path="/tmp/aidlc-unit001-tab-${RANDOM}.txt"
    rm -f "$missing_path"

    run _pr_ready_validate_body_file "$missing_path"

    [ "$status" -eq 1 ]
    # 1 行目を取り出して tab 区切りフィールド数を確認
    local first_line="${lines[0]}"
    # 3 フィールド = tab 2 個
    local tab_count="${first_line//[!$'\t']/}"
    [ "${#tab_count}" -eq 2 ]
    # 1 フィールド目は "error"
    [[ "$first_line" == "error"$'\t'* ]]
    # 2 フィールド目は missing コード
    [[ "$first_line" == *$'\t'"pr-ready:body-file-missing"$'\t'* ]]
}

# --- cmd_pr_ready Primary 経路: 0 バイト / 不在で fail-fast し下流コマンドを呼ばない ---

@test "cmd_pr_ready: --body-file が 0 バイトなら exit 1 + 機械可読エラー + gh 未呼び出し" {
    export GH_MOCK_MODE="pr-edit-success"
    local empty_file
    empty_file="$(mktemp -t aidlc-unit001-cmd-empty.XXXXXX)"
    : > "$empty_file"

    run cmd_pr_ready --cycle v2.6.2 --pr 123 --body-file "$empty_file"
    rm -f "$empty_file"

    [ "$status" -eq 1 ]
    [[ "$output" == *"error"*"pr-ready:body-file-empty"* ]]
    [[ "$output" == *"本文が空です"* ]]
    # gh shim 一度も呼ばれていない
    [ ! -s "$GH_MOCK_CALL_LOG" ]
}

@test "cmd_pr_ready: --body-file 不在パスなら exit 1 + missing エラー + gh 未呼び出し" {
    export GH_MOCK_MODE="pr-edit-success"
    local missing_path="/tmp/aidlc-unit001-cmd-missing-${RANDOM}.txt"
    rm -f "$missing_path"

    run cmd_pr_ready --cycle v2.6.2 --pr 456 --body-file "$missing_path"

    [ "$status" -eq 1 ]
    [[ "$output" == *"error"*"pr-ready:body-file-missing"* ]]
    [[ "$output" == *"$missing_path"* ]]
    [ ! -s "$GH_MOCK_CALL_LOG" ]
}

@test "cmd_pr_ready: --body-file がディレクトリでも missing 扱いで fail-fast" {
    export GH_MOCK_MODE="pr-edit-success"
    local d
    d="$(mktemp -d -t aidlc-unit001-cmd-dir.XXXXXX)"

    run cmd_pr_ready --cycle v2.6.2 --pr 789 --body-file "$d"
    rmdir "$d"

    [ "$status" -eq 1 ]
    [[ "$output" == *"error"*"pr-ready:body-file-missing"* ]]
    [ ! -s "$GH_MOCK_CALL_LOG" ]
}

@test "cmd_pr_ready: --body-file 未指定（既存挙動）への影響なし - validator は呼ばれない" {
    # --body-file 未指定経路は本 Unit のスコープ外。validator が呼ばれず、
    # 既存の body-file-required 等のエラー経路に影響しないことを確認する。
    # dry-run で副作用を回避しつつ、validator のエラーコードが混入しないことを検証。
    export GH_MOCK_MODE="pr-edit-success"
    run cmd_pr_ready --dry-run --cycle v2.6.2 --pr 999
    # body-file 未指定での validator エラーコードは混入しないこと
    [[ "$output" != *"pr-ready:body-file-empty"* ]]
    [[ "$output" != *"pr-ready:body-file-missing"* ]]
}
