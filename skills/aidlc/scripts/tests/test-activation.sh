#!/usr/bin/env bash
#
# test-activation.sh - aidlc（v3 本流）起動有効化（marketplace.json 登録）の構造検証
#
# /aidlc の実起動（対話セッション）はテスト不能なため、起動「可能性」を構造的に検証する:
#   (1) marketplace.json が有効な JSON で ./skills/aidlc を含み、旧 ./skills/aidlc-v3 エントリが残っていない
#   (2) 起動に必要なファイル（SKILL.md / steps / 参照スクリプト）が存在
#   (3) SKILL.md の注記が実態同期済み（stale 注記が残っていない）
#
# 外部テストフレームワークに依存しない自己完結型ハーネス（jq のみ前提）。
#
# Usage: test-activation.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（jq 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# tests → scripts → aidlc → skills → リポジトリルート（4 階層上）。
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"   # skills/aidlc/scripts
V3_DIR="$(cd "$SKILL_DIR/.." && pwd)"       # skills/aidlc
readonly SCRIPT_DIR REPO_ROOT SKILL_DIR V3_DIR
readonly MARKETPLACE="$REPO_ROOT/.claude-plugin/marketplace.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not found (前提不備)" >&2
    exit 2
fi

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ok   : $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL : $1"; }

echo "== 静的検査（bash -n / shellcheck） =="
if bash -n "$SCRIPT_DIR/test-activation.sh" 2>/dev/null; then
    pass "bash -n: test-activation.sh"
else
    fail "bash -n: test-activation.sh"
fi
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck "$SCRIPT_DIR/test-activation.sh" >/dev/null 2>&1; then
        pass "shellcheck: test-activation.sh（重大警告なし）"
    else
        fail "shellcheck: test-activation.sh"
    fi
else
    echo "  skip : shellcheck 未導入のため静的検査をスキップ"
fi

echo "== marketplace.json =="
if jq empty "$MARKETPLACE" >/dev/null 2>&1; then
    pass "marketplace.json は有効な JSON"
else
    fail "marketplace.json が有効な JSON でない"
fi
# v3 本流登録（起動有効化）
if jq -e '.plugins[0].skills | index("./skills/aidlc")' "$MARKETPLACE" >/dev/null 2>&1; then
    pass "plugins[0].skills に ./skills/aidlc を含む（起動有効化）"
else
    fail "plugins[0].skills に ./skills/aidlc が登録されていない"
fi
# 旧エントリの残存なし（本流化完了）
if jq -e '.plugins[0].skills | index("./skills/aidlc-v3")' "$MARKETPLACE" >/dev/null 2>&1; then
    fail "plugins[0].skills に旧 ./skills/aidlc-v3 が残存している（本流化未完了）"
else
    pass "plugins[0].skills に旧 ./skills/aidlc-v3 の残存なし"
fi
# SKILL.md frontmatter name が aidlc であること（/aidlc 起動面）
if grep -qE '^name: aidlc$' "$V3_DIR/SKILL.md"; then
    pass "SKILL.md frontmatter name: aidlc（/aidlc 起動面）"
else
    fail "SKILL.md frontmatter name が aidlc でない"
fi

echo "== 起動必須ファイルの存在 =="
# 起動エントリポイント + define/develop/status 手順ファイル
required_docs=(
    "$V3_DIR/SKILL.md"
    "$V3_DIR/steps/define.md"
    "$V3_DIR/steps/develop.md"
    "$V3_DIR/steps/status.md"
)
for f in "${required_docs[@]}"; do
    if [[ -f "$f" ]]; then
        pass "存在: ${f#"$REPO_ROOT"/}"
    else
        fail "不在: ${f#"$REPO_ROOT"/}"
    fi
done
# define/develop/status が参照する主要スクリプト（define は state-init.sh / work-item-validate.sh も参照）
required_scripts=(
    "state-init.sh"
    "state-validate.sh"
    "state-write.sh"
    "state-read.sh"
    "work-item-validate.sh"
    "work-item-next.sh"
    "work-item-status.sh"
)
for s in "${required_scripts[@]}"; do
    if [[ -f "$SKILL_DIR/$s" ]]; then
        pass "存在: skills/aidlc/scripts/$s"
    else
        fail "不在: skills/aidlc/scripts/$s"
    fi
done

echo "== 本流化完了の構造確認 =="
# 旧ディレクトリが存在しないこと
if [[ -d "$REPO_ROOT/skills/aidlc-v3" ]]; then
    fail "skills/aidlc-v3 ディレクトリが残存している（本流化未完了）"
else
    pass "skills/aidlc-v3 ディレクトリの残存なし"
fi

echo "== SKILL.md 注記の実態同期 =="
# 本流化後に stale となる注記が残っていないことを確認する。
stale_patterns=(
    "本 Unit で作成"
    "Unit 005 で行う"
    "v3.0.0-alpha.2 / Phase 2"
    "現時点の起動表面は \`/aidlc-v3\`"
    "skeleton"
)
for p in "${stale_patterns[@]}"; do
    if grep -qF "$p" "$V3_DIR/SKILL.md"; then
        fail "stale 注記が残存: '$p'"
    else
        pass "stale 注記なし: '$p'"
    fi
done

echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
