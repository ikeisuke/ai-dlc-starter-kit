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

- インジェクション対策が適切か（SQL、OS コマンド、LDAP）
- アクセス制御が適切に実装されているか（認可バイパスの防止）
- 暗号化が適切か（平文保存の回避、強いアルゴリズムの使用）
- XSS 対策が施されているか（出力エスケープ、CSP）
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
