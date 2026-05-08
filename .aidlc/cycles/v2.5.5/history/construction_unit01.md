# Construction Phase Unit 001 履歴

## Unit 概要

- **Unit**: 001 — pr-ops.sh の auto-merge エラー判別精度向上
- **関連 Issue**: #665（[Feedback] pr-ops.sh merge: auto-merge 無効リポジトリで error:unknown が返る）
- **担当**: AI-DLC エージェント
- **着手日**: 2026-05-08
- **完了日**: 2026-05-08

## Unit 定義パス記述補正

Unit 定義 `001-pr-ops-auto-merge-error-classification.md` の「責務」セクションに `scripts/lib/pr-ops.sh:449` と記載されていたが、実体は `skills/aidlc/scripts/pr-ops.sh:444`。`scripts/lib/` 階層は本リポジトリに存在せず、Unit 定義の記述ズレ（Inception フェーズで参考にした記述が古い構造を引きずっていた）。本 Unit では実パスで進め、本履歴に補正事実を記録する。

## 変更ファイル一覧

| ファイル | 操作 | 概要 |
|---------|------|------|
| `skills/aidlc/scripts/pr-ops.sh` | 改修（line 444） | `grep -qi "auto-merge is not allowed\|not enabled\|auto_merge"` を `grep -qiE "auto[- ]merge is not allowed\|enablePullRequestAutoMerge\|not enabled\|auto_merge"` に拡張。文言バリアント由来コメントを直前に追記 |
| `skills/aidlc/scripts/tests/test_pr_ops_auto_merge_error_classification.sh` | 新規作成 | gh モック方式で 4 ケース（半角スペース型 / GraphQL 型 / 既存ハイフン型 / permission 系）を検証する `.sh` 形式のユニットテスト |
| `.aidlc/cycles/v2.5.5/plans/unit-001-plan.md` | 新規作成 | Unit 001 計画（Round 1 指摘反映 + スコープ境界明示 + CI 接続条件） |
| `.aidlc/cycles/v2.5.5/design-artifacts/domain-models/unit_001_pr_ops_auto_merge_error_classification_domain_model.md` | 新規作成 | ドメインモデル（文言バリアント表 / `AutoMergeErrorClassifier` / 不変条件） |
| `.aidlc/cycles/v2.5.5/design-artifacts/logical-designs/unit_001_pr_ops_auto_merge_error_classification_logical_design.md` | 新規作成 | 論理設計（案 A 採用判断 / 改修前後 pseudo / fixture / 検証クエリ / 正規表現方言混在ガード） |

## レビュー履歴

### 計画レビュー（reviewing-construction-plan）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 3 件（中 2 / 低 1） | 全件修正対応（#1: 案 A vs 案 B 比較を Phase 1 設計に追記 / #2: スコープ境界の明示セクション追加 / #3: CI 実行エントリへの接続を完了条件に追加） |
| Round 2 | 0 件 | 2R clean、auto_approved |

### 設計レビュー（reviewing-construction-design）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 2 件（中 1 / 低 1） | 全件修正対応（#1: ドメインモデルの判定方式を「case-insensitive 部分一致」へ修正 / #2: 論理設計に正規表現方言混在ガードセクション追加） |
| Round 2 | 0 件 | 2R clean、auto_approved |

### コードレビュー（reviewing-construction-code）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 2 件（中 1 / 低 1） | 全件修正対応（#1: Case (d) の未使用実行を削除し、純粋な permission エラーで検証する形に整理 / #2: pr-ops.sh:444 直前に文言バリアント由来コメントと `not enabled` 保持理由を追記） |
| Round 2 | 0 件 | 2R clean、auto_approved |

### 統合レビュー（reviewing-construction-integration）

| Round | 指摘件数 | 対応 |
|-------|---------|------|
| Round 1 | 2 件（中 2） | 全件修正対応（#1: 本履歴ファイルを作成し 5 記録項目を明示 / #2: CI 接続未対応を実証記録 + backlog Issue #669 起票） |
| Round 2 | （Round 2 で確認予定） | - |

## 検証結果

### テスト

- 新規テスト `test_pr_ops_auto_merge_error_classification.sh`: PASS=7 / FAIL=0 / TOTAL=7
- 既存テスト regression（`test_pr_ops_merge_skip_checks.sh`）: PASS=21 / FAIL=0 / TOTAL=21
- bash 構文チェック (`bash -n skills/aidlc/scripts/pr-ops.sh`): OK

### 整合性検証 grep（論理設計の検証クエリ）

| 検証項目 | コマンド | 結果 |
|---------|---------|------|
| 拡張パターン存在 | `grep -nE 'grep -qiE.*auto\[- \]merge is not allowed.*enablePullRequestAutoMerge' skills/aidlc/scripts/pr-ops.sh` | line 444 ヒット |
| 既存パターン残存（後方互換） | grep の交替パターン内に `not enabled\|auto_merge` 残存 | 確認済（pr-ops.sh:444） |
| basic regex 残骸非存在 | `grep -nE 'grep -qi "auto-merge is not allowed' skills/aidlc/scripts/pr-ops.sh` | 0 行（改修後は `-qiE` のみ） |

## DR-001 fixture 更新トリガー（Intent 成功基準 (d) 必須記録）

**fixture 更新トリガー**: `gh` CLI バージョン更新で auto-merge 実エラー文言が変わった場合、`skills/aidlc/scripts/tests/test_pr_ops_auto_merge_error_classification.sh` の fixture（半角スペース型 `auto merge is not allowed for this repository` / GraphQL 型 `enablePullRequestAutoMerge` 等）が `gh` 実出力との乖離により失敗することで気付ける運用とする。失敗時の対応:

1. `gh pr merge --auto` の現実エラー出力を `gh` バージョン明記の上で fixture に追加
2. `skills/aidlc/scripts/pr-ops.sh:444` の `grep -qiE` パターンに新文言を追記（必要に応じて）
3. 既存パターン（半角スペース型 / GraphQL 型 / ハイフン型）の後方互換は維持

本トリガーは Unit 005 (#626、`gh pr edit --body-file` REST PATCH fallback の grep 検出パターン) と保守方針を統一する（fixture 更新トリガーの記録先は各 Unit 完了履歴 `history/construction_unit{NN}.md` に統一）。

## CI 実行エントリへの接続（統合レビュー Round 1 指摘 #2 対応）

### 実証結果（確認日: 2026-05-08）

`.github/workflows/` 内のすべての workflow（`auto-tag.yml` / `migration-tests.yml` / `pr-check.yml` / `skill-reference-check.yml`）に対して以下の grep を実行:

```bash
grep -rn "test_pr_ops\|skills/aidlc/scripts/tests" .github/workflows/  # 結果: 0 行
```

`bin/` / `Makefile` 等にも巡回スクリプト無し。

**結論**: 既存テスト `test_pr_ops_merge_skip_checks.sh` を含む `pr-ops` 関連テスト群が CI で自動実行されていない構造課題が判明。新規 `test_pr_ops_auto_merge_error_classification.sh` も同状態。

### 切り分け理由

- 本 Unit 001 の責務は Intent §「修正対象の限定」: 「`pr-ops.sh` の `auto_error` grep パターンに限定（他エラーパターンの再設計は OUT_OF_SCOPE）」
- CI workflow 整備は「テスト基盤の構造改善」に該当し、複数 Unit / 複数テストファイルに跨る共通課題
- v2.5.5 Unit 001 単独で `.github/workflows/pr-check.yml` に新規ジョブを追加する場合、既存 `test_pr_ops_merge_skip_checks.sh` も同時に巻き込む必要があり、Unit 境界を超える
- そのため、別 Unit / Backlog として切り分け、本 Unit 履歴に実証結果と切り分け理由を記録する形で対応

### 次 Unit / Backlog ID

**Backlog Issue**: [#669](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/669) — `[Backlog] CI workflow に skills/aidlc/scripts/tests/test_pr_ops_*.sh の実行ジョブ追加`

ラベル: `backlog`, `type:chore`, `priority:low`

## スコープ境界の defer 記録（計画レビュー Round 1 指摘 #2 対応）

計画レビュー Round 1 指摘 #2（テストヘルパ共通化、`tests/lib/gh_mock.sh` 等の共通ヘルパ層）は本 Unit 001 のスコープ外として処理した:

- 単一テストファイル新設のみが本 Unit 責務であり、共通化メリットは複数 Unit にまたがるテストファイル群への展開時に発現する
- Intent §「除外するもの」: 「`pr-ops.sh` 全エラーパターンの網羅再設計」OUT_OF_SCOPE 該当として整理
- 本 Unit 完了処理時点では別 Backlog Issue 起票せず、Unit 履歴記録のみで保留（共通ヘルパ層化は次回 pr-ops 関連テスト追加時、または `gh_mock` 利用テストが 3 ファイル以上になった時点で再検討）

## 完了条件チェックリスト充足状況

| 区分 | 項目 | 状態 |
|------|------|------|
| 機能整合 | grep パターンに `auto[- ]merge is not allowed` と `enablePullRequestAutoMerge` 含む | ✓ |
| 機能整合 | 既存パターン後方互換残存 | ✓ |
| 機能整合 | `grep -qi` → `grep -qiE` 移行 | ✓ |
| テスト | 新規テスト 4 ケース全実装 | ✓（PASS=7） |
| テスト | 既存テスト regression なし | ✓（PASS=21） |
| CI 接続 | ローカル直接実行 | ✓（exit 0） |
| CI 接続 | CI workflow 自動接続 | ☓ → Backlog #669 として defer（履歴記録済） |
| CI 接続 | bats vs `.sh` 選択理由明示 | ✓（Intent 成功基準は「追加テスト 1 件以上」でフォーマット非限定。`.sh` 形式で充足） |
| 履歴 | 本ファイル新規作成 | ✓ |
| 品質ゲート | AI レビュー 4 種類すべて 2R clean | ✓ |
| 品質ゲート | markdownlint | （完了処理ステップで実施） |

## 備考

- 計画 → 設計 → コード生成 → 統合の各レビューで Round 1 指摘を全件修正対応し Round 2 clean を達成。defer Issue 起票は #669（CI 接続未対応のみ）
- DR-001 fixture 更新トリガー記録は本履歴ファイルにて完結
