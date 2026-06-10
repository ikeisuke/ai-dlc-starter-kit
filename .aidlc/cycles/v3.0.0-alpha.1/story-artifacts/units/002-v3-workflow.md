# Unit: v3 ワークフロー設計

## 概要

`docs/v3/workflow.md` を作成する。define / build / release / reflect / status / doctor の責務、v2 コマンド対応、引数なし実行ルーティング、各フェーズの Step レベル詳細設計を文書化する。

## 含まれるユーザーストーリー
- ストーリー 2: ワークフロー設計を文書化する

## 責務
- `docs/v3/workflow.md` の作成
- 6 コマンドの責務定義（define/build/release/reflect = フェーズコマンド、status/doctor = 補助コマンド（読み取り専用 / 診断）として区別）
- v2 コマンドとの対応・エイリアス方針
- 引数なし実行時のフェーズ自動ルーティング仕様
- 各フェーズ（define/build/release/reflect/status/doctor）の Step 詳細設計
- Express モードの扱い

## 境界
- core/extension 境界・設計判断の結論（Unit 001 で確定）
- state.json schema 詳細（Unit 003）
- フェーズ導出ロジックの正本（SoT）は Unit 003 の data-model.md。本 Unit は自動ルーティングがその導出ロジックを参照する形で記述する（ロジック本体は再定義しない）
- 実装は対象外

## 依存関係

### 依存する Unit
- 001-v3-rfc-core（依存理由: コマンド名の結論（設計判断 #1）・core/extension 境界・Express の扱いを RFC で確定してから workflow に反映するため）

### 外部依存
- 入力: `docs/v3-renewal-plan.md`（v3 ワークフロー / フェーズ詳細設計セクション）

## 非機能要件（NFR）
- **整合性**: RFC の設計判断結論と矛盾しない
- **完全性**: 6 コマンド全ての責務と各フェーズの Step を網羅

## 技術的考慮事項
- コマンド名は RFC 設計判断 #1 の結論に従う
- フェーズ導出ロジックの正本は data-model.md（Unit 003）。workflow.md は引数なし実行のルーティングがその導出結果を参照する形で記述し、二重定義しない

## 関連Issue
- なし

## 実装優先度
High

## 見積もり
docs 1 ファイル（中〜大）。

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-06-10
- **完了日**: 2026-06-10
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -

<!-- 進捗: 計画承認済 / 設計承認済 / Phase 2 完了（docs/v3/workflow.md 執筆 + コードレビュー Set 2(3R) + 統合レビュー Set 3(1R)、いずれも auto_approved）。完了条件 11 項目すべて充足。コマンド名は RFC DG-1 確定の develop を採用（Unit 定義冒頭の旧表記 build は RFC 準拠で develop に補正済み） -->
