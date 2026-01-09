# 論理設計: Claude Code機能活用

## 概要
AGENTS.md（共通）とCLAUDE.md（Claude Code専用）の多段参照構造の設計。

**重要**: この論理設計では**コードは書かず**、処理フローと変更箇所の定義のみを行います。

## アーキテクチャパターン
多段ファイル参照 - メインファイルから参照ファイルへの `@` 参照で設定を分離

**設計方針**:
- **AGENTS.md** → 全AIツール共通のAI-DLC設定（Codex、Amazon Q等も対応）
- **CLAUDE.md** → Claude Code専用の設定（AskUserQuestion、TodoWrite等）

## コンポーネント構成

### ファイル構成

```text
prompts/
├── setup-prompt.md              # セットアップエントリーポイント（修正対象）
└── package/
    ├── CLAUDE_AIDLC.md          # Claude Code専用設定（rsync対象）
    ├── AGENTS_AIDLC.md          # 全AIツール共通設定（rsync対象）
    └── templates/
        ├── CLAUDE.md.template   # 削除（不要に）
        └── AGENTS.md.template   # 削除（不要に）

docs/aidlc/
├── CLAUDE_AIDLC.md              # rsyncでコピー - Claude Code専用
└── AGENTS_AIDLC.md              # rsyncでコピー - 全AIツール共通

プロジェクトルート/
├── CLAUDE.md                    # @docs/aidlc/CLAUDE_AIDLC.md を参照
└── AGENTS.md                    # @docs/aidlc/AGENTS_AIDLC.md を参照
```

**AIツール対応表**:
| AIツール | 読み込むファイル |
|---------|-----------------|
| Claude Code | CLAUDE.md → AGENTS.md |
| Codex | AGENTS.md |
| Amazon Q | AGENTS.md |
| その他 | AGENTS.md |

### コンポーネント詳細

#### CLAUDE_AIDLC.md（新規作成）
- **責務**: Claude Code固有のAI-DLC設定
- **配置**: `prompts/package/` → rsync → `docs/aidlc/`
- **内容**: AskUserQuestion活用ルール、TodoWrite活用ルール等

#### AGENTS_AIDLC.md（新規作成）
- **責務**: AI-DLCプロンプト自動解決の基本構造
- **配置**: `prompts/package/` → rsync → `docs/aidlc/`
- **内容**: 開発サイクルの開始方法、推奨ワークフロー、ドキュメント参照

#### setup-prompt.md
- **責務**: セットアップフロー全体の制御
- **修正箇所**: セクション8.2.3「プロジェクト固有ファイル」
- **追加機能**: CLAUDE.md/AGENTS.mdへの参照行追記処理

#### CLAUDE.md.template / AGENTS.md.template
- **状態**: 削除（不要に）
- **理由**: 多段参照方式に変更のため

## 処理フロー概要

### CLAUDE.md/AGENTS.md処理フロー（セクション8.2.3拡張）

**ステップ**:
1. AGENTS.mdの存在確認
   - 存在しない場合: 最小限のAGENTS.mdを作成（参照行のみ）
   - 存在する場合: 参照行の存在確認、なければ追記
2. CLAUDE.mdについても同様に処理

**関与するファイル**: setup-prompt.md, CLAUDE_AIDLC.md, AGENTS_AIDLC.md

### 参照行追記ロジック

**シンプルなアプローチ**: 参照行が欠けていれば追記

| ファイル | 参照行 |
|---------|--------|
| AGENTS.md | `@docs/aidlc/AGENTS_AIDLC.md` |
| CLAUDE.md | `@AGENTS.md` + `@docs/aidlc/CLAUDE_AIDLC.md` |

**処理フロー**:
```text
# AGENTS.md
if @docs/aidlc/AGENTS_AIDLC.md not found:
    prepend to AGENTS.md

# CLAUDE.md
if @AGENTS.md not found:
    prepend @AGENTS.md to CLAUDE.md
if @docs/aidlc/CLAUDE_AIDLC.md not found:
    prepend to CLAUDE.md
```

**追記位置**: ファイル先頭（参照を最初に読み込ませるため）

## setup-prompt.md 変更設計

### 変更箇所: セクション8.2.3

現在の内容（rules.md, operations.md）に以下を追加:

```markdown
#### 8.2.3 プロジェクト固有ファイル（初回のみコピー / 参照行追記）

... (既存のrules.md, operations.md処理)

# AGENTS.md の処理（全AIツール共通）
AGENTS_REF="@docs/aidlc/AGENTS_AIDLC.md"
if [ ! -f AGENTS.md ]; then
  echo "# AGENTS.md" > AGENTS.md
  echo "" >> AGENTS.md
  echo "${AGENTS_REF}" >> AGENTS.md
  echo "Created: AGENTS.md"
else
  if ! grep -q "${AGENTS_REF}" AGENTS.md; then
    # 先頭に参照行を追記
    echo -e "${AGENTS_REF}\n\n$(cat AGENTS.md)" > AGENTS.md
    echo "Added reference: ${AGENTS_REF} to AGENTS.md"
  fi
fi

# CLAUDE.md の処理（Claude Code専用）
CLAUDE_REF="@docs/aidlc/CLAUDE_AIDLC.md"
if [ ! -f CLAUDE.md ]; then
  echo "# CLAUDE.md" > CLAUDE.md
  echo "" >> CLAUDE.md
  echo "${CLAUDE_REF}" >> CLAUDE.md
  echo "Created: CLAUDE.md"
else
  if ! grep -q "${CLAUDE_REF}" CLAUDE.md; then
    echo -e "${CLAUDE_REF}\n\n$(cat CLAUDE.md)" > CLAUDE.md
    echo "Added reference: ${CLAUDE_REF} to CLAUDE.md"
  fi
fi
```

**利点**:
- 参照先ファイル（_AIDLC.md）はrsyncで常に最新化される
- ユーザーのカスタマイズ（CLAUDE.md/AGENTS.md本体）は保護される
- 参照行の追記のみなので、既存内容への影響が最小限

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
