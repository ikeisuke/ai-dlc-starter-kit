# 実装記録: Unit 003 v3-data-model（v3 データモデル・state schema・work item template 確定）

## 実装日時

2026-06-10（Phase 2 = docs/v3/data-model.md 執筆〜統合レビュー完了）

## 作成ファイル

### ソースコード（docs-only 成果物）

- `docs/v3/data-model.md` - v3 データモデルの正本。全 10 章（概要/目的 / ディレクトリ構造 / state.json schema / work item frontmatter+テンプレート / フェーズ導出ロジック SoT / 破損・不正・矛盾時の扱い / journal 形式 / size×depth_level マトリクス / trace・RFC/workflow.md 整合 / 成果物一覧マトリクス）

### 関連変更（整合追従）

- `docs/v3/workflow.md` §7.1 - data-model.md §5 の SoT 確定に伴い、参考表を非規範スナップショット化し確定前文言を更新（統合レビュー指摘対応 / drift 防止）

### テスト

- markdownlint（`npx markdownlint-cli2 docs/v3/data-model.md docs/v3/workflow.md`）- docs-only のためビルド/テストは markdownlint で代替

### 設計ドキュメント

- `.aidlc/cycles/v3.0.0-alpha.1/design-artifacts/logical-designs/unit_003_v3_data_model_logical_design.md`（ドメインモデルは N/A: docs-only）
- `.aidlc/cycles/v3.0.0-alpha.1/plans/unit-003-plan.md`
- `.aidlc/cycles/v3.0.0-alpha.1/construction/units/003-review-summary.md`（Set 1 設計 / Set 2 コード / Set 3 統合）

## ビルド結果

成功（docs-only / markdownlint をビルド相当として扱う）

```text
markdownlint-cli2: docs/v3/data-model.md, docs/v3/workflow.md
Summary: 0 error(s)
```

## テスト結果

成功（markdownlint）

- 実行テスト数: 2（markdownlint 2 ファイル）
- 成功: 2
- 失敗: 0

## コードレビュー結果

- [x] セキュリティ: OK（docs-only / 機密情報・ホーム配下絶対パス混入なし / state.json・frontmatter に機密保存する設計でないことを codex 確認 = N/A 妥当）
- [x] コーディング規約: OK（markdownlint 0 errors / documentation.language=日本語）
- [x] エラーハンドリング: N/A（実行可能コードなし。破損時方針は §6 で方針レベル確定 / validator 実装は対象外）
- [x] テストカバレッジ: OK（markdownlint で検証 / 統合レビューで完了条件 12 項目充足確認）
- [x] ドキュメント: OK（ディレクトリ構造・state.json schema・work item template・フェーズ導出 SoT・破損方針・journal・size×depth_level を網羅）

レビュー内訳（`003-review-summary.md`）:

- Set 1 設計レビュー（codex）: 4R（R1: 5 件 → R2: 3 件 → R3: 1 件 → R4: 0 件）。§5 導出表 first-match 評価順序・dependency 解決規則・§8↔§10 成果物要否整合。
- Set 2 コード生成後レビュー（codex / docs+security 観点）: 2R（R1: 2 件 → R2: 0 件）。depth_level 保存場所明記・reviews/*.md の develop 限定。security N/A。
- Set 3 統合レビュー（codex）: 2R（R1: 1 件 → R2: 0 件）。完了条件 12 項目すべて充足確認・workflow.md §7.1 drift 解消。

## 技術的な決定事項

- **フェーズ導出ロジック SoT の正本化**: フェーズ導出規則の本体を data-model.md §5 に確定（first-match 評価順 / `complete` 最優先 / `current_phase` 非保持 / `complete` 判定は merge_approved + PR 実態の両方）。workflow.md は結果参照に統一し SoT 二重定義を回避（§7.1 を非規範スナップショット化）。
- **dependency 解決規則の確定**: develop の work item 選定は `dependencies` 全 done が条件。`withdrawn` 依存先は人間判断（依存解除 or dependent も withdrawn）まで blocked 相当。cycle 終端の release 可能判定（done/withdrawn 両完了扱い）とは別レイヤとして矛盾しないことを明示（§5.2）。
- **成果物要否の正本を §8 に一元化**: size × depth_level マトリクス（§8）を成果物要否の唯一の正本とし、§10 成果物一覧と §2 ディレクトリ構造コメントを §8 依存のビューに整合（計画書原文の成果物一覧と size×depth_level の食い違いを解消）。
- **depth_level の保存場所明記**: `.aidlc/config.toml` の設定キー（enum minimal/standard/comprehensive、既定 standard、サイクル単位固定）と確定し、`size`（frontmatter）× `depth_level`（config）の組で成果物要否を判定可能にした。config キー全体の終端設計はスコープ外（RFC §6 で別途）。
- **build → develop 統一**: 計画書データモデルセクションの旧表記「build」を成果物全体で「develop」に統一（RFC DG-1 / workflow.md 確定に整合）。
- **review 成果物の保存先区別**: `reviews/*.md` は develop の work item レビュー限定、release-level review（premerge/integration/deploy）は `release.md` に集約と明示。

## 課題・改善点

- v2 → v3 のデータ変換マッピング（state.json / frontmatter の移行）は Unit 004（migration.md）で本 data-model.md を入力として定義する。
- v3 config.toml キー全体の終端設計（キー数削減・命名）は RFC §6 で別途確定。
- validator / state 操作スクリプトの実装は後続フェーズ（本サイクル対象外）。

## 状態

**完了**

## 備考

- すべてのゲート（計画承認・設計承認・コードレビュー承認・統合レビュー承認）は `automation_mode=semi_auto` により auto_approved。
- 完了条件 12 項目すべて充足（統合レビューで codex 確認）。
- 意思決定記録: 本 Unit の Phase 1/2 で新規のユーザー 2 択選択は発生せず（設計判断は Unit 001 RFC で確定済み、レビュー指摘はすべてメインエージェント判断で修正、スコープ縮小なし）。意思決定記録の対象なし。
