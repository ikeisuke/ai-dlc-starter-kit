# スキル利用ガイド

AI-DLCスターターキットに含まれるスキルの利用方法。

---

## スキルとは

特定のレビューやワークフローを実行するための手順書。必要なときに必要なスキルだけ読めばOK。

---

## スキルファイルの配置場所

```text
skills/
├── reviewing-inception-{intent,stories,units}/     # Inceptionレビュー
├── reviewing-construction-{plan,design,code,integration}/  # Constructionレビュー
├── reviewing-operations-{deploy,premerge}/          # Operationsレビュー
├── aidlc-setup/                                     # セットアップ
├── squash-unit/                                     # コミットスカッシュ
└── write-history/                                   # 履歴記録
```

---

## 名前空間

| 名前空間 | 説明 |
|----------|------|
| `aidlc:` | AI-DLC固有のワークフロー・レビュースキル |

スキル呼び出しはディレクトリ名ベース（例: `/reviewing-construction-code`）。名前空間はカタログ上の表示名。

---

## 利用可能なスキル

正規表は `steps/common/ai-tools.md` を参照。

- **レビュー**: `reviewing-{inception,construction,operations}-*`
- **ワークフロー**: `aidlc-setup`, `squash-unit`, `write-history`

---

## 各AIツールでの使い方

### Claude Code

組み込みのSkillツールで自動検出。`/reviewing-construction-code` のように呼び出す。

セットアップ時に `.claude/skills/` ディレクトリが作成され、各スキルへのシンボリックリンクが配置される。

### Codex CLI

`~/.codex/skills` にシンボリックリンクを手動作成:

```bash
mkdir -p ~/.codex/skills
# 各スキルへのシンボリックリンクを作成
ln -s "<PROJECT_ROOT>/skills/reviewing-construction-code" ~/.codex/skills/reviewing-construction-code
# ... 他のスキルも同様
```

初回設定後、`skills/` はアップグレード時に自動更新されるためリンクの再作成は不要。

### Gemini CLI

該当するスキルファイルを直接読み込んで手順に従う:

```text
「コードレビューして」→ skills/reviewing-construction-code/SKILL.md を読む
「設計レビューして」→ skills/reviewing-construction-design/SKILL.md を読む
```

### KiroCLI

エージェント設定ファイルの `resources` でスキルファイルを指定:

```json
{
  "name": "aidlc-agent",
  "resources": [
    "file://skills/aidlc/AGENTS.md",
    "file://skills/reviewing-construction-code/SKILL.md"
  ],
  "tools": ["read", "write", "shell"]
}
```

全スキルを含めるとコンテキスト増大。必要なスキルのみ指定を推奨。

---

## プロジェクト独自スキルの追加（Claude Code）

`.claude/skills/` に独自ディレクトリを作成し `SKILL.md` を配置。

**予約名**（使用不可）: `reviewing-*`, `aidlc-setup`, `squash-unit`, `write-history`
**推奨**: プロジェクト名やチーム名プレフィックス（例: `my-project-lint`）

アップグレード時、独自スキル（実ディレクトリ）は影響を受けない。シンボリックリンクは自動更新。

---

## トラブルシューティング

スキルが見つからない場合: `ls skills/` で存在確認、セットアップ完了を確認。

---

## オプショナルスキル

以下は [claude-skills](https://github.com/ikeisuke/claude-skills) リポジトリから別途インストール:

| スキル | 用途 |
|--------|------|
| `session-title` | ターミナルタブのタイトル・バッジ設定（macOS） |
| `suggest-permissions` | 許可設定の自動提案・監査 |

未インストールでも各フェーズのセッション判別設定ステップは自動スキップ。

---

## 関連リンク

- [KiroCLI](https://kiro.dev/docs/cli/)
