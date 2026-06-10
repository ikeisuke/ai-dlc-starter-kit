# Unit: v3 データモデル・state schema・work item template 確定

## 概要

`docs/v3/data-model.md` を作成する。v3 ディレクトリ構造、state.json schema、work item frontmatter、フェーズ導出ロジック、journal 形式、size × depth_level マトリクスを確定する。state.json schema 初版と work item template 初版を確定例示として含む。

## 含まれるユーザーストーリー
- ストーリー 3: データモデルと state schema を確定する

## 責務
- `docs/v3/data-model.md` の作成
- v3 ディレクトリ構造の確定
- state.json schema 確定例示（必須フィールド集合・型・schema_version 値・enum 値の明示）
- work item Markdown template 確定例示（必須 frontmatter キー・enum 値・本文必須セクションの明示）
- フェーズ導出ロジック（state.json + frontmatter → フェーズ）
- 破損・不正・矛盾時の扱い（doctor が検知する破損パターンと復帰可否の方針 / 方針レベル、validator 実装は対象外）
- journal 形式・size × depth_level マトリクス

## 境界
- state format の選定理由（Unit 001 設計判断 #6 で確定）
- validator / state スクリプト実装（後続フェーズ、本サイクル対象外）
- migration のデータ変換マッピング（Unit 004）

## 依存関係

### 依存する Unit
- 001-v3-rfc-core（依存理由: state format の結論（設計判断 #6: ハイブリッド）を RFC で確定してから schema を具体化するため）

### 外部依存
- 入力: `docs/v3-renewal-plan.md`（データモデルセクション）

## 非機能要件（NFR）
- **明確性**: schema / template の固定対象が測定可能に明示されている
- **SoT**: フェーズ導出ロジックの正本（Single Source of Truth）として記述する（Unit 002 はこれを参照する）
- **整合性**: workflow.md のフェーズ導出記述（Unit 002）と矛盾しない

## 技術的考慮事項
- state format は RFC 設計判断 #6 の結論に従う
- schema は JSON、work item は Markdown frontmatter（分散状態モデル）
- validator 実装は本サイクル対象外（schema の文書確定のみ）

## 関連Issue
- なし

## 実装優先度
High

## 見積もり
docs 1 ファイル（中）。schema / template 例示を含む。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-10
- **完了日**: 2026-06-10
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

<!-- 進捗: 計画承認済 / 設計承認済 / Phase 2 完了（docs/v3/data-model.md 執筆 + 設計レビュー Set 1(4R) + コードレビュー Set 2(2R) + 統合レビュー Set 3(2R)、いずれも codex / auto_approved）。完了条件 12 項目すべて充足。markdownlint 0 errors。フェーズ導出ロジックの SoT を data-model.md §5 に確定し、workflow.md §7.1 を結果参照（非規範スナップショット）に追従（drift 防止）。コマンド名は develop 統一（計画書 build 不混入）。 -->
