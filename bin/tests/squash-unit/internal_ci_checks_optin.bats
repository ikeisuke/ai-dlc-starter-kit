#!/usr/bin/env bats
# Unit 007: squash-unit.sh の CI 構造チェック opt-in 化テスト
#
# run_internal_ci_checks_or_skip() を bats から source して直接呼び出し、
# - 全揃い: 3 種すべて存在 → 全実行
# - 全不在: 全 check 不在 → 集約 skip + info ログ + 安定トークン
# - 部分存在: 一部のみ存在 → 存在分のみ実行 / 個別 skip は無音
# - starter kit 3 種揃い保証: REPO_ROOT に 3 ファイルが揃っている境界契約
#
# 契約: bats-core >= 1.5（リポジトリ現行 1.13.0）。コマンド実行検証は run --separate-stderr。
# ファイル存在静的アサートは run を介さず [ -f ... ] を使用。

bats_require_minimum_version 1.5.0

setup_file() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
    export REPO_ROOT
}

setup() {
    TMP_DIR="$(mktemp -d -t squash-unit-optin.XXXXXX)"
    cd "$TMP_DIR"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test"
    # squash-unit.sh を source して関数定義のみロード（main "$@" は BASH_SOURCE ガードで起動しない）
    # shellcheck source=/dev/null
    source "${REPO_ROOT}/skills/aidlc/scripts/squash-unit.sh"
}

teardown() {
    cd "$BATS_TMPDIR"
    rm -rf "$TMP_DIR"
}

@test "全揃い: 3 種チェックスクリプトが存在し全 pass で実行される" {
    mkdir -p bin
    cp "${REPO_ROOT}/bin/check-skill-references.sh" bin/
    cp "${REPO_ROOT}/bin/check-bash-substitution.sh" bin/
    cp "${REPO_ROOT}/bin/check-test-isolation.sh" bin/
    cp "${REPO_ROOT}/bin/check-test-isolation.allowlist" bin/
    chmod +x bin/check-*.sh
    # 各 check スクリプトが必要とする最小ファイルを配置（fixture 不在で fail しないよう）
    # 各 check は repo 構造を git ls-files 等で走査するため空 commit を作る
    git add . >/dev/null
    git commit --quiet -m "init"

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # 集約 skip トークンは出力されない
    [[ "$output" != *"squash:info:internal-ci-checks-skipped"* ]]
}

@test "全不在: 全 check が不在で集約 skip + 安定トークン + info ログ" {
    # bin/ も check-*.sh も作らない（consumer プロジェクト想定）
    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # stdout に集約 skip トークン
    [[ "$output" == *"squash:info:internal-ci-checks-skipped"* ]]
    # stderr に集約 info 文言
    [[ "$stderr" == *"info: no internal CI check scripts present in bin/ (skipping)"* ]]
}

@test "部分存在: 一部の check スクリプトのみ存在 / 集約 skip も個別 skip も無音" {
    mkdir -p bin
    # check-skill-references.sh のみ配置（他 2 種は配置しない）
    cp "${REPO_ROOT}/bin/check-skill-references.sh" bin/
    chmod +x bin/check-skill-references.sh
    git add . >/dev/null
    git commit --quiet -m "init"

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # 部分存在では集約 skip トークンは出力されない
    [[ "$output" != *"squash:info:internal-ci-checks-skipped"* ]]
    # 個別 skip も無音（集約 info ログも出力されない）
    [[ "$stderr" != *"no internal CI check scripts present"* ]]
}

@test "starter kit 3 種揃い保証: REPO_ROOT/bin/check-*.sh が 3 ファイルすべて存在する" {
    # GATE-8 境界契約: starter kit 自身が 3 種チェックスクリプトを欠落させないことを保証する
    # 1 つでも欠ければ本テストが fail し、全件 bats 実行（pre-commit / CI）でブロックされる
    [ -f "${REPO_ROOT}/bin/check-skill-references.sh" ]
    [ -f "${REPO_ROOT}/bin/check-bash-substitution.sh" ]
    [ -f "${REPO_ROOT}/bin/check-test-isolation.sh" ]
}
