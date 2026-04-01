#!/usr/bin/env bash
#
# test_migrate_version_update.sh - migrate-verify.sh starter_kit_version検証テスト
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0
FAIL=0

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT

assert_json() {
    local test_name="$1"
    local json="$2"
    local jq_expr="$3"
    local expected="$4"
    local actual
    actual=$(echo "$json" | jq -r "$jq_expr" 2>/dev/null) || actual="JQ_ERROR"
    if [[ "$expected" == "$actual" ]]; then
        echo "  PASS: $test_name"
        ((++PASS))
    else
        echo "  FAIL: $test_name (expected='$expected', actual='$actual')"
        ((++FAIL))
    fi
}

echo "=== migrate-verify.sh starter_kit_version検証テスト ==="

_setup_project() {
    local project_dir="$TEST_DIR/project_$$_$RANDOM"
    mkdir -p "$project_dir/.aidlc"
    cat > "$project_dir/.aidlc/config.toml" << 'EOF'
starter_kit_version = "2.1.0"
[project]
name = "test"
EOF
    echo "2.1.0" > "$project_dir/version.txt"
    # 空のmanifest
    echo '{"resources": []}' > "$project_dir/manifest.json"
    git -C "$project_dir" init -q
    git -C "$project_dir" config user.name "test"
    git -C "$project_dir" config user.email "test@example.com"
    git -C "$project_dir" add -A
    git -C "$project_dir" commit -q -m "init" --allow-empty
    echo "$project_dir"
}

echo ""
echo "--- テスト1: version一致でjournal指定時にok ---"
project_dir=$(_setup_project)
# journalにsuccess + expected_version
cat > "$project_dir/journal.json" << 'EOF'
{"phase": "config", "applied": [{"resource_type": "version_update", "path": ".aidlc/config.toml", "status": "success", "detail": "updated", "expected_version": "2.1.0"}]}
EOF
output=$(cd "$project_dir" && AIDLC_PROJECT_ROOT="$project_dir" bash "${SCRIPT_DIR}/../migrate-verify.sh" --manifest "$project_dir/manifest.json" --journal "$project_dir/journal.json" 2>/dev/null) || true
assert_json "version一致→ok" "$output" \
    '.checks[] | select(.name == "starter_kit_version_updated") | .status' "ok"

echo ""
echo "--- テスト2: version不一致でfail ---"
project_dir=$(_setup_project)
# config.tomlのversionを古い値に
cat > "$project_dir/.aidlc/config.toml" << 'EOF'
starter_kit_version = "1.0.0"
[project]
name = "test"
EOF
cat > "$project_dir/journal.json" << 'EOF'
{"phase": "config", "applied": [{"resource_type": "version_update", "path": ".aidlc/config.toml", "status": "success", "detail": "updated", "expected_version": "2.1.0"}]}
EOF
output=$(cd "$project_dir" && AIDLC_PROJECT_ROOT="$project_dir" bash "${SCRIPT_DIR}/../migrate-verify.sh" --manifest "$project_dir/manifest.json" --journal "$project_dir/journal.json" 2>/dev/null) || true
assert_json "version不一致→fail" "$output" \
    '.checks[] | select(.name == "starter_kit_version_updated") | .status' "fail"

echo ""
echo "--- テスト3: journal status=skipped(canonical_version_unavailable)時にok ---"
project_dir=$(_setup_project)
cat > "$project_dir/journal.json" << 'EOF'
{"phase": "config", "applied": [{"resource_type": "version_update", "path": ".aidlc/config.toml", "status": "skipped", "detail": "version.txt not found", "reason_code": "canonical_version_unavailable"}]}
EOF
output=$(cd "$project_dir" && AIDLC_PROJECT_ROOT="$project_dir" bash "${SCRIPT_DIR}/../migrate-verify.sh" --manifest "$project_dir/manifest.json" --journal "$project_dir/journal.json" 2>/dev/null) || true
assert_json "skipped(canonical_version_unavailable)→ok" "$output" \
    '.checks[] | select(.name == "starter_kit_version_updated") | .status' "ok"

echo ""
echo "--- テスト3b: journal status=skipped(config_migration_failed)時にfail ---"
project_dir=$(_setup_project)
cat > "$project_dir/journal.json" << 'EOF'
{"phase": "config", "applied": [{"resource_type": "version_update", "path": ".aidlc/config.toml", "status": "skipped", "detail": "config migration failed", "reason_code": "config_migration_failed"}]}
EOF
output=$(cd "$project_dir" && AIDLC_PROJECT_ROOT="$project_dir" bash "${SCRIPT_DIR}/../migrate-verify.sh" --manifest "$project_dir/manifest.json" --journal "$project_dir/journal.json" 2>/dev/null) || true
assert_json "skipped(config_migration_failed)→fail" "$output" \
    '.checks[] | select(.name == "starter_kit_version_updated") | .status' "fail"

echo ""
echo "--- テスト4: journal status=error時にfail ---"
project_dir=$(_setup_project)
cat > "$project_dir/journal.json" << 'EOF'
{"phase": "config", "applied": [{"resource_type": "version_update", "path": ".aidlc/config.toml", "status": "error", "detail": "dasel not found", "reason_code": "dasel_not_found"}]}
EOF
output=$(cd "$project_dir" && AIDLC_PROJECT_ROOT="$project_dir" bash "${SCRIPT_DIR}/../migrate-verify.sh" --manifest "$project_dir/manifest.json" --journal "$project_dir/journal.json" 2>/dev/null) || true
assert_json "error→fail" "$output" \
    '.checks[] | select(.name == "starter_kit_version_updated") | .status' "fail"

echo ""
echo "--- テスト5: journal未指定時にversion.txtからフォールバック ---"
project_dir=$(_setup_project)
output=$(cd "$project_dir" && AIDLC_PROJECT_ROOT="$project_dir" bash "${SCRIPT_DIR}/../migrate-verify.sh" --manifest "$project_dir/manifest.json" 2>/dev/null) || true
assert_json "journal未指定→version.txtフォールバック→ok" "$output" \
    '.checks[] | select(.name == "starter_kit_version_updated") | .status' "ok"

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
