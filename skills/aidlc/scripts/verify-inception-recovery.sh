#!/usr/bin/env bash
#
# verify-inception-recovery.sh
#
# Unit 002 の正常系・異常系・#553 再現シナリオ用の test fixture を生成する補助スクリプト。
# 自動判定ロジックは実装せず、入力スナップショットを再現することだけを目的とする。
# 判定ロジック本体は steps/common/phase-recovery-spec.md を参照。
#
# 使用方法:
#   verify-inception-recovery.sh --case <case_id> [--dest <dir>] [--clean] [--dry-run]
#
# 引数:
#   --case CASE_ID    必須。再現するケース識別子
#   --dest DIR        任意。セットアップ先ディレクトリ (デフォルト: .aidlc/cycles/vTEST-<case>)
#                     必ず .aidlc/cycles/vTEST-* プレフィックス、かつ '..' を含まない相対パス
#   --clean           任意。既存のテストディレクトリを削除してから作成
#   --dry-run         任意。実ファイルを作成せず、作成予定のファイルリストのみ表示
#
# 有効な case_id:
#   normal-1 / normal-2 / normal-3 / normal-4a / normal-4b / normal-5
#   abnormal-missing_file / abnormal-conflict / abnormal-format_error / abnormal-legacy_structure
#   i553-1a / i553-1b / i553-2
#
# 成功時出力 (stdout):
#   verify-case:<case>:<dest>:setup-ready
#   expected_phase:<期待 phase>
#   expected_step_id:<期待 step_id または 'none'>
#   expected_diagnostics:<diagnostics 種別のセミコロン区切り または 'none'>
#   spec_refs:<照合すべき spec 参照のセミコロン区切り>
#
# エラー時出力 (stderr):
#   【verify-inception-recovery エラー】
#   理由: <メッセージ>
#
# 終了コード:
#   0  成功
#   1  一般エラー
#   2  引数エラー
#
# 注意:
#   - このスクリプトはコマンド置換 `$(...)` およびバッククォートを使用しない
#     (.aidlc/rules.md のコーディング規約および bin/check-bash-substitution.sh 準拠)

set -euo pipefail

SCRIPT_NAME="verify-inception-recovery"

print_error() {
    echo "【${SCRIPT_NAME} エラー】" >&2
    echo "理由: $1" >&2
}

usage_error() {
    print_error "$1"
    echo "" >&2
    echo "使用方法: verify-inception-recovery.sh --case <case_id> [--dest <dir>] [--clean] [--dry-run]" >&2
    exit 2
}

# 引数パース
CASE=""
DEST=""
CLEAN="false"
DRY_RUN="false"

while [ $# -gt 0 ]; do
    case "$1" in
        --case)
            if [ $# -lt 2 ]; then
                usage_error "--case には値が必要です"
            fi
            CASE="$2"
            shift 2
            ;;
        --dest)
            if [ $# -lt 2 ]; then
                usage_error "--dest には値が必要です"
            fi
            DEST="$2"
            shift 2
            ;;
        --clean)
            CLEAN="true"
            shift
            ;;
        --dry-run)
            DRY_RUN="true"
            shift
            ;;
        -h|--help)
            sed -n '3,45p' "$0"
            exit 0
            ;;
        *)
            usage_error "不明な引数: $1"
            ;;
    esac
done

# --case バリデーション
if [ -z "$CASE" ]; then
    usage_error "--case は必須です"
fi

# ケース識別子の正規表現チェック (英数字・ハイフン・アンダースコアのみ)
if ! printf '%s' "$CASE" | grep -Eq '^[a-z0-9][a-z0-9_-]*$'; then
    usage_error "--case の値が不正です: $CASE"
fi

# 有効な case_id の列挙
VALID_CASES="normal-1 normal-2 normal-3 normal-4a normal-4b normal-5 abnormal-missing_file abnormal-conflict abnormal-format_error abnormal-legacy_structure i553-1a i553-1b i553-2"

CASE_VALID="false"
for v in $VALID_CASES; do
    if [ "$v" = "$CASE" ]; then
        CASE_VALID="true"
        break
    fi
done

if [ "$CASE_VALID" != "true" ]; then
    usage_error "未知の case_id です: $CASE (有効値: $VALID_CASES)"
fi

# --dest デフォルト値
if [ -z "$DEST" ]; then
    DEST=".aidlc/cycles/vTEST-${CASE}"
fi

# --dest セキュリティバリデーション（ディレクトリトラバーサル対策）
# ルール:
#   1. 先頭が '/' でない（絶対パス禁止）
#   2. '.aidlc/cycles/vTEST-' プレフィックス必須
#   3. '..' セグメントを含まない（トラバーサル拒否）
#   4. 連続スラッシュ '//' を含まない
#   5. 制御文字・空白を含まない
#   6. 全体として安全な文字集合のみ（英数字・ハイフン・アンダースコア・ドット・スラッシュ）

# ルール1: 絶対パス拒否
case "$DEST" in
    /*)
        usage_error "--dest は絶対パス不可です: $DEST"
        ;;
esac

# ルール2: プレフィックス必須
case "$DEST" in
    .aidlc/cycles/vTEST-*)
        ;;
    *)
        usage_error "--dest は .aidlc/cycles/vTEST- プレフィックスが必要です: $DEST"
        ;;
esac

# ルール3: '..' セグメント拒否（先頭/中間/末尾を全て網羅）
case "$DEST" in
    ..|*/..|*/../*|../*)
        usage_error "--dest に '..' セグメントは含められません: $DEST"
        ;;
esac

# ルール4: 連続スラッシュ拒否
case "$DEST" in
    *//*)
        usage_error "--dest に連続スラッシュは含められません: $DEST"
        ;;
esac

# ルール5/6: 安全な文字集合のみ許可
if ! printf '%s' "$DEST" | grep -Eq '^[a-zA-Z0-9._/-]+$'; then
    usage_error "--dest に不正な文字が含まれています: $DEST"
fi

# fixture 変数
FIXTURE_FILES=""
FIXTURE_CONTENT=""

mkdir_p() {
    local dir="$1"
    FIXTURE_FILES="${FIXTURE_FILES}${FIXTURE_FILES:+ }${dir}/"
    if [ "$DRY_RUN" = "false" ]; then
        mkdir -p "$dir"
    fi
}

write_file() {
    # 使用前に gen_*() 関数で FIXTURE_CONTENT を設定しておくこと
    local path="$1"
    FIXTURE_FILES="${FIXTURE_FILES}${FIXTURE_FILES:+ }${path}"
    if [ "$DRY_RUN" = "false" ]; then
        local parent
        parent="${path%/*}"
        mkdir -p "$parent"
        printf '%s' "$FIXTURE_CONTENT" > "$path"
    fi
}

# progress.md のテンプレート生成関数（グローバル変数 FIXTURE_CONTENT に格納）
gen_progress_md_empty() {
    FIXTURE_CONTENT='# Inception Phase 進捗管理

## ステップ進捗

| ステップ | 状態 | 完了日 |
|---------|------|-------|
| 1. セットアップ | 未着手 | - |
| 2. インセプション準備 | 未着手 | - |
| 3. Intent 明確化 | 未着手 | - |
| 4. ストーリー・Unit 定義 | 未着手 | - |
| 5. 完了処理 | 未着手 | - |
'
}

gen_progress_md_at_step() {
    # $1 = 最新「進行中」ステップ (1〜5)
    local at="$1"
    local step1="未着手"
    local step2="未着手"
    local step3="未着手"
    local step4="未着手"
    local step5="未着手"

    if [ "$at" -ge 2 ]; then step1="完了"; fi
    if [ "$at" -ge 3 ]; then step2="完了"; fi
    if [ "$at" -ge 4 ]; then step3="完了"; fi
    if [ "$at" -ge 5 ]; then step4="完了"; fi

    case "$at" in
        1) step1="進行中" ;;
        2) step2="進行中" ;;
        3) step3="進行中" ;;
        4) step4="進行中" ;;
        5) step5="進行中" ;;
    esac

    FIXTURE_CONTENT="# Inception Phase 進捗管理

## ステップ進捗

| ステップ | 状態 | 完了日 |
|---------|------|-------|
| 1. セットアップ | ${step1} | - |
| 2. インセプション準備 | ${step2} | - |
| 3. Intent 明確化 | ${step3} | - |
| 4. ストーリー・Unit 定義 | ${step4} | - |
| 5. 完了処理 | ${step5} | - |
"
}

gen_progress_md_all_complete() {
    FIXTURE_CONTENT='# Inception Phase 進捗管理

## ステップ進捗

| ステップ | 状態 | 完了日 |
|---------|------|-------|
| 1. セットアップ | 完了 | 2026-01-01 |
| 2. インセプション準備 | 完了 | 2026-01-01 |
| 3. Intent 明確化 | 完了 | 2026-01-01 |
| 4. ストーリー・Unit 定義 | 完了 | 2026-01-01 |
| 5. 完了処理 | 完了 | 2026-01-01 |
'
}

gen_progress_md_format_broken() {
    FIXTURE_CONTENT='broken progress file
no headings at all
random content
'
}

gen_intent_md() {
    FIXTURE_CONTENT='# Intent

## 背景

test fixture

## 含まれるもの

- fixture requirement
'
}

gen_user_stories_md() {
    FIXTURE_CONTENT='# User Stories

## Story 1

test fixture story
'
}

gen_unit_md() {
    FIXTURE_CONTENT='# Unit: test fixture unit

## 実装状態

- 状態: 未着手
'
}

gen_history_inception_md() {
    FIXTURE_CONTENT='# Inception Phase History

## Step: Intent 明確化

- 日時: 2026-01-01T00:00:00
- 内容: fixture history
'
}

gen_operations_progress_md() {
    FIXTURE_CONTENT='# Operations Phase 進捗管理

## ステップ進捗

| ステップ | 状態 |
|---------|------|
| デプロイ準備 | 進行中 |
'
}

gen_session_state_md() {
    FIXTURE_CONTENT='# Legacy Session State

(v2.2.x 以前の旧構造マーカー)
'
}

# --clean 処理（バリデーション完了後のみ実行）
if [ "$CLEAN" = "true" ]; then
    if [ -e "$DEST" ]; then
        if [ "$DRY_RUN" = "true" ]; then
            echo "would-remove:$DEST" >&2
        else
            rm -rf "$DEST"
        fi
    fi
fi

# ケース別のセットアップ
EXPECTED_PHASE=""
EXPECTED_STEP_ID=""
EXPECTED_DIAGNOSTICS="none"
SPEC_REFS=""

setup_normal_1() {
    mkdir_p "${DEST}/inception"
    gen_progress_md_empty
    write_file "${DEST}/inception/progress.md"
    EXPECTED_PHASE="inception"
    EXPECTED_STEP_ID="inception.01-setup"
    SPEC_REFS="spec§4;spec§5.setup_done;spec§6;spec§8"
}

setup_normal_2() {
    mkdir_p "${DEST}/inception"
    gen_progress_md_at_step 3
    write_file "${DEST}/inception/progress.md"
    gen_intent_md
    write_file "${DEST}/inception/intent.md"
    EXPECTED_PHASE="inception"
    EXPECTED_STEP_ID="inception.03-intent"
    SPEC_REFS="spec§4;spec§5.intent_done;spec§6;spec§8"
}

setup_normal_3() {
    mkdir_p "${DEST}/inception"
    mkdir_p "${DEST}/story-artifacts"
    gen_progress_md_at_step 4
    write_file "${DEST}/inception/progress.md"
    gen_intent_md
    write_file "${DEST}/inception/intent.md"
    gen_user_stories_md
    write_file "${DEST}/story-artifacts/user_stories.md"
    EXPECTED_PHASE="inception"
    EXPECTED_STEP_ID="inception.04-stories-units"
    SPEC_REFS="spec§4;spec§5.units_done;spec§6;spec§8"
}

setup_normal_4a() {
    mkdir_p "${DEST}/inception"
    mkdir_p "${DEST}/story-artifacts/units"
    gen_progress_md_at_step 4
    write_file "${DEST}/inception/progress.md"
    gen_intent_md
    write_file "${DEST}/inception/intent.md"
    gen_user_stories_md
    write_file "${DEST}/story-artifacts/user_stories.md"
    gen_unit_md
    write_file "${DEST}/story-artifacts/units/001-test.md"
    EXPECTED_PHASE="inception"
    EXPECTED_STEP_ID="inception.04-stories-units"
    SPEC_REFS="spec§4;spec§5.units_done;spec§6;spec§8"
}

setup_normal_4b() {
    mkdir_p "${DEST}/inception"
    mkdir_p "${DEST}/story-artifacts/units"
    gen_progress_md_at_step 5
    write_file "${DEST}/inception/progress.md"
    gen_intent_md
    write_file "${DEST}/inception/intent.md"
    gen_user_stories_md
    write_file "${DEST}/story-artifacts/user_stories.md"
    gen_unit_md
    write_file "${DEST}/story-artifacts/units/001-test.md"
    EXPECTED_PHASE="inception"
    EXPECTED_STEP_ID="inception.05-completion"
    SPEC_REFS="spec§4;spec§5.completion_done;spec§6;spec§8"
}

setup_normal_5() {
    mkdir_p "${DEST}/inception"
    mkdir_p "${DEST}/story-artifacts/units"
    mkdir_p "${DEST}/history"
    gen_progress_md_at_step 5
    write_file "${DEST}/inception/progress.md"
    gen_intent_md
    write_file "${DEST}/inception/intent.md"
    gen_user_stories_md
    write_file "${DEST}/story-artifacts/user_stories.md"
    gen_unit_md
    write_file "${DEST}/story-artifacts/units/001-test.md"
    gen_history_inception_md
    write_file "${DEST}/history/inception.md"
    EXPECTED_PHASE="inception"
    EXPECTED_STEP_ID="inception.05-completion"
    SPEC_REFS="spec§4;spec§5.completion_done;spec§6;spec§8"
}

setup_abnormal_missing_file() {
    # inception/progress.md を作成せず、units/*.md だけ作る（inception の必須 progress.md が欠損）
    mkdir_p "${DEST}/story-artifacts/units"
    gen_unit_md
    write_file "${DEST}/story-artifacts/units/001-test.md"
    EXPECTED_PHASE="undecidable:missing_file"
    EXPECTED_STEP_ID="none"
    SPEC_REFS="spec§4;spec§7;spec§8"
}

setup_abnormal_conflict() {
    mkdir_p "${DEST}/inception"
    mkdir_p "${DEST}/operations"
    gen_progress_md_at_step 3
    write_file "${DEST}/inception/progress.md"
    gen_operations_progress_md
    write_file "${DEST}/operations/progress.md"
    EXPECTED_PHASE="undecidable:conflict"
    EXPECTED_STEP_ID="none"
    SPEC_REFS="spec§4;spec§7;spec§8"
}

setup_abnormal_format_error() {
    mkdir_p "${DEST}/inception"
    gen_progress_md_format_broken
    write_file "${DEST}/inception/progress.md"
    EXPECTED_PHASE="undecidable:format_error"
    EXPECTED_STEP_ID="none"
    SPEC_REFS="spec§3;spec§7;spec§8"
}

setup_abnormal_legacy_structure() {
    mkdir_p "${DEST}/inception"
    gen_progress_md_empty
    write_file "${DEST}/inception/progress.md"
    gen_session_state_md
    write_file "${DEST}/session-state.md"
    EXPECTED_PHASE="inception"
    EXPECTED_STEP_ID="inception.01-setup"
    EXPECTED_DIAGNOSTICS="legacy_structure"
    SPEC_REFS="spec§4;spec§5.setup_done;spec§6;spec§7;spec§8"
}

setup_i553_1a() {
    # PRFAQ 未着手 (完了処理未着手、units/*.md 存在、history なし)
    mkdir_p "${DEST}/inception"
    mkdir_p "${DEST}/story-artifacts/units"
    gen_progress_md_at_step 4
    write_file "${DEST}/inception/progress.md"
    gen_intent_md
    write_file "${DEST}/inception/intent.md"
    gen_user_stories_md
    write_file "${DEST}/story-artifacts/user_stories.md"
    gen_unit_md
    write_file "${DEST}/story-artifacts/units/001-test.md"
    EXPECTED_PHASE="inception"
    EXPECTED_STEP_ID="inception.04-stories-units"
    SPEC_REFS="spec§4;spec§5.units_done;spec§6;spec§8;spec§10"
}

setup_i553_1b() {
    # 完了処理進行中 (units/*.md 存在、history なし)
    mkdir_p "${DEST}/inception"
    mkdir_p "${DEST}/story-artifacts/units"
    gen_progress_md_at_step 5
    write_file "${DEST}/inception/progress.md"
    gen_intent_md
    write_file "${DEST}/inception/intent.md"
    gen_user_stories_md
    write_file "${DEST}/story-artifacts/user_stories.md"
    gen_unit_md
    write_file "${DEST}/story-artifacts/units/001-test.md"
    EXPECTED_PHASE="inception"
    EXPECTED_STEP_ID="inception.05-completion"
    SPEC_REFS="spec§4;spec§5.completion_done;spec§6;spec§8;spec§10"
}

setup_i553_2() {
    # PRFAQ 完了・完了処理完了 (全完了、history あり)
    mkdir_p "${DEST}/inception"
    mkdir_p "${DEST}/story-artifacts/units"
    mkdir_p "${DEST}/history"
    gen_progress_md_all_complete
    write_file "${DEST}/inception/progress.md"
    gen_intent_md
    write_file "${DEST}/inception/intent.md"
    gen_user_stories_md
    write_file "${DEST}/story-artifacts/user_stories.md"
    gen_unit_md
    write_file "${DEST}/story-artifacts/units/001-test.md"
    gen_history_inception_md
    write_file "${DEST}/history/inception.md"
    EXPECTED_PHASE="construction"
    EXPECTED_STEP_ID="none"
    SPEC_REFS="spec§2;spec§4;spec§10"
}

# ケース分岐
case "$CASE" in
    normal-1) setup_normal_1 ;;
    normal-2) setup_normal_2 ;;
    normal-3) setup_normal_3 ;;
    normal-4a) setup_normal_4a ;;
    normal-4b) setup_normal_4b ;;
    normal-5) setup_normal_5 ;;
    abnormal-missing_file) setup_abnormal_missing_file ;;
    abnormal-conflict) setup_abnormal_conflict ;;
    abnormal-format_error) setup_abnormal_format_error ;;
    abnormal-legacy_structure) setup_abnormal_legacy_structure ;;
    i553-1a) setup_i553_1a ;;
    i553-1b) setup_i553_1b ;;
    i553-2) setup_i553_2 ;;
    *)
        print_error "内部エラー: 未処理の case: $CASE"
        exit 1
        ;;
esac

# 結果出力
if [ "$DRY_RUN" = "true" ]; then
    echo "verify-case:${CASE}:${DEST}:dry-run"
    echo "would-create-files:${FIXTURE_FILES}"
else
    echo "verify-case:${CASE}:${DEST}:setup-ready"
fi
echo "expected_phase:${EXPECTED_PHASE}"
echo "expected_step_id:${EXPECTED_STEP_ID}"
echo "expected_diagnostics:${EXPECTED_DIAGNOSTICS}"
echo "spec_refs:${SPEC_REFS}"

exit 0
