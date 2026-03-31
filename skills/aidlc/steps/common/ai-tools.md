# AIツール対応

AI-DLCは複数のAIツールで利用できます。

**スキル利用ガイド**: `guides/skill-usage-guide.md` を参照

## スキルカタログ

### 名前空間

| 名前空間キー | プレフィックス | 説明 |
|------------|-------------|------|
| `aidlc` | `aidlc:` | AI-DLC固有のワークフロー・レビュースキル |

- **名前空間キー**: marketplace.json の `plugins[].name` と一致する識別子
- **プレフィックス**: カタログ表示名の接頭辞（`キー:` 形式）

### スキル正規表

| 名前空間キー | 呼び出し名 | カタログ表示名 | 読むファイル | 状態 | MP掲載 |
|------------|-----------|-------------|-------------|------|--------|
| `aidlc` | `reviewing-inception-intent` | `aidlc:reviewing-inception-intent` | `skills/reviewing-inception-intent/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-inception-stories` | `aidlc:reviewing-inception-stories` | `skills/reviewing-inception-stories/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-inception-units` | `aidlc:reviewing-inception-units` | `skills/reviewing-inception-units/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-construction-plan` | `aidlc:reviewing-construction-plan` | `skills/reviewing-construction-plan/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-construction-design` | `aidlc:reviewing-construction-design` | `skills/reviewing-construction-design/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-construction-code` | `aidlc:reviewing-construction-code` | `skills/reviewing-construction-code/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-construction-integration` | `aidlc:reviewing-construction-integration` | `skills/reviewing-construction-integration/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-operations-deploy` | `aidlc:reviewing-operations-deploy` | `skills/reviewing-operations-deploy/SKILL.md` | active | Yes |
| `aidlc` | `reviewing-operations-premerge` | `aidlc:reviewing-operations-premerge` | `skills/reviewing-operations-premerge/SKILL.md` | active | Yes |
| `aidlc` | `aidlc-setup` | `aidlc:aidlc-setup` | `skills/aidlc-setup/SKILL.md` | active | Yes |
| `aidlc` | `squash-unit` | `aidlc:squash-unit` | `skills/squash-unit/SKILL.md` | active | Yes |

- **MP掲載**: marketplace.json に掲載されているか。deprecated スキルはマーケットプレイスに非掲載
- **呼び出し名**: `/skill` コマンドで使用するディレクトリ名ベースの識別子
- **カタログ表示名**: `プレフィックス + 呼び出し名` 形式のドキュメント上の表記

### 用途別ガイド

#### レビュースキル

AIレビューを実行するスキル（`aidlc` 名前空間）:

| 呼び出し名 | レビュー種別 |
|-----------|------------|
| `reviewing-inception-intent` | Intent承認前レビュー |
| `reviewing-inception-stories` | ストーリー承認前レビュー |
| `reviewing-inception-units` | Unit定義承認前レビュー |
| `reviewing-construction-plan` | 計画承認前レビュー |
| `reviewing-construction-design` | 設計レビュー |
| `reviewing-construction-code` | コード+セキュリティレビュー |
| `reviewing-construction-integration` | 統合レビュー |
| `reviewing-operations-deploy` | デプロイ計画レビュー |
| `reviewing-operations-premerge` | PRマージ前レビュー |

#### ワークフロースキル

AI-DLCのワークフローを実行するスキル（`aidlc` 名前空間）:

| 呼び出し名 | 説明 |
|-----------|------|
| `aidlc-setup` | AI-DLC環境を最新バージョンに更新 |
| `squash-unit` | Unit完了時のコミットスカッシュ |

## KiroCLI対応

AI-DLCセットアップ時に `.kiro/agents/aidlc.json` が実ファイルとして配置されます。

**利用方法**:

```bash
# aidlcエージェントでKiroCLIを起動
kiro-cli --agent aidlc

# または起動後に切り替え
> /agent swap aidlc
```

**設定ファイル**:

`.kiro/agents/aidlc.json` — テンプレートからコピーされた実ファイル

```json
{
  "name": "aidlc",
  "description": "AI-DLC開発支援エージェント",
  "tools": ["read", "shell", "write"],
  "resources": [
    "skill://.agents/skills/*/SKILL.md",
    "skill://~/.agents/skills/*/SKILL.md",
    "skill://.kiro/skills/*/SKILL.md",
    "skill://~/.kiro/skills/*/SKILL.md"
  ]
}
```

**手動で設定する場合**:
- ローカル: `.kiro/agents/{agent-name}.json`
- グローバル: `~/.kiro/agents/{agent-name}.json`

**注意**: KiroCLIの仕様は更新される可能性があります。[公式ドキュメント](https://kiro.dev/docs/cli/custom-agents/configuration-reference/)を参照してください。
