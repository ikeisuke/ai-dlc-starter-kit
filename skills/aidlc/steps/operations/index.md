<!-- phase-index-schema: v1 -->
<!--
Materialized Binding 宣言:
  本インデックスファイルは `steps/common/phase-recovery-spec.md`（規範仕様）の Operations Phase 向け
  materialized binding である。判定規則の本文は spec 側にあり、本ファイルは具象パスと spec 参照
  トークン（`spec§N` / `spec§N.<phase>.<checkpoint>`）のみを保持する。
  Operations Phase は Inception と同じく直線的進行（Unit loop なし）のため、Inception 同型の
  単純な checkpoint 評価のみを行う。ただし bootstrap 分岐（Construction 完了直後の Operations
  新規開始）が Operations 固有要素として §3 冒頭に明記される。
  binding_schema_version は spec_version と独立管理される（spec §1.4 参照）。
-->

# Operations Phase インデックス

Operations Phase の入口ファイル。以下4要素を集約する:

1. 全ステップの目次・概要
2. ステップ間分岐ロジック
3. 判定チェックポイント表（4 checkpoint）+ bootstrap 分岐
4. ステップ読み込み契約（`step_id` → `detail_file` の解決テーブル）

AI エージェントは本ファイルを常時ロードし、詳細手順ファイル（`01-setup.md` 〜 `04-completion.md`）は「ステップ読み込み契約」に従って必要時のみロードする。

Operations Phase は Inception と同じく直線的進行（Unit loop なし）であり、`operations/progress.md` ベースで順次進行する。判定仕様は `phase-recovery-spec.md §5.3` に記載され、本 binding はその materialized binding として機能する。Construction 完了直後の Operations 新規開始は **bootstrap 分岐**として `OperationsBootstrapRule` で正常系として扱う。

---

## 1. 目次・概要

| step_id | タイトル | 目的 |
|---------|---------|------|
| `operations.01-setup` | 初期セットアップ | プリフライト、Depth Level 確認、`operations/progress.md` 新規作成、運用引き継ぎ情報読み込み、全 Unit 完了確認、Construction 引き継ぎタスク確認 |
| `operations.02-deploy` | デプロイ実作業 | ステップ1（変更確認）、ステップ2-5（デプロイ準備一式: デプロイ準備 / CI/CD / 監視 / 配布）、ステップ6（バックログ整理と運用計画）、ステップ7.1-7.7（リリース準備の PR 準備完了まで）。ステップ7 の自動化可能な工程は `scripts/operations-release.sh` を呼び出す |
| `operations.03-release` | リリース完了基準確認 | 実行ルール確認、PR Ready 化、コミット漏れ確認、リモート同期、main との差分チェック、PR マージ前レビュー |
| `operations.04-completion` | PR マージ後手順・次サイクル準備 | バックトラック対応、PR マージ後手順（mainブランチ移動、最新取得、バージョンタグ付け、ブランチ削除、worktree フロー）、次サイクル開始の準備 |

各ステップの詳細手順は「4. ステップ読み込み契約」に示された `detail_file` を参照すること。

---

## 2. 分岐ロジック

Operations フェーズ内で発生する分岐を一元化する。各詳細ステップファイルは本セクションを参照し、分岐判定ロジック自体は重複記載しない。

### 2.1 ステップ進行（直線構造）

Operations Phase は Inception と同じく Unit loop を持たない直線的進行である:

```text
operations.01-setup → operations.02-deploy → operations.03-release → operations.04-completion
```

各 step_id 間の遷移条件は `phase-recovery-spec.md §5.3` の checkpoint 達成条件に従う。

### 2.2 Construction → Operations 遷移（bootstrap 分岐）

Construction Phase 完了直後の Operations 新規開始は **bootstrap 分岐**として正常系扱いする:

| 状況 | 動作 |
|------|------|
| `phaseProgressStatus[construction]=completed` ∧ `operations/progress.md` 未存在 ∧ `history/operations.md` 未存在 | bootstrap 分岐: `operations.01-setup` を返す（`construction_complete` info diagnostic 付き）。`undecidable:missing_file` ではない |
| `operations/progress.md` 存在 | 通常の checkpoint 評価（§3 参照） |
| `history/operations.md` に Operations 進行中マーカーあり ∧ `operations/progress.md` 欠損 | `undecidable:missing_file`（異常系、ユーザー確認必須） |

判定規則の本文は `spec§5.operations.bootstrap`（`phase-recovery-spec.md §5.3.0`）を参照。

### 2.3 「変更なし」スキップ（ステップ1の分岐）

`operations.02-deploy` 内のステップ1（変更確認）で「いいえ（変更なし）」を選択した場合、ステップ2-5 を一括スキップしてステップ6 に進む。`automation_mode=semi_auto` の場合は自動的に「いいえ」を選択する。詳細は `steps/operations/02-deploy.md` のステップ1 参照。

### 2.4 `project.type` 依存スキップ（ステップ5の分岐）

`operations.02-deploy` 内のステップ5（配布）は `.aidlc/config.toml` の `project.type` により自動スキップされる:

| `project.type` | ステップ5 動作 |
|---------------|--------------|
| `web` / `backend` / `general` / 未設定 | スキップ |
| `cli` / `desktop` / `ios` / `android` | 実行 |

詳細は `steps/operations/02-deploy.md` のステップ5 参照。

### 2.5 depth_level 分岐

| depth_level | 影響範囲 | 動作差分 |
|-------------|---------|---------|
| `comprehensive` | リリース準備（ステップ7） | ロールバック手順を詳細化（手順書作成、ロールバック判定基準の明記） |
| `standard`（デフォルト） | - | 現行動作 |
| `minimal` | - | 現行動作（変更なし） |

詳細は `common/rules-reference.md` の「レベル別成果物要件」を参照。

### 2.6 automation_mode 分岐（ゲート判定・インタラクション種別）

| automation_mode | ゲート動作 |
|-----------------|----------|
| `manual` | 全承認ポイントでユーザー確認 |
| `semi_auto` | フォールバック条件非該当なら `auto_approved`、該当時は `fallback(reason_code)` |

本 Operations フェーズでのインタラクションポイント:

| ステップ | インタラクション種別 | manual | semi_auto |
|---------|-------------------|--------|-----------|
| ステップ1（変更確認）の選択 | ゲート承認 | ユーザー確認 | auto_approved（§2.3） |
| 各対話形式ステップ（2/3/4/5/6）計画承認 | ゲート承認 | ユーザー確認 | auto_approved |
| リリース準備計画承認（ステップ7開始時） | ゲート承認 | ユーザー確認 | auto_approved |
| PR Ready 化承認 | ゲート承認 | ユーザー確認 | auto_approved |
| PRマージ実行（ステップ7.13） | ユーザー選択 | ユーザー確認 | ユーザー確認 |

**注記**: 「ユーザー選択」は SKILL.md「AskUserQuestion使用ルール」に定義されたインタラクション種別であり、`automation_mode` に関わらず（`full_auto` を含む全モードで）常にユーザー確認が必要。PRマージは破壊的・不可逆操作であるためこの分類に該当する。上記マトリクスは `manual` / `semi_auto` を列挙しているが、PRマージ実行確認は全 `automation_mode` でユーザー確認必須。詳細手順は `operations-release.md` §7.13 を参照。

詳細・フォールバック条件テーブル・構造化シグナルは `common/rules-automation.md` の「セミオートゲート仕様」を参照。

### 2.7 worktree フロー分岐（PR マージ後）

`operations.04-completion` 内の PR マージ後手順は、worktree 環境かどうかで分岐する:

| 環境 | 動作 |
|------|------|
| 通常環境 | `git checkout main` → `git pull` → タグ付け → ブランチ削除 |
| worktree 環境 | `post-merge-cleanup.sh` を dry-run → 本実行（main pull、fetch、detached HEAD 切り替え、ブランチ削除をスクリプトが代行）→ タグ付けのみ手動 |

詳細は `steps/operations/04-completion.md` の「PR マージ後の手順【重要】」参照。

### 2.8 gh_status 分岐

プリフライトで取得済みの `gh_status` を各ステップが参照する:

| gh_status | 対象機能の動作 |
|-----------|--------------|
| `available` | Issue クローズ・PR 操作・タグ push・GitHub Release 作成をすべて実行 |
| `available` 以外 | 関連機能をスキップし、警告表示して続行 |

### 2.9 AI レビュー分岐

各承認ポイントで AI レビューを実施する。**ルーティング判定（スキル名・focus・処理パス選択）は `steps/common/review-routing.md` 参照**、**反復・指摘対応・完了処理の手順は `steps/common/review-flow.md` 参照**。`review_mode=disabled` 時は `review-routing.md` のパス 3（ユーザーレビュー）へ直行。

対象タイミング（本フェーズ）:

- デプロイ計画承認前
- 運用ドキュメント承認前

---

## 3. 判定チェックポイント表（`phase-recovery-spec.md §5.3` の materialized binding）

本テーブルは `phase-recovery-spec.md §12`（Operations 適用例）の materialized binding である。判定規則の本文は spec §4（PhaseResolver）／ §5.3（Operations Step 判定仕様）／ §6（戻り値契約）／ §8（ユーザー確認必須性ルール）に記載されており、本テーブルは spec 参照トークンで該当セクションにリンクする。**本テーブルの列構造は Unit 001 から不変**（`binding_schema_version=v1`）。

**bootstrap 分岐**: `phaseProgressStatus[construction]=completed ∧ operations/progress.md 未存在 ∧ history/operations.md 未存在` の場合は **Operations 新規開始の正常状態**として `operations.01-setup` を返す。`undecidable:missing_file` には**ならない**。判定規則の本文は `spec§5.operations.bootstrap`（`phase-recovery-spec.md §5.3.0`）を参照。

Operations Phase は Inception と同じく直線的進行のため、4 checkpoint × 4 step_id × 4 detail_file の 1:1 対応構造を持つ:

| checkpoint_id | input_artifacts | priority_order | undecidable_return | user_confirmation_required |
|---------------|-----------------|----------------|--------------------|----------------------------|
| `operations.setup_done` | `.aidlc/cycles/{{CYCLE}}/operations/progress.md` | `spec§5.operations.setup_done` | `spec§6` | `spec§8` |
| `operations.deploy_done` | `.aidlc/cycles/{{CYCLE}}/operations/progress.md`, `.aidlc/cycles/{{CYCLE}}/operations/deployment_checklist.md`, `.aidlc/cycles/{{CYCLE}}/operations/cicd_setup.md`, `.aidlc/cycles/{{CYCLE}}/operations/monitoring_strategy.md`, `.aidlc/cycles/{{CYCLE}}/operations/post_release_operations.md` | `spec§5.operations.deploy_done` | `spec§6` | `spec§8` |
| `operations.release_done` | `.aidlc/cycles/{{CYCLE}}/history/operations.md` | `spec§5.operations.release_done` | `spec§6` | `spec§8` |
| `operations.completion_done` | `.aidlc/cycles/{{CYCLE}}/history/operations.md` | `spec§5.operations.completion_done` | `spec§6` | `spec§8` |

**列の意味**（spec §9.2 参照）:

- `priority_order`: checkpoint の step 判定規則への参照（`spec§5.<phase>.<checkpoint_suffix>` 推奨形式）
- `undecidable_return`: 戻り値インターフェース契約への参照（`spec§6`）。全 checkpoint 共通
- `user_confirmation_required`: ユーザー確認必須性ルールへの参照（`spec§8`）。全 checkpoint 共通

**判定条件**（詳細は spec §5.3.1 参照）:

- `setup_done`: `operations/progress.md` が**存在する**（01-setup.md による初期化完了）
- `deploy_done`: `operations/progress.md` のステップ1-7 のすべてが「完了」or「スキップ」（02-deploy.md による PR 準備完了）
- `release_done`: `history/operations.md` に「PR Ready 化」記録あり（03-release.md による完了基準到達）
- `completion_done`: `history/operations.md` に「PR マージ」記録あり（04-completion.md による PR マージ後手順実施済み）

### 3.1 論理インターフェース契約（spec への binding）

判定ロジックの公開 API は `RecoveryJudgmentService.judge()`（spec §6）であり、呼び出し層（`compaction.md` / `session-continuity.md`）は必ず本 API を入口とする。Operations 内部の step 判定は `OperationsStepResolver.determine_current_step()`（spec §5.3、非公開下位契約）として提供される。

```text
operation: judge                           # 唯一の公開 API (spec §6)
signature: judge(artifacts_state: ArtifactsState) -> PhaseRecoveryJudgment
semantics:
  - PhaseResolver.resolvePhase() が先に評価される (spec §4)
  - 結果が Operations の場合のみ OperationsStepResolver.determine_current_step() (spec §5.3) が呼ばれる
  - OperationsStepResolver は以下の構造で評価する:
    - bootstrap 分岐評価: OperationsBootstrapRule.isBootstrap() で bootstrap 状態か判定
      - true → step_id=operations.01-setup を返す（construction_complete info diagnostic 付き）
      - false → 通常の checkpoint 評価へ
    - 通常評価: 4 checkpoint を順に評価し、未達成の最初の checkpoint に対応する step_id を返す（§5.3.1）
  - 戻り値は result + diagnostics[] の 2 フィールド分離形式 (spec §6)
    - blocking (undecidable:missing_file / undecidable:format_error) は自動継続禁止
    - info (construction_complete) は diagnostics[] に追加、result は継続可

責務境界:
  - phase 遷移は PhaseResolver の責務 (spec §4)。OperationsStepResolver は phase 遷移を返さない
  - bootstrap 状態の検出は OperationsBootstrapRule に閉じ、OperationsStepResolver は単純に
    そのフラグで分岐する
  - Operations は AI-DLC サイクルの最終 phase であり、「次サイクル」遷移は AI-DLC オーケストレーター
    層の責務（OperationsStepResolver の対象外）
```

---

## 4. ステップ読み込み契約

AI エージェントはこのテーブルを参照して詳細ファイルをロードする。**本テーブルの列構造・行構造は予算都合でも変更不可**。**4 step_id × 4 detail_file の 1:1 対応**を維持する。

| step_id | detail_file | entry_condition | exit_condition | load_timing |
|---------|-------------|-----------------|----------------|-------------|
| `operations.01-setup` | `steps/operations/01-setup.md` | フェーズ開始時または bootstrap 分岐から（`step_id` 未指定時の既定開始点） | プリフライト＋進捗管理ファイル作成＋運用引き継ぎ情報読み込み＋全 Unit 完了確認＋Construction 引き継ぎタスク確認 | `on_demand` |
| `operations.02-deploy` | `steps/operations/02-deploy.md` | `operations.01-setup` 完了後（progress.md 存在） | progress.md ステップ1-7 のすべてが「完了」or「スキップ」（PR 準備完了） | `on_demand` |
| `operations.03-release` | `steps/operations/03-release.md` | `operations.02-deploy` 完了後（PR 準備完了） | history に「PR Ready 化」記録（コミット漏れ確認、リモート同期、PR マージ前レビュー完了） | `on_demand` |
| `operations.04-completion` | `steps/operations/04-completion.md` | `operations.03-release` 完了後（PR Ready 化済み） | history に「PR マージ」記録（PR マージ後手順、worktree フロー、バージョンタグ付け、次サイクル準備完了） | `on_demand` |

### 4.1 既定ルート

- `step_id` が明示指定されている場合: 上記テーブルから解決
- `step_id` 未指定の場合（**新規開始時のみ**）: **`operations.01-setup` を既定開始点**として契約テーブルから解決
- **コンパクション復帰時（再開文脈）**: `RecoveryJudgmentService.judge(ArtifactsState)`（spec §6）を呼び、戻り値 `PhaseRecoveryJudgment.step.result`（`StepId`）から `step_id` を取得する。内部的には `PhaseResolver`（spec §4）→ `OperationsStepResolver`（spec §5.3）が順に評価される。bootstrap 状態では `operations.01-setup` + `construction_complete` info、blocking（`undecidable:missing_file` / `undecidable:format_error`）時はユーザー確認フローへ遷移する（詳細は `steps/common/compaction.md` の「復帰フローの確認手順」および `phase-recovery-spec.md` §6/§7/§8 参照）

### 4.2 SKILL.md 側のルーティング責務

SKILL.md の共通初期化フローは本インデックスファイルのみを常時ロードし、詳細ファイルは上記契約経由で必要時ロードする。**SKILL.md は契約テーブルを参照する薄いルーティング責務のみを持ち、詳細ステップの読み込み条件ロジックを直接持たない**。

---

## 5. 汎用構造仕様（Unit 001 / 002 / 003 から継承）

本インデックスファイルの章構成（1. 目次 / 2. 分岐ロジック / 3. 判定チェックポイント表 / 4. ステップ読み込み契約）は、Unit 001（Inception）で確立した共通構造を流用している。フェーズ固有要素（ステップ名、分岐条件、checkpoint、bootstrap 分岐）のみを Operations 向けに差し替えた。

**共通要素（フェーズ非依存）**:

- 章立て: 目次 / 分岐ロジック / 判定チェックポイント表 / ステップ読み込み契約
- `StepLoadingContract` 列スキーマ: `step_id` / `detail_file` / `entry_condition` / `exit_condition` / `load_timing`
- `RecoveryCheckpoint` 列スキーマ: `checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`
- Materialized Binding 宣言と `<!-- phase-index-schema: v1 -->` スキーマバージョンコメント（`spec_version` と独立管理、詳細は `phase-recovery-spec.md` §1.4 参照）

**Operations 固有要素**:

- 各ステップの `step_id` 命名規約: `operations.{step-slug}`
- 直線的進行構造（Unit loop なし、Inception 同型）
- bootstrap 分岐（Construction → Operations 初回遷移を正常系として扱う、Inception/Construction にはない Operations 固有要素）
- 分岐ロジックセクションの具体的な条件（「変更なし」スキップ、`project.type` 依存スキップ、worktree フロー、`automation_mode` 分岐等）
- チェックポイントの具体的な `checkpoint_id`: `setup_done` / `deploy_done` / `release_done` / `completion_done`（4 checkpoint × 4 step_id × 4 detail_file の 1:1 対応）
- Inception（Unit 001 パイロット）は 5 checkpoint、Construction（Unit 003）は 4 checkpoint + Stage 1 アルゴリズム節、Operations（本 Unit 004）は 4 checkpoint + bootstrap 分岐。列スキーマは全 phase で不変
