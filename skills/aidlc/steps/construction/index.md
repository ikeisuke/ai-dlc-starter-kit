<!-- phase-index-schema: v1 -->
<!--
Materialized Binding 宣言:
  本インデックスファイルは `steps/common/phase-recovery-spec.md`（規範仕様）の Construction Phase 向け
  materialized binding である。判定規則の本文は spec 側にあり、本ファイルは具象パスと spec 参照
  トークン（`spec§N` / `spec§N.<phase>.<checkpoint>`）のみを保持する。
  Construction Phase は「Unit loop 構造」を持つため、Stage 1（Unit 特定）はアルゴリズム節として
  記述し、Stage 2（step 進行判定）は 4 checkpoint の表として記述する。
  binding_schema_version は spec_version と独立管理される（spec §1.4 参照）。
-->

# Construction Phase インデックス

Construction Phase の入口ファイル。以下4要素を集約する:

1. 全ステップの目次・概要
2. ステップ間分岐ロジック
3. 判定チェックポイント表（Stage 2 の 4 checkpoint）+ Stage 1 アルゴリズム節
4. ステップ読み込み契約（`step_id` → `detail_file` の解決テーブル）

AI エージェントは本ファイルを常時ロードし、詳細手順ファイル（`01-setup.md` 〜 `04-completion.md`）は「ステップ読み込み契約」に従って必要時のみロードする。

Construction Phase は Unit ごとに「セットアップ → 設計 → 実装 → 完了処理」を繰り返す Unit loop 構造を持つ。判定仕様は `phase-recovery-spec.md §5.2` に記載され、本 binding はその materialized binding として機能する。

---

## 1. 目次・概要

| step_id | タイトル | 目的 |
|---------|---------|------|
| `construction.01-setup` | セットアップ・Unit 選定 | プリフライト、Depth Level 確認、進捗状況確認、対象 Unit 決定、計画ファイル作成・承認、Unit ブランチ作成 |
| `construction.02-design` | Phase 1（設計） | ドメインモデル設計、論理設計、設計レビュー（`depth_level=minimal` ではスキップ可） |
| `construction.03-implementation` | Phase 2（実装） | コード生成、テスト生成、ビルド・テスト実行（Self-Healing ループ）、コードレビュー |
| `construction.04-completion` | Unit 完了処理 | 完了条件チェック、設計・実装整合性チェック、Unit 定義ファイル更新、履歴記録、squash、コミット、PR 作成・マージ、コンテキストリセット提示 |

各ステップの詳細手順は「4. ステップ読み込み契約」に示された `detail_file` を参照すること。

---

## 2. 分岐ロジック

Construction フェーズ内で発生する分岐を一元化する。各詳細ステップファイルは本セクションを参照し、分岐判定ロジック自体は重複記載しない。

### 2.1 Phase 構成

| Phase | 含まれる step_id | 遷移条件 |
|-------|-----------------|---------|
| Phase 1（設計） | `construction.02-design` | 計画承認後、`depth_level ≠ minimal` の場合に遷移 |
| Phase 2（実装） | `construction.03-implementation` | 設計承認後、または `depth_level=minimal` で Phase 1 スキップ時 |

**設計承認なしで Phase 2 に進むことは禁止**（`depth_level=minimal` での省略を除く）。

### 2.2 Unit ループと対象 Unit 決定

Unit 選定は `phase-recovery-spec.md §5.2.0`（Stage 1）の決定ツリーに従う。詳細は本ファイル §3.1（Stage 1 アルゴリズム節）を参照。

| 状況 | 動作 |
|------|------|
| 進行中Unitあり（1件） | そのUnitを継続 |
| 進行中Unitあり（2件以上） | `undecidable:conflict`（`multi_unit_in_progress`）、ユーザー確認必須 |
| 実行可能Unit 0個 + 未完了 Unit あり | `undecidable:dependency_block`、ユーザー確認必須 |
| 実行可能Unit 1個 | 自動選択 |
| 実行可能Unit 複数 + `semi_auto` | 番号順で最初を自動選択 |
| 実行可能Unit 複数 + `manual` | ユーザーに選択提示（`user_selection_required` diagnostic） |
| 全 Unit 完了 | `PhaseResolver` 側で `phaseProgressStatus[construction]=completed` として検出され Operations 遷移判定（`construction_complete` info diagnostic） |

実行可能条件: 状態「未着手」かつ依存Unit全て「完了」or「取り下げ」。

### 2.3 depth_level 分岐

| depth_level | 影響範囲 | 動作差分 |
|-------------|---------|---------|
| `minimal` | Phase 1（設計） | Phase 1 をスキップ可、設計レビューもスキップ。「設計省略（depth_level=minimal）」を履歴記録し、Phase 2 に直行 |
| `standard`（デフォルト） | - | 現行動作 |
| `comprehensive` | ドメインモデル / 論理設計 / テスト | ドメインイベント追加、シーケンス図・状態遷移図追加、統合テスト強化 |

詳細は `common/rules-reference.md` の「レベル別成果物要件」を参照。

### 2.4 automation_mode 分岐（ゲート判定）

| automation_mode | ゲート動作 |
|-----------------|----------|
| `manual` | 全承認ポイントでユーザー確認 |
| `semi_auto` | フォールバック条件非該当なら `auto_approved`、該当時は `fallback(reason_code)` |

本 Construction フェーズでのゲート発生箇所:

- 計画承認（`construction.01-setup` 完了時）
- 設計承認（`construction.02-design` 完了時、`depth_level ≠ minimal`）
- コードレビュー承認（`construction.03-implementation` ステップ4 完了時）
- 統合レビュー承認（`construction.03-implementation` ステップ6 完了時）
- 実装承認（`construction.04-completion` 開始時）

詳細・フォールバック条件テーブル・構造化シグナルは `common/rules-automation.md` の「セミオートゲート仕様」を参照。

### 2.5 エクスプレスモード分岐

`express_enabled=true` かつ全 Unit の適格性が `eligible` の場合に適用:

| depth_level | 動作 |
|-------------|------|
| `minimal` | Phase 1（設計）スキップ → Phase 2 のコード生成に直行 |
| `standard` / `comprehensive` | Phase 1 から通常実行 |

複数 Unit 時は通常の Unit 選定ルール（§2.2）を適用。全 Unit 完了後に Operations へ自動遷移。

### 2.6 Self-Healing ループ分岐（`construction.03-implementation`）

ビルド/テストエラー発生時、`max_retry` 回まで自動修正を試行する。エラー分類と具体的な試行手順は `steps/construction/03-implementation.md` のステップ6 参照。

| エラー分類 | 対応 |
|-----------|------|
| `non_recoverable` | 即時フォールバック（ユーザー判断） |
| `transient` | 1 回再試行 → 再失敗時フォールバック |
| `recoverable` | Self-Healing ループ対象（最大 `max_retry` 回） |

### 2.7 gh_status 分岐

プリフライトで取得済みの `gh_status` を各ステップが参照する:

| gh_status | 対象機能の動作 |
|-----------|--------------|
| `available` | Issue ステータス更新・Unit ブランチ作成・ドラフト PR 作成をすべて実行 |
| `available` 以外 | 関連機能をスキップし、警告表示して続行 |

### 2.8 AI レビュー分岐

各承認ポイントで AI レビューを実施する。**ルーティング判定（スキル名・focus・処理パス選択）は `steps/common/review-routing.md` 参照**、**反復・指摘対応・完了処理の手順は `steps/common/review-flow.md` 参照**。`review_mode=disabled` 時は `review-routing.md` のパス 3（ユーザーレビュー）へ直行。

対象タイミング（本フェーズ）:

- 計画承認前
- 設計レビュー前
- コード生成後
- 統合とレビュー（ビルド・テスト完了後）

---

## 3. 判定チェックポイント表（`phase-recovery-spec.md §5.2` の materialized binding）

本テーブルは `phase-recovery-spec.md §11.1`（Construction 適用例）の materialized binding である。判定規則の本文は spec §4（PhaseResolver）／ §5.2（Construction Step 判定仕様）／ §6（戻り値契約）／ §8（ユーザー確認必須性ルール）に記載されており、本テーブルは spec 参照トークンで該当セクションにリンクする。**本テーブルの列構造は Unit 001 から不変**（`binding_schema_version=v1`）。

Construction Phase は「Unit loop 構造」のため、Stage 1（Unit 特定）は本表の外のアルゴリズム節（§3.1）に記述し、Stage 2（step 進行判定）のみを以下の 4 checkpoint として表形式で記述する。

| checkpoint_id | input_artifacts | priority_order | undecidable_return | user_confirmation_required |
|---------------|-----------------|----------------|--------------------|----------------------------|
| `construction.setup_done` | `.aidlc/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md`, `.aidlc/cycles/{{CYCLE}}/history/construction_unit{NN}.md` | `spec§5.construction.setup_done` | `spec§6` | `spec§8` |
| `construction.design_done` | `.aidlc/cycles/{{CYCLE}}/design-artifacts/domain-models/unit_{NNN}_{stem}_domain_model.md`, `.aidlc/cycles/{{CYCLE}}/design-artifacts/logical-designs/unit_{NNN}_{stem}_logical_design.md`, `.aidlc/cycles/{{CYCLE}}/history/construction_unit{NN}.md` | `spec§5.construction.design_done` | `spec§6` | `spec§8` |
| `construction.implementation_done` | `.aidlc/cycles/{{CYCLE}}/history/construction_unit{NN}.md` | `spec§5.construction.implementation_done` | `spec§6` | `spec§8` |
| `construction.completion_done` | `.aidlc/cycles/{{CYCLE}}/story-artifacts/units/{NNN}-{slug}.md`, `.aidlc/cycles/{{CYCLE}}/history/construction_unit{NN}.md` | `spec§5.construction.completion_done` | `spec§6` | `spec§8` |

**列の意味**（spec §9.2 参照）:

- `priority_order`: checkpoint の step 判定規則への参照（`spec§5.<phase>.<checkpoint_suffix>` 推奨形式）
- `undecidable_return`: 戻り値インターフェース契約への参照（`spec§6`）。全 checkpoint 共通
- `user_confirmation_required`: ユーザー確認必須性ルールへの参照（`spec§8`）。全 checkpoint 共通

**canonical path 正規化**: `{NNN}` は 3 桁ゼロ埋め、`{NN}` は 2 桁ゼロ埋め（`{NNN}` の下 2 桁）、`{slug}` は Unit 定義ファイル名の slug 部（ケバブケース）、`{stem}` は `{slug}` の `-` を `_` に置換したもの（アンダースコア）。詳細は `phase-recovery-spec.md §5.2.2` を参照。

### 3.1 Stage 1 アルゴリズム節（Unit 選定）

Unit 選定は `phase-recovery-spec.md §5.2.0` の `UnitSelectionRule` に従う。呼び出し層は以下の手順で Unit 選定を行う:

```text
inputs:
  units = scan(story-artifacts/units/*.md) → List<UnitReference>
  automation_mode = artifacts_state.automation_mode

precondition (PhaseResolver が保証):
  phaseProgressStatus[construction] = incomplete    # = |pending_units| > 0

sets:
  in_progress_units = { u | u.status = 進行中 }
  executable_units  = { u | u.status = 未着手 ∧ u.dependencies ⊆ {完了, 取り下げ} }

decision:
  if |in_progress_units| ≥ 2  → undecidable:conflict (multi_unit_in_progress)
  if |in_progress_units| = 1  → UnitSelected(in_progress_units[0]) → Stage 2
  if |executable_units| = 0   → undecidable:dependency_block
  if |executable_units| = 1   → UnitSelected(executable_units[0]) → Stage 2
  if |executable_units| ≥ 2 ∧ automation_mode=semi_auto  → UnitSelected(min_by_number) → Stage 2
  if |executable_units| ≥ 2 ∧ automation_mode=manual     → step=None + user_selection_required diagnostic
```

判定規則の本文は `spec§5.construction.unit_selection` を参照（`phase-recovery-spec.md §5.2.0`）。

### 3.2 論理インターフェース契約（spec への binding）

判定ロジックの公開 API は `RecoveryJudgmentService.judge()`（spec §6）であり、呼び出し層（`compaction.md` / `session-continuity.md`）は必ず本 API を入口とする。Construction 内部の step 判定は `ConstructionStepResolver.determine_current_step()`（spec §5.2、非公開下位契約）として提供される。

```text
operation: judge                           # 唯一の公開 API (spec §6)
signature: judge(artifacts_state: ArtifactsState) -> PhaseRecoveryJudgment
semantics:
  - PhaseResolver.resolvePhase() が先に評価される (spec §4)
  - 結果が Construction の場合のみ ConstructionStepResolver.determine_current_step() (spec §5.2) が呼ばれる
  - ConstructionStepResolver は以下の 2 段構造で評価する:
    - Stage 1: UnitSelectionRule.selectUnit() で現在進行中の Unit を特定（§5.2.0）
    - Stage 2: 特定された Unit の 4 checkpoint を順に評価し、未達成の最初の checkpoint に対応する step_id を返す（§5.2.1）
  - 戻り値は result + diagnostics[] の 2 フィールド分離形式 (spec §6)
    - blocking (undecidable:conflict / undecidable:dependency_block) は自動継続禁止
    - info (user_selection_required / construction_complete) は diagnostics[] に追加、result は継続可

責務境界:
  - phase 遷移は PhaseResolver の責務 (spec §4)。ConstructionStepResolver は phase 遷移を返さない
  - Construction 完了判定（全 Unit 完了 → Operations 遷移）は PhaseResolver 側で
    phaseProgressStatus[construction]=completed を検出して吸収する
  - ConstructionStepResolver は事前条件として phaseProgressStatus[construction]=incomplete が
    保証されており、AllUnitsCompleted ケースは発生しない
```

---

## 4. ステップ読み込み契約

AI エージェントはこのテーブルを参照して詳細ファイルをロードする。**本テーブルの列構造・行構造は予算都合でも変更不可**。

| step_id | detail_file | entry_condition | exit_condition | load_timing |
|---------|-------------|-----------------|----------------|-------------|
| `construction.01-setup` | `steps/construction/01-setup.md` | フェーズ開始時（`step_id` 未指定時の既定開始点）または新規 Unit 選定時 | 対象 Unit 決定＋計画ファイル作成＋承認完了 | `on_demand` |
| `construction.02-design` | `steps/construction/02-design.md` | `construction.01-setup` 承認後、`depth_level ≠ minimal` | 設計承認（`auto_approved` または ユーザー承認） | `on_demand` |
| `construction.03-implementation` | `steps/construction/03-implementation.md` | `construction.02-design` 承認後、または `depth_level=minimal` で Phase 1 スキップ | コード生成完了＋テスト成功＋統合レビュー承認 | `on_demand` |
| `construction.04-completion` | `steps/construction/04-completion.md` | `construction.03-implementation` 承認後 | 完了条件チェック＋Unit 定義更新＋履歴記録＋squash＋コミット＋PR マージ完了 | `on_demand` |

### 4.1 既定ルート

- `step_id` が明示指定されている場合: 上記テーブルから解決
- `step_id` 未指定の場合（**新規開始時のみ**）: **`construction.01-setup` を既定開始点**として契約テーブルから解決
- **コンパクション復帰時（再開文脈）**: `RecoveryJudgmentService.judge(ArtifactsState)`（spec §6）を呼び、戻り値 `PhaseRecoveryJudgment.step.result`（`StepId`）から `step_id` を取得する。内部的には `PhaseResolver`（spec §4）→ `ConstructionStepResolver`（spec §5.2）が順に評価される。blocking（`undecidable:conflict` / `undecidable:dependency_block`）時はユーザー確認フローへ、warning（`legacy_structure`）/ info（`user_selection_required` / `construction_complete`）時は警告/情報表示後に通常判定を継続する（詳細は `steps/common/compaction.md` の「復帰フローの確認手順」および `phase-recovery-spec.md` §6/§7/§8 参照）

### 4.2 SKILL.md 側のルーティング責務

SKILL.md の共通初期化フローは本インデックスファイルのみを常時ロードし、詳細ファイルは上記契約経由で必要時ロードする。**SKILL.md は契約テーブルを参照する薄いルーティング責務のみを持ち、詳細ステップの読み込み条件ロジックを直接持たない**。

---

## 5. 汎用構造仕様（Unit 001 / 002 から継承）

本インデックスファイルの章構成（1. 目次 / 2. 分岐ロジック / 3. 判定チェックポイント表 + Stage 1 アルゴリズム節 / 4. ステップ読み込み契約）は、Unit 001（Inception）で確立した共通構造を流用している。フェーズ固有要素（ステップ名、分岐条件、checkpoint、Unit loop 構造）のみを Construction 向けに差し替えた。

**共通要素（フェーズ非依存）**:

- 章立て: 目次 / 分岐ロジック / 判定チェックポイント表 / ステップ読み込み契約
- `StepLoadingContract` 列スキーマ: `step_id` / `detail_file` / `entry_condition` / `exit_condition` / `load_timing`
- `RecoveryCheckpoint` 列スキーマ: `checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`
- Materialized Binding 宣言と `<!-- phase-index-schema: v1 -->` スキーマバージョンコメント（`spec_version` と独立管理、詳細は `phase-recovery-spec.md` §1.4 参照）

**Construction 固有要素**:

- 各ステップの `step_id` 命名規約: `construction.{step-slug}`
- Unit loop 構造: Stage 1（Unit 特定）+ Stage 2（step 進行判定）の 2 段構造
- 分岐ロジックセクションの具体的な条件（Phase 1/Phase 2 境界、Self-Healing ループ、`automation_mode` 分岐等）
- チェックポイントの具体的な `checkpoint_id`: `setup_done` / `design_done` / `implementation_done` / `completion_done`（Stage 1 の `unit_selection` はアルゴリズム節に分離）
- Inception（Unit 001 パイロット）は 5 checkpoint、Construction（本 Unit 003）は Stage 2 が 4 checkpoint。これは Construction の Unit loop 構造に固有の減少であり、列スキーマは不変
