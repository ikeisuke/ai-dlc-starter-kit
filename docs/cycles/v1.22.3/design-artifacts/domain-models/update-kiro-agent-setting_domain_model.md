# ドメインモデル: Kiro agent設定のアップデート

## 概要

`.kiro/agents/aidlc-poc.json` の設定構造を定義する。

## エンティティ: KiroAgentConfig

- **name**: `"aidlc"` - エージェント識別名
- **description**: エージェントの説明文
- **tools**: `["@builtin"]` - 使用ツールセット
- **allowedTools**: 明示的に許可するツール一覧（fs_read, grep, glob, code, thinking, todo_list, knowledge）
- **toolsSettings.execute_bash**: Bash実行の設定
  - **allowedCommands**: 正規表現パターンで許可コマンドを制限
  - **autoAllowReadonly**: `true` で読み取り専用コマンドを自動許可
- **resources**: エージェントが参照するリソースファイル（AGENTS.md）
