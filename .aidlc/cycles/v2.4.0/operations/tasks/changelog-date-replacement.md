# CHANGELOG リリース日置換

Construction Phase で発生した手動作業を Operations Phase に引き継ぐためのタスク定義です。

---

## 基本情報

- **発生Unit**: Unit 003 - update-version-docs-comms
- **発生日**: 2026-04-23
- **発生サイクル**: v2.4.0
- **緊急度**: 高（CHANGELOG プレースホルダのまま出荷を防ぐ必須タスク）

## 発生理由

Construction Phase Unit 003 で `CHANGELOG.md` の v2.4.0 セクション骨組みを追加した際、リリース日が未確定だったため `## [2.4.0] - 2026-04-XX` の形式でプレースホルダを記載した。Operations Phase の CHANGELOG 更新ステップ（`operations-release.md §7.2-7.6` および `02-deploy.md` 7.2）で確定日付に置換する必要がある。

- 自動化できない理由: リリース日が Operations Phase 実施時点で初めて確定するため、Construction Phase では確定値を埋められない
- 一時的な対応か恒久的な対応か: 一時的（v2.4.0 サイクル限定の引き継ぎ）

## 作業手順

1. `CHANGELOG.md` を開き、`## [2.4.0] - 2026-04-XX` を検索
2. `XX` を Operations Phase 実施日（2 桁ゼロ埋め）に置換（例: `2026-04-25`）
3. `git diff CHANGELOG.md` で置換完了を確認

## 完了条件

- [ ] `grep -c "2026-04-XX" CHANGELOG.md` が 0 を返す
- [ ] v2.4.0 セクションヘッダが `## [2.4.0] - YYYY-MM-DD` の有効な日付形式
- [ ] CHANGELOG コミットに置換差分が含まれている

## 注意事項

- Operations Phase 7.2 の CHANGELOG 更新ステップで他の見出し追加と同タイミングで実施することで、追加コミットを発生させない
- v2.5.0 以降のサイクルでは本タスク不要（このタスクファイルは v2.4.0 サイクル限定）

---

## 実行状態

- **状態**: 未実行
- **実行日**: -
- **実行者**: -
- **備考**: -
