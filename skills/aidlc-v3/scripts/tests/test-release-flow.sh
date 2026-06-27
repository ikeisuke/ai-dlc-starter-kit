#!/usr/bin/env bash
#
# test-release-flow.sh - release フロー（Step 1-4）の構造・契約の静的検証
#
# release の実 PR 操作（gh / merge）はテスト不能なため、release.md / templates/release.md /
# SKILL.md の構造・契約を静的に検証する（ネットワーク非依存 / 実 gh・merge を行わない）:
#   (1) steps/release.md が存在し Step 1-4 の見出しを持つ
#   (2) release.md が依存スクリプト契約・merge ゲート要素を参照する
#   (3) review ルーティング / post-merge は SoT 参照 + キーワードのスモーク検証
#   (4) templates/release.md の review 結果サマリ固定マーカーを perspective 単位で構造検証
#       （Unit 002->003 契約 / jq は YAML 非対応のため parse せず構造検証）
#   (5) SKILL.md の release が steps/release.md を指し、release flip 後の stale 注記が残らない
#
# 外部テストフレームワークに依存しない自己完結型ハーネス（jq のみ前提 / 既存テストと同方式）。
#
# Usage: test-release-flow.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（jq 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"   # skills/aidlc-v3/scripts
V3_DIR="$(cd "$SKILL_DIR/.." && pwd)"       # skills/aidlc-v3
readonly SCRIPT_DIR SKILL_DIR V3_DIR
readonly RELEASE_MD="$V3_DIR/steps/release.md"
readonly RELEASE_TMPL="$V3_DIR/templates/release.md"
readonly SKILL_MD="$V3_DIR/SKILL.md"

# 既存ハーネス（test-activation.sh）と同様に jq を前提とする（未導入は前提不備で SKIP）。
if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not found (前提不備)" >&2
    exit 2
fi

PASS=0
FAIL=0
pass() { PASS=$((PASS + 1)); echo "  ok   : $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  FAIL : $1"; }

# grep_q <file> <fixed-string> : 固定文字列の存在確認（移植性のため -F / -q）
grep_q() { grep -qF -- "$2" "$1"; }

echo "== 静的検査（bash -n / shellcheck） =="
if bash -n "$SCRIPT_DIR/test-release-flow.sh" 2>/dev/null; then
    pass "bash -n: test-release-flow.sh"
else
    fail "bash -n: test-release-flow.sh"
fi
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck "$SCRIPT_DIR/test-release-flow.sh" >/dev/null 2>&1; then
        pass "shellcheck: test-release-flow.sh（重大警告なし）"
    else
        fail "shellcheck: test-release-flow.sh"
    fi
else
    echo "  skip : shellcheck 未導入のため静的検査をスキップ"
fi

echo "== 成果物の存在 =="
for f in "$RELEASE_MD" "$RELEASE_TMPL" "$SKILL_MD"; do
    if [[ -f "$f" ]]; then
        pass "存在: ${f#"$V3_DIR"/}"
    else
        fail "不在: ${f#"$V3_DIR"/}"
    fi
done

echo "== steps/release.md: Step 1-4 見出し =="
for s in "## Step 1: リリース準備" "## Step 2: PR 整備" "## Step 3: Merge 承認 + 実行" "## Step 4: Post-merge"; do
    if grep_q "$RELEASE_MD" "$s"; then
        pass "見出し: $s"
    else
        fail "見出し欠落: $s"
    fi
done

echo "== steps/release.md: 依存スクリプト契約 =="
for c in \
    "state-read.sh" \
    "state-write.sh release.pr_number" \
    "state-write.sh release.ready" \
    "state-write.sh release.merge_approved" \
    "work-item-validate.sh" \
    "work-item-status.sh --read"; do
    if grep_q "$RELEASE_MD" "$c"; then
        pass "依存契約参照: $c"
    else
        fail "依存契約参照欠落: $c"
    fi
done

echo "== steps/release.md: merge ゲート要素 =="
for g in "merge_blocker_any" "--match-head-commit" "gh pr checks <N> --required"; do
    if grep_q "$RELEASE_MD" "$g"; then
        pass "merge ゲート要素: $g"
    else
        fail "merge ゲート要素欠落: $g"
    fi
done

echo "== steps/release.md: review ルーティング / post-merge スモーク（SoT 参照 + 語彙）=="
# 条件文の完全一致ではなく SoT 参照 + perspective 名 + 主要語彙の存在を確認（厳密な条件は docs に閉じる）。
for k in \
    "docs/v3/workflow.md" \
    "docs/v3/data-model.md" \
    "premerge" "integration" "deploy" \
    "version_tag" "changelog" "merge commit" "journal"; do
    if grep_q "$RELEASE_MD" "$k"; then
        pass "スモーク語彙: $k"
    else
        fail "スモーク語彙欠落: $k"
    fi
done

echo "== steps/release.md: 契約条件の核となる固定文字列 =="
# 語彙の存在だけでなく、ルーティング/opt-in 契約の核となる文字列が release.md に記述されていること
# （条件式が壊れた場合に検出する。条件の正本は release.md / docs に閉じ、本テストは記述の存在を確認する）。
for c in \
    "status:done" \
    "2 件以上" \
    "size:risky" \
    "常時" \
    "正常完了" \
    "統合先" \
    "必須成果物" \
    "PR に含める"; do
    if grep_q "$RELEASE_MD" "$c"; then
        pass "契約文字列: $c"
    else
        fail "契約文字列欠落: $c"
    fi
done

echo "== templates/release.md: review サマリ固定マーカーの perspective 単位構造検証 =="
start_count="$(grep -cF "<!-- aidlc-release-review:start -->" "$RELEASE_TMPL")"
end_count="$(grep -cF "<!-- aidlc-release-review:end -->" "$RELEASE_TMPL")"
if [[ "$start_count" == "1" && "$end_count" == "1" ]]; then
    pass "マーカー start/end が各 1 回"
else
    fail "マーカー start/end が各 1 回でない（start=$start_count end=${end_count}）"
fi

# マーカー間（start の次行〜end の前行）を抽出（純 YAML 契約区間）。
block="$(awk '
    /<!-- aidlc-release-review:start -->/ { inblk=1; next }
    /<!-- aidlc-release-review:end -->/   { inblk=0 }
    inblk == 1 { print }
' "$RELEASE_TMPL")"

if [[ -n "$block" ]]; then
    pass "マーカー間ブロックを抽出できた"
else
    fail "マーカー間ブロックが空"
fi

# マーカー間にコードフェンス / Markdown 見出しがない（純 YAML 契約 / parse はしない）。
if printf '%s\n' "$block" | grep -qE '^[[:space:]]*```'; then
    fail "マーカー間にコードフェンスがある（純 YAML 契約違反）"
else
    pass "マーカー間にコードフェンスなし"
fi
if printf '%s\n' "$block" | grep -qE '^[[:space:]]*#'; then
    fail "マーカー間に Markdown 見出しがある（純 YAML 契約違反）"
else
    pass "マーカー間に Markdown 見出しなし"
fi

# perspective が premerge/integration/deploy で各 1 回（接頭辞衝突なしのため単純一致で可）。
persp_total="$(printf '%s\n' "$block" | grep -cE '^[[:space:]]*-[[:space:]]+perspective:')"
if [[ "$persp_total" -ge 1 ]]; then
    pass "perspective エントリが存在（$persp_total 件）"
else
    fail "perspective エントリがない"
fi
for p in premerge integration deploy; do
    pc="$(printf '%s\n' "$block" | grep -cE "perspective:[[:space:]]*${p}$")"
    if [[ "$pc" == "1" ]]; then
        pass "perspective $p が 1 回"
    else
        fail "perspective $p が 1 回でない（${pc}）"
    fi
done

# 各 perspective ブロックに 5 キーがあることを「キー出現数 == perspective 数」で検証
# （premerge だけに全キーがあり integration/deploy で欠落、を出現数の不足で検出する）。
for key in status unresolved_count max_severity merge_blocker skip_reason; do
    kc="$(printf '%s\n' "$block" | grep -cE "^[[:space:]]+${key}:")"
    if [[ "$kc" == "$persp_total" ]]; then
        pass "キー $key が各 perspective に存在（$kc == ${persp_total}）"
    else
        fail "キー $key の出現数が perspective 数と不一致（$kc != $persp_total / ブロック欠落の疑い）"
    fi
done

# merge_blocker_any は reviews リスト外（トップレベル / インデントなし）に 1 回。
mba_count="$(printf '%s\n' "$block" | grep -cE '^merge_blocker_any:')"
if [[ "$mba_count" == "1" ]]; then
    pass "merge_blocker_any が reviews 外に 1 回"
else
    fail "merge_blocker_any が reviews 外に 1 回でない（${mba_count}）"
fi

# schema_version と enum/boolean 文字列の存在（例ブロックは boolean が false のみのため true は必須にしない）。
for v in "schema_version:" "passed" "skipped" "false"; do
    if printf '%s\n' "$block" | grep -qF -- "$v"; then
        pass "マーカー間に文字列: $v"
    else
        fail "マーカー間に文字列欠落: $v"
    fi
done

echo "== SKILL.md: release ルーティング =="
# コマンド表の release 行を一意な非バッククォート文字列で特定する。
release_row="$(grep -F 'main に安全に取り込む' "$SKILL_MD")"
if printf '%s\n' "$release_row" | grep -qF "steps/release.md"; then
    pass "release 行が steps/release.md を指す"
else
    fail "release 行が steps/release.md を指していない"
fi
if printf '%s\n' "$release_row" | grep -qF "予約"; then
    fail "release 行に「予約」が残存"
else
    pass "release 行に「予約」なし"
fi

echo "== SKILL.md: stale 注記の回帰検出（Unit 004 後に残してはいけない） =="
# reflect / doctor の「予約」は実態として残るため対象外。
stale_patterns=(
    "v3.0.0-alpha.3 / Phase 3"
    "tiny フローのみ"
    "release / reflect / doctor は"
)
for p in "${stale_patterns[@]}"; do
    if grep_q "$SKILL_MD" "$p"; then
        fail "stale 注記が残存: '$p'"
    else
        pass "stale 注記なし: '$p'"
    fi
done

echo "== steps/release.md: 公開フリップ後に残してはいけない stale 記述 =="
# Step 2-4 がプレースホルダだった時代の語彙が残っていないこと（実行エージェントが
# 途中未実装と誤解する false negative を防ぐ）。
release_stale=(
    "骨格 + Step 1"
    "後続 Unit"
    "未実装"
)
for p in "${release_stale[@]}"; do
    if grep_q "$RELEASE_MD" "$p"; then
        fail "release.md に stale 記述が残存: '$p'"
    else
        pass "release.md に stale 記述なし: '$p'"
    fi
done

echo "== templates/release.md: 生成物に混入してはいけない Unit 履歴コメント =="
# テンプレートから生成される release.md に Unit 番号・「本 Unit」「枠のみ」等の履歴コメントが
# 混入しないこと（Phase 5 仕上げ後の生成物として不適切）。
tmpl_stale=(
    "本 Unit"
    "枠のみ"
    "Unit 002"
    "Unit 003"
)
for p in "${tmpl_stale[@]}"; do
    if grep_q "$RELEASE_TMPL" "$p"; then
        fail "templates/release.md に stale 履歴コメントが残存: '$p'"
    else
        pass "templates/release.md に stale 履歴コメントなし: '$p'"
    fi
done

echo "----------------------------------------"
echo "PASS: $PASS  FAIL: $FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
echo "All tests passed."
exit 0
