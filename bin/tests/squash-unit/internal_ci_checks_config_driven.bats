#!/usr/bin/env bats
# Unit 005: squash-unit.sh の CI 構造チェック設定駆動化テスト
#
# run_internal_ci_checks_or_skip() および parse_config_array() / is_invalid_check_path() を
# bats から source して直接呼び出し、設定駆動化後の分岐を検証する。
#
# 検証対象（v2.6.1 Unit 005 / Issue #687）:
# - 設定 3 種指定 + 全実体存在 → 全実行成功（既存と同等動作）
# - 設定 3 種指定 + 一部実体不在 → 個別 skip + 残り実行成功
# - 空配列指定 → 集約 skip + reason=empty-config
# - セクション不在 → 集約 skip + reason=no-config（consumer プロジェクト想定）
# - 設定読取エラー（dasel 未利用環境想定）→ 集約 skip + reason=config-read-error
# - 不正フォーマット → 集約 skip + reason=invalid-config-format
# - 不正パス（絶対パス / traversal / 不正文字 / 空）→ 個別 skip + reason=invalid-path
# - チェック失敗 → 既存安定トークン squash:error:<basename>-failed + return 2
# - 既存トークン後方互換: squash:info:internal-ci-checks-skipped が 1 行目として常時出力
#
# 契約: bats-core >= 1.5。コマンド実行検証は run --separate-stderr。

bats_require_minimum_version 1.5.0

setup_file() {
    REPO_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/../../.." && pwd)"
    export REPO_ROOT
}

setup() {
    TMP_DIR="$(mktemp -d -t squash-unit-cfg.XXXXXX)"
    cd "$TMP_DIR"
    git init --quiet
    git config user.email "test@example.com"
    git config user.name "Test"

    # squash-unit.sh を source して関数定義のみロード
    # shellcheck source=/dev/null
    source "${REPO_ROOT}/skills/aidlc/scripts/squash-unit.sh"

    # 各テストでは config.toml を TMP_DIR に作る。read-config.sh は cwd の
    # .aidlc/config.toml を「プロジェクト設定」として読むため、cwd 配下に
    # .aidlc/config.toml を配置すれば設定駆動分岐を検証できる。
    mkdir -p .aidlc
}

teardown() {
    cd "$BATS_TMPDIR"
    rm -rf "$TMP_DIR"
}

# ============================================================
# parse_config_array 単体テスト
# ============================================================

@test "parse_config_array: 正常な list literal をデコードする" {
    run --separate-stderr parse_config_array "['bin/a.sh', 'bin/b.sh']"
    [ "$status" -eq 0 ]
    [[ "$output" == *"bin/a.sh"* ]]
    [[ "$output" == *"bin/b.sh"* ]]
}

@test "parse_config_array: 空配列 [] は exit 0 + 0 行" {
    run --separate-stderr parse_config_array "[]"
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "parse_config_array: 空文字列は exit 0 + 0 行（防御的処理）" {
    run --separate-stderr parse_config_array ""
    [ "$status" -eq 0 ]
    [ -z "$output" ]
}

@test "parse_config_array: 配列開始がない不正フォーマットは exit 1" {
    run --separate-stderr parse_config_array "broken"
    [ "$status" -eq 1 ]
}

@test "parse_config_array: 配列終端がない不正フォーマットは exit 1" {
    run --separate-stderr parse_config_array "[a"
    [ "$status" -eq 1 ]
}

@test "parse_config_array: 制御文字混入は exit 1" {
    run --separate-stderr parse_config_array $'[a\x01]'
    [ "$status" -eq 1 ]
}

@test "parse_config_array: クオート欠落は exit 1（厳密フォーマット検証）" {
    # コードレビュー Round 1 指摘 #1 反映: クオートなしは invalid
    run --separate-stderr parse_config_array "[bin/a.sh, bin/b.sh]"
    [ "$status" -eq 1 ]
}

@test "parse_config_array: スペース区切り（カンマなし）は exit 1" {
    run --separate-stderr parse_config_array "['a' 'b']"
    [ "$status" -eq 1 ]
}

@test "parse_config_array: クオート種類混在（' と \"）は許容される" {
    run --separate-stderr parse_config_array "['a', \"b\"]"
    [ "$status" -eq 0 ]
    [[ "$output" == *"a"* ]]
    [[ "$output" == *"b"* ]]
}

# ============================================================
# is_invalid_check_path 単体テスト
# ============================================================

@test "is_invalid_check_path: 妥当なリポジトリルート相対パスは valid（return 1）" {
    run --separate-stderr is_invalid_check_path "bin/check-skill-references.sh"
    [ "$status" -eq 1 ]
}

@test "is_invalid_check_path: 空エントリは invalid（return 0）" {
    run --separate-stderr is_invalid_check_path ""
    [ "$status" -eq 0 ]
}

@test "is_invalid_check_path: 絶対パスは invalid" {
    run --separate-stderr is_invalid_check_path "/etc/passwd"
    [ "$status" -eq 0 ]
}

@test "is_invalid_check_path: '..' を含むパスは invalid（traversal）" {
    run --separate-stderr is_invalid_check_path "../etc/passwd"
    [ "$status" -eq 0 ]
}

@test "is_invalid_check_path: パス中に '..' を含む場合も invalid" {
    run --separate-stderr is_invalid_check_path "bin/../etc/passwd"
    [ "$status" -eq 0 ]
}

@test "is_invalid_check_path: 許容文字外は invalid（スペース）" {
    run --separate-stderr is_invalid_check_path "bin/with space.sh"
    [ "$status" -eq 0 ]
}

# ============================================================
# run_internal_ci_checks_or_skip 統合テスト
# ============================================================

@test "config-driven: 3 種指定 + 全実体存在 → 全実行成功（既存と同等動作）" {
    mkdir -p bin
    cp "${REPO_ROOT}/bin/check-skill-references.sh" bin/
    cp "${REPO_ROOT}/bin/check-bash-substitution.sh" bin/
    cp "${REPO_ROOT}/bin/check-test-isolation.sh" bin/
    cp "${REPO_ROOT}/bin/check-test-isolation.allowlist" bin/
    chmod +x bin/check-*.sh
    cat > .aidlc/config.toml <<'EOF'
[rules.squash.internal_ci_checks]
scripts = ["bin/check-skill-references.sh", "bin/check-bash-substitution.sh", "bin/check-test-isolation.sh"]
EOF
    git add . >/dev/null
    git commit --quiet -m "init"

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # 集約 skip トークンは出力されない
    [[ "$output" != *"squash:info:internal-ci-checks-skipped"* ]]
}

@test "config-driven: セクション不在 → 集約 skip + reason=no-config（consumer 想定）" {
    cat > .aidlc/config.toml <<'EOF'
[project]
name = "consumer-test"
EOF

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # 1 行目: 既存トークン（後方互換）
    [[ "${lines[0]}" == "squash:info:internal-ci-checks-skipped" ]]
    # 2 行目: reason 別行
    [[ "${lines[1]}" == "squash:info:internal-ci-checks-skipped:reason=no-config" ]]
}

@test "config-driven: 空配列指定 → 集約 skip + reason=empty-config" {
    cat > .aidlc/config.toml <<'EOF'
[rules.squash.internal_ci_checks]
scripts = []
EOF

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    [[ "${lines[0]}" == "squash:info:internal-ci-checks-skipped" ]]
    [[ "${lines[1]}" == "squash:info:internal-ci-checks-skipped:reason=empty-config" ]]
}

@test "config-driven: 全エントリが実体不在 → 集約 skip + reason=no-script-present" {
    # 設定はあるが、bin/ にスクリプトを配置しない
    cat > .aidlc/config.toml <<'EOF'
[rules.squash.internal_ci_checks]
scripts = ["bin/check-foo.sh", "bin/check-bar.sh"]
EOF

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # 個別 skip 2 件 + 集約 skip 2 行
    [[ "$output" == *"squash:info:internal-ci-check-skipped:reason=script-not-found:script=bin/check-foo.sh"* ]]
    [[ "$output" == *"squash:info:internal-ci-check-skipped:reason=script-not-found:script=bin/check-bar.sh"* ]]
    [[ "$output" == *"squash:info:internal-ci-checks-skipped"* ]]
    [[ "$output" == *"squash:info:internal-ci-checks-skipped:reason=no-script-present"* ]]
}

@test "config-driven: 一部実体不在 → 個別 skip + 残り実行成功（集約 skip なし）" {
    mkdir -p bin
    cp "${REPO_ROOT}/bin/check-skill-references.sh" bin/
    chmod +x bin/check-skill-references.sh
    cat > .aidlc/config.toml <<'EOF'
[rules.squash.internal_ci_checks]
scripts = ["bin/check-skill-references.sh", "bin/check-missing.sh"]
EOF
    git add . >/dev/null
    git commit --quiet -m "init"

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    # 個別 skip
    [[ "$output" == *"squash:info:internal-ci-check-skipped:reason=script-not-found:script=bin/check-missing.sh"* ]]
    # 集約 skip は出ない（1 件は実行済み）
    [[ "$output" != *"squash:info:internal-ci-checks-skipped"* ]]
}

@test "config-driven: 不正パス（絶対パス）→ 個別 skip + reason=invalid-path" {
    cat > .aidlc/config.toml <<'EOF'
[rules.squash.internal_ci_checks]
scripts = ["/etc/passwd", "bin/check-real.sh"]
EOF
    mkdir -p bin
    cp "${REPO_ROOT}/bin/check-skill-references.sh" bin/check-real.sh
    chmod +x bin/check-real.sh
    git add . >/dev/null
    git commit --quiet -m "init"

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    [[ "$output" == *"squash:warn:internal-ci-check-skipped:reason=invalid-path:script=/etc/passwd"* ]]
    # 集約 skip は出ない（1 件は実行済み）
    [[ "$output" != *"squash:info:internal-ci-checks-skipped"* ]]
}

@test "config-driven: 不正パス（traversal）→ 個別 skip + reason=invalid-path" {
    cat > .aidlc/config.toml <<'EOF'
[rules.squash.internal_ci_checks]
scripts = ["bin/../etc/passwd"]
EOF

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 0 ]
    [[ "$output" == *"squash:warn:internal-ci-check-skipped:reason=invalid-path:script=bin/../etc/passwd"* ]]
    # 全 entry skip → no-script-present
    [[ "$output" == *"squash:info:internal-ci-checks-skipped:reason=no-script-present"* ]]
}

@test "config-driven: チェック失敗 → 既存トークン squash:error:<basename>-failed + return 2" {
    mkdir -p bin
    cat > bin/check-fail.sh <<'EOF'
#!/usr/bin/env bash
echo "intentional failure" >&2
exit 1
EOF
    chmod +x bin/check-fail.sh
    cat > .aidlc/config.toml <<'EOF'
[rules.squash.internal_ci_checks]
scripts = ["bin/check-fail.sh"]
EOF
    git add . >/dev/null
    git commit --quiet -m "init"

    run --separate-stderr run_internal_ci_checks_or_skip "$PWD"
    [ "$status" -eq 2 ]
    [[ "$output" == *"squash:error:check-fail-failed"* ]]
}

# ============================================================
# 後方互換: 本体スクリプトに固有名がハードコードされていないことを確認
# ============================================================

@test "backward-compat: squash-unit.sh に starter kit 固有チェック名がハードコードされていない" {
    run --separate-stderr grep -nE 'check-skill-references|check-bash-substitution|check-test-isolation' \
        "${REPO_ROOT}/skills/aidlc/scripts/squash-unit.sh"
    # grep は何もマッチしない場合 exit 1
    [ "$status" -eq 1 ]
}

# ============================================================
# GATE-8 境界契約（v2.6.0 Unit 007 由来 / Unit 005 で本ファイルへ移植）
# starter kit 自身が 3 種チェックスクリプトを欠落させないことを保証する。
# 1 つでも欠ければ本テストが fail し、全件 bats 実行（pre-commit / CI）でブロックされる。
# ============================================================

@test "GATE-8: starter kit リポジトリに bin/check-skill-references.sh が存在する" {
    [ -f "${REPO_ROOT}/bin/check-skill-references.sh" ]
}

@test "GATE-8: starter kit リポジトリに bin/check-bash-substitution.sh が存在する" {
    [ -f "${REPO_ROOT}/bin/check-bash-substitution.sh" ]
}

@test "GATE-8: starter kit リポジトリに bin/check-test-isolation.sh が存在する" {
    [ -f "${REPO_ROOT}/bin/check-test-isolation.sh" ]
}

@test "GATE-8 starter kit config has 3 scripts" {
    # 設定駆動化後、3 種実行は .aidlc/config.toml の設定に依存する。
    # consumer プロジェクトでは省略可だが、starter kit 自身の dogfooding として
    # 3 種が設定されていることを保証する。
    # 注: bootstrap.sh が export した AIDLC_* 環境変数を引きずらないよう
    # subshell + env -u で隔離して REPO_ROOT 上の config を読む。
    local raw
    raw=$(env -u AIDLC_CONFIG -u AIDLC_LOCAL_CONFIG -u AIDLC_LOCAL_CONFIG_LEGACY \
        -u AIDLC_PROJECT_ROOT -u AIDLC_CYCLES -u AIDLC_DEFAULTS \
        -u AIDLC_MARKETPLACE_JSON -u _AIDLC_DASEL_BRACKET \
        bash -c "cd \"${REPO_ROOT}\" && bash skills/aidlc/scripts/read-config.sh rules.squash.internal_ci_checks.scripts")
    [[ "$raw" == *"bin/check-skill-references.sh"* ]]
    [[ "$raw" == *"bin/check-bash-substitution.sh"* ]]
    [[ "$raw" == *"bin/check-test-isolation.sh"* ]]
}
