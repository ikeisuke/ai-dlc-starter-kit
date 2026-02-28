---
name: reviewing-inception
description: Reviews Inception Phase artifacts including Intent clarity, user story quality (INVEST), and Unit definition completeness. Use when reviewing inception artifacts, checking requirements quality, or when the user mentions inception review, requirements review, or unit definition review.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Inception

Inception Phase成果物に特化したレビューを実行するスキル。

## レビュー観点

以下の観点でInception Phase成果物をレビューする。

### Intent品質

- 目的・狙いが明確で妥当か
- スコープが明確に定義されているか（含まれるもの・除外されるもの）
- 曖昧な表現や解釈の余地がないか
- 期待する成果が具体的か
- 既存機能への影響が考慮されているか

### ユーザーストーリー品質

- INVEST原則（Independent, Negotiable, Valuable, Estimable, Small, Testable）への準拠
- 受け入れ基準が具体的で検証可能か
- ユーザー視点で価値が明確か
- 正常系・異常系が網羅されているか
- ストーリー間の重複・矛盾がないか

### Unit定義品質

- Unit分割が適切か（独立性、凝集性）
- 依存関係が正しく定義されているか
- 見積もりが妥当か
- 実装順序に矛盾がないか
- 責務と境界が明確に定義されているか

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
