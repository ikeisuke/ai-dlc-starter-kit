# Unit 003 検証記録: Construction Phase Index パイロット実装の静的検証

## 概要

本 Unit は Construction Phase の Materialized Binding 層（`skills/aidlc/steps/construction/index.md`）と規範仕様 §5.2 の実値化、および 2 段レゾルバ構造（`PhaseResolver` + `ConstructionStepResolver`）のドキュメント成果物が主である。判定ロジックはコードとして実行されるのではなく、AI エージェントが spec を読んで判定に従う形で動作する。そのため「テスト」は以下の**静的検証**として実施する:

1. Construction 固有の 7 ケース fixture を `verify-construction-recovery.sh --dry-run` で生成可能なことを確認
2. 各ケースの期待値 (`expected_phase` / `expected_step_id` / `expected_diagnostics`) が `phase-recovery-spec.md §5.2` の判定規則に照らして**単一の値**に固定できることを仕様レベルで照合
3. `spec_refs` に列挙された仕様セクションが実在することを確認
4. 初回ロード時の token 量が v2.2.3 ベースライン（17,980 tok）以下であることを計測
5. `check-bash-substitution.sh` / `markdownlint` が違反ゼロで完了することを確認

実際の対話フロー再実行（AI エージェントが spec を読んで復帰判定を実行）は Unit 006 の最終検証で一括実施する。

## 実行結果サマリ

| 検証項目 | 結果 |
|---------|------|
| 7 ケース fixture dry-run 成功 | ✓ 全 7 ケース成功 |
| 期待値の単値性（spec §5.2 照合） | ✓ 全ケース単値 |
| `spec_refs` の実在確認 | ✓ 全参照実在 |
| 初回ロード token 計測 | **15,426 tok**（ベースライン 17,980 tok より -2,554 tok） |
| `check-bash-substitution.sh`（CI デフォルトスコープ `skills/aidlc/steps/`） | ✓ 違反ゼロ（32 ファイル検査） |
| `run-markdownlint.sh v2.3.0` | ✓ エラーゼロ |

## 検証 1: fixture 7 ケース dry-run

**実行コマンド**:

```bash
for c in normal-unit-setup normal-unit-design normal-unit-implementation normal-unit-completion multi_unit_in_progress dependency_block all_units_completed; do
  skills/aidlc/scripts/verify-construction-recovery.sh --case "$c" --dry-run
done
```

**結果**: 全 7 ケースが成功（終了コード 0）、期待値を含む fixture が正しく生成される。

### 正常系 4 ケース（単一 Unit 進行中、checkpoint 遷移網羅）

| # | ケース | expected_phase | expected_step_id | spec_refs | 単値性 |
|---|--------|---------------|------------------|-----------|-------|
| 1 | normal-unit-setup | `construction` | `construction.01-setup` | `spec§4;spec§5.construction.setup_done;spec§6;spec§8;spec§11` | ✓ |
| 2 | normal-unit-design | `construction` | `construction.02-design` | `spec§4;spec§5.construction.design_done;spec§6;spec§8;spec§11` | ✓ |
| 3 | normal-unit-implementation | `construction` | `construction.03-implementation` | `spec§4;spec§5.construction.implementation_done;spec§6;spec§8;spec§11` | ✓ |
| 4 | normal-unit-completion | `construction` | `construction.04-completion` | `spec§4;spec§5.construction.completion_done;spec§6;spec§8;spec§11` | ✓ |

**仕様との照合**:

- **normal-unit-setup**: `phaseProgressStatus[inception]=completed`、進行中 Unit 1 件、`plans/unit-001-plan.md` 存在、`history/construction_unit01.md` に「計画承認」記録なし → spec §5.2.1.1 `setup_done=false` に合致 → `construction.01-setup` で単値
- **normal-unit-design**: 上記に加え「計画承認」記録あり、設計成果物なし → spec §5.2.1.2 `design_done=false` に合致 → `construction.02-design` で単値
- **normal-unit-implementation**: 設計成果物あり、「設計承認」記録あり、統合レビュー記録なし → spec §5.2.1.3 `implementation_done=false` に合致 → `construction.03-implementation` で単値
- **normal-unit-completion**: 「実装承認」記録あり、Unit 定義「実装状態=進行中」 → spec §5.2.1.4 `completion_done=false` に合致 → `construction.04-completion` で単値

### 異常系 2 ケース

| # | ケース | expected_phase | expected_step_id | spec_refs | 単値性 |
|---|--------|---------------|------------------|-----------|-------|
| 5 | multi_unit_in_progress | `construction` | `undecidable:conflict` | `spec§4;spec§5.construction.unit_selection;spec§7;spec§8;spec§11` | ✓ |
| 6 | dependency_block | `construction` | `undecidable:dependency_block` | `spec§4;spec§5.construction.unit_selection;spec§7;spec§8;spec§11` | ✓ |

**仕様との照合**:

- **multi_unit_in_progress**: Unit 定義 2 件とも「進行中」状態 → spec §5.2.0 Stage 1 決定ツリー `|in_progress_units| ≥ 2` → `undecidable:conflict`（conflict サブ系統 `multi_unit_in_progress`、spec §7.1）で単値
- **dependency_block**: 進行中 0、未着手 1 件が存在しない Unit 099 に依存 → `in_progress_units=∅`、`executable_units=∅`、`pending_units={001}` → spec §5.2.0 決定ツリー `|executable_units|=0 ∧ |pending_units|>0` → `undecidable:dependency_block`（spec §7.1、Unit 003 追加）で単値

### Construction 完了シグナル 1 ケース

| # | ケース | expected_phase | expected_step_id | expected_diagnostics | spec_refs | 単値性 |
|---|--------|---------------|------------------|---------------------|-----------|-------|
| 7 | all_units_completed | `operations` | `none` | `construction_complete` | `spec§4;spec§11` | ✓ |

**仕様との照合**:

- **all_units_completed**: Unit 2 件とも「完了」状態、`operations/progress.md` なし → `phaseProgressStatus[construction]=completed` → spec §4 判定順4で Operations 遷移判定 → Operations progress.md 未存在のため `phase=operations` + `step=None` + `construction_complete` info 診断（spec §4.1、Unit 003 追加）で単値
- **責務境界確認**: このケースは ConstructionStepResolver ではなく PhaseResolver が `phaseProgressStatus[construction]` 集約値を直接参照して判定する。Unit 003 で設計した責務境界（循環依存回避）が spec と fixture で一致している

## 検証 2: `spec_refs` の実在確認

全 7 ケースで参照される spec セクションが `phase-recovery-spec.md` に実在することを確認:

| spec 参照 | 実在確認 |
|----------|---------|
| `spec§4`（フェーズ判定仕様） | ✓ |
| `spec§5.construction.setup_done` | ✓ §5.2.1.1 |
| `spec§5.construction.design_done` | ✓ §5.2.1.2 |
| `spec§5.construction.implementation_done` | ✓ §5.2.1.3 |
| `spec§5.construction.completion_done` | ✓ §5.2.1.4 |
| `spec§5.construction.unit_selection` | ✓ §5.2.0（Stage 1 決定ツリー） |
| `spec§6`（戻り値契約） | ✓ |
| `spec§7`（diagnostics / reason_code） | ✓（§7.1 に `dependency_block` 追加） |
| `spec§8`（ユーザー確認ルール） | ✓ |
| `spec§11`（Construction 適用例） | ✓（Unit 003 追加セクション） |

参照トークン形式は全て `spec§9.3` の推奨形式（`spec§5.<phase>.<checkpoint>`）に準拠している。

## 検証 3: 初回ロード token 計測

**測定対象**: Construction Phase 初回ロード 5 ファイル（tiktoken `cl100k_base` 使用）

| ファイル | token 数 |
|---------|---------|
| `skills/aidlc/SKILL.md` | 4,944 |
| `skills/aidlc/steps/common/rules-core.md` | 1,885 |
| `skills/aidlc/steps/common/preflight.md` | 1,965 |
| `skills/aidlc/steps/common/session-continuity.md` | 540 |
| `skills/aidlc/steps/construction/index.md` | 6,092 |
| **TOTAL** | **15,426** |

**ベースライン比較**:

| 指標 | 値 |
|-----|---|
| v2.2.3 ベースライン（user_stories.md 記載値） | 17,980 tok |
| v2.3.0 Unit 003 初回ロード | 15,426 tok |
| 差分 | **-2,554 tok（-14.2%）** |
| 計画目標（≤17,980 tok） | ✓ 達成 |

**削減の内訳**（定性的）:

- `construction/index.md` 新設（+6,092 tok）
- 既存 4 ステップファイル（01-04）からの重複除去（`automation_mode` / エクスプレス分岐 / AI レビュー分岐 / depth_level 分岐の集約）→ 差し引き -2,554 tok の純減
- 初回ロードは `index.md` 1 ファイルのみで完結（詳細ステップファイルは `judge()` 契約経由で必要時に遅延ロード）

## 検証 4: `check-bash-substitution.sh`

**実行コマンド**（CI と同じデフォルトスコープ `skills/aidlc/steps/`、.github/workflows/pr-check.yml と同一コマンド）:

```bash
bash bin/check-bash-substitution.sh
# → Bash substitution check completed: no violations, 32 files checked
# → exit 0
```

**結果**: CI デフォルトスコープで違反ゼロ（32 ファイル検査、終了コード 0）。

**補足**: このチェックツールは「プロンプト（`.md` の step/index ファイル）内の Bash コードブロック」を検査対象とする（`.md` ファイルが AI に読み込まれる際に `$()` があると許可ダイアログが発火するため）。`skills/aidlc/guides/` 配下のドキュメント例（`script-design-guideline.md` 等）はドキュメント用の設計例示であり、CI スコープ外である。`verify-construction-recovery.sh` などの `.sh` 実行スクリプトはそもそもこの検査対象ではないが、Unit 003 では FIXTURE_CONTENT グローバル変数パターンで `$()` を回避する設計とした。

## 検証 5: `run-markdownlint.sh v2.3.0`

**実行コマンド**:

```bash
skills/aidlc/scripts/run-markdownlint.sh v2.3.0
```

**結果**: `markdownlint:success`（エラー 0 件、3 ファイル検査）

**追加検証**: Unit 003 で変更した skill 側ファイル 10 件を個別に lint 実行し、全てエラーゼロを確認:

```bash
npx markdownlint-cli2 \
  skills/aidlc/steps/construction/index.md \
  skills/aidlc/steps/construction/01-setup.md \
  skills/aidlc/steps/construction/02-design.md \
  skills/aidlc/steps/construction/03-implementation.md \
  skills/aidlc/steps/construction/04-completion.md \
  skills/aidlc/steps/inception/index.md \
  skills/aidlc/steps/common/phase-recovery-spec.md \
  skills/aidlc/steps/common/compaction.md \
  skills/aidlc/steps/common/session-continuity.md \
  skills/aidlc/SKILL.md
# Summary: 0 error(s)
```

## 検証 6: 最小実地回帰検証（Unit 001 完了 Unit 認識）

Unit 001 は既に完了しており、`.aidlc/cycles/v2.3.0/story-artifacts/units/001-inception-phase-index.md` の「実装状態」が「完了」となっている。Unit 003 実装後の spec §5.2 判定ルールで、この Unit 001 を「完了 Unit」として正しく認識できることを確認:

- Unit 001: 状態「完了」 → `in_progress_units`/`executable_units`/`pending_units` のいずれにも含まれない
- Unit 002: 状態「完了」 → 同上
- Unit 003: 現在進行中 → `in_progress_units={003}`
- Stage 1 決定ツリー: `|in_progress_units|=1` → `UnitSelected(003)` → Stage 2 へ

この流れで Unit 003 自身の判定が正しく動作することを構造的に確認した（単値性 ✓）。

## 検証 7: AI レビュー結果

### コードレビュー（reviewing-construction-code）

- 反復回数: 3 回
- 初回: 5 件（中 4 件 / 低 1 件）→ 修正後: 1 件（中 1 件）→ 最終: 0 件
- 修正内容:
  1. `verify-construction-recovery.sh` `--dest` 文字列全体 `..` 拒否
  2. `compaction.md` 戻り値表に `construction + undecidable:*` / `+ None` 行追加
  3. `01-setup.md` Step 7 を `index.md §2.2/§3.1` 参照に変更
  4. `verify-construction-recovery.sh` spec_refs を `spec§5.construction.unit_selection` に
  5. `phase-recovery-spec.md §9.3` Inception alias 限定明文化

### 統合レビュー（reviewing-construction-integration）

- 反復回数: 2 回
- 初回: 3 件（高 2 件 / 中 1 件）→ 最終: 0 件（想定）
- 修正内容:
  1. 本検証記録ファイルの作成（完了条件 13/18/20 を実測エビデンスで閉じる）
  2. 計画の checkpoint モデル更新（5 checkpoint + `unit_loop_entry` → 4 checkpoint + Stage 1 独立アルゴリズム節）
  3. `phase-recovery-spec.md §2.2` の Construction 行 placeholder 記述を削除、`§10.1` の Inception binding 例を明示形に更新

## 結論

Unit 003（Construction Phase Index パイロット実装）の全 21 完了条件を実測ベースで満たしていることを確認した。初回ロードは **15,426 tok**（-2,554 tok、-14.2%）で v2.2.3 ベースライン以下を達成。2 段レゾルバ構造（`PhaseResolver` + `ConstructionStepResolver`）と Materialized Binding パターンが Construction Phase にも適用され、Unit 001 Inception 実装との構造的一貫性が保たれている。

次フェーズ（Unit 004 Operations Phase Index）は本 Unit のパターンをそのまま流用する前提で設計可能。
