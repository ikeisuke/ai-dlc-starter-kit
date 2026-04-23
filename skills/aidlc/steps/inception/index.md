<!-- phase-index-schema: v1 -->
<!--
Materialized Binding 宣言:
  本インデックスファイルは `steps/common/phase-recovery-spec.md`（規範仕様）の Inception Phase 向け
  materialized binding である。判定規則の本文は spec 側にあり、本ファイルは具象パスと spec 参照
  トークン（`spec§N` / `spec§N.<checkpoint_id>`）のみを保持する。
  ステップ間分岐ロジックと判定チェックポイント表は本ファイルで managed されるが、判定規則の
  アルゴリズム・ポリシーは spec を参照すること。
  binding_schema_version は spec_version と独立管理される（spec §1.4 参照）。
-->

# Inception Phase インデックス

Inception Phase の入口ファイル。以下4要素を集約する:

1. 全ステップの目次・概要
2. ステップ間分岐ロジック
3. 判定チェックポイント表（Unit 002 で実値化済み、`phase-recovery-spec.md` への materialized binding）
4. ステップ読み込み契約（`step_id` → `detail_file` の解決テーブル）

AI エージェントは本ファイルを常時ロードし、詳細手順ファイル（`01-setup.md` 〜 `05-completion.md`）は「ステップ読み込み契約」に従って必要時のみロードする。

---

## 1. 目次・概要

| step_id | タイトル | 目的 |
|---------|---------|------|
| `inception.01-setup` | セットアップ | プリフライト、バージョン・ブランチ決定、サイクルディレクトリ作成、progress.md 初期化 |
| `inception.02-preparation` | インセプション準備 | エクスプレス検出、depth_level 確認、Issue/バックログ確認、既存成果物確認 |
| `inception.03-intent` | Intent 明確化 | Intent 対話作成、brownfield 既存解析、AIレビュー・承認 |
| `inception.04-stories-units` | ストーリー・Unit 定義 | ユーザーストーリー作成、Unit 分解、エクスプレス判定、PRFAQ 作成 |
| `inception.05-completion` | 完了処理 | Milestone（v2.4.0以降、`[rules.milestone].enabled=true` のみ動作 / 既定 off）、履歴記録、意思決定記録、ドラフト PR、squash、コミット、コンテキストリセット |

各ステップの詳細手順は「4. ステップ読み込み契約」に示された `detail_file` を参照すること。

---

## 2. 分岐ロジック

インセプションフェーズ内で発生する分岐を一元化する。各詳細ステップファイルは本セクションを参照し、分岐判定ロジック自体は重複記載しない。

### 2.1 ステップ構成

| ステップ | 含まれる step_id | 遷移条件 |
|---------|-----------------|---------|
| ステップ1（セットアップ） | `inception.01-setup` | フェーズ開始時から開始 |
| ステップ2以降（インセプション本体） | `inception.02-preparation` 以降 | サイクルディレクトリ作成完了 / 既存サイクル再開時は progress.md 読み込み完了 |

**再開時**: `.aidlc/cycles/{{CYCLE}}/inception/progress.md` が存在する場合、未完了ステップから再開する。

### 2.2 エクスプレスモード分岐

| 契機 | 条件 | 動作 |
|------|------|------|
| インスタント検出（`inception.02-preparation`） | 初回入力が `start express` と完全一致（case-insensitive） | `express_enabled=true`、`express_source=command`、`depth_level` は変更なし |
| 判定実行（`inception.04-stories-units` ステップ4b） | `express_enabled=true` かつ Unit 数 ≥ 1 かつ全 Unit が `eligible` | エクスプレスモード有効、Inception → Construction 統合フロー適用 |
| フォールバック | Unit 数 0 / 1つでも `ineligible` | 通常フロー継続、履歴に理由記録 |

詳細は `common/rules-automation.md` の「エクスプレスモード仕様」を参照。

### 2.3 depth_level 分岐

| depth_level | 影響範囲 | 動作差分 |
|-------------|---------|---------|
| `minimal` | 受け入れ基準・Intent 記述・PRFAQ | PRFAQ スキップ可、Intent 質問観点最小化、受け入れ基準主要ケースのみ |
| `standard`（デフォルト） | - | 現行動作 |
| `comprehensive` | Intent・ストーリー・Unit 定義 | リスク分析・代替案検討・エッジケース網羅・技術リスク評価を追加 |

詳細は `common/rules-reference.md` の「レベル別成果物要件」を参照。

### 2.4 automation_mode 分岐（ゲート判定）

| automation_mode | ゲート動作 |
|-----------------|----------|
| `manual` | 全承認ポイントでユーザー確認 |
| `semi_auto` | フォールバック条件非該当なら `auto_approved`、該当時は `fallback(reason_code)` |

本 Inception フェーズでのゲート発生箇所:

- Intent 承認（`inception.03-intent` ステップ1 完了時）
- ユーザーストーリー承認（`inception.04-stories-units` ステップ3 完了時）
- Unit 定義承認（`inception.04-stories-units` ステップ4 完了時）

詳細・フォールバック条件テーブル・構造化シグナルは `common/rules-automation.md` の「セミオートゲート仕様」を参照。

### 2.5 cycle_mode 分岐（`inception.01-setup`）

| mode | 動作 |
|------|------|
| `default` | 通常フロー（名前入力なし） |
| `named` | サイクル名入力／既存名付きサイクル選択。バリデーション: `^[a-z0-9][a-z0-9-]{0,63}$`。予約名禁止 |
| `ask` | 通常／名前付きの選択を提示 |

無効値・読み取り失敗時（exit 2）→ `default` にフォールバック。

### 2.6 branch_mode 分岐（`inception.01-setup` ステップ9）

| mode | 動作 |
|------|------|
| `branch` | 自動でブランチ作成 |
| `worktree` | worktree 作成 |
| `ask`（デフォルト） | ユーザーに選択提示 |

無効値 → `ask` にフォールバック。

### 2.7 gh_status 分岐

プリフライトで取得済みの `gh_status` を各ステップが参照する:

| gh_status | 対象機能の動作 |
|-----------|--------------|
| `available` | Issue 確認・バックログ確認・Milestone（v2.4.0以降、`[rules.milestone].enabled=true` のみ動作 / 既定 off）紐付け・ドラフト PR 作成をすべて実行 |
| `available` 以外 | 関連機能をスキップし、警告表示して続行 |

### 2.7.1 draft_pr 分岐（`inception.05-completion` ステップ5）

`gh_status=available` の場合にのみ評価される。ドラフトPR作成方針を `rules.git.draft_pr` 設定で制御する。`draft_pr` は `automation_mode` とは独立した設定であり、`ask` は常にユーザー選択（`AskUserQuestion`）として扱う。

**正規化契約**（`read-config.sh rules.git.draft_pr` の結果を正規化）:

| read-config.sh 終了コード | draft_pr_raw | draft_pr_effective | decision_source | 警告メッセージ |
|--------------------------|-------------|-------------------|-----------------|--------------|
| 0 | `always` / `never` / `ask` | そのまま | `explicit` | なし |
| 0 | その他 | `ask` | `defaulted_invalid` | `⚠ draft_pr の値が不正です（"{value}"）。デフォルト値 "ask" を使用します。` |
| 1 | - | `ask` | `defaulted_missing` | `⚠ draft_pr が未設定です。デフォルト値 "ask" を使用します。` |
| 2 | - | `ask` | `fallback_error` | `⚠ draft_pr の読み取りに失敗しました。デフォルト値 "ask" を使用します。` |

**resolveDraftPrAction**（`gh_status` 判定後に評価）:

| gh_status | draft_pr_effective | existing_pr | action |
|-----------|-------------------|------------|--------|
| != available | - | - | `skip_unavailable` |
| available | `never` | - | `skip_never` |
| available | `always` / `ask` | true | `skip_existing_pr` |
| available | `ask` | false | `ask_user` |
| available | `always` | false | `create_draft_pr` |

### 2.8 brownfield / greenfield 分岐（`inception.03-intent` ステップ2）

- **greenfield**: Reverse Engineering（ステップ2）全体をスキップ
- **brownfield**: ディレクトリ構造・アーキテクチャ・技術スタック・依存関係の4解析を実施し、`existing_analysis.md` に記録

### 2.9 AI レビュー分岐

各承認ポイントで AI レビューを実施する。**ルーティング判定（スキル名・focus・処理パス選択）は `steps/common/review-routing.md` 参照**、**反復・指摘対応・完了処理の手順は `steps/common/review-flow.md` 参照**。`review_mode=disabled` 時は `review-routing.md` のパス 3（ユーザーレビュー）へ直行。

対象タイミング（本フェーズ）:

- Intent 承認前
- ユーザーストーリー承認前
- Unit 定義承認前

---

## 3. 判定チェックポイント表（Unit 002 で実値化済み）

本テーブルは `phase-recovery-spec.md` §10（Inception への適用例）の materialized binding である。判定規則の本文は spec §4（PhaseResolver）／ §5.1（Inception Step 判定仕様）／ §6（戻り値契約）／ §8（ユーザー確認必須性ルール）に記載されており、本テーブルは spec 参照トークンで該当セクションにリンクする。**本テーブルの列構造・行構造（`binding_schema_version=v1`）は変更不可**。

| checkpoint_id | input_artifacts | priority_order | undecidable_return | user_confirmation_required |
|---------------|-----------------|----------------|--------------------|----------------------------|
| `inception.setup_done` | `.aidlc/cycles/{{CYCLE}}/inception/progress.md`, `.aidlc/cycles/{{CYCLE}}/` | `spec§5.inception.setup_done` | `spec§6` | `spec§8` |
| `inception.preparation_done` | `inception/progress.md` | `spec§5.inception.preparation_done` | `spec§6` | `spec§8` |
| `inception.intent_done` | `inception/intent.md`, `inception/progress.md` | `spec§5.inception.intent_done` | `spec§6` | `spec§8` |
| `inception.units_done` | `story-artifacts/units/`, `story-artifacts/user_stories.md`, `inception/progress.md` | `spec§5.inception.units_done` | `spec§6` | `spec§8` |
| `inception.completion_done` | `history/inception.md`, `inception/decisions.md`, `inception/progress.md` | `spec§5.inception.completion_done` | `spec§6` | `spec§8` |

**列の意味**（spec §9.2 参照）:

- `priority_order`: checkpoint の step 判定規則への参照（`spec§5.<phase>.<checkpoint_suffix>` 推奨形式、Unit 003 で §9.3 正式化）。phase 全体優先順位への参照ではない。phase 優先順位は `PhaseResolver` の固定責務（spec §4）で、binding 層には複製しない
- `undecidable_return`: 戻り値インターフェース契約への参照（`spec§6`）。全 checkpoint 共通
- `user_confirmation_required`: ユーザー確認必須性ルールへの参照（`spec§8`）。全 checkpoint 共通

### 3.1 論理インターフェース契約（spec への binding）

判定ロジックの公開 API は `RecoveryJudgmentService.judge()`（spec §6）であり、呼び出し層（`compaction.md` / `session-continuity.md`）は必ず本 API を入口とする。Inception 内部の step 判定は `PhaseLocalStepResolver.determine_current_step()`（spec §5.1、非公開下位契約）として提供される。

```text
operation: judge                           # 唯一の公開 API (spec §6)
signature: judge(artifacts_state: ArtifactsState) -> PhaseRecoveryJudgment
semantics:
  - PhaseResolver.resolvePhase() が先に評価される (spec §4)
  - 結果が Inception の場合のみ InceptionStepResolver.determine_current_step() (spec §5.1) が呼ばれる
  - 戻り値は result + diagnostics[] の2フィールド分離形式 (spec §6)
    - blocking (missing_file/conflict/format_error) は result=undecidable:<reason_code>
    - warning (legacy_structure) / info (new_cycle_start) は diagnostics[] に蓄積、result は継続可
  - blocking undecidable は automation_mode=semi_auto でも自動継続禁止 (spec §8)

Unit 002 時点の注意:
  - Inception フェーズの step 判定は本 binding + spec §5.1 で完結する
  - Construction/Operations と判定された場合は step=None となり、呼び出し層が現行ルート (Unit 定義の
    「実装状態」/ operations/progress.md) に委譲する暫定ディスパッチャを維持する (spec §2.4)
  - Unit 003/004 完了後、Construction/Operations も同様の binding を持つ
```

---

## 4. ステップ読み込み契約

AI エージェントはこのテーブルを参照して詳細ファイルをロードする。**本テーブルの列構造・行構造は予算都合でも変更不可**。

| step_id | detail_file | entry_condition | exit_condition | load_timing |
|---------|-------------|-----------------|----------------|-------------|
| `inception.01-setup` | `steps/inception/01-setup.md` | フェーズ開始時（`step_id` 未指定時の既定開始点） | サイクルディレクトリ作成＋progress.md 初期化完了 | `on_demand` |
| `inception.02-preparation` | `steps/inception/02-preparation.md` | `inception.01-setup` 完了 | エクスプレス検出／depth_level／Issue／バックログ／既存成果物確認完了 | `on_demand` |
| `inception.03-intent` | `steps/inception/03-intent.md` | `inception.02-preparation` 完了 | Intent 承認（`auto_approved` または ユーザー承認） | `on_demand` |
| `inception.04-stories-units` | `steps/inception/04-stories-units.md` | `inception.03-intent` 承認後 | ストーリー・Unit 定義承認 + エクスプレス判定 + PRFAQ 作成（depth_level 分岐） | `on_demand` |
| `inception.05-completion` | `steps/inception/05-completion.md` | `inception.04-stories-units` 承認後 | Milestone（v2.4.0以降、`[rules.milestone].enabled=true` のみ動作 / 既定 off）／履歴／意思決定記録／PR／squash／コミット／コンテキストリセット完了 | `on_demand` |

### 4.1 既定ルート

- `step_id` が明示指定されている場合: 上記テーブルから解決
- `step_id` 未指定の場合（**新規開始時のみ**）: **`inception.01-setup` を既定開始点**として契約テーブルから解決
- **コンパクション復帰時（再開文脈）**: `RecoveryJudgmentService.judge(ArtifactsState)`（spec §6）を呼び、戻り値 `PhaseRecoveryJudgment.step.result`（`StepId`）から `step_id` を取得する。内部的には `PhaseResolver`（spec §4）→ `InceptionStepResolver`（spec §5.1）が順に評価される。blocking（`undecidable:<reason_code>`）時はユーザー確認フローへ、warning（`legacy_structure`）/ info（`new_cycle_start`）時は警告表示後に通常判定を継続する（詳細は `steps/common/compaction.md` の「復帰フローの確認手順」および `phase-recovery-spec.md` §6/§7/§8 参照）
- `06-backtrack.md`（バックトラック用）は初回ロード対象外。バックトラック発動時のみ追加ロードする

### 4.2 SKILL.md 側のルーティング責務

SKILL.md の共通初期化フローは本インデックスファイルのみを常時ロードし、詳細ファイルは上記契約経由で必要時ロードする。**SKILL.md は契約テーブルを参照する薄いルーティング責務のみを持ち、詳細ステップの読み込み条件ロジックを直接持たない**。

---

## 5. 汎用構造仕様（他フェーズへの流用前提）

本インデックスファイルの章構成（1. 目次 / 2. 分岐ロジック / 3. 判定チェックポイント骨格 / 4. ステップ読み込み契約）は、フェーズに依存しない共通構造である。Unit 003（Construction）/ Unit 004（Operations）は本構造をそのまま流用し、フェーズ固有の要素（ステップ名、分岐条件、契約行、チェックポイント行）のみを差し替える。

**共通要素（フェーズ非依存）**:

- 章立て: 目次 / 分岐ロジック / 判定チェックポイント骨格 / ステップ読み込み契約
- `StepLoadingContract` 列スキーマ: `step_id` / `detail_file` / `entry_condition` / `exit_condition` / `load_timing`
- `RecoveryCheckpoint` 列スキーマ: `checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`
- Materialized Binding 宣言と `<!-- phase-index-schema: v1 -->` スキーマバージョンコメント（`spec_version` と独立管理、詳細は `phase-recovery-spec.md` §1.4 参照）

**フェーズ固有要素**:

- 各ステップの `step_id` 命名規約: `{phase}.{step-slug}`
- 分岐ロジックセクションの具体的な条件（automation_mode の発生箇所など）
- チェックポイントの具体的な `checkpoint_id`
