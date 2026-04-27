# リリース後の運用記録

## リリース情報

- **バージョン**: v2.4.2
- **リリース日**: 2026-04-27（予定）
- **リリース内容**: setup/migrate マージ後フォローアップ追加 + Operations 手順書 / progress.md テンプレート明文化 patch
  - Unit 001: aidlc-setup マージ後フォローアップ（#607 setup側 + #605） — `chore/aidlc-v*-upgrade` 一時ブランチ削除案内 + ユーザー確認ベースの HEAD 同期
  - Unit 002: aidlc-migrate マージ後フォローアップ（#607 migrate側） — `chore/aidlc-v*-upgrade` 一時ブランチ削除案内
  - Unit 003: Operations 手順書 / template 明文化（#591 + #585 統合） — `operations-release.md §7.2-§7.6` / `02-deploy.md §7` の明文化と `operations_progress_template.md` への固定スロット同梱

## 運用状況

メタ開発（AI-DLC スターターキット自体の開発）プロジェクトのため、稼働率・インシデント・パフォーマンスの計測対象外。利用者は AI-DLC を採用する個別プロジェクト側でセットアップ実行時にスターターキットを取得する。

## バックログ整理

### 本サイクルで対応した Issue（PR #608 Closes 経由で自動クローズ予定）

- #607: [setup/migrate] アップグレード後の `chore/aidlc-vX.X.X-upgrade` 一時ブランチが削除されず残る
- #605: [Backlog] aidlc-setup のマージ後 HEAD を origin/main と同期する処理を追加
- #591: [Backlog] operations-release.md §7.6 / template / 02-deploy.md の明文化（固定スロット配置・状態ラベル・コミット対象）
- #585: [Backlog] operations_progress_template.md に固定スロット（release_gate_ready / completion_gate_ready / pr_number）を追加

### 本サイクル中に新規発見（次サイクル以降で対応）

- #609: [Backlog] markdownlint を Claude Code hook（PostToolUse）に移行する
  - 本サイクル Unit 001 / Unit 002 で markdownlint 違反（MD038 / MD056）が発生し、Self-Healing で対処した経験から発見

### 残置するバックログ

その他の `backlog` ラベル付き Issue（#592 / #590 / #586 / #582 / #581 / #573 / #568 / #554 / #552 / #545 / #536 / #492 / #443 / #442 / #441 / #440 等）は本サイクルのスコープ外。次サイクル以降のサイクルスコープ決定時に再評価する。

## 次期バージョンの計画

### 対象バージョン

未定（次サイクルの Inception Phase で決定）。

### 主要な改善候補

- #609 markdownlint PostToolUse hook 移行（本サイクルの直接派生）
- 残バックログから優先度・スコープ評価により選定

### スケジュール

- **計画開始**: v2.4.2 リリース後
- **リリース予定**: 未定

## 備考

- メタ開発プロジェクトのため、リリース後の稼働監視・インシデント対応は対象外
- リリース実態は `main` ブランチへのマージ + GitHub Actions による自動タグ付け
- ロールバック方法は `.aidlc/operations.md` の「ロールバック方法」セクション参照（`git checkout v<前バージョン>`）
