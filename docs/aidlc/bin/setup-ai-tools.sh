#!/bin/bash
# AIツール設定のセットアップ
# - Claude Code: .claude/skills/ に各スキルへのシンボリックリンクを配置
# - KiroCLI: .kiro/agents/aidlc.json へのシンボリックリンクを配置

set -euo pipefail

AIDLC_DIR="docs/aidlc"

# docs/aidlc/ の存在確認
if [ ! -d "$AIDLC_DIR" ]; then
  echo "Error: $AIDLC_DIR not found"
  exit 1
fi

# ============================================
# Claude Code スキルのセットアップ
# ============================================
setup_claude_skills() {
  local CLAUDE_SKILLS_DIR=".claude/skills"
  local AIDLC_SKILLS_DIR="$AIDLC_DIR/skills"

  if [ ! -d "$AIDLC_SKILLS_DIR" ]; then
    echo "Warning: $AIDLC_SKILLS_DIR not found, skipping Claude skills setup"
    return
  fi

  # 親ディレクトリ作成
  mkdir -p .claude

  # .claude/skills がシンボリックリンクの場合は削除（旧形式からの移行）
  if [ -L "$CLAUDE_SKILLS_DIR" ]; then
    echo "移行: $CLAUDE_SKILLS_DIR シンボリックリンクを削除してディレクトリ化します"
    rm "$CLAUDE_SKILLS_DIR"
  fi

  # .claude/skills ディレクトリ作成
  mkdir -p "$CLAUDE_SKILLS_DIR"

  # 各スキルへのシンボリックリンクを作成
  for skill_path in "$AIDLC_SKILLS_DIR"/*/; do
    skill=$(basename "$skill_path")
    SKILL_PATH="$CLAUDE_SKILLS_DIR/$skill"
    TARGET_PATH="../../$AIDLC_SKILLS_DIR/$skill"

    if [ ! -e "$SKILL_PATH" ]; then
      ln -s "$TARGET_PATH" "$SKILL_PATH"
      echo "Created: $SKILL_PATH → $TARGET_PATH"

    elif [ -L "$SKILL_PATH" ]; then
      CURRENT_TARGET=$(readlink "$SKILL_PATH")
      if [ "$CURRENT_TARGET" = "$TARGET_PATH" ]; then
        echo "Skipped: $SKILL_PATH (already correct)"
      else
        echo "Warning: $SKILL_PATH points to different target"
        echo "  Current: $CURRENT_TARGET"
        echo "  Expected: $TARGET_PATH"
      fi

    else
      echo "Skipped: $SKILL_PATH (exists as directory/file)"
    fi
  done

  echo "Done: Claude skills setup complete"
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
    CURRENT_TARGET=$(readlink "$AGENT_PATH")
    if [ "$CURRENT_TARGET" = "$TARGET_PATH" ]; then
      echo "Skipped: $AGENT_PATH (already correct)"
    else
      echo "Warning: $AGENT_PATH points to different target"
      echo "  Current: $CURRENT_TARGET"
      echo "  Expected: $TARGET_PATH"
    fi

  else
    echo "Skipped: $AGENT_PATH (exists as file, not symlink)"
  fi

  echo "Done: KiroCLI agent setup complete"
}

# ============================================
# メイン処理
# ============================================
echo "=== AI Tools Setup ==="
echo ""

echo "[1/2] Setting up Claude Code skills..."
setup_claude_skills
echo ""

echo "[2/2] Setting up KiroCLI agent..."
setup_kiro_agent
echo ""

echo "=== Setup Complete ==="
