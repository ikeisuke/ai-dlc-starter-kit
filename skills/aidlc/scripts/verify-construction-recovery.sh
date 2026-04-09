#!/usr/bin/env bash
#
# verify-construction-recovery.sh
#
# Unit 003 の Construction 固有検証 (正常系4 + 異常系2 + Construction 完了シグナル1) 用の
# test fixture を生成する補助スクリプト。
# 自動判定ロジックは実装せず、入力スナップショットを再現することだけを目的とする。
# 判定ロジック本体は steps/common/phase-recovery-spec.md §5.2 を参照。
#
# 使用方法:
#   verify-construction-recovery.sh --case <case_id> [--dest <dir>] [--clean] [--dry-run]
#
# 引数:
#   --case CASE_ID    必須。再現するケース識別子
#   --dest DIR        任意。セットアップ先ディレクトリ (デフォルト: .aidlc/cycles/vTEST-<case>)
#                     必ず .aidlc/cycles/vTEST-* プレフィックス、かつ '..' を含まない相対パス
#   --clean           任意。既存のテストディレクトリを削除してから作成
#   --dry-run         任意。実ファイルを作成せず、作成予定のファイルリストのみ表示
#
# 有効な case_id:
#   normal-unit-setup / normal-unit-design / normal-unit-implementation / normal-unit-completion
#   multi_unit_in_progress / dependency_block / all_units_completed
#
# 成功時出力 (stdout):
#   verify-case:<case>:<dest>:setup-ready
#   expected_phase:<期待 phase>
#   expected_step_id:<期待 step_id または 'none'>
#   expected_diagnostics:<diagnostics 種別のセミコロン区切り または 'none'>
#   spec_refs:<照合すべき spec 参照のセミコロン区切り>
#
# エラー時出力 (stderr):
#   【verify-construction-recovery エラー】
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

SCRIPT_NAME="verify-construction-recovery"

print_error() {
    echo "【${SCRIPT_NAME} エラー】" >&2
    echo "理由: $1" >&2
}

usage_error() {
    print_error "$1"
    echo "" >&2
    echo "使用方法: verify-construction-recovery.sh --case <case_id> [--dest <dir>] [--clean] [--dry-run]" >&2
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

if ! printf '%s' "$CASE" | grep -Eq '^[a-z0-9][a-z0-9_-]*$'; then
    usage_error "--case の値が不正です: $CASE"
fi

VALID_CASES="normal-unit-setup normal-unit-design normal-unit-implementation normal-unit-completion multi_unit_in_progress dependency_block all_units_completed"

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
case "$DEST" in
    /*)
        usage_error "--dest は絶対パス不可です: $DEST"
        ;;
esac

case "$DEST" in
    .aidlc/cycles/vTEST-*)
        ;;
    *)
        usage_error "--dest は .aidlc/cycles/vTEST- プレフィックスが必要です: $DEST"
        ;;
esac

case "$DEST" in
    *..*)
        usage_error "--dest に '..' を含めることはできません: $DEST"
        ;;
esac

case "$DEST" in
    *//*)
        usage_error "--dest に連続スラッシュは含められません: $DEST"
        ;;
esac

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

# Inception progress.md（Construction 判定の前提条件として inception=completed を満たす）
gen_inception_progress_all_complete() {
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

# Unit 定義ファイル（実装状態を引数で指定）
gen_unit_md_with_status() {
    # $1 = 実装状態（未着手 / 進行中 / 完了 / 取り下げ）
    # $2 = 依存 Unit リスト（空文字 or "001" 等）
    local status="$1"
    local deps="$2"
    FIXTURE_CONTENT="# Unit: test fixture unit

## 概要

test fixture unit for Construction recovery verification.

## 依存関係

### 依存する Unit

${deps}

---
## 実装状態

- **状態**: ${status}
- **開始日**: -
- **完了日**: -
- **担当**: -
"
}

# Construction history（ステップ完了記録を含む）
gen_construction_history_empty() {
    FIXTURE_CONTENT='# Construction Phase History (Unit 01)

## Unit 001 test-unit

'
}

gen_construction_history_setup_done() {
    FIXTURE_CONTENT='# Construction Phase History (Unit 01)

## Unit 001 test-unit

### Step: 計画承認

- 日時: 2026-01-01T00:00:00
- 内容: fixture plan approval
'
}

gen_construction_history_design_done() {
    FIXTURE_CONTENT='# Construction Phase History (Unit 01)

## Unit 001 test-unit

### Step: 計画承認

- 日時: 2026-01-01T00:00:00
- 内容: fixture plan approval

### Step: 設計承認

- 日時: 2026-01-01T01:00:00
- 内容: fixture design approval
'
}

gen_construction_history_implementation_done() {
    FIXTURE_CONTENT='# Construction Phase History (Unit 01)

## Unit 001 test-unit

### Step: 計画承認

- 日時: 2026-01-01T00:00:00
- 内容: fixture plan approval

### Step: 設計承認

- 日時: 2026-01-01T01:00:00
- 内容: fixture design approval

### Step: 実装承認

- 日時: 2026-01-01T02:00:00
- 内容: fixture implementation approval
'
}

# Plan file
gen_plan_file() {
    FIXTURE_CONTENT='# Unit 001 計画: test fixture

## 概要

test fixture plan

## 完了条件チェックリスト

- [ ] fixture completion
'
}

# Domain model / logical design stub
gen_domain_model_stub() {
    FIXTURE_CONTENT='# ドメインモデル: test fixture

test fixture domain model
'
}

gen_logical_design_stub() {
    FIXTURE_CONTENT='# 論理設計: test fixture

test fixture logical design
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

# 共通: inception を completed 状態にする（Construction 判定の前提条件）
setup_inception_completed() {
    mkdir_p "${DEST}/inception"
    gen_inception_progress_all_complete
    write_file "${DEST}/inception/progress.md"
}

setup_normal_unit_setup() {
    # 進行中 Unit 1 件、plan のみ、history 空（計画承認前）
    setup_inception_completed
    mkdir_p "${DEST}/story-artifacts/units"
    mkdir_p "${DEST}/plans"
    mkdir_p "${DEST}/history"
    gen_unit_md_with_status "進行中" ""
    write_file "${DEST}/story-artifacts/units/001-test-unit.md"
    gen_plan_file
    write_file "${DEST}/plans/unit-001-plan.md"
    gen_construction_history_empty
    write_file "${DEST}/history/construction_unit01.md"
    EXPECTED_PHASE="construction"
    EXPECTED_STEP_ID="construction.01-setup"
    SPEC_REFS="spec§4;spec§5.construction.setup_done;spec§6;spec§8;spec§11"
}

setup_normal_unit_design() {
    # 進行中 Unit 1 件、plan 承認済み、設計未着手
    setup_inception_completed
    mkdir_p "${DEST}/story-artifacts/units"
    mkdir_p "${DEST}/plans"
    mkdir_p "${DEST}/history"
    gen_unit_md_with_status "進行中" ""
    write_file "${DEST}/story-artifacts/units/001-test-unit.md"
    gen_plan_file
    write_file "${DEST}/plans/unit-001-plan.md"
    gen_construction_history_setup_done
    write_file "${DEST}/history/construction_unit01.md"
    EXPECTED_PHASE="construction"
    EXPECTED_STEP_ID="construction.02-design"
    SPEC_REFS="spec§4;spec§5.construction.design_done;spec§6;spec§8;spec§11"
}

setup_normal_unit_implementation() {
    # 進行中 Unit 1 件、設計承認済み、実装未着手
    setup_inception_completed
    mkdir_p "${DEST}/story-artifacts/units"
    mkdir_p "${DEST}/plans"
    mkdir_p "${DEST}/history"
    mkdir_p "${DEST}/design-artifacts/domain-models"
    mkdir_p "${DEST}/design-artifacts/logical-designs"
    gen_unit_md_with_status "進行中" ""
    write_file "${DEST}/story-artifacts/units/001-test-unit.md"
    gen_plan_file
    write_file "${DEST}/plans/unit-001-plan.md"
    gen_domain_model_stub
    write_file "${DEST}/design-artifacts/domain-models/unit_001_test_unit_domain_model.md"
    gen_logical_design_stub
    write_file "${DEST}/design-artifacts/logical-designs/unit_001_test_unit_logical_design.md"
    gen_construction_history_design_done
    write_file "${DEST}/history/construction_unit01.md"
    EXPECTED_PHASE="construction"
    EXPECTED_STEP_ID="construction.03-implementation"
    SPEC_REFS="spec§4;spec§5.construction.implementation_done;spec§6;spec§8;spec§11"
}

setup_normal_unit_completion() {
    # 進行中 Unit 1 件、実装承認済み、完了処理未着手
    setup_inception_completed
    mkdir_p "${DEST}/story-artifacts/units"
    mkdir_p "${DEST}/plans"
    mkdir_p "${DEST}/history"
    mkdir_p "${DEST}/design-artifacts/domain-models"
    mkdir_p "${DEST}/design-artifacts/logical-designs"
    gen_unit_md_with_status "進行中" ""
    write_file "${DEST}/story-artifacts/units/001-test-unit.md"
    gen_plan_file
    write_file "${DEST}/plans/unit-001-plan.md"
    gen_domain_model_stub
    write_file "${DEST}/design-artifacts/domain-models/unit_001_test_unit_domain_model.md"
    gen_logical_design_stub
    write_file "${DEST}/design-artifacts/logical-designs/unit_001_test_unit_logical_design.md"
    gen_construction_history_implementation_done
    write_file "${DEST}/history/construction_unit01.md"
    EXPECTED_PHASE="construction"
    EXPECTED_STEP_ID="construction.04-completion"
    SPEC_REFS="spec§4;spec§5.construction.completion_done;spec§6;spec§8;spec§11"
}

setup_multi_unit_in_progress() {
    # 2 Unit 同時に「進行中」→ undecidable:conflict
    setup_inception_completed
    mkdir_p "${DEST}/story-artifacts/units"
    mkdir_p "${DEST}/plans"
    mkdir_p "${DEST}/history"
    gen_unit_md_with_status "進行中" ""
    write_file "${DEST}/story-artifacts/units/001-first-unit.md"
    gen_unit_md_with_status "進行中" ""
    write_file "${DEST}/story-artifacts/units/002-second-unit.md"
    gen_plan_file
    write_file "${DEST}/plans/unit-001-plan.md"
    gen_plan_file
    write_file "${DEST}/plans/unit-002-plan.md"
    EXPECTED_PHASE="construction"
    EXPECTED_STEP_ID="undecidable:conflict"
    SPEC_REFS="spec§4;spec§5.construction.unit_selection;spec§7;spec§8;spec§11"
}

setup_dependency_block() {
    # 進行中 0、実行可能 0（Unit 002 が Unit 001 に依存、Unit 001 が未着手 → 002 は実行不可）
    # 実際には 001 も未着手だが依存なしなので executable。これで executable=1 になってしまう。
    # dependency_block を再現するには、001 の依存が外部 Unit（999 等、完了扱い）で自己完結できる必要がある。
    # シナリオ: Unit 001 が未着手、Unit 001 は Unit 099（未完了・取り下げでもない）に依存
    # → executable_units = 0, pending_units > 0
    setup_inception_completed
    mkdir_p "${DEST}/story-artifacts/units"
    mkdir_p "${DEST}/plans"
    gen_unit_md_with_status "未着手" "- Unit 099（存在しない依存 → 依存ブロック）"
    write_file "${DEST}/story-artifacts/units/001-blocked-unit.md"
    EXPECTED_PHASE="construction"
    EXPECTED_STEP_ID="undecidable:dependency_block"
    SPEC_REFS="spec§4;spec§5.construction.unit_selection;spec§7;spec§8;spec§11"
}

setup_all_units_completed() {
    # 全 Unit 完了 → PhaseResolver が phaseProgressStatus[construction]=completed として吸収
    # operations/progress.md なし → Operations 未着手、construction_complete info 追加
    setup_inception_completed
    mkdir_p "${DEST}/story-artifacts/units"
    mkdir_p "${DEST}/plans"
    mkdir_p "${DEST}/history"
    gen_unit_md_with_status "完了" ""
    write_file "${DEST}/story-artifacts/units/001-first-unit.md"
    gen_unit_md_with_status "完了" ""
    write_file "${DEST}/story-artifacts/units/002-second-unit.md"
    gen_plan_file
    write_file "${DEST}/plans/unit-001-plan.md"
    gen_plan_file
    write_file "${DEST}/plans/unit-002-plan.md"
    EXPECTED_PHASE="operations"
    EXPECTED_STEP_ID="none"
    EXPECTED_DIAGNOSTICS="construction_complete"
    SPEC_REFS="spec§4;spec§11"
}

# ケース分岐
case "$CASE" in
    normal-unit-setup) setup_normal_unit_setup ;;
    normal-unit-design) setup_normal_unit_design ;;
    normal-unit-implementation) setup_normal_unit_implementation ;;
    normal-unit-completion) setup_normal_unit_completion ;;
    multi_unit_in_progress) setup_multi_unit_in_progress ;;
    dependency_block) setup_dependency_block ;;
    all_units_completed) setup_all_units_completed ;;
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
