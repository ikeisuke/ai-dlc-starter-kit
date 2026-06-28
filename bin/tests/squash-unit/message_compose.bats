#!/usr/bin/env bats
# Unit 001 (#735): squash-unit.sh 複数 --message 段落結合 / Co-Authored-By 重複排除テスト
#
# 検証対象（v3.0.0-alpha.7 Unit 001 / Issue #735）:
# - 複数 --message を git commit -m 準拠で段落結合（1個目=件名 / 2個目以降=本文段落）
# - 最後の --message に Co-Authored-By を渡しても subject が消えず二重出力しない（#735 再現）
# - 単一 --message の後方互換
# - compose_full_message 純関数: dedup（完全一致 / case 差 / コロン後空白差 / co_authors 内部重複）/
#   空 co_authors / 全既出 / 末尾改行なし契約
# - build_commit_message_file（retroactive 経路）が compose_full_message を通り二重付与しない
#
# 契約: bats-core >= 1.5。実行コマンド検証は run。

bats_require_minimum_version 1.5.0

setup_file() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
    export REPO_ROOT
    export SQUASH="${REPO_ROOT}/skills/aidlc/scripts/squash-unit.sh"
}

# --- 統合テスト用: 一時 git リポジトリと中間コミットを構築 ---
# $1: 中間コミット wip1 に付与する Co-Authored-By 行（空なら付与しない）
setup_repo() {
    local wip1_coauthor="${1:-}"
    TMP_DIR="$(mktemp -d -t squash-unit-msg.XXXXXX)"
    cd "$TMP_DIR"
    git init --quiet
    git config user.email "test@test.com"
    git config user.name "Test"
    # main/master 保護を避けるため cycle ブランチで作業
    git checkout -q -b cycle/vTEST
    echo a > a.txt
    git add a.txt
    git commit -q -m "feat: [vTEST] Inception Phase完了 - base"
    BASE_COMMIT="$(git rev-parse HEAD)"
    echo b > b.txt
    git add b.txt
    if [[ -n "$wip1_coauthor" ]]; then
        git commit -q -m "wip 1" -m "$wip1_coauthor"
    else
        git commit -q -m "wip 1"
    fi
    echo c > c.txt
    git add c.txt
    git commit -q -m "wip 2"
}

teardown() {
    if [[ -n "${TMP_DIR:-}" && -d "${TMP_DIR}" ]]; then
        # 削除前に bats 提供の安全ディレクトリへ退避（test-isolation cd-guard 規約）
        cd "$BATS_TEST_TMPDIR"
        rm -rf "${TMP_DIR}"
    fi
}

# 純関数テスト用に関数定義をロード（main はソースガードで起動しない）
load_functions() {
    # shellcheck source=/dev/null
    source "${SQUASH}"
}

# =========================================================================
# 統合テスト（実 squash 実行）
# =========================================================================

@test "integration: 複数 --message が段落結合される（件名 + 本文段落）" {
    setup_repo ""
    run bash "${SQUASH}" --cycle vTEST --vcs git --base "${BASE_COMMIT}" \
        --message "feat: [vTEST] Unit 001完了 - 段落結合" \
        --message "本文段落の内容"
    [ "$status" -eq 0 ]
    run git log -1 --format=%B
    # 1 行目が件名
    [ "$(printf '%s\n' "$output" | sed -n '1p')" = "feat: [vTEST] Unit 001完了 - 段落結合" ]
    # 本文段落が空行区切りで含まれる
    [ "$(printf '%s\n' "$output" | sed -n '2p')" = "" ]
    [ "$(printf '%s\n' "$output" | sed -n '3p')" = "本文段落の内容" ]
}

@test "integration: 最後の --message に Co-Authored-By を渡しても subject が保持され二重出力しない（#735 再現）" {
    # 中間コミット wip1 に同一 Co-Authored-By を付与 → 抽出経路でも拾われる
    setup_repo "Co-Authored-By: Claude <noreply@anthropic.com>"
    run bash "${SQUASH}" --cycle vTEST --vcs git --base "${BASE_COMMIT}" \
        --message "feat: [vTEST] Unit 001完了 - subject 保持" \
        --message "Co-Authored-By: Claude <noreply@anthropic.com>"
    [ "$status" -eq 0 ]
    run git log -1 --format=%B
    # subject が消えていない
    [ "$(printf '%s\n' "$output" | sed -n '1p')" = "feat: [vTEST] Unit 001完了 - subject 保持" ]
    # Co-Authored-By: Claude が 1 回のみ
    [ "$(printf '%s\n' "$output" | grep -c "Co-Authored-By: Claude <noreply@anthropic.com>")" -eq 1 ]
}

@test "integration: 単一 --message の後方互換（件名のみ）" {
    setup_repo ""
    run bash "${SQUASH}" --cycle vTEST --vcs git --base "${BASE_COMMIT}" \
        --message "feat: [vTEST] Unit 001完了 - 単一メッセージ"
    [ "$status" -eq 0 ]
    run git log -1 --format=%s
    [ "$output" = "feat: [vTEST] Unit 001完了 - 単一メッセージ" ]
}

@test "integration(retroactive): 実 CLI 経路で subject 保持 + Co-Authored-By 二重出力なし" {
    # 中間コミット wip1 に Co-Authored-By を付与 → extract_co_authors_for_range で拾われる
    setup_repo "Co-Authored-By: Claude <noreply@anthropic.com>"
    local from_c to_c
    from_c="$(git rev-parse HEAD~1)"  # wip 1
    to_c="$(git rev-parse HEAD)"      # wip 2
    # extract_co_authors_for_range -> build_commit_message_file -> rebase editor の接続を検証
    run bash "${SQUASH}" --cycle vTEST --vcs git --retroactive --unit 001 \
        --from "$from_c" --to "$to_c" \
        --message "feat: [vTEST] Unit 001完了 - retro" \
        --message "Co-Authored-By: Claude <noreply@anthropic.com>"
    [ "$status" -eq 0 ]
    run git log -1 --format=%B
    [ "$(printf '%s\n' "$output" | sed -n '1p')" = "feat: [vTEST] Unit 001完了 - retro" ]
    [ "$(printf '%s\n' "$output" | grep -c "Co-Authored-By: Claude <noreply@anthropic.com>")" -eq 1 ]
}

# =========================================================================
# 純関数テスト: compose_full_message
# =========================================================================

@test "compose: co_authors 空なら message をそのまま返す" {
    load_functions
    run compose_full_message "feat: title" ""
    [ "$status" -eq 0 ]
    [ "$output" = "feat: title" ]
}

@test "compose: 通常付与（message + 空行 + co_author）" {
    load_functions
    result="$(compose_full_message "feat: title" "Co-Authored-By: Claude <noreply@anthropic.com>")"
    expected="$(printf 'feat: title\n\nCo-Authored-By: Claude <noreply@anthropic.com>')"
    [ "$result" = "$expected" ]
}

@test "compose: message 側に既出の Co-Authored-By は二重付与しない" {
    load_functions
    msg="$(printf 'feat: title\n\nCo-Authored-By: Claude <noreply@anthropic.com>')"
    result="$(compose_full_message "$msg" "Co-Authored-By: Claude <noreply@anthropic.com>")"
    [ "$(printf '%s\n' "$result" | grep -c "Co-Authored-By: Claude")" -eq 1 ]
    [ "$(printf '%s\n' "$result" | sed -n '1p')" = "feat: title" ]
}

@test "compose: case 差・コロン後空白差で重複排除される" {
    load_functions
    msg="$(printf 'feat: title\n\nCo-Authored-By: Claude <noreply@anthropic.com>')"
    result="$(compose_full_message "$msg" "co-authored-by:  Claude <noreply@anthropic.com>")"
    # Co-Authored-By 行（大小文字問わず）が 1 件のみ
    count="$(printf '%s\n' "$result" | grep -ci "co-authored-by:")"
    [ "$count" -eq 1 ]
    # subject も保持
    [ "$(printf '%s\n' "$result" | sed -n '1p')" = "feat: title" ]
}

@test "compose: co_authors 内部の重複（case 差）も一意化される" {
    load_functions
    co="$(printf 'Co-Authored-By: Claude <noreply@anthropic.com>\nco-authored-by: Claude <noreply@anthropic.com>')"
    result="$(compose_full_message "feat: title" "$co")"
    [ "$(printf '%s\n' "$result" | grep -ci "co-authored-by:")" -eq 1 ]
}

@test "compose: 異なる 2 著者は両方残る" {
    load_functions
    co="$(printf 'Co-Authored-By: Claude <noreply@anthropic.com>\nCo-Authored-By: Codex <noreply@openai.com>')"
    result="$(compose_full_message "feat: title" "$co")"
    [ "$(printf '%s\n' "$result" | grep -ci "co-authored-by:")" -eq 2 ]
}

@test "compose: 全て既出なら message 単体（残余なし）" {
    load_functions
    msg="$(printf 'feat: title\n\nCo-Authored-By: Claude <noreply@anthropic.com>')"
    result="$(compose_full_message "$msg" "Co-Authored-By: Claude <noreply@anthropic.com>")"
    [ "$result" = "$msg" ]
}

@test "compose: 出力に末尾改行を付与しない（契約）" {
    load_functions
    # printf '%s' で取得した長さと、wc -c の差で末尾改行有無を判定
    out="$(compose_full_message "feat: title" "Co-Authored-By: Claude <noreply@anthropic.com>")"
    # command substitution は末尾改行を除去するため、明示的に再付与せず raw を確認
    compose_full_message "feat: title" "Co-Authored-By: Claude <noreply@anthropic.com>" > "${BATS_TEST_TMPDIR}/out.txt"
    # ファイル末尾が改行でないこと（最後のバイトが \n でない）
    last_byte="$(tail -c 1 "${BATS_TEST_TMPDIR}/out.txt")"
    [ -n "$last_byte" ]
}

# =========================================================================
# 純関数テスト: build_commit_message_file（retroactive 経路）
# =========================================================================

@test "build_commit_message_file: message 側 Co-Authored-By と co_authors の二重付与をしない（retroactive 経路）" {
    load_functions
    msg="$(printf 'feat: [vTEST] Unit 003完了 - retro\n\nCo-Authored-By: Claude <noreply@anthropic.com>')"
    msg_file="$(build_commit_message_file "$msg" "Co-Authored-By: Claude <noreply@anthropic.com>")"
    [ -f "$msg_file" ]
    [ "$(sed -n '1p' "$msg_file")" = "feat: [vTEST] Unit 003完了 - retro" ]
    [ "$(grep -c "Co-Authored-By: Claude" "$msg_file")" -eq 1 ]
}

@test "build_commit_message_file: co_authors 空でも件名が保持される" {
    load_functions
    msg_file="$(build_commit_message_file "feat: [vTEST] Unit 003完了 - retro" "")"
    [ -f "$msg_file" ]
    [ "$(sed -n '1p' "$msg_file")" = "feat: [vTEST] Unit 003完了 - retro" ]
    [ "$(grep -c "Co-Authored-By" "$msg_file")" -eq 0 ]
}
