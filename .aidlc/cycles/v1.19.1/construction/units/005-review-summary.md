# レビューサマリ: error-handling.md新規作成

## 基本情報

- **サイクル**: v1.19.1
- **フェーズ**: Construction
- **対象**: Unit 005 error-handling-basics

---

## Set 1: 2026-03-08 19:35:00

- **レビュー種別**: code, security
- **使用ツール**: codex
- **反復回数**: 2（code: 2回、security: 2回）
- **結論**: 指摘0件

### 指摘一覧

| # | 重要度 | 内容 | 対応 |
|---|--------|------|------|
| 1 | 中 | error-handling.md L42 設定ファイル名 - `aidlc.toml` が他ドキュメントの標準表記 `docs/aidlc.toml` と不整合 | 修正済み（error-handling.md L42: `docs/aidlc.toml` に統一） |
| 2 | 低 | error-handling.md L50,L58 スクリプト名 - 相対パスなしで実体との対応が曖昧 | 修正済み（error-handling.md: `docs/aidlc/bin/squash-unit.sh`, `prompts/package/bin/post-merge-cleanup.sh` にフルパス化） |
| 3 | 低 | intro.md L11 フェーズ列挙 - 直後の箇条書きと情報重複 | スコープ外（Unit 005は参照追加のみ。intro.md既存構造の変更は含まない） |
| 4 | 中 | error-handling.md L19-31 エラー通知 - 機微情報マスクルールの欠落 | 修正済み（error-handling.md: 通知フォーマットに機微情報除去の注記と「機微情報除去済み」を追加） |
| 5 | 中 | error-handling.md L41,L57 gh auth案内 - 最小権限スコープの要件欠落 | 修正済み（error-handling.md: スコープ確認と最小限スコープ付与の注記を追加） |
| 6 | 中 | error-handling.md L50 recoveryコマンド - ユーザー確認なしの実行リスク | 修正済み（error-handling.md: ユーザー確認後に実行する旨を明記） |
| 7 | 低 | 依存脆弱性管理の記述欠落 | スコープ外（エラーハンドリングガイドの責務ではなく、セキュリティポリシーの範疇） |
