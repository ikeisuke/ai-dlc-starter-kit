# AI-DLCプロンプト内の複合コマンド削減

- **発見日**: 2026-01-10
- **発見フェーズ**: Construction
- **発見サイクル**: v1.7.0
- **優先度**: 低

## 概要

AI-DLCプロンプト内で使用されている複合コマンド（`&&`, `||` 等）を削減し、許可リスト運用時の承認回数を減らす。

## 詳細

現在のAI-DLCプロンプト（construction.md, operations.md等）では複合コマンドが多用されている。

**例**:
- `git diff --quiet && git diff --cached --quiet || git add -A && git commit -m "..."`
- `if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then ... fi`

これらは許可リストで許可しても、シェル演算子を含むため都度承認が必要になる。

## 対応案

1. 複合コマンドを単一コマンドに分解
2. または、sandbox環境での実行を前提とする（別バックログ参照）

## 関連

- Unit 002: AIエージェント許可リストガイド
- chore-sandbox-environment-guide.md
