---
name: reviewing-architecture
description: Reviews architecture for structural issues including layer separation, design patterns, API design, and dependency management. Use when performing architecture reviews, checking system design, or when the user mentions architecture review, design review, or structural analysis.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Architecture

アーキテクチャ・設計に特化したレビューを実行するスキル。

## レビュー観点

以下の観点でアーキテクチャをレビューする。

### 構造（Structure）

- レイヤー間の責務が明確に分離されているか
- モジュール/パッケージの凝集度は適切か
- コンポーネント間のインターフェースが明確に定義されているか
- ビジネスロジックがプレゼンテーション層やインフラ層に漏れ出していないか

### パターン（Patterns）

- 採用されたデザインパターンが問題に対して適切か
- アンチパターン（God Class、Spaghetti Code等）が含まれていないか
- パターンの過剰適用（Over-engineering）がないか
- プロジェクト内でパターンの適用が一貫しているか

### API設計（API Design）

- エンドポイント/インターフェースの命名が一貫しているか
- 入出力の型定義が明確か
- エラーハンドリングの方針が統一されているか
- バージョニング・後方互換性が考慮されているか

### 依存関係（Dependencies）

- 依存方向が適切か（上位レイヤーが下位に依存しない等）
- 循環依存が存在しないか
- コンポーネント間の境界（コンテキスト境界）が明確に定義されているか
- 障害の伝播が適切に分離されているか（障害分離）

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
