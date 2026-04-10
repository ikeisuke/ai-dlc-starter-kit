# Unit 004 検証記録: Operations Phase Index パイロット実装の静的検証

## 概要

本 Unit は Operations Phase の Materialized Binding 層（`skills/aidlc/steps/operations/index.md`）と規範仕様 §5.3 の実値化、および 2 段レゾルバ構造（`PhaseResolver` + `OperationsStepResolver`）のドキュメント成果物が主である。判定ロジックはコードとして実行されるのではなく、AI エージェントが spec を読んで判定に従う形で動作する。そのため「テスト」は以下の**静的検証**として実施する:

1. Operations 固有の 7 ケース fixture を `verify-operations-recovery.sh --dry-run` で生成可能なことを確認
2. 各ケースの期待値（`expected_phase` / `expected_step_id` / `expected_diagnostics`）が `phase-recovery-spec.md §5.3` の判定規則に照らして**単一の値**に固定できることを仕様レベルで照合
3. `spec_refs` に列挙された仕様セクションが実在することを確認
4. 初回ロード時の token 量が v2.2.3 ベースライン（17,827 tok）以下であることを計測
5. `check-bash-substitution.sh` / `markdownlint` が違反ゼロで完了することを確認

実際の対話フロー再実行は Unit 006 の最終検証で一括実施する。

## 実行結果サマリ

| 検証項目 | 結果 |
|---------|------|
| 7 ケース fixture dry-run 成功 | ✓ 全 7 ケース成功 |
| 期待値の単値性（spec §5.3 照合） | ✓ 全ケース単値 |
| `spec_refs` の実在確認 | ✓ 全参照実在 |
| 初回ロード token 計測 | **15,394 tok**（ベースライン 17,827 tok より -2,433 tok、-13.7%） |
| `check-bash-substitution.sh`（CI デフォルトスコープ） | ✓ 違反ゼロ（33 ファイル検査） |
| `run-markdownlint.sh v2.3.0` | ✓ エラーゼロ |

## 検証 1: fixture 7 ケース dry-run

**実行コマンド**:

```bash
for c in normal-deploy-fresh normal-deploy-progress normal-release normal-completion bootstrap-from-construction abnormal-operations_in_progress_missing_progress abnormal-progress_corrupt; do
  skills/aidlc/scripts/verify-operations-recovery.sh --case "$c" --dry-run
done
```

**結果**: 全 7 ケースが成功（終了コード 0）、期待値を含む fixture が正しく生成される。

### 正常系 4 ケース（4 step_id すべて + 境界条件）

| # | ケース | expected_phase | expected_step_id | spec_refs | 単値性 |
|---|--------|---------------|------------------|-----------|-------|
| 1 | normal-deploy-fresh | `operations` | `operations.02-deploy` | `spec§4;spec§5.operations.deploy_done;spec§6;spec§8;spec§12` | ✓ |
| 2 | normal-deploy-progress | `operations` | `operations.02-deploy` | `spec§4;spec§5.operations.deploy_done;spec§6;spec§8;spec§12` | ✓ |
| 3 | normal-release | `operations` | `operations.03-release` | `spec§4;spec§5.operations.release_done;spec§6;spec§8;spec§12` | ✓ |
| 4 | normal-completion | `operations` | `operations.04-completion` | `spec§4;spec§5.operations.completion_done;spec§6;spec§8;spec§12` | ✓ |

**仕様との照合**:

- **normal-deploy-fresh**: progress.md 存在（setup_done=true）、ステップ1-7 すべて未着手（deploy_done=false） → spec §5.3.1.2 で `deploy_done=false` に合致 → `operations.02-deploy` で単値
- **normal-deploy-progress**: progress.md 存在、ステップ1-3 完了、ステップ4-7 進行中 → 引き続き `deploy_done=false` → `operations.02-deploy` で単値（境界条件中間）
- **normal-release**: progress.md ステップ1-7 すべて「完了」or「スキップ」（deploy_done=true）、history に PR Ready 化記録なし（release_done=false） → spec §5.3.1.3 に合致 → `operations.03-release` で単値
- **normal-completion**: 上記 + history に PR Ready 化記録あり（release_done=true）、PR マージ記録なし（completion_done=false） → spec §5.3.1.4 に合致 → `operations.04-completion` で単値

### bootstrap 1 ケース

| # | ケース | expected_phase | expected_step_id | expected_diagnostics | spec_refs | 単値性 |
|---|--------|---------------|------------------|---------------------|-----------|-------|
| 5 | bootstrap-from-construction | `operations` | `operations.01-setup` | `construction_complete` | `spec§4;spec§5.operations.bootstrap;spec§5.operations.setup_done;spec§6;spec§8;spec§12` | ✓ |

**仕様との照合**:

- Construction 完了状態（`phaseProgressStatus[construction]=completed`）、operations/progress.md 未存在、history/operations.md 未存在 → spec §5.3.0 `OperationsBootstrapRule.isBootstrap=true` → `operations.01-setup` + `construction_complete` info diagnostic で単値
- これは Unit 003 で確立した Construction → Operations 遷移パスが Unit 004 の `OperationsStepResolver` に正しく接続されていることを検証する

### 異常系 2 ケース

| # | ケース | expected_phase | expected_step_id | spec_refs | 単値性 |
|---|--------|---------------|------------------|-----------|-------|
| 6 | abnormal-operations_in_progress_missing_progress | `operations` | `undecidable:missing_file` | `spec§4;spec§5.operations.setup_done;spec§7;spec§8;spec§12` | ✓ |
| 7 | abnormal-progress_corrupt | `operations` | `undecidable:format_error` | `spec§4;spec§5.operations.setup_done;spec§7;spec§8;spec§12` | ✓ |

**仕様との照合**:

- **abnormal-operations_in_progress_missing_progress**: history に「Operations 進行中」記録あり、progress.md 欠損 → `OperationsBootstrapRule.isBootstrap=false`（history 存在のため）、validateArtifacts で missing_file を検出 → spec §5.3.2 / §7.0 の Operations setup_done 必須集合 → `undecidable:missing_file` で単値（bootstrap 例外には該当しない）
- **abnormal-progress_corrupt**: progress.md 存在するがパース不能 → spec §5.3.2 で `format_error` を検出 → `undecidable:format_error` で単値

## 検証 2: `spec_refs` の実在確認

全 7 ケースで参照される spec セクションが `phase-recovery-spec.md` に実在することを確認:

| spec 参照 | 実在確認 |
|----------|---------|
| `spec§4`（フェーズ判定仕様） | ✓ |
| `spec§5.operations.bootstrap` | ✓ §5.3.0 |
| `spec§5.operations.setup_done` | ✓ §5.3.1.1 |
| `spec§5.operations.deploy_done` | ✓ §5.3.1.2 |
| `spec§5.operations.release_done` | ✓ §5.3.1.3 |
| `spec§5.operations.completion_done` | ✓ §5.3.1.4 |
| `spec§6`（戻り値契約） | ✓ |
| `spec§7`（diagnostics / reason_code） | ✓（§7.0 に Operations 行追加） |
| `spec§8`（ユーザー確認ルール） | ✓ |
| `spec§12`（Operations 適用例） | ✓（Unit 004 追加セクション） |

参照トークン形式は全て `spec§9.3` の推奨形式（`spec§5.<phase>.<checkpoint>`）に準拠している。

## 検証 3: 初回ロード token 計測

**測定対象**: Operations Phase 初回ロード 5 ファイル（tiktoken `cl100k_base` 使用）

| ファイル | token 数 |
|---------|---------|
| `skills/aidlc/SKILL.md` | 4,960 |
| `skills/aidlc/steps/common/rules-core.md` | 1,885 |
| `skills/aidlc/steps/common/preflight.md` | 1,965 |
| `skills/aidlc/steps/common/session-continuity.md` | 585 |
| `skills/aidlc/steps/operations/index.md` | 5,999 |
| **TOTAL** | **15,394** |

**ベースライン比較**:

| 指標 | 値 |
|-----|---|
| v2.2.3 ベースライン（実測） | 17,827 tok |
| v2.3.0 Unit 004 初回ロード | 15,394 tok |
| 差分 | **-2,433 tok（-13.7%）** |
| 計画目標（≤17,827 tok） | ✓ 達成 |

**削減の内訳**（定性的）:

- `operations/index.md` 新設（+5,999 tok）
- 既存 4 ステップファイル（01-04）からの重複除去（`automation_mode` / `project.type` / `depth_level` / worktree フロー / AI レビュー分岐の集約）→ 差し引き -2,433 tok の純減
- 初回ロードは `index.md` 1 ファイルのみで完結（詳細ステップファイルは `judge()` 契約経由で必要時に遅延ロード）

## 検証 4: `check-bash-substitution.sh`

**実行コマンド**（CI と同じデフォルトスコープ `skills/aidlc/steps/`）:

```bash
bash bin/check-bash-substitution.sh
# → Bash substitution check completed: no violations, 33 files checked
# → exit 0
```

**結果**: CI デフォルトスコープで違反ゼロ（33 ファイル検査、終了コード 0）。

**確認**: `verify-operations-recovery.sh` は FIXTURE_CONTENT グローバル変数パターンで `$()` を完全回避している。

## 検証 5: `run-markdownlint.sh v2.3.0`

**実行コマンド**:

```bash
skills/aidlc/scripts/run-markdownlint.sh v2.3.0
```

**結果**: `markdownlint:success`（エラー 0 件）

**追加検証**: Unit 004 で変更した skill 側ファイル 9 件を個別に lint 実行し、全てエラーゼロを確認:

```bash
npx markdownlint-cli2 \
  skills/aidlc/steps/operations/index.md \
  skills/aidlc/steps/operations/01-setup.md \
  skills/aidlc/steps/operations/02-deploy.md \
  skills/aidlc/steps/operations/03-release.md \
  skills/aidlc/steps/operations/04-completion.md \
  skills/aidlc/steps/common/phase-recovery-spec.md \
  skills/aidlc/steps/common/compaction.md \
  skills/aidlc/steps/common/session-continuity.md \
  skills/aidlc/SKILL.md
# Summary: 0 error(s)
```

## 検証 6: bootstrap 分岐の動作確認

Unit 003 で確立した「Construction → Operations 遷移」が Unit 004 の `OperationsStepResolver` を経由する新ルートでも動作することを fixture o5（bootstrap-from-construction）で確認:

- **入力状態**: inception/progress.md 全完了、構築済み Unit 全完了、operations/progress.md 未存在、history/operations.md 未存在
- **PhaseResolver**: spec §4.1 末尾の bootstrap 特殊分岐により `phase=operations` + `construction_complete` info を返す
- **OperationsStepResolver**: `OperationsBootstrapRule.isBootstrap=true` → `step_id=operations.01-setup` を返す（`undecidable:missing_file` ではない）
- **判定の単値性**: ✓ 確認

## 検証 7: AI レビュー結果

### 計画レビュー（reviewing-construction-plan）

- 反復回数: 3 回
- 初回: 3 件（高 2 件 / 中 1 件）→ 修正後: 1 件（中 1 件）→ 最終: 0 件
- 修正内容: bootstrap 分岐の明示、5→4 checkpoint への変更（cleanup_done 廃止）、完了条件 2 項目追加、対象ファイル一覧の同期

### 設計レビュー（reviewing-construction-design）

- 反復回数: 3 回
- 初回: 2 件（高 1 件 / 中 1 件）→ 2回目: 2 件（中 2 件）→ 最終: 1 件（低 1 件）→ 0 件
- 修正内容: setup_done を「progress.md 存在」と再定義、PhaseResolver 判定順を 4→2 に修正、verify-operations-recovery.sh の case_id 一覧を fixture 表と完全一致、plan.md の同期

### コードレビュー（reviewing-construction-code）

- 反復回数: 2 回
- 初回: 3 件（中 3 件）→ 最終: 0 件
- 修正内容: phase-recovery-spec.md §1.4 / §9.3 の版番号 v1.1 → v1.2、§7.0 input_artifacts 解釈表に Operations 4 行追加（bootstrap 例外含む）、compaction.md line 25 を index.md + 契約テーブル経由に統一

## 結論

Unit 004（Operations Phase Index パイロット実装）の全 17 完了条件を実測ベースで満たしていることを確認した。初回ロードは **15,394 tok**（-2,433 tok、-13.7%）で v2.2.3 ベースライン以下を達成。2 段レゾルバ構造（`PhaseResolver` + `OperationsStepResolver`）と Materialized Binding パターンが Operations Phase にも適用され、Unit 001/002/003 との構造的一貫性が保たれている。

**Unit 005/006 への接続点**: Unit 004 完了時点で `phase-recovery-spec.md §5` 配下のすべての phase（Inception §5.1 / Construction §5.2 / Operations §5.3）が実値化された。Unit 005（Tier2 統合）は Unit 001-004 で確立したインデックス構造を前提とした追加施策を実装可能。Unit 006（計測・クローズ判断）は全 phase を一括検証可能。

**bootstrap 分岐の重要性**: Operations Phase は AI-DLC サイクルの最終フェーズで、Construction 完了直後に新規開始される。`OperationsBootstrapRule` による bootstrap 分岐により、`undecidable:missing_file` で blocking されることなく正規の遷移パスが確保された。これは Inception/Construction にはない Operations 固有の設計要素。
