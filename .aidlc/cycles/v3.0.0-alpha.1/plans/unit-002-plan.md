# Unit 002 計画: v3 ワークフロー設計

## 対象 Unit

- Unit 002: v3-workflow
- 成果物: `docs/v3/workflow.md`
- 依存: Unit 001 v3-rfc-core（完了）。RFC の設計判断（DG-1 コマンド名 / DG-2 Express / DG-4 review 統合 / DG-5 GitHub 前提）と core/extension 境界基準を入力とする
- 入力参照: `docs/v3/rfc.md`（確定済み RFC）、`docs/v3-renewal-plan.md`（ワークフロー / フェーズ詳細設計セクション: コマンド設計 L159-187・各フェーズ詳細 L716-937・承認ゲート対応表 L102-112）
- 見積もり: docs 1 ファイル（中〜大）

## 前提整合（Unit 定義の旧表記補正）

- Unit 定義ファイル（`002-v3-workflow.md`）は Inception 時点の表記で **コマンド名を `define/build/release/reflect`** と記述しているが、**RFC DG-1 で `define/develop/release/reflect` に確定**済み（"build" は compile 連想のため不採用、"develop" 採用）。本 Unit は **RFC 確定名 `develop` を正本**として設計する（"build" は使用しない）。

## アプローチ

docs-only の設計文書のため、Phase 1（設計）/ Phase 2（実装）を以下にマッピングする:

- **Phase 1（設計）**: workflow.md の論理設計（章立て + 各コマンドの責務定義 + v2 対応表 + 引数なしルーティング設計 + 各フェーズ Step 詳細 + Express 扱い）を design-artifacts に記録する。RFC 引き継ぎマトリクス（rfc.md §7）の DG-1/DG-2/DG-4/DG-5 制約を反映する。フェーズ導出ロジックは **正本を data-model.md（Unit 003）に置く**ため、workflow.md は導出結果を参照する形で記述し二重定義しない（参照先未確定部分は「data-model.md で確定」と引き継ぎ事項化）。
- **Phase 2（実装）**: 確定設計に基づき `docs/v3/workflow.md` を執筆。

## 成果物の責務（Unit 定義由来）

- 6 コマンドの責務定義: **define / develop / release / reflect = フェーズコマンド**、**status / doctor = 補助コマンド（読み取り専用 / 診断）** として区別
- v2 コマンド（inception/construction/operations/retrospective）との対応・エイリアス方針（DG-1: 旧名のみ後方互換エイリアス、不採用動詞は別名にしない）
- 引数なし実行時のフェーズ自動ルーティング仕様（フェーズ導出は data-model.md SoT を参照）
- 各フェーズ（define/develop/release/reflect/status/doctor）の Step 詳細設計
- Express モードの扱い（DG-2: 維持。連続実行の適用単位は RFC で workflow.md 確定の引き継ぎ事項とされている → 本 Unit で確定）

## 完了条件チェックリスト（Unit 002 責務由来）

- [ ] `docs/v3/workflow.md` が作成されている
- [ ] 6 コマンド（define/develop/release/reflect/status/doctor）の責務が定義され、フェーズコマンド 4 と補助コマンド 2（読み取り専用/診断）が区別されている
- [ ] v2 コマンドとの対応表・エイリアス方針が記載され、RFC DG-1（旧名のみエイリアス・不採用動詞非エイリアス・develop 採用）と整合している
- [ ] 引数なし実行時のフェーズ自動ルーティング仕様が記載され、フェーズ導出ロジックの正本を data-model.md（Unit 003）に委ねる形で二重定義していない
- [ ] 各フェーズ（define/develop/release/reflect/status/doctor）の Step 詳細設計が記載されている
- [ ] Express モードの扱い（DG-2）が記載され、連続実行の適用単位が確定している
- [ ] DG-4（review 統合: 各フェーズの review 呼び出しは perspective 指定）が各フェーズ Step に反映されている
- [ ] DG-5（core は Issue/PR まで。Projects/Milestone/Release は extension）と整合し、core ワークフローが extension 不在でも成立している
- [ ] RFC の設計判断結論・core/extension 境界と矛盾しない
- [ ] 成果物が docs/v3 配下に限定され実行可能コードを生成していない
- [ ] markdownlint を通過する

## レビュー方針

- Phase 1（設計）: 計画承認前レビュー（reviewing-construction-plan）、設計レビュー（reviewing-construction-design）
- Phase 2（実装）: コードレビュー（reviewing-construction-code）、統合レビュー（reviewing-construction-integration）。**docs-only のため code レビューは docs 向け観点で適用**: RFC との整合性 / 設計判断の反映漏れ / data-model.md との SoT 二重定義回避 / markdownlint / 後続 Unit への入力としての明確性
- review_mode=required のためスキップ不可。tools=codex。

## 非スコープ

- core/extension 境界・設計判断の結論（Unit 001 で確定済み・参照のみ）
- state.json schema 詳細・フェーズ導出ロジックの正本（Unit 003 data-model.md）
- migration のデータ変換（Unit 004）
- skeleton / スクリプト実装（後続フェーズ）
