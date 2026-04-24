#!/usr/bin/env bash
#
# migrate-config.sh - config.toml 設定マイグレーション（自己完結版）
#
# 使用方法:
#   ./migrate-config.sh [--config <path>] [--rules <path>] [--dry-run]
#
# パラメータ:
#   --config <path>: config.toml のパス（デフォルト: .aidlc/config.toml）
#   --rules <path>: rules.md のパス（廃止設定の移行先参照用。config.toml の変更のみ行い、rules.md 自体は更新しない）
#   --dry-run: 実際の変更を行わず、実行予定の操作を表示
#
# 出力形式（stdout - 構造化メッセージ）:
#   - mode:{execute|dry-run}     : 実行モード
#   - config:{path}              : 対象ファイルパス
#   - migrate:<action>:<target>  : 実行された移行操作
#   - skip:<reason>:<target>     : スキップされた操作
#   - warn:<type>:<detail>       : 警告（ユーザー対応が必要）
#   - result:{status}:migrated={N},skipped={N},warnings={N} : 最終サマリ
#
# 出力（stderr）:
#   - 人間向け診断メッセージ（廃止設定の案内等）
#
# 終了コード:
#   0: 正常終了（警告があっても処理完了なら exit 0）
#   1: エラー（ファイル不在等）
#

set -euo pipefail

# --- パス解決（bootstrap.sh 非依存・自己完結） ---
# bootstrap.sh はスキル共通の初期化ライブラリ（AIDLC_PROJECT_ROOT等の環境変数を設定）だが、
# migrate-config.sh はセットアップ/マイグレーション用途で bootstrap.sh の初期化前に
# 実行される可能性があるため、パス解決を独自に行い自己完結させている。
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# プロジェクトルート解決（優先順位: 引数推定 → pwd → git rev-parse → エラー）
_resolve_project_root() {
    # 1. --config 引数からの推定（後で引数解析後に再評価）
    # 2. pwd に .aidlc/ が存在する場合
    if [[ -d "${PWD}/.aidlc" ]]; then
        echo "$PWD"
        return
    fi
    # 3. git rev-parse
    local git_root
    git_root="$(git rev-parse --show-toplevel 2>/dev/null)" || true
    if [[ -n "$git_root" ]]; then
        echo "$git_root"
        return
    fi
    # 4. 解決不可
    echo ""
}

PROJECT_ROOT="$(_resolve_project_root)"

# デフォルト値（引数解析で上書き可能）
CONFIG=""
RULES=""
DRY_RUN=false

# カウンタ
_migrate_count=0
_skip_count=0
_warn_count=0
_has_warnings=false
_cleanup_files=()

_cleanup() {
    for f in ${_cleanup_files[@]+"${_cleanup_files[@]}"}; do
        [[ -f "$f" ]] && \rm -f "$f"
    done
}
trap _cleanup EXIT

# 安全な一時ファイル作成（予測不能なファイル名）
_mktmp() {
    local tmp
    tmp=$(mktemp) || { echo "error:mktemp-failed"; exit 1; }
    _cleanup_files+=("$tmp")
    echo "$tmp"
}

# sed/awk → 一時ファイル → mv の安全なパターン
_safe_transform() {
    local target="$1"
    shift
    local tmp
    tmp=$(_mktmp)
    "$@" "$target" > "$tmp" && \mv "$tmp" "$target"
}

# カウント付き出力ヘルパー
_emit_migrate() {
    echo "migrate:$1"
    _migrate_count=$((_migrate_count + 1))
}

_emit_skip() {
    echo "skip:$1"
    _skip_count=$((_skip_count + 1))
}

_emit_warn() {
    echo "warn:$1"
    _warn_count=$((_warn_count + 1))
    _has_warnings=true
}

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            if [[ $# -lt 2 ]]; then
                echo "error:missing-config-value" >&2
                exit 1
            fi
            CONFIG="$2"
            shift 2
            ;;
        --rules)
            if [[ $# -lt 2 ]]; then
                echo "error:missing-rules-value" >&2
                exit 1
            fi
            RULES="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            echo "error:unknown-option" >&2
            exit 1
            ;;
    esac
done

# --config からプロジェクトルートを再推定（--config は常に最優先）
if [[ -n "$CONFIG" ]]; then
    _config_dirname="$(dirname "$CONFIG")"
    if [[ -d "$_config_dirname" ]]; then
        _config_dir="$(cd "$_config_dirname" && pwd)"
        # .aidlc/config.toml → .aidlc/ の親がプロジェクトルート
        if [[ "$(basename "$_config_dir")" == ".aidlc" ]]; then
            PROJECT_ROOT="$(cd "${_config_dir}/.." && pwd)"
        fi
    fi
fi

# プロジェクトルート必須チェック
if [[ -z "$PROJECT_ROOT" ]]; then
    echo "error:project-root-not-found" >&2
    exit 1
fi

# デフォルトパス設定
[[ -z "$CONFIG" ]] && CONFIG="${PROJECT_ROOT}/.aidlc/config.toml"
[[ -z "$RULES" ]] && RULES="${PROJECT_ROOT}/.aidlc/rules.md"

# ローカル設定ファイルパス
LOCAL_CONFIG="${PROJECT_ROOT}/.aidlc/config.local.toml"
LOCAL_CONFIG_LEGACY="${PROJECT_ROOT}/.aidlc/config.toml.local"

# config.toml 存在・シンボリックリンク確認
if [[ -L "$CONFIG" ]]; then
    echo "error:symlink-detected:config" >&2
    exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
    echo "error:config-not-found" >&2
    exit 1
fi

# dry-run 用の一時ファイル（実ファイルを変更しない）
if [[ "$DRY_RUN" == "true" ]]; then
    _tmp_config=$(_mktmp)
    \cp -f "$CONFIG" "$_tmp_config"
    _target="$_tmp_config"
    echo "mode:dry-run"
else
    _target="$CONFIG"
    echo "mode:execute"
fi

echo "config:${CONFIG}"

# --- v1旧設定ファイルのクリーンアップ ---
# .aidlc/config.toml が存在する場合、docs/aidlc.toml は不要（v1の旧パス）
_old_config="${PROJECT_ROOT}/docs/aidlc.toml"
if [[ -f "$_old_config" ]]; then
    if [[ "$DRY_RUN" == "true" ]]; then
        _emit_migrate "would-remove:docs/aidlc.toml(v1 legacy)"
    else
        rm -f "$_old_config"
        _emit_migrate "remove:docs/aidlc.toml(v1 legacy)"
    fi
fi

# --- セクション 7.4: 設定マイグレーション ---

# 1. [rules.mcp_review] → [rules.reviewing] リネーム移行
if grep -q "^\[rules\.mcp_review\]" "$_target"; then
    if grep -q "^\[rules\.reviewing\]" "$_target"; then
        # 両方存在: 旧セクションを削除
        _safe_transform "$_target" awk '/^\[rules\.mcp_review\]/{skip=1; next} /^\[[a-zA-Z]/{skip=0} !skip'
        _emit_migrate "remove-duplicate:rules.mcp_review"
    else
        # リネーム
        _safe_transform "$_target" sed 's/^\[rules\.mcp_review\]/[rules.reviewing]/'
        # ai_tools → tools リネーム
        _safe_transform "$_target" sed '/^\[rules\.reviewing\]/,/^\[/ {
          s/^ai_tools/tools/
        }'
        _emit_migrate "rename:rules.mcp_review->rules.reviewing"
    fi
    # オーバーライドファイルの旧キー警告
    for _override_file in "$HOME/.aidlc/config.toml" "${LOCAL_CONFIG}" "${LOCAL_CONFIG_LEGACY}"; do
        if [[ -f "$_override_file" ]] && grep -qE "mcp_review|ai_tools" "$_override_file"; then
            _emit_warn "override-old-keys:${_override_file}"
        fi
    done
else
    _emit_skip "not-found:rules.mcp_review"
fi

# 2. 不足セクション追加
_add_section() {
    local section_pattern="$1"
    local section_content="$2"

    if ! grep -q "^\\[${section_pattern}\\]" "$_target"; then
        printf '\n%s\n' "$section_content" >> "$_target"
        _emit_migrate "add-section:${section_pattern}"
    else
        _emit_skip "already-exists:${section_pattern}"
    fi
}

_add_section "rules\\.feedback" '[rules.feedback]
# フィードバック送信機能設定（v1.13.3で追加）
# enabled: true | false（デフォルト: true）
enabled = true'

_add_section "rules\\.reviewing" '[rules.reviewing]
# AIレビュー設定（v1.4.0で追加、v1.14.0でリネーム）
# mode: "recommend" | "required" | "disabled"
mode = "recommend"'

# [rules.backlog] は v2.0.3 で廃止。新規追加しない。
if grep -q "^\[rules\.backlog\]" "$_target" 2>/dev/null || grep -q "^\[backlog\]" "$_target" 2>/dev/null; then
    _emit_skip "deprecated:rules.backlog(v2.0.3: backlog is now always GitHub Issues)"
else
    _emit_skip "not-found:rules.backlog"
fi

_add_section "rules\\.linting" '[rules.linting]
# Markdown lint設定（v2.1.6でenabled/commandに統合）
# enabled: true | false - lintを実行するか（デフォルト: false）
enabled = false'

# [rules.linting] 内の markdown_lint → enabled リネーム（v2.2.0で追加）
if grep -q "^\[rules\.linting\]" "$_target" 2>/dev/null; then
    _old_key_count=$(sed -n '/^\[rules\.linting\]/,/^\[/p' "$_target" | { grep -c "^markdown_lint" || true; })
    _new_key_count=$(sed -n '/^\[rules\.linting\]/,/^\[/p' "$_target" | { grep -c "^enabled" || true; })
    if [[ "$_old_key_count" != "0" ]] && [[ "$_new_key_count" == "0" ]]; then
        _old_value=$(sed -n '/^\[rules\.linting\]/,/^\[/p' "$_target" | grep "^markdown_lint" | head -1 | sed 's/.*=[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//' | tr -d ' ')
        _safe_transform "$_target" awk -v val="$_old_value" '
/^\[rules\.linting\]/{in_sec=1}
in_sec && /^markdown_lint[[:space:]]*=/{print "enabled = " val; next}
/^\[/{if(in_sec && !/^\[rules\.linting\]/) in_sec=0}
{print}'
        _emit_migrate "rename:rules.linting.markdown_lint->rules.linting.enabled"
    fi
fi

_add_section "rules\\.release" '[rules.release]
# リリース設定（v2.1.6で追加）
# changelog: true | false - CHANGELOG自動更新（デフォルト: false）
# version_tag: true | false - gitタグ作成（デフォルト: false）
changelog = false
version_tag = false'

_add_section "rules\\.depth_level" '[rules.depth_level]
# 成果物詳細度設定（v1.19.0で追加）
# level: "minimal" | "standard" | "comprehensive"
level = "standard"
history_level = ""'

# [rules.history] → [rules.depth_level].history_level 統合（v2.1.8で統合）
if grep -q "^\[rules\.history\]" "$_target" 2>/dev/null; then
    _history_level=$(sed -n '/^\[rules\.history\]/,/^\[/p' "$_target" | grep "^level" | head -1 | sed 's/.*=[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//' | tr -d ' ')
    if [[ -n "$_history_level" ]]; then
        _hl_count=$(sed -n '/^\[rules\.depth_level\]/,/^\[/p' "$_target" | { grep -c "^history_level" || true; })
        if [[ "$_hl_count" == "0" ]]; then
            _safe_transform "$_target" awk -v val="$_history_level" '
/^\[rules\.depth_level\]/{in_sec=1}
in_sec && /^level[[:space:]]*=/{print; print "history_level = \"" val "\""; next}
/^\[/{if(in_sec && !/^\[rules\.depth_level\]/) in_sec=0}
{print}'
        fi
    fi
    # 旧セクション削除
    _safe_transform "$_target" awk '/^\[rules\.history\]/{skip=1; next} /^\[[a-zA-Z]/{skip=0} !skip'
    _emit_migrate "consolidate:rules.history->rules.depth_level.history_level"
fi

# 3. [rules.reviewing] に tools が存在しない場合は追加
if grep -q "^\[rules\.reviewing\]" "$_target"; then
    _tools_count=$(sed -n '/^\[rules\.reviewing\]/,/^\[/p' "$_target" | { grep -c "^tools" || true; })
    if [[ "$_tools_count" == "0" ]]; then
        _tmp_tools=$(_mktmp)
        if awk '
/^\[rules\.reviewing\]/{in_section=1}
in_section && /^mode[[:space:]]*=/{
    print
    print "tools = [\"codex\"]"
    next
}
/^\[/{if(in_section && !/^\[rules\.reviewing\]/) in_section=0}
{print}
' "$_target" > "$_tmp_tools" && \mv "$_tmp_tools" "$_target"; then
            if sed -n '/^\[rules\.reviewing\]/,/^\[/p' "$_target" | grep -q "^tools[[:space:]]*="; then
                _emit_migrate "add-key:rules.reviewing.tools"
            else
                _emit_warn "tools-insertion-unverified:rules.reviewing.tools"
            fi
        else
            _emit_warn "awk-failed:tools-addition"
        fi
    else
        _emit_skip "already-exists:rules.reviewing.tools"
    fi
else
    _emit_skip "section-not-found:rules.reviewing"
fi

_add_section "rules\\.automation" '[rules.automation]
# セミオート設定（v2.0.0で追加）
# mode: "manual" | "semi_auto"
mode = "manual"'

_add_section "rules\\.construction" '[rules.construction]
# Construction Phase設定（v2.0.0で追加）
# max_retry: Self-Healingループの最大リトライ回数（デフォルト: 3）
max_retry = 3'

_add_section "rules\\.cycle" '[rules.cycle]
# サイクル設定（v2.1.6で追加）
# mode: "default"
# git_tracked: true | false - cyclesをgit管理するか（デフォルト: true）
mode = "default"
git_tracked = true'

_add_section "rules\\.documentation" '[rules.documentation]
# ドキュメント設定（v2.1.8で追加）
language = "日本語"'

# --- [rules.github] GitHub 連携設定（v2.4.0で追加 / Unit 008 / #597 Unit G） ---

_add_section "rules\\.github" '[rules.github]
# GitHub 連携設定（v2.4.0で追加 / Unit 008 / #597 Unit G）
# milestone_enabled: true | false - GitHub Milestone 自動作成 / 紐付け / close を有効にするか（既定: false）
# - true: Inception Phase で自動作成、Operations Phase で自動 close
# - false: Milestone 関連ステップを全てスキップ（後方互換性確保のため既定は false）
milestone_enabled = false'

# --- [rules.git] 統合セクション（v2.1.8で統合） ---

_add_section "rules\\.git" '[rules.git]
# Git運用ルール（v2.1.8で統合）
commit_on_unit_complete = true
commit_on_phase_complete = true
branch_mode = "ask"
unit_branch_enabled = false
squash_enabled = false
ai_author = ""
ai_author_auto_detect = true'

# 旧セクション → [rules.git] 統合マイグレーション（v2.1.8で統合）
# [rules.commit] → rules.git.ai_author, rules.git.ai_author_auto_detect
# ヘルパー: セクション内にキーがなければ [section] 直後に追加
_add_key_to_section() {
    local section_pattern="$1"
    local key_name="$2"
    local key_line="$3"
    local _count
    _count=$(sed -n '/^\['"$section_pattern"'\]/,/^\[/p' "$_target" | { grep -c "^${key_name}" || true; })
    if [[ "$_count" == "0" ]]; then
        _safe_transform "$_target" awk -v line="$key_line" '
/^\['"$section_pattern"'\]/{print; print line; next}
{print}'
    fi
}

if grep -q "^\[rules\.commit\]" "$_target" 2>/dev/null; then
    _ai_author=$(sed -n '/^\[rules\.commit\]/,/^\[/p' "$_target" | grep "^ai_author[[:space:]]*=" | head -1 | sed 's/.*=[ \t]*//')
    if grep -q "^\[rules\.git\]" "$_target" && [[ -n "$_ai_author" ]]; then
        _add_key_to_section "rules\\.git" "ai_author[[:space:]]*=" "ai_author = $_ai_author"
    fi
    _safe_transform "$_target" awk '/^\[rules\.commit\]/{skip=1; next} /^\[[a-zA-Z]/{skip=0} !skip'
    _emit_migrate "consolidate:rules.commit->rules.git"
fi

# [rules.squash] → rules.git.squash_enabled
if grep -q "^\[rules\.squash\]" "$_target" 2>/dev/null; then
    _squash_val=$(sed -n '/^\[rules\.squash\]/,/^\[/p' "$_target" | grep "^enabled" | head -1 | sed 's/.*=[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//' | tr -d ' ')
    if grep -q "^\[rules\.git\]" "$_target" && [[ -n "$_squash_val" ]]; then
        _add_key_to_section "rules\\.git" "squash_enabled" "squash_enabled = $_squash_val"
    fi
    _safe_transform "$_target" awk '/^\[rules\.squash\]/{skip=1; next} /^\[[a-zA-Z]/{skip=0} !skip'
    _emit_migrate "consolidate:rules.squash->rules.git.squash_enabled"
fi

# [rules.unit_branch] → rules.git.unit_branch_enabled
if grep -q "^\[rules\.unit_branch\]" "$_target" 2>/dev/null; then
    _ub_val=$(sed -n '/^\[rules\.unit_branch\]/,/^\[/p' "$_target" | grep "^enabled" | head -1 | sed 's/.*=[[:space:]]*//' | sed 's/^["'"'"']//;s/["'"'"']$//' | tr -d ' ')
    if grep -q "^\[rules\.git\]" "$_target" && [[ -n "$_ub_val" ]]; then
        _add_key_to_section "rules\\.git" "unit_branch_enabled" "unit_branch_enabled = $_ub_val"
    fi
    _safe_transform "$_target" awk '/^\[rules\.unit_branch\]/{skip=1; next} /^\[[a-zA-Z]/{skip=0} !skip'
    _emit_migrate "consolidate:rules.unit_branch->rules.git.unit_branch_enabled"
fi

# [rules.worktree] は v2.1.8 で廃止。新規追加しない。
if grep -q "^\[rules\.worktree\]" "$_target" 2>/dev/null; then
    _emit_skip "deprecated:rules.worktree(v2.1.8: consolidated into rules.git.branch_mode)"
fi

# --- セクション 7.4.5: upgrade_check → version_check リネームマイグレーション ---

# 旧セクション [rules.upgrade_check] が存在する場合のリネーム処理
if grep -q "^\[rules\.upgrade_check\]" "$_target"; then
    if grep -q "^\[rules\.version_check\]" "$_target"; then
        # 新旧両方存在 → 旧セクションを削除（新セクションの値を優先）
        _safe_transform "$_target" awk '/^\[rules\.upgrade_check\]/{skip=1; next} /^\[[a-zA-Z]/{skip=0} !skip'
        _emit_migrate "remove-old:rules.upgrade_check(version_check優先)"
    else
        # 旧セクションのみ存在 → セクション名をリネーム（値は保持）
        _safe_transform "$_target" sed 's/^\[rules\.upgrade_check\]/[rules.version_check]/'
        _emit_migrate "rename:rules.upgrade_check->rules.version_check"
    fi
fi

# 新セクションが存在しない場合にデフォルト値で追加（新規インストール環境向け）
_add_section "rules\\.version_check" '[rules.version_check]
# バージョンチェック設定（v2.1.4でupgrade_checkからリネーム）
# enabled: true | false（デフォルト: true）
enabled = true'

# --- セクション 7.5: 廃止設定の検出 ---

# [inception.dependabot] 廃止設定検出
if grep -q "^\[inception\.dependabot\]" "$_target"; then
    _dep_enabled=$(sed -n '/^\[inception\.dependabot\]/,/^\[/p' "$_target" | grep "^enabled" | head -1 | sed 's/.*= *//' | tr -d ' "')
    if [[ "$_dep_enabled" == "true" ]]; then
        if [[ -f "$RULES" ]] && grep -q "## Dependabot PR確認" "$RULES" 2>/dev/null; then
            _emit_skip "already-migrated:inception.dependabot"
        else
            _emit_warn "deprecated-needs-manual:inception.dependabot"
            echo "[inception.dependabot の廃止] enabled=true が検出されました。" >&2
            echo "v1.13.0 以降、この機能はスターターキットから削除されました。" >&2
            echo "必要に応じて ${RULES} に手動で Dependabot PR 確認手順を追加してください。" >&2
        fi
    else
        _emit_skip "disabled:inception.dependabot"
    fi
else
    _emit_skip "not-found:inception.dependabot"
fi

# [rules.jj] 廃止設定検出
if grep -q "^\[rules\.jj\]" "$_target"; then
    _emit_warn "deprecated-config:rules.jj"
    echo "[jj設定の廃止] config.toml に [rules.jj] セクションが検出されました。" >&2
    echo "jjサポートは v1.21.0 でスターターキット本体から削除されました。" >&2
    echo "移行手順: ${SKILL_ROOT}/guides/jj-migration.md" >&2
    echo "[rules.jj] セクションは手動で削除してください。" >&2
else
    _emit_skip "not-found:rules.jj"
fi

# --- 終了サマリ ---
if [[ "$_has_warnings" == "true" ]]; then
    echo "result:completed-with-warnings:migrated=${_migrate_count},skipped=${_skip_count},warnings=${_warn_count}"
else
    echo "result:completed:migrated=${_migrate_count},skipped=${_skip_count},warnings=${_warn_count}"
fi
exit 0
