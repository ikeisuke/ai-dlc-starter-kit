# リリース後の運用記録

## リリース情報

- **バージョン**: v2.5.5
- **リリース予定日**: 2026-05-08
- **リリース内容**: v2.5.4 リリース後にバックログへ蓄積された 5 件の高優先度（priority:high）バックログを統合解消する patch リリース。Operations / Construction Phase の自動化フロー上で AI エージェントが実害を経験した実証ベースの改善案を一括で構造的健全化する。

### 含まれる Unit

- Unit 001: pr-ops.sh の auto-merge エラー判別精度向上（#665 / 6268397e の前提）
- Unit 002: retrospective-issue.sh の zsh source 互換性復元（#661）
- Unit 003: Construction Unit 完了処理 step5↔step8 分裂の構造的予防（#654 / DR-002）
- Unit 004: Operations 04-completion ステップ 3 の CI 自動 tag 競合手順追加（#650）
- Unit 005: gh pr edit スコープ不足エラーの REST PATCH fallback 経路追加（#626）

### 自動クローズ対象 Issue（PR #668 マージ時）

- #665, #661, #654, #650, #626

## 運用状況

本プロジェクトは AI-DLC スターターキット（プロンプト・スクリプト集としての OSS リポジトリ）であり、サーバー稼働を伴わない。インシデント追跡・パフォーマンス計測は対象外。

| 項目 | 状態 |
|------|------|
| 稼働率 / ダウンタイム / インシデント数 | N/A（OSS リポジトリのため対象外） |
| パフォーマンス計測 | N/A |
| アクティブユーザー数 | N/A（GitHub stars / fork で間接観測） |

## バグ対応

### 本サイクルで解消したバグ（priority:high）

- #665 pr-ops.sh の auto-merge エラー判別不正 → Unit 001 で grep パターン拡張
- #661 retrospective-issue.sh が zsh `source` で動作不能 → Unit 002 で互換性復元
- #654 Construction step5↔step8 履歴・コミット分裂 → Unit 003 で順序契約明文化（DR-002）
- #650 Operations 04-completion ステップ 3 タグ競合検出漏れ → Unit 004 で `git fetch --tags` + 競合検出手順追加
- #626 gh pr edit スコープ不足エラー → Unit 005 で REST PATCH fallback 経路追加

### 未修正のバックログ（次サイクル候補）

| Issue | priority | 概要 |
|-------|----------|------|
| #617 | high | version 管理を marketplace.json に一本化 |
| #615 | high | migrate-backlog.sh: cut -c1-50 の UTF-8 境界分断 |
| #670 | （未指定） | main-repo-health-check: tests/docs 内のコンフリクトマーカー fixture 除外（本サイクル中に検出・起票） |
| その他 medium/low | - | #621 #629 #630 #633 #640 #641 #645 #646 #649 #652 #655 #662 #663 #664 #666 #667 #669 等 |

## ユーザーフィードバック

`feedback` ラベル付き Issue を継続的に集約。本サイクル統合分は priority:high のみで、medium/low は次サイクル以降で扱う。

## 次期バージョンの計画

### 対象バージョン

v2.5.6 もしくは v2.6.0（priority:high バックログ #617 / #615 / #670 の解消可否で確定）

### 主要候補

- #617 marketplace.json 一本化（version 同期漏れ構造的解消）
- #615 migrate-backlog.sh UTF-8 境界バグ
- #670 main-repo-health-check 偽陽性除外

### スケジュール

未確定。次回 Inception Phase で Intent ベースで決定する。

## 備考

- 本サイクル中、メインリポジトリ health check で `conflict-marker` warning 12 件（全件 BATS fixture / 過去サイクル設計ドキュメントの引用）を検出。Issue #670 で次サイクル対応予定。
- v2.5.5 は patch リリース（version_tag = false 設定下、CI auto-tag.yml が main マージ時に v2.5.5 タグを自動作成）。
