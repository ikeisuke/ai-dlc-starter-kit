#!/usr/bin/env bash
#
# migrate-config.sh - aidlc.toml 設定マイグレーション
#
# 使用方法:
#   ./migrate-config.sh [--config <path>] [--rules <path>] [--dry-run]
#
# パラメータ:
#   --config <path>: aidlc.toml のパス（デフォルト: docs/aidlc.toml）
#   --rules <path>: rules.md のパス（デフォルト: docs/cycles/rules.md）
#   --dry-run: 実際の変更を行わず、実行予定の操作を表示
#
# 出力形式:
#   - migrate:<action>:<target> : 実行された移行操作
#   - skip:<reason>:<target>   : スキップされた操作
#   - warn:<type>:<detail>     : 警告（ユーザー対応が必要）
#   - error:<type>             : エラー
#
# 終了コード:
#   0: 正常終了（全マイグレーション完了）
#   1: エラー（ファイル不在等）
#   2: 正常終了だがユーザー対応が必要な警告あり
#

set -euo pipefail

CONFIG="docs/aidlc.toml"
RULES="docs/cycles/rules.md"
DRY_RUN=false
_has_warnings=false
_cleanup_files=()

_cleanup() {
    for f in "${_cleanup_files[@]}"; do
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

# 引数解析
while [[ $# -gt 0 ]]; do
    case $1 in
        --config)
            if [[ $# -lt 2 ]]; then
                echo "error:missing-config-value"
                exit 1
            fi
            CONFIG="$2"
            shift 2
            ;;
        --rules)
            if [[ $# -lt 2 ]]; then
                echo "error:missing-rules-value"
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
            echo "error:unknown-option"
            exit 1
            ;;
    esac
done

# aidlc.toml 存在・シンボリックリンク確認
if [[ -L "$CONFIG" ]]; then
    echo "error:symlink-detected:config"
    exit 1
fi
if [[ ! -f "$CONFIG" ]]; then
    echo "error:config-not-found"
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

# --- セクション 7.4: 設定マイグレーション ---

# 1. [rules.mcp_review] → [rules.reviewing] リネーム移行
if grep -q "^\[rules\.mcp_review\]" "$_target"; then
    if grep -q "^\[rules\.reviewing\]" "$_target"; then
        # 両方存在: 旧セクションを削除
        _safe_transform "$_target" awk '/^\[rules\.mcp_review\]/{skip=1; next} /^\[[a-zA-Z]/{skip=0} !skip'
        echo "migrate:remove-duplicate:rules.mcp_review"
    else
        # リネーム
        _safe_transform "$_target" sed 's/^\[rules\.mcp_review\]/[rules.reviewing]/'
        # ai_tools → tools リネーム
        _safe_transform "$_target" sed '/^\[rules\.reviewing\]/,/^\[/ {
          s/^ai_tools/tools/
        }'
        echo "migrate:rename:rules.mcp_review->rules.reviewing"
    fi
    # オーバーライドファイルの旧キー警告
    for _override_file in "$HOME/.aidlc/config.toml" "docs/aidlc.toml.local"; do
        if [[ -f "$_override_file" ]] && grep -qE "mcp_review|ai_tools" "$_override_file"; then
            echo "warn:override-old-keys:${_override_file}"
            _has_warnings=true
        fi
    done
else
    echo "skip:not-found:rules.mcp_review"
fi

# 2. 不足セクション追加
_add_section() {
    local section_pattern="$1"
    local section_content="$2"

    if ! grep -q "^\\[${section_pattern}\\]" "$_target"; then
        printf '\n%s\n' "$section_content" >> "$_target"
        echo "migrate:add-section:${section_pattern}"
    else
        echo "skip:already-exists:${section_pattern}"
    fi
}

_add_section "rules\\.reviewing" '[rules.reviewing]
# AIレビュー設定（v1.4.0で追加、v1.14.0でリネーム）
# mode: "recommend" | "required" | "disabled"
# - recommend: AIレビューツール利用可能時にレビューを推奨（デフォルト）
# - required: AIレビューツール利用可能時にレビュー必須
# - disabled: レビュー推奨を無効化
mode = "recommend"'

_add_section "rules\\.worktree" '[rules.worktree]
# git worktree設定（v1.4.0で追加）
# enabled: true | false
# - true: サイクル開始時にworktreeの使用を提案する
# - false: 提案しない（デフォルト）
enabled = false'

_add_section "rules\\.history" '[rules.history]
# 履歴記録設定（v1.5.1で追加）
# level: "detailed" | "standard" | "minimal"
# - detailed: ステップ完了時に記録 + 修正差分も記録
# - standard: ステップ完了時に記録（デフォルト）
# - minimal: Unit完了時にまとめて記録
level = "standard"'

# [rules.backlog] は旧[backlog]からの値引き継ぎロジック付き
if ! grep -q "^\[rules\.backlog\]" "$_target"; then
    _old_backlog_mode=""
    if grep -q "^\[backlog\]" "$_target" 2>/dev/null; then
        _old_backlog_mode=$(sed -n '/^\[backlog\]/,/^\[/p' "$_target" | grep -E '^[[:space:]]*mode[[:space:]]*=' | head -1 | sed "s/^[^=]*=[[:space:]]*//;s/[[:space:]]*#.*//;s/^[\"']//;s/[\"']$//" || echo "")
    fi
    # 有効値バリデーション
    case "$_old_backlog_mode" in
        git|issue|git-only|issue-only) ;;
        *) _old_backlog_mode="" ;;
    esac
    _backlog_mode="${_old_backlog_mode:-issue-only}"
    cat >> "$_target" << EOF

[rules.backlog]
# バックログ管理モード設定（v1.7.0で追加、v1.10.0でデフォルト変更、v1.16.2で[backlog]から移動）
# mode: "git" | "issue" | "git-only" | "issue-only"
# - git: ローカルファイルがデフォルト、状況に応じてIssueも許容
# - issue: GitHub Issueがデフォルト、状況に応じてローカルも許容
# - git-only: ローカルファイルのみ（Issueへの記録を禁止）
# - issue-only: GitHub Issueのみ（ローカルファイルへの記録を禁止）（デフォルト）
mode = "${_backlog_mode}"
EOF
    if [[ -n "$_old_backlog_mode" ]]; then
        echo "migrate:add-section:rules.backlog(inherited:${_old_backlog_mode})"
    else
        echo "migrate:add-section:rules.backlog(default:issue-only)"
    fi
else
    echo "skip:already-exists:rules.backlog"
fi

_add_section "rules\\.jj" '[rules.jj]
# jjサポート設定（v1.7.2で追加）
# enabled: true | false
# - true: プロンプト内でjj-support.md参照を案内
# - false: 従来のgitコマンドを使用（デフォルト）
enabled = false'

_add_section "rules\\.linting" '[rules.linting]
# markdownlint設定（v1.8.0で追加）
# markdown_lint: true | false
# - true: markdownlint を実行する
# - false: markdownlint をスキップする（デフォルト）
markdown_lint = false'

# 3. [rules.reviewing] に tools が存在しない場合は追加（awk で BSD/GNU 互換）
if grep -q "^\[rules\.reviewing\]" "$_target"; then
    _tools_count=$(sed -n '/^\[rules\.reviewing\]/,/^\[/p' "$_target" | { grep -c "^tools" || true; })
    if [[ "$_tools_count" == "0" ]]; then
        _tmp_tools=$(_mktmp)
        awk '
/^\[rules\.reviewing\]/{in_section=1}
in_section && /^mode = /{
    print
    print "# tools: AIレビューに使用するツールの優先順位リスト（v1.8.2で追加、v1.14.0でリネーム）"
    print "# - デフォルト: [\"codex\"]"
    print "# - 例: [\"codex\", \"claude\", \"gemini\"]"
    print "# - リスト先頭を優先ツールヒントとしてスキルに渡す（最終選択はスキル内部の責務）"
    print "tools = [\"codex\"]"
    next
}
/^\[/{if(in_section && !/^\[rules\.reviewing\]/) in_section=0}
{print}
' "$_target" > "$_tmp_tools" && \mv "$_tmp_tools" "$_target" || {
            echo "warn:awk-failed:tools-addition"
            _has_warnings=true
        }
        echo "migrate:add-key:rules.reviewing.tools"
    else
        echo "skip:already-exists:rules.reviewing.tools"
    fi
else
    echo "skip:section-not-found:rules.reviewing"
fi

_add_section "rules\\.commit" '[rules.commit]
# コミット設定（v1.9.1で追加）
# ai_author: Co-Authored-By に使用するAI著者情報
# - 形式: "ツール名 <email>"（推奨）または任意の文字列
# - デフォルト: "Claude <noreply@anthropic.com>"
ai_author = "Claude <noreply@anthropic.com>"'

# --- セクション 7.5: 廃止設定の移行 ---

if grep -q "^\[inception\.dependabot\]" "$_target"; then
    _dep_enabled=$(sed -n '/^\[inception\.dependabot\]/,/^\[/p' "$_target" | grep "^enabled" | head -1 | sed 's/.*= *//' | tr -d ' "')
    if [[ "$_dep_enabled" == "true" ]]; then
        if [[ -f "$RULES" ]] && grep -q "## Dependabot PR確認" "$RULES" 2>/dev/null; then
            echo "skip:already-migrated:inception.dependabot"
        else
            if [[ "$DRY_RUN" == "true" ]]; then
                echo "migrate:deprecate:inception.dependabot->rules.md"
            else
                if [[ -L "$RULES" ]]; then
                    echo "warn:symlink-detected:rules"
                    _has_warnings=true
                elif [[ -f "$RULES" ]]; then
                    cat >> "$RULES" << 'RULES_EOF'

---

## Dependabot PR確認（v1.13.0で廃止された機能）

このプロジェクトでは以前 Dependabot PR 確認機能を使用していました。
v1.13.0 以降、この機能はスターターキットから削除されましたが、
必要に応じて以下のワークフローを手動で実行できます。

### 手動確認手順

```bash
# オープンな Dependabot PR を一覧表示
gh pr list --author "app/dependabot" --state open
```

### 推奨対応

1. Inception Phase 開始時に上記コマンドで Dependabot PR を確認
2. 対応が必要な PR がある場合、ユーザーストーリーと Unit 定義に追加
RULES_EOF
                    echo "migrate:deprecate:inception.dependabot->rules.md"
                else
                    echo "warn:rules-not-found"
                    _has_warnings=true
                fi
            fi
        fi
    else
        echo "skip:disabled:inception.dependabot"
    fi
else
    echo "skip:not-found:inception.dependabot"
fi

# 終了コード判定
if [[ "$_has_warnings" == "true" ]]; then
    exit 2
fi
exit 0
