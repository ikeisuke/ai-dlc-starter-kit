#!/usr/bin/env bash
#
# test-reflect-flow.sh - reflect フロー（Step 0-4）の構造・契約の静的検証
#
# reflect の実行（gh issue create / 対話編集）はテスト不能なため、steps/reflect.md /
# templates/reflect.md / SKILL.md の構造・契約を静的に検証する（ネットワーク非依存）:
#   (1) steps/reflect.md が存在し Step 0-4 の見出しを持つ
#   (2) Step 0 complete 前提（release.merge_approved / release.pr_number / PR merged）を参照する
#   (3) Step 1 材料収集対象（journal.md / release.md / withdrawn・blocked）と work-item-status.sh --read 委譲
#   (4) Step 3 Try Issue 化の 3 分岐（承認しない / 一部承認 / gh 不可 skip）と gh issue create --body-file
#   (5) reflect が state を変更しないこと（state.json 非変更宣言 + scripts/state-write.sh 呼び出し不在）
#   (6) Step 4 journal 追記形式（## YYYY-MM-DD / reflect completed）
#   (7) core から外す 4 項目（workflow.md §3.4）の実装しない明示
#   (8) templates/reflect.md の章立て（Keep / Problem / Try / Issue リンク）
#   (9) SKILL.md の reflect が steps/reflect.md を指し、reflect の予約 stale が残らない /
#       retrospective エイリアス整合 / express に reflect を含めない
#
# 外部テストフレームワークに依存しない自己完結型ハーネス（jq のみ前提 / 既存テストと同方式）。
#
# Usage: test-reflect-flow.sh
# 終了コード: 0=全テスト成功 / 1=失敗あり / 2=前提不備（jq 未導入 等）
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"   # skills/aidlc-v3/scripts
V3_DIR="$(cd "$SKILL_DIR/.." && pwd)"       # skills/aidlc-v3
readonly SCRIPT_DIR SKILL_DIR V3_DIR
readonly REFLECT_MD="$V3_DIR/steps/reflect.md"
readonly REFLECT_TMPL="$V3_DIR/templates/reflect.md"
readonly SKILL_MD="$V3_DIR/SKILL.md"

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
if bash -n "$SCRIPT_DIR/test-reflect-flow.sh" 2>/dev/null; then
    pass "bash -n: test-reflect-flow.sh"
else
    fail "bash -n: test-reflect-flow.sh"
fi
if command -v shellcheck >/dev/null 2>&1; then
    if shellcheck "$SCRIPT_DIR/test-reflect-flow.sh" >/dev/null 2>&1; then
        pass "shellcheck: test-reflect-flow.sh（重大警告なし）"
    else
        fail "shellcheck: test-reflect-flow.sh"
    fi
else
    echo "  skip : shellcheck 未導入のため静的検査をスキップ"
fi

echo "== 成果物の存在 =="
for f in "$REFLECT_MD" "$REFLECT_TMPL" "$SKILL_MD"; do
    if [[ -f "$f" ]]; then
        pass "存在: ${f#"$V3_DIR"/}"
    else
        fail "不在: ${f#"$V3_DIR"/}"
    fi
done

echo "== steps/reflect.md: Step 0-4 見出し =="
for s in \
    "## Step 0: 前提確認" \
    "## Step 1: 材料収集" \
    "## Step 2: KPT 抽出" \
    "## Step 3: 行動化" \
    "## Step 4: 完了"; do
    if grep_q "$REFLECT_MD" "$s"; then
        pass "見出し: $s"
    else
        fail "見出し欠落: $s"
    fi
done

echo "== steps/reflect.md: Step 0 complete 前提 =="
for c in \
    "scripts/state-read.sh current_cycle" \
    "release.merge_approved" \
    "release.pr_number" \
    "state == MERGED"; do
    if grep_q "$REFLECT_MD" "$c"; then
        pass "complete 前提参照: $c"
    else
        fail "complete 前提参照欠落: $c"
    fi
done

echo "== steps/reflect.md: Step 1 材料収集対象 + 安全境界委譲 =="
for c in \
    "journal.md" \
    "release.md" \
    "withdrawn" \
    "blocked" \
    "scripts/work-item-status.sh --read"; do
    if grep_q "$REFLECT_MD" "$c"; then
        pass "材料収集参照: $c"
    else
        fail "材料収集参照欠落: $c"
    fi
done
# release.md 不在は停止（必須成果物 / 空扱いしない）
if grep_q "$REFLECT_MD" "不在は不整合として停止"; then
    pass "release.md 不在停止契約"
else
    fail "release.md 不在停止契約欠落"
fi
# 理由は非構造抽出 + unknown フォールバック
if grep_q "$REFLECT_MD" "unknown"; then
    pass "理由 unknown フォールバック"
else
    fail "理由 unknown フォールバック欠落"
fi

echo "== steps/reflect.md: Step 3 Try Issue 化の 3 分岐 =="
if grep_q "$REFLECT_MD" "承認しない場合"; then
    pass "分岐: 承認しない→作らない"
else
    fail "分岐欠落: 承認しない"
fi
if grep_q "$REFLECT_MD" "一部のみ承認"; then
    pass "分岐: 一部のみ承認→必要分"
else
    fail "分岐欠落: 一部のみ承認"
fi
if grep_q "$REFLECT_MD" "Issue 化を skip"; then
    pass "分岐: gh 不可→skip + reflect.md 継続"
else
    fail "分岐欠落: gh 不可 skip"
fi
if grep_q "$REFLECT_MD" "gh issue create --body-file"; then
    pass "Issue 起票: gh issue create --body-file（file-based）"
else
    fail "Issue 起票契約欠落: gh issue create --body-file"
fi
# 必須ラベル検証は導入しない
if grep_q "$REFLECT_MD" "必須ラベル検証は行わない"; then
    pass "ラベル検証非導入の明示"
else
    fail "ラベル検証非導入の明示欠落"
fi

echo "== steps/reflect.md: state 非変更 =="
if grep_q "$REFLECT_MD" "を一切変更しない"; then
    pass "state 非変更の宣言"
else
    fail "state 非変更の宣言欠落"
fi
# コマンド位置（行頭の任意空白の後）に state-write.sh が現れないこと。
# 否定文中の `state-write.sh`（mid-sentence / backtick 囲み）は許容し、コードブロックや
# 行頭コマンドとしての呼び出し（`scripts/state-write.sh ...` / `state-write.sh ...`）のみ検出する。
if grep -qE '^[[:space:]]*(scripts/)?state-write\.sh' "$REFLECT_MD"; then
    fail "state-write.sh のコマンド呼び出しが存在する（reflect は state 非変更のはず）"
else
    pass "state-write.sh のコマンド呼び出し不在（状態を進行させない）"
fi

echo "== steps/reflect.md: Step 4 journal 追記形式 =="
if grep_q "$REFLECT_MD" "## YYYY-MM-DD"; then
    pass "journal 日付見出し形式"
else
    fail "journal 日付見出し形式欠落"
fi
if grep_q "$REFLECT_MD" "reflect completed: <cycle>"; then
    pass "journal 追記文言"
else
    fail "journal 追記文言欠落"
fi

echo "== steps/reflect.md: core から外す 4 項目（workflow.md §3.4） =="
for c in \
    "upstream mirror" \
    "cap 管理" \
    "dialog token" \
    "aggregate retrospective issue"; do
    if grep_q "$REFLECT_MD" "$c"; then
        pass "core から外す明示: $c"
    else
        fail "core から外す明示欠落: $c"
    fi
done

echo "== templates/reflect.md: 章立て =="
for s in "## Keep" "## Problem" "## Try" "## Issue リンク"; do
    if grep_q "$REFLECT_TMPL" "$s"; then
        pass "テンプレ章: $s"
    else
        fail "テンプレ章欠落: $s"
    fi
done
if grep_q "$REFLECT_TMPL" "# Reflect: {{cycle}}"; then
    pass "テンプレ見出し + {{cycle}} プレースホルダ"
else
    fail "テンプレ見出し / プレースホルダ欠落"
fi

echo "== SKILL.md: reflect 実装反映 / alias / express =="
if grep_q "$SKILL_MD" "steps/reflect.md"; then
    pass "SKILL.md が steps/reflect.md を参照"
else
    fail "SKILL.md の steps/reflect.md 参照欠落"
fi
# reflect の予約 stale が残らない（コマンド表で reflect が実在表記 / バックティック回避のため部分一致）
if grep_q "$SKILL_MD" "（実在 / Unit 002 で実装）"; then
    pass "reflect コマンド表が実在表記（予約 stale なし）"
else
    fail "reflect コマンド表が実在表記でない（予約 stale の疑い）"
fi
# doctor は予約のまま（混在更新で誤って変えていないこと）
if grep_q "$SKILL_MD" "doctor"; then
    pass "doctor 行は維持（予約のまま）"
else
    fail "doctor 行が失われた"
fi
# retrospective エイリアス整合（alias 表に retrospective 行が存在）
if grep_q "$SKILL_MD" "retrospective"; then
    pass "retrospective -> reflect エイリアス整合"
else
    fail "retrospective -> reflect エイリアス欠落"
fi
# express に reflect を含めない（define -> develop -> release のみ / 単一引用でバックティック保護）
# shellcheck disable=SC2016  # バックティックは grep -F のリテラル検索内容（展開意図なし / 二重引用だとコマンド置換扱いになる）
if grep_q "$SKILL_MD" 'define` → `develop` → `release`'; then
    pass "express チェーンが define->develop->release（reflect 非包含）"
else
    fail "express チェーン表記が変化（reflect 非包含の確認失敗）"
fi

echo ""
echo "== 結果 =="
echo "  PASS=$PASS FAIL=$FAIL"
if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
