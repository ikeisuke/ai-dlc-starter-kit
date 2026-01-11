# 論理設計: AIエージェント許可リストガイド

## 成果物

1. `prompts/package/guides/ai-agent-allowlist.md` - 許可リストガイド
2. `prompts/setup-prompt.md` への案内追加

## ドキュメント構成

```
prompts/package/guides/ai-agent-allowlist.md
├── 1. はじめに
│   ├── 目的
│   ├── 適用範囲
│   └── 重要な注意事項（Git hooks/alias、データ漏洩リスク）
├── 2. 推奨アプローチ
│   ├── アプローチA: 許可リスト + denylist
│   └── アプローチB: sandbox環境での実行（推奨）
├── 3. コマンドカテゴリ一覧
│   ├── 3.1 読み取り専用（許可推奨）
│   ├── 3.2 作成系（許可推奨）
│   ├── 3.3 Git操作（条件付き許可）
│   ├── 3.4 破壊的操作（注意が必要）
│   └── 3.5 除外対象（許可非推奨）
├── 4. AIエージェント別設定方法
│   ├── 4.1 Claude Code
│   ├── 4.2 Codex CLI
│   ├── 4.3 Kiro CLI
│   ├── 4.4 Cline
│   └── 4.5 Cursor
├── 5. セキュリティ上の注意事項
│   ├── 5.1 シェル演算子の扱い
│   ├── 5.2 ワイルドカードの限界
│   ├── 5.3 Git hooks/aliasのリスク
│   └── 5.4 推奨対策
└── 6. 参考リンク
```

## セクション詳細

### 1. はじめに

- **目的**: AI-DLCで使用するコマンドの許可リストを整理し、各AIエージェントで効率的に開発できるようにする
- **適用範囲**: Claude Code, Codex CLI, Kiro CLI, Cline, Cursor
- **重要な注意事項**: Git hooks/aliasのリスク、データ漏洩リスク（レビュー反映で追加）

### 2. 推奨アプローチ（レビュー反映で追加）

- **アプローチA**: 許可リスト + denylist（細かい制御が可能）
- **アプローチB**: sandbox環境での実行（推奨、被害を限定）
- Codex CLIはread-onlyを推奨

### 3. コマンドカテゴリ一覧

ドメインモデル設計の表をベースに、5カテゴリに再分類（レビュー反映）:
- 読み取り専用、作成系、Git操作、破壊的操作、除外対象

### 4. AIエージェント別設定方法

各エージェントについて以下を記載:
- 設定ファイルパス
- 設定フォーマット（例示）
- ワイルドカード/パターンの仕様
- 複合コマンドの扱い
- 既知の問題（あれば）

### 5. セキュリティ上の注意事項

- シェル演算子（`&&`, `||`, `;`, `|`）の各ツールでの扱い
- ワイルドカードのバイパス可能性
- Git hooks/aliasのリスク（レビュー反映で追加）
- 推奨対策（sandbox環境、denylist、定期レビュー、Git hooks確認）

### 6. 参考リンク

- 各ツールの公式ドキュメント
- 関連Issue

## setup-prompt.md への追加

セクション10「完了メッセージと次のステップ」に以下を追加:

```markdown
### AIエージェント許可リストの設定（オプション）

AI-DLCではファイル操作やGitコマンドを多用します。
毎回の確認を減らすため、許可リストの設定を推奨します。

詳細は `docs/aidlc/guides/ai-agent-allowlist.md` を参照してください。
```

## ディレクトリ構成

```
prompts/
├── package/
│   ├── guides/           ← 新規作成
│   │   └── ai-agent-allowlist.md
│   ├── prompts/
│   └── templates/
└── setup-prompt.md       ← 案内追加
```

## バックログ追加

AI-DLCプロンプト内の複合コマンド削減について、バックログに追加:

```
docs/cycles/backlog/chore-reduce-compound-commands.md
```
