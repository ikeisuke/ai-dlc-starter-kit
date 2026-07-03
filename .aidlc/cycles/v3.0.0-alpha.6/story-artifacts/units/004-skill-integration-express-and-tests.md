# Unit: SKILL.md 統合・express 整合・テスト・回帰

## 概要

release フロー実装の仕上げ。`SKILL.md` の express ラッパが release まで到達することの整合確認、release フロー新規分のテスト追加、既存 v3 テストの green 維持、SoT 非再定義の最終確認を担う。

## 含まれるユーザーストーリー

- ストーリー 6: SKILL.md 統合・express 整合・テスト（`release` コマンドの公開フリップを含む全体）

## 責務

- `SKILL.md` の `release` コマンドを「予約」から「実装済み」に更新し、ルーティング先を `steps/release.md` にする（利用者向け公開フリップ。Unit 001–003 で Step 1–4 が揃った後に有効化する / Unit 001 から移管）。
- express ラッパ（work item 1 つ・risky なし時の `define → develop → release` 連続実行）が release まで到達する記述になっていることを確認・必要なら修正。
- release フロー新規分の検証を `scripts/tests/` に追加（state 書き込み契約・Step 1 ゲート・review ルーティング条件・post-merge opt-in 分岐のユニット/契約テスト、または手順のドライ検証）。
- 既存 v3 テスト（`scripts/tests/`）が green を維持することを確認（回帰）。
- state.json schema・フェーズ導出・review perspective の SoT（docs/v3）を本サイクルで再定義していないことを確認。
- release フロー全体（Step 1→4）の整合性・通し動作の検証。

## 境界

- 各 Step の機能実装そのもの（Unit 001–003）は扱わない（本 Unit は統合・検証・整合）。
- 本サイクル自身の release を v3 release フローで実行すること（dogfooding は Phase 7）は扱わない。

## 依存関係

### 依存する Unit

- 001 release フロー骨格 + リリース準備ゲート（依存理由: 統合対象）
- 002 PR 整備 + release.md テンプレート + review ルーティング（依存理由: 統合対象）
- 003 Merge 承認・実行 + Post-merge cleanup（依存理由: 統合対象 / 通し検証に全 Step が必要）

### 外部依存

- 既存 `scripts/tests/` テストハーネス
- 設計 SoT: `docs/v3/`（再定義していないことの確認対象）

## 非機能要件（NFR）

- **品質**: 新規テストが Step 1–4 の主要分岐をカバーする。
- **互換性**: 既存テスト green 維持（回帰ゼロ）。
- **クロスプラットフォーム**: テスト・スクリプトは macOS / Linux 両対応。

## 技術的考慮事項

- テストは既存 v3 `scripts/tests/` の方式に合わせる。
- gh 依存部分はモック/ドライ検証で扱い、ネットワーク非依存にする。

## 関連Issue

- #736（部分対応 / Relates）

## 実装優先度

High

## 見積もり

0.5〜1 日（統合・テスト・回帰）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-27
- **完了日**: 2026-06-27
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
