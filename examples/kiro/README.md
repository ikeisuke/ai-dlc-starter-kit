# Kiro エージェント設定サンプル

v2以降、Kiroエージェント設定ファイル（`.kiro/agents/aidlc.json`）はスターターキットによる自動配置の対象外となりました。

Kiro CLIを使用する場合は、このサンプルを参考にプロジェクトに手動で配置してください。

## 配置手順

```bash
mkdir -p .kiro/agents
cp examples/kiro/agents/aidlc.json .kiro/agents/aidlc.json
```

## カスタマイズ

`aidlc.json` の `allowedCommands` や `deniedCommands` は、プロジェクトの要件に合わせて編集してください。
