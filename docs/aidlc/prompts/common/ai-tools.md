# AIツール対応

AI-DLCは複数のAIツールで利用できます。

**スキル利用ガイド**: [詳細はこちら](../../guides/skill-usage-guide.md)

## レビュースキル

AIレビューを実行するスキル:

| レビュー種別 | 読むファイル |
|-------------|-------------|
| コードレビュー | `docs/aidlc/skills/reviewing-code/SKILL.md` |
| アーキテクチャレビュー | `docs/aidlc/skills/reviewing-architecture/SKILL.md` |
| セキュリティレビュー | `docs/aidlc/skills/reviewing-security/SKILL.md` |
| Inceptionレビュー | `docs/aidlc/skills/reviewing-inception/SKILL.md` |

## ワークフロースキル

AI-DLCのワークフローを実行するスキル:

| スキル | 読むファイル | 説明 |
|--------|-------------|------|
| アップグレード | `docs/aidlc/skills/upgrading-aidlc/SKILL.md` | AI-DLC環境を最新バージョンに更新 |
| jjバージョン管理 | `docs/aidlc/skills/versioning-with-jj/SKILL.md` | jjを使用したバージョン管理 |

## KiroCLI対応

AI-DLCセットアップ時に `.kiro/agents/aidlc.json` がシンボリックリンクとして作成されます。

**利用方法**:

```bash
# aidlcエージェントでKiroCLIを起動
kiro-cli --agent aidlc

# または起動後に切り替え
> /agent swap aidlc
```

**設定ファイル**:

`.kiro/agents/aidlc.json` → `docs/aidlc/kiro/agents/aidlc.json` へのシンボリックリンク

```json
{
  "name": "aidlc",
  "description": "AI-DLC開発支援エージェント。AGENTS.mdの指示に従い開発を進めます。コード・アーキテクチャ・セキュリティのAIレビューも実行できます。",
  "tools": ["@builtin"],
  "resources": [
    "file://AGENTS.md",
    "file://docs/aidlc/prompts/AGENTS.md",
    "skill://docs/aidlc/skills/*/SKILL.md"
  ]
}
```

**手動で設定する場合**:
- ローカル: `.kiro/agents/{agent-name}.json`
- グローバル: `~/.kiro/agents/{agent-name}.json`

**注意**: KiroCLIの仕様は更新される可能性があります。[公式ドキュメント](https://kiro.dev/docs/cli/custom-agents/configuration-reference/)を参照してください。
