# レビューサマリ: Unit 005 — gh pr edit スコープ不足エラーの REST PATCH fallback 経路追加

## 基本情報

- **サイクル**: v2.5.5
- **フェーズ**: Construction
- **対象**: Unit 005（gh pr edit スコープ不足エラーの REST PATCH fallback 経路追加 / 関連 Issue #626）

---

## Set 1: 2026-05-08（設計レビュー）

- **レビュー種別**: 設計レビュー（reviewing-construction-design）
- **使用ツール**: codex
- **反復回数**: 4
- **結論**: 指摘0件（4R clean、last_round_clean）

### 指摘一覧

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `.aidlc/cycles/v2.5.5/design-artifacts/domain-models/unit_005_gh_pr_edit_rest_patch_fallback_domain_model.md` - `PRBodyUpdateRequest` 不変条件（`pr_number > 0` / `body_file` 存在）が論理設計の「追加検証しない」記述と責務境界衝突 | 修正済み（domain_model.md: 不変条件を「前提条件（caller 側責務）」に弱め、本ヘルパー関数では検証しないと明記） | - |
| 2 | 中 | `.aidlc/cycles/v2.5.5/design-artifacts/logical-designs/unit_005_gh_pr_edit_rest_patch_fallback_logical_design.md`, `.aidlc/cycles/v2.5.5/plans/unit-005-plan.md` - ドリフト検知が「計画書 8 + ドメイン 9」で同期表現不整合 | 修正済み（domain_model.md §「ドリフト検知（クエリセット SoT）」を 9 クエリ SoT として確定。logical_design.md / unit-005-plan.md は SoT 参照に統一） | - |
| 3 | 中 | `.aidlc/cycles/v2.5.5/design-artifacts/logical-designs/unit_005_gh_pr_edit_rest_patch_fallback_logical_design.md` - bats fixture の `gh` 切替方式が「symlink または rename」で未確定 | 修正済み（logical_design.md: 単一 `gh` shim + `GH_MOCK_MODE` 環境変数 4 モード分岐方式に固定。bash 雛形を含めて記載。`tests/predecessor-issue-handoff.bats` 方式に統一） | - |
| 4 | 低 | `.aidlc/cycles/v2.5.5/design-artifacts/domain-models/unit_005_gh_pr_edit_rest_patch_fallback_domain_model.md` - Round 4+ 新領域指摘の境界（`scripts` / `tests` / `cycle-artifacts`）が未明示 | 修正済み（domain_model.md 末尾に「新規指摘の配置ルール」節追加） | - |
| 5 | 中 | `.aidlc/cycles/v2.5.5/design-artifacts/logical-designs/unit_005_gh_pr_edit_rest_patch_fallback_logical_design.md` - L27 の「入力検証（pr_number / body_file の非空チェック）」と L196 の「関数入口の検証」が Round 1 修正の caller 責務化と再衝突（Round 2 指摘） | 修正済み（logical_design.md: L27 を「（入力検証なし。caller 責務）」、エラーハンドリング表を「検証しない（caller 責務）」に修正） | - |
| 6 | 中 | `.aidlc/cycles/v2.5.5/plans/unit-005-plan.md` - fixture 方針が 5 ファイル列挙のまま残存、論理設計の「単一 shim」と SoT 不整合（Round 2 指摘） | 修正済み（unit-005-plan.md: 「変更対象ファイル」「fixture 構造」「完了条件チェックリスト」をすべて単一 `gh` shim + 4 モード分岐方式に統一） | - |
| 7 | 低 | `.aidlc/cycles/v2.5.5/design-artifacts/logical-designs/unit_005_gh_pr_edit_rest_patch_fallback_logical_design.md` - 見積もり節の「bats fixture スクリプト 5 種作成」が単一 shim 方針と不整合（Round 3 指摘） | 修正済み（logical_design.md: 見積もり節を「bats fixture（単一 `gh` shim + `GH_MOCK_MODE` 4 モード分岐）作成」に修正） | - |
| 8 | 低 | `.aidlc/cycles/v2.5.5/design-artifacts/domain-models/unit_005_gh_pr_edit_rest_patch_fallback_domain_model.md` - ユビキタス言語のヘルパー関数引数数が「3 引数受付」で、他セクションの 2 引数定義と表記ゆれ（Round 3 指摘） | 修正済み（domain_model.md: 「2 引数受付（`$1` PR 番号 / `$2` body_file パス）」に修正） | - |

### Round 4 早期 defer ガイド判定（review-flow.md §「Round 別指摘件数閾値」）

- Round 3 指摘 2 件（< 5）: アラート発動なし
- Round 4 指摘 0 件（< 3）: 千日手予兆なし
- 新規領域判定: K_old = `cycle-artifacts`（Round 1〜3 全指摘領域）, K_new = なし（空集合）, K_diff = なし → 新領域指摘 0 件、自動 backlog 化対象なし

---

---

## Set 2: 2026-05-08（コードレビュー）

- **レビュー種別**: コード生成後レビュー（reviewing-construction-code）
- **使用ツール**: codex
- **反復回数**: 1
- **結論**: 指摘 0 件（1R clean）

### 指摘一覧

指摘なし。

### 検証結果（ドリフト検知 Q1〜Q7 / コード側）

| クエリ | 内容 | hit 件数 | 判定 |
|-------|------|---------|------|
| Q1（不変条件 1: 4 grep パターン） | `grep -nE 'read:org\|read:discussion\|requires.*scope\|Could not resolve to a User'` | 2 | pass（≥ 1） |
| Q2（不変条件 2: DRY 化 / 4 hit） | `grep -nE 'gh_pr_edit_body_with_fallback'` | 4（コメント 1 + 定義 1 + 呼び出し 2） | pass（≥ 3） |
| Q3（不変条件 3: gh pr create 残存） | `grep -nE 'gh pr create'` | 7 | pass（≥ 1） |
| Q4（不変条件 4 発動） | `grep -nE 'pr-ready:fallback:rest-patch'` | 2 | pass（≥ 1） |
| Q5（不変条件 4 失敗） | `grep -nE 'pr-ready:fallback:rest-patch:failed'` | 1 | pass（≥ 1） |
| Q6（不変条件 4 PATCH） | `grep -nE 'gh api -X PATCH .*/repos/'` | 5（実装 1 + dry-run 4） | pass（≥ 1） |
| Q7（結合検証） | `awk '/^gh_pr_edit_body_with_fallback\(\)/,/^}/'` 内に `gh pr edit` と `gh api -X PATCH` の両方 | 両方 hit | pass |

---

## Set 3: 2026-05-08（統合とレビュー）

- **レビュー種別**: 統合とレビュー（reviewing-construction-integration）
- **使用ツール**: codex
- **反復回数**: 2
- **結論**: Round 1 指摘 4 件（高 1 / 中 2 / 低 1）→ Round 2 で 0 件、last_round_clean → auto_approved

### 指摘一覧（Round 1）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 高 | `skills/aidlc/scripts/operations-release.sh` - `gh pr edit` の stdout を `1>/dev/null` で破棄、PR URL 等の出力透過の後方互換性回帰 | 修正済み（gh_pr_edit_body_with_fallback: stderr のみを mktemp 経由で捕捉、stdout は呼び出し元へ透過。bats ケース 5 を追加して fallback 経路 stdout 透過も保証） | - |
| 2 | 中 | `.aidlc/cycles/v2.5.5/plans/unit-005-plan.md` - 完了条件チェックリストが全項目 `- [ ]` のまま、達成状況の機械的トレースが文書上未完了 | 修正済み（unit-005-plan.md: 全項目を実績に基づき `- [x]` に更新、行番号と検証根拠を追記） | - |
| 3 | 中 | `.aidlc/cycles/v2.5.5/construction/units/005-review-summary.md` - 統合レビュー Set（reviewing-construction-integration）が未記録 | 修正済み（本セクション Set 3 を追記） | - |
| 4 | 低 | `.aidlc/cycles/v2.5.5/history/construction_unit05.md` - DR-001「gh CLI 文言変化時に fixture 失敗で検知」の明示記録なし | 修正済み（履歴に DR-001 トリガー文を 1 行追記） | - |

---

## レビュー総括

| 観点 | 結論 |
|------|------|
| 計画レビュー | Round 1 指摘 4 件（中 2 / 低 2）→ Round 2 指摘 1 件（低 1）→ Round 3 で 0 件、auto_approved |
| 設計レビュー | Round 1 指摘 4 件（高 1 / 中 2 / 低 1）→ Round 2 指摘 2 件（中 2）→ Round 3 指摘 2 件（低 2）→ Round 4 で 0 件、auto_approved |
| コードレビュー | Round 1 指摘 0 件（1R clean）→ auto_approved |
| 統合レビュー | Round 1 指摘 4 件（高 1 / 中 2 / 低 1）→ Round 2 で 0 件、last_round_clean → auto_approved |
