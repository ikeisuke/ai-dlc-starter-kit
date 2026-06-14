#!/usr/bin/env bash
#
# test-activation.sh - aidlc-v3 起動有効化（Unit 005 / marketplace.json 登録）の構造検証
#
# /aidlc-v3 の実起動（対話セッション）はテスト不能なため、起動「可能性」を構造的に検証する:
#   (1) marketplace.json が有効な JSON で ./skills/aidlc-v3 を含み、v2（./skills/aidlc）と共存
#   (2) 起動に必要なファイル（SKILL.md / steps / 参照スクリプト）が存在
#   (3) SKILL.md の skeleton 注記が実態同期済み（stale 注記が残っていない）
#
# 外部テストフレームワークに依存しない自己完結型ハーネス（jq のみ前提）。
#
# Usage: test-activation.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（jq 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# tests → scripts → aidlc-v3 → skills → リポジトリルート（4 階層上）。
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"   # skills/aidlc-v3/scripts
V3_DIR="$(cd "$SKILL_DIR/.." && pwd)"       # skills/aidlc-v3
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
# v3 登録（起動有効化）
if jq -e '.plugins[0].skills | index("./skills/aidlc-v3")' "$MARKETPLACE" >/dev/null 2>&1; then
    pass "plugins[0].skills に ./skills/aidlc-v3 を含む（起動有効化）"
else
    fail "plugins[0].skills に ./skills/aidlc-v3 が登録されていない"
fi
# v2 共存（非後退）
if jq -e '.plugins[0].skills | index("./skills/aidlc")' "$MARKETPLACE" >/dev/null 2>&1; then
    pass "plugins[0].skills に ./skills/aidlc を含む（v2 共存 / 非後退）"
else
    fail "plugins[0].skills から ./skills/aidlc が失われた（v2 共存破綻）"
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
        pass "存在: skills/aidlc-v3/scripts/$s"
    else
        fail "不在: skills/aidlc-v3/scripts/$s"
    fi
done

echo "== SKILL.md skeleton 注記の実態同期 =="
# activation 後に stale となる 3 種が残っていないことを確認する。
stale_patterns=(
    "本 Unit で作成"
    "Unit 005 で行う"
    "v3.0.0-alpha.2 / Phase 2"
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
