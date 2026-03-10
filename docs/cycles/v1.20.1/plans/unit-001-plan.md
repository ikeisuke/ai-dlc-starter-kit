# Unit 001 計画: セキュリティレビュー観点拡充

## 概要

reviewing-securityスキルのSKILL.mdにAmazon AIDLC SECURITY-01〜15の全ルールに対応するレビュー観点を追加する。既存の3カテゴリ（OWASP Top 10、認証・認可、依存脆弱性）を維持しつつ、カバーされていないルールに対応する新カテゴリを追加する。

## 用語定義

| 用語 | 定義 |
|------|------|
| 依存脆弱性 | SKILL.mdのカテゴリ名（正規名称）。「依存関係脆弱性」は使用しない |

## 外部基準参照

- **参照元**: awslabs/aidlc-workflows `extensions/security/baseline/security-baseline.md`
- **参照URL**: `https://github.com/awslabs/aidlc-workflows`
- **参照コミット**: `9793958adbb293238ad065d4b1bf88ba56a8293e`（2026-03-10取得）
- **調査レポート**: `docs/cycles/v1.18.0/requirements/amazon-aidlc-report.md`

**基準更新時の運用手順**: 外部基準の更新検知はサイクルのInception Phase（バックログ確認時）に実施する。差分が検出された場合は、正規マッピング表を更新し15/15カバレッジを再検証する。対応はバックログに登録して次サイクルで実施する。

## 変更対象ファイル

- `prompts/package/skills/reviewing-security/SKILL.md`（レビュー観点セクションの拡張）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 既存3カテゴリとSECURITY-01〜15のマッピングを分析し、新規カテゴリ構成を設計
2. **論理設計**: SKILL.mdへの追加セクション構成、N/A判定ガイダンス、対応表のフォーマットを設計

### Phase 2: 実装

3. **コード生成**: SKILL.mdのレビュー観点セクションを拡張
   - 既存カテゴリへの観点追加（下記正規マッピング表の「既存拡張」行）
   - 新規カテゴリの追加（下記正規マッピング表の「新規」行）
   - N/A判定ガイダンスの追加
   - SECURITY-01〜15対応表の作成
4. **テスト**: 15/15カバレッジの独立検証（下記「検証手順」参照）
5. **統合とレビュー**: AIレビュー実施

### SECURITY-01〜15 正規マッピング表（Single Source of Truth）

各ルールは主カテゴリに1対1で割り当てる。既存SKILL.mdでのカバー状態と、本Unitでの対応方針を統一的に管理する。

| rule_id | タイトル | 既存カバー状態 | 対応方針 | 割当カテゴリ |
|---------|---------|-------------|---------|-----------|
| SECURITY-01 | Encryption at Rest and in Transit | 部分的 | 既存拡張 | OWASP Top 10 |
| SECURITY-02 | Access Logging on Network Intermediaries | なし | 新規追加 | ログ・監視 |
| SECURITY-03 | Application-Level Logging | なし | 新規追加 | ログ・監視 |
| SECURITY-04 | HTTP Security Headers | 部分的 | 既存拡張 | OWASP Top 10 |
| SECURITY-05 | Input Validation on All API Parameters | あり | 維持 | OWASP Top 10 |
| SECURITY-06 | Least-Privilege Access Policies | あり | 維持 | 認証・認可 |
| SECURITY-07 | Restrictive Network Configuration | なし | 新規追加 | ネットワークセキュリティ |
| SECURITY-08 | Application-Level Access Control | あり | 維持 | 認証・認可 |
| SECURITY-09 | Security Hardening and Misconfiguration Prevention | 部分的 | 既存拡張 | OWASP Top 10 |
| SECURITY-10 | Software Supply Chain Security | あり | 維持 | 依存脆弱性 |
| SECURITY-11 | Secure Design Principles | なし | 新規追加 | セキュアデザイン |
| SECURITY-12 | Authentication and Credential Management | あり | 維持 | 認証・認可 |
| SECURITY-13 | Software and Data Integrity Verification | なし | 新規追加 | 依存脆弱性 |
| SECURITY-14 | Alerting and Monitoring | なし | 新規追加 | ログ・監視 |
| SECURITY-15 | Exception Handling and Fail-Safe Defaults | なし | 新規追加 | OWASP Top 10 |

### カテゴリ構成

| 種別 | カテゴリ名 | 対応するSECURITYルール |
|------|-----------|---------------------|
| 既存拡張 | OWASP Top 10 | 01, 04, 05, 09, 15 |
| 既存拡張 | 認証・認可 | 06, 08, 12 |
| 既存拡張 | 依存脆弱性 | 10, 13 |
| 新規 | ログ・監視 | 02, 03, 14 |
| 新規 | ネットワークセキュリティ | 07 |
| 新規 | セキュアデザイン | 11 |

### 対応表スキーマ

SKILL.md末尾に追加する対応表の各行は以下のフィールドを持つ:

| フィールド | 必須 | 説明 |
|-----------|------|------|
| rule_id | 必須 | SECURITY-XX形式 |
| カテゴリ | 必須 | 割当先カテゴリ名（上記6カテゴリのいずれか） |
| チェック項目 | 必須 | レビュー時の確認内容 |
| N/A条件 | 任意 | プロジェクトに該当しない場合の判定基準 |

**カーディナリティ**: 1ルール1カテゴリ（主カテゴリへの1対1割当）

### 検証手順（独立検証）

15/15カバレッジの検証は以下の独立した手順で実施する:

1. Intent（`docs/cycles/v1.20.1/requirements/intent.md`）のSECURITY-01〜15一覧を基準リストとする
2. SKILL.mdの対応表から全rule_idを抽出する
3. 基準リストと対応表のrule_idを突合し、漏れがないことを確認する
4. 各rule_idに対応するチェック項目がレビュー観点セクション内に存在することを確認する

## 完了条件チェックリスト

- [x] reviewing-securityスキルのSKILL.mdにSECURITY-01〜15の全15ルールに対応するレビュー観点が追加されている
- [x] 既存の3観点（OWASP Top 10、認証・認可、依存脆弱性）が維持されている
- [x] プロジェクトに該当しない観点のN/A判定ガイダンスが記載されている
- [x] SECURITY-01〜15と追加観点の対応表が作成され、15/15カバーが検証可能な形で記載されている
