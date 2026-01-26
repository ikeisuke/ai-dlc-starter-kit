# スキル利用ガイド

このガイドでは、AI-DLCスターターキットに含まれるスキルファイルを各AIツールで利用する方法を説明します。

**関連ドキュメント**: [AGENTS.md](../prompts/AGENTS.md)（AI-DLC全体の概要）

---

## スキルとは

スキルは、**特定のAIツールを呼び出す**ための手順書です。

例えば:
- Claude Code で「Codexでレビューして」と言われたら → `/codex` スキルを使用
- Codex CLI で「Claudeでレビューして」と言われたら → `claude/SKILL.md` を参照
- KiroCLI で「Geminiで分析して」と言われたら → `gemini/SKILL.md` を参照

**ポイント**: 必要なときに、必要なスキルだけを読めばOK。

---

## スキルファイルの配置場所

セットアップ後、スキルファイルは以下の場所に配置されます:

```text
docs/aidlc/skills/          ← rsync で同期（スターターキット提供）
├── codex/
│   └── SKILL.md    # Codex CLI の呼び出し方
├── claude/
│   └── SKILL.md    # Claude Code の呼び出し方
└── gemini/
    └── SKILL.md    # Gemini CLI の呼び出し方
```

Claude Code では `.claude/skills/` からこれらを参照します。プロジェクト独自スキルの追加方法は後述の「プロジェクト独自スキルの追加」を参照してください。

---

## 利用可能なスキル

| 呼び出したいツール | 読むスキルファイル |
|-------------------|-------------------|
| Codex CLI | `docs/aidlc/skills/codex/SKILL.md` |
| Claude Code | `docs/aidlc/skills/claude/SKILL.md` |
| Gemini CLI | `docs/aidlc/skills/gemini/SKILL.md` |

---

## 各AIツールでの使い方

### Claude Code

Claude Code には組み込みの Skill ツールがあり、スキルを自動検出します。

```text
/codex   → Codex CLI を呼び出してレビュー
/gemini  → Gemini CLI を呼び出してレビュー
/claude  → 別の Claude Code セッションを呼び出し
```

セットアップ時にシンボリックリンク（`.claude/skills/` → `docs/aidlc/skills/`）が作成されます。

---

### Codex CLI / Gemini CLI

他のAIツールを呼び出したいときは、該当するスキルファイルを読んでください:

```text
「Claude でレビューして」と言われたら:
→ docs/aidlc/skills/claude/SKILL.md を読んで、その手順に従う

「Gemini で分析して」と言われたら:
→ docs/aidlc/skills/gemini/SKILL.md を読んで、その手順に従う
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
    "file://docs/aidlc/skills/codex/SKILL.md",
    "file://docs/aidlc/skills/claude/SKILL.md",
    "file://docs/aidlc/skills/gemini/SKILL.md"
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
├── codex/   → ../../docs/aidlc/skills/codex/   (シンボリックリンク)
├── claude/  → ../../docs/aidlc/skills/claude/  (シンボリックリンク)
├── gemini/  → ../../docs/aidlc/skills/gemini/  (シンボリックリンク)
└── my-review/           ← プロジェクト独自スキル（実ディレクトリ）
    └── SKILL.md
```

### 追加手順

1. `.claude/skills/` 配下にディレクトリを作成
   ```bash
   mkdir -p .claude/skills/my-review
   ```

2. `SKILL.md` ファイルを作成
   ```bash
   touch .claude/skills/my-review/SKILL.md
   ```

3. SKILL.md ファイルを作成してスキルの内容を記述

### 命名規則

| 名前 | 使用可否 | 理由 |
|------|----------|------|
| `codex`, `claude`, `gemini` | 不可 | スターターキット予約名（シンボリックリンク） |
| `my-project-lint` | 可 | プロジェクト名プレフィックス推奨 |
| `team-review` | 可 | チーム名プレフィックス推奨 |

### アップグレード時の挙動

- `docs/aidlc/skills/` は rsync で同期されます（スターターキット提供のスキル）
- `.claude/skills/` 内のプロジェクト独自スキル（実ディレクトリ）はアップグレードの影響を受けません
- シンボリックリンク（codex, claude, gemini）は `docs/aidlc/skills/` を参照するため、自動的に最新版が適用されます

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
