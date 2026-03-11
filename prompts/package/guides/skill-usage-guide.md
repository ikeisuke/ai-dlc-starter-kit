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
├── reviewing-code/
│   └── SKILL.md        # コードレビュー
├── reviewing-architecture/
│   └── SKILL.md        # アーキテクチャレビュー
├── reviewing-security/
│   └── SKILL.md        # セキュリティレビュー
├── reviewing-inception/
│   └── SKILL.md        # Inceptionレビュー
├── upgrading-aidlc/
│   └── SKILL.md        # AI-DLCアップグレード
└── versioning-with-jj/
    └── SKILL.md        # jjバージョン管理
```

Claude Code では `.claude/skills/` からこれらを参照します。プロジェクト独自スキルの追加方法は後述の「プロジェクト独自スキルの追加」を参照してください。

---

## 利用可能なスキル

### レビュースキル

| レビュー種別 | 読むスキルファイル |
|-------------|-------------------|
| コードレビュー | `docs/aidlc/skills/reviewing-code/SKILL.md` |
| アーキテクチャレビュー | `docs/aidlc/skills/reviewing-architecture/SKILL.md` |
| セキュリティレビュー | `docs/aidlc/skills/reviewing-security/SKILL.md` |
| Inceptionレビュー | `docs/aidlc/skills/reviewing-inception/SKILL.md` |

### ワークフロースキル

| スキル | 読むスキルファイル |
|--------|-------------------|
| AI-DLCアップグレード | `docs/aidlc/skills/upgrading-aidlc/SKILL.md` |
| jjバージョン管理 | `docs/aidlc/skills/versioning-with-jj/SKILL.md` |

---

## 各AIツールでの使い方

### Claude Code

Claude Code には組み込みの Skill ツールがあり、スキルを自動検出します。

```text
/reviewing-code           → コードレビューを実行
/reviewing-architecture   → アーキテクチャレビューを実行
/reviewing-security       → セキュリティレビューを実行
/reviewing-inception      → Inceptionレビューを実行
/upgrading-aidlc          → AI-DLC環境をアップグレード
/versioning-with-jj       → jjバージョン管理
```

セットアップ時に`.claude/skills/`ディレクトリが作成され、各スキルへのシンボリックリンクが配置されます。

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
├── upgrading-aidlc/          → ../../docs/aidlc/skills/upgrading-aidlc/          (シンボリックリンク)
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
| `reviewing-code`, `reviewing-architecture`, `reviewing-security`, `reviewing-inception`, `upgrading-aidlc`, `versioning-with-jj` | 不可 | スターターキット予約名（シンボリックリンク） |
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

---

## 関連リンク

- [KiroCLI](https://kiro.dev/docs/cli/)
