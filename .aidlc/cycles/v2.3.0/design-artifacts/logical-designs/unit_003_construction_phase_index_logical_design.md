# 論理設計: Unit 003 Construction Phase インデックス化

## 概要

Unit 001（Inception パイロット）で確立したフェーズインデックス構造と、Unit 002（規範仕様）で確立した **Normative Spec + Materialized Binding** パターンを Construction Phase に展開する論理設計を定義する。本 Unit の成果物もコードではなくドキュメントが主体であり、Unit 002 と同じドキュメント層アーキテクチャを適用する。加えて、Construction 固有の検証のために `verify-construction-recovery.sh` を新規追加する（Unit 002 の `verify-inception-recovery.sh` と同じアーキテクチャ）。

**重要**: この論理設計では**コードは書かず**、ドキュメント構成・セクション階層・参照関係・検証スクリプトの I/F のみを定義する。

## アーキテクチャパターン

**パターン名**: **Normative Spec + Materialized Binding**（Unit 002 と同一、Construction 向けの展開）

**選定理由**（Unit 002 の理由に追記）:

- Unit 002 で確立した「spec 1 箇所 + binding 複数」の構造を Construction にも適用することで、`phase-recovery-spec.md` を全フェーズ横断の唯一の正本として維持できる
- Construction は Inception と異なり Unit loop 構造を持つが、その複雑さは spec §5.2（規範仕様側）に吸収し、binding 層（`steps/construction/index.md`）は Inception binding と同じ列スキーマで記述できる
- `ConstructionStepResolver` という新しい phase-local resolver を導入するが、`PhaseLocalStepResolver` インターフェースは Unit 002 で定義済みであり、既存契約をそのまま実装する形になる

**依存方向**:

```text
compaction.md / session-continuity.md                 (呼び出し層)
        │
        ▼
RecoveryJudgmentService.judge()                        (唯一の公開 API、spec §6 で定義)
        │
        ├─→ PhaseResolver.resolvePhase()               (spec §4、Unit 003 で Construction 完了条件を追加)
        │
        ├─→ InceptionStepResolver                      (spec §5.1、Unit 002)
        │       │
        │       ▼
        │  steps/inception/index.md (binding)
        │       │
        │       ▼
        │  steps/common/phase-recovery-spec.md         (規範仕様、§5.1 Inception)
        │
        └─→ ConstructionStepResolver                   (spec §5.2、Unit 003 新設、非公開下位契約)
                │
                ▼
          steps/construction/index.md (binding 層)      (spec§5.construction.<checkpoint> 参照)
                │
                ▼
          steps/common/phase-recovery-spec.md           (規範仕様、§5.2 Construction)
```

一方向の参照関係を維持。循環依存なし。`ConstructionStepResolver` → spec §5.2 → `RecoveryJudgmentService` の循環が生じないよう、spec 側は `PhaseLocalStepResolver` の**契約のみ**を定義し、実装コンテキスト（呼び出し元）には言及しない。

**境界の整理**（Unit 002 と同様）:

- **呼び出し層（`compaction.md` / `session-continuity.md`）は `judge()` 契約を介して扱う**: Unit 003 完了後、`compaction.md` の Construction 行は「`judge()` の結果を消費する」記述になり、現行ルート委譲（`step=None` 時の暫定ディスパッチャ）は解消される
- **内部実装データとしての `construction/index.md` / `phase-recovery-spec.md`**: Unit 002 と同様、これらは `ConstructionStepResolver` が内部で読む実装データ。呼び出し層から見れば `judge()` の内部実装への参照は発生しない
- **手順記述上の区別**: `compaction.md` の本文では引き続き抽象レベルの記述（`judge()` を呼ぶ）を維持し、Construction 固有の判定条件（Unit 選定ロジック等）を重複記述しない

## コンポーネント構成

### レイヤー / モジュール構成（ドキュメントファイル単位）

```text
skills/aidlc/
├── SKILL.md                                ← 更新 (共通初期化フローの construction 行を index.md のみに)
├── steps/
│   ├── common/
│   │   ├── phase-recovery-spec.md          ← 更新 (§4 拡張 / §5.2 実装 / §7 dependency_block / §9 token grammar / §10.2)
│   │   ├── compaction.md                   ← 更新 (Construction 行を正式ルートに昇格、Operations は暫定維持)
│   │   └── session-continuity.md           ← 更新 (Construction 行を judge() 契約経由に更新)
│   ├── inception/
│   │   └── index.md                        ← 更新 (spec§5.<checkpoint> → spec§5.inception.<checkpoint> 明示形に)
│   └── construction/
│       ├── index.md                        ← 新規 (Construction binding 層、4 checkpoint + Stage 1 アルゴリズム節)
│       ├── 01-setup.md                     ← 更新 (重複除去)
│       ├── 02-design.md                    ← 更新 (重複除去)
│       ├── 03-implementation.md            ← 更新 (重複除去)
│       └── 04-completion.md                ← 更新 (重複除去)
└── scripts/
    └── verify-construction-recovery.sh     ← 新規 (Construction 版 fixture 生成スクリプト)
```

### コンポーネント詳細

#### steps/construction/index.md（新規・Construction binding 層）

- **責務**:
  - Construction フェーズの目次・分岐ロジック・判定チェックポイント表（**4 行、Stage 2 用**）・Stage 1 アルゴリズム節・ステップ読み込み契約を保持する
  - `phase-recovery-spec.md §5.2` の materialized binding として位置付け、spec 参照トークン（`spec§5.construction.<checkpoint>`）のみを持つ
  - Unit 001 の章立て（1. 目次 / 2. 分岐ロジック / 3. 判定チェックポイント表 / 4. ステップ読み込み契約 / 5. 汎用構造仕様）を機械的に流用し、Construction 固有要素（step 名、checkpoint 名、分岐条件）のみを差し替える
- **依存**:
  - `phase-recovery-spec.md`（`spec§5.construction.<checkpoint>` 参照）
  - 詳細ステップファイル（`01-setup.md` 〜 `04-completion.md`、`StepLoadingContract` の `detail_file` 列から参照）
- **公開インターフェース**:
  - `StepLoadingContract` テーブル（4 行、`step_id` = `construction.01-setup` 〜 `construction.04-completion`）
  - `RecoveryCheckpoint` テーブル（4 行: `construction.setup_done` / `design_done` / `implementation_done` / `completion_done`。Stage 1 の Unit 選定アルゴリズムは checkpoint 表外のアルゴリズム節として binding §3.1 相当に記述）
- **先頭宣言**: Unit 001 / 002 / Inception binding と同形式の Materialized Binding 宣言と `<!-- phase-index-schema: v1 -->` コメント

#### steps/common/phase-recovery-spec.md（更新・規範仕様層）

- **本 Unit での更新内容**:
  - **§3 拡張**: `ArtifactsState.phaseProgressStatus[construction]` の意味論を明示化（`unknown`: `units/*.md` なし、`incomplete`: 未完了 Unit あり、`completed`: 全 Unit 完了/取り下げ）。`ArtifactsStateRepository.snapshot()` が構築時に一度だけ計算する集約値として固定
  - **§4 拡張**: 判定順3（Construction 判定）に「`phaseProgressStatus[construction]=incomplete`」必須条件を追加。判定順4（Operations 判定）では Construction 完了後の Operations 未着手ケース（`construction_complete` info diagnostic 追加）を扱う。この拡張は `ConstructionStepResolver` を一切呼び出さず、phase-level 集約値のみで判定する（責務境界維持）
  - **§5.2 実装**: placeholder から実装に昇格:
    - Stage 1（Unit 特定）: `UnitSelectionRule` の決定ツリーを規範化（事前条件: `phaseProgressStatus[construction]=incomplete` が PhaseResolver で保証）
    - Stage 2（Step 特定）: 4 checkpoint の判定条件（Stage 1 はアルゴリズム節、Stage 2 は checkpoint 表として分離）
    - canonical path 正規化表（`unit_number` 3 桁/2 桁、`unit_slug`、`unit_stem` の使い分け。`unit_title` は path 構築に使わない）
    - `depth_level=minimal` 対応ルール
  - **§7 追加**: `dependency_block` 新 reason_code（blocking 分類）を追加
  - **§9 token grammar 正式化**: `spec§5.<phase>.<checkpoint>` を推奨形式として明記し、Unit 001/002 で使用していた省略形 `spec§5.<checkpoint>` は **後方互換 alias として当面許容**（Inception 暗黙形として §9 に明示）。Unit 003 の作業範囲では Inception binding を明示形に migrate するが、`spec_version` は minor 更新（v1.1）のままで済むよう、alias 許容を明文化する
  - **§10.2 追加**: Construction 適用例（`ArtifactsState` サンプル + 4 checkpoint の判定例）
  - **spec_version**: v1.0 → v1.1（minor 更新。binding 追随は推奨だが必須ではない。省略形 alias で旧 binding も動作可能）
  - **placeholder 維持**: §5.3（Operations）は引き続き Unit 004 の responsibility として placeholder のまま
- **依存**: なし（本 Unit でも最下流の参照先）
- **公開インターフェース**: セクション番号（§1〜§10）と `spec§N.<phase>.<checkpoint>` 参照トークン

#### steps/inception/index.md（更新・Inception binding 層）

- **本 Unit での更新内容**:
  - §9 の token grammar 正式化に伴い、§3 チェックポイント表の `priority_order` 列を `spec§5.setup_done` → `spec§5.inception.setup_done` の明示形に更新
  - `spec§5.preparation_done` / `spec§5.intent_done` / `spec§5.units_done` / `spec§5.completion_done` も同様に明示形化
  - ヘッダ summary の更新（v1.0 → v1.1 への追従コメント、ただし binding_schema_version は v1 のまま）
- **依存**: `phase-recovery-spec.md`（拡張形式参照）
- **不変部分**: チェックポイント行の 5 行構造、input_artifacts、§3.1 論理インターフェース契約

#### steps/common/compaction.md（更新・呼び出し層その1）

- **本 Unit での更新内容**:
  - 暫定ディスパッチャの「phase 別 result テーブル」を更新:
    - Construction 行: `None`（暫定ディスパッチャ）→ `construction.<step_id>`（`ConstructionStepResolver` 経由の正式ルート）
    - Operations 行: 引き続き暫定ディスパッチャ（Unit 004 で解消予定）
  - 「復帰フローの確認手順」内の Construction 案内を更新: `steps/construction/index.md` を読み込み → `judge()` 契約経由で `step_id` を決定 → 契約テーブルから `detail_file` を解決
- **不変部分**: `automation_mode` 復元手順（手順1〜5）は diff 上変更なし
- **契約層の依存**: `RecoveryJudgmentService.judge()`

#### steps/common/session-continuity.md（更新・呼び出し層その2）

- **本 Unit での更新内容**:
  - フェーズ別進捗源テーブルの Construction 行を更新: 現在の「Unit 定義ファイル（`story-artifacts/units/*.md`）の「実装状態」セクション（Unit 003 でインデックス化予定）」から「`judge()` 契約経由の `step_id` 決定（`steps/construction/index.md` binding + `phase-recovery-spec.md §5.2` 規範仕様）」に更新
  - Operations 行は変更なし（Unit 004 で更新予定）

#### skills/aidlc/SKILL.md（更新）

- **本 Unit での更新内容**:
  - 共通初期化フロー「ステップ4: フェーズステップ読み込み」の construction 行を更新:
    - 現在: `steps/construction/01-setup.md → 02-design.md → 03-implementation.md → 04-completion.md`（Unit 003 でインデックス化予定）
    - 更新後: `steps/construction/index.md`
- **不変ルール整合**: 「ステップファイル読み込みは省略不可」に抵触しないよう、`index.md` を必須読み込み対象として位置付け、詳細ファイルは契約テーブル経由で必要時ロード

#### steps/construction/01-setup.md 〜 04-completion.md（更新・詳細手順ファイル）

- **本 Unit での更新内容**（各ファイル共通）:
  - インデックスに集約される分岐・判定の重複記述を除去:
    - `automation_mode` 分岐の繰り返し説明
    - エクスプレスモード分岐の繰り返し説明
    - AI レビュー分岐（`review-flow.md` 参照への置換）
    - `depth_level` 分岐の繰り返し説明
    - Phase 1/Phase 2 の責務宣言（インデックスに一元化）
  - 残す内容:
    - 各ステップの具体的な実行手順（ステップ番号付き操作列）
    - Self-Healing ループ本体（03-implementation.md）
    - Unit 完了時の必須作業手順（04-completion.md）
    - エラー分類判定テーブル（03-implementation.md）
    - 対話規約の具体ルール（01-setup.md）

#### skills/aidlc/scripts/verify-construction-recovery.sh（新規）

- **責務**:
  - Construction 固有の検証ケース（c1〜c7）の fixture を生成する
  - Unit 002 の `verify-inception-recovery.sh` と同じアーキテクチャ（`FIXTURE_CONTENT` グローバル変数パターン、`$()` 禁止準拠、ディレクトリトラバーサル対策、終了コード規約準拠）
  - 各ケースで期待値（`expected_phase` / `expected_step_id` / `expected_diagnostics` / `spec_refs`）を出力する
- **入力**:
  - `--case <case_id>`: ケース識別子（`normal-unit-setup` / `normal-unit-design` / `normal-unit-implementation` / `normal-unit-completion` / `multi_unit_in_progress` / `dependency_block` / `all_units_completed`）
  - `--dest <path>`: セットアップ先ディレクトリ（デフォルト: `.aidlc/cycles/vTEST-<case>`）
  - `--clean`: 既存のテストディレクトリを削除してから作成
  - `--dry-run`: 実際のファイル作成は行わず、作成予定のファイルリストのみ表示
- **成功時出力**:

  ```text
  verify-case:<case>:<dest>:setup-ready
  expected_phase:<期待値>
  expected_step_id:<期待値>
  expected_diagnostics:<warning種別リスト、なければ'none'>
  spec_refs:<照合すべきspec§N参照のセミコロン区切りリスト>
  ```

  - 終了コード: `0`
  - 出力先: stdout
- **エラー時出力**:

  ```text
  【verify-construction-recovery エラー】
  理由: <エラー内容>
  ```

  - 終了コード: `1`（一般エラー）、`2`（引数エラー）
  - 出力先: stderr
- **セキュリティ**:
  - `--dest` の絶対パス拒否、`..` セグメント拒否、`//` 拒否、`^[a-zA-Z0-9._/-]+$` 文字制限
  - `--clean` は `--dest` バリデーションの**後**に実行する（ディレクトリトラバーサル先の誤削除防止）
- **実装制約**:
  - `$()` コマンド置換禁止（`FIXTURE_CONTENT` グローバル変数パターン）
  - `set -euo pipefail`
  - `bin/check-bash-substitution.sh` 準拠

## API 設計（インターフェース契約）

### 公開 API（契約層、Unit 002 から不変）

`RecoveryJudgmentService.judge()` の契約は Unit 002 で確立済み。Unit 003 で**変更しない**。

```text
operation: judge                           # 唯一の公開 API (spec §6)
signature: judge(artifacts_state: ArtifactsState) -> PhaseRecoveryJudgment
semantics:
  - PhaseResolver.resolvePhase() が先に評価される (spec §4)
  - 結果が Construction の場合、ConstructionStepResolver.determine_current_step() (spec §5.2) が呼ばれる  ★Unit 003 で追加
  - 戻り値は result + diagnostics[] の 2 フィールド分離形式 (spec §6)
  - blocking undecidable は automation_mode=semi_auto でも自動継続禁止 (spec §8)
```

### 非公開下位契約（新設）

```text
interface PhaseLocalStepResolver:
  method determine_current_step(artifacts_state: ArtifactsState) -> StepResolution

class ConstructionStepResolver implements PhaseLocalStepResolver:    # Unit 003 新設
  # 事前条件: PhaseResolver 側で phaseProgressStatus[construction]=incomplete が保証されている
  method determine_current_step(artifacts_state):
    1. outcome = UnitSelectionRule.selectUnit(artifacts_state)         # Stage 1
    2. if outcome == ConflictDetected(multi_unit_in_progress):
         return StepResolution(result=undecidable:conflict, diagnostics=[...])
    3. if outcome == DependencyBlock(blocked_units):
         return StepResolution(result=undecidable:dependency_block, diagnostics=[...])
    4. if outcome == UserSelectionRequired(candidates):
         return StepResolution(result=None, diagnostics=[user_selection_required(candidates)])
    5. # outcome is UnitSelected(currentUnit) — non-nullable
    6. step_id = evaluate_checkpoints(outcome.currentUnit, artifacts_state)    # Stage 2
    7. return StepResolution(result=step_id, diagnostics=[...])
    # 注: AllUnitsCompleted は本 resolver では発生しない (PhaseResolver が吸収)
```

### Stage 1 の決定ツリー（宣言的）

```text
precondition (PhaseResolver 側で保証):
  phaseProgressStatus[construction] = incomplete    # = |pending_units| > 0 が保証される

inputs:
  units = scan(story-artifacts/units/*.md) → List<UnitReference>
  automation_mode = artifacts_state.automation_mode

sets:
  in_progress_units = { u ∈ units | u.status = 進行中 }
  executable_units  = { u ∈ units | u.status = 未着手 ∧ u.dependencies ⊆ {完了, 取り下げ} }
  pending_units     = { u ∈ units | u.status ∈ {未着手, 進行中} }

decision:
  if |in_progress_units| ≥ 2:                                  → ConflictDetected(multi_unit_in_progress)
  if |in_progress_units| = 1:                                  → UnitSelected(in_progress_units[0])
  if |executable_units| = 0:                                   → DependencyBlock(pending_units)
  if |executable_units| = 1:                                   → UnitSelected(executable_units[0])
  if |executable_units| ≥ 2 ∧ automation_mode = semi_auto:     → UnitSelected(min_by_number(executable_units))
  if |executable_units| ≥ 2 ∧ automation_mode = manual:        → UserSelectionRequired(executable_units)
```

**備考**: `AllUnitsCompleted` のケースは `PhaseResolver` 側で `phaseProgressStatus[construction]=completed` として吸収されるため、`ConstructionStepResolver` に到達した時点では `|pending_units| > 0` が事前条件として成立している。これにより Stage 1 は nullable な結果を返さず、すべての outcome が単一の有効状態を表現する。

### Stage 2 の checkpoint 評価順

```text
Stage 2 (currentUnit 既定):
  1. evaluate construction.setup_done
     if NOT met → return construction.01-setup
  2. evaluate construction.design_done (depth_level=minimal の場合は設計省略記録で代替)
     if NOT met → return construction.02-design
  3. evaluate construction.implementation_done
     if NOT met → return construction.03-implementation
  4. evaluate construction.completion_done
     if NOT met → return construction.04-completion
  5. all met → 次周回の Stage 1 へ。次回以降、PhaseResolver 側で phaseProgressStatus[construction] が completed に遷移した時点で Construction 判定は skip される
```

### canonical path 正規化表（spec §5.2 内で固定）

| 対象 | キー | フォーマット | 例 |
|------|------|-------------|----|
| Plan | `unit_number` (3桁) | `plans/unit-{NNN}-plan.md` | `unit-003-plan.md` |
| Unit 定義 | `unit_number` + `unit_slug` | `story-artifacts/units/{NNN}-{slug}.md` | `003-construction-phase-index.md` |
| History | `unit_number` 下 2 桁 | `history/construction_unit{NN}.md` | `construction_unit03.md` |
| Domain Model | `unit_number` + `unit_stem` | `design-artifacts/domain-models/unit_{NNN}_{stem}_domain_model.md` | `unit_003_construction_phase_index_domain_model.md` |
| Logical Design | `unit_number` + `unit_stem` | `design-artifacts/logical-designs/unit_{NNN}_{stem}_logical_design.md` | `unit_003_construction_phase_index_logical_design.md` |
| Verification | `unit_number` + `unit_stem` | `construction/units/unit_{NNN}_{stem}_verification.md` | `unit_003_construction_phase_index_verification.md` |
| Review Summary | `unit_number` (3桁) | `construction/units/{NNN}-review-summary.md` | `003-review-summary.md` |

- `unit_slug`: Unit 定義ファイル `{NNN}-{slug}.md` の slug 部分（ケバブケース、例: `construction-phase-index`）
- `unit_stem`: `unit_slug` をアンダースコア化したもの（例: `construction_phase_index`）。path 構築専用のキー
- `unit_title`: 表示用タイトル（Unit 定義ファイルの `# Unit: ...` 見出し）。path 構築には一切使用しない（日本語や任意文字列を許容するが、命名規約には影響しない）

## エラーハンドリング方針

Unit 002 で確立した方針を Construction にも適用:

- **blocking**: `undecidable:missing_file` / `undecidable:conflict` / `undecidable:format_error` / `undecidable:dependency_block`（Unit 003 で追加）
- **warning**: `diagnostics[]` に追加するのみ。`result` 判定は継続可能
- **info**: `construction_complete`（Unit 003 で追加）は `diagnostics` に追加し、`PhaseResolver` が消費

## フロー（シーケンス）

### フロー1: AI エージェントの Construction Phase 初回ロード

```text
1. SKILL.md 共通初期化フロー
   └ ステップ4: construction 分岐 → steps/construction/index.md を読み込む
2. index.md の § 1 目次と § 4 ステップ読み込み契約テーブルを参照
3. 引数がない or step_id 未指定 → 既定ルート
   └ compaction 復帰コンテキストなら judge() を呼んで step_id を決定
   └ 新規開始なら construction.01-setup
4. 契約テーブルから step_id に対応する detail_file を解決
5. detail_file のみを追加ロード（インデックスに集約された共通知識は再ロード不要）
```

### フロー2: コンパクション復帰時の Construction 判定

```text
1. compaction.md を読み込み、phase 別 result テーブルを参照
2. ArtifactsStateRepository.snapshot(cycleRoot) が phaseProgressStatus[construction] を計算
3. RecoveryJudgmentService.judge(artifactsState) を呼ぶ
4. PhaseResolver.resolvePhase() が評価される (集約値参照のみ)
   ├ conflict 検出 → 終了
   ├ Operations 判定 → 終了
   ├ Construction 判定:
   │   ├ units/*.md 存在 ∧ phaseProgressStatus[inception]=completed ∧ phaseProgressStatus[construction]=incomplete → construction 確定
   │   └ 上記条件を満たさない (例: phaseProgressStatus[construction]=completed) → skip
   ├ Inception 判定 → 終了
   └ 新規開始フォールバック → 終了
5. construction 確定の場合のみ ConstructionStepResolver.determine_current_step() が step_id を返す
6. index.md の StepLoadingContract から detail_file を解決してロード
```

**責務境界の明示**: ステップ 4 の Construction 判定は `ArtifactsState.phaseProgressStatus[construction]` の集約値だけを参照し、`ConstructionStepResolver` を一切呼び出さない。これにより `PhaseResolver` → `ConstructionStepResolver` の依存は発生せず、2 段レゾルバ構造の責務境界が保たれる。

## 検証方針

### 静的検証

- `steps/construction/index.md` の 4 checkpoint 行（Stage 2 の step 進行判定）が `phase-recovery-spec.md §5.2` の checkpoint ルールと 1 対 1 対応、かつ Stage 1 のアルゴリズム節が §5.2 の Unit 選定決定ツリーと対応
- `spec§5.construction.<checkpoint>` 参照トークンがすべて spec §5.2 内に実在
- Inception binding の token 形式更新が全行に適用されている

### Construction 固有検証（c1〜c7、verify-construction-recovery.sh）

各ケースを fixture として生成し、期待値を静的照合:

| case | 事前状態 | expected_phase | expected_step_id | expected_diagnostics |
|------|---------|----------------|------------------|---------------------|
| `normal-unit-setup` | Unit 進行中 1 件、plan 作成済み、計画承認記録なし | `construction` | `construction.01-setup` | `none` |
| `normal-unit-design` | Unit 進行中 1 件、plan 承認済み、設計未着手 | `construction` | `construction.02-design` | `none` |
| `normal-unit-implementation` | Unit 進行中 1 件、設計承認記録あり、実装未着手 | `construction` | `construction.03-implementation` | `none` |
| `normal-unit-completion` | Unit 進行中 1 件、実装承認記録あり、完了処理未着手 | `construction` | `construction.04-completion` | `none` |
| `multi_unit_in_progress` | 2 Unit 同時に「進行中」 | `undecidable:conflict` | `none` | `none` |
| `dependency_block` | 全 Unit 未着手、どれも依存未達 | `undecidable:dependency_block` | `none` | `none` |
| `all_units_completed` | 全 Unit が完了、operations/progress.md なし | `operations`（PhaseResolver が吸収） | `None`（Operations binding まだ placeholder） | `construction_complete` |

**事前状態の明示**: 各 case は単値の expected_step_id が一意に決まるよう、「前段 checkpoint までは達成済み、当該 checkpoint は未達成」という形で定義する。例えば `normal-unit-design` は `setup_done=true ∧ design_done=false` の境界状態であり、次に進むべき step は `construction.02-design`（設計ステップに進む）となる。

### 最小実地回帰検証

- Unit 001 自身を「完了 Unit」として認識できることを確認
- vTEST-construction-conflict fixture で `undecidable:conflict`（multi_unit_in_progress）が返ることを確認

### トークン計測

ベースライン（v2.2.3）と実装後（v2.3.0 Unit 003）の初回ロードを tiktoken（cl100k_base）で計測。目標 17,980 tok 以下。

## リスクと留意事項

- **Stage 1 決定ツリーの完全性**: 6 つの分岐すべてが単値の `UnitSelectionOutcome` バリアント（`UnitSelected` / `UserSelectionRequired` / `ConflictDetected` / `DependencyBlock`）を返すことを決定論的に保証する。事前条件 `phaseProgressStatus[construction]=incomplete` により `|pending_units| > 0` が保証されるため Construction 完了状態は `PhaseResolver` 側で吸収される。`|executable_units| ≥ 2 ∧ automation_mode=manual` は `UserSelectionRequired(candidates)` バリアントを返し、nullable な currentUnit は型レベルで排除されている
- **§4 拡張の安全性**: `PhaseResolver` 判定順3 の Construction 完了条件追加は `ArtifactsState.phaseProgressStatus[construction]` の集約値を参照するだけで、`ConstructionStepResolver` への仮呼び出しは一切発生しない。これにより `PhaseResolver` → `ConstructionStepResolver` の依存を排除し、2 段レゾルバ構造の責務境界を維持する
- **token grammar 変更の波及**: `spec§5.<checkpoint>` の省略形は後方互換 alias として §9 に明記されるため、Inception binding の即時更新は必須ではない。ただし Unit 003 の作業範囲では cleanliness 目的で Inception binding も明示形 `spec§5.inception.<checkpoint>` に migrate する（5 行すべて）
- **Construction ステップファイル重複除去の線引き**: どこまでをインデックスに集約するかは設計判断が必要。Self-Healing ループ本体・エラー分類判定テーブル等の具体ロジックは詳細ファイルに残し、分岐判定（`automation_mode` 分岐等）のみをインデックスに集約する

## Unit 001 / 002 との整合性

- Unit 001 の章立て・列スキーマ・`StepLoadingContract` 形式・`<!-- phase-index-schema: v1 -->` コメントはすべて流用（変更なし）
- Unit 002 の `PhaseRecoverySpec` / `RecoveryCheckpoint` / `PhaseLocalStepResolver` / `RecoveryJudgmentService` 等の概念はすべて流用（変更なし）
- 新規追加: `ConstructionStepResolver` / `UnitSelectionRule` / `UnitSelectionOutcome` / `UnitReference` / `ConstructionPathNormalizer` / `dependency_block` reason_code / `construction_complete` info diagnostic
- 破壊的変更なし: 既存 API は不変、既存 token の省略形は §9 正式化により「暗黙形」から「明示形への移行」のみ（Inception binding の同時更新で対応）

## Unit 004 / 006 への接続点

- **Unit 004 (Operations)**: `OperationsStepResolver` を `PhaseLocalStepResolver` の派生として追加する際、本 Unit と同じパターン（2 段決定が不要なシンプルな step 判定、または Operations 固有の構造）を適用する。`phase-recovery-spec.md §5.3` の placeholder を実装に昇格、`§10.3` に Operations 適用例を追加
- **Unit 006 (計測・クローズ)**: 全フェーズ横断の実地回帰検証（Inception + Construction + Operations の統合検証）を実施。本 Unit の最小実地回帰（Unit 001 完了認識、multi_unit_in_progress conflict）はあくまで Construction 単体の検証範囲
