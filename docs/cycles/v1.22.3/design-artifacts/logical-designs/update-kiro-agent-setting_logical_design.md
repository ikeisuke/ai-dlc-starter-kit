# 論理設計: Kiro agent設定のアップデート

## 概要

Issue #344で指定されたJSON設定をそのまま `.kiro/agents/aidlc-poc.json` に適用する。

## 変更内容

- `name`: `"aidlc-poc"` → `"aidlc"`
- `description`: 新規追加
- `tools`: `["read", "write", "shell"]` → `["@builtin"]`
- `allowedTools`: 新規追加（7項目）
- `toolsSettings`: 新規追加（execute_bash設定）
- `resources`: `[]` → `["file://AGENTS.md", "file://docs/aidlc/prompts/AGENTS.md"]`

## セキュリティ考慮

- `allowedCommands` で実行可能コマンドを正規表現パターンで制限
- `autoAllowReadonly: true` で読み取り専用は自動許可（書き込み操作は明示的許可が必要）
