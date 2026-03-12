# スキル利用ガイド

このガイドでは、AI-DLCスターターキットに含まれるスキルファイルを各AIツールで利用する方法を説明します。

**関連ドキュメント**: [AGENTS.md](../prompts/AGENTS.md)（AI-DLC全体の概要）

---

## スキルとは

スキルは、**特定のレビューやワークフローを実行する**ための手順書です。

例えば:
- 「コードレビューして」と言われたら → `reviewing-code` スキルを使用
- 「アーキテクチャレビューして」と言われたら → `reviewing-architecture` スキルを使用
- 「セキュリティレビューして」と言われたら → `reviewing-security` スキルを使用

**ポイント**: 必要なときに、必要なスキルだけを読めばOK。

---

## スキルファイルの配置場所

セットアップ後、スキルファイルは以下の場所に配置されます:

```text
docs/aidlc/skills/              ← rsync で同期（スターターキット提供）
├── reviewing-code/             # aidlc: コードレビュー
│   └── SKILL.md
├── reviewing-architecture/     # aidlc: アーキテクチャレビュー
│   └── SKILL.md
├── reviewing-security/         # aidlc: セキュリティレビュー
│   └── SKILL.md
├── reviewing-inception/        # aidlc: Inceptionレビュー
│   └── SKILL.md
├── aidlc-setup/                # aidlc: AI-DLCアップグレード
│   └── SKILL.md
├── squash-unit/                # aidlc: コミットスカッシュ
│   └── SKILL.md
├── session-title/              # tools: タブタイトル設定
│   └── SKILL.md
└── versioning-with-jj/         # aidlc: jjバージョン管理（非推奨）
    └── SKILL.md
```

Claude Code では `.claude/skills/` からこれらを参照します。プロジェクト独自スキルの追加方法は後述の「プロジェクト独自スキルの追加」を参照してください。

---

## 名前空間

スキルは**名前空間**で論理的に分類されています。

| 名前空間 | 説明 |
|----------|------|
| `aidlc:` | AI-DLC固有のワークフロー・レビュースキル |
| `tools:` | 汎用ツールスキル |

名前空間はカタログ上の表示名に使用されます（例: `aidlc:reviewing-code`）。実際のスキル呼び出しは引き続きディレクトリ名（例: `reviewing-code`）で行います。

### 後方互換性

- `/skill` コマンドの実行は引き続きディレクトリ名ベース（例: `/reviewing-code`）
- プレフィックス付き名前（例: `aidlc:reviewing-code`）はカタログ上の論理的な表示名
- 既存のスキル呼び出し方法は変更されません

### 名前衝突解決規則

| コンテキスト | 解決方法 |
|------------|---------|
| 内部 `/skill` 呼び出し | ディレクトリ名で一意解決（AIツールの責務） |
| マーケットプレイス `/plugin install` | プラグイングループ名 + スキルスラッグで解決（プラットフォームの責務） |
| 同一名前空間内の重複 | 禁止（スキル登録時に確認） |

---

## 利用可能なスキル

スキルの完全な一覧（名前空間・呼び出し名・状態・MP掲載状況）は [ai-tools.md の正規表](../prompts/common/ai-tools.md) を参照してください。ai-tools.md がスキル一覧の正（Source of Truth）です。

以下は用途別の概要です:

- **レビュースキル**（`aidlc` 名前空間）: `reviewing-code`, `reviewing-architecture`, `reviewing-security`, `reviewing-inception`
- **ワークフロースキル**（`aidlc` 名前空間）: `aidlc-setup`, `squash-unit`, `versioning-with-jj`（非推奨）
- **ツールスキル**（`tools` 名前空間）: `session-title`

---

## 各AIツールでの使い方

### Claude Code

Claude Code には組み込みの Skill ツールがあり、スキルを自動検出します。

```text
/reviewing-code           → コードレビューを実行（aidlc:reviewing-code）
/reviewing-architecture   → アーキテクチャレビューを実行（aidlc:reviewing-architecture）
/reviewing-security       → セキュリティレビューを実行（aidlc:reviewing-security）
/reviewing-inception      → Inceptionレビューを実行（aidlc:reviewing-inception）
/aidlc-setup              → AI-DLC環境をアップグレード（aidlc:aidlc-setup）
/squash-unit              → コミットスカッシュ（aidlc:squash-unit）
/session-title            → タブタイトル設定（tools:session-title）
/versioning-with-jj       → jjバージョン管理（aidlc:versioning-with-jj、非推奨）
```

セットアップ時に`.claude/skills/`ディレクトリが作成され、各スキルへのシンボリックリンクが配置されます。

---

### Codex CLI

#### スキル設定（初回のみ）

Codex CLI は `~/.codex/skills` からスキルファイルを読み込みます。プロジェクトのスキルを利用するには、手動でシンボリックリンクを作成してください。

```bash
# スキルディレクトリを作成
mkdir -p ~/.codex/skills

# プロジェクトのactiveスキルへのシンボリックリンクを作成
# <PROJECT_ROOT> はプロジェクトのルートディレクトリの絶対パスに置き換えてください
# aidlc名前空間（レビュー系）
ln -s "<PROJECT_ROOT>/docs/aidlc/skills/reviewing-code" ~/.codex/skills/reviewing-code
ln -s "<PROJECT_ROOT>/docs/aidlc/skills/reviewing-architecture" ~/.codex/skills/reviewing-architecture
ln -s "<PROJECT_ROOT>/docs/aidlc/skills/reviewing-security" ~/.codex/skills/reviewing-security
ln -s "<PROJECT_ROOT>/docs/aidlc/skills/reviewing-inception" ~/.codex/skills/reviewing-inception
# aidlc名前空間（ワークフロー系）
ln -s "<PROJECT_ROOT>/docs/aidlc/skills/aidlc-setup" ~/.codex/skills/aidlc-setup
ln -s "<PROJECT_ROOT>/docs/aidlc/skills/squash-unit" ~/.codex/skills/squash-unit
# tools名前空間
ln -s "<PROJECT_ROOT>/docs/aidlc/skills/session-title" ~/.codex/skills/session-title
```

**注**: deprecated スキル（`versioning-with-jj`）は将来削除予定のため、新規設定では除外を推奨します。

#### 設定確認

シンボリックリンクが正しく作成されたことを確認します:

```bash
ls -la ~/.codex/skills/
```

期待される出力例:

```text
aidlc-setup -> /path/to/project/docs/aidlc/skills/aidlc-setup
reviewing-code -> /path/to/project/docs/aidlc/skills/reviewing-code
reviewing-architecture -> /path/to/project/docs/aidlc/skills/reviewing-architecture
reviewing-security -> /path/to/project/docs/aidlc/skills/reviewing-security
reviewing-inception -> /path/to/project/docs/aidlc/skills/reviewing-inception
session-title -> /path/to/project/docs/aidlc/skills/session-title
squash-unit -> /path/to/project/docs/aidlc/skills/squash-unit
```

#### セットアップフローとの関係

- AI-DLCセットアップ（`prompts/setup-prompt.md`）は Claude Code 用の `.claude/skills/` を自動作成しますが、`~/.codex/skills` は対象外です
- Codex CLI ユーザーは上記の手順で手動設定が必要です
- 初回設定後、`docs/aidlc/skills/` はアップグレード時に自動更新されるため、シンボリックリンクの再作成は不要です

---

### Gemini CLI

レビューを実行したいときは、該当するスキルファイルを読んでください:

```text
「コードレビューして」と言われたら:
→ docs/aidlc/skills/reviewing-code/SKILL.md を読んで、その手順に従う

「アーキテクチャレビューして」と言われたら:
→ docs/aidlc/skills/reviewing-architecture/SKILL.md を読んで、その手順に従う

「セキュリティレビューして」と言われたら:
→ docs/aidlc/skills/reviewing-security/SKILL.md を読んで、その手順に従う

「Inceptionレビューして」と言われたら:
→ docs/aidlc/skills/reviewing-inception/SKILL.md を読んで、その手順に従う
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
    "file://docs/aidlc/skills/reviewing-code/SKILL.md",
    "file://docs/aidlc/skills/reviewing-architecture/SKILL.md",
    "file://docs/aidlc/skills/reviewing-security/SKILL.md",
    "file://docs/aidlc/skills/reviewing-inception/SKILL.md"
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
├── reviewing-code/           → ../../docs/aidlc/skills/reviewing-code/           (シンボリックリンク)
├── reviewing-architecture/   → ../../docs/aidlc/skills/reviewing-architecture/   (シンボリックリンク)
├── reviewing-security/       → ../../docs/aidlc/skills/reviewing-security/       (シンボリックリンク)
├── reviewing-inception/      → ../../docs/aidlc/skills/reviewing-inception/      (シンボリックリンク)
├── aidlc-setup/              → ../../docs/aidlc/skills/aidlc-setup/              (シンボリックリンク)
├── squash-unit/              → ../../docs/aidlc/skills/squash-unit/              (シンボリックリンク)
├── session-title/            → ../../docs/aidlc/skills/session-title/            (シンボリックリンク)
├── versioning-with-jj/       → ../../docs/aidlc/skills/versioning-with-jj/       (シンボリックリンク)
└── my-custom/                ← プロジェクト独自スキル（実ディレクトリ）
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
| `reviewing-code`, `reviewing-architecture`, `reviewing-security`, `reviewing-inception`, `aidlc-setup`, `squash-unit`, `session-title`, `versioning-with-jj` | 不可 | スターターキット予約名（シンボリックリンク） |
| `my-project-lint` | 可 | プロジェクト名プレフィックス推奨 |
| `team-review` | 可 | チーム名プレフィックス推奨 |

### アップグレード時の挙動

- `docs/aidlc/skills/` は rsync で同期されます（スターターキット提供のスキル）
- `.claude/skills/` 内のプロジェクト独自スキル（実ディレクトリ）はアップグレードの影響を受けません
- シンボリックリンクは `docs/aidlc/skills/` を参照するため、自動的に最新版が適用されます

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
