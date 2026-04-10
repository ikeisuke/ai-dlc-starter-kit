# Unit 004 計画: Operations Phase インデックスのパイロット実装

## 目的

Unit 001（Inception Phase Index）/ Unit 003（Construction Phase Index）で確立した Materialized Binding パターンを Operations Phase に展開し、Operations 初回ロードを最適化する。`phase-recovery-spec.md §5.3`（現在 placeholder）を実値化し、`PhaseLocalStepResolver` の Operations 実装である `OperationsStepResolver` を追加する。

## 背景

- Unit 001 は Inception Phase Index を新設し、Phase Index 構造（目次 / 分岐 / 判定チェックポイント / ステップ読み込み契約 / 汎用構造仕様）の汎用スキーマを確立した
- Unit 002 は `phase-recovery-spec.md` を新設し、`PhaseResolver`（phase 層）+ `PhaseLocalStepResolver`（step 層）の 2 段レゾルバ構造と Materialized Binding パターンを規範化した
- Unit 003 は Construction Phase Index を新設し、Construction 固有の Unit loop 構造（Stage 1: UnitSelectionRule + Stage 2: 4 checkpoint）を実装した
- Operations Phase は Construction とは異なり Unit loop 構造を持たず、Inception と同様の直線的進行（progress.md ベース）であるため、判定仕様は Inception パターンに近い形になる
- 現状の `phase-recovery-spec.md §5.3` は placeholder のままで、Unit 004 で実値化することが Unit 001/002/003 から既定路線として設定されている

## スコープ

### 含むもの

- **Materialized Binding ファイル新設**: `skills/aidlc/steps/operations/index.md` を Unit 001/003 と同形式の章立て（目次 / 分岐ロジック / 判定チェックポイント表 / ステップ読み込み契約 / 汎用構造仕様）で作成
- **`phase-recovery-spec.md §5.3` 実値化**: placeholder から OperationsStepResolver の実装に昇格。Operations Phase の checkpoint を Unit 001 の汎用スキーマに従って定義（4 checkpoint × 4 step_id × 4 detail_file の 1:1 対応で現状ファイル境界に整合）
- **OperationsStepResolver の追加**: `PhaseLocalStepResolver` の Operations 実装。`ConstructionStepResolver` と異なり Unit loop は持たないため、Inception 同様の直線的 checkpoint 評価のみ
- **Construction → Operations bootstrap 分岐の明確化**: `phaseProgressStatus[construction]=completed ∧ operations/progress.md 未存在` を **正常な未着手状態**として認識し、`operations.01-setup` を返す bootstrap 分岐を spec §5.3 に明記する。`missing_file` 異常系は「Operations が既に進行中（history に記録あり）∧ progress.md 欠損」のケースに限定
- **既存 Operations ステップファイル（01-04）からの重複除去**: index.md に集約される分岐・判定・`automation_mode` 分岐・depth_level 分岐等の重複記述を除去
- **`compaction.md` / `session-continuity.md` / `SKILL.md` の更新**: Operations 行を「現行ルート維持」から「`phase-recovery-spec.md §5.3` 経由の正式ルート」に更新
- **Operations 固有検証スクリプト新設**: `skills/aidlc/scripts/verify-operations-recovery.sh`（Unit 002 の `verify-inception-recovery.sh` および Unit 003 の `verify-construction-recovery.sh` と同じアーキテクチャ）。Operations 固有の正常系（各 checkpoint 遷移）+ 異常系（progress.md 欠損 / format_error）の fixture を生成
- **トークン予算検証**: Operations 初回ロードが v2.2.3 ベースライン以下であることを計測

### 含まないもの

- Inception / Construction Phase Index の変更（Unit 001 / 003 で完了済み。Unit 004 では Operations のみを変更し、共通仕様 spec への追加更新は §5.3 を中心に最小限に留める）
- `phase-recovery-spec.md` の構造的変更（v1.1 → v2.0 への major 更新は不要、§5.3 の埋め込み + Operations 適用例 §12 追加の minor 更新で十分）
- 共通判定仕様そのものの策定（Unit 002 の責務、Unit 004 では Operations への適用のみ）
- `operations-release.md` のスクリプト化（Unit 005 の責務）
- Operations Phase の機能変更（既存ステップ手順は維持し、index.md への集約とコメントアウトのみ実施）
- v2.2.x 以前の Operations 構造への migration（Unit 002/003 と同じく forward-only アプローチ）

## 設計方針

- **Operations Phase は Inception パターンに近い**: Unit loop を持たず、`operations/progress.md` ベースで直線的に進行する。判定仕様は Inception の checkpoint 評価ルール（`§5.1.1` 〜 `§5.1.5`）と同じ構造をとる
- **2 段レゾルバ構造の維持**: `PhaseResolver`（spec §4）の判定順は変更しない。**判定順2** で Operations 判定（spec §4.1）+ Construction 完了後の bootstrap 経路は spec §4.1 末尾の特殊分岐で `result=operations` + `construction_complete` info 診断を返す。`OperationsStepResolver.determine_current_step()` を `PhaseLocalStepResolver` の Operations 実装として追加し、`PhaseResolver` が Operations と判定した場合に委譲する
- **checkpoint 設計（4 checkpoint, 4 step_id, 4 detail_file の 1:1 対応）**: Operations Phase の現状ファイル境界（`01-setup.md` / `02-deploy.md` / `03-release.md` / `04-completion.md`）に合わせて 4 checkpoint を定義し、各 checkpoint が 1 つの step_id + 1 つの detail_file に対応する形を採用する。`setup_done` を「`operations/progress.md` の存在」と再定義することで、ファイル境界と判定条件を完全に一致させる:
  - `operations.setup_done` → `operations.01-setup` → `01-setup.md` （初期セットアップ: `operations/progress.md` が**存在する** = 01-setup.md による初期化完了）
  - `operations.deploy_done` → `operations.02-deploy` → `02-deploy.md` （デプロイ実作業: progress.md ステップ1-7 すべてが「完了」or「スキップ」 = PR 準備完了）
  - `operations.release_done` → `operations.03-release` → `03-release.md` （リリース完了基準確認: history に「PR Ready 化」記録あり）
  - `operations.completion_done` → `operations.04-completion` → `04-completion.md` （次サイクルへの遷移: history に「PR マージ」記録あり）
- **checkpoint 数の妥当性**: Operations の現状ファイル境界に 1:1 で対応させるため 4 checkpoint。Construction と同じ 4 checkpoint × 5 列構造（`checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`）を維持
- **過剰適用の回避**: Inception の 5 step と異なり、Operations の進捗単位は 7 ステップ（progress.md）あるが、実体ファイルは 4 つに集約されている。判定 checkpoint を 7 にすると `step_id → detail_file` の 1:1 が崩れ Materialized Binding 原則に反するため、4 checkpoint で集約する設計を採用する
- **Unit 001/002/003 で確立した骨格スキーマは不変**: 列構造（5 列）と `<!-- phase-index-schema: v1 -->` コメントは維持
- **暫定ディスパッチャからの正式ルート移行**: `compaction.md` / `session-continuity.md` の Operations 行を「Unit 004 でインデックス化予定」から「`phase-recovery-spec.md §5.3` 経由の正式ルート」に更新する
- **既存 Operations ステップファイルの重複除去**: `01-setup.md` / `02-deploy.md` / `03-release.md` / `04-completion.md` から、インデックスに集約される分岐・判定・`automation_mode` 分岐・depth_level 分岐等の重複記述を除去し、詳細手順に特化させる
- **トークン予算**: Operations 初回ロード **17,827 tok 以下**（v2.2.3 ベースライン現状値）。インデックス化によって初回ロード量が悪化しないこと、かつ可能な限り削減されることを計測で確認する
- **削減見込みの内訳**（設計ステップで精緻化）:
  - 現状ベースライン: SKILL.md（4,944）+ rules-core（1,885）+ preflight（1,965）+ session-continuity（540）+ operations 4 ファイル（1,315 + 3,158 + 768 + 3,252）= 17,827 tok
  - Unit 004 実装後: 共通 4 ファイル + `operations/index.md`（新設、≈ 5,000-6,000 tok 想定）+ ステップ 4 ファイルからの重複除去（≈ 1,500-2,500 tok）→ 純減 0〜2,000 tok の想定
  - 総合: 初回ロード対象は 5 ファイルとなり、ベースライン以下を保つ想定。設計段階で実測ベースラインと照合する
- **Construction → Operations 遷移の明確化**: spec §4 Operations 判定分岐 + §4.1 末尾の bootstrap 特殊分岐（`construction_complete` info 診断付き）の現状記述を再確認し、Operations 側の checkpoint 評価および bootstrap 分岐との接続を明確にする
- **後方互換性**: Operations Phase は既存サイクル運用中に変更されるリスクが低いため、ファイル構造・命名規約は変更しない
- **token grammar**: Unit 003 で確立した推奨形式 `spec§5.<phase>.<checkpoint>` を Operations binding でも使用（`spec§5.operations.setup_done` 等）
- **Operations Phase 固有の特性**:
  - **直線的進行**: Unit loop なし、Inception と同じ progress.md ベース
  - **`project.type` 依存のスキップ**: ステップ5（配布）は `project.type` により自動スキップ
  - **「変更なし」スキップ**: ステップ1で「いいえ」選択時はステップ2-5を一括スキップ
  - これらの分岐は判定仕様（spec §5.3）には影響せず、各 checkpoint の達成判定は progress.md の「完了」or「スキップ」状態を等価に扱う

### Operations Phase 判定チェックポイントの設計方針

Operations Phase は Inception と同じ「直線的進行」構造を持つため、判定仕様は Inception パターン（spec §5.1.1〜§5.1.5）と同形となる。ただし checkpoint 数は Operations の現状ファイル境界（4 ファイル）に 1:1 対応させて 4 つとし、checkpoint と step_id と detail_file が常に 1:1 で結ばれる構造を採用する。

`OperationsStepResolver` は以下の checkpoint を順に評価し、**未達成の最初の checkpoint** に対応する `step_id` を返す:

**Operations checkpoint（4 行構成、Unit 001 スキーマに適合）**:

| checkpoint_id | 対応 step_id | 意味 | 主な input_artifacts |
|--------------|-------------|------|---------------------|
| `operations.setup_done` | `operations.01-setup` | 初期セットアップ完了（プリフライト、`operations/progress.md` の新規作成、運用引き継ぎ情報読み込み、全 Unit 完了確認、Construction 引き継ぎタスク確認） | `operations/progress.md` が**存在する** |
| `operations.deploy_done` | `operations.02-deploy` | デプロイ実作業全体完了（ステップ1-7 のすべてが「完了」or「スキップ」 = PR 準備完了 = 7.7 Gitコミット完了） | `operations/progress.md`（ステップ1-7 がすべて「完了」or「スキップ」）、`operations/deployment_checklist.md`（条件付き）、`operations/cicd_setup.md`（条件付き）、`operations/monitoring_strategy.md`（条件付き）、`operations/post_release_operations.md`（条件付き） |
| `operations.release_done` | `operations.03-release` | リリース完了基準確認完了（PR Ready 化〜マージ前レビュー完了 = サブステップ 7.8〜7.12 完了） | `history/operations.md`（「PR Ready 化」記録あり） |
| `operations.completion_done` | `operations.04-completion` | PR マージ完了 + 次サイクル準備完了（PR マージ後の手順 + バージョンタグ付け + 次サイクル開始の準備） | `history/operations.md`（「PR マージ」記録あり） |

**Construction → Operations bootstrap 分岐**: `phaseProgressStatus[construction]=completed ∧ operations/progress.md 未存在` の場合は **Operations 新規開始の正常状態**として `operations.setup_done=false` を返し、`operations.01-setup` に遷移する。これは bootstrap 分岐として spec §5.3 の冒頭に明記する。

判定ルール本文（境界条件・単値化ルール・bootstrap 分岐・各 checkpoint の判定条件詳細）は `phase-recovery-spec.md §5.3` に記載し、index.md には重複記述しない。spec 参照トークンは Unit 003 で確立した推奨形式 `spec§5.operations.<checkpoint_suffix>` を使用する。

### 異常系の Operations 固有ケース

- **operations_in_progress_missing_progress**（missing_file 系統）: history に「Operations 進行中」記録（`operations.setup_done` 等の完了マーカー）があるのに `operations/progress.md` が欠損 → spec §7.0 の missing_file トリガーに該当 → `result=undecidable:missing_file`。**注**: bootstrap 状態（Construction 完了直後 + Operations 未着手）は missing_file の対象外とする
- **operations_progress_corrupt**（format_error 系統）: `operations/progress.md` が存在するが空ファイルまたはパース不能 → `result=undecidable:format_error`
- **legacy_structure**（warning）: v2.2.x 以前の構造（`operations.md` 単一ファイル等）残存 → `diagnostics[]` に `legacy_structure` 追加、判定継続可

これらは `phase-recovery-spec.md §7` の既存 4 系統（`missing_file` / `conflict` / `format_error` / `legacy_structure`）の Operations 固有インスタンス化として扱う。Operations 固有の新 reason_code は追加しない（Unit 003 の `dependency_block` のような Unit loop 由来の特殊ケースが Operations にはないため）。

## 対象ファイル

| # | ファイル | 操作 | 主な変更内容 |
|---|---------|------|-------------|
| 1 | `skills/aidlc/steps/operations/index.md` | **新規** | Operations Phase インデックス。Unit 001/003 の章立てを流用し、Operations 固有要素を差し替え。`<!-- phase-index-schema: v1 -->` コメントと Materialized Binding 宣言を先頭に記載 |
| 2 | `skills/aidlc/steps/common/phase-recovery-spec.md` | 更新 | (a) §1.3 の Unit 004 責務を「実値化済み」に更新。(b) §2.2 の Operations 実装を「Unit 004 で実値化（Inception 同型の直線評価、4 checkpoint × 4 step_id × 4 detail_file の 1:1 対応）」に更新。(c) §5.3 を placeholder から実装に昇格。Operations Phase の **4 checkpoint**（`setup_done` / `deploy_done` / `release_done` / `completion_done`）の判定条件、`OperationsStepResolver` のアルゴリズム、および **bootstrap 分岐**（`phaseProgressStatus[construction]=completed ∧ operations/progress.md 未存在 → operations.01-setup`）を記述。(d) §6 の Operations 戻り値説明から「placeholder」記述を削除。(e) §12 Operations 適用例を追加（Construction §11 と同様の構造、bootstrap 分岐の判定例を含む）。(f) `spec_version` を v1.1 → v1.2 に更新 |
| 3 | `skills/aidlc/steps/common/compaction.md` | 更新 | 暫定ディスパッチャの Operations 行を「現行ルート維持」から「`phase-recovery-spec.md §5.3` 経由の正式ルート」に更新。Operations の `StepId` 戻り値ハンドリングを追加 |
| 4 | `skills/aidlc/steps/common/session-continuity.md` | 更新 | フェーズ別進捗源テーブルの Operations 行を「Unit 004 でインデックス化予定」から `judge()` 契約経由 + `steps/operations/index.md` 参照に更新 |
| 5 | `skills/aidlc/SKILL.md` | 更新 | 共通初期化フロー「ステップ4: フェーズステップ読み込み」の operations 行を `index.md` のみに変更 |
| 6 | `skills/aidlc/steps/operations/01-setup.md` | 更新 | インデックスに集約される分岐（プリフライト、Depth Level、`automation_mode` 分岐、AI レビュー分岐）の重複記述を除去 |
| 7 | `skills/aidlc/steps/operations/02-deploy.md` | 更新 | 同上（ステップ1の変更確認分岐、`project.type` 依存スキップ等は詳細手順として残す） |
| 8 | `skills/aidlc/steps/operations/03-release.md` | 更新 | 同上（リリース準備の `Depth Level` 分岐、`automation_mode` 分岐等） |
| 9 | `skills/aidlc/steps/operations/04-completion.md` | 更新 | 同上（バックトラックフロー、PR マージ後手順、worktree フロー等は詳細手順として残す） |
| 10 | `skills/aidlc/scripts/verify-operations-recovery.sh` | **新規** | Operations 固有の検証 fixture 生成スクリプト。Unit 002/003 と同じアーキテクチャ（`--case` / `--dest` / `--clean` / `--dry-run` 引数、`bin/check-bash-substitution.sh` 準拠、`--dest` ディレクトリトラバーサル対策、終了コード規約準拠） |

## 設計成果物（Phase 1）

- `.aidlc/cycles/v2.3.0/design-artifacts/domain-models/unit_004_operations_phase_index_domain_model.md`
- `.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/unit_004_operations_phase_index_logical_design.md`

## 実装記録（Phase 2）

- `.aidlc/cycles/v2.3.0/construction/units/unit_004_operations_phase_index_verification.md`

## 検証手順

### 静的検証（spec との照合）

1. `steps/operations/index.md` の判定チェックポイント表の全 **4 行**（`setup_done` / `deploy_done` / `release_done` / `completion_done`）が `phase-recovery-spec.md §5.3` のルールと 1 対 1 対応し、bootstrap 分岐が spec §5.3 冒頭に明記されていることを確認
2. 各 checkpoint の `input_artifacts` が `.aidlc/cycles/{{CYCLE}}/operations/` 配下の実パスを正しく指していることを確認
3. `spec§5.operations.<checkpoint>` 参照トークンが spec 側に実在することを確認
4. Operations ステップファイル 4 件（`01-setup.md` 〜 `04-completion.md`）から除去した重複記述が index.md 側に集約されていることを確認
5. spec §4 **判定順2**（Operations 判定）+ §4.1 末尾の bootstrap 特殊分岐が、Operations 側の `setup_done` 評価および bootstrap 分岐との接続を持つことを確認

### Operations 固有の検証ケース（fixture 生成）

Unit 002 の `verify-inception-recovery.sh` および Unit 003 の `verify-construction-recovery.sh` と同じパターンで Operations 版の検証 fixture を生成し、静的検証を行う。**正常系 4 + bootstrap 1 + 異常系 2 = 計 7 ケース**:

| # | ケース | 期待結果 |
|---|--------|---------|
| o1 | normal-deploy-fresh（progress.md 存在、ステップ1-7 すべて未着手） | `phase=operations`、`step=operations.02-deploy`（setup_done=true（progress.md 存在）、deploy_done=false） |
| o2 | normal-deploy-progress（progress.md 存在、ステップ1-3 完了、ステップ4-7 進行中） | `phase=operations`、`step=operations.02-deploy`（境界条件中間） |
| o3 | normal-release（ステップ1-7 すべて「完了」or「スキップ」 = PR 準備完了、PR Ready 化記録なし） | `phase=operations`、`step=operations.03-release` |
| o4 | normal-completion（PR Ready 化記録あり、PR マージ記録なし） | `phase=operations`、`step=operations.04-completion` |
| o5 | bootstrap-from-construction（Construction 完了、operations/progress.md 未存在、history/operations.md 未存在 = 新規開始） | `phase=operations`、`step=operations.01-setup`（bootstrap 分岐、`missing_file` ではない、`construction_complete` info 診断付き） |
| o6 | abnormal-operations_in_progress_missing_progress（history に Operations 進行中記録あり、progress.md 欠損） | `result=undecidable:missing_file` |
| o7 | abnormal-progress_corrupt（progress.md 存在するがパース不能） | `result=undecidable:format_error` |

各ケースの期待値は `phase-recovery-spec.md §5.3` の規範ルールから演繹的に決定する。

**setup_done の再定義**: `operations.setup_done` は「`operations/progress.md` が**存在する**（01-setup.md による初期化完了）」と定義する。これによりファイル境界（01-setup.md = progress.md 作成、02-deploy.md = ステップ1-7 進行）と判定条件が完全に一致する。

**カバレッジ**: 4 step_id すべてが少なくとも 1 つの fixture でテストされる（`operations.01-setup` は o5 のみ、`operations.02-deploy` は o1/o2、`operations.03-release` は o3、`operations.04-completion` は o4）。

**bootstrap 分岐の扱い**: o5 は Unit 003 で確立した「Construction → Operations 遷移（`phaseProgressStatus[construction]=completed`、`construction_complete` info 診断付き）」が Unit 004 の `OperationsStepResolver` に正しく接続されることを検証する。判定仕様では「Operations 進行中の証拠（progress.md or history 記録）の有無」で bootstrap か missing_file かを区別する。

**検証方法**: `skills/aidlc/scripts/verify-operations-recovery.sh`（新規）を作成し、上記 7 ケースの fixture 生成と期待値出力を行う。`bin/check-bash-substitution.sh` 準拠、`--dest` ディレクトリトラバーサル対策、終了コード規約準拠。

### 初回ロード計測

```bash
/tmp/venv-tok/bin/python -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
files = [
    'skills/aidlc/SKILL.md',
    'skills/aidlc/steps/common/rules-core.md',
    'skills/aidlc/steps/common/preflight.md',
    'skills/aidlc/steps/common/session-continuity.md',
    'skills/aidlc/steps/operations/index.md',
]
total = 0
for f in files:
    with open(f) as fh:
        c = fh.read()
    t = len(enc.encode(c))
    total += t
    print(f'{t:>6} tok  {f}')
print(f'{total:>6} tok  TOTAL v2.3.0 Unit 004')
"
```

**判定基準**: 実装後の TOTAL が **17,827 tok 以下**かつベースライン以下であること。

### compaction.md / session-continuity.md 整合性検証

- `compaction.md` の phase 別 result テーブルから Operations 行が「現行ルート維持」→「`phase-recovery-spec.md §5.3` 経由」に更新されていることを grep で確認
- `session-continuity.md` の Operations 行が `judge()` 契約経由の新フローに更新されていることを確認
- Construction 行は Unit 003 で確立した形式が変更されていないことを確認

### phase-recovery-spec.md §5.3 実装検証

- §5.3 が placeholder（「Unit 004 で埋める」）ではなく実装内容（4 checkpoint の判定ルール、bootstrap 分岐、Inception 同型の直線評価アルゴリズム）を含むことを確認
- `spec_version` がマイナーバージョンアップされること（v1.1 → v1.2）
- §12（Operations 適用例、bootstrap 分岐の判定例を含む）が追加されていること

## 完了条件チェックリスト

- [ ] **【index.md 新設】** `skills/aidlc/steps/operations/index.md` が新規作成され、Unit 001/003 の章立て（目次 / 分岐ロジック / 判定チェックポイント表 / ステップ読み込み契約 / 汎用構造仕様）と 5 列スキーマを流用している。先頭に Unit 001/003 と同形式の Materialized Binding 宣言と `<!-- phase-index-schema: v1 -->` コメントを記載
- [ ] **【Operations checkpoint 実値化】** `operations/index.md` §3 の判定チェックポイント表が **4 行**（`setup_done` / `deploy_done` / `release_done` / `completion_done`）で埋められ、`input_artifacts` 列は Operations 固有の具象パス、`priority_order` 列は `spec§5.operations.<checkpoint>` 形式、`undecidable_return` / `user_confirmation_required` 列は `spec§6` / `spec§8`
- [ ] **【骨格スキーマ不変】** `operations/index.md` のチェックポイント表の列構造（5 列）と Unit 001 で確立した共通要素（章立て・`StepLoadingContract` 列スキーマ・`<!-- phase-index-schema: v1 -->`）が Unit 001 から変更されていない
- [ ] **【論理インターフェース契約】** `operations/index.md` §3.1 に `judge()` 契約経由 + `result + diagnostics[]` 分離形式のインターフェース記述があり、`OperationsStepResolver.determine_current_step()` への委譲が明記されている
- [ ] **【spec §5.3 実装】** spec §5.3 が placeholder から実装に昇格し、4 checkpoint の判定条件、入力アーティファクトの canonical path、Inception 同型の直線的評価アルゴリズム、Construction → Operations bootstrap 分岐が記述されている
- [ ] **【spec §1.3 / §2.2 更新】** spec §1.3 の Unit 004 責務を「実値化済み」に更新、§2.2 の Operations 実装を「Unit 004 で実値化（Inception 同型の直線評価、4 checkpoint × 4 step_id × 4 detail_file の 1:1 対応）」に更新
- [ ] **【spec §12 Operations 適用例追加】** spec §12（Construction §11 と同様の構造）が追加され、Operations 固有の `ArtifactsState` サンプルと 4 checkpoint の判定例（bootstrap 分岐を含む）が記載されている
- [ ] **【spec_version 更新】** `phase-recovery-spec.md` の `spec_version` が v1.1 → v1.2 に更新されている
- [ ] **【Operations 固有検証】** `verify-operations-recovery.sh` が新規作成され、o1〜o7 の 7 ケースすべてで期待値の単値性が確認されている（normal-deploy-fresh / normal-deploy-progress / normal-release / normal-completion + bootstrap-from-construction + abnormal-operations_in_progress_missing_progress + abnormal-progress_corrupt）
- [ ] **【bootstrap 分岐検証】** `phaseProgressStatus[construction]=completed ∧ operations/progress.md 未存在 → operations.01-setup` の正常系遷移が o5 fixture で確認され、`undecidable:missing_file` には**ならない**ことが検証されている
- [ ] **【StepLoadingContract と detail_file 整合性】** `operations/index.md §4` の StepLoadingContract が `01-setup.md` / `02-deploy.md` / `03-release.md` / `04-completion.md` の現状ファイル責務と矛盾しないことが静的照合で確認されている（4 step_id × 4 detail_file の 1:1 対応）
- [ ] **【compaction.md / session-continuity.md 更新】** (a) `compaction.md` の暫定ディスパッチャ Operations 行が「`phase-recovery-spec.md §5.3` 経由の正式ルート」に更新されている、(b) `compaction.md` 戻り値テーブルに `operations | StepId` 行を追加、(c) `session-continuity.md` の Operations 行が `judge()` 契約経由に更新されている、(d) Construction 行は Unit 003 で確立した形式が変更されていない
- [ ] **【SKILL.md 更新】** 共通初期化フローの operations 行が `steps/operations/index.md` のみを読み込む形に変更されている
- [ ] **【既存ステップファイル重複除去】** `01-setup.md` / `02-deploy.md` / `03-release.md` / `04-completion.md` の 4 ファイルから、インデックスに集約される分岐・判定・`automation_mode` 分岐・depth_level 分岐の重複記述が除去され、詳細手順（バックトラック、PR マージ後手順、worktree フロー、Self-Healing ループ等）は残っている
- [ ] **【初回ロード計測】** v2.3.0 Unit 004 実装後の Operations 初回ロードが **17,827 tok 以下**かつ v2.2.3 ベースライン以下であることを計測結果で確認済み
- [ ] **【Unit 005/006 接続点】** `phase-recovery-spec.md §5` 配下の Operations セクションが完全に実値化され、Unit 005（Tier2 統合）/ Unit 006（計測・クローズ判断）でさらに利用可能な状態
- [ ] **【bash substitution check & markdownlint】** `bash bin/check-bash-substitution.sh`（CI デフォルトスコープ `skills/aidlc/steps/`）が違反ゼロで完了、`skills/aidlc/scripts/run-markdownlint.sh v2.3.0` がエラーゼロで完了する

## 依存関係

### 前提 Unit

- Unit 001（Inception インデックス構造のパイロット、汎用構造仕様の確立）
- Unit 002（`phase-recovery-spec.md` 規範仕様、2 段レゾルバ構造、Materialized Binding パターン）
- Unit 003（Construction Phase Index、§5.2 実値化、token grammar 正式化、`spec§5.<phase>.<checkpoint>` 形式）

### 本 Unit を依存元とする Unit

- Unit 005（Tier2 施策統合、Unit 001-004 で確立したインデックス構造を前提）
- Unit 006（計測・クローズ判断、Unit 001〜005 の成果物を一括検証）

## 関連 Issue

- #519: コンテキスト圧縮メイン Issue（ストーリー 3 が本 Unit 対象）

## リスクと留意事項

- **checkpoint と detail_file の 1:1 対応**: Operations Phase の現状ファイル境界（4 ファイル）に合わせて 4 checkpoint を採用し、`step_id → detail_file` の 1:1 対応を維持する。これにより Materialized Binding 原則が崩れない。Inception の 5 checkpoint や progress.md の 7 ステップを直接 mapping することは過剰適用となるため避ける
- **02-deploy.md の広範な責務**: `02-deploy.md` は実態としてステップ2-7 すべての本体を含む（リリース準備のサブステップ参照含む）。これを 1 つの step_id `operations.02-deploy` にマップし、`deploy_done` の判定条件は「ステップ2-7 すべてが progress.md 上で『完了』or『スキップ』」と定義する
- **bootstrap 分岐の重要性**: `phaseProgressStatus[construction]=completed ∧ operations/progress.md 未存在` は **Operations 新規開始の正常状態**であり、`undecidable:missing_file` で blocking してはいけない。`missing_file` は「Operations 進行中マーカーが history にあるのに progress.md 欠損」のケースに限定する。fixture o5 と o6 で両方を区別して検証する
- **トークン予算の余裕**: 現状ベースライン 17,827 tok は Construction の 17,980 tok よりわずかに小さい。Construction では -2,554 tok の純減を達成したが、Operations では `04-completion.md` が 3,252 tok と大きく、重複除去対象が少ない可能性がある。設計ステップで実測ベースラインと照合する
- **Construction → Operations 遷移**: Unit 003 で `phaseProgressStatus[construction]=completed` → Operations 遷移判定を確立したが、現状の暫定実装では Operations 側は `step=None` を返している。Unit 004 では `OperationsStepResolver` が bootstrap 分岐経由で `operations.01-setup` を返すため、遷移パスが変わる。fixture o5 で動作確認が必要
- **Operations Phase の特殊ケース**: `project.type` 依存スキップ、「変更なし」一括スキップ、worktree フロー等の Operations 固有分岐は判定仕様（spec §5.3）の対象外（progress.md の状態管理に閉じる）。これを設計ステップで明確化する
