# スキル利用ガイド

このガイドでは、AI-DLCスターターキットに含まれるスキルファイルを各AIツールで利用する方法を説明します。

**関連ドキュメント**: [AGENTS.md](../prompts/AGENTS.md)（AI-DLC全体の概要）

---

## スキルとは

スキルは、**特定のレビューやワークフローを実行する**ための手順書です。

例えば:
- 「コードレビューして」と言われたら → `reviewing-construction-code` スキルを使用
- 「設計レビューして」と言われたら → `reviewing-construction-design` スキルを使用
- 「セキュリティレビューして」と言われたら → `reviewing-construction-code` スキルを使用（セキュリティ観点はcodeに統合）

**ポイント**: 必要なときに、必要なスキルだけを読めばOK。

---

## スキルファイルの配置場所

セットアップ後、スキルファイルは以下の場所に配置されます:

```text
skills/              ← rsync で同期（スターターキット提供）
├── reviewing-construction-code/        # aidlc: コードレビュー
│   └── SKILL.md
├── reviewing-construction-design/      # aidlc: 設計レビュー
│   └── SKILL.md
├── reviewing-construction-integration/ # aidlc: 結合レビュー
│   └── SKILL.md
├── reviewing-construction-plan/        # aidlc: 計画レビュー
│   └── SKILL.md
├── reviewing-inception-intent/         # aidlc: Intent レビュー
│   └── SKILL.md
├── reviewing-inception-stories/        # aidlc: ストーリーレビュー
│   └── SKILL.md
├── reviewing-inception-units/          # aidlc: Unit レビュー
│   └── SKILL.md
├── reviewing-operations-deploy/        # aidlc: デプロイレビュー
│   └── SKILL.md
├── reviewing-operations-premerge/      # aidlc: プレマージレビュー
│   └── SKILL.md
├── aidlc-setup/                        # aidlc: AI-DLCアップグレード
│   └── SKILL.md
└── squash-unit/                        # aidlc: コミットスカッシュ
    └── SKILL.md
```

Claude Code では `.claude/skills/` からこれらを参照します。プロジェクト独自スキルの追加方法は後述の「プロジェクト独自スキルの追加」を参照してください。

---

## 名前空間

スキルは**名前空間**で論理的に分類されています。

| 名前空間 | 説明 |
|----------|------|
| `aidlc:` | AI-DLC固有のワークフロー・レビュースキル |

名前空間はカタログ上の表示名に使用されます（例: `aidlc:reviewing-construction-code`）。実際のスキル呼び出しは引き続きディレクトリ名（例: `reviewing-construction-code`）で行います。

### 後方互換性

- `/skill` コマンドの実行は引き続きディレクトリ名ベース（例: `/reviewing-construction-code`）
- プレフィックス付き名前（例: `aidlc:reviewing-construction-code`）はカタログ上の論理的な表示名
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

- **レビュースキル**（`aidlc` 名前空間）: `reviewing-construction-code`, `reviewing-construction-design`, `reviewing-construction-integration`, `reviewing-construction-plan`, `reviewing-inception-intent`, `reviewing-inception-stories`, `reviewing-inception-units`, `reviewing-operations-deploy`, `reviewing-operations-premerge`
- **ワークフロースキル**（`aidlc` 名前空間）: `aidlc-setup`, `squash-unit`

---

## 各AIツールでの使い方

### Claude Code

Claude Code には組み込みの Skill ツールがあり、スキルを自動検出します。

```text
/reviewing-construction-code        → コードレビューを実行（aidlc:reviewing-construction-code）
/reviewing-construction-design      → 設計レビューを実行（aidlc:reviewing-construction-design）
/reviewing-construction-integration → 結合レビューを実行（aidlc:reviewing-construction-integration）
/reviewing-construction-plan        → 計画レビューを実行（aidlc:reviewing-construction-plan）
/reviewing-inception-intent         → Intentレビューを実行（aidlc:reviewing-inception-intent）
/reviewing-inception-stories        → ストーリーレビューを実行（aidlc:reviewing-inception-stories）
/reviewing-inception-units          → Unitレビューを実行（aidlc:reviewing-inception-units）
/reviewing-operations-deploy        → デプロイレビューを実行（aidlc:reviewing-operations-deploy）
/reviewing-operations-premerge      → プレマージレビューを実行（aidlc:reviewing-operations-premerge）
/aidlc-setup              → AI-DLC環境をアップグレード（aidlc:aidlc-setup）
/squash-unit              → コミットスカッシュ（aidlc:squash-unit）
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
ln -s "<PROJECT_ROOT>/skills/reviewing-construction-code" ~/.codex/skills/reviewing-construction-code
ln -s "<PROJECT_ROOT>/skills/reviewing-construction-design" ~/.codex/skills/reviewing-construction-design
ln -s "<PROJECT_ROOT>/skills/reviewing-construction-integration" ~/.codex/skills/reviewing-construction-integration
ln -s "<PROJECT_ROOT>/skills/reviewing-construction-plan" ~/.codex/skills/reviewing-construction-plan
ln -s "<PROJECT_ROOT>/skills/reviewing-inception-intent" ~/.codex/skills/reviewing-inception-intent
ln -s "<PROJECT_ROOT>/skills/reviewing-inception-stories" ~/.codex/skills/reviewing-inception-stories
ln -s "<PROJECT_ROOT>/skills/reviewing-inception-units" ~/.codex/skills/reviewing-inception-units
ln -s "<PROJECT_ROOT>/skills/reviewing-operations-deploy" ~/.codex/skills/reviewing-operations-deploy
ln -s "<PROJECT_ROOT>/skills/reviewing-operations-premerge" ~/.codex/skills/reviewing-operations-premerge
# aidlc名前空間（ワークフロー系）
ln -s "<PROJECT_ROOT>/skills/aidlc-setup" ~/.codex/skills/aidlc-setup
ln -s "<PROJECT_ROOT>/skills/squash-unit" ~/.codex/skills/squash-unit
```

#### 設定確認

シンボリックリンクが正しく作成されたことを確認します:

```bash
ls -la ~/.codex/skills/
```

期待される出力例:

```text
aidlc-setup -> /path/to/project/skills/aidlc-setup
reviewing-construction-code -> /path/to/project/skills/reviewing-construction-code
reviewing-construction-design -> /path/to/project/skills/reviewing-construction-design
reviewing-construction-integration -> /path/to/project/skills/reviewing-construction-integration
reviewing-construction-plan -> /path/to/project/skills/reviewing-construction-plan
reviewing-inception-intent -> /path/to/project/skills/reviewing-inception-intent
reviewing-inception-stories -> /path/to/project/skills/reviewing-inception-stories
reviewing-inception-units -> /path/to/project/skills/reviewing-inception-units
reviewing-operations-deploy -> /path/to/project/skills/reviewing-operations-deploy
reviewing-operations-premerge -> /path/to/project/skills/reviewing-operations-premerge
squash-unit -> /path/to/project/skills/squash-unit
```

#### セットアップフローとの関係

- AI-DLCセットアップ（`prompts/setup-prompt.md`）は Claude Code 用の `.claude/skills/` を自動作成しますが、`~/.codex/skills` は対象外です
- Codex CLI ユーザーは上記の手順で手動設定が必要です
- 初回設定後、`skills/` はアップグレード時に自動更新されるため、シンボリックリンクの再作成は不要です

---

### Gemini CLI

レビューを実行したいときは、該当するスキルファイルを読んでください:

```text
「コードレビューして」と言われたら:
→ skills/reviewing-construction-code/SKILL.md を読んで、その手順に従う

「設計レビューして」と言われたら:
→ skills/reviewing-construction-design/SKILL.md を読んで、その手順に従う

「計画レビューして」と言われたら:
→ skills/reviewing-construction-plan/SKILL.md を読んで、その手順に従う

「結合レビューして」と言われたら:
→ skills/reviewing-construction-integration/SKILL.md を読んで、その手順に従う

「Intentレビューして」と言われたら:
→ skills/reviewing-inception-intent/SKILL.md を読んで、その手順に従う

「ストーリーレビューして」と言われたら:
→ skills/reviewing-inception-stories/SKILL.md を読んで、その手順に従う

「Unitレビューして」と言われたら:
→ skills/reviewing-inception-units/SKILL.md を読んで、その手順に従う

「デプロイレビューして」と言われたら:
→ skills/reviewing-operations-deploy/SKILL.md を読んで、その手順に従う

「プレマージレビューして」と言われたら:
→ skills/reviewing-operations-premerge/SKILL.md を読んで、その手順に従う
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
    "file://skills/aidlc/AGENTS.md",
    "file://skills/reviewing-construction-code/SKILL.md",
    "file://skills/reviewing-construction-design/SKILL.md",
    "file://skills/reviewing-construction-integration/SKILL.md",
    "file://skills/reviewing-construction-plan/SKILL.md",
    "file://skills/reviewing-inception-intent/SKILL.md",
    "file://skills/reviewing-inception-stories/SKILL.md",
    "file://skills/reviewing-inception-units/SKILL.md",
    "file://skills/reviewing-operations-deploy/SKILL.md",
    "file://skills/reviewing-operations-premerge/SKILL.md"
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
├── reviewing-construction-code/        → <MARKETPLACE_ROOT>/skills/reviewing-construction-code/        (シンボリックリンク)
├── reviewing-construction-design/      → <MARKETPLACE_ROOT>/skills/reviewing-construction-design/      (シンボリックリンク)
├── reviewing-construction-integration/ → <MARKETPLACE_ROOT>/skills/reviewing-construction-integration/ (シンボリックリンク)
├── reviewing-construction-plan/        → <MARKETPLACE_ROOT>/skills/reviewing-construction-plan/        (シンボリックリンク)
├── reviewing-inception-intent/         → <MARKETPLACE_ROOT>/skills/reviewing-inception-intent/         (シンボリックリンク)
├── reviewing-inception-stories/        → <MARKETPLACE_ROOT>/skills/reviewing-inception-stories/        (シンボリックリンク)
├── reviewing-inception-units/          → <MARKETPLACE_ROOT>/skills/reviewing-inception-units/          (シンボリックリンク)
├── reviewing-operations-deploy/        → <MARKETPLACE_ROOT>/skills/reviewing-operations-deploy/        (シンボリックリンク)
├── reviewing-operations-premerge/      → <MARKETPLACE_ROOT>/skills/reviewing-operations-premerge/      (シンボリックリンク)
├── aidlc-setup/              → <MARKETPLACE_ROOT>/skills/aidlc-setup/              (シンボリックリンク)
├── squash-unit/              → <MARKETPLACE_ROOT>/skills/squash-unit/              (シンボリックリンク)
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
| `reviewing-construction-code`, `reviewing-construction-design`, `reviewing-construction-integration`, `reviewing-construction-plan`, `reviewing-inception-intent`, `reviewing-inception-stories`, `reviewing-inception-units`, `reviewing-operations-deploy`, `reviewing-operations-premerge`, `aidlc-setup`, `squash-unit` | 不可 | スターターキット予約名（シンボリックリンク） |
| `my-project-lint` | 可 | プロジェクト名プレフィックス推奨 |
| `team-review` | 可 | チーム名プレフィックス推奨 |

### アップグレード時の挙動

- `skills/` は rsync で同期されます（スターターキット提供のスキル）
- `.claude/skills/` 内のプロジェクト独自スキル（実ディレクトリ）はアップグレードの影響を受けません
- シンボリックリンクは `skills/` を参照するため、自動的に最新版が適用されます

---

## トラブルシューティング

### スキルが見つからない

1. スキルファイルが存在するか確認
   ```bash
   ls skills/
   ```
2. セットアップが完了しているか確認（`prompts/setup-prompt.md` を実行）

---

## オプショナルスキル

以下のスキルはスターターキットに同梱されていませんが、外部リポジトリからインストールして利用できます。

### session-title

ターミナルのタブタイトルとiTerm2バッジを設定するスキル（macOS専用）。

**インストール方法**:

Claude Code の場合、`.claude/skills/session-title/` ディレクトリにスキルファイルを配置してください。claude-skills リポジトリからインストールするか、手動で設定できます。

スキルがインストールされていない場合、各フェーズプロンプトのセッション判別設定ステップは自動的にスキップされます。

---

## 関連リンク

- [KiroCLI](https://kiro.dev/docs/cli/)
