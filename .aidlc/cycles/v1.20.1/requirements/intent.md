# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v1.20.1

## 開発の目的

AI-DLCの品質保証機能と運用安定性を向上させる。具体的には、セキュリティレビューの観点拡充、監査ログの強化、コンテンツバリデーションの追加、およびテンポラリファイル管理の統一を行う。

## ターゲットユーザー

AI-DLCスターターキットを使用してソフトウェア開発を行う開発者・チーム

## ビジネス価値

- セキュリティレビューの網羅性向上により、見落としリスクを低減
- 監査ログの強化により、トレーサビリティとデバッグ効率が向上
- コンテンツバリデーションにより、成果物（図表）の品質を保証
- テンポラリファイル管理の統一により、プロンプト記述の一貫性と保守性が向上

## スコープ

### #278 Security Extension強化

- **In Scope**: `prompts/package/skills/reviewing-security/SKILL.md` のレビュー観点セクションに、Amazon AIDLC SECURITY-01〜15の全ルールに対応する観点を追加
- **Out of Scope**: スキルの呼び出し方式・出力フォーマット変更、外部ツール連携の変更

**対象ルール一覧（完了判定基準: 15/15カバー）**:

| ID | タイトル | 既存カバー |
|----|---------|-----------|
| SECURITY-01 | Encryption at Rest and in Transit | 部分的 |
| SECURITY-02 | Access Logging on Network Intermediaries | なし |
| SECURITY-03 | Application-Level Logging | なし |
| SECURITY-04 | HTTP Security Headers | 部分的 |
| SECURITY-05 | Input Validation on All API Parameters | あり |
| SECURITY-06 | Least-Privilege Access Policies | あり |
| SECURITY-07 | Restrictive Network Configuration | なし |
| SECURITY-08 | Application-Level Access Control | あり |
| SECURITY-09 | Security Hardening and Misconfiguration Prevention | 部分的 |
| SECURITY-10 | Software Supply Chain Security | あり |
| SECURITY-11 | Secure Design Principles | なし |
| SECURITY-12 | Authentication and Credential Management | あり |
| SECURITY-13 | Software and Data Integrity Verification | なし |
| SECURITY-14 | Alerting and Monitoring | なし |
| SECURITY-15 | Exception Handling and Fail-Safe Defaults | なし |

### #277 Audit Trail強化

- **In Scope**: `prompts/package/bin/write-history.sh` の出力にISO 8601タイムスタンプを付加し、構造化ログを強化
- **Out of Scope**: ログ保存先・ローテーションの変更
- **互換性**: 既存の履歴ファイル（`history/*.md`）のMarkdownフォーマットは維持する。タイムスタンプは既存エントリの情報を補完する形で追加し、既存のログパーサー（プロンプトがgrepで読み取る等）への影響はない

### #279 Content Validation

- **In Scope**: `prompts/package/skills/reviewing-code/SKILL.md` のレビュー観点にASCII図・Mermaid図のバリデーション観点を追加
- **Out of Scope**: 専用のバリデーションツール作成、図の自動生成・自動修正

### テンポラリファイル出力先固定化

- **In Scope**: `prompts/package/prompts/` 配下のプロンプトで使用する `<一時ファイルパス>` の出力先ディレクトリを統一定義（`common/rules.md` に規約追加）。既存プロンプト・スキル内の固定パス（`CLAUDE.md`, `commit-flow.md`, `review-flow.md`, `squash-unit/SKILL.md`等）を規約に統一
- **Out of Scope**: シェルスクリプト内部のテンポラリファイル処理

## 成功基準

- reviewing-securityスキルのレビュー観点がAmazon AIDLC SECURITY-01〜15の全15ルールをカバーしていること（15/15）
- write-history.shがISO 8601タイムスタンプ付きの構造化ログを出力し、既存フォーマットとの互換性を維持すること
- reviewing-codeスキルのレビュー観点にASCII図・Mermaid図のバリデーション観点が追加されていること
- テンポラリファイルの出力先ディレクトリが `common/rules.md` に統一定義されていること

## 期限とマイルストーン

パッチリリース（1サイクル内で完結）

## 制約事項

- アーキテクチャレベルの変更は行わない（#280 Workflow Planningは除外済み）
- `prompts/package/` を編集し、Operations Phaseで `docs/aidlc/` にrsyncする（メタ開発ルール）
- 既存のreviewing-securityスキルのインターフェース（呼び出し方式・出力フォーマット）は変更しない
- write-history.shの既存出力フォーマット（Markdownベース）との後方互換性を維持する

## 不明点と質問（Inception Phase中に記録）

[Question] #278 Security Extension: Amazon AIDLC 15ルールのうち、既存でカバーされていない7-8ルールを全て追加するか？
[Answer] はい、全て追加する

[Question] #280 Workflow Planningの扱い
[Answer] アーキテクチャ変更が必要なため除外

[Question] テンポラリファイルの出力先固定化の方針
[Answer] 別件として追加対応。プロンプト内の `<一時ファイルパス>` プレースホルダーの出力先ディレクトリを統一する

[Question] #279 Content Validationの実装先
[Answer] reviewing-codeスキルのSKILL.mdに図のバリデーション観点を追加する方針（専用スキルは作らない）
