# リリース後の運用記録

## リリース情報

- **バージョン**: v2.6.6 (patch)
- **リリース日**: 2026-05-20
- **リリース内容**: aidlc-retrospective skill の T 中心リファクタ + 本質的振り返り化（集約 Issue 既定廃止 + Try ループ起票 / セルフレビュー観点新ステップ / 一次情報三層検証 helper / patch 互換 `aggregate_issue_enabled` フラグ）

## バックログ整理結果

### 自動クローズ対象（PR #725 の `Closes` 記載）

- #704 — Retrospective skill セルフレビュー観点不在 → Unit 002 で §1.2.5 + 判別ガイド導入
- #652 — 振り返り 3 層検証 helper skill 化 → Unit 003 で opt-in helper 追加

### Comment 対象（クローズせず PR コメントに参照記録）

- #710 — CLOSED / 振り返り Issue 起票方針見直し / minor 想定 — 本サイクルが本体を patch サブセット適用で先取り
- #715 — minor 想定 Issue の patch サブセット適用パターン SoT 化 — 本サイクル自体が実証実例（SoT 化本体は別サイクル defer）

### 他 Milestone に紐付け済（skip-overwrite）

- #634 — v2.5.3 Milestone 維持
- #710 — v2.6.4 Milestone 維持（CLOSED 状態）

## 運用上の留意点

### 新動作（既定）の影響

- `aidlc-retrospective` 実行時、集約 Issue (`Retrospective: {cycle}`) は **既定で作成されない**
- 代わりに T 件数分の個別 Issue がループ起票される
- consumer が旧動作を維持する場合: `.aidlc/config.toml` / `.aidlc/config.local.toml` に `[rules.retrospective] aggregate_issue_enabled = true` を明示設定

### 後方互換解決経路

- `predecessor_resolve_issue` の経路 1/1' は retrospective ラベル付き T Issue 群を milestone 単位で集計するロジックを追加し、集約 Issue 不在でも前サイクル振り返り結果を解決可能

### CI / テスト

- `tests/retrospective_*.bats` に新旧両系統テストを追加済、CI green 想定
- defaults.toml 同期チェック / size check は Operations §1 で sync:ok, 0 warnings を確認

## 次期バージョンの計画

### v2.7.0+ defer 項目（本サイクル外）

- `Retrospective: {cycle}` タイトル運用の完全廃止
- `retrospective_api_*` の破壊的シグネチャ変更
- `predecessor_resolve_issue` 経路再設計
- #715 SoT 化本体（minor 想定 Issue の patch サブセット適用パターンの一般化）

### 監視ポイント

- v2.6.6 リリース後の retrospective 起票数（旧サイクルの集約 1 件 → 新サイクルでは T 件数分にスケール）
- consumer 側で `aggregate_issue_enabled = true` opt-in 利用が発生するかどうか

## 備考

本サイクル自身の振り返り（v2.6.6 retrospective）は `/aidlc retrospective` で実施し、Intent SC-10 の dogfooding 条件を検証する。
