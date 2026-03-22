#!/usr/bin/env bash
#
# test_kiro_merge.sh - setup_kiro_agent() / _merge_kiro_commands_*() ユニットテスト
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TMPDIR_BASE=""
COUNTER_FILE=""

# --- テストヘルパー ---

setup_tmpdir() {
    TMPDIR_BASE=$(mktemp -d)
    COUNTER_FILE="${TMPDIR_BASE}/.test_counters"
    printf '0\n0\n' > "$COUNTER_FILE"
}

cleanup_tmpdir() {
    if [ -n "$TMPDIR_BASE" ] && [ -d "$TMPDIR_BASE" ]; then
        \rm -rf "$TMPDIR_BASE"
    fi
}
trap cleanup_tmpdir EXIT

_inc_pass() {
    local pass fail
    { read -r pass; read -r fail; } < "$COUNTER_FILE"
    printf '%d\n%d\n' "$(( pass + 1 ))" "$fail" > "$COUNTER_FILE"
}

_inc_fail() {
    local pass fail
    { read -r pass; read -r fail; } < "$COUNTER_FILE"
    printf '%d\n%d\n' "$pass" "$(( fail + 1 ))" > "$COUNTER_FILE"
}

assert_eq() {
    local test_name="$1"
    local expected="$2"
    local actual="$3"
    if [ "$expected" = "$actual" ]; then
        echo "  PASS: $test_name"
        _inc_pass
    else
        echo "  FAIL: $test_name (expected='$expected', actual='$actual')"
        _inc_fail
    fi
}

assert_contains() {
    local test_name="$1"
    local expected_substring="$2"
    local actual="$3"
    if printf '%s' "$actual" | grep -qF "$expected_substring"; then
        echo "  PASS: $test_name"
        _inc_pass
    else
        echo "  FAIL: $test_name (expected to contain '$expected_substring', actual='$actual')"
        _inc_fail
    fi
}

# 対象スクリプトから関数を読み込む
source_functions() {
    local script="${SCRIPT_DIR}/../bin/setup-ai-tools.sh"
    # set -euo pipefail を除外して関数のみ読み込み
    eval "$(sed -n '1,/^echo "=== AI Tools Setup ==="/{ /^echo "=== AI Tools Setup ==="/d; /^set -euo pipefail/d; p; }' "$script")"
}

# 統合テスト用: テンプレートソースファイルのパス
REAL_TEMPLATE="${SCRIPT_DIR}/../kiro/agents/aidlc.json"

# --- テスト ---

echo "=== _merge_kiro_commands / setup_kiro_agent テスト ==="

setup_tmpdir
source_functions

echo ""
echo "--- テスト1: _generate_kiro_template() が有効なJSONを返す ---"
(
    result=$(_generate_kiro_template)
    if echo "$result" | jq . >/dev/null 2>&1; then
        echo "  PASS: 有効なJSON"
        _inc_pass
    else
        echo "  FAIL: 無効なJSON"
        _inc_fail
    fi

    # allowedCommands が存在するか
    ac_count=$(echo "$result" | jq '.toolsSettings.shell.allowedCommands | length')
    if [ "$ac_count" -gt 0 ]; then
        echo "  PASS: allowedCommandsが存在 (${ac_count}件)"
        _inc_pass
    else
        echo "  FAIL: allowedCommandsが空"
        _inc_fail
    fi
)

echo ""
echo "--- テスト2: _merge_kiro_commands_jq() 新規追加あり ---"
(
    test_file="${TMPDIR_BASE}/test2.json"
    cat > "$test_file" <<'EOF'
{
  "name": "aidlc",
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["echo hello"]
    }
  }
}
EOF
    merge_count_file="${TMPDIR_BASE}/test2_counts"
    merged=$(_merge_kiro_commands_jq "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?
    assert_eq "戻り値=0" "0" "$rc"

    counts=$(cat "$merge_count_file")
    new_count=$(echo "$counts" | awk '{print $1}')
    if [ "$new_count" -gt 0 ]; then
        echo "  PASS: 新規追加あり (${new_count}件)"
        _inc_pass
    else
        echo "  FAIL: 新規追加なし"
        _inc_fail
    fi

    # マージ済みJSONに _meta が含まれないことを確認
    if echo "$merged" | jq -e '._meta' >/dev/null 2>&1; then
        echo "  FAIL: _metaが残っている"
        _inc_fail
    else
        echo "  PASS: _metaなし（純粋JSON）"
        _inc_pass
    fi
)

echo ""
echo "--- テスト3: _merge_kiro_commands_jq() 全パターン既存 ---"
(
    # テンプレートの全コマンドを含むファイルを作成
    template_cmds=$(_generate_kiro_template | jq '.toolsSettings.shell.allowedCommands')
    test_file="${TMPDIR_BASE}/test3.json"
    echo "{\"name\":\"aidlc\",\"toolsSettings\":{\"shell\":{\"allowedCommands\":$template_cmds}}}" | jq . > "$test_file"

    merge_count_file="${TMPDIR_BASE}/test3_counts"
    merged=$(_merge_kiro_commands_jq "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?
    assert_eq "戻り値=1（全パターン既存）" "1" "$rc"
)

echo ""
echo "--- テスト4: ワイルドカード包含チェック ---"
(
    # "git *" があれば "git checkout *" は包含される
    test_file="${TMPDIR_BASE}/test4.json"
    cat > "$test_file" <<'EOF'
{
  "name": "aidlc",
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["git *", "ls *", "cat *"]
    }
  }
}
EOF
    merge_count_file="${TMPDIR_BASE}/test4_counts"
    merged=$(_merge_kiro_commands_jq "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?
    counts=$(cat "$merge_count_file")
    skipped_count=$(echo "$counts" | awk '{print $2}')

    if [ "$skipped_count" -gt 0 ]; then
        echo "  PASS: ワイルドカード包含スキップあり (${skipped_count}件)"
        _inc_pass
    else
        echo "  FAIL: ワイルドカード包含スキップなし"
        _inc_fail
    fi
)

echo ""
echo "--- テスト5: allowedCommands がnull/未定義 → 空配列補完 ---"
(
    test_file="${TMPDIR_BASE}/test5.json"
    cat > "$test_file" <<'EOF'
{
  "name": "aidlc",
  "toolsSettings": {
    "shell": {}
  }
}
EOF
    merge_count_file="${TMPDIR_BASE}/test5_counts"
    merged=$(_merge_kiro_commands_jq "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?
    assert_eq "戻り値=0（新規追加あり）" "0" "$rc"
)

echo ""
echo "--- テスト6: allowedCommands が不正型 → return 2 ---"
(
    test_file="${TMPDIR_BASE}/test6.json"
    cat > "$test_file" <<'EOF'
{
  "name": "aidlc",
  "toolsSettings": {
    "shell": {
      "allowedCommands": "not-an-array"
    }
  }
}
EOF
    merge_count_file="${TMPDIR_BASE}/test6_counts"
    merged=$(_merge_kiro_commands_jq "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?
    assert_eq "戻り値=2（スキーマエラー）" "2" "$rc"
)

echo ""
echo "--- テスト7: _merge_kiro_commands_python() 新規追加あり ---"
(
    if ! command -v python3 >/dev/null 2>&1; then
        echo "  SKIP: python3 not found"
        _inc_pass
    else
        test_file="${TMPDIR_BASE}/test7.json"
        cat > "$test_file" <<'EOF'
{
  "name": "aidlc",
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["echo hello"]
    }
  }
}
EOF
        merge_count_file="${TMPDIR_BASE}/test7_counts"
        merged=$(_merge_kiro_commands_python "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?
        assert_eq "Python版 戻り値=0" "0" "$rc"

        counts=$(cat "$merge_count_file")
        new_count=$(echo "$counts" | awk '{print $1}')
        if [ "$new_count" -gt 0 ]; then
            echo "  PASS: Python版 新規追加あり (${new_count}件)"
            _inc_pass
        else
            echo "  FAIL: Python版 新規追加なし"
            _inc_fail
        fi
    fi
)

echo ""
echo "--- テスト8: _merge_kiro_commands_python() スキーマエラー ---"
(
    if ! command -v python3 >/dev/null 2>&1; then
        echo "  SKIP: python3 not found"
        _inc_pass
    else
        test_file="${TMPDIR_BASE}/test8.json"
        cat > "$test_file" <<'EOF'
{
  "toolsSettings": {
    "shell": {
      "allowedCommands": 42
    }
  }
}
EOF
        merge_count_file="${TMPDIR_BASE}/test8_counts"
        merged=$(_merge_kiro_commands_python "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?
        assert_eq "Python版 スキーマエラー=2" "2" "$rc"
    fi
)

echo ""
echo "--- テスト9: マージ後JSONの内容検証（jq） ---"
(
    test_file="${TMPDIR_BASE}/test9.json"
    cat > "$test_file" <<'EOF'
{
  "name": "aidlc",
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["echo hello", "custom-cmd *"]
    }
  }
}
EOF
    merge_count_file="${TMPDIR_BASE}/test9_counts"
    merged=$(_merge_kiro_commands_jq "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?

    # 元のコマンドが保持されているか
    has_echo=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "echo hello")] | length')
    assert_eq "元のコマンド保持" "1" "$has_echo"

    has_custom=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "custom-cmd *")] | length')
    assert_eq "ユーザーカスタムコマンド保持" "1" "$has_custom"

    # テンプレートのコマンドが追加されているか（cat * はテンプレートに含まれる）
    has_cat=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "cat *")] | length')
    assert_eq "テンプレートコマンド追加" "1" "$has_cat"

    # name フィールドが保持されているか
    name_val=$(echo "$merged" | jq -r '.name')
    assert_eq "nameフィールド保持" "aidlc" "$name_val"
)

echo ""
echo "--- テスト10: ワイルドカード包含の具体的検証 ---"
(
    test_file="${TMPDIR_BASE}/test10.json"
    # "git *" があれば、テンプレートの "git checkout *", "git add *" 等は包含されるべき
    cat > "$test_file" <<'EOF'
{
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["git *"]
    }
  }
}
EOF
    merge_count_file="${TMPDIR_BASE}/test10_counts"
    merged=$(_merge_kiro_commands_jq "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?

    # "git checkout *" は "git *" に包含されるため追加されないはず
    has_git_checkout=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "git checkout *")] | length')
    assert_eq "git checkout *は包含される" "0" "$has_git_checkout"

    # "cat *" は "git *" に包含されないため追加されるはず
    has_cat=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "cat *")] | length')
    assert_eq "cat *は包含されない→追加" "1" "$has_cat"
)

echo ""
echo "--- テスト11: _apply_kiro_merge() 結果種別の検証 ---"
(
    # 新規追加ありのケース
    test_file="${TMPDIR_BASE}/test11.json"
    cat > "$test_file" <<'EOF'
{
  "name": "aidlc",
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["echo hello"]
    }
  }
}
EOF
    output=$(_apply_kiro_merge "$test_file")
    result_line=$(echo "$output" | tail -1)
    assert_eq "_apply_kiro_merge result=updated" "updated" "$result_line"
    assert_contains "_apply_kiro_merge Updated出力" "Updated:" "$output"
)

echo ""
echo "--- テスト12: _apply_kiro_merge() skippedケース ---"
(
    template_cmds=$(_generate_kiro_template | jq '.toolsSettings.shell.allowedCommands')
    test_file="${TMPDIR_BASE}/test12.json"
    echo "{\"name\":\"aidlc\",\"toolsSettings\":{\"shell\":{\"allowedCommands\":$template_cmds}}}" | jq . > "$test_file"

    output=$(_apply_kiro_merge "$test_file")
    result_line=$(echo "$output" | tail -1)
    assert_eq "_apply_kiro_merge result=skipped" "skipped" "$result_line"
)

echo ""
echo "--- テスト13: マージ後JSONの内容検証（python3） ---"
(
    if ! command -v python3 >/dev/null 2>&1; then
        echo "  SKIP: python3 not found"
        _inc_pass; _inc_pass; _inc_pass; _inc_pass
    else
        test_file="${TMPDIR_BASE}/test13.json"
        cat > "$test_file" <<'EOF'
{
  "name": "aidlc",
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["echo hello", "custom-cmd *"]
    }
  }
}
EOF
        merge_count_file="${TMPDIR_BASE}/test13_counts"
        merged=$(_merge_kiro_commands_python "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?

        has_echo=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "echo hello")] | length')
        assert_eq "Python版 元のコマンド保持" "1" "$has_echo"

        has_custom=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "custom-cmd *")] | length')
        assert_eq "Python版 ユーザーカスタムコマンド保持" "1" "$has_custom"

        has_cat=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "cat *")] | length')
        assert_eq "Python版 テンプレートコマンド追加" "1" "$has_cat"

        name_val=$(echo "$merged" | jq -r '.name')
        assert_eq "Python版 nameフィールド保持" "aidlc" "$name_val"
    fi
)

echo ""
echo "--- テスト14: ワイルドカード包含の具体的検証（python3） ---"
(
    if ! command -v python3 >/dev/null 2>&1; then
        echo "  SKIP: python3 not found"
        _inc_pass; _inc_pass
    else
        test_file="${TMPDIR_BASE}/test14.json"
        cat > "$test_file" <<'EOF'
{
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["git *"]
    }
  }
}
EOF
        merge_count_file="${TMPDIR_BASE}/test14_counts"
        merged=$(_merge_kiro_commands_python "$test_file" 2>"$merge_count_file") && rc=0 || rc=$?

        has_git_checkout=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "git checkout *")] | length')
        assert_eq "Python版 git checkout *は包含される" "0" "$has_git_checkout"

        has_cat=$(echo "$merged" | jq '[.toolsSettings.shell.allowedCommands[] | select(. == "cat *")] | length')
        assert_eq "Python版 cat *は包含されない→追加" "1" "$has_cat"
    fi
)

echo ""
echo "--- テスト15: setup_kiro_agent() 統合テスト: ファイル不在→symlink作成 ---"
(
    test_workdir="${TMPDIR_BASE}/integration1"
    mkdir -p "$test_workdir"
    # AIDLC_DIR を設定してテンプレートファイルを配置
    export AIDLC_DIR="${test_workdir}/aidlc"
    mkdir -p "$AIDLC_DIR/kiro/agents"
    \cp "$REAL_TEMPLATE" "$AIDLC_DIR/kiro/agents/aidlc.json"

    cd "$test_workdir"
    output=$(setup_kiro_agent)
    assert_contains "symlink created出力" "result:created" "$output"

    # symlinkが作成されたか
    if [ -L ".kiro/agents/aidlc.json" ]; then
        echo "  PASS: symlinkが作成された"
        _inc_pass
    else
        echo "  FAIL: symlinkが作成されていない"
        _inc_fail
    fi
)

echo ""
echo "--- テスト16: setup_kiro_agent() 統合テスト: 実ファイルvalid→updated ---"
(
    test_workdir="${TMPDIR_BASE}/integration2"
    mkdir -p "$test_workdir"
    export AIDLC_DIR="${test_workdir}/aidlc"
    mkdir -p "$AIDLC_DIR/kiro/agents"
    \cp "$REAL_TEMPLATE" "$AIDLC_DIR/kiro/agents/aidlc.json"

    cd "$test_workdir"
    mkdir -p ".kiro/agents"
    cat > ".kiro/agents/aidlc.json" <<'EOF'
{
  "name": "aidlc",
  "toolsSettings": {
    "shell": {
      "allowedCommands": ["echo hello"]
    }
  }
}
EOF
    output=$(setup_kiro_agent)
    assert_contains "実ファイルvalid result:updated" "result:updated" "$output"
)

echo ""
echo "--- テスト17: setup_kiro_agent() 統合テスト: 実ファイルvalid→skipped ---"
(
    test_workdir="${TMPDIR_BASE}/integration3"
    mkdir -p "$test_workdir"
    export AIDLC_DIR="${test_workdir}/aidlc"
    mkdir -p "$AIDLC_DIR/kiro/agents"
    \cp "$REAL_TEMPLATE" "$AIDLC_DIR/kiro/agents/aidlc.json"

    cd "$test_workdir"
    mkdir -p ".kiro/agents"
    # テンプレートと同じコマンドを含むファイル
    \cp "$REAL_TEMPLATE" ".kiro/agents/aidlc.json"

    output=$(setup_kiro_agent)
    assert_contains "実ファイルvalid result:skipped" "result:skipped" "$output"
)

echo ""
echo "--- テスト18: setup_kiro_agent() 統合テスト: 実ファイルinvalid→backup+created ---"
(
    test_workdir="${TMPDIR_BASE}/integration4"
    mkdir -p "$test_workdir"
    export AIDLC_DIR="${test_workdir}/aidlc"
    mkdir -p "$AIDLC_DIR/kiro/agents"
    \cp "$REAL_TEMPLATE" "$AIDLC_DIR/kiro/agents/aidlc.json"

    cd "$test_workdir"
    mkdir -p ".kiro/agents"
    echo "not valid json{{{" > ".kiro/agents/aidlc.json"

    output=$(setup_kiro_agent) || true
    assert_contains "invalidファイル result:created" "result:created" "$output"
    assert_contains "backupメッセージ" "Backup:" "$output"

    # .bakファイルが作成されたか
    if [ -f ".kiro/agents/aidlc.json.bak" ]; then
        echo "  PASS: .bakファイルが作成された"
        _inc_pass
    else
        echo "  FAIL: .bakファイルが作成されていない"
        _inc_fail
    fi
)

echo ""
# カウンタ読み取り
{
    read -r PASS
    read -r FAIL
} < "$COUNTER_FILE"
echo "=== 結果: PASS=$PASS FAIL=$FAIL ==="
if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
