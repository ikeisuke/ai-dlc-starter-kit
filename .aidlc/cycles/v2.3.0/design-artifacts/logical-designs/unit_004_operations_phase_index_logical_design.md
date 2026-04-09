# 論理設計: Unit 004 Operations Phase インデックス化

## 概要

Unit 001（Inception パイロット）で確立したフェーズインデックス構造、Unit 002（規範仕様）で確立した **Normative Spec + Materialized Binding** パターン、Unit 003（Construction Phase Index）で確立した phase-local resolver の追加パターンを **Operations Phase に展開**する論理設計を定義する。本 Unit の成果物もコードではなくドキュメントが主体であり、Unit 002/003 と同じドキュメント層アーキテクチャを適用する。加えて、Operations 固有の検証のために `verify-operations-recovery.sh` を新規追加する（Unit 002 の `verify-inception-recovery.sh` および Unit 003 の `verify-construction-recovery.sh` と同じアーキテクチャ）。

**重要**: この論理設計では**コードは書かず**、ドキュメント構成・セクション階層・参照関係・検証スクリプトの I/F のみを定義する。

## アーキテクチャパターン

**パターン名**: **Normative Spec + Materialized Binding**（Unit 002/003 と同一、Operations 向けの展開）

**選定理由**（Unit 002/003 の理由に追記）:

- Unit 002 で確立した「spec 1 箇所 + binding 複数」の構造を Operations にも適用することで、`phase-recovery-spec.md` を全フェーズ横断の唯一の正本として維持できる
- Operations は Inception と同様の直線的進行のため、Construction の `UnitSelectionRule` のような複雑な決定ツリーは不要。`OperationsStepResolver` は Inception の `InceptionStepResolver` と同型のシンプルな checkpoint 評価のみ
- ただし Operations Phase は AI-DLC サイクルの最終フェーズで、Construction 完了直後に新規開始される。この遷移を blocking しないために **bootstrap 分岐**を `OperationsStepResolver` に追加する（Inception/Construction にはない Operations 固有の要素）

**依存方向**:

```text
compaction.md / session-continuity.md                 (呼び出し層)
        │
        ▼
RecoveryJudgmentService.judge()                        (唯一の公開 API、spec §6 で定義)
        │
        ├─→ PhaseResolver.resolvePhase()               (spec §4、判定順2 で Operations 判定。Construction 完了後の bootstrap ケースは spec §4.1 末尾の特殊分岐で `result=operations` + `construction_complete` info)
        │
        ├─→ InceptionStepResolver                      (spec §5.1、Unit 002)
        │       │
        │       ▼
        │  steps/inception/index.md (binding)
        │       │
        │       ▼
        │  steps/common/phase-recovery-spec.md         (規範仕様、§5.1 Inception)
        │
        ├─→ ConstructionStepResolver                   (spec §5.2、Unit 003)
        │       │
        │       ▼
        │  steps/construction/index.md (binding)
        │       │
        │       ▼
        │  steps/common/phase-recovery-spec.md         (規範仕様、§5.2 Construction)
        │
        └─→ OperationsStepResolver                     (spec §5.3、Unit 004 新設、非公開下位契約)
                │
                ├─→ OperationsBootstrapRule            (bootstrap 分岐判定)
                │
                ▼
          steps/operations/index.md (binding 層)        (spec§5.operations.<checkpoint> 参照)
                │
                ▼
          steps/common/phase-recovery-spec.md           (規範仕様、§5.3 Operations)
```

一方向の参照関係を維持。循環依存なし。`OperationsStepResolver` → spec §5.3 → `RecoveryJudgmentService` の循環が生じないよう、spec 側は `PhaseLocalStepResolver` の**契約のみ**を定義し、実装コンテキスト（呼び出し元）には言及しない。

**境界の整理**（Unit 002/003 と同様）:

- **呼び出し層（`compaction.md` / `session-continuity.md`）は `judge()` 契約を介して扱う**: Unit 004 完了後、`compaction.md` の Operations 行は「`judge()` の結果を消費する」記述になり、現行ルート委譲（`step=None` 時の暫定ディスパッチャ）は解消される
- **bootstrap 分岐の責務分離**: bootstrap 判定は `OperationsBootstrapRule` に閉じ、`OperationsStepResolver.determine_current_step()` は単純に「bootstrap か否か」のフラグを得て分岐する。`OperationsBootstrapRule` の判定条件は spec §5.3 で固定
- **手順記述上の区別**: `compaction.md` の本文では引き続き抽象レベルの記述（`judge()` を呼ぶ）を維持し、Operations 固有の判定条件（4 checkpoint 評価ロジック等）を重複記述しない

## コンポーネント構成

### レイヤー / モジュール構成（ドキュメントファイル単位）

```text
skills/aidlc/
├── SKILL.md                                ← 更新 (共通初期化フローの operations 行を index.md のみに)
├── steps/
│   ├── common/
│   │   ├── phase-recovery-spec.md          ← 更新 (§1.3 / §2.2 / §5.3 実装 / §6 placeholder 削除 / §12 Operations 適用例)
│   │   ├── compaction.md                   ← 更新 (Operations 行を正式ルートに昇格、戻り値テーブルに operations + StepId 行追加)
│   │   └── session-continuity.md           ← 更新 (Operations 行を judge() 契約経由に更新)
│   └── operations/
│       ├── index.md                        ← 新規 (Operations binding 層、4 checkpoint × 4 step_id × 4 detail_file の 1:1 対応)
│       ├── 01-setup.md                     ← 更新 (重複除去)
│       ├── 02-deploy.md                    ← 更新 (重複除去、ステップ1-7 全体の本体は維持)
│       ├── 03-release.md                   ← 更新 (重複除去)
│       └── 04-completion.md                ← 更新 (重複除去)
└── scripts/
    └── verify-operations-recovery.sh       ← 新規 (Operations 版 fixture 生成スクリプト)
```

### コンポーネント詳細

#### steps/operations/index.md（新規・Operations binding 層）

Unit 001 で確立した汎用構造仕様に従い、以下の章立てで構成する:

```markdown
<!-- phase-index-schema: v1 -->
<!-- Materialized Binding 宣言 -->

# Operations Phase インデックス

[概要]

## 1. 目次・概要        ← 4 step_id の一覧
## 2. 分岐ロジック       ← Operations 固有の分岐（automation_mode、project.type、変更なしスキップ等）
## 3. 判定チェックポイント表   ← 4 checkpoint × 5 列
### 3.1 論理インターフェース契約  ← judge() 契約経由 + result + diagnostics[]
## 4. ステップ読み込み契約    ← 4 step_id → 4 detail_file の 1:1 対応
## 5. 汎用構造仕様         ← Unit 001 から継承
```

**checkpoint 表の具体値**（spec §5.3 と 1:1 対応、setup_done を「`operations/progress.md` の存在」と再定義してファイル境界に整合）:

| checkpoint_id | 判定条件 | input_artifacts | priority_order | undecidable_return | user_confirmation_required |
|---------------|---------|-----------------|----------------|--------------------|----------------------------|
| `operations.setup_done` | `operations/progress.md` が**存在する**（01-setup.md による初期化完了） | `operations/progress.md` | `spec§5.operations.setup_done` | `spec§6` | `spec§8` |
| `operations.deploy_done` | `operations/progress.md` のステップ1-7 のすべてが「完了」or「スキップ」（02-deploy.md の全責務完了 = PR 準備完了） | `operations/progress.md`, `operations/deployment_checklist.md`, `operations/cicd_setup.md`, `operations/monitoring_strategy.md`, `operations/post_release_operations.md` | `spec§5.operations.deploy_done` | `spec§6` | `spec§8` |
| `operations.release_done` | `history/operations.md` に「PR Ready 化」記録あり（03-release.md 完了基準到達） | `history/operations.md` | `spec§5.operations.release_done` | `spec§6` | `spec§8` |
| `operations.completion_done` | `history/operations.md` に「PR マージ」記録あり（04-completion.md PR マージ後手順実施済み） | `history/operations.md` | `spec§5.operations.completion_done` | `spec§6` | `spec§8` |

**bootstrap 分岐記述**: §3 の冒頭に「bootstrap 分岐: `phaseProgressStatus[construction]=completed ∧ operations/progress.md 未存在 → operations.01-setup`（`spec§5.operations.bootstrap` 参照）」を明記する。

**StepLoadingContract**（§4）:

| step_id | detail_file | ロードタイミング |
|---------|------------|----------------|
| `operations.01-setup` | `steps/operations/01-setup.md` | setup_done=false 判定時 |
| `operations.02-deploy` | `steps/operations/02-deploy.md` | deploy_done=false 判定時 |
| `operations.03-release` | `steps/operations/03-release.md` | release_done=false 判定時 |
| `operations.04-completion` | `steps/operations/04-completion.md` | completion_done=false 判定時 |

#### phase-recovery-spec.md（更新・規範仕様）

§5.3 を placeholder から実装に昇格させる。新しいセクション構成:

```markdown
### §5.3 Operations Phase の step 判定

#### §5.3.0 bootstrap 分岐
phaseProgressStatus[construction]=completed ∧ operations/progress.md 未存在
→ result=operations.01-setup（正常な未着手状態、missing_file ではない）

#### §5.3.1 直線的 checkpoint 評価（4 checkpoint）

##### §5.3.1.1 spec§5.operations.setup_done
- 対応 step_id: operations.01-setup
- 判定条件: operations/progress.md が**存在する**（01-setup.md が初期化済み）
- 未達成時: operations.01-setup を返す（progress.md 未存在 ∧ bootstrap でない場合は §5.3.0 で吸収済み）

##### §5.3.1.2 spec§5.operations.deploy_done
- 対応 step_id: operations.02-deploy
- 判定条件: operations/progress.md のステップ1-7 のすべてが「完了」or「スキップ」
- 未達成時: operations.02-deploy を返す

##### §5.3.1.3 spec§5.operations.release_done
- 対応 step_id: operations.03-release
- 判定条件: history/operations.md に「PR Ready 化」記録あり
- 未達成時: operations.03-release を返す

##### §5.3.1.4 spec§5.operations.completion_done
- 対応 step_id: operations.04-completion
- 判定条件: history/operations.md に「PR マージ」記録あり
- 未達成時: operations.04-completion を返す
- 全達成時: operations.04-completion を返す（次サイクル準備可能状態）

#### §5.3.2 戻り値
StepResolution 型に従う

#### §5.3.3 異常系の扱い
- bootstrap でない ∧ Operations 進行中マーカーあり ∧ progress.md 欠損 → undecidable:missing_file
- progress.md 存在するがパース不能 → undecidable:format_error
```

§12（Operations 適用例）を新規追加（Construction §11 と同様の構造、bootstrap 分岐の判定例を含む）。

#### scripts/verify-operations-recovery.sh（新規）

**目的**: Operations Phase の判定仕様に対する fixture 生成と期待値出力。Unit 002 の `verify-inception-recovery.sh` および Unit 003 の `verify-construction-recovery.sh` と同じアーキテクチャ。

**インターフェース**:

```text
verify-operations-recovery.sh --case <case_id> [--dest <dir>] [--clean] [--dry-run]
```

| 引数 | 必須 | 説明 |
|------|------|------|
| `--case CASE_ID` | Yes | 再現するケース識別子 |
| `--dest DIR` | No | セットアップ先ディレクトリ（デフォルト: `.aidlc/cycles/vTEST-<case>`） |
| `--clean` | No | 既存ディレクトリを削除してから作成 |
| `--dry-run` | No | 実ファイルを作成せず作成予定リストのみ表示 |

**有効な case_id**: `normal-deploy-fresh`、`normal-deploy-progress`、`normal-release`、`normal-completion`、`bootstrap-from-construction`、`abnormal-operations_in_progress_missing_progress`、`abnormal-progress_corrupt`

**出力フォーマット**:

```text
verify-case:<case>:<dest>:setup-ready
expected_phase:<期待 phase>
expected_step_id:<期待 step_id または 'none'>
expected_diagnostics:<diagnostics 種別のセミコロン区切り または 'none'>
spec_refs:<照合すべき spec 参照のセミコロン区切り>
```

**セキュリティ要件**（Unit 003 の `verify-construction-recovery.sh` と同等）:

- `--dest` ディレクトリトラバーサル対策: 絶対パス禁止、`..` 文字列全体禁止、`.aidlc/cycles/vTEST-` プレフィックス必須、連続スラッシュ禁止、文字クラス制限
- `bin/check-bash-substitution.sh` 準拠（`$()` および backtick の使用禁止、FIXTURE_CONTENT グローバル変数パターンを採用）
- 引数は二重引用符で囲む

**終了コード**: 0=成功、1=一般エラー、2=引数エラー

## 7 検証ケースの fixture 仕様

| # | case_id | fixture 内容 | 期待結果 |
|---|---------|------------|---------|
| 1 | `normal-deploy-fresh` | inception/progress.md 全完了、構築済み Unit 全完了、operations/progress.md 存在（ステップ1-7 すべて未着手）、history/operations.md 空 | `expected_phase=operations`、`expected_step_id=operations.02-deploy`（setup_done=true、deploy_done=false） |
| 2 | `normal-deploy-progress` | 上記 + operations/progress.md ステップ1-3 完了、ステップ4-7 進行中 | `operations.02-deploy`（境界条件中間） |
| 3 | `normal-release` | operations/progress.md ステップ1-7 すべて完了/スキップ、history に PR Ready 化記録なし | `operations.03-release` |
| 4 | `normal-completion` | 上記 + history に PR Ready 化記録あり、PR マージ記録なし | `operations.04-completion` |
| 5 | `bootstrap-from-construction` | inception/progress.md 全完了、構築済み Unit 全完了、operations/progress.md **未存在**、history/operations.md 未存在 | `operations.01-setup`（bootstrap 分岐、`expected_diagnostics` に `construction_complete` を含む） |
| 6 | `abnormal-operations_in_progress_missing_progress` | history/operations.md に Operations 進行中記録あり、operations/progress.md 欠損 | `result=undecidable:missing_file` |
| 7 | `abnormal-progress_corrupt` | operations/progress.md 存在するが空ファイル or パース不能 | `result=undecidable:format_error` |

**カバレッジ**: 4 step_id すべてが少なくとも 1 つの fixture でテストされる（`operations.01-setup` は case 5、`operations.02-deploy` は cases 1/2、`operations.03-release` は case 3、`operations.04-completion` は case 4）。異常系 2 種類（missing_file / format_error）も網羅。

## 既存ファイルへの変更

### compaction.md

戻り値テーブルに `operations | StepId（例: operations.02-deploy）` 行を追加し、暫定ディスパッチャ記述を「`steps/operations/index.md` の契約テーブルから `step_id` に対応する `detail_file` を解決してロード」に更新する。`construction` 行は Unit 003 で確立した形式を維持。

### session-continuity.md

Operations 行を「`operations/progress.md`（Unit 004 でインデックス化予定）」から「`operations/progress.md` + `judge()` 契約経由の `step_id` 決定 / `steps/operations/index.md`（binding） + `phase-recovery-spec.md` §5.3（規範仕様）」に更新。Construction 行は Unit 003 形式を維持。

### SKILL.md

共通初期化フロー「ステップ4: フェーズステップ読み込み」の `operations` 行を `steps/operations/01-setup.md → 02-deploy.md → 03-release.md → 04-completion.md` から `steps/operations/index.md` のみに変更。

### Operations ステップファイル（01-04）の重複除去

各ファイルから以下の重複記述を除去し、index.md への参照に置き換える:

- 01-setup.md: プリフライト、Depth Level、`automation_mode` 分岐、AI レビュー分岐
- 02-deploy.md: ステップ1の変更確認の `automation_mode` 分岐（残す: `project.type` 依存スキップ、対話形式の手順本体、リリース準備サブステップ参照）
- 03-release.md: 実行ルールの `automation_mode` 分岐（残す: 完了基準、PR Ready 化〜マージの実体）
- 04-completion.md: バックトラックフローの分岐（残す: PR マージ後手順、worktree フロー本体、次サイクル開始フロー）

## 公開 API と内部実装の境界

| カテゴリ | 該当要素 | アクセス |
|---------|---------|---------|
| 公開 API | `RecoveryJudgmentService.judge()` | 呼び出し層から使用 |
| 非公開下位契約 | `PhaseLocalStepResolver.determine_current_step()` | `RecoveryJudgmentService` 内部のみ |
| 規範仕様 | `phase-recovery-spec.md` の判定ルール | `PhaseLocalStepResolver` の実装が参照 |
| binding 層 | `steps/operations/index.md` の checkpoint テーブル | `OperationsStepResolver` の実装が参照 |
| bootstrap 規則 | `OperationsBootstrapRule.isBootstrap()` | `OperationsStepResolver` 内部のみ |

## 障害分離

| 障害 | 検出層 | 戻り値 | 呼び出し層の対応 |
|------|-------|-------|----------------|
| operations/progress.md 欠損（Operations 進行中マーカーあり） | `OperationsStepResolver.validateArtifacts` | `undecidable:missing_file` | ユーザー確認必須 |
| operations/progress.md パース不能 | `OperationsStepResolver.validateArtifacts` | `undecidable:format_error` | ユーザー確認必須 |
| bootstrap 状態（progress.md 未存在 + Construction 完了） | `OperationsBootstrapRule.isBootstrap` | `step_id=operations.01-setup`（正常系） | そのまま遷移 |
| v2.2.x 以前の構造残存 | `OperationsStepResolver.detectLegacyStructure` | `diagnostics[]` に `legacy_structure`（warning） | 警告表示 + マイグレーション案内、判定継続 |

## 設計トレードオフ

### 4 checkpoint vs 7 step（progress.md ベース）

**選定**: 4 checkpoint（現状ファイル境界に 1:1 対応）

**理由**:

- **代替案**: progress.md の 7 ステップに対応する 7 checkpoint を設計する
- **却下理由**: 7 checkpoint にすると `step_id → detail_file` の 1:1 が崩れ（複数 checkpoint が同じ detail_file を指す）、Materialized Binding 原則に反する。Inception の 5 checkpoint × 5 detail_file 構造との整合性も失われる
- **採用理由**: 4 checkpoint × 4 step_id × 4 detail_file の 1:1 対応により、`StepLoadingContract` が現実のファイル責務と矛盾しない。progress.md の細かい状態管理は `OperationsStepResolver` 内部で抽象化される

### bootstrap 分岐 vs missing_file

**選定**: bootstrap 分岐（Construction → Operations 初回遷移を正常系として扱う）

**理由**:

- **代替案**: `operations/progress.md` 未存在を一律 `undecidable:missing_file` として扱う
- **却下理由**: Operations Phase は AI-DLC サイクルの最終フェーズで、Construction 完了直後に新規開始される。この遷移を blocking すると正規ルートが自分で塞がれる
- **採用理由**: bootstrap 分岐を明示することで、「正常な未着手」と「異常な欠損」を構造的に区別できる。fixture o5 と o6 で両方を独立に検証可能

### Inception 同型 vs Construction 同型

**選定**: Inception 同型（直線的 checkpoint 評価）

**理由**:

- **代替案**: Construction の 2 段構造（Stage 1: 何かを選定 / Stage 2: checkpoint 評価）を採用する
- **却下理由**: Operations は Unit loop を持たず、選定対象がない。2 段構造は不要な複雑さの追加（過剰設計）
- **採用理由**: Inception の `InceptionStepResolver` と同型の単純な checkpoint 評価で十分。bootstrap 分岐のみ Operations 固有として追加する

## トークン予算の見積もり

| 項目 | サイズ |
|------|--------|
| `operations/index.md` 新設 | ≈ 5,000-6,000 tok（Construction の 6,092 tok と同程度を想定） |
| 既存 4 ステップファイルの重複除去 | -1,500〜-2,500 tok（Construction の純減 -2,554 tok を参考） |
| 純差分 | ≈ +3,000〜+4,500 tok（増加リスク）または -500〜+1,000 tok（最良ケース） |
| ベースライン（v2.2.3 現状） | 17,827 tok |
| 目標（Unit 004 完了後） | ≤ 17,827 tok |

**リスク**: Operations のステップファイルは Construction と異なり `04-completion.md`（3,252 tok）が重複除去対象が少ない可能性があり、純減が小さくなる可能性がある。設計段階で実測ベースラインと照合する。

## 関連 spec 参照トークン

Unit 003 で確立した推奨形式 `spec§5.<phase>.<checkpoint>` を Operations binding でも使用:

- `spec§5.operations.bootstrap`（bootstrap 分岐）
- `spec§5.operations.setup_done`
- `spec§5.operations.deploy_done`
- `spec§5.operations.release_done`
- `spec§5.operations.completion_done`

## Unit 005/006 への接続点

Unit 004 完了時点で `phase-recovery-spec.md §5` 配下のすべての phase（Inception §5.1 / Construction §5.2 / Operations §5.3）が実値化される。これにより:

- Unit 005（Tier2 統合）は Unit 001-004 で確立したインデックス構造を前提とした追加施策を実装可能
- Unit 006（計測・クローズ判断）は全 5 phase を一括検証可能（Inception / Construction / Operations の初回ロード token、復帰判定の正確性）
