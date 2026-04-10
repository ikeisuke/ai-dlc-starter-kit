#!/usr/bin/env bash
#
# verify-operations-recovery.sh
#
# Unit 004 の Operations 固有検証 (正常系4 + bootstrap1 + 異常系2 = 計7) 用の
# test fixture を生成する補助スクリプト。
# 自動判定ロジックは実装せず、入力スナップショットを再現することだけを目的とする。
# 判定ロジック本体は steps/common/phase-recovery-spec.md §5.3 を参照。
#
# 使用方法:
#   verify-operations-recovery.sh --case <case_id> [--dest <dir>] [--clean] [--dry-run]
#
# 引数:
#   --case CASE_ID    必須。再現するケース識別子
#   --dest DIR        任意。セットアップ先ディレクトリ (デフォルト: .aidlc/cycles/vTEST-<case>)
#                     必ず .aidlc/cycles/vTEST-* プレフィックス、かつ '..' を含まない相対パス
#   --clean           任意。既存のテストディレクトリを削除してから作成
#   --dry-run         任意。実ファイルを作成せず、作成予定のファイルリストのみ表示
#
# 有効な case_id:
#   normal-deploy-fresh / normal-deploy-progress / normal-release / normal-completion
#   bootstrap-from-construction
#   abnormal-operations_in_progress_missing_progress / abnormal-progress_corrupt
#
# 成功時出力 (stdout):
#   verify-case:<case>:<dest>:setup-ready
#   expected_phase:<期待 phase>
#   expected_step_id:<期待 step_id または 'none'>
#   expected_diagnostics:<diagnostics 種別のセミコロン区切り または 'none'>
#   spec_refs:<照合すべき spec 参照のセミコロン区切り>
#
# エラー時出力 (stderr):
#   【verify-operations-recovery エラー】
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

SCRIPT_NAME="verify-operations-recovery"

print_error() {
    echo "【${SCRIPT_NAME} エラー】" >&2
    echo "理由: $1" >&2
}

usage_error() {
    print_error "$1"
    echo "" >&2
    echo "使用方法: verify-operations-recovery.sh --case <case_id> [--dest <dir>] [--clean] [--dry-run]" >&2
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
            sed -n '3,46p' "$0"
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

VALID_CASES="normal-deploy-fresh normal-deploy-progress normal-release normal-completion bootstrap-from-construction abnormal-operations_in_progress_missing_progress abnormal-progress_corrupt"

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

# Inception progress.md（Operations 判定の前提条件として inception=completed を満たす）
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

# Unit 定義ファイル（完了状態固定、Construction 完了の前提条件として）
gen_unit_md_completed() {
    FIXTURE_CONTENT='# Unit: test fixture unit

## 概要

test fixture unit for Operations recovery verification.

## 依存関係

### 依存する Unit

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-01-01
- **完了日**: 2026-01-02
- **担当**: -
'
}

# Operations progress.md（各 Step の状態を引数で指定）
gen_operations_progress() {
    # $1 = ステップ1 状態
    # $2 = ステップ2 状態
    # $3 = ステップ3 状態
    # $4 = ステップ4 状態
    # $5 = ステップ5 状態
    # $6 = ステップ6 状態
    # $7 = ステップ7 状態
    local s1="$1"
    local s2="$2"
    local s3="$3"
    local s4="$4"
    local s5="$5"
    local s6="$6"
    local s7="$7"
    FIXTURE_CONTENT="# Operations Phase 進捗管理

## ステップ進捗

| ステップ | 状態 | 完了日 |
|---------|------|-------|
| 1. 変更確認 | ${s1} | - |
| 2. デプロイ準備 | ${s2} | - |
| 3. CI/CD 構築 | ${s3} | - |
| 4. 監視・ロギング戦略 | ${s4} | - |
| 5. 配布 | ${s5} | - |
| 6. バックログ整理と運用計画 | ${s6} | - |
| 7. リリース準備 | ${s7} | - |
"
}

# Operations progress.md（破損ファイル）
gen_operations_progress_corrupt() {
    FIXTURE_CONTENT=''
}

# Operations history（空）
gen_operations_history_empty() {
    FIXTURE_CONTENT='# Operations Phase History

'
}

# Operations history（Operations 進行中マーカーあり、PR Ready 化記録なし）
gen_operations_history_in_progress() {
    FIXTURE_CONTENT='# Operations Phase History

## Step: ステップ1: 変更確認

- 日時: 2026-01-01T00:00:00
- 内容: fixture step 1 in progress
'
}

# Operations history（PR Ready 化記録あり）
gen_operations_history_ready() {
    FIXTURE_CONTENT='# Operations Phase History

## Step: ステップ7.7: Gitコミット

- 日時: 2026-01-01T00:00:00
- 内容: fixture pr commit

## Step: ステップ7.8: PR Ready 化

- 日時: 2026-01-01T01:00:00
- 内容: fixture pr ready
'
}

# Operations history（PR マージ記録あり）
gen_operations_history_merged() {
    FIXTURE_CONTENT='# Operations Phase History

## Step: ステップ7.7: Gitコミット

- 日時: 2026-01-01T00:00:00
- 内容: fixture pr commit

## Step: ステップ7.8: PR Ready 化

- 日時: 2026-01-01T01:00:00
- 内容: fixture pr ready

## Step: ステップ7.13: PR マージ

- 日時: 2026-01-01T02:00:00
- 内容: fixture pr merged
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

# 共通: inception を completed 状態にする（Operations 判定の前提条件）+ Construction 完了
setup_inception_and_construction_completed() {
    mkdir_p "${DEST}/inception"
    gen_inception_progress_all_complete
    write_file "${DEST}/inception/progress.md"
    mkdir_p "${DEST}/story-artifacts/units"
    gen_unit_md_completed
    write_file "${DEST}/story-artifacts/units/001-test-unit.md"
}

setup_normal_deploy_fresh() {
    # progress.md 存在、ステップ1-7 すべて未着手 (setup_done=true、deploy_done=false)
    setup_inception_and_construction_completed
    mkdir_p "${DEST}/operations"
    mkdir_p "${DEST}/history"
    gen_operations_progress "未着手" "未着手" "未着手" "未着手" "未着手" "未着手" "未着手"
    write_file "${DEST}/operations/progress.md"
    gen_operations_history_empty
    write_file "${DEST}/history/operations.md"
    EXPECTED_PHASE="operations"
    EXPECTED_STEP_ID="operations.02-deploy"
    SPEC_REFS="spec§4;spec§5.operations.deploy_done;spec§6;spec§8;spec§12"
}

setup_normal_deploy_progress() {
    # progress.md 存在、ステップ1-3 完了、ステップ4-7 進行中
    setup_inception_and_construction_completed
    mkdir_p "${DEST}/operations"
    mkdir_p "${DEST}/history"
    gen_operations_progress "完了" "完了" "完了" "進行中" "未着手" "未着手" "未着手"
    write_file "${DEST}/operations/progress.md"
    gen_operations_history_empty
    write_file "${DEST}/history/operations.md"
    EXPECTED_PHASE="operations"
    EXPECTED_STEP_ID="operations.02-deploy"
    SPEC_REFS="spec§4;spec§5.operations.deploy_done;spec§6;spec§8;spec§12"
}

setup_normal_release() {
    # progress.md ステップ1-7 すべて「完了」or「スキップ」、history に PR Ready 化記録なし
    setup_inception_and_construction_completed
    mkdir_p "${DEST}/operations"
    mkdir_p "${DEST}/history"
    gen_operations_progress "完了" "完了" "完了" "完了" "スキップ" "完了" "完了"
    write_file "${DEST}/operations/progress.md"
    gen_operations_history_in_progress
    write_file "${DEST}/history/operations.md"
    EXPECTED_PHASE="operations"
    EXPECTED_STEP_ID="operations.03-release"
    SPEC_REFS="spec§4;spec§5.operations.release_done;spec§6;spec§8;spec§12"
}

setup_normal_completion() {
    # 上記 + history に PR Ready 化記録あり、PR マージ記録なし
    setup_inception_and_construction_completed
    mkdir_p "${DEST}/operations"
    mkdir_p "${DEST}/history"
    gen_operations_progress "完了" "完了" "完了" "完了" "スキップ" "完了" "完了"
    write_file "${DEST}/operations/progress.md"
    gen_operations_history_ready
    write_file "${DEST}/history/operations.md"
    EXPECTED_PHASE="operations"
    EXPECTED_STEP_ID="operations.04-completion"
    SPEC_REFS="spec§4;spec§5.operations.completion_done;spec§6;spec§8;spec§12"
}

setup_bootstrap_from_construction() {
    # Construction 完了、operations/progress.md 未存在、history/operations.md 未存在
    # → bootstrap 分岐で operations.01-setup を返す（construction_complete info diagnostic）
    setup_inception_and_construction_completed
    EXPECTED_PHASE="operations"
    EXPECTED_STEP_ID="operations.01-setup"
    EXPECTED_DIAGNOSTICS="construction_complete"
    SPEC_REFS="spec§4;spec§5.operations.bootstrap;spec§5.operations.setup_done;spec§6;spec§8;spec§12"
}

setup_abnormal_operations_in_progress_missing_progress() {
    # history に Operations 進行中記録あり、operations/progress.md 欠損 → missing_file
    setup_inception_and_construction_completed
    mkdir_p "${DEST}/history"
    gen_operations_history_in_progress
    write_file "${DEST}/history/operations.md"
    EXPECTED_PHASE="operations"
    EXPECTED_STEP_ID="undecidable:missing_file"
    SPEC_REFS="spec§4;spec§5.operations.setup_done;spec§7;spec§8;spec§12"
}

setup_abnormal_progress_corrupt() {
    # operations/progress.md 存在するが空ファイル or パース不能 → format_error
    setup_inception_and_construction_completed
    mkdir_p "${DEST}/operations"
    mkdir_p "${DEST}/history"
    gen_operations_progress_corrupt
    write_file "${DEST}/operations/progress.md"
    gen_operations_history_in_progress
    write_file "${DEST}/history/operations.md"
    EXPECTED_PHASE="operations"
    EXPECTED_STEP_ID="undecidable:format_error"
    SPEC_REFS="spec§4;spec§5.operations.setup_done;spec§7;spec§8;spec§12"
}

# ケース分岐
case "$CASE" in
    normal-deploy-fresh) setup_normal_deploy_fresh ;;
    normal-deploy-progress) setup_normal_deploy_progress ;;
    normal-release) setup_normal_release ;;
    normal-completion) setup_normal_completion ;;
    bootstrap-from-construction) setup_bootstrap_from_construction ;;
    abnormal-operations_in_progress_missing_progress) setup_abnormal_operations_in_progress_missing_progress ;;
    abnormal-progress_corrupt) setup_abnormal_progress_corrupt ;;
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
