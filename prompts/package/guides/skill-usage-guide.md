# スキル利用ガイド

このガイドでは、AI-DLCスターターキットに含まれるスキルファイルを各AIツールで利用する方法を説明します。

**関連ドキュメント**: [AGENTS.md](../prompts/AGENTS.md)（AI-DLC全体の概要）

---

## スキルとは

スキルは、**特定のAIツールを呼び出す**ための手順書です。

例えば:
- Claude Code で「Codexでレビューして」と言われたら → `/codex-review` スキルを使用
- Codex CLI で「Claudeでレビューして」と言われたら → `claude-review/SKILL.md` を参照
- KiroCLI で「Geminiでレビューして」と言われたら → `gemini-review/SKILL.md` を参照

**ポイント**: 必要なときに、必要なスキルだけを読めばOK。

---

## スキルファイルの配置場所

セットアップ後、スキルファイルは以下の場所に配置されます:

```text
docs/aidlc/skills/          ← rsync で同期（スターターキット提供）
├── codex-review/
│   └── SKILL.md    # Codex CLI でレビュー
├── claude-review/
│   └── SKILL.md    # Claude Code でレビュー
└── gemini-review/
    └── SKILL.md    # Gemini CLI でレビュー
```

Claude Code では `.claude/skills/` からこれらを参照します。プロジェクト独自スキルの追加方法は後述の「プロジェクト独自スキルの追加」を参照してください。

---

## 利用可能なスキル

| 呼び出したいツール | 読むスキルファイル |
|-------------------|-------------------|
| Codex CLI | `docs/aidlc/skills/codex-review/SKILL.md` |
| Claude Code | `docs/aidlc/skills/claude-review/SKILL.md` |
| Gemini CLI | `docs/aidlc/skills/gemini-review/SKILL.md` |

---

## 各AIツールでの使い方

### Claude Code

Claude Code には組み込みの Skill ツールがあり、スキルを自動検出します。

```text
/codex-review   → Codex CLI を呼び出してレビュー
/gemini-review  → Gemini CLI を呼び出してレビュー
/claude-review  → 別の Claude Code セッションを呼び出してレビュー
```

セットアップ時に`.claude/skills/`ディレクトリが作成され、各スキルへのシンボリックリンクが配置されます。

---

### Codex CLI

#### スキル設定（初回のみ）

Codex CLI は `~/.codex/skills` からスキルファイルを読み込みます。プロジェクトのスキルを利用するには、手動でシンボリックリンクを作成してください。

```bash
# スキルディレクトリを作成
mkdir -p ~/.codex/skills

# プロジェクトのスキルへのシンボリックリンクを作成
# <PROJECT_ROOT> はプロジェクトのルートディレクトリの絶対パスに置き換えてください
ln -s <PROJECT_ROOT>/docs/aidlc/skills/codex-review ~/.codex/skills/codex-review
ln -s <PROJECT_ROOT>/docs/aidlc/skills/claude-review ~/.codex/skills/claude-review
ln -s <PROJECT_ROOT>/docs/aidlc/skills/gemini-review ~/.codex/skills/gemini-review
```

#### 設定確認

シンボリックリンクが正しく作成されたことを確認します:

```bash
ls -la ~/.codex/skills/
```

期待される出力例:

```text
codex-review -> /path/to/project/docs/aidlc/skills/codex-review
claude-review -> /path/to/project/docs/aidlc/skills/claude-review
gemini-review -> /path/to/project/docs/aidlc/skills/gemini-review
```

#### 他のAIツールを呼び出す場合

他のAIツールを呼び出したいときは、該当するスキルファイルを読んでください:

```text
「Claude でレビューして」と言われたら:
→ docs/aidlc/skills/claude-review/SKILL.md を読んで、その手順に従う

「Gemini でレビューして」と言われたら:
→ docs/aidlc/skills/gemini-review/SKILL.md を読んで、その手順に従う
```

#### セットアップフローとの関係

- AI-DLCセットアップ（`prompts/setup-prompt.md`）は Claude Code 用の `.claude/skills/` を自動作成しますが、`~/.codex/skills` は対象外です
- Codex CLI ユーザーは上記の手順で手動設定が必要です
- 初回設定後、`docs/aidlc/skills/` はアップグレード時に自動更新されるため、シンボリックリンクの再作成は不要です

---

### Gemini CLI

他のAIツールを呼び出したいときは、該当するスキルファイルを読んでください:

```text
「Codex でレビューして」と言われたら:
→ docs/aidlc/skills/codex-review/SKILL.md を読んで、その手順に従う

「Claude でレビューして」と言われたら:
→ docs/aidlc/skills/claude-review/SKILL.md を読んで、その手順に従う
```

---

### KiroCLI

KiroCLI では、エージェント設定ファイルの `resources` フィールドでスキルファイルを指定できます。

**設定ファイルの場所**:
- ローカル: `.kiro/agents/{agent-name}.json`
- グローバル: `~/.kiro/agents/{agent-name}.json`

**設定例**:

```json
{
  "name": "aidlc-agent",
  "resources": [
    "file://docs/aidlc/prompts/AGENTS.md",
    "file://docs/aidlc/skills/codex-review/SKILL.md",
    "file://docs/aidlc/skills/claude-review/SKILL.md",
    "file://docs/aidlc/skills/gemini-review/SKILL.md"
  ],
  "tools": ["read", "write", "shell"]
}
```

**注**: 全スキルを含めるとコンテキストが増大します。必要なスキルのみ指定することを推奨します。

**パス解決**: 相対パスはエージェント設定ファイルの場所を基準に解決されます。

---

## プロジェクト独自スキルの追加（Claude Code）

`.claude/skills/` ディレクトリに独自のスキルを追加できます。

### ディレクトリ構成

```text
.claude/skills/
├── codex-review/   → ../../docs/aidlc/skills/codex-review/   (シンボリックリンク)
├── claude-review/  → ../../docs/aidlc/skills/claude-review/  (シンボリックリンク)
├── gemini-review/  → ../../docs/aidlc/skills/gemini-review/  (シンボリックリンク)
└── my-custom/              ← プロジェクト独自スキル（実ディレクトリ）
    └── SKILL.md
```

### 追加手順

1. `.claude/skills/` 配下にディレクトリを作成
   ```bash
   mkdir -p .claude/skills/my-custom
   ```

2. `SKILL.md` ファイルを作成
   ```bash
   touch .claude/skills/my-custom/SKILL.md
   ```

3. SKILL.md ファイルを作成してスキルの内容を記述

### 命名規則

| 名前 | 使用可否 | 理由 |
|------|----------|------|
| `codex-review`, `claude-review`, `gemini-review` | 不可 | スターターキット予約名（シンボリックリンク） |
| `my-project-lint` | 可 | プロジェクト名プレフィックス推奨 |
| `team-review` | 可 | チーム名プレフィックス推奨 |

### アップグレード時の挙動

- `docs/aidlc/skills/` は rsync で同期されます（スターターキット提供のスキル）
- `.claude/skills/` 内のプロジェクト独自スキル（実ディレクトリ）はアップグレードの影響を受けません
- シンボリックリンク（codex-review, claude-review, gemini-review）は `docs/aidlc/skills/` を参照するため、自動的に最新版が適用されます

---

## トラブルシューティング

### スキルが見つからない

1. スキルファイルが存在するか確認
   ```bash
   ls docs/aidlc/skills/
   ```
2. セットアップが完了しているか確認（`prompts/setup-prompt.md` を実行）

### CLIツールがエラーになる

1. ツールがインストールされているか確認
   ```bash
   which codex
   which gemini
   ```
2. 認証が完了しているか確認

---

## 関連リンク

- [Codex CLI](https://github.com/openai/codex)
- [Gemini CLI](https://github.com/google/gemini-cli)
- [KiroCLI](https://kiro.dev/docs/cli/)
