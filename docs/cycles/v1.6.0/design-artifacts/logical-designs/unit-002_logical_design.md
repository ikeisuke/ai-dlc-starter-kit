# 論理設計: Claude Code機能活用

## 概要
CLAUDE.md/AGENTS.mdテンプレートの配置場所変更と、setup-prompt.mdへのコピー・マージ処理追加の設計。

**重要**: この論理設計では**コードは書かず**、処理フローと変更箇所の定義のみを行います。

## アーキテクチャパターン
ファイルベース設定管理 - テンプレートとターゲットファイルの関係を明確に定義

## コンポーネント構成

### ファイル構成

```text
prompts/
├── setup-prompt.md          # セットアップエントリーポイント（修正対象）
├── package/
│   └── templates/           # rsync同期対象
│       ├── CLAUDE.md.template   # 削除（移動元）
│       └── AGENTS.md.template   # 削除（移動元）
└── setup/
    └── templates/           # 初回のみコピー対象
        ├── rules_template.md
        ├── operations_handover_template.md
        ├── CLAUDE.md.template   # 追加（移動先）
        └── AGENTS.md.template   # 追加（移動先）
```

### コンポーネント詳細

#### setup-prompt.md
- **責務**: セットアップフロー全体の制御
- **修正箇所**: セクション8.2.3「プロジェクト固有ファイル」
- **追加機能**: CLAUDE.md/AGENTS.mdのコピー・マージ処理

#### CLAUDE.md.template
- **責務**: Claude Code固有設定のテンプレート
- **必須セクション**:
  - `## Claude Code固有の設定`
  - `### 質問時のルール`
  - `### TodoWriteツールの活用`

#### AGENTS.md.template
- **責務**: AI-DLCプロンプト自動解決の基本構造
- **必須セクション**:
  - `## 開発サイクルの開始`
  - `## 推奨ワークフロー`
  - `## ドキュメント`

## 処理フロー概要

### CLAUDE.md/AGENTS.md処理フロー（セクション8.2.3拡張）

**ステップ**:
1. CLAUDE.mdの存在確認
2. 存在しない場合: テンプレートをコピー
3. 存在する場合: 必須セクションの存在を確認し、欠けていれば追記
4. AGENTS.mdについても同様に処理

**関与するファイル**: setup-prompt.md, CLAUDE.md.template, AGENTS.md.template

### 必須セクション追記ロジック

```text
for each required_section in template:
    if required_section.header not in target_file:
        append required_section to target_file
```

**セクション識別方法**: 見出し行（`## `, `### `）でマッチング

## setup-prompt.md 変更設計

### 変更箇所: セクション8.2.3

現在の内容（rules.md, operations.md）に以下を追加:

```markdown
#### 8.2.3 プロジェクト固有ファイル（初回のみコピー / 必須セクション追記）

... (既存のrules.md, operations.md処理)

# CLAUDE.md の処理
if [ ! -f CLAUDE.md ]; then
  # ファイルが存在しない場合: テンプレートをコピー
  \cp -f [スターターキットパス]/prompts/setup/templates/CLAUDE.md.template CLAUDE.md
  echo "Created: CLAUDE.md"
else
  # ファイルが存在する場合: 必須セクションを確認・追記
  # 「## Claude Code固有の設定」セクションの存在確認
  if ! grep -q "^## Claude Code固有の設定" CLAUDE.md; then
    echo "" >> CLAUDE.md
    echo "## Claude Code固有の設定" >> CLAUDE.md
    echo "" >> CLAUDE.md
    echo "(以降、テンプレートから必須セクションを追記)"
    # テンプレートから該当セクションを抽出して追記
  fi
fi

# AGENTS.md の処理（同様のロジック）
if [ ! -f AGENTS.md ]; then
  \cp -f [スターターキットパス]/prompts/setup/templates/AGENTS.md.template AGENTS.md
  echo "Created: AGENTS.md"
else
  # 必須セクションの確認・追記
  if ! grep -q "^## 開発サイクルの開始" AGENTS.md; then
    # テンプレートから該当セクションを抽出して追記
  fi
fi
```

### 追加する説明文

| ファイル | 説明 |
|--------|------|
| `CLAUDE.md` | Claude Code固有の設定（AskUserQuestion活用等） |
| `AGENTS.md` | AI-DLCプロンプト自動解決の基本構造 |

## 非機能要件（NFR）への対応

### パフォーマンス
- N/A（セットアップ時のみ実行）

### セキュリティ
- N/A

### スケーラビリティ
- N/A

### 可用性
- 既存ファイルは上書きしない（安全性重視）

## 技術選定
- **言語**: Bash（setup-prompt.md内のスクリプト）
- **ツール**: grep, cp

## 実装上の注意事項
- 既存ファイルの内容を破壊しないこと
- セクション追記時は空行を適切に挿入すること
- テンプレートからのセクション抽出は見出しレベルを考慮すること

## 不明点と質問（設計中に記録）

（なし）
