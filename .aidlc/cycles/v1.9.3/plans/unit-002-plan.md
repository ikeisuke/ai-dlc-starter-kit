# Unit 002 計画: kiroエージェント設定修正

## 概要

AGENTS.md 内の KiroCLI エージェント設定例を、KiroCLI公式ドキュメントに基づいた正確な内容に修正する。

## 変更対象ファイル

- `prompts/package/prompts/AGENTS.md`
- `prompts/setup-prompt.md`（同一の設定例があるため同時修正）

## 問題点

現在の設定:
```json
{
  "tools": ["read", "write", "shell"],
  ...
}
```

- `tools` を個別に列挙しており、必要なツールが不足している
- `@builtin` を使えば全組み込みツールを一括指定できる

## 修正内容

### toolsの更新

```json
{
  "tools": ["@builtin"],
  ...
}
```

`@builtin` により以下の全組み込みツールが利用可能になる:
- `read`, `write`, `shell`, `glob`, `grep`, `web_search`, `web_fetch`, `use_subagent` など

### 修正後の完全な設定例

```json
{
  "name": "aidlc",
  "description": "AI-DLC開発支援エージェント。AGENTS.mdの指示に従い開発を進めます。Codex、Claude、Gemini CLIを呼び出してコードレビューや分析も実行できます。",
  "tools": ["@builtin"],
  "resources": [
    "file://AGENTS.md",
    "file://docs/aidlc/prompts/AGENTS.md",
    "skill://docs/aidlc/skills/*/SKILL.md"
  ]
}
```

- プロジェクトルートの `AGENTS.md` を追加（プロジェクト固有の設定を読み込む）
- ワイルドカード `*/SKILL.md` により、将来スキルが追加されても自動的に読み込まれる

## 実装計画

1. `prompts/package/kiro/agents/aidlc.json` にマスターファイルを作成
2. `prompts/setup-prompt.md` を修正:
   - aidlc.json の直接作成 → シンボリックリンク作成に変更
   - rsync対象に `kiro/` を追加
3. `prompts/package/prompts/AGENTS.md` の KiroCLI設定例を修正
4. 動作確認（設定例の構文チェック）

## 完了条件チェックリスト

- [ ] .kiro/agents/aidlc.json をシンボリックリンク方式に変更する
- [ ] tools を `@builtin` に変更して全組み込みツールを利用可能にする
- [ ] resources にプロジェクトルートの `AGENTS.md` を追加する
- [ ] resources の skills 参照をワイルドカード `skills/*/SKILL.md` に変更する

## 参考

- [KiroCLI Built-in tools](https://kiro.dev/docs/cli/reference/built-in-tools/)
- [Agent configuration reference](https://kiro.dev/docs/cli/custom-agents/configuration-reference/)
