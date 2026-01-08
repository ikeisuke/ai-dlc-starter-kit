# ドメインモデル: AGENTS.md/CLAUDE.md統合

## 概要

AIエージェント（Claude Code等）がAI-DLCスターターキットの存在を自動認識できるようにするための設定ファイル構造を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## ドキュメント構造（エンティティに相当）

### AGENTS.md

汎用的なAIエージェント向け設定ファイル。AI-DLCスターターキットの存在と使用方法を記述する。

- **配置場所**: プロジェクトルート
- **対象**: 全てのAIエージェント（Claude Code、GitHub Copilot、Cursor等）
- **責務**:
  - AI-DLCスターターキットの存在を宣言
  - 各フェーズの開始方法を提供
  - 推奨ワークフローを説明

- **セクション構造**:
  1. **AI-DLCスターターキット**: 概要説明
  2. **サイクルの開始**: 各プロンプトファイルへのパス
  3. **推奨ワークフロー**: 基本的な使い方

### CLAUDE.md

Claude Code固有の設定ファイル。AGENTS.mdを参照しつつ、Claude Code特有の機能活用を指示する。

- **配置場所**: プロジェクトルート
- **対象**: Claude Code
- **責務**:
  - AGENTS.mdへの参照を提供
  - Claude Code固有の機能（AskUserQuestion等）の活用を指示
  - プロジェクト固有の設定を補完

- **セクション構造**:
  1. **参照**: @AGENTS.md
  2. **質問時のルール**: AskUserQuestion機能の活用指示
  3. **タスク管理**: TodoWriteツールの活用指示
  4. **追加設定**: プロジェクト固有の制約

## 参照関係（集約に相当）

```mermaid
graph LR
    A[CLAUDE.md] -->|@参照| B[AGENTS.md]
    B -->|パス参照| C[prompts/setup-prompt.md]
    B -->|パス参照| D[docs/aidlc/prompts/*.md]
```

- **CLAUDE.md → AGENTS.md**: @AGENTS.md 形式で参照
- **AGENTS.md → プロンプトファイル**: パス文字列で参照

## 責務分離の原則

| ファイル | 責務 | 対象読者 |
|---------|------|----------|
| AGENTS.md | AI-DLC汎用情報 | 全AIエージェント |
| CLAUDE.md | Claude Code固有設定 | Claude Code |

**設計方針**:
- 汎用的な情報はAGENTS.mdに集約
- Claude Code固有の機能活用はCLAUDE.mdに記載
- 他のAIエージェント固有ファイル（例: COPILOT.md）を追加しやすい構造

## テンプレート化の検討

### prompts/package/templates/ への追加

Operations Phase でスターターキットを配布する際、AGENTS.md と CLAUDE.md もテンプレートとして配布することを検討。

**候補**:
- `prompts/package/templates/AGENTS.md.template`
- `prompts/package/templates/CLAUDE.md.template`

ただし、これらはプロジェクトルートに配置するため、テンプレートではなく直接コピーされるファイルとして扱う方が適切かもしれない。

## ユビキタス言語

- **AGENTS.md**: 複数のAIコーディングエージェントが参照可能な汎用設定ファイル
- **CLAUDE.md**: Claude Code専用の設定ファイル（@参照でAGENTS.mdを読み込む）
- **@参照**: Claude Codeの機能で、別ファイルの内容を自動的に読み込む構文
- **AskUserQuestion**: Claude Codeの機能で、選択肢を提示してユーザーに回答を求める

## 不明点と質問

[Question] AGENTS.mdに記載するプロンプトファイルのパスについて:
- セットアップ: `prompts/setup-prompt.md`
- Inception: `docs/aidlc/prompts/inception.md`
- Construction: `docs/aidlc/prompts/construction.md`
- Operations: `docs/aidlc/prompts/operations.md`
この構成でよろしいですか？

[Answer] はい、この構成でOK（2026-01-08）
