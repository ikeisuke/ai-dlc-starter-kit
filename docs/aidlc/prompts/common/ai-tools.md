# AIツール対応

AI-DLCは複数のAIツールで利用できます。

**スキル利用ガイド**: [詳細はこちら](../../guides/skill-usage-guide.md)

## スキルカタログ

### 名前空間

| 名前空間キー | プレフィックス | 説明 |
|------------|-------------|------|
| `aidlc` | `aidlc:` | AI-DLC固有のワークフロー・レビュースキル |
| `tools` | `tools:` | 汎用ツールスキル |

- **名前空間キー**: marketplace.json の `plugins[].name` と一致する識別子
- **プレフィックス**: カタログ表示名の接頭辞（`キー:` 形式）

### スキル正規表

| 名前空間キー | 呼び出し名 | カタログ表示名 | 読むファイル | 状態 | MP掲載 |
|------------|-----------|-------------|-------------|------|--------|
| `aidlc` | `reviewing-code` | `aidlc:reviewing-code` | `docs/aidlc/skills/reviewing-code/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-architecture` | `aidlc:reviewing-architecture` | `docs/aidlc/skills/reviewing-architecture/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-security` | `aidlc:reviewing-security` | `docs/aidlc/skills/reviewing-security/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-inception` | `aidlc:reviewing-inception` | `docs/aidlc/skills/reviewing-inception/SKILL.md` | active | Yes |
| `aidlc` | `aidlc-setup` | `aidlc:aidlc-setup` | `docs/aidlc/skills/aidlc-setup/SKILL.md` | active | Yes |
| `aidlc` | `squash-unit` | `aidlc:squash-unit` | `docs/aidlc/skills/squash-unit/SKILL.md` | active | Yes |
| `tools` | `session-title` | `tools:session-title` | `docs/aidlc/skills/session-title/SKILL.md` | active | Yes |

- **MP掲載**: marketplace.json に掲載されているか。deprecated スキルはマーケットプレイスに非掲載
- **呼び出し名**: `/skill` コマンドで使用するディレクトリ名ベースの識別子
- **カタログ表示名**: `プレフィックス + 呼び出し名` 形式のドキュメント上の表記

### 用途別ガイド

#### レビュースキル

AIレビューを実行するスキル（`aidlc` 名前空間）:

| 呼び出し名 | レビュー種別 |
|-----------|------------|
| `reviewing-code` | コードレビュー |
| `reviewing-architecture` | アーキテクチャレビュー |
| `reviewing-security` | セキュリティレビュー |
| `reviewing-inception` | Inceptionレビュー |

#### ワークフロースキル

AI-DLCのワークフローを実行するスキル（`aidlc` 名前空間）:

| 呼び出し名 | 説明 |
|-----------|------|
| `aidlc-setup` | AI-DLC環境を最新バージョンに更新 |
| `squash-unit` | Unit完了時のコミットスカッシュ |

#### ツールスキル

汎用ツールスキル（`tools` 名前空間）:

| 呼び出し名 | 説明 |
|-----------|------|
| `session-title` | ターミナルタブタイトル設定（macOS専用） |

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
