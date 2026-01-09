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

**シンプルなアプローチ**: 各ファイルに1つのキーセクションを定義し、そのセクションが欠けていればテンプレートの該当部分全体を追記

| ファイル | キーセクション | 追記内容 |
|---------|---------------|---------|
| CLAUDE.md | `## Claude Code固有の設定` | テンプレートの`## Claude Code固有の設定`以降全体 |
| AGENTS.md | `## 開発サイクルの開始` | テンプレートの`## 開発サイクルの開始`以降全体 |

**処理フロー**:
```text
if キーセクション not found in target_file:
    append テンプレートのキーセクション以降全体 to end of target_file
```

**追記位置**: 常にファイル末尾（冪等性を保証）

## setup-prompt.md 変更設計

### 変更箇所: セクション8.2.3

現在の内容（rules.md, operations.md）に以下を追加:

```markdown
#### 8.2.3 プロジェクト固有ファイル（初回のみコピー / 必須セクション追記）

... (既存のrules.md, operations.md処理)

# CLAUDE.md の処理
if [ ! -f CLAUDE.md ]; then
  \cp -f [スターターキットパス]/prompts/setup/templates/CLAUDE.md.template CLAUDE.md
  echo "Created: CLAUDE.md"
else
  # キーセクションが欠けていれば追記
  if ! grep -q "^## Claude Code固有の設定" CLAUDE.md; then
    echo "" >> CLAUDE.md
    sed -n '/^## Claude Code固有の設定$/,$p' \
      [スターターキットパス]/prompts/setup/templates/CLAUDE.md.template >> CLAUDE.md
    echo "Added: Claude Code settings to CLAUDE.md"
  fi
fi

# AGENTS.md の処理
if [ ! -f AGENTS.md ]; then
  \cp -f [スターターキットパス]/prompts/setup/templates/AGENTS.md.template AGENTS.md
  echo "Created: AGENTS.md"
else
  if ! grep -q "^## 開発サイクルの開始" AGENTS.md; then
    echo "" >> AGENTS.md
    sed -n '/^## 開発サイクルの開始$/,$p' \
      [スターターキットパス]/prompts/setup/templates/AGENTS.md.template >> AGENTS.md
    echo "Added: AI-DLC workflow to AGENTS.md"
  fi
fi
```

**テンプレート更新と既存内容の関係**:
- 既存ファイルのキーセクションは上書きしない（ユーザーのカスタマイズを保護）
- これは意図的な設計

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
