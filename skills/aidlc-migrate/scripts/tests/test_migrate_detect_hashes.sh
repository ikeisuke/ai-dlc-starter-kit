#!/usr/bin/env bash
#
# test_migrate_detect_hashes.sh - migrate-detect.sh セクション6 ハッシュ比較テスト
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

echo "=== migrate-detect.sh セクション6 ハッシュ比較テスト ==="

# テスト用のプロジェクト構造を作成
_setup_project() {
    local project_dir="$TEST_DIR/project"
    rm -rf "$project_dir"
    mkdir -p "$project_dir/.aidlc" "$project_dir/.github/ISSUE_TEMPLATE"
    # 最低限のconfig.toml
    cat > "$project_dir/.aidlc/config.toml" << 'EOF'
starter_kit_version = "1.0.0"
[project]
name = "test"
EOF
    # gitリポジトリとして初期化
    git -C "$project_dir" init -q
    git -C "$project_dir" config user.name "test"
    git -C "$project_dir" config user.email "test@example.com"
    git -C "$project_dir" add -A
    git -C "$project_dir" commit -q -m "init" --allow-empty
    echo "$project_dir"
}

echo ""
echo "--- テスト1: ハッシュ一致時にaction=deleteになること ---"
project_dir=$(_setup_project)
# known-hashes.shのハッシュ値と一致するテンプレートを作成
# backlog.ymlの既知ハッシュに一致する内容を用意するため、実際のテンプレートをコピー
_tmpl_src="$(git rev-parse --show-toplevel 2>/dev/null)"
if [[ -f "$_tmpl_src/.github/ISSUE_TEMPLATE/backlog.yml" ]]; then
    cp "$_tmpl_src/.github/ISSUE_TEMPLATE/backlog.yml" "$project_dir/.github/ISSUE_TEMPLATE/backlog.yml"
    output=$(cd "$project_dir" && AIDLC_PROJECT_ROOT="$project_dir" bash "${SCRIPT_DIR}/../migrate-detect.sh" 2>/dev/null) || true
    # backlog.ymlがaction=deleteになっていることを確認
    assert_json "ハッシュ一致→action=delete" "$output" \
        '.resources[] | select(.path == ".github/ISSUE_TEMPLATE/backlog.yml") | .action' "delete"
    assert_json "ハッシュ一致→is_owned=true" "$output" \
        '.resources[] | select(.path == ".github/ISSUE_TEMPLATE/backlog.yml") | .ownership_evidence.is_owned' "true"
    assert_json "ハッシュ一致→method=hash_comparison" "$output" \
        '.resources[] | select(.path == ".github/ISSUE_TEMPLATE/backlog.yml") | .ownership_evidence.method' "hash_comparison"
else
    echo "  SKIP: テスト1 (テンプレートファイルが見つかりません)"
fi

echo ""
echo "--- テスト2: ハッシュ不一致時にaction=confirm_deleteになること ---"
project_dir=$(_setup_project)
echo "modified content" > "$project_dir/.github/ISSUE_TEMPLATE/backlog.yml"
output=$(cd "$project_dir" && AIDLC_PROJECT_ROOT="$project_dir" bash "${SCRIPT_DIR}/../migrate-detect.sh" 2>/dev/null) || true
assert_json "ハッシュ不一致→action=confirm_delete" "$output" \
    '.resources[] | select(.path == ".github/ISSUE_TEMPLATE/backlog.yml") | .action' "confirm_delete"
assert_json "ハッシュ不一致→is_owned=false" "$output" \
    '.resources[] | select(.path == ".github/ISSUE_TEMPLATE/backlog.yml") | .ownership_evidence.is_owned' "false"
assert_json "ハッシュ不一致→method=hash_comparison" "$output" \
    '.resources[] | select(.path == ".github/ISSUE_TEMPLATE/backlog.yml") | .ownership_evidence.method' "hash_comparison"

echo ""
echo "--- テスト3: テンプレートが存在しない場合はリソースに含まれないこと ---"
project_dir=$(_setup_project)
# テンプレートファイルを作成しない
output=$(cd "$project_dir" && AIDLC_PROJECT_ROOT="$project_dir" bash "${SCRIPT_DIR}/../migrate-detect.sh" 2>/dev/null) || true
tmpl_count=$(echo "$output" | jq '[.resources[] | select(.resource_type == "issue_template")] | length' 2>/dev/null) || tmpl_count="JQ_ERROR"
if [[ "$tmpl_count" == "0" ]]; then
    echo "  PASS: テンプレート未存在→リソースなし"
    ((++PASS))
else
    echo "  FAIL: テンプレート未存在→リソースなし (count=$tmpl_count)"
    ((++FAIL))
fi

echo ""
echo "=== 結果: PASS=$PASS, FAIL=$FAIL ==="
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
