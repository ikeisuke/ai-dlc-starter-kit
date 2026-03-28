# Kiro エージェント設定サンプル

Kiro CLIのエージェント設定ファイル（`.kiro/agents/aidlc.json`）は、`setup-ai-tools.sh` によって自動管理されます。

## 自動セットアップ

AI-DLCのセットアップ時に `setup-ai-tools.sh` が実行され、以下の処理が行われます:

1. **ファイル未存在時**: `docs/aidlc/kiro/agents/aidlc.json` へのシンボリックリンクを作成
2. **シンボリックリンク存在時**: ターゲットが正しいか確認し、必要に応じて修正
3. **実ファイル存在時**: テンプレートとマージし、ユーザーのカスタマイズを保持しつつ更新

## 手動セットアップ（フォールバック）

`setup-ai-tools.sh` が利用できない環境では、手動で配置してください:

```bash
mkdir -p .kiro/agents
cp examples/kiro/agents/aidlc.json .kiro/agents/aidlc.json
```

## カスタマイズ

`aidlc.json` の `allowedCommands` や `deniedCommands` は、プロジェクトの要件に合わせて編集してください。

シンボリックリンクではなく実ファイルとして配置した場合、次回のセットアップ時にマージロジックが適用され、カスタマイズが保持されます。
