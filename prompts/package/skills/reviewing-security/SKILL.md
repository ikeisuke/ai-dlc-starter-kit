---
name: reviewing-security
description: Reviews code for security vulnerabilities including OWASP Top 10 risks, authentication and authorization flaws, and dependency vulnerabilities. Use when performing security reviews, checking for vulnerabilities, or when the user mentions security review, vulnerability assessment, or security audit.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Security

セキュリティに特化したレビューを実行するスキル。

## レビュー観点

以下の観点でセキュリティをレビューする。

### OWASP Top 10

- インジェクション対策が適切か（SQL、OS コマンド、XSS、LDAP）
- アクセス制御が適切に実装されているか（認可バイパス、IDOR の防止）
- 暗号化が適切か（平文保存の回避、強いアルゴリズムの使用、TLS の適用）
- セキュリティ設定が適切か（デフォルト設定の変更、不要な機能の無効化、エラーメッセージの制御）
- ソフトウェア・データの整合性が保たれているか（署名検証、CI/CD パイプラインの安全性）
- セキュリティログ・監視が適切か（認証イベントの記録、改ざん防止、アラート設定）
- SSRF 対策が施されているか（URL 検証、内部ネットワークへのアクセス制限）

### 認証・認可

- 認証メカニズムが安全か（多要素認証、ブルートフォース対策）
- セッション管理が適切か（セッション固定攻撃の防止、適切な有効期限）
- 最小権限の原則が遵守されているか
- 権限昇格の防止策が実装されているか
- トークン・クレデンシャルが安全に管理されているか（環境変数、シークレットマネージャー）

### 依存脆弱性

- 既知の脆弱性を持つ依存がないか
- 依存バージョンが適切に管理されているか（ロックファイル、バージョン固定）
- サプライチェーンリスクが評価されているか
- 不要な依存が含まれていないか

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
