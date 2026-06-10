# Unit: v3 移行方針

## 概要

`docs/v3/migration.md` を作成する。v2 → v3 の移行モード、データ変換マッピング、v2 との非互換点、推奨移行モード（new-cycle-only）と片方向移行を文書化する。方針のみ（スクリプト実装は対象外）。

## 含まれるユーザーストーリー
- ストーリー 4: v2 → v3 移行方針を提示する

## 責務
- `docs/v3/migration.md` の作成
- 移行モード（new-cycle-only / best-effort / archive-only）の定義 + 比較表（推奨対象 / 前提条件 / 変換有無 / 既知リスク）
- v2 → v3 データ変換マッピング（config / units / progress / history / release_notes）
- v2 との非互換点の列挙
- 推奨移行モードと片方向移行（rollback 不可）の明記

## 境界
- migration スクリプトの実装（後続フェーズ、本サイクル対象外）
- core/extension 境界（Unit 001）・data model 詳細（Unit 003）

## 依存関係

### 依存する Unit
- 001-v3-rfc-core（依存理由: core/extension 境界・非互換点の前提を RFC で確定するため）
- 003-v3-data-model（依存理由: v2 → v3 のデータ変換マッピングは v3 のディレクトリ構造・state.json schema・work item frontmatter が確定してから定義するため）

### 外部依存
- 入力: `docs/v3-renewal-plan.md`（v2 → v3 移行 / 非互換点セクション）

## 非機能要件（NFR）
- **網羅性**: 主要な v2 資産（config/units/progress/history/release_notes）の変換方針を網羅
- **明確性**: consumer が移行コストを見積もれる粒度

## 技術的考慮事項
- 方針のみを記述。実装は別フェーズ
- 推奨は new-cycle-only（過去資産を触らない）

## 関連Issue
- なし

## 実装優先度
Medium

## 見積もり
docs 1 ファイル（中）。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-10
- **完了日**: 2026-06-10
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

<!-- 進捗: 計画承認済 / 設計承認済 / Phase 2 完了（docs/v3/migration.md 執筆 + 設計レビュー Set 1(3R) + コードレビュー Set 2(2R) + 統合レビュー Set 3(2R)、いずれも codex / auto_approved）。完了条件 15 項目すべて充足。markdownlint 0 errors。変換先 schema は data-model.md 正本参照（二重定義回避）/ config 終端 schema は SoT ガードで新規定義せず未確定注記 / 非互換点 #4 は workflow.md §6.1 粒度・#10 に GitHub Release 統合（DG-5 整合）/ DG-3 引き継ぎ受け（EOL 3 条件等の相互関係を方針記述）/ コマンド名 develop 統一。 -->
