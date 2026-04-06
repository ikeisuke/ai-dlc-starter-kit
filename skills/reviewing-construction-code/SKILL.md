---
name: reviewing-construction-code
description: Reviews code for quality and security issues. Combines code quality review with security vulnerability detection. Use when reviewing code after generation in Construction Phase.
argument-hint: [レビュー対象ファイルまたはディレクトリ]
compatibility: Requires codex CLI, claude CLI, or gemini CLI. Runs in read-only/sandbox mode.
allowed-tools: Bash(codex:*) Bash(claude:*) Bash(gemini:*)
---

# Reviewing Construction Code

コード生成後のコード品質+セキュリティレビューを実行するスキル。

**focusメタデータ**: このスキルは `code` と `security` の2つのfocusを持つ。セキュリティ関連の指摘には `focus: security` を付与すること。

## レビュー観点

### コード品質（focus: code）

- **可読性**: 命名規則の一貫性、関数の長さ、ネストの深さ、コメントの適切さ
- **保守性**: 単一責任の原則、DRY原則、疎結合・高凝集、拡張性
- **パフォーマンス**: アルゴリズムの計算量、不要な再計算、メモリリーク、I/O効率
- **テスト品質**: カバレッジ、境界値テスト、テスト名の明確さ、テストの独立性
- **ASCII図バリデーション**: ASCII図が含まれる場合、罫線のずれ・文字化け・構造の不整合がないか検証する
- **Mermaid図バリデーション**: Mermaid記法の図が含まれる場合、構文エラー・ノード/エッジの不整合がないか検証する

### セキュリティ（focus: security）

以下の観点はAmazon AIDLC SECURITY-01〜15に対応している。

- **OWASP Top 10（SECURITY-01,04,05,09,15）**: インジェクション対策（SQL、OS コマンド、XSS、LDAP）、アクセス制御（認可バイパス、IDOR防止）、暗号化（平文回避、TLS）、保存時暗号化、HTTPセキュリティヘッダー、セキュリティ設定（デフォルト変更、不要機能無効化）、SSRF対策、例外処理での情報漏洩防止、フェイルセーフデフォルト
- **認証・認可（SECURITY-06,08,12）**: 認証メカニズム（MFA、ブルートフォース対策）、セッション管理、最小権限の原則、権限昇格防止、トークン・クレデンシャル管理
- **依存脆弱性（SECURITY-10,13）**: 既知脆弱性チェック、バージョン管理（ロックファイル）、サプライチェーンリスク、ソフトウェア成果物の整合性検証
- **ログ・監視（SECURITY-02,03,14）**: アクセスログ有効化、アプリケーションログ（認証・権限変更）、ログへの機密情報混入防止、セキュリティイベントアラート
- **ネットワーク（SECURITY-07）**: NW最小権限、通信分離、パブリックアクセス制限、通信暗号化
- **セキュアデザイン（SECURITY-11）**: 脅威モデリング（STRIDE等）、攻撃面最小化、防御多層化

### N/A判定ガイダンス

プロジェクトの特性により一部の観点が該当しない場合がある。N/A判定時はレビュー記録に「N/A: 理由」を明記すること。

| カテゴリ | N/A条件の例 |
|---------|-----------|
| ログ・監視 | ネットワーク中間点を使用しないローカルアプリケーション |
| ネットワーク | ネットワーク通信を行わないCLIツール・ライブラリ |
| セキュアデザイン | 設計フェーズが対象外のバグ修正・パッチ変更 |
| OWASP Top 10（HTTP関連） | HTTPを使用しないバッチ処理・データパイプライン |

## 共通基盤

実行コマンド・セッション継続・外部ツールとの関係・セルフレビューモードは `references/reviewing-common-base.md` を参照。
