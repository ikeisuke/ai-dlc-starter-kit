#!/bin/bash
# AIツール設定のセットアップ
# - Claude Code: .claude/skills/ に各スキルへのシンボリックリンクを配置
# - KiroCLI: .kiro/skills/ に各スキルへのシンボリックリンクを配置
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
# $1: ターゲットディレクトリ（例: .claude/skills, .kiro/skills）
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
# KiroCLI スキルのセットアップ
# ============================================
setup_kiro_skills() {
  setup_skill_symlinks ".kiro/skills" "$AIDLC_DIR/skills"
  echo "Done: KiroCLI skills setup complete"
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
# メイン処理
# ============================================
echo "=== AI Tools Setup ==="
echo ""

echo "[1/3] Setting up Claude Code skills..."
setup_claude_skills
echo ""

echo "[2/3] Setting up KiroCLI skills..."
setup_kiro_skills
echo ""

echo "[3/3] Setting up KiroCLI agent..."
setup_kiro_agent
echo ""

echo "=== Setup Complete ==="
