# 論理設計: AGENTS.md/CLAUDE.md統合

## 概要

AIエージェントがAI-DLCスターターキットを自動認識できるようにするための設定ファイル（AGENTS.md、CLAUDE.md）の構成と内容を定義する。

**重要**: この論理設計では**コードは書かず**、ファイル構成と内容定義のみを行います。

## アーキテクチャパターン

**参照委譲パターン**: CLAUDE.md から AGENTS.md への @参照により、共通情報は AGENTS.md に集約し、ツール固有設定のみ個別ファイルに記載する。

## ファイル構成

```
プロジェクトルート/
├── AGENTS.md          # 汎用AIエージェント向け設定
├── CLAUDE.md          # Claude Code固有設定
└── prompts/
    ├── setup-prompt.md
    └── package/
        └── templates/
            ├── AGENTS.md.template  # テンプレート（新規）
            └── CLAUDE.md.template  # テンプレート（新規）
```

## ファイル詳細設計

### AGENTS.md

#### 構成

```markdown
# AGENTS.md

このプロジェクトはAI-DLC（AI-Driven Development Lifecycle）を使用しています。

## 開発サイクルの開始

### 初期セットアップ / アップグレード
`prompts/setup-prompt.md` を読み込んでください。
（スターターキットの初期セットアップ、バージョンアップ、または移行時に使用）

### 新規サイクル開始
`docs/aidlc/prompts/setup.md` を読み込んでください。
（既存プロジェクトで新しいサイクルを開始する場合に使用）

### 既存サイクルの継続
以下のプロンプトを読み込んでください：

- Inception Phase: `docs/aidlc/prompts/inception.md`
- Construction Phase: `docs/aidlc/prompts/construction.md`
- Operations Phase: `docs/aidlc/prompts/operations.md`

## 推奨ワークフロー

1. 初回は `prompts/setup-prompt.md` でセットアップ
2. `docs/aidlc/prompts/setup.md` でサイクルを作成
3. Inception Phaseで要件定義とUnit分解
4. Construction Phaseで設計と実装
5. Operations Phaseでデプロイと運用

## ドキュメント

- 設定: `docs/aidlc.toml`
- 追加ルール: `docs/cycles/rules.md`
```

#### セクション責務

| セクション | 責務 |
|-----------|------|
| 開発サイクルの開始 | プロンプトファイルへのパスを提供 |
| 推奨ワークフロー | 基本的な使い方を説明 |
| ドキュメント | 設定ファイルの場所を案内 |

### CLAUDE.md

#### 構成

```markdown
# CLAUDE.md

@AGENTS.md を参照してください。

## Claude Code固有の設定

### 質問時のルール

AI-DLCプロンプトで質問する際は、選択肢が明確な場合はAskUserQuestion機能を使用してください。
自由回答が必要な場合はテキストで質問してください。

### TodoWriteツールの活用

タスク管理にはTodoWriteツールを積極的に使用してください。
```

#### セクション責務

| セクション | 責務 |
|-----------|------|
| @AGENTS.md参照 | 汎用設定への委譲 |
| Claude Code固有の設定 | Claude Code特有の機能活用指示 |

## テンプレート設計

### ソース・オブ・トゥルース

**正規ソース**: `prompts/package/templates/` 内のテンプレートファイル

**セットアップ時の動作**:
1. **既存ファイルが存在しない場合**: テンプレートをコピー
2. **既存ファイルが存在する場合**: 内容を確認し、AI-DLCセクションがなければ追記

**更新フロー**:
1. 変更は `prompts/package/templates/AGENTS.md.template` または `CLAUDE.md.template` に対して行う
2. Operations Phase の rsync でスターターキット配布時に反映
3. 新規プロジェクトはセットアップ時にテンプレートからコピー
4. 既存プロジェクト: 既存ファイルに追記（上書きしない）

### prompts/package/templates/AGENTS.md.template

AGENTS.md のテンプレート。セットアップ時にプロジェクトルートに配置される。

### prompts/package/templates/CLAUDE.md.template

CLAUDE.md のテンプレート。セットアップ時にプロジェクトルートに配置される。

## 非機能要件（NFR）への対応

- **パフォーマンス**: N/A（静的ドキュメント）
- **セキュリティ**: N/A（機密情報なし）
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術選定

- **形式**: Markdown
- **文字コード**: UTF-8
- **改行コード**: LF

## 実装上の注意事項

1. **@参照の動作確認**: CLAUDE.md の @AGENTS.md 参照が正しく機能することを確認
2. **パスの整合性**: 記載するファイルパスが実際のファイル構成と一致していることを確認
3. **テンプレート配置**: `prompts/package/templates/` にテンプレートを配置し、セットアップスクリプトでコピーされることを確認

## セットアッププロセスへの統合

### setup-prompt.md への追記（必要な場合）

セットアップ時に AGENTS.md と CLAUDE.md をプロジェクトルートにコピーする処理を追加する必要があるか検討。

**選択肢**:
1. テンプレートとして配置し、セットアップ時にコピー
2. セットアッププロンプト内で生成指示を追加
3. ユーザーが手動で配置（非推奨）

## 不明点と質問

設計に関する不明点はありません。ドメインモデル設計で確認済みの内容に基づいて設計しました。
