#!/bin/bash
# AIツール設定のセットアップ
# - Claude Code: .claude/skills/ に各スキルへのシンボリックリンクを配置
# - Agent: .agents/skills/ に各スキルへのシンボリックリンクを配置
# - KiroCLI: .kiro/agents/aidlc.json へのシンボリックリンクを配置

set -euo pipefail

AIDLC_DIR="docs/aidlc"

# docs/aidlc/ の存在確認
if [ ! -d "$AIDLC_DIR" ]; then
  echo "Error: $AIDLC_DIR not found"
  exit 1
fi

# ============================================
# 共通関数: スキルシンボリックリンクのセットアップ
# ============================================
# $1: ターゲットディレクトリ（例: .claude/skills, .agents/skills）
# $2: ソースディレクトリ（例: docs/aidlc/skills）
setup_skill_symlinks() {
  local TARGET_DIR="$1"
  local SOURCE_DIR="$2"

  if [ ! -d "$SOURCE_DIR" ]; then
    echo "Warning: $SOURCE_DIR not found, skipping"
    return
  fi

  # 空ディレクトリでのglob展開失敗を防止
  local _prev_nullglob
  _prev_nullglob=$(shopt -p nullglob || true)
  shopt -s nullglob

  # ターゲットディレクトリの親を作成
  mkdir -p "$(dirname "$TARGET_DIR")"

  # ターゲットがシンボリックリンクの場合は削除してディレクトリ化（旧形式からの移行）
  if [ -L "$TARGET_DIR" ]; then
    echo "Removed: $TARGET_DIR (symlink → converting to directory)"
    rm "$TARGET_DIR"
  fi

  # ターゲットディレクトリ作成
  mkdir -p "$TARGET_DIR"

  # 壊れたシンボリックリンクを削除（リンク先が存在しないもの）
  for link in "$TARGET_DIR"/*; do
    if [ -L "$link" ] && [ ! -e "$link" ]; then
      echo "Removed: $link (broken symlink)"
      rm "$link"
    fi
  done

  # ソースディレクトリ内の各スキルへのシンボリックリンクを作成
  for skill_path in "$SOURCE_DIR"/*/; do
    local skill
    skill=$(basename "$skill_path")
    local SKILL_PATH="$TARGET_DIR/$skill"
    local LINK_TARGET="../../$SOURCE_DIR/$skill"

    # SKILL.md 存在チェック
    if [ ! -f "$skill_path/SKILL.md" ]; then
      echo "Warning: $skill_path has no SKILL.md, skipping"
      continue
    fi

    if [ ! -e "$SKILL_PATH" ]; then
      ln -s "$LINK_TARGET" "$SKILL_PATH"
      echo "Created: $SKILL_PATH → $LINK_TARGET"

    elif [ -L "$SKILL_PATH" ]; then
      local CURRENT_TARGET
      CURRENT_TARGET=$(readlink "$SKILL_PATH")
      if [ "$CURRENT_TARGET" = "$LINK_TARGET" ]; then
        echo "Skipped: $SKILL_PATH (already correct)"
      else
        # 不正なリンク先 → 自己修復
        rm "$SKILL_PATH"
        ln -s "$LINK_TARGET" "$SKILL_PATH"
        echo "Fixed: $SKILL_PATH (target corrected)"
      fi

    else
      echo "Warning: $SKILL_PATH (exists as directory/file, cannot replace)"
    fi
  done

  # nullglob を元に戻す
  eval "$_prev_nullglob"
}

# ============================================
# Claude Code スキルのセットアップ
# ============================================
setup_claude_skills() {
  setup_skill_symlinks ".claude/skills" "$AIDLC_DIR/skills"
  echo "Done: Claude skills setup complete"
}

# ============================================
# Agent スキルのセットアップ
# ============================================
setup_agent_skills() {
  setup_skill_symlinks ".agents/skills" "$AIDLC_DIR/skills"
  echo "Done: Agent skills setup complete"
}

# ============================================
# KiroCLI エージェントのセットアップ
# ============================================
setup_kiro_agent() {
  local KIRO_AGENTS_DIR=".kiro/agents"
  local AIDLC_KIRO_AGENT="$AIDLC_DIR/kiro/agents/aidlc.json"

  if [ ! -f "$AIDLC_KIRO_AGENT" ]; then
    echo "Warning: $AIDLC_KIRO_AGENT not found, skipping KiroCLI setup"
    return
  fi

  # .kiro/agents ディレクトリ作成
  mkdir -p "$KIRO_AGENTS_DIR"

  local AGENT_PATH="$KIRO_AGENTS_DIR/aidlc.json"
  local TARGET_PATH="../../$AIDLC_KIRO_AGENT"

  if [ ! -e "$AGENT_PATH" ]; then
    ln -s "$TARGET_PATH" "$AGENT_PATH"
    echo "Created: $AGENT_PATH → $TARGET_PATH"

  elif [ -L "$AGENT_PATH" ]; then
    local CURRENT_TARGET
    CURRENT_TARGET=$(readlink "$AGENT_PATH")
    if [ "$CURRENT_TARGET" = "$TARGET_PATH" ]; then
      echo "Skipped: $AGENT_PATH (already correct)"
    else
      # 不正なリンク先 → 自己修復
      rm "$AGENT_PATH"
      ln -s "$TARGET_PATH" "$AGENT_PATH"
      echo "Fixed: $AGENT_PATH (target corrected)"
    fi

  else
    echo "Warning: $AGENT_PATH (exists as file, cannot replace)"
  fi

  echo "Done: KiroCLI agent setup complete"
}

# ============================================
# Claude Code 許可パターンのセットアップ
# ============================================

# JSON状態判定
# $1: ファイルパス
# stdout: absent / valid / invalid / unknown
_detect_json_state() {
  local file_path="$1"

  if [ ! -f "$file_path" ]; then
    echo "absent"
    return
  fi

  # jq で検証（優先）
  if command -v jq >/dev/null 2>&1; then
    if jq . "$file_path" >/dev/null 2>&1; then
      echo "valid"
    else
      echo "invalid"
    fi
    return
  fi

  # python3 で検証（フォールバック）
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$file_path" 2>/dev/null; then
      echo "valid"
    else
      echo "invalid"
    fi
    return
  fi

  # jq・python3 ともに不在
  echo "unknown"
}

# テンプレートJSON生成
# stdout: JSON文字列
_generate_template() {
  cat <<'TEMPLATE_EOF'
{
  "permissions": {
    "allow": [
      "Bash(docs/aidlc/bin/:*)",
      "Bash(mktemp /tmp/aidlc-commit-msg.XXXXXX)",
      "Bash(mktemp /tmp/aidlc-squash-msg.XXXXXX)",
      "Bash(mktemp /tmp/aidlc-history-content.XXXXXX)",
      "Bash(mktemp /tmp/aidlc-pr-body.XXXXXX)",
      "Bash(mktemp /tmp/aidlc-review-input.XXXXXX)",
      "Skill(reviewing-architecture)",
      "Skill(reviewing-code)",
      "Skill(reviewing-security)",
      "Skill(reviewing-inception)",
      "Skill(squash-unit)",
      "Skill(aidlc-setup)"
    ]
  }
}
TEMPLATE_EOF
}

# 原子的書き込み
# $1: ターゲットパス
# stdin: 書き込み内容
# 戻り値: 0=成功, 1=失敗
_write_atomic() {
  local target_path="$1"
  local tmp_file

  mkdir -p "$(dirname "$target_path")"
  tmp_file=$(mktemp "$(dirname "$target_path")/.settings.json.tmp.XXXXXX") || return 1

  if cat > "$tmp_file" 2>/dev/null; then
    if \mv "$tmp_file" "$target_path" 2>/dev/null; then
      return 0
    fi
  fi

  # 失敗時: テンポラリファイルを削除
  \rm -f "$tmp_file" 2>/dev/null
  return 1
}

# パターンマージ（jq版）
# $1: 既存JSONファイルパス
# stdout: マージ済みJSON文字列
# 戻り値: 0=新規パターンあり, 1=全て既存, 2=エラー
_merge_permissions_jq() {
  local existing_file="$1"
  local template_defaults
  template_defaults=$(_generate_template | jq '.permissions.allow') || return 2

  local merged
  merged=$(jq --argjson defaults "$template_defaults" '
    .permissions //= {} |
    .permissions.allow //= [] |
    .permissions.allow as $existing |
    ($defaults - $existing) as $new |
    if ($new | length) > 0 then
      .permissions.allow += $new |
      . + {"_new_count": ($new | length)}
    else
      . + {"_new_count": 0}
    end
  ' "$existing_file") || return 2

  local new_count
  new_count=$(echo "$merged" | jq -r '._new_count') || return 2
  merged=$(echo "$merged" | jq 'del(._new_count)') || return 2

  echo "$merged"
  if [ "$new_count" -gt 0 ]; then
    echo "$new_count" >&2
    return 0
  else
    return 1
  fi
}

# パターンマージ（python3版）
# $1: 既存JSONファイルパス
# stdout: マージ済みJSON文字列
# 戻り値: 0=新規パターンあり, 1=全て既存, 2=エラー
_merge_permissions_python() {
  local existing_file="$1"
  local template_json
  template_json=$(_generate_template) || return 2

  python3 -c "
import json, sys

try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    defaults = json.loads(sys.argv[2])['permissions']['allow']
    if not isinstance(defaults, list):
        sys.exit(2)

    if 'permissions' not in data:
        data['permissions'] = {}
    if 'allow' not in data['permissions']:
        data['permissions']['allow'] = []
    if not isinstance(data['permissions']['allow'], list):
        sys.exit(2)

    existing = data['permissions']['allow']
    existing_set = set(existing)
    new_patterns = [p for p in defaults if p not in existing_set]

    if new_patterns:
        data['permissions']['allow'].extend(new_patterns)
        print(json.dumps(data, indent=2, ensure_ascii=False))
        print(len(new_patterns), file=sys.stderr)
        sys.exit(0)
    else:
        print(json.dumps(data, indent=2, ensure_ascii=False))
        sys.exit(1)
except SystemExit:
    raise
except Exception:
    sys.exit(2)
" "$existing_file" "$template_json"
}

setup_claude_permissions() {
  local SETTINGS_FILE=".claude/settings.json"
  local result=""
  local new_count=""

  # JSON状態判定
  local state
  state=$(_detect_json_state "$SETTINGS_FILE")

  case "$state" in
    absent)
      # テンプレートJSON新規作成
      if _generate_template | _write_atomic "$SETTINGS_FILE"; then
        echo "Created: $SETTINGS_FILE (default permissions)"
        result="created"
      else
        echo "Warning: Failed to write $SETTINGS_FILE, skipping"
        result="failed"
      fi
      ;;

    invalid)
      # バックアップ＋テンプレートJSON新規作成
      if ! \cp "$SETTINGS_FILE" "${SETTINGS_FILE}.bak" 2>/dev/null; then
        echo "Warning: Failed to backup $SETTINGS_FILE, skipping"
        result="failed"
      else
        echo "Backup: $SETTINGS_FILE → ${SETTINGS_FILE}.bak (invalid JSON)"
        if _generate_template | _write_atomic "$SETTINGS_FILE"; then
          echo "Created: $SETTINGS_FILE (default permissions)"
          result="created"
        else
          echo "Warning: Failed to write $SETTINGS_FILE, skipping"
          result="failed"
        fi
      fi
      ;;

    unknown)
      echo "Warning: jq/python3 not found, cannot validate/update existing $SETTINGS_FILE"
      result="degraded"
      ;;

    valid)
      # マージツール利用可否チェック
      local merge_count_file
      if command -v jq >/dev/null 2>&1; then
        merge_count_file=$(mktemp /tmp/aidlc-merge-count.XXXXXX)
        local merged_json merge_rc
        merged_json=$(_merge_permissions_jq "$SETTINGS_FILE" 2>"$merge_count_file") && merge_rc=0 || merge_rc=$?

        case $merge_rc in
          0)
            new_count=$(cat "$merge_count_file" 2>/dev/null)
            \rm -f "$merge_count_file" 2>/dev/null
            if echo "$merged_json" | _write_atomic "$SETTINGS_FILE"; then
              echo "Updated: $SETTINGS_FILE ($new_count new permissions added)"
              result="updated"
            else
              echo "Warning: Failed to write $SETTINGS_FILE, skipping"
              result="failed"
            fi
            ;;
          1)
            \rm -f "$merge_count_file" 2>/dev/null
            echo "Skipped: $SETTINGS_FILE (all permissions already present)"
            result="skipped"
            ;;
          *)
            \rm -f "$merge_count_file" 2>/dev/null
            echo "Warning: Failed to merge permissions for $SETTINGS_FILE, skipping"
            result="failed"
            ;;
        esac

      elif command -v python3 >/dev/null 2>&1; then
        merge_count_file=$(mktemp /tmp/aidlc-merge-count.XXXXXX)
        local merged_json merge_rc
        merged_json=$(_merge_permissions_python "$SETTINGS_FILE" 2>"$merge_count_file") && merge_rc=0 || merge_rc=$?

        case $merge_rc in
          0)
            new_count=$(cat "$merge_count_file" 2>/dev/null)
            \rm -f "$merge_count_file" 2>/dev/null
            if echo "$merged_json" | _write_atomic "$SETTINGS_FILE"; then
              echo "Updated: $SETTINGS_FILE ($new_count new permissions added)"
              result="updated"
            else
              echo "Warning: Failed to write $SETTINGS_FILE, skipping"
              result="failed"
            fi
            ;;
          1)
            \rm -f "$merge_count_file" 2>/dev/null
            echo "Skipped: $SETTINGS_FILE (all permissions already present)"
            result="skipped"
            ;;
          *)
            \rm -f "$merge_count_file" 2>/dev/null
            echo "Warning: Failed to merge permissions for $SETTINGS_FILE, skipping"
            result="failed"
            ;;
        esac

      else
        echo "Warning: jq/python3 not found, cannot update existing $SETTINGS_FILE"
        result="degraded"
      fi
      ;;
  esac

  echo "Done: Claude permissions setup complete"
  echo "result:${result}"

  # 失敗時は非ゼロを返し、set -e によりスクリプト全体を終了させる。
  # 呼び出し元 (_run_setup_ai_tools) が set +e で exit code を検出する。
  case "$result" in
    created|updated|skipped|degraded) return 0 ;;
    *) return 1 ;;  # failed および未知値
  esac
}

# ============================================
# メイン処理
# ============================================
echo "=== AI Tools Setup ==="
echo ""

echo "[1/4] Setting up Claude Code skills..."
setup_claude_skills
echo ""

echo "[2/4] Setting up Agent skills..."
setup_agent_skills
echo ""

echo "[3/4] Setting up KiroCLI agent..."
setup_kiro_agent
echo ""

echo "[4/4] Setting up Claude Code permissions..."
setup_claude_permissions
echo ""

echo "=== Setup Complete ==="
