# git worktree を活用したワークフローの提案

- **発見日**: 2025-12-08
- **発見フェーズ**: Operations
- **発見サイクル**: v1.2.3
- **対応サイクル**: v1.4.0
- **完了日**: 2025-12-14
- **優先度**: 低

## 概要

git worktree を使って複数サイクルを並行作業できるようにする提案

## 対応内容

- setup-cycle.md に worktree 提案機能を追加
- aidlc.toml に [rules.worktree] セクション追加（デフォルト: disabled）
- worktree 作成手順の案内を実装

## 成果物

- Unit 6: git worktree提案機能追加
