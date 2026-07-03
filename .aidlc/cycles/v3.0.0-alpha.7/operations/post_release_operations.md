# リリース後の運用記録

## リリース情報

- **バージョン**: v3.0.0-alpha.7
- **リリース日**: 2026-06-29
- **リリース内容**: v3 リニューアル Phase 6（Epic #736）。`skills/aidlc-v3` に reflect（振り返り）と doctor（診断）を実装し status を拡充して、`define → develop → release → reflect` の v3 単独フルサイクル完走を可能にした。あわせて #735（squash-unit footgun）を修正し、alpha.4 で実装済みの #733 をクローズ。

## 運用状況

> 本プロジェクトは AI-DLC スターターキット（GitHub 配布物）のメタ開発であり、本番サービスの稼働監視（稼働率 / レスポンスタイム / アクティブユーザー数）は対象外（N/A）。配布物としての健全性は CI（pr-check.yml / auto-tag.yml）で担保する。

- **稼働状況**: N/A（配布物のためサービス稼働なし）
- **パフォーマンス**: N/A
- **ユーザー数**: N/A

## インシデント対応

- なし

## バグ対応

### 修正済みバグ

- #735: `squash-unit.sh` の複数 `--message` 指定で subject が失われる footgun を修正（Unit 001 / 段落結合 + Co-Authored-By 重複排除）

### 未修正バグ

- なし

## ユーザーフィードバック

- 本リリース時点では未収集（alpha プレリリース）。フィードバックは GitHub Issue（`[Feedback]` ラベル）で随時収集。

## 改善点の洗い出し

### 機能面

- v3 リニューアルは Phase 6 完了時点。doctor は shallow 診断（config/state/cycle/work-items/git/gh/pr/scripts + parse-guard）まで実装し、`[phase]` / `[trace]` 領域は alpha.8 へ defer（follow-up #741）。残 Phase 7（v2 本流化 / dogfooding）が継続課題（Epic #736）。

### 既知の follow-up

- #741: doctor に `[phase]` / `[trace]` 領域を追加（shallow → 完全診断 / Phase 6 必須 follow-up）
- #740: `squash-unit.sh` の `find_unit_commit_range_git` の `--from/--to` 経路がルートコミット `--from` で失敗（defer-from-review）

## 次期バージョンの計画

### 対象バージョン

- v3.0.0-alpha.8 以降（Epic #736 Phase 6 残 + Phase 7）

### 主要な改善・新機能

- Phase 6 残: doctor `[phase]` / `[trace]` 領域追加（#741）
- Phase 7: v2（`skills/aidlc`）の v3 本流化 + dogfooding
