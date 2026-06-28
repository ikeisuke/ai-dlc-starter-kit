# リリース後の運用記録

## リリース情報

- **バージョン**: v3.0.0-alpha.6
- **リリース日**: 2026-06-27
- **リリース内容**: v3 リニューアル Phase 5「release フロー」。`skills/aidlc-v3` に release フェーズ（`steps/release.md` / `templates/release.md` / PR ready・merge・cleanup / release state 書き込み）を実装し、`define → develop` 済みサイクルを main へ安全に取り込めるようにした。`release` コマンドを公開フリップ。

## 運用状況

> 本プロジェクトは AI-DLC スターターキット（GitHub 配布物）のメタ開発であり、本番サービスの稼働監視（稼働率 / レスポンスタイム / アクティブユーザー数）は対象外（N/A）。配布物としての健全性は CI（pr-check.yml / auto-tag.yml）で担保する。

- **稼働状況**: N/A（配布物のためサービス稼働なし）
- **パフォーマンス**: N/A
- **ユーザー数**: N/A

## インシデント対応

- なし

## バグ対応

### 修正済みバグ

- なし（本サイクルは新規機能追加: v3 release フロー）

### 未修正バグ

- なし

## ユーザーフィードバック

- 本リリース時点では未収集（alpha プレリリース）。フィードバックは GitHub Issue（`[Feedback]` ラベル）で随時収集。

## 改善点の洗い出し

### 機能面

- v3 リニューアルは Phase 5 完了時点。残 Phase 6（reviewing 9→1 統合 / reflect / doctor）・Phase 7（v2 本流化 / dogfooding）が継続課題（Epic #736）。

## 次期バージョンの計画

### 対象バージョン

- v3.0.0-alpha.7 以降（Epic #736 Phase 6–7）

### 主要な改善・新機能

- Phase 6: reviewing スキル 9→1 統合 / reflect / doctor
- Phase 7: v2（`skills/aidlc`）の v3 本流化 + dogfooding

### スケジュール

- 次サイクル Inception 開始時に決定

## 備考

- 本サイクルの実リリースは v2 Operations フロー（`skills/aidlc`）で実施。v3 release フローの dogfooding は Phase 7 で実施予定。
- PR #738 は Epic #736 への "Relates to"（Closes ではない）。Epic は Phase 6–7 完了まで open 維持。
