# Unit 003 計画: v3 データモデル・state schema・work item template 確定

## 対象 Unit

- Unit 003: v3-data-model
- 成果物: `docs/v3/data-model.md`
- 依存: Unit 001 v3-rfc-core（完了）。RFC 設計判断 DG-6（state format = ハイブリッド: cycle = state.json / work item = Markdown frontmatter）を入力とする
- 入力参照:
  - `docs/v3/rfc.md`（確定済み RFC。DG-6 §5.6・引き継ぎマトリクス §7 の「DG-6 → data-model.md」行）
  - `docs/v3/workflow.md`（Unit 002 完了。§2.3 引数なしルーティング / §7.1 フェーズ導出ロジックの参照 = 本 Unit が正本化する対象）
  - `docs/v3-renewal-plan.md`（データモデルセクション L235-462: ディレクトリ構造・分散状態モデル・state.json schema・work item frontmatter/template・フェーズ導出ロジック・size×depth_level・journal・成果物一覧）
- 見積もり: docs 1 ファイル（中）。schema / template 例示を含む

## アプローチ

docs-only の設計文書のため、Phase 1（設計）/ Phase 2（実装）を Unit 002 と同様にマッピングする:

- **Phase 1（設計）**: data-model.md の論理設計（章立て + 各セクションの確定内容の骨子）を `design-artifacts/logical-designs/unit_003_v3_data_model_logical_design.md` に記録する。ドメインモデルは docs-only のため N/A。
- **Phase 2（実装）**: 確定設計に基づき `docs/v3/data-model.md` を執筆。

## SoT・整合方針（重要）

- 本 Unit はフェーズ導出ロジックの**正本（SoT）**を確定する。workflow.md §7.1 の導出表は「参考（正本は data-model.md）」と明記されており、本 Unit 確定をもって正本化される。
- **コマンド名整合**: RFC DG-1 / workflow.md で確定した `develop`（旧表記 `build` 不採用）を使用する。計画書（renewal-plan）データモデルセクションは旧表記 `build` を含むが、本 Unit は確定名 `develop` を正本とする。
- フェーズ導出表は state.json + work item frontmatter からの導出として記述し、`current_phase` は状態として保持しない（DG-6 / workflow.md §7 と整合）。`complete` 判定には `release.merge_approved`（ブランチ上の承認記録）と PR の実態（実際に merged か）の両方を要する。

## 成果物の責務（Unit 定義由来）

- `docs/v3/data-model.md` の作成
- v3 ディレクトリ構造の確定
- state.json schema 確定例示（必須フィールド集合・型・`schema_version` 値・enum 値の明示）
- work item Markdown template 確定例示（必須 frontmatter キー・enum 値・本文必須セクションの明示）
- フェーズ導出ロジック（state.json + frontmatter → フェーズ）の正本記述
- 破損・不正・矛盾時の扱い（doctor が検知する破損パターンと復帰可否の方針 / 方針レベル。validator 実装は対象外）
- journal 形式・size × depth_level マトリクス

## 完了条件チェックリスト（Unit 003 責務由来）

- [ ] `docs/v3/data-model.md` が作成されている
- [ ] v3 ディレクトリ構造が確定され、各成果物（state.json / cycles 配下 / work-items / designs / reviews / journal / release / reflect）の配置と生成フェーズが明示されている
- [ ] state.json schema が確定例示として記述され、必須フィールド集合・型・`schema_version` 値・enum 値・各フィールドの書き込みタイミングと書き込み主体が明示されている
- [ ] work item Markdown template が確定例示として記述され、必須 frontmatter キー（id/status/size/risk/assigned/dependencies）・各 enum 値（status/size/risk）・本文必須セクションが明示されている
- [ ] フェーズ導出ロジック（state.json + frontmatter → define/develop/release/complete）が正本（SoT）として記述され、`current_phase` 非保持・complete 判定の merge_approved+PR 実態併用が明示されている
- [ ] 破損・不正・矛盾時の扱い（doctor が検知する破損パターンと復帰可否の方針）が方針レベルで記述され、validator 実装が対象外であることが明示されている
- [ ] journal 形式（追記型・軽量・目的）と size × depth_level マトリクスが記述されている
- [ ] workflow.md（Unit 002）の引数なしルーティング / status / doctor のフェーズ導出記述と矛盾せず、SoT を二重定義していない（workflow.md は導出結果参照、本書が導出規則の正本）
- [ ] コマンド名が RFC/workflow.md 確定の `develop` に整合している（旧表記 `build` を使用していない）
- [ ] RFC DG-6 の設計判断結論（ハイブリッド state format）と矛盾しない
- [ ] Unit の最終成果物が `docs/v3/data-model.md`（docs/v3 配下）に限定され、実行可能コード（validator / state スクリプト）を生成していない（`design-artifacts/logical-designs/` 配下の論理設計は AI-DLC 設計フェーズのプロセス記録であり、Unit 最終成果物には含めない）
- [ ] markdownlint を通過する

## レビュー方針

- Phase 1（設計）: 計画承認前レビュー（reviewing-construction-plan）、設計レビュー（reviewing-construction-design）
- Phase 2（実装）: コードレビュー（reviewing-construction-code）、統合レビュー（reviewing-construction-integration）。**docs-only のため code レビューは docs 向け観点で適用**: RFC DG-6 との整合性 / workflow.md との SoT 二重定義回避 / コマンド名整合（develop）/ schema・template 例示の確定性（必須集合・型・enum の明示） / markdownlint / 後続 Unit 004（migration）への入力としての明確性
- review_mode=required のためスキップ不可。tools=codex。

## 非スコープ

- state format の選定理由（Unit 001 RFC DG-6 で確定済み・参照のみ）
- validator / state スクリプト実装（後続フェーズ、本サイクル対象外）
- migration のデータ変換マッピング（Unit 004 data-model 確定後に定義）
- skeleton / スクリプト実装（後続フェーズ）
