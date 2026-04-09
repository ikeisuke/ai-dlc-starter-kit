# Unit: 汎用復帰判定仕様の策定と Inception への先行適用（#553 解決込み）

## 概要

フェーズインデックスに集約する「現在位置判定ロジック」の仕様を策定し、Inception Phase インデックスに先行適用する。コンパクション復帰時にインデックスのみで一意判定できる仕組みの基盤を本 Unit で確立する。Construction / Operations フェーズへの組み込みは Unit 003 / 004 の責務とする（本 Unit では共通仕様の定義のみ行い、各フェーズ側は Unit 003/004 で実装完了とみなす）。副次目的として #553（Inception 後半でのフェーズ誤判定バグ）を根本解決する。

## 含まれるユーザーストーリー

- ストーリー4: 汎用復帰判定基盤（インデックス集約型） — **Inception フェーズへの適用分と共通仕様の策定**
- ストーリー5: #553 回帰防止シナリオ（ストーリー4の受け入れ確認）

## 責務

### 共通判定仕様の策定

- 判定ロジックの規範仕様書 `steps/common/phase-recovery-spec.md` を作成する（本 Unit の**正本**）。以下を含む:
  - `ArtifactsState` の入力モデル（`requirements/`, `story-artifacts/`, `construction/`, `operations/` の具体ファイル + `phaseProgressStatus` enum）
  - 2段レゾルバ構造（`PhaseResolver` + `PhaseLocalStepResolver`）と判定順（conflict → Operations → Construction → Inception → 新規開始）
  - 判定結果マッピング（Inception §5.1 のチェックポイントルール）
  - 異常系4系統の処理仕様（`missing_file` / `conflict` / `format_error` / `legacy_structure`）と `result + diagnostics[]` 分離
- 各フェーズインデックスは本仕様書の **Materialized Binding**（実値化参照）として位置付け、規範仕様は常に `phase-recovery-spec.md` に一本化する（Unit 003 / 004 も同じ binding 形式で接続）

### Inception への先行適用

- Unit 001 で作成した Inception フェーズインデックスに、上記共通仕様に基づく「現在位置判定セクション」を実装する
- Inception の正常系検証: 代表的な進行中状態（Intent完了時点、ストーリー完了時点、Unit定義完了時点、完了処理中）で復帰判定が正しく動作することを確認（単一 step_id が導出されること）
- Inception の異常系検証: 欠損・競合・不正フォーマット・旧バージョン混在の4系統すべてが期待動作を示すことを確認
- **blocking 3系統（`missing_file` / `conflict` / `format_error`）は `automation_mode=semi_auto` でも自動継続しない（ユーザー確認必須）**
- **warning 1系統（`legacy_structure`）は `diagnostics[]` への追加のみで `result` 判定は継続可能。強制マイグレーションは行わない**

### #553 根本解決

- #553 再現シナリオ 1a（完了処理未着手）は `inception.04-stories-units`、1b（完了処理進行中）は `inception.05-completion`、シナリオ 2（全完了）は `construction` と、それぞれ**単一の値**に判定されることを仕様書内に明記する
- v2.2.3 判定ロジックとの対比を `phase-recovery-spec.md §10.3` に記録する（`phaseProgressStatus` enum 正規化によって書式依存の文字列マッチング取りこぼしを構造的に排除する旨）

### compaction.md の整理

- `compaction.md` の現在位置判定テーブルセクションを削除する
- `automation_mode` 復元等の他機能は存続させる
- `session-continuity.md` を新フロー（インデックス経由の復帰）に合わせて更新する

## 境界

- **含まない**: Construction / Operations フェーズインデックスへの判定ロジック組み込み（Unit 003 / 004 の責務。本 Unit では共通仕様を提供するのみ）
- **含まない**: `automation_mode` 復元ロジックの変更
- **含まない**: 計測レポート作成（Unit 006）

## 依存関係

### 依存する Unit

- Unit 001（Inception インデックスファイルの存在が前提）

### 本 Unit を依存元とする Unit

- Unit 003（Construction インデックスへの判定仕様組み込み）
- Unit 004（Operations インデックスへの判定仕様組み込み）

### 外部依存

- v2.2.3 タグ — #553 再現シナリオの対比記録に使用

## 非機能要件（NFR）

- **パフォーマンス**: 復帰時の追加ロードはフェーズインデックス（binding）1個 + 規範仕様 `phase-recovery-spec.md` 1個に限定する
- **信頼性**: blocking 3系統（`missing_file` / `conflict` / `format_error`）で自動継続を禁止しユーザー判断を必須とする。warning 1系統（`legacy_structure`）は `diagnostics[]` へ追加するのみで判定継続可能
- **後方互換性**: v2.2.x 以前の成果物構造を検出した場合は `diagnostics[]` に `legacy_structure` warning を追加するのみ（強制マイグレーションはしない）

## 技術的考慮事項

- **共通仕様書の位置付け**: 規範仕様の正本は `steps/common/phase-recovery-spec.md` に一本化し、各フェーズインデックスは仕様の **Materialized Binding**（実値化された参照層）として位置付ける。binding 層は `spec§N.<checkpoint_id>` 参照トークンで仕様と結合する。これにより Unit 003 / 004 での組み込みが機械的に行える
- **異常系の検知方法**: ファイル存在チェック + 簡易パース（progress.md のテーブル行数カウント、見出し構造の存在確認等）で判定。複雑な構文解析は避ける
- **回帰検証手順**: `scripts/` 配下に再現シナリオ準備スクリプトを用意するか、手動で `vTEST` サイクルを作成して再現する
- **複雑度**: 異常系4系統の実装 + 回帰検証 + compaction.md リファクタを含むため中規模。エクスプレス不適格

## 関連Issue

- #519: コンテキスト圧縮メイン Issue
- #553: コンパクション時の Inception 後半フェーズ誤判定

## 実装優先度

High

## 見積もり

中規模（2 日相当）。共通仕様策定 + Inception インデックス適用 + 異常系4系統 + compaction.md リファクタ + 再現シナリオ検証。

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-04-09
- **完了日**: 2026-04-09
- **担当**: Claude Code (Construction Phase)
- **エクスプレス適格性**: 不適格
- **適格性理由**: 異常系4系統の仕様策定 + #553 根本解決 + compaction.md/session-continuity.md リファクタを含む中規模 Unit のため、エクスプレスモード対象外
