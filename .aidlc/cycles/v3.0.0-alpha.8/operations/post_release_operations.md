# リリース後の運用記録

## リリース情報

- **バージョン**: v3.0.0-alpha.8
- **リリース日**: 2026-07-02
- **リリース内容**: v3 リニューアル Phase 6（Epic #736）の必須 follow-up。v3 診断コマンド `doctor`（`skills/aidlc-v3/scripts/doctor.sh`）に `[phase]`（フェーズ導出の整合診断）と `[trace]`（design 必須 work item の design ファイル存在診断）の 2 領域を追加し、shallow 9 領域から完全 11 領域へ拡張した（Unit 001）。あわせて doctor.md / workflow.md / v3-renewal-plan.md の SoT ドキュメントを 11 領域構成へ反映した（Unit 002）。read-only / 自動修正なしを維持。#741 をクローズ。

## 運用状況

> 本プロジェクトは AI-DLC スターターキット（GitHub 配布物）のメタ開発であり、本番サービスの稼働監視（稼働率 / レスポンスタイム / アクティブユーザー数）は対象外（N/A）。配布物としての健全性は CI（pr-check.yml / auto-tag.yml）で担保する。

- **稼働状況**: N/A（配布物のためサービス稼働なし）
- **パフォーマンス**: N/A
- **ユーザー数**: N/A

## インシデント対応

- なし

## バグ対応

### 修正済みバグ

- なし（本サイクルは doctor 領域拡張とドキュメント反映のみ）

### 未修正バグ

- #740: `squash-unit.sh` の `find_unit_commit_range_git` の `--from/--to` 経路がルートコミット `--from` で失敗（defer-from-review / backlog 継続）

## ユーザーフィードバック

- 本リリース時点では未収集（alpha プレリリース）。フィードバックは GitHub Issue（`[Feedback]` ラベル）で随時収集。

## 改善点の洗い出し

### 機能面

- doctor は本サイクルで `[phase]` / `[trace]` を追加し完全 11 領域化を達成。v3 リニューアルは Phase 6（Epic #736）を完了に近づけた。残 Phase 7（v2 本流化 / dogfooding）が継続課題。

### 既知の follow-up

- Epic #736 Phase 7: v2（`skills/aidlc`）の v3 本流化 + dogfooding

## 次期バージョンの計画

### 対象バージョン

- v3.0.0-alpha.9 以降（Epic #736 Phase 7）

### 主要な改善・新機能

- Phase 7: v2（`skills/aidlc`）の v3 本流化 + dogfooding
