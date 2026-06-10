# 実装記録: Unit 001 v3-rfc-core（v3 RFC・core/extension 境界・設計判断確定）

## 実装日時

2026-06-10（Phase 2 = docs/v3/rfc.md 執筆〜統合レビュー完了）

## 作成ファイル

### ソースコード（docs-only 成果物）

- `docs/v3/rfc.md` - v3 全体設計の正本 RFC。全 7 章（概要・v2 課題 / v3 AI-DLC Principles / 方法論保全 / core-extension 境界 / Decision Gate Log / 削減目標 / 後続引き継ぎ）

### テスト

- markdownlint（`npx markdownlint-cli2 docs/v3/rfc.md`）- docs-only のためビルド/テストは markdownlint で代替

### 設計ドキュメント

- `.aidlc/cycles/v3.0.0-alpha.1/design-artifacts/logical-designs/unit_001_v3_rfc_core_logical_design.md`（ドメインモデルは N/A: docs-only）
- `.aidlc/cycles/v3.0.0-alpha.1/plans/unit-001-plan.md`
- `.aidlc/cycles/v3.0.0-alpha.1/construction/units/001-review-summary.md`（Set 1 設計 / Set 2 コード / Set 3 統合）

## ビルド結果

成功（docs-only / markdownlint をビルド相当として扱う）

```text
markdownlint-cli2 v0.22.1 (markdownlint v0.40.0)
Linting: 1 file(s)
Summary: 0 error(s)
```

## テスト結果

成功（markdownlint）

- 実行テスト数: 1（markdownlint 1 ファイル）
- 成功: 1
- 失敗: 0

```text
docs/v3/rfc.md: 0 errors（.markdownlint.json 適用 / MD013 無効・docs/v3 は lint 対象）
```

## コードレビュー結果

- [x] セキュリティ: OK（docs-only / 機密情報・ホーム配下絶対パス混入なし）
- [x] コーディング規約: OK（markdownlint 0 errors / documentation.language=日本語）
- [x] エラーハンドリング: N/A（実行可能コードなし）
- [x] テストカバレッジ: OK（markdownlint で検証 / 統合レビューで完了条件 9 項目充足確認）
- [x] ドキュメント: OK（設計判断 DG-1〜DG-6・境界基準・削減目標・後続引き継ぎを網羅）

レビュー内訳（`001-review-summary.md`）:

- Set 2 コード生成後レビュー（codex / docs 観点）: 2R（R1: 2 件 中1低1 → R2: 0 件）。§5.7 v2 凍結とメンテ例外整合・§7.1 markdownlint 充足記録を反映。
- Set 3 統合レビュー（codex）: 2R（R1: 1 件 中1 → R2: 0 件）。Express 適用単位を workflow.md 確定へ整理（トレーサビリティ）。完了条件 9 項目すべて充足確認。

## 技術的な決定事項

- **§6 削減目標の再計測**: 計画書概算（スクリプト 138 本 / 復帰仕様 819 行等）をそのまま使わず、測定定義に基づき v2 ベースラインを実測（スクリプト 97 本・27,600 行 / 復帰仕様 1,019 行 = 3 ファイル合算 等）。計画書との差分（§6.3）を「カウント単位の違い」として明示し、設計判断結論に影響しないことを記録。
- **設定キー終端値の不整合（8 vs 12）**: 計画書内の揺れを §6.4 で明記し、v3 確定値は data-model.md（Unit 003）に委譲。
- **Express 適用単位のトレーサビリティ**: 計画書 L803 由来の「単一 work item 限定」を、承認済み DG-2（= Express 維持）の範囲外の詳細と位置づけ、最終仕様を workflow.md（Unit 002）確定の引き継ぎ事項に整理。

## 課題・改善点

- v3 各削減指標の確定値は実装フェーズで再計測して確定（RFC は方向性・目標規模の提示）。
- 設定キー終端値・state.json schema・work item template の確定は後続 Unit（003）で実施。

## 状態

**完了**

## 備考

- 本 Unit は本サイクル最大の Unit（6 設計判断 + 境界基準 + 承認ゲート複数回）。設計判断はすべて Phase 1 でユーザー承認ゲートにより確定済み（Set 1）。
- すべてのゲート（コードレビュー承認・統合レビュー承認）は `automation_mode=semi_auto` により auto_approved。
