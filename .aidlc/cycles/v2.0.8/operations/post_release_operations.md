# リリース後の運用記録

## リリース情報
- **バージョン**: v2.0.8
- **リリース日**: 2026-03-29
- **リリース内容**: バグ修正（スクリプト系3件）、/aidlc helpアクション追加、主要4フェーズ総点検、スキルスクリプト設計ガイドライン整備

## 運用状況

### 稼働状況
- **稼働率**: N/A（CLIツール/スターターキット）
- **ダウンタイム**: N/A
- **インシデント数**: 0 件

### パフォーマンス
- N/A（CLIツール/スターターキットのため該当なし）

### ユーザー数
- N/A（オープンソースプロジェクト、個人利用）

## インシデント対応

なし

## バグ対応

### 修正済みバグ
- #463 squash-unit.sh バグ修正 - v2.0.8
- #466 squash-unit.sh --dry-run 時の --message 必須チェックスキップ - v2.0.8
- #465 aidlc-setup/aidlc-migrate の bootstrap.sh 依存脱却 - v2.0.8

### 未修正バグ
- #468 review-flow.md の required 時 CLI失敗でセルフレビューに自動フォールバックする問題 - Medium - 次サイクル

## ユーザーフィードバック

### 機能リクエスト（バックログ）
- #443 Operations Phase自律実行モード（マージ前後分割） - Medium
- #442 Construction Phaseにself-healingテストループを標準化 - Medium
- #441 Construction Phaseで独立Unitの並列実装をサポート - Medium
- #440 レビューフローに矛盾フィードバック検出ステップを追加 - Medium
- #398 full_auto モード（全フェーズ自律完走）の追加 - Medium
- #304 ナビゲーションモード（AI-DLC説明モード）の追加 - Medium

## 改善点の洗い出し

### v2.0.8総点検で発見された軽微な乖離
- #470 inception/01-setup.md ステップ番号欠番（ステップ6不在）
- #471 check-open-issues.sh 出力形式とステップファイルの記述不一致
- #472 init-cycle-dir.sh バックログディレクトリ記述が実動作と不一致
- #473 worktree_path の名前付きサイクル形式が未記載
- #474 issue-ops.sh の出力形式を01-setup.mdに追記
- #475 implementation_record_template.md のプレースホルダ形式統一
- #476 run-markdownlint.sh の出力フォーマット標準化
- #477 Operations Phase軽微な乖離一括（v2.0.8総点検）
- #478 aidlc-setup 軽微な乖離一括（v2.0.8総点検）

## 次期バージョンの計画

### 対象バージョン
v2.0.9（予定）

### 主要な改善・新機能
- 総点検で発見された軽微な乖離の修正（#470-#478）
- review-flow.md のバグ修正（#468）
- その他バックログから優先度の高い項目を選定

## 備考
v2.0.8は主要4フェーズ（Inception/Construction/Operations/Setup）の総点検サイクルであり、重大な乖離の修正と軽微な乖離のバックログ化を完了した。
