# リリース後の運用記録

## リリース情報

- **バージョン**: v2.5.6
- **リリース予定日**: 2026-05-09
- **リリース内容**: v2.5.5 リリース時に浮上した残務・追記修正 4 件を patch サイクルでまとめ処理する。CI ガード強化 / fixture 誤検出除去 / permissions audit 衛生 / Inception 対話 UX 改善を含む。

### 含まれる Unit

- Unit 001: cycle/* PR の 3 Phase 完了 CI ガード追加（#672 / A）— `bin/check-cycle-phase-completion.sh` 新規 + `.github/workflows/cycle-phase-completion-check.yml` 新設 + Repository Ruleset 適用手順 doc 化
- Unit 002: main-repo-health-check の fixture 誤検出除外（#670 / B）— `check_conflict_marker()` の `git grep` に pathspec 除外追加 + bats テスト 2 ケース追加
- Unit 003: permissions audit 9 件解消（#671 / C）— acknowledged 登録 + ask ガード追加（HIGH/CRITICAL/MED 0 件達成）
- Unit 004: Inception 02-preparation §16 複数 Issue 選択前提の明示化（#674 / D）— AI 単一選択バイアス是正、AskUserQuestion `multiSelect=true` 例追加

### 自動クローズ対象 Issue（PR #675 マージ時）

- #670, #671, #672, #674

## 運用状況

本プロジェクトは AI-DLC スターターキット（プロンプト・スクリプト集としての OSS リポジトリ）であり、サーバー稼働を伴わない。インシデント追跡・パフォーマンス計測は対象外。

| 項目 | 状態 |
|------|------|
| 稼働率 / ダウンタイム / インシデント数 | N/A（OSS リポジトリのため対象外） |
| パフォーマンス計測 | N/A |
| アクティブユーザー数 | N/A（GitHub stars / fork で間接観測） |

## バグ対応

### 本サイクルで解消した課題

- #670 main-repo-health-check `check_conflict_marker()` で fixture / 過去サイクル設計ドキュメントの conflict marker を誤検出（v2.5.5 Operations 開始時 count=12）→ Unit 002 で pathspec 除外追加し count=0 に解消
- #671 permissions audit の HIGH/CRITICAL/MED 指摘 9 件 → Unit 003 で acknowledged 登録 + ask ガード追加し全件解消
- #672 cycle/* PR の 3 Phase 未完了マージ → Unit 001 で `check-cycle-phase-completion.sh` + GitHub Actions ガード + Repository Ruleset 手順整備
- #674 Inception 02-preparation §16 で AI が単一 Issue しか選ばないバイアス → Unit 004 で複数選択前提の文言と `multiSelect=true` 例を §16 に追加

### 未修正のバックログ（次サイクル候補）

| Issue | priority | 概要 |
|-------|----------|------|
| #617 | high | version 管理を marketplace.json に一本化（v2.5.5 から持ち越し） |
| #615 | high | migrate-backlog.sh: cut -c1-50 の UTF-8 境界分断（v2.5.5 から持ち越し） |
| その他 medium/low | - | #304 #398 #440-#443 #536 #545 #552 #554 #573 #581 #582 #586 #614 #618 #621-#624 #629 #630 #633 #640 #641 #645 #646 #649 #652 #655 #662-#664 #666 #667 #669 #673 等 |

## ユーザーフィードバック

`feedback` ラベル付き Issue を継続的に集約。本サイクル統合分は v2.5.5 残務 4 件のみで、その他 feedback は次サイクル以降で扱う。

## 次期バージョンの計画

### 対象バージョン

v2.5.7 もしくは v2.6.0（priority:high バックログ #617 / #615 の解消可否で確定）

### 主要候補

- #617 marketplace.json 一本化（version 同期漏れ構造的解消）
- #615 migrate-backlog.sh UTF-8 境界バグ
- #673 GitHub Projects 移行（Milestone 並行運用）

### スケジュール

未確定。次回 Inception Phase で Intent ベースで決定する。

## 備考

- 本サイクル開始時、メインリポジトリ health check は `status:ok`（Unit 002 の fixture 除外修正の効果実観測）。
- v2.5.6 は patch リリース（CI auto-tag.yml が main マージ時に v2.5.6 タグを自動作成）。
- PR #675 の Closes リンクで Issue #670 #671 #672 #674 はマージ時自動クローズ。手動クローズ不要。
