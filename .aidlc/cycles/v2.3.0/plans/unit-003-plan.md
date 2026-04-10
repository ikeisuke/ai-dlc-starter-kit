# Unit 003 計画: Construction フェーズのインデックス化

## 概要

Unit 001 で確立した「フェーズインデックス + ステップ読み込み契約 + 判定チェックポイント骨格」の汎用構造を Construction Phase に展開する。Unit 002 で確立した `phase-recovery-spec.md`（規範仕様）を Construction Phase にも適用し、`phase-recovery-spec.md §5.2`（Unit 002 時点の placeholder）を実装 Construction 判定仕様へ昇格させる。`compaction.md` / `session-continuity.md` の暫定ディスパッチャから Construction を正式ルートへ移行する。

Inception（Unit 001 / 002）/ Operations（Unit 004）への組み込みとは独立した Unit 003 の範囲として、**Construction フェーズの index.md 新設** + **Construction 判定仕様の実装** + **既存 Construction ステップファイルからの重複除去** + **初回ロード計測** を実施する。

## 方針

- **Unit 001 構造スキーマ不変**: `steps/construction/index.md` は Unit 001 で確立した章立て（目次 / 分岐ロジック / 判定チェックポイント表 / ステップ読み込み契約 / 汎用構造仕様）と 5 列スキーマ（`checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`）をそのまま流用する。フェーズ固有要素（step_id 命名、具体的な分岐条件、checkpoint_id）のみを Construction に差し替える
- **Materialized Binding 原則**: `steps/construction/index.md` は `phase-recovery-spec.md` の Construction 向け materialized binding と位置付け、判定規則の本文は spec 側に置く。binding 層は具象パスと `spec§5.<phase>.<checkpoint>` 参照トークンのみを保持する
- **Construction 判定仕様を spec §5.2 に実装**: Unit 002 では Construction を暫定ディスパッチャで現行ルート維持としていた。Unit 003 では `phase-recovery-spec.md §5.2`（Construction Phase の step 判定）を placeholder から実装に昇格させ、Construction 固有の checkpoint ルールを記述する
- **spec §4 への Construction 完了条件の追加**: Phase 遷移は `PhaseResolver`（spec §4）の責務であり、`ConstructionStepResolver` は step しか返さない。Construction Phase が「全 Unit 完了」状態になった場合の Operations 遷移判定は spec §4 の判定順3（Construction 判定）に完了条件を追加する形で PhaseResolver 側に実装する。`ConstructionStepResolver` は「進行中 Unit の現在ステップ」のみを返し、phase 遷移には関与しない
- **spec §9 の token grammar 正式採用**: spec §9 で既に拡張形式として予告されている `spec§5.<phase>.<checkpoint>` を Unit 003 の作業で正式規約として採用する。Construction binding は `spec§5.construction.<checkpoint>` 形式、既存 Inception binding も `spec§5.setup_done` → `spec§5.inception.setup_done` に同時更新して全 binding を統一規約に揃える。checkpoint 名の phase 間衝突（例: `setup_done` / `completion_done`）を構造的に排除する
- **2段レゾルバ構造の維持**: `PhaseResolver`（spec §4）の判定順は変更しない（完了条件追加のみ）。`ConstructionStepResolver.determine_current_step()` を `PhaseLocalStepResolver` の Construction 実装として追加し、`PhaseResolver` が Construction と判定した場合に委譲する
- **Unit loop 構造の明示化**: Construction Phase は「Unit 選定 → 設計（Phase 1）→ 実装（Phase 2）→ 完了処理」を Unit ごとに繰り返す。判定仕様はまず「現在進行中の Unit を特定」し、次に「その Unit の現在ステップを特定」する 2 段構造とする。Unit 定義ファイル（`story-artifacts/units/*.md`）の「実装状態」セクションが一次入力となる
- **Unit 特定アルゴリズムの既存ロジック忠実再現**: Stage 1 の Unit 特定は既存 `construction/01-setup.md` ステップ7 の決定ロジックを規範化する（単値性を保証）:
  - `in_progress_units = { u | u.status=進行中 }`
  - `executable_units = { u | u.status=未着手 ∧ u.dependencies ⊆ {完了,取り下げ} }`
  - 判定順: (a) `|in_progress_units|=1` → その Unit、(b) `|in_progress_units|≥2` → `undecidable:conflict`（multi_unit_in_progress）、(c) `|in_progress_units|=0 ∧ |executable_units|=0 ∧ ∀u.status∈{完了,取り下げ}` → `PhaseResolver` が Construction 完了シグナルを認識し Operations 遷移判定へ（spec §4 判定順3の完了条件）、(d) `|executable_units|=0` かつ未完了 Unit あり（依存ブロック） → `undecidable:dependency_block`（新 reason_code、§7 に追加）、(e) `|executable_units|=1` → その Unit（自動選択）、(f) `|executable_units|≥2 ∧ automation_mode=semi_auto` → 番号順で最小、(g) `|executable_units|≥2 ∧ automation_mode=manual` → ユーザー選択フロー（既存フォールバック）
- **Unit 001/002 で確立した骨格スキーマは不変**: 列構造（5 列）と `<!-- phase-index-schema: v1 -->` コメントは維持。Construction の checkpoint 表は Construction ステップ数（4）に合わせて 4 行構成とする。Stage 1（Unit 特定アルゴリズム）は checkpoint 行としてではなく index.md §3.1 の独立「アルゴリズム節」として配置する（決定ツリーは checkpoint の判定ルールと異質のため）
- **暫定ディスパッチャからの正式ルート移行**: `compaction.md` / `session-continuity.md` の Construction 行を「暫定ディスパッチャで現行ルート維持」から「`phase-recovery-spec.md §5.2` 経由の正式ルート」に更新する。Operations は Unit 004 まで暫定維持のままとする
- **既存 Construction ステップファイルの重複除去**: `01-setup.md` / `02-design.md` / `03-implementation.md` / `04-completion.md` から、インデックスに集約される分岐・判定・`automation_mode` 分岐・AI レビュー分岐等の重複記述を除去し、詳細手順に特化させる
- **トークン予算**: Construction 初回ロード **17,980 tok 以下**（v2.2.3 ベースライン維持）。インデックス化によって初回ロード量が悪化しないこと、かつ可能な限り削減されることを計測で確認する
- **削減見込みの内訳**（設計ステップで精緻化、計画段階の見積もり）:
  - v2.2.3 ベースライン想定: SKILL.md + rules-core + preflight + session-continuity + construction step 4 ファイル合計 ≈ 17,980 tok（user_stories.md 記載値）
  - Unit 003 実装後: 共通 4 ファイル + `index.md`（新設、≈ 5,500 tok 想定、Inception index ≈ 6,269 tok より小さい想定。Construction は分岐が Inception より少ない）
  - ステップ 4 ファイルからの重複除去対象: `automation_mode` 分岐、エクスプレス分岐、AI レビュー分岐、depth_level 分岐、フェーズ責務宣言（「Phase 1/Phase 2」）等 → 合計 ≈ 1,500〜2,500 tok の削減想定
  - 総合: 初回ロード対象は 5 ファイルとなり、ベースライン以下を保つ想定。設計段階で実測ベースラインと照合する
- **後方互換性**: Construction フェーズは既に cycle ブランチ上で稼働中の Unit が存在する可能性があるため、既存の `construction/units/` 配下の成果物構造・命名規約は変更しない。判定仕様は既存構造をそのまま読み取る形で設計する
- **ファイル命名規約の正規化表を spec §5.2 に追加**: 現行 Construction 成果物は `unit_number` が 2 桁（`history/construction_unitNN.md`）/ 3 桁（`plans/unit-NNN-plan.md` / `{NNN}-review-summary.md`）/ `unit_slug`（`[unit_name]_implementation.md`）と混在している。spec §5.2 に canonical path 正規化表を追加し、`unit_number`（ゼロ埋め 3 桁）/ `unit_slug`（ケバブケース）/ `unit_name`（スネークケース）の3 種類のキーをどのファイルで使うか固定する。これにより `missing_file` 誤検知を防ぐ

### Construction Phase 判定チェックポイントの設計方針

Construction Phase は Inception と異なり「Unit loop 構造」を持つため、判定仕様は 2 段構造となる。ただし phase 遷移は `PhaseResolver`（spec §4）の責務であり、`ConstructionStepResolver` は step のみを返す（Operations 遷移判定は PhaseResolver 側の責務）:

1. **Stage 1: 現在進行中 Unit の特定**（アルゴリズムは上記「Unit 特定アルゴリズムの既存ロジック忠実再現」を参照）: `story-artifacts/units/*.md` を全件スキャンし、`in_progress_units` / `executable_units` を算出して決定ツリーで単値化する。`ConstructionStepResolver` は以下のいずれかを返す:
   - 進行中 Unit 1 件 → その Unit を `currentUnit` として Stage 2 へ
   - 進行中 Unit 2 件以上 → `result=undecidable:conflict`（multi_unit_in_progress）
   - 進行中 0 件 ∧ 実行可能 1 件 → その Unit を `currentUnit` として Stage 2 へ（新規 Unit 選定、step は `construction.setup`）
   - 進行中 0 件 ∧ 実行可能 複数 → `automation_mode` に応じて番号順選択 or ユーザー選択フォールバック
   - 進行中 0 件 ∧ 実行可能 0 件 ∧ 依存ブロックなし → **Construction Phase 完了シグナル**（`PhaseResolver` 側でこのシグナルを検出し Operations 遷移を判定する。`ConstructionStepResolver` 自体は phase 遷移を返さない）
   - 進行中 0 件 ∧ 実行可能 0 件 ∧ 依存ブロックあり → `result=undecidable:dependency_block`

2. **Stage 2: 進行中 Unit の現在ステップ特定**: `currentUnit` の各ステップ成果物の存在・履歴記録の有無から、現在のステップを特定する（下記 4 checkpoint）

**Construction checkpoint（4 行構成、Unit 001 スキーマに適合）**:

| checkpoint_id | 意味 | 主な input_artifacts（canonical path は spec §5.2 正規化表参照） |
|--------------|------|---------------------|
| `construction.setup_done` | Unit 選定 + 計画承認完了 | `plans/unit-{NNN}-plan.md` 存在 ∧ `history/construction_unit{NN}.md` に「計画承認」記録あり |
| `construction.design_done` | Phase 1 設計完了（ドメインモデル + 論理設計 + 設計承認）。`depth_level=minimal` 時は設計省略記録で代替可 | `design-artifacts/domain-models/unit_{NNN}_{stem}_domain_model.md`, `design-artifacts/logical-designs/unit_{NNN}_{stem}_logical_design.md`, `history/construction_unit{NN}.md`（設計承認 or 設計省略記録）|
| `construction.implementation_done` | Phase 2 実装完了（コード + テスト + 統合レビュー承認） | `history/construction_unit{NN}.md` に「実装承認」or「AIレビュー完了」の統合レビュー記録 |
| `construction.completion_done` | Unit 完了処理完了（Unit 定義「完了」、履歴、squash、コミット） | `story-artifacts/units/{NNN}-{slug}.md`（実装状態＝完了）, `history/construction_unit{NN}.md`（Unit完了記録） |

Stage 1 の Unit 特定アルゴリズム（決定ツリー）は `index.md §3.1` に独立セクションとして配置し、checkpoint 表には含めない（checkpoint は Stage 2 の Unit 内ステップ判定のみを表現する責務境界）。判定ルール本文（境界条件・単値化ルール・conflict 判定・canonical path 正規化表）は `phase-recovery-spec.md §5.2` に記載し、index.md には重複記述しない。spec 参照トークンは **spec §9 拡張形式** `spec§5.construction.<checkpoint_suffix>` を使用する（例: `spec§5.construction.setup_done`、Stage 1 アルゴリズム参照は `spec§5.construction.unit_selection`）。

**Inception binding の同時更新**: spec §9 の token grammar 正式採用に伴い、`steps/inception/index.md` §3 のチェックポイント表の `priority_order` 列も `spec§5.setup_done` → `spec§5.inception.setup_done` の明示形に同時更新する（Unit 003 の作業範囲）。

**depth_level=minimal での設計省略ケース**: `construction.design_done` は `depth_level=minimal` の場合に設計省略を許容する。判定仕様では「設計ファイル未存在 AND history に『設計省略（depth_level=minimal）』記録」の場合も `design_done=true` とみなす。

**Unit 003/004 接続点**: Unit 003 完了時点で `phase-recovery-spec.md §5.2` は実装済みとなり、`§5.3`（Operations）は引き続き placeholder のまま Unit 004 の責務として残る。

### 異常系の Construction 固有ケース

- **multi_unit_in_progress**（conflict 系統）: 複数の Unit 定義ファイルが同時に「進行中」状態 → `result=undecidable:conflict`（`§7.2` の conflict サブケースとして追加）
- **dependency_block**（新 reason_code）: 進行中 Unit なし ∧ 実行可能 Unit なし ∧ 依存ブロックで未完了 Unit が残存 → `result=undecidable:dependency_block`。`§7` に新しい reason_code として追加する（blocking）
- **plan_missing**（missing_file 系統）: 進行中 Unit の `plans/unit-{NNN}-plan.md` が存在しない → `result=undecidable:missing_file`
- **progress_file_corrupt**（format_error 系統）: `history/construction_unit{NN}.md` が空ファイルまたはパース不能 → `result=undecidable:format_error`
- **legacy_structure**（warning）: v2.2.x 以前の `construction/implementation.md`（Unit 分割前の単一ファイル）残存 → `diagnostics[]` に `legacy_structure` 追加、判定継続可

`multi_unit_in_progress` / `plan_missing` / `progress_file_corrupt` / `legacy_structure` は `phase-recovery-spec.md §7` の既存 4 系統（`missing_file` / `conflict` / `format_error` / `legacy_structure`）の Construction 固有インスタンス化として扱う。`dependency_block` は Construction 固有の新 reason_code として `§7` に追加する。

## 対象ファイル

| # | ファイル | 操作 | 主な変更内容 |
|---|---------|------|-------------|
| 1 | `skills/aidlc/steps/construction/index.md` | **新規** | Construction Phase インデックス。Unit 001 の章立て（目次 / 分岐 / 判定チェックポイント / ステップ読み込み契約 / 汎用構造仕様）を流用し、Construction 固有要素を差し替え。`<!-- phase-index-schema: v1 -->` コメントと Materialized Binding 宣言を先頭に記載 |
| 2 | `skills/aidlc/steps/common/phase-recovery-spec.md` | 更新 | (a) §4 の判定順3（Construction 判定）に Construction 完了条件（全 Unit 完了シグナル）を追加。(b) §5.2（Construction Step 判定仕様）を placeholder から実装に昇格。Unit loop 構造（Stage 1: Unit 特定アルゴリズム / Stage 2: Step 特定 4 checkpoint）と canonical path 正規化表、`construction.01-setup` ステップ7 の Unit 選定アルゴリズム、§5.2.4 01-setup.md ステップ7 対応表を記述。(c) §7 に `dependency_block` 新 reason_code を追加。(d) §9.3 token grammar 正式採用（`spec§5.<phase>.<checkpoint>` 推奨形式、Inception 省略形は後方互換 alias）。(e) §11（Construction 適用例、旧 §10.2 相当）を追加。(f) `spec_version` を v1.0 → v1.1 に更新 |
| 3 | `skills/aidlc/steps/inception/index.md` | 更新 | §9 token grammar 正式採用に伴い、§3 チェックポイント表の `priority_order` 列を `spec§5.setup_done` → `spec§5.inception.setup_done` の明示形に同時更新（trivial な参照トークン変更のみ） |
| 4 | `skills/aidlc/steps/common/compaction.md` | 更新 | 暫定ディスパッチャの Construction 行を「現行ルート維持」から「`phase-recovery-spec.md §5.2` 経由の正式ルート」に更新。Operations は暫定のまま |
| 5 | `skills/aidlc/steps/common/session-continuity.md` | 更新 | フェーズ別進捗源テーブルの Construction 行を「Unit 003 でインデックス化予定」から `judge()` 契約経由 + `steps/construction/index.md` 参照に更新 |
| 6 | `skills/aidlc/SKILL.md` | 更新 | 共通初期化フロー「ステップ4: フェーズステップ読み込み」の construction 行を `index.md` のみに変更 |
| 7 | `skills/aidlc/steps/construction/01-setup.md` | 更新 | インデックスに集約される分岐（対象 Unit 決定、`automation_mode` 分岐、エクスプレス分岐、AI レビュー分岐）の重複記述を除去 |
| 8 | `skills/aidlc/steps/construction/02-design.md` | 更新 | 同上（Phase 1/2 境界、depth_level 分岐、設計レビュー分岐等） |
| 9 | `skills/aidlc/steps/construction/03-implementation.md` | 更新 | 同上。Self-Healing ループの本体（エラー分類判定、attempt 出力フォーマット、フォールバック選択肢）は詳細手順として残す |
| 10 | `skills/aidlc/steps/construction/04-completion.md` | 更新 | 同上（完了条件分岐、squash 分岐、コンテキストリセット分岐等）。Unit 完了時の必須作業手順本体は詳細手順として残す |

## 設計成果物（Phase 1）

- `.aidlc/cycles/v2.3.0/design-artifacts/domain-models/unit_003_construction_phase_index_domain_model.md`
- `.aidlc/cycles/v2.3.0/design-artifacts/logical-designs/unit_003_construction_phase_index_logical_design.md`

## 実装記録（Phase 2）

- `.aidlc/cycles/v2.3.0/construction/units/unit_003_construction_phase_index_verification.md`

## 検証手順

### 静的検証（spec との照合）

1. `steps/construction/index.md` の判定チェックポイント表の全 **4 行**（`setup_done` / `design_done` / `implementation_done` / `completion_done`）が `phase-recovery-spec.md §5.2.1.1〜§5.2.1.4` のルールと 1 対 1 対応していること、および §3.1 Stage 1 アルゴリズム節が `phase-recovery-spec.md §5.2.0` と 1 対 1 対応していることを確認
2. 各 checkpoint の `input_artifacts` が `.aidlc/cycles/{{CYCLE}}/` 配下の実パスを正しく指していること（canonical path 正規化表と一致）を確認
3. `spec§5.construction.<checkpoint>` / `spec§5.inception.<checkpoint>` 参照トークンが spec 側に実在することを確認（Inception binding の更新分も含む）
4. Construction ステップファイル 4 件（`01-setup.md` 〜 `04-completion.md`）から除去した重複記述が index.md 側に集約されていることを確認
5. spec §4 判定順3（Construction 判定）に Construction 完了条件が追加され、`PhaseResolver` が完了シグナルを検出して Operations 遷移を判定できることを spec レベルで確認
6. spec §7 に `dependency_block` 新 reason_code が追加され、blocking 分類に統合されていることを確認

### Construction 固有の検証ケース（fixture 生成）

Unit 002 の `verify-inception-recovery.sh` と同じパターンで Construction 版の検証 fixture を生成し、静的検証を行う。本 Unit のスコープは Construction 固有ケースのみとする（Inception ケースは Unit 002 で実施済み）:

| # | ケース | 期待結果 |
|---|--------|---------|
| c1 | normal-unit-setup（進行中 Unit 1 件、plan のみ存在、設計・実装・完了処理なし） | `phase=construction`、`step=construction.01-setup` |
| c2 | normal-unit-design（plan + domain_model + logical_design 存在、設計承認記録あり） | `phase=construction`、`step=construction.02-design` または Phase 2 待機 |
| c3 | normal-unit-implementation（設計完了 + 実装レビュー承認記録なし） | `phase=construction`、`step=construction.03-implementation` |
| c4 | normal-unit-completion（実装承認記録あり、Unit 定義「進行中」） | `phase=construction`、`step=construction.04-completion` |
| c5 | multi_unit_in_progress（2 Unit が同時に「進行中」） | `result=undecidable:conflict`（blocking） |
| c6 | dependency_block（進行中 0、実行可能 0、依存ブロックで未完了 Unit あり） | `result=undecidable:dependency_block`（blocking） |
| c7 | all_units_completed（全 Unit 完了） | `PhaseResolver` が Construction 完了を認識し Operations 遷移判定（`phase=operations` or `phase=construction` + diagnostic `construction_complete`） |

**検証方法**: `skills/aidlc/scripts/verify-construction-recovery.sh`（新規、Unit 002 の verify-inception-recovery.sh と同じアーキテクチャ）を作成し、上記 7 ケースの fixture 生成と期待値出力を行う。`bin/check-bash-substitution.sh` 準拠、`--dest` ディレクトリトラバーサル対策、終了コード規約準拠。

### 最小実地回帰検証（1 Unit）

Construction フェーズの実地回帰を最小規模で実施する（Unit 006 には全フェーズ横断検証を残す）:

- **検証対象**: Unit 001 自身（本サイクル内で既に完了済みの Unit）を再現対象とし、判定仕様が「完了 Unit」として正しく認識することを確認
- **検証項目**:
  - Unit 001 の Unit 定義ファイルを `ArtifactsState` に読み込ませ、`ConstructionStepResolver` が「進行中 Unit なし」「Unit 001 は完了」と判定すること
  - 全 Unit（001, 002）完了時点では、`PhaseResolver` が Construction 完了を検出して Operations への遷移シグナルを出すこと
  - `multi_unit_in_progress` 異常系を再現するため、vTEST-construction-conflict fixture を作り「Unit 001 も Unit 002 も進行中」という状態を捏造した上で `undecidable:conflict` が返ることを確認

実サイクルでの「新規 Unit の Phase 1 → Phase 2 → 完了処理」フルサイクル回帰は Unit 006 で全フェーズ横断検証として実施する（本 Unit では Unit 003 自体がそのフル回帰例として機能する）。

### 初回ロード計測

**ベースライン計測（v2.2.3）**:

```bash
BASE_REF="d88b0074"
TMPDIR=$(mktemp -d)
mkdir -p "$TMPDIR/skills/aidlc/steps/common" "$TMPDIR/skills/aidlc/steps/construction"
git show ${BASE_REF}:skills/aidlc/SKILL.md > "$TMPDIR/skills/aidlc/SKILL.md"
git show ${BASE_REF}:skills/aidlc/steps/common/rules-core.md > "$TMPDIR/skills/aidlc/steps/common/rules-core.md"
git show ${BASE_REF}:skills/aidlc/steps/common/preflight.md > "$TMPDIR/skills/aidlc/steps/common/preflight.md"
git show ${BASE_REF}:skills/aidlc/steps/common/session-continuity.md > "$TMPDIR/skills/aidlc/steps/common/session-continuity.md"
for f in 01-setup 02-design 03-implementation 04-completion; do
    git show ${BASE_REF}:skills/aidlc/steps/construction/${f}.md > "$TMPDIR/skills/aidlc/steps/construction/${f}.md"
done

cd "$TMPDIR" && /tmp/anthropic-venv/bin/python3 -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
files = [
    'skills/aidlc/SKILL.md',
    'skills/aidlc/steps/common/rules-core.md',
    'skills/aidlc/steps/common/preflight.md',
    'skills/aidlc/steps/common/session-continuity.md',
    'skills/aidlc/steps/construction/01-setup.md',
    'skills/aidlc/steps/construction/02-design.md',
    'skills/aidlc/steps/construction/03-implementation.md',
    'skills/aidlc/steps/construction/04-completion.md',
]
total=0
for p in files:
    with open(p) as f: t=f.read()
    n=len(enc.encode(t))
    total+=n
    print(f'{n:>6} tok  {p}')
print(f'{total:>6} tok  TOTAL baseline (v2.2.3)')
"
rm -rf "$TMPDIR"
```

**実装後計測（v2.3.0 Unit 003 実装後）**:

Unit 003 完了後、初回ロード対象は 5 ファイル（共通 4 + `steps/construction/index.md`）のみとなる:

```bash
/tmp/anthropic-venv/bin/python3 -c "
import tiktoken
enc = tiktoken.get_encoding('cl100k_base')
files = [
    'skills/aidlc/SKILL.md',
    'skills/aidlc/steps/common/rules-core.md',
    'skills/aidlc/steps/common/preflight.md',
    'skills/aidlc/steps/common/session-continuity.md',
    'skills/aidlc/steps/construction/index.md',
]
total=0
for p in files:
    with open(p) as f: t=f.read()
    n=len(enc.encode(t))
    total+=n
    print(f'{n:>6} tok  {p}')
print(f'{total:>6} tok  TOTAL v2.3.0 Unit 003')
"
```

**判定基準**: 実装後の TOTAL が **17,980 tok 以下**かつベースライン以下であること。ベースラインより増加する場合は NG としてインデックスの構造を見直す。

### compaction.md / session-continuity.md 整合性検証

- `compaction.md` の phase 別 result テーブルから Construction 行が「現行ルート維持」→「`phase-recovery-spec.md §5.2` 経由」に更新されていることを grep で確認
- `session-continuity.md` の Construction 行が `judge()` 契約経由の新フローに更新されていることを grep で確認
- Operations 行は変更されず Unit 004 待ちの状態であることを確認

### phase-recovery-spec.md §5.2 実装検証

- §5.2 が placeholder（「Unit 003 で埋める」）ではなく実装内容（Stage 1 アルゴリズム節 / Stage 2 の **4 checkpoint** ルール / canonical path 正規化表 / §5.2.4 01-setup.md ステップ7 対応表）を含むことを確認
- `spec_version` がマイナーバージョンアップされること（v1.0 → v1.1 相当）
- §11（Construction 適用例、旧 §10.2 相当）が追加されていること

## 完了条件チェックリスト

- [ ] **【index.md 新設】** `skills/aidlc/steps/construction/index.md` が新規作成され、Unit 001 の章立て（目次 / 分岐ロジック / 判定チェックポイント表 / ステップ読み込み契約 / 汎用構造仕様）と 5 列スキーマを流用している。先頭に Unit 001 / 002 と同形式の Materialized Binding 宣言と `<!-- phase-index-schema: v1 -->` コメントを記載
- [ ] **【Construction checkpoint 実値化】** `construction/index.md` §3 の判定チェックポイント表が **4 行**（`setup_done` / `design_done` / `implementation_done` / `completion_done`）で埋められ、`input_artifacts` 列は Construction 固有の具象パス（canonical path 正規化表準拠）、`priority_order` 列は `spec§5.construction.<checkpoint>` 形式、`undecidable_return` / `user_confirmation_required` 列は `spec§6` / `spec§8`。Stage 1（Unit 特定アルゴリズム）は checkpoint 行ではなく `index.md §3.1` の独立「アルゴリズム節」に配置する
- [ ] **【骨格スキーマ不変】** `construction/index.md` のチェックポイント表の列構造（5 列）と Unit 001 で確立した共通要素（章立て・`StepLoadingContract` 列スキーマ・`<!-- phase-index-schema: v1 -->`）が Unit 001 から変更されていない
- [ ] **【論理インターフェース契約】** `construction/index.md` §3.2 に `judge()` 契約経由 + `result + diagnostics[]` 分離形式のインターフェース記述があり、`ConstructionStepResolver.determine_current_step()` への委譲と「phase 遷移は PhaseResolver の責務（`phaseProgressStatus[construction]` 集約値を直接参照）」が明記されている
- [ ] **【spec §4 Construction 完了条件追加】** spec §4 判定順3（Construction 判定）に `phaseProgressStatus[construction]=incomplete` の前提条件と、全 Unit 完了時に `construction_complete` info 診断を返す旨が追加されている
- [ ] **【spec §5.2 実装】** spec §5.2 が placeholder から実装に昇格し、Stage 1（Unit 特定アルゴリズム: `in_progress_units` / `executable_units` / `pending_units` の決定ツリー）/ Stage 2（**4 checkpoint** の判定ルール）/ canonical path 正規化表 / depth_level=minimal 対応が記述されている
- [ ] **【spec §7 dependency_block 追加】** spec §7 に `dependency_block` 新 reason_code が blocking 分類として追加され、判定条件と期待動作が記述されている
- [ ] **【spec §9 token grammar 正式採用】** spec §9.3 で `spec§5.<phase>.<checkpoint>` 推奨形式が正式規約として明記され、phase 省略形（`spec§5.setup_done` 等）は Inception のみ後方互換 alias として許容される旨が記載されている
- [ ] **【spec §11 Construction 適用例追加】** spec §11（Unit 003 追加セクション、旧 §10.2 相当）に Construction 適用例が追加され、Construction 固有の `ArtifactsState` サンプルと 4 checkpoint の判定例、§5.2.4（01-setup.md ステップ7 対応表）への参照が記載されている
- [ ] **【spec_version 更新】** `phase-recovery-spec.md` の `spec_version` が v1.0 → v1.1 に更新されている
- [ ] **【Inception binding 更新】** `steps/inception/index.md` §3 の `priority_order` 列が `spec§5.inception.<checkpoint>` の明示形に更新され、spec §9 の正式規約と整合している
- [ ] **【Unit 特定アルゴリズム忠実再現】** spec §5.2 の Stage 1 決定ツリーが既存 `steps/construction/01-setup.md` ステップ7 の選定ロジック（進行中優先 → executable 算出 → 0/1/複数分岐）と 1 対 1 対応していることが検証記録されている
- [ ] **【Construction 固有検証】** `verify-construction-recovery.sh` が新規作成され、c1〜c7 の 7 ケースすべてで期待値の単値性が確認されている（normal-unit-setup/design/implementation/completion、multi_unit_in_progress、dependency_block、all_units_completed）
- [ ] **【最小実地回帰検証】** Unit 001 を「完了 Unit」として正しく認識できること、および vTEST-construction-conflict fixture で `undecidable:conflict`（multi_unit_in_progress）が返ることが実測で確認されている
- [ ] **【depth_level=minimal 対応】** spec §5.2 で `depth_level=minimal` の設計省略ケースが明示的に扱われ、`design_done` の判定条件に「設計省略記録があれば design_done=true」が含まれている
- [ ] **【compaction.md / session-continuity.md 更新】** (a) `compaction.md` の暫定ディスパッチャ Construction 行が「`phase-recovery-spec.md §5.2` 経由の正式ルート」に更新されている、(b) `session-continuity.md` の Construction 行が `judge()` 契約経由に更新されている、(c) `automation_mode` 復元手順（compaction.md 手順1〜5）は diff 上変更なし、(d) Operations 行は Unit 004 待ちで維持
- [ ] **【SKILL.md 更新】** 共通初期化フローの construction 行が `steps/construction/index.md` のみを読み込む形に変更されている
- [ ] **【既存ステップファイル重複除去】** `01-setup.md` / `02-design.md` / `03-implementation.md` / `04-completion.md` の 4 ファイルから、インデックスに集約される分岐・判定・`automation_mode` 分岐・AI レビュー分岐の重複記述が除去され、詳細手順（Self-Healing ループ本体、Unit 完了時必須作業手順等）は残っている
- [ ] **【初回ロード計測】** v2.3.0 Unit 003 実装後の Construction 初回ロードが **17,980 tok 以下**かつ v2.2.3 ベースライン以下であることを計測結果で確認済み
- [ ] **【Unit 004 接続点】** `phase-recovery-spec.md §5.3`（Operations）が placeholder のまま維持され、Unit 004 で埋める旨が明記されている
- [ ] **【bash substitution check & markdownlint】** `bash bin/check-bash-substitution.sh`（CI デフォルトスコープ `skills/aidlc/steps/`、`.github/workflows/pr-check.yml` と同一）が違反ゼロで完了、`skills/aidlc/scripts/run-markdownlint.sh v2.3.0` がエラーゼロで完了する

## 依存関係

### 前提 Unit

- Unit 001（Inception インデックス構造のパイロット、汎用構造仕様の確立）
- Unit 002（`phase-recovery-spec.md` 規範仕様、2 段レゾルバ構造、Materialized Binding パターン）

### 本 Unit を依存元とする Unit

- Unit 004（Operations インデックス化、Unit 003 のパターンをそのまま流用）
- Unit 006（計測・クローズ判断、Unit 001〜005 の成果物を一括検証）

## 関連 Issue

- #519: コンテキスト圧縮メイン Issue（ストーリー 2 が本 Unit 対象）

## リスクと留意事項

- **Unit loop 構造の判定複雑度**: Inception と異なり Construction は Unit ごとのループを持つため、判定は 2 段構造になる。設計ステップで Stage 1 / Stage 2 の境界条件を明確化し、単値性を保つことが重要
- **既存 Construction ステップファイルからの重複除去範囲**: どこまでをインデックスに集約し、どこから詳細手順として残すかの線引きが重要。Unit 001 で確立した原則（「分岐・判定はインデックスに集約、具体手順は詳細ファイルに残す」）に従うが、Construction 特有の詳細（Self-Healing ループ、エラー分類判定等）は詳細ファイルに残す判断が必要
- **トークン予算の余裕不足**: Construction 初回ロードのベースラインは v2.2.3 で既に 17,980 tok 付近と想定される。インデックス化で追加される `index.md` のサイズ分、既存ステップファイルからの重複除去で相殺する必要がある。ベースライン計測で初期値を確認してから設計に入る
- **依存 Unit の成果物との整合**: Unit 001（Inception パイロット）/ Unit 002（Materialized Binding / 規範仕様）で確立した構造とパターンを機械的に流用する。独自の構造変更は行わない
- **Operations との境界**: `compaction.md` / `session-continuity.md` の Operations 行は暫定維持のままとし、Unit 004 の責務として残す。Unit 003 で Operations に手を出さないこと
- **実地回帰検証の延期**: Construction フェーズの対話フロー再実行は Unit 006 で一括実施する。本 Unit では静的検証 + トークン計測のみで完了とする
