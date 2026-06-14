# リリース後の運用記録

## リリース情報

- **バージョン**: v3.0.0-alpha.3
- **リリース日**: 2026-06-14
- **リリース内容**: v3 リニューアル Phase 3。`skills/aidlc-v3/` を「読める手順」から実行実装へ前進。`/aidlc-v3 define` で v3 cycle（intent / work-items / `.aidlc/state.json` / journal）を実生成、`develop` の tiny フローを実装。依存解決 `work-item-next.sh`、state safety hardening（schema_version 互換性検証 + writer ガード / #731 解消）、`/aidlc-v3` 起動有効化（marketplace 登録）を含む。

## 運用状況

本リポジトリは配布物（AI-DLC starter kit / Claude Code プラグイン）であり、ランタイムサービスを持たない。稼働率 / レスポンスタイム / アクティブユーザー数等のサービス指標は **N/A**。配布は marketplace.json 経由のプラグイン取得で行われる。

- **配布形態**: Claude Code プラグイン（`.claude-plugin/marketplace.json`）
- **アルファ版位置づけ**: v3 はドッグフーディング検証中。本流化（v3→v2 置換）・marketplace version の v3.0.0 化は Phase 7 へ defer

## バグ対応

### 修正済み

- #731 v3 state-validate.sh: 未知 schema_version の WARN 化 + state-write.sh 更新防止ガード - v3.0.0-alpha.3（PR #732 `Closes #731`）

### 未修正

- なし（本サイクル起因の既知バグなし）

## 改善点の洗い出し

- v3 `define` / `develop` フローの実起動ドッグフーディング（次サイクル以降で実セッション検証）
- `release` / `reflect` / `doctor` コマンドは予約のまま（後続 Phase で実装）

## 次期バージョンの計画

### 対象バージョン

v3.0.0-alpha.4 以降（Phase 4+）

### 主要な改善・新機能

- v3 `release` / `reflect` フローの実装
- v3 `doctor` の実装
- 本流化（v3→v2 置換 / marketplace version 化）は Phase 7

### スケジュール

- **計画開始**: 次サイクル Inception 時に確定
- **リリース予定**: 未定（alpha 反復）

## 備考

- 共通バックログ（backlog ラベル付き open Issue）は本サイクル非関連分を次サイクル以降へ持ち越し。
- Milestone #22（v3.0.0-alpha.3）は PR #732 マージ後に close する（04-completion §4.5）。
