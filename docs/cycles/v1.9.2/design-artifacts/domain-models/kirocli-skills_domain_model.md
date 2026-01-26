# ドメインモデル: KiroCLI Skills対応

## 概要

KiroCLIから他のAIツール（Codex、Claude、Gemini）をSkillsとして呼び出せるようにする。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。

## 目的

KiroCLIユーザーがKiro内から以下のAIツールを呼び出せるようにする：
- Codex CLI（コードレビュー、分析）
- Claude Code CLI（コードレビュー、分析）
- Gemini CLI（コードレビュー、分析）

## 調査結果の整理

### KiroCLI Skills機能の特徴

| 項目 | 内容 |
|------|------|
| ファイル形式 | Markdown + YAMLフロントマター |
| 必須フィールド | `name`, `description` |
| 読み込み方式 | プログレッシブローディング（メタデータ先行読み込み） |
| 参照方式 | `skill://` URIスキーム |
| 保存場所 | `.kiro/skills/**/SKILL.md` |

### 既存スキルとの互換性

| 項目 | AI-DLC既存スキル | KiroCLI要件 | 互換性 |
|------|------------------|-------------|--------|
| フロントマター | あり (name, description) | 必須 | **互換** |
| ファイル形式 | Markdown | Markdown | **互換** |
| 内容 | CLIコマンドの使い方 | 任意の知識 | **互換** |

**結論**: 既存の `prompts/package/skills/` 配下のスキルファイルはKiroCLI形式と互換性がある。

## エンティティ

### Skill (スキル)

- **識別子**: name (フロントマターで定義)
- **属性**:
  - `name`: String - スキルの識別名（例: codex, claude, gemini）
  - `description`: String - スキルの説明、用途
  - `content`: Markdown - CLIコマンドの使い方
- **振る舞い**:
  - KiroCLIエージェントに呼び出し方法を提供
  - プログレッシブローディングで効率的に読み込まれる

### KiroCLI Agent (エージェント設定)

- **識別子**: name (JSONファイル名)
- **属性**:
  - `resources`: Array - `skill://` URIでスキルを参照
  - `tools`: Array - shell等のツール（CLIコマンド実行に必要）
- **振る舞い**:
  - スキルの指示に従い外部CLIツールを実行

## 設計方針

### 方針: セットアップ時にエージェント設定を自動生成

既存の `docs/aidlc/skills/{codex,claude,gemini}/SKILL.md` はKiroCLI形式と互換。
**セットアップ時に `.kiro/agents/aidlc.json` を自動生成**し、スキルを参照する。

**生成されるエージェント設定**:
```json
{
  "name": "aidlc",
  "description": "AI-DLC開発支援エージェント。Codex、Claude、Gemini CLIを呼び出してコードレビューや分析を実行できます。",
  "tools": ["read", "write", "shell"],
  "resources": [
    "skill://docs/aidlc/skills/codex/SKILL.md",
    "skill://docs/aidlc/skills/claude/SKILL.md",
    "skill://docs/aidlc/skills/gemini/SKILL.md"
  ]
}
```

### 変更対象ファイル

```
prompts/setup-prompt.md  # KiroCLIエージェント設定生成処理を追加
```

## ディレクトリ構造

### AI-DLC側（既存、変更なし）

```
prompts/package/skills/
├── codex/SKILL.md    # Codex CLI呼び出し方法
├── claude/SKILL.md   # Claude Code CLI呼び出し方法
└── gemini/SKILL.md   # Gemini CLI呼び出し方法
```

### プロジェクト側（セットアップ時に生成）

```
.kiro/agents/
└── aidlc.json        # AI-DLCエージェント設定（自動生成）
```

## ユビキタス言語

| 用語 | 定義 |
|------|------|
| Skill | KiroCLIエージェントが参照できる知識ドキュメント |
| Progressive Loading | メタデータ先行読み込みによる効率的なコンテキスト管理 |
| skill:// URI | KiroCLIでスキルファイルを参照するURIスキーム |

## 不明点と質問

（なし - 目的が明確化された）
