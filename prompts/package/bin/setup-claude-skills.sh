#!/bin/bash
# Claude Code スキルディレクトリのセットアップ
# .claude/skills/ を実ディレクトリとして作成し、各スキルへのシンボリックリンクを配置

set -euo pipefail

CLAUDE_SKILLS_DIR=".claude/skills"
AIDLC_SKILLS_DIR="docs/aidlc/skills"

# docs/aidlc/skills/ 配下のディレクトリを動的に取得
if [ ! -d "$AIDLC_SKILLS_DIR" ]; then
  echo "Error: $AIDLC_SKILLS_DIR not found"
  exit 1
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
    # 新規リンク作成
    ln -s "$TARGET_PATH" "$SKILL_PATH"
    echo "Created: $SKILL_PATH → $TARGET_PATH"

  elif [ -L "$SKILL_PATH" ]; then
    # シンボリックリンクの場合: ターゲット確認
    CURRENT_TARGET=$(readlink "$SKILL_PATH")
    if [ "$CURRENT_TARGET" = "$TARGET_PATH" ]; then
      echo "Skipped: $SKILL_PATH (already correct)"
    else
      echo "Warning: $SKILL_PATH points to different target"
      echo "  Current: $CURRENT_TARGET"
      echo "  Expected: $TARGET_PATH"
      echo "  Run with --force to overwrite"
    fi

  else
    # 実ディレクトリまたはファイルが存在 → スキップ
    echo "Skipped: $SKILL_PATH (exists as directory/file)"
  fi
done

echo "Done: $CLAUDE_SKILLS_DIR setup complete"
