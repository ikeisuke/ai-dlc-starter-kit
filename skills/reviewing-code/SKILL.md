---
name: reviewing-code
description: Reviews code for quality issues including readability, maintainability, performance, and test quality. Use when performing code reviews, checking code quality, or when the user mentions code review, code quality, or refactoring suggestions.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Code

コード品質に特化したレビューを実行するスキル。

## レビュー観点

以下の観点でコードをレビューする。

### 可読性

- 命名規則が一貫しているか（変数名、関数名、クラス名）
- 関数/メソッドが適切な長さか（単一責任）
- ネストが深すぎないか
- コメントが適切か（なぜを説明、何をは自明にする）
- コードの意図が読み手に明確か

### 保守性

- 単一責任原則を遵守しているか
- DRY原則に従っているか（重複コードがないか）
- 疎結合・高凝集か
- 将来の変更に対して拡張しやすいか
- 依存関係が明確で管理されているか

### パフォーマンス

- アルゴリズムの計算量は適切か
- 不要な再計算やループがないか
- メモリリークの可能性はないか
- I/O操作が効率的か
- N+1問題などのデータアクセスパターンの問題がないか

### テスト品質

- テストカバレッジが十分か
- 境界値テストが含まれているか
- テスト名が何をテストしているか明確か
- 各テストが独立しているか
- アサーションが適切で意味のあるエラーメッセージを含むか

### ASCII図バリデーション

対象ファイルにASCII図（罫線で描画された図）が含まれる場合にのみ適用する。

- 罫線接続: ボックス間の接続線（`─`, `│`, `┌`, `┐`, `└`, `┘`, `├`, `┤`, `┬`, `┴`, `┼`, `|`, `-`, `+`等）が途切れず接続されているか
- ラベル対応: 図中のラベル（ボックス内テキスト、矢印ラベル）が本文の用語・定義と一致しているか
- 交差線ゼロ原則: 接続線の交差を避けるレイアウトになっているか。交差が不可避な場合は交差理由がコメントまたは本文で説明されているか
- 整列・余白: ボックスやラベルの水平・垂直方向の整列が一貫しているか

### Mermaid図バリデーション

対象ファイルにMermaidコードブロック（` ```mermaid `）が含まれる場合にのみ適用する。

#### 共通観点

- 構文準拠: Mermaid公式構文に準拠しているか（宣言キーワード、ノード定義、エッジ記法）
- ノードID/ラベル重複: 同一図内でノードIDが重複していないか（ID重複は原則NG）。ラベルの重複は、文脈上の曖昧性がある場合のみ指摘する

#### 対象6種別と種別固有観点

| 種別 | 宣言キーワード |
|------|-------------|
| flowchart | `flowchart` / `graph` |
| sequenceDiagram | `sequenceDiagram` |
| classDiagram | `classDiagram` |
| stateDiagram | `stateDiagram-v2` / `stateDiagram` |
| erDiagram | `erDiagram` |
| gantt | `gantt` |

- flowchart: 方向（`TB`, `TD`, `LR`, `RL`, `BT`）が明示されているか
- sequenceDiagram: `participant`/`actor`の明示定義が望ましい（暗黙定義でも構文上妥当であれば許容）
- classDiagram: 継承（`<|--`）、実装（`<|..`）、関連（`-->`）等の関係記法が正しいか
- stateDiagram: 遷移（`-->`）、開始状態（`[*]`）、終了状態（`[*]`）が適切に定義されているか
- erDiagram: カーディナリティ記法（`||--o{`等）が正しいか
- gantt: `dateFormat`が指定されているか

#### 構文検証対象外の種別

上記対象6種別以外のMermaid図種別はすべて構文検証の対象外とする。対象外種別については構文の検証は行わないが、図としての可読性（ラベルの明確さ、本文との整合性）は可読性カテゴリの一般ルールで確認する。

既知の対象外種別: `pie`, `mindmap`, `timeline`, `journey`, `quadrantChart`, `gitGraph`, `c4Context`/`c4Container`/`c4Component`/`c4Deployment`, `block-beta`, `sankey-beta`, `xychart-beta`, `packet-beta`, `kanban`, `architecture-beta`

## 実行コマンド

### Codex

```bash
codex exec -s read-only -C . "<レビュー指示>"
```

### Claude Code

```bash
claude -p --output-format stream-json "<レビュー指示>"
```

### Gemini

```bash
gemini -p "<レビュー指示>" --sandbox
```

## セッション継続

反復レビュー時は前回のセッションを継続する。

- **Codex**: `codex exec resume <session-id> "<指示>"`
- **Claude**: `claude --session-id <uuid> -p --output-format stream-json "<指示>"`
- **Gemini**: `gemini --resume <session_index> -p "<指示>"`

詳細は [references/session-management.md](references/session-management.md) を参照。

## 外部ツールとの関係

このスキルは2つのモードで動作する:

1. **通常モード（外部CLI使用）**: 外部CLIツール（codex / claude / gemini）を使用してレビューを実行する。呼び出し元が `優先ツール: [tool]` を引数に含める
2. **セルフレビューモード（フォールバック）**: 外部CLIが利用不可の場合に使用する。呼び出し元が `self-review` を引数の先頭トークンに含める

**責務の分離**:

- **呼び出し元（review-flow.md）**: 実行モードを決定し、適切な引数でスキルを呼び出す。ステップ3で外部CLI可用性を事前チェックする
- **スキル側**: 受け取った引数を解釈し、指定されたモードでレビューを実行する
- 外部CLIが利用可能な場合は、呼び出し元が常に通常モード（外部CLI使用）を選択する
- セルフレビューモードは、外部CLIが利用不可の場合のフォールバックとしてのみ使用される

## セルフレビューモード

引数の先頭トークンが `self-review` の場合、このモードで実行する。
引数の残り部分はレビュー対象ファイルパス（半角スペース区切り）。空白を含むファイルパスは非対応。

セルフレビューモードでは外部CLI（codex / claude / gemini）は使用しない。

### 手順

1. 引数の先頭トークン `self-review` を除去し、残りをレビュー対象ファイルパスとして取得する
2. 上記「レビュー観点」セクションの基準に基づいてレビューを実行する
3. レビュー結果は呼び出し元のフロー（review-flow.md）で定義されたセルフレビュー出力フォーマットに準拠して返す

### 実行方式

- **サブエージェント方式（推奨）**: Taskツールで `subagent_type: "general-purpose"` を起動し、以下の指示テンプレートを渡す。サブエージェントは読み取り専用の指示に従うこと（技術的な強制はプラットフォーム依存。指示テンプレート内の制約が実質的な手段）
- **インライン方式（フォールバック）**: サブエージェント起動失敗時（Taskツール利用不可含む）、メインエージェント自身がレビューを実施する。フォールバック発生時はその旨を結果に含める

### サブエージェントへの指示テンプレート

````text
以下のファイルをレビューしてください。
あなたの役割は読み取り専用のレビュアーです。ファイルの読み取りと評価のみを行い、ファイルの編集・コマンド実行・外部通信は行わないでください。

**レビュー種別**: {review_type}

**対象ファイル**:
{target_files を改行区切りで列挙}

**レビュー観点**:
{本SKILL.mdの「レビュー観点」セクション内容}

**出力フォーマット**:
レビュー結果を以下のフォーマットで出力してください。

指摘がある場合:

指摘 #1
- 重要度: {高 | 中 | 低}
- 内容: {指摘内容の要約}
- 推奨修正: {修正方法の提案}

指摘 #2
...

合計: {N}件（高: {n}件 / 中: {n}件 / 低: {n}件）

指摘がない場合:
指摘0件
````

### 制約

- ファイルの編集・コマンド実行・外部通信は行わない（読み取り専用）
- 機密情報（秘密鍵・トークン・個人情報等）はレビュー出力に含めない
- セルフレビューは外部ツールに比べて品質が劣る可能性がある
