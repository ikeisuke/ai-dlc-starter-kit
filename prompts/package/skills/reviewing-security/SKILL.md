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

以下の観点でセキュリティをレビューする。各観点はAmazon AIDLC SECURITY-01〜15に対応している（対応表は末尾を参照）。

### OWASP Top 10

- インジェクション対策が適切か（SQL、OS コマンド、XSS、LDAP）
- アクセス制御が適切に実装されているか（認可バイパス、IDOR の防止）
- 暗号化が適切か（平文保存の回避、強いアルゴリズムの使用、TLS の適用）
- 保存時暗号化（encryption at rest）が適用されているか（データベース、ファイルストレージ、バックアップ）
- セキュリティ設定が適切か（デフォルト設定の変更、不要な機能の無効化、エラーメッセージの制御）
- デフォルトクレデンシャルが変更されているか、不要なサービス・ポートが無効化されているか
- HTTPセキュリティヘッダーが適切に設定されているか（Content-Security-Policy、Strict-Transport-Security、X-Content-Type-Options、X-Frame-Options、Referrer-Policy）
- ソフトウェア・データの整合性が保たれているか（署名検証、CI/CD パイプラインの安全性）
- セキュリティログ・監視が適切か（認証イベントの記録、改ざん防止、アラート設定）
- SSRF 対策が施されているか（URL 検証、内部ネットワークへのアクセス制限）
- 例外処理でセキュリティ情報が漏洩しないか（スタックトレース、内部パス、デバッグ情報）
- フェイルセーフデフォルトが実装されているか（失敗時にセキュアな状態にフォールバックする設計）

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
- ソフトウェア成果物の整合性が検証されているか（署名検証、チェックサム確認）
- データの完全性チェックが実装されているか（改ざん検知、ハッシュ検証）

### ログ・監視

- ネットワーク中間点（ロードバランサー、APIゲートウェイ、プロキシ）でアクセスログが有効化されているか
- アプリケーションレベルのログが適切に実装されているか（認証イベント、権限変更、データアクセス）
- ログに機密情報（パスワード、トークン、個人情報）が含まれていないか
- ログの保存期間と保護が適切か（改ざん防止、アクセス制限）
- セキュリティイベントに対するアラートが設定されているか
- 監視ダッシュボードまたは通知が構成されているか
- 異常検知の仕組みがあるか（閾値ベース、パターンベース）

### ネットワークセキュリティ

- ネットワーク設定が最小権限原則に基づいているか（不要なポートの閉鎖、セキュリティグループ/ファイアウォールルールの制限）
- 内部サービス間通信が適切に分離されているか（VPC、サブネット、セグメンテーション）
- パブリックアクセスが必要最小限に制限されているか
- 通信経路が暗号化されているか（TLS/mTLS）

### セキュアデザイン

- 脅威モデリングが実施されているか（STRIDE等）
- セキュリティ要件がアーキテクチャ設計に組み込まれているか
- 攻撃面（Attack Surface）が最小化されているか
- 防御の多層化（Defense in Depth）が考慮されているか

### N/A判定ガイダンス

プロジェクトの特性により一部の観点が該当しない場合がある。N/A判定時はレビュー記録に「N/A: 理由」を明記すること。下表に記載のないカテゴリは原則N/A不可とし、N/Aとする場合は具体的な技術的理由を必須とする。

| カテゴリ | N/A条件の例 |
|---------|-----------|
| ログ・監視 | ネットワーク中間点を使用しないローカルアプリケーション |
| ネットワークセキュリティ | ネットワーク通信を行わないCLIツール・ライブラリ |
| セキュアデザイン | 設計フェーズが対象外のバグ修正・パッチ変更 |
| OWASP Top 10（HTTP関連） | HTTPを使用しないバッチ処理・データパイプライン |

### SECURITY-01〜15 対応表

| rule_id | タイトル | カテゴリ | チェック項目 |
|---------|---------|---------|-----------|
| SECURITY-01 | Encryption at Rest and in Transit | OWASP Top 10 | 暗号化（平文回避・強アルゴリズム・TLS）、保存時暗号化（DB・ストレージ・バックアップ） |
| SECURITY-02 | Access Logging on Network Intermediaries | ログ・監視 | ネットワーク中間点（LB・APIゲートウェイ・プロキシ）のアクセスログ有効化 |
| SECURITY-03 | Application-Level Logging | ログ・監視 | アプリケーションログ（認証・権限変更・データアクセス）、ログへの機密情報混入防止、ログ保存期間・保護 |
| SECURITY-04 | HTTP Security Headers | OWASP Top 10 | HTTPセキュリティヘッダー（CSP・HSTS・X-Content-Type-Options・X-Frame-Options・Referrer-Policy） |
| SECURITY-05 | Input Validation on All API Parameters | OWASP Top 10 | インジェクション対策（SQL・OSコマンド・XSS・LDAP）、SSRF対策（URL検証・内部NWアクセス制限） |
| SECURITY-06 | Least-Privilege Access Policies | 認証・認可 | 最小権限の原則の遵守 |
| SECURITY-07 | Restrictive Network Configuration | ネットワークセキュリティ | NW最小権限（ポート閉鎖・FWルール）、通信分離（VPC・サブネット）、パブリックアクセス制限、通信暗号化（TLS/mTLS） |
| SECURITY-08 | Application-Level Access Control | 認証・認可 | アクセス制御（認可バイパス・IDOR防止）、権限昇格防止 |
| SECURITY-09 | Security Hardening and Misconfiguration Prevention | OWASP Top 10 | セキュリティ設定（デフォルト変更・不要機能無効化）、デフォルトクレデンシャル変更、不要サービス・ポート無効化 |
| SECURITY-10 | Software Supply Chain Security | 依存脆弱性 | 既知脆弱性の依存チェック、依存バージョン管理（ロックファイル）、サプライチェーンリスク評価、不要依存の除去 |
| SECURITY-11 | Secure Design Principles | セキュアデザイン | 脅威モデリング（STRIDE等）、セキュリティ要件の設計組込、攻撃面最小化、防御多層化 |
| SECURITY-12 | Authentication and Credential Management | 認証・認可 | 認証メカニズム（MFA・ブルートフォース対策）、セッション管理、トークン・クレデンシャル管理 |
| SECURITY-13 | Software and Data Integrity Verification | 依存脆弱性 | ソフトウェア成果物の整合性（署名検証・チェックサム）、データ完全性チェック（改ざん検知・ハッシュ検証） |
| SECURITY-14 | Alerting and Monitoring | ログ・監視 | セキュリティイベントアラート、監視ダッシュボード・通知、異常検知（閾値・パターンベース） |
| SECURITY-15 | Exception Handling and Fail-Safe Defaults | OWASP Top 10 | 例外処理での情報漏洩防止（スタックトレース・内部パス）、フェイルセーフデフォルト（失敗時セキュア状態） |

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
