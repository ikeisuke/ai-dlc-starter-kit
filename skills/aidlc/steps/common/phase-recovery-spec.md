<!-- spec_version: v1.1 -->
<!-- normative_status: normative -->

# Phase Recovery Spec（汎用復帰判定仕様）

コンパクション復帰時およびフェーズ再開時に「どのフェーズのどのステップに復帰すべきか」を成果物状態から一意判定するための**規範仕様（Normative Spec）**。本仕様が判定ロジックの正本であり、各フェーズインデックスは本仕様への `materialized binding` として位置付けられる。

---

## §1. 仕様の位置付けとスコープ

### 1.1 正本宣言

本ファイルは v2.3.0 以降における **AI-DLC の復帰判定ロジックの正本**である。判定規則の本文はすべて本ファイルに置かれ、各フェーズインデックス（`steps/inception/index.md` など）は本仕様への具体値バインディングとして機能する。

### 1.2 各 phase index との関係（binding 定義）

| レイヤー | 役割 | ファイル |
|---------|------|---------|
| 規範仕様層（normative spec） | 判定規則の本文（ポリシー・アルゴリズム・戻り値契約） | `steps/common/phase-recovery-spec.md`（本ファイル） |
| materialized binding 層 | 各フェーズ固有の具体パスと spec 参照トークン | `steps/inception/index.md`（Inception）、`steps/construction/index.md`（Unit 003 で新設）、`steps/operations/index.md`（Unit 004 で新設） |
| 呼び出し層 | `judge()` 契約を介して結果を消費 | `steps/common/compaction.md`、`steps/common/session-continuity.md` |

### 1.3 Unit 002/003 との責務境界

- **Unit 002 で確立**: `PhaseResolver` の判定順、戻り値契約、異常系4系統分類、Inception Phase の step 判定仕様、spec_version v1.0
- **Unit 003 で追加（v1.1）**: Construction Phase の step 判定仕様（§5.2 実装昇格）、`phaseProgressStatus[construction]` 意味論（§3）、Construction 完了条件（§4 拡張）、`dependency_block` reason_code（§7）、token grammar 正式化（§9 更新）、Construction 適用例（§10.2）
- **placeholder のまま**: Operations Phase の step 判定仕様（§5.3、Unit 004 で埋める）
- **対象外**: 新たな Reviewing スキルの追加、既存スキルの内部実装変更

### 1.4 spec_version と binding_schema_version の独立管理

2種類のバージョンを**独立管理**する:

| バージョン | 対象 | 宣言場所 | 現在値 |
|-----------|------|---------|------|
| `spec_version` | 本ファイルの**コンテンツ**バージョン | 本ファイル先頭コメント | `v1.1` |
| `binding_schema_version` | 各 phase index の**テーブル列スキーマ**バージョン | 各 phase index 先頭コメント（`<!-- phase-index-schema: v1 -->`） | `v1` |

**互換性ルール**:

| 変更種別 | 影響 | binding 側の追随 |
|---------|------|---------------|
| `spec_version` の minor 更新（例: `v1.0 → v1.1`、本文の追記・明確化のみ） | spec 本文のみ更新 | **追随不要** |
| `spec_version` の major 更新（例: `v1.x → v2.0`、セクション番号や参照トークンの変更） | spec 本文 + 参照トークン形式 | **全 phase index の参照トークンを同期更新必須** |
| `binding_schema_version` の更新（列の追加・削除・型変更） | 全 phase index のテーブル構造 | **全 phase index の列を同期更新必須**。spec 本文は参照トークン方式を維持する限り追随不要 |

---

## §2. 2段レゾルバ構造

復帰判定は以下の2段のレゾルバで実装される。本仕様は両者の責務を分離して定義する。

### 2.1 PhaseResolver（phase 層）

- **責務**: `ArtifactsState` からどのフェーズに復帰すべきかを決定する
- **入力**: `ArtifactsState`（`phaseProgressStatus` を含む、詳細は §3）
- **出力**: `PhaseResolution`（§6）
- **判定順と条件**: §4 参照

### 2.2 PhaseLocalStepResolver（step 層、フェーズ固有）

- **責務**: 特定フェーズ内の具体的な復帰ステップ `step_id` を決定する
- **入力**: `ArtifactsState`
- **出力**: `StepResolution`（§6）
- **Inception 実装**: §5.1（Unit 002 で実値化）
- **Construction 実装**: §5.2（Unit 003 で実値化。Stage 1 = UnitSelectionRule、Stage 2 = 4 checkpoint）
- **Operations 実装**: §5.3（Unit 004 placeholder）

### 2.3 依存方向

```text
compaction.md / session-continuity.md            （呼び出し層）
        │
        ▼
RecoveryJudgmentService.judge()                   （唯一の公開 API）
        │
        ├─→ PhaseResolver.resolvePhase()          （§4 参照）
        │
        └─→ PhaseLocalStepResolver.determine_current_step()    （§5 参照、非公開下位契約）
                │
                ▼
          本ファイル（phase-recovery-spec.md）＋ 各 phase index（binding）
```

一方向、循環依存なし。

### 2.4 暫定ディスパッチャ（Unit 002 時点）

Unit 002 では Inception 向け `PhaseLocalStepResolver` のみを提供する。`PhaseResolver` が Construction / Operations と判定した場合は `StepResolution=None` を返し、呼び出し層（`compaction.md`）が**現行ルート**（Unit 定義ファイルの「実装状態」セクション / `operations/progress.md`）にフォールバックする。Unit 003 / 004 完了後に `PhaseLocalStepResolver` の Construction / Operations 実装が埋まり、暫定ディスパッチャは解消される。

---

## §3. 判定の入力モデル（ArtifactsState）

### 3.1 構造

`ArtifactsState` は 1 回の判定呼び出し時点のサイクル成果物状態のスナップショットであり、以下のフィールドを持つ:

| フィールド | 型 | 説明 |
|----------|-----|------|
| `cycleRoot` | path | サイクルディレクトリパス（例: `.aidlc/cycles/v2.3.0`） |
| `fileExistenceMap` | Map<path, bool> | 成果物パス → 存在有無 |
| `progressMarks` | Map<step_key, ProgressStatus> | progress.md から抽出した各行の状態（step 単位） |
| `phaseProgressStatus` | Map<PhaseName, PhaseProgressStatus> | phase 単位の完了状態サマリ |
| `legacyMarkers` | List<path> | 検出された旧構造マーカー（例: `session-state.md` のパス） |

### 3.2 PhaseProgressStatus の値

| 値 | 意味 |
|----|------|
| `unknown` | 該当 phase の進捗源（`{phase}/progress.md` や Unit 定義等）が存在しない（新規開始または未着手） |
| `incomplete` | 進捗源が存在し、未完了ステップ（または未完了 Unit）が残っている |
| `completed` | 進捗源が存在し、全ステップ（または全 Unit）が完了/取り下げ済み |

### 3.2.1 phase 別の進捗源と集約ルール（Unit 003 拡張）

| phase | 進捗源 | `unknown` | `incomplete` | `completed` |
|-------|--------|-----------|--------------|-------------|
| `inception` | `inception/progress.md` | 同ファイル未存在 | 同ファイル存在 ∧ 未完了ステップあり | 同ファイル存在 ∧ 全ステップ完了 |
| `construction` | `story-artifacts/units/*.md` 全件の「実装状態」セクション | `units/*.md` が 1 件も未存在 | `∃ unit. status ∈ {未着手, 進行中}` | `∀ unit. status ∈ {完了, 取り下げ}`（`units/*.md` 存在時） |
| `operations` | `operations/progress.md` | 同ファイル未存在 | 同ファイル存在 ∧ 未完了ステップあり | 同ファイル存在 ∧ 全ステップ完了 |

**注意**: `phaseProgressStatus[construction]` は `ArtifactsStateRepository.snapshot()` が Unit 定義ファイル群をスキャンして構築時に 1 度だけ計算する集約値である。判定層は文字列マッチングを一切行わず、enum 比較のみで動作する。

### 3.3 ProgressStatus の値

| 値 | 意味 |
|----|------|
| `未着手` | progress.md の該当行が未着手 |
| `進行中` | progress.md の該当行が進行中 |
| `完了` | progress.md の該当行が完了 |

### 3.4 構築方法

`ArtifactsState` はファイル存在チェック + progress.md の簡易パースで構築する。複雑な構文解析は避け、以下の手順で状態を集約する:

1. サイクルディレクトリ配下の成果物ファイルを `ls` 相当で列挙し `fileExistenceMap` を構築
2. 各フェーズの `progress.md` を読み込み、行ごとのステータスを抽出して `progressMarks` に格納
3. `progress.md` 全体の完了状態を集約して `phaseProgressStatus` に格納
4. `session-state.md` 等の旧マーカーを検出して `legacyMarkers` に格納

### 3.5 パース失敗時の扱い

`progress.md` のパースに失敗した場合（見出し欠落、行数異常等）、該当 phase の `phaseProgressStatus` は `unknown` とし、かつ `format_error` blocking を §7 の判定で検出させる。`ArtifactsState` は可能な範囲で構築される。

---

## §4. フェーズ判定仕様（PhaseResolver）

### 4.1 判定順

`PhaseResolver.resolvePhase(artifactsState)` は以下の順で評価する:

1. **conflict 検出**: 複数 phase が同時に `incomplete` かつ競合条件を満たす場合
2. **Operations 判定**: `operations/progress.md` が存在し、かつ `phaseProgressStatus[operations]=incomplete`
3. **Construction 判定**: `story-artifacts/units/*.md` が存在し、かつ **`phaseProgressStatus[inception]=completed` かつ `phaseProgressStatus[construction]=incomplete`**（Unit 003 で追加: Construction に未完了 Unit がある場合のみ）
4. **Inception 判定**: 上記以外（`phaseProgressStatus[inception]=incomplete` の場合）
5. **新規開始フォールバック**: `phaseProgressStatus[inception]=unknown` かつ他 phase も `unknown` の場合、Inception を返しつつ `diagnostics[]` に `new_cycle_start`（severity=info）を追加

**Construction 完了後の Operations 未着手ケース（Unit 003 追加）**: `phaseProgressStatus[inception]=completed` ∧ `phaseProgressStatus[construction]=completed` ∧ `phaseProgressStatus[operations]=unknown` の場合、判定順3 を skip し判定順2 のループへ戻ってから Operations 判定に流れる。Operations 判定は `operations/progress.md` が未存在のため当該分岐にも合致せず、結果として `result=operations` を返しつつ `diagnostics[]` に `construction_complete`（severity=info）を追加する形で Operations Phase の新規開始を促す。

**重要**: 判定順3 の Construction 完了条件は **`ArtifactsState.phaseProgressStatus[construction]` の集約値のみで評価**する。`ConstructionStepResolver.determine_current_step()` への仮呼び出しは一切行わない。これにより `PhaseResolver` → `ConstructionStepResolver` の依存を排除し、2 段レゾルバ構造の責務境界を維持する。

いずれの場合も blocking 条件（§7 参照）が検出されれば、`result=undecidable:<reason_code>` を優先して返す。

### 4.2 #553 補正ガードの統合

v2.2.3 では `story-artifacts/units/*.md` 存在時に問答無用で Construction と判定していたが、本仕様の判定順3（Construction 判定）では **`phaseProgressStatus[inception]=completed` を必須条件**とする。これにより `units/*.md` が存在しても `inception/progress.md` に未完了ステップがあれば判定順3を skip し、判定順4 の Inception に到達する。

**#553 補正は判定順3の分岐に本質的に統合され、特殊ガードとしての独立した条件は不要**。

### 4.3 conflict 検出条件

以下のいずれかに該当する場合、`result=undecidable:conflict` を返す:

- `phaseProgressStatus[operations]=incomplete` かつ `phaseProgressStatus[inception]=incomplete`（Inception と Operations が同時進行中）
- `phaseProgressStatus[operations]=incomplete` かつ `phaseProgressStatus[inception]=unknown` かつ `units/*.md` 存在（Construction と Operations が同時進行中で Inception 状態が不明）

### 4.4 戻り値

`PhaseResolution`（§6 参照）:

- **成功時**: `result=operations | construction | inception`、`diagnostics=[ ... ]`（warning/info があれば列挙）
- **conflict**: `result=undecidable:conflict`、`diagnostics=[ ... ]`
- **legacy_structure 検出時**: `result` は通常判定を継続し、`diagnostics` に `legacy_structure` warning を追加

**注意**: `unknown` は `PhaseProgressStatus`（入力状態）のラベルのみで使い、`PhaseResolution.result` には含まれない。`result` は常に `PhaseName`（`operations`/`construction`/`inception`）または `undecidable:<reason_code>` のいずれか。

---

## §5. Step 判定仕様（PhaseLocalStepResolver）

### §5.1 Inception Phase の step 判定

Inception 向け `PhaseLocalStepResolver.determine_current_step(artifactsState)` は `steps/inception/index.md` の判定チェックポイント表を実装データとして読み込み、以下の checkpoint ごとの判定規則に従って単一の `step_id` を返す。

#### §5.1.1 spec§5.setup_done

- **対応 step_id**: `inception.01-setup`
- **判定条件**: `.aidlc/cycles/{{CYCLE}}/inception/progress.md` が存在し、かつ progress.md のステップ1完了マークが未設定（=「未着手」または「進行中」）
- **単値化ルール**: サイクルディレクトリが存在するが progress.md のステップ1が未完了の状態

#### §5.1.2 spec§5.preparation_done

- **対応 step_id**: `inception.02-preparation`
- **判定条件**: progress.md のステップ1が「完了」、かつステップ2完了マークが未設定
- **単値化ルール**: 前段 `setup_done` の条件を満たしたうえで、ステップ2が未完了の状態

#### §5.1.3 spec§5.intent_done

- **対応 step_id**: `inception.03-intent`
- **判定条件**: `inception/intent.md` が存在するが `story-artifacts/user_stories.md` が未存在、かつ progress.md のステップ3完了マークが未設定
- **単値化ルール**: Intent 作成が進行中であり、次のストーリー作成ステップに進んでいない状態

#### §5.1.4 spec§5.units_done

- **対応 step_id**: `inception.04-stories-units`
- **判定条件**: 以下のいずれか:
  - `story-artifacts/user_stories.md` が存在するが `story-artifacts/units/*.md` が未存在
  - `units/*.md` が存在するが progress.md の「完了処理」セクションが「未着手」かつ `history/inception.md` が未存在
- **単値化ルール（境界条件）**: 04/05 境界は「progress.md『完了処理』＋ `history/inception.md` 存在」の**両方**で判定する。両方揃ったら `completion_done`、一方のみなら `units_done` にフォールバック

#### §5.1.5 spec§5.completion_done

- **対応 step_id**: `inception.05-completion`
- **判定条件**: `units/*.md` が存在し、かつ以下のいずれか:
  - progress.md の「完了処理」セクションが「進行中」
  - `history/inception.md` が存在し progress.md 全完了ではない
- **単値化ルール（境界条件）**: 04 境界との区別は §5.1.4 に記載

#### §5.1.6 undecidable return（全 checkpoint 共通）

戻り値は `spec§6` の `StepResolution` 型に従う。

### §5.2 Construction Phase の step 判定

Construction 向け `ConstructionStepResolver.determine_current_step(artifactsState)` は `steps/construction/index.md` の binding 層（Stage 1 アルゴリズム節 + Stage 2 の 4 checkpoint 表）を実装データとして読み込み、以下の 2 段構造で単一の `step_id` を返す。

**事前条件**: 本 resolver は `PhaseResolver` が `phase=construction` を確定した後にのみ呼ばれる。事前条件として `phaseProgressStatus[construction]=incomplete` が保証されており、少なくとも 1 つの未完了 Unit が存在する。

#### §5.2.0 Stage 1: 現在進行中 Unit の特定（UnitSelectionRule）

Unit 定義ファイル群（`story-artifacts/units/*.md`）の「実装状態」セクションを全件スキャンし、以下の集合を算出する:

- `in_progress_units = { u ∈ units | u.status = 進行中 }`
- `executable_units  = { u ∈ units | u.status = 未着手 ∧ u.dependencies ⊆ {完了, 取り下げ} }`
- `pending_units     = { u ∈ units | u.status ∈ {未着手, 進行中} }`

事前条件により `|pending_units| > 0` が保証される。以下の決定ツリーを順に評価し、最初に合致した分岐の outcome を返す:

| 条件 | outcome |
|------|---------|
| `\|in_progress_units\| ≥ 2` | `undecidable:conflict`（§7.1 conflict サブ系統: `multi_unit_in_progress`）|
| `\|in_progress_units\| = 1` | `UnitSelected(in_progress_units[0])` → Stage 2 へ |
| `\|executable_units\| = 0`（進行中 0 ∧ 実行可能 0 ∧ 未完了 Unit あり = 依存ブロック） | `undecidable:dependency_block`（§7.1 新 reason_code、Unit 003 追加）|
| `\|executable_units\| = 1` | `UnitSelected(executable_units[0])` → Stage 2（新規 Unit 選定）へ |
| `\|executable_units\| ≥ 2 ∧ automation_mode=semi_auto` | `UnitSelected(min_by_number(executable_units))` → Stage 2 へ |
| `\|executable_units\| ≥ 2 ∧ automation_mode=manual` | `step=None` + `diagnostics[]` に `user_selection_required(executable_units)`（info）を追加 |

#### §5.2.1 Stage 2: 進行中 Unit の現在ステップ特定（checkpoint 評価）

`UnitSelected(currentUnit)` が返った場合、以下の 4 checkpoint を順に評価し、**未達成の最初の checkpoint** に対応する `step_id` を返す。すべて達成済みの場合は Stage 1 の次周回（= 次の進行中/実行可能 Unit）に進む。

##### §5.2.1.1 spec§5.construction.setup_done

- **対応 step_id**: `construction.01-setup`
- **判定条件**: `plans/unit-{NNN}-plan.md` が存在し、かつ `history/construction_unit{NN}.md` に「計画承認」記録が含まれる
- **未達成時**: `construction.01-setup` を返す（計画作成 or 承認待ち）

##### §5.2.1.2 spec§5.construction.design_done

- **対応 step_id**: `construction.02-design`
- **判定条件**: 以下のいずれか:
  - (a) `design-artifacts/domain-models/unit_{NNN}_{stem}_domain_model.md` ∧ `design-artifacts/logical-designs/unit_{NNN}_{stem}_logical_design.md` が存在し、かつ `history/construction_unit{NN}.md` に「設計承認」記録が含まれる
  - (b) `depth_level=minimal` かつ `history/construction_unit{NN}.md` に「設計省略（depth_level=minimal）」記録が含まれる
- **未達成時**: `construction.02-design` を返す

##### §5.2.1.3 spec§5.construction.implementation_done

- **対応 step_id**: `construction.03-implementation`
- **判定条件**: `history/construction_unit{NN}.md` に「実装承認」または統合レビュー完了の記録が含まれる
- **未達成時**: `construction.03-implementation` を返す

##### §5.2.1.4 spec§5.construction.completion_done

- **対応 step_id**: `construction.04-completion`
- **判定条件**: `story-artifacts/units/{NNN}-{slug}.md` の「実装状態」セクションの `状態` が「完了」または「取り下げ」、かつ `history/construction_unit{NN}.md` に「Unit 完了」記録が含まれる
- **未達成時**: `construction.04-completion` を返す
- **全達成時**: Stage 1 の次周回へ（次 Unit に遷移、または全 Unit 完了時は `phaseProgressStatus[construction]=completed` により `PhaseResolver` 側で Operations 遷移判定される）

#### §5.2.2 canonical path 正規化表

Construction 成果物の命名規約を以下に固定する。`unit_slug`（ケバブケース）と `unit_stem`（アンダースコア化）の 2 種類のキーのみを path 構築に使用し、Unit 定義ファイルのタイトル文字列（`unit_title`）は path 構築に使用しない:

| 対象 | キー | フォーマット | 例 |
|------|------|-------------|----|
| Plan | `unit_number`（3桁） | `plans/unit-{NNN}-plan.md` | `unit-003-plan.md` |
| Unit 定義 | `unit_number`（3桁） + `unit_slug` | `story-artifacts/units/{NNN}-{slug}.md` | `003-construction-phase-index.md` |
| History | `unit_number` 下 2 桁 | `history/construction_unit{NN}.md` | `construction_unit03.md` |
| Domain Model | `unit_number`（3桁） + `unit_stem` | `design-artifacts/domain-models/unit_{NNN}_{stem}_domain_model.md` | `unit_003_construction_phase_index_domain_model.md` |
| Logical Design | `unit_number`（3桁） + `unit_stem` | `design-artifacts/logical-designs/unit_{NNN}_{stem}_logical_design.md` | `unit_003_construction_phase_index_logical_design.md` |
| Verification | `unit_number`（3桁） + `unit_stem` | `construction/units/unit_{NNN}_{stem}_verification.md` | `unit_003_construction_phase_index_verification.md` |
| Review Summary | `unit_number`（3桁） | `construction/units/{NNN}-review-summary.md` | `003-review-summary.md` |

- `unit_slug`: Unit 定義ファイル名 `{NNN}-{slug}.md` の slug 部分（ケバブケース）
- `unit_stem`: `unit_slug` の `-` を `_` に置換したもの（例: `construction-phase-index` → `construction_phase_index`）。path 構築専用
- `unit_title`: Unit 定義ファイルの `# Unit: ...` 見出し文字列。表示専用。path 構築には使用しない

#### §5.2.3 戻り値

戻り値は `spec§6` の `StepResolution` 型に従う。

#### §5.2.4 Stage 1 の Unit 特定アルゴリズムと既存 01-setup.md ステップ7 の対応

本 §5.2.0 の決定ツリーは `steps/construction/01-setup.md` ステップ7（対象 Unit 決定）の選定ロジックを規範化したものであり、以下の 1 対 1 対応を持つ:

| 01-setup.md ステップ7 の記述 | §5.2.0 の決定ツリー |
|---------------------------|-------------------|
| 進行中Unitあり → そのUnitを継続 | `\|in_progress_units\| = 1` → `UnitSelected(in_progress_units[0])` |
| 実行可能Unit 0個 → 全Unit完了 | Stage 1 に到達しない（`PhaseResolver` が `phaseProgressStatus[construction]=completed` で吸収） |
| 実行可能Unit 1個 → 自動選択 | `\|executable_units\| = 1` → `UnitSelected(executable_units[0])` |
| 実行可能Unit 複数 + `semi_auto` → 番号順で最初を自動選択 | `\|executable_units\| ≥ 2 ∧ semi_auto` → `UnitSelected(min_by_number(...))` |
| 実行可能Unit 複数 + `manual` → ユーザーに選択提示 | `\|executable_units\| ≥ 2 ∧ manual` → `step=None` + `user_selection_required` diagnostic |
| （新規）依存ブロック検出 | `\|executable_units\| = 0 ∧ \|pending_units\| > 0` → `undecidable:dependency_block` |
| （新規）複数 Unit 同時進行中 | `\|in_progress_units\| ≥ 2` → `undecidable:conflict` |

### §5.3 Operations Phase の step 判定（placeholder）

**Unit 004 で本セクションを埋める**。現時点では以下の暫定ルートを `PhaseResolver` が `step=None` を返す形で維持する:

- 再開ポイント: `.aidlc/cycles/{{CYCLE}}/operations/progress.md`
- Unit 004 完了時点で本セクションに `operations.deploy_done` / `operations.release_done` / `operations.cleanup_done` 等の checkpoint を追加予定

---

## §6. 戻り値インターフェース契約（result + diagnostics[]）

### 6.1 公開 API: `RecoveryJudgmentService.judge()`

```text
operation: judge
signature: judge(artifacts_state: ArtifactsState) -> PhaseRecoveryJudgment

input:
  - artifacts_state: ArtifactsState（§3）

output:
  - phase_recovery_judgment: PhaseRecoveryJudgment
    - phase: PhaseResolution
      - result: PhaseName | "undecidable:<reason_code>"
      - diagnostics: List<Diagnostic>
    - step: Optional<StepResolution>
      - result: StepId | "undecidable:<reason_code>"
      - diagnostics: List<Diagnostic>
```

### 6.2 PhaseResolution

| フィールド | 型 | 値 |
|----------|-----|------|
| `result` | enum | `operations` / `construction` / `inception` / `undecidable:missing_file` / `undecidable:conflict` / `undecidable:format_error` / `undecidable:dependency_block` |
| `diagnostics` | List<Diagnostic> | warning / info イベントのリスト（空でも可） |

### 6.3 StepResolution

| フィールド | 型 | 値 |
|----------|-----|------|
| `result` | enum | `StepId`（例: `inception.04-stories-units`、`construction.02-design`） / `None`（ユーザー選択待ち等、非 blocking） / `undecidable:missing_file` / `undecidable:format_error` / `undecidable:conflict` / `undecidable:dependency_block` |
| `diagnostics` | List<Diagnostic> | warning / info イベントのリスト（空でも可） |

### 6.4 Diagnostic

| フィールド | 型 | 値 |
|----------|-----|------|
| `type` | enum | `legacy_structure` / `new_cycle_start` / `construction_complete` / `user_selection_required`（Unit 003 追加） |
| `severity` | enum | `warning`（`legacy_structure`） / `info`（`new_cycle_start` / `construction_complete` / `user_selection_required`） |
| `detail` | string | 検出内容の説明（`user_selection_required` の場合は候補 Unit 一覧を含む） |

### 6.5 semantics

- `judge()` は**唯一の公開 API**。呼び出し層（`compaction.md` / `session-continuity.md`）は必ず本 API を入口とする
- `PhaseResolver.resolvePhase()`（§4）が先に評価される
- 結果が Inception の場合 `InceptionStepResolver.determine_current_step()`（§5.1、非公開下位契約）が呼ばれる
- 結果が Construction の場合 `ConstructionStepResolver.determine_current_step()`（§5.2、非公開下位契約、Unit 003 で追加）が呼ばれる
- Operations と判定された場合、`step` は `None` を返し、呼び出し側が暫定ルートに委譲する（Unit 004 で §5.3 実装後に解消予定）
- `result` が `undecidable` の場合、`diagnostics` は空でも可（blocking と独立）
- `diagnostics` に warning/info が含まれても `result` は継続可能

---

## §7. 異常系4系統の処理仕様

### 7.0 input_artifacts の解釈（必須 / 参照候補の区別）

binding 層（各 phase index）の `input_artifacts` 列に記載されるパスは「**判定ブランチ**が参照する候補の全列挙」であり、すべてが **「常に存在必須」ではない**。判定ブランチ（§5 の checkpoint 判定規則）ごとに「必須集合」と「オプション集合」が決まる:

| checkpoint | 必須集合（missing_file トリガー） | オプション集合（不在でも許容） |
|-----------|------------------------------|--------------------------|
| `inception.setup_done` | `inception/progress.md`（サイクルディレクトリ配下） | - |
| `inception.preparation_done` | `inception/progress.md` | - |
| `inception.intent_done` | `inception/progress.md` | `inception/intent.md`（存在有無は判定条件に使用、欠損は missing_file 不発） |
| `inception.units_done` | `inception/progress.md` | `inception/intent.md` / `story-artifacts/user_stories.md` / `story-artifacts/units/*.md`（判定条件に使用） |
| `inception.completion_done` | `inception/progress.md` | `story-artifacts/units/*.md` / `history/inception.md` / `inception/decisions.md`（判定条件に使用） |

**`missing_file` トリガー条件**: 各 phase の「進捗源となる `progress.md`」（= 必須集合）が欠損した場合のみ `missing_file` を発火する。オプション集合のファイルは「存在有無で判定ブランチを切り替える」入力であり、欠損は blocking ではない（欠損を前提とした判定ブランチが §5.1.1〜§5.1.5 に明記されている）。

### 7.1 分類

| reason_code | 分類 | 判定層 | 検出条件 | 戻り値への反映 |
|------------|------|-------|---------|--------------|
| `missing_file` | blocking | PhaseResolver / PhaseLocalStepResolver | 必須集合（§7.0）のファイルが欠損し、かつ判定ブランチのいずれにも合致しない | `result=undecidable:missing_file` |
| `conflict` | blocking | PhaseResolver / ConstructionStepResolver | §4.3 の条件に該当、または Construction Stage 1 で `\|in_progress_units\| ≥ 2`（`multi_unit_in_progress`、Unit 003 追加） | `result=undecidable:conflict` |
| `format_error` | blocking | ArtifactsState 構築時 | progress.md のテーブル構造パース失敗、見出し欠落、異常な行数 | `result=undecidable:format_error` |
| `dependency_block` | blocking | ConstructionStepResolver | Construction Stage 1 で `\|in_progress_units\|=0 ∧ \|executable_units\|=0 ∧ \|pending_units\|>0`（依存ブロックで実行可能な Unit が存在しない、Unit 003 追加） | `result=undecidable:dependency_block` |
| `legacy_structure` | warning | LegacyStructureDetector | `session-state.md` 残存、v2.2.x 以前の旧ファイル構造検出 | `diagnostics[].push({type: "legacy_structure", severity: "warning", detail: "..."})`、`result` は通常判定継続 |

### 7.1.1 dependency_block の期待動作（Unit 003 追加）

`result=undecidable:dependency_block` の場合、呼び出し層は以下を実施する:

- 未完了 Unit の一覧と各 Unit の依存関係を表示
- 依存ブロックの原因となっている未完了依存 Unit を特定して表示
- ユーザーに「依存 Unit の取り下げ」「依存解消」「Inception への戻り」のいずれかを促す
- `automation_mode=semi_auto` でも**自動継続禁止**（§8）

### 7.2 排他性

判定順は `blocking > warning` の優先順位で評価する:

1. ArtifactsState 構築時に `format_error` が検出されれば blocking 扱い
2. `PhaseResolver` 評価中に `missing_file` / `conflict` が検出されれば blocking 扱い（該当 reason_code を優先）
3. `ConstructionStepResolver` の Stage 1 で `conflict`（`multi_unit_in_progress`） / `dependency_block` が検出されれば blocking 扱い
4. blocking 検出時も warning 評価は継続する。`result=undecidable:<reason_code>` と同時に `diagnostics[]` に warning が含まれうる
5. blocking が複数同時検出された場合の優先順位: `missing_file > conflict > format_error > dependency_block`

### 7.3 warning のみ（blocking なし）の場合

`legacy_structure` のみ検出され blocking なしの場合、`result` は通常判定を継続する（Phase / Step の成功 result を返す）。`diagnostics[]` に `legacy_structure` を追加し、呼び出し側が警告表示するだけ。

---

## §8. ユーザー確認必須性ルール

### 8.1 blocking undecidable の場合

`result=undecidable:<reason_code>`（`missing_file` / `conflict` / `format_error` / `dependency_block`）の場合、`automation_mode=semi_auto` でも**自動継続を禁止**し、必ずユーザー確認を要求する。`common/rules-automation.md` のフォールバック条件（`reason_code=error` 相当）に該当する。

### 8.2 warning / info のみの場合

`diagnostics[]` に `legacy_structure` / `new_cycle_start` のみ含まれ `result` が成功値の場合、継続可能。ただし警告/情報表示は必須:

- `legacy_structure`: `⚠ 旧構造マーカー検出: {detail}。マイグレーションを推奨します（強制ではありません）。`
- `new_cycle_start`: `ℹ 新規サイクル開始として Inception フェーズを開始します。`

### 8.3 `automation_mode` 別の扱い

| automation_mode | blocking undecidable | warning / info のみ |
|----------------|---------------------|-------------------|
| `manual` | ユーザー確認必須 | 警告/情報表示 + 継続 |
| `semi_auto` | ユーザー確認必須（自動継続禁止） | 警告/情報表示 + 自動継続 |

---

## §9. フェーズインデックスからの参照方法（materialized binding の書き方）

### 9.1 binding 層の責務

各 phase index（例: `steps/inception/index.md`）は以下のみを保持する:

1. フェーズの目次・分岐ロジック・ステップ読み込み契約（Unit 001 以降の既存責務）
2. 判定チェックポイント表（binding 層）: `checkpoint_id` + 具象 `input_artifacts` パス + spec 参照トークン

判定規則の本文（ポリシー・アルゴリズム）は binding 層に**記述しない**。spec 参照トークンで本仕様へリンクするのみ。

### 9.2 判定チェックポイント表のスキーマ

Unit 001 で確立された5列を維持（`binding_schema_version=v1`）:

| 列名 | 本 Unit での意味 | 型 |
|------|----------------|-----|
| `checkpoint_id` | checkpoint の一意識別子 | string |
| `input_artifacts` | 判定に必要な成果物パスのリスト（具象パス） | list of path |
| `priority_order` | この checkpoint の step 判定規則への参照（`spec§5.<phase>.<checkpoint_suffix>` 推奨形式、または後方互換 alias の `spec§5.<checkpoint_suffix>` 省略形式、§9.3 参照） | spec ref |
| `undecidable_return` | 戻り値インターフェース契約への参照 = `spec§6` | spec ref |
| `user_confirmation_required` | ユーザー確認必須性ルールへの参照 = `spec§8` | spec ref |

**注意**: Unit 001 時点では `priority_order` 列は「同点時の phase 優先順位」への参照として想定されていたが、Unit 002 の設計整理により「checkpoint 単位の step 判定規則への参照」として意味を確定した。phase 全体優先順位は `PhaseResolver` の固定責務（本仕様 §4）に寄せられたため、binding 層には再複製しない。列名自体は `binding_schema_version=v1` 互換性のため変更しない。

### 9.3 参照トークン形式（Unit 003 で正式化）

Unit 001/002 で暫定的に使用していた省略形を、Unit 003 で phase 明示の推奨形式に昇格させた。**推奨形式**と**後方互換 alias** を明確に区別する:

| 種別 | トークン形式 | 用途 | 例 |
|------|------------|------|------|
| トップレベル | `spec§N` | spec トップレベルセクションへの参照 | `spec§4`（§4 フェーズ判定仕様）、`spec§6`（§6 戻り値契約）、`spec§8`（§8 ユーザー確認ルール） |
| **推奨形式（phase 明示）** | `spec§N.<phase>.<checkpoint_suffix>` | spec §N 配下の phase 別 checkpoint 単位サブルールへの参照 | `spec§5.inception.setup_done`、`spec§5.construction.setup_done`、`spec§5.construction.design_done` |
| **後方互換 alias**（Inception 暗黙形、Unit 001/002 で使用） | `spec§N.<checkpoint_suffix>` | spec §N 配下の checkpoint 参照（phase 省略時は Inception を指す暗黙形） | `spec§5.setup_done` ≡ `spec§5.inception.setup_done` |

**互換性ルール**:

- `spec§5.construction.<checkpoint>` / `spec§5.operations.<checkpoint>` は **推奨形式のみ**使用可能（phase を省略した形式は Construction/Operations には使えない）
- `spec§5.<checkpoint>` の省略形は **Inception に限り** 後方互換 alias として許容される。`spec_version=v1.1` 時点では Inception binding が省略形または明示形のどちらを使っても等価
- 新規 binding 作成時は**推奨形式（phase 明示）を使用すべき**。Unit 003 では Inception binding を明示形に migrate する（互換性のためではなく cleanliness 目的）
- Unit 004 以降で Operations binding を追加する際は推奨形式のみを使用する

この alias 許容により、`spec_version` を major 更新（v2.0）に昇格させずに minor 更新（v1.1）のまま token grammar を拡張できる。

**正規化ルール**:

- `<checkpoint_id>` は Unit 001 の `checkpoint_id` 列の値と完全一致する文字列（例: `setup_done`）を採用する
- フェーズ prefix（`<phase>.`）は**推奨形式では必須**。phase を省略できるのは上記「互換性ルール」に定める **Inception の後方互換 alias に限定** される（Construction/Operations では phase 省略不可）
- トークンは常に小文字・アンダースコア区切り。ハイフンは使わない（`step_id` の `01-setup` とは別系統）
- `spec§N.M` 形式（数値サブセクション）は本 Unit では未使用

### 9.4 checkpoint_id 命名規約

`{phase}.{step_slug}_done` 形式。`step_slug` は phase 内で一意な slug（例: `setup`、`preparation`、`intent`、`units`、`completion`）。末尾の `_done` は「その step が完了した状態」を意味する。

---

## §10. Inception への適用例

### 10.1 binding テーブルの具体値

`steps/inception/index.md` の判定チェックポイント表は以下の値で埋まる:

`priority_order` 列は §9.3 で正式化された `spec§5.<phase>.<checkpoint>` 推奨形式で記載する（Unit 003 で migrate）。Inception の後方互換 alias（phase 省略形）も §9.3 の互換性ルールにより等価だが、canonical な適用例はこちらの明示形に揃える:

| checkpoint_id | input_artifacts | priority_order | undecidable_return | user_confirmation_required |
|---------------|-----------------|----------------|--------------------|----------------------------|
| `inception.setup_done` | `.aidlc/cycles/{{CYCLE}}/inception/progress.md`, `.aidlc/cycles/{{CYCLE}}/` | `spec§5.inception.setup_done` | `spec§6` | `spec§8` |
| `inception.preparation_done` | `inception/progress.md` | `spec§5.inception.preparation_done` | `spec§6` | `spec§8` |
| `inception.intent_done` | `inception/intent.md`, `inception/progress.md` | `spec§5.inception.intent_done` | `spec§6` | `spec§8` |
| `inception.units_done` | `story-artifacts/units/`, `story-artifacts/user_stories.md`, `inception/progress.md` | `spec§5.inception.units_done` | `spec§6` | `spec§8` |
| `inception.completion_done` | `history/inception.md`, `inception/decisions.md`, `inception/progress.md` | `spec§5.inception.completion_done` | `spec§6` | `spec§8` |

### 10.2 #553 再現シナリオの判定例

| シナリオ | ArtifactsState | 判定結果 |
|---------|---------------|---------|
| 1a: PRFAQ 未着手（`units/*.md` 存在、progress.md「完了処理」未着手、`history/inception.md` なし、`phaseProgressStatus[inception]=incomplete`） | § 4 判定順: conflict なし → Operations なし → Construction 判定で `phaseProgressStatus[inception]!=completed` のため skip → Inception | `phase=inception`、`step=inception.04-stories-units`（単値） |
| 1b: 完了処理進行中（`units/*.md` 存在、progress.md「完了処理」進行中、`history/inception.md` なし、`phaseProgressStatus[inception]=incomplete`） | § 4 判定順: 同上 → Inception | `phase=inception`、`step=inception.05-completion`（単値） |
| 2: 全完了（`units/*.md` 存在、progress.md 全完了、`history/inception.md` 存在、`phaseProgressStatus[inception]=completed`） | § 4 判定順: conflict なし → Operations なし → Construction 判定で `phaseProgressStatus[inception]=completed` を満たす | `phase=construction`、`step=None`（暫定ディスパッチャで現行ルート委譲） |

### 10.3 v2.2.3 ロジックとの対比記録

**v2.2.3 の判定ロジック**（`compaction.md` の判定順テーブル、本仕様により削除予定）:

| 判定順 | 条件 | 判定 |
|-------|------|------|
| 1 | `operations/progress.md` 存在 | Operations |
| 2 | `inception/progress.md` 存在 かつ 未完了ステップあり | Inception（優先ガード） |
| 3 | `story-artifacts/units/*.md` 存在 | Construction |
| 4 | 上記以外 | Inception |

**v2.2.3 ロジックを再現シナリオ1a/1b に手動適用した場合の挙動**:

- シナリオ1a: `units/*.md` 存在、`inception/progress.md`「完了処理」未着手
- シナリオ1b: `units/*.md` 存在、`inception/progress.md`「完了処理」進行中
- 判定表テキスト上の建前: v2.2.3 判定順2（「進行中」「未着手」が inception/progress.md にあれば Inception 優先ガード発動）により、どちらのシナリオでも Inception と判定される**はず**
- 実運用での実際の挙動: v2.2.3 の判定順2 ガードは `inception/progress.md` のテーブル本文を「進行中」「未着手」などの文字列で走査していたが、`progress.md` の書式変化（チェックマーク位置・空白・日本語表記のゆれ等）によりこれらのマーカーが検出できないケースが発生し、判定順2 を skip → 判定順3（`units/*.md` 存在で Construction 判定）に流れてしまう。結果として**再現シナリオ1a/1b はいずれも Construction と誤判定され、本来 Inception 後半で再開すべきセッションが Construction として扱われる**。これが #553 の本質である。

**対比**: 上記の通り、判定表の建前と実運用の挙動が乖離していた点が #553 の構造的問題である。本仕様では `ArtifactsState` 構築時に `phaseProgressStatus` を `unknown` / `incomplete` / `completed` の 3値 enum に正規化し、判定層（`PhaseResolver`）は文字列マッチングを一切行わず enum 比較のみで判定する。さらに判定順3（Construction 判定）の必須条件に `phaseProgressStatus[inception]=completed` を課すことで、Inception が未完了である限り構造的に Construction へ流れないことを保証する。これにより progress.md の書式変化に起因する取りこぼしを構造的に排除する。

### 10.4 正常系検証ケースと期待値

| # | シナリオ | phase | step |
|---|---------|-------|------|
| 1 | サイクルディレクトリ + 空 progress.md のみ（intent.md なし） | inception | `inception.01-setup` |
| 2 | Intent 完了時点（intent.md 存在、user_stories.md なし、units/ 空） | inception | `inception.03-intent` |
| 3 | ストーリー完了時点（user_stories.md 存在、units/ 空） | inception | `inception.04-stories-units` |
| 4a | Unit 定義作成済み、progress.md「完了処理」未着手（units/*.md 存在、history/inception.md なし） | inception | `inception.04-stories-units` |
| 4b | Unit 定義完了・完了処理進行中（units/*.md 存在、progress.md「完了処理」進行中、history/inception.md なし） | inception | `inception.05-completion` |
| 5 | 完了処理中盤（history/inception.md 存在、progress.md 一部未完了） | inception | `inception.05-completion` |

### 10.5 異常系検証ケースと期待値

| # | reason_code | 分類 | 期待結果 |
|---|------------|------|---------|
| 1 | `missing_file` | blocking | `phase.result=undecidable:missing_file`、ユーザー確認必須 |
| 2 | `conflict` | blocking | `phase.result=undecidable:conflict`、ユーザー確認必須 |
| 3 | `format_error` | blocking | `phase.result=undecidable:format_error`、ユーザー確認必須 |
| 4 | `legacy_structure` | warning | `phase.result` は通常判定継続、`diagnostics[]` に `legacy_structure` 追加、警告表示のみ |

---

## §11. Construction への適用例（Unit 003）

### 11.1 binding テーブルの具体値

`steps/construction/index.md` の判定チェックポイント表の実値例（Stage 2 の 4 行）:

| checkpoint_id | input_artifacts | priority_order | undecidable_return | user_confirmation_required |
|---------------|-----------------|----------------|--------------------|----------------------------|
| `construction.setup_done` | `plans/unit-{NNN}-plan.md`, `history/construction_unit{NN}.md` | `spec§5.construction.setup_done` | `spec§6` | `spec§8` |
| `construction.design_done` | `design-artifacts/domain-models/unit_{NNN}_{stem}_domain_model.md`, `design-artifacts/logical-designs/unit_{NNN}_{stem}_logical_design.md`, `history/construction_unit{NN}.md` | `spec§5.construction.design_done` | `spec§6` | `spec§8` |
| `construction.implementation_done` | `history/construction_unit{NN}.md` | `spec§5.construction.implementation_done` | `spec§6` | `spec§8` |
| `construction.completion_done` | `story-artifacts/units/{NNN}-{slug}.md`, `history/construction_unit{NN}.md` | `spec§5.construction.completion_done` | `spec§6` | `spec§8` |

Stage 1（Unit 選定アルゴリズム）は checkpoint 表ではなく、`steps/construction/index.md` §3.1（アルゴリズム節）に記述する。`spec§5.construction.unit_selection` トークンで spec §5.2.0 を参照する。

### 11.2 Construction 正常系検証ケース

| # | シナリオ | phase | step |
|---|---------|-------|------|
| 1 | 新規 Unit 選定、計画承認前（plan のみ存在、承認記録なし） | construction | `construction.01-setup` |
| 2 | 計画承認済み、設計未着手（Phase 1 開始直前） | construction | `construction.02-design` |
| 3 | 設計承認済み、実装未着手（Phase 2 開始直前） | construction | `construction.03-implementation` |
| 4 | 実装承認済み、完了処理未着手 | construction | `construction.04-completion` |

### 11.3 Construction 異常系検証ケース

| # | reason_code | 分類 | シナリオ | 期待結果 |
|---|------------|------|---------|---------|
| 1 | `multi_unit_in_progress`（§7.1 conflict） | blocking | 2 Unit 同時に「進行中」 | `phase.result=construction`、`step.result=undecidable:conflict`、ユーザー確認必須 |
| 2 | `dependency_block` | blocking | 実行可能 Unit なし、未完了 Unit は依存ブロック | `phase.result=construction`、`step.result=undecidable:dependency_block`、ユーザー確認必須 |
| 3 | `construction_complete`（info） | info | 全 Unit 完了、operations/progress.md なし | `phase.result=operations`、`diagnostics[]` に `construction_complete` 追加 |

### 11.4 Unit 特定アルゴリズムと既存 01-setup.md ステップ7 の対応

§5.2.4 を参照。Unit 003 で確立した `UnitSelectionRule` の決定ツリーは、既存 `steps/construction/01-setup.md` ステップ7（対象 Unit 決定）の選定ロジックを規範化したものであり、1 対 1 対応を持つ。
