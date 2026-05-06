# Unit: AIDLC_PROJECT_ROOT 横断 path resolution リファクタ

## 概要

`skills/aidlc/scripts/lib/aidlc-paths.sh` に共通 path resolution helper を新設し、`AIDLC_PROJECT_ROOT` 環境変数の解釈を producer (`__retro_spool_path` 等) と consumer (`retrospective-resend.sh`, `predecessor-issue.sh`) 両側で統一する。`AIDLC_PROJECT_ROOT` を設定した状態でも未設定でも全 BATS テストが pass することを保証し、AI-DLC を別リポで利用した際の path 不整合を解消する。

## 含まれるユーザーストーリー

- ストーリー 3: AIDLC_PROJECT_ROOT 横断 path resolution リファクタ

## 責務

- `skills/aidlc/scripts/lib/aidlc-paths.sh` の新規作成
  - 関数 `aidlc_cycle_path <cycle> <subpath>` を提供
  - `AIDLC_PROJECT_ROOT` 設定時: `<AIDLC_PROJECT_ROOT>/.aidlc/cycles/<cycle>/<subpath>` を返す（値そのものを基準。絶対パスとは限らない）
  - `AIDLC_PROJECT_ROOT` 未設定 / 空文字時: cwd 相対の `.aidlc/cycles/<cycle>/<subpath>` を返す
  - 多重 source ガード `__AIDLC_PATHS_SH_LOADED` を採用
- `scripts/retrospective-resend.sh` の `SPOOL_PATH` 算出を helper 経由に変更
- `scripts/lib/predecessor-issue.sh` の `compat_path` / `spool_path` 算出を helper 経由に変更
- `scripts/lib/retrospective-issue.sh` の `__retro_spool_path` を helper 経由に統一
- `bin/tests/` 配下の既存 BATS テストが `AIDLC_PROJECT_ROOT` 設定時 / 未設定時の両方で pass することを確認
- 既存テストでカバーされていない経路（特に consumer 側）に対する追加 BATS テストの追加
- CHANGELOG への AIDLC_PROJECT_ROOT 横断対応の記載

## 境界

- helper は単純な path 連結関数（validation や絶対パス化は呼び出し側責務）
- `predecessor-issue.sh` を zsh から `source` した際の `BASH_SOURCE` 解決失敗（本サイクル開始時に検証済）は別 Issue として切り出し、本 Unit のスコープ外
- Issue #631 / #632 の実際の close 操作は Operations Phase 6.x（バックログクリーンアップ）と運用チェックリストで実施。本 Unit の DoD ではない
- `__retro_spool_path` 以外の producer 側 path（`retrospective-issue.sh` 内の他のパス変数）は対象外（明示的に対象に挙げたもののみリファクタ）

## 依存関係

### 依存する Unit

- 001-review-flow-5r-and-defer-automation（**soft dependency / レビュー運用前提**: 実装着手は Unit 001 完了を待たずに開始可能。レビュー実施時点で Unit 001 が完了している必要がある）
- 002-construction-ci-structural-checks（**hard dependency / 実装依存**: 本 Unit 完了時の Unit 完了 hook で `check-skill-references.sh` / `check-bash-substitution.sh` / `check-test-isolation.sh` が必須実行されるため、Unit 002 の squash-unit.sh 改修と check-test-isolation.sh の実装が完了している必要がある。Unit 002 完了前に本 Unit を完了させると hook が動作しない）

### 外部依存

- `bash` 4+

## 非機能要件（NFR）

- **パフォーマンス**: helper 関数呼び出しはミリ秒未満（path 連結のみ）
- **セキュリティ**: `AIDLC_PROJECT_ROOT` の値をそのまま path 連結に使うため、shell 注入の懸念があれば呼び出し側で quote する責務を負う（helper 自体は受け取った値をそのまま展開）
- **スケーラビリティ**: 対象外
- **可用性**: 後方互換性を維持（未設定時は v2.5.1 と同一動作）

## 技術的考慮事項

- helper は `BASH_SOURCE` 自己解決パターンを採用（既存 `predecessor-issue.sh` と同パターン）
- 多重 source ガード `__AIDLC_PATHS_SH_LOADED` は既存 `__AIDLC_*_LOADED` パターンに合わせる
- BATS テストの追加は Unit B 完了後の `check-test-isolation.sh` でテスト隔離が検証されるため、本 Unit でのテスト追加時に cwd 依存パターンを発生させないよう注意
- producer 側 (`__retro_spool_path`) は既に `AIDLC_PROJECT_ROOT` 対応済み（v2.5.1 で実装）。本 Unit では既存実装を helper 経由にリファクタするのみ。動作変更は consumer 側のみ

## 関連Issue

- #638（AIDLC_PROJECT_ROOT 対応の横断リファクタ、Epic for #631 + #632）
- #631（[Backlog] retrospective-resend.sh の spool path を AIDLC_PROJECT_ROOT 対応にする） — Operations 6.x で close
- #632（[Backlog] predecessor-issue.sh の fallback path を AIDLC_PROJECT_ROOT 対応にする） — Operations 6.x で close

## 実装優先度

High（別リポでの AI-DLC 利用時の最大の不整合源）

## 見積もり

中（新規 helper + 既存 3 ファイルのリファクタ + BATS テスト追加 + 後方互換性検証）。0.5 〜 1 日。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-06
- **完了日**: 2026-05-06
- **担当**: AI Agent (Claude Opus 4.7)
- **エクスプレス適格性**: -
- **適格性理由**: -
