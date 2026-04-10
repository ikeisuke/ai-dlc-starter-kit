# 論理設計: Unit 002 汎用復帰判定仕様

## 概要

Unit 002 のドメインモデル（`PhaseResolver` / `PhaseLocalStepResolver` / `PhaseRecoverySpec` / `RecoveryCheckpoint` 等）を**ドキュメント層**（Markdown ファイル）として materialize する論理設計を定義する。本 Unit の成果物はコードではなく規範仕様書と binding ファイルであり、コンポーネントは「ドキュメントとその相互参照構造」として実装される。

**重要**: この論理設計では**コードは書かず**、ドキュメント構成・セクション階層・参照関係のみを定義する。具体的な仕様本文・binding テーブルの具体値はコード生成ステップ（Phase 2）で作成する。

## アーキテクチャパターン

**パターン名**: **Normative Spec + Materialized Binding**（ドキュメント層への適用）

**選定理由**:

- AI-DLC スキルは「シェルコマンド可能なコード」と「AI エージェントに読ませるドキュメント」の混合物であり、本 Unit は後者に属する
- 判定規則を 1 箇所（`phase-recovery-spec.md`）に集約しつつ、各フェーズのインデックス（`inception/index.md` 等）が必要最小限の具象値（パス）と spec 参照だけを持つ構造は、ソフトウェアにおける「Normative Reference + Concrete Binding」パターンに相当する
- ポリシー変更時の波及範囲を spec 本文 1 箇所に限定でき、binding 層は参照トークンだけを更新（または更新不要）となる
- Unit 003/004 で Construction/Operations 側の binding を追加する際、spec 側の共通ルールに依存する構造が自動的に実現される（機械的流し込みが可能）

**依存方向**:

```text
compaction.md / session-continuity.md                 (呼び出し層)
        │
        ▼
RecoveryJudgmentService.judge()                        (唯一の公開 API、spec §6 で定義)
        │
        ├─→ PhaseResolver.resolvePhase()               (spec §4)
        │
        └─→ InceptionStepResolver                      (spec §5、非公開下位契約)
                │
                ▼
         steps/inception/index.md (binding 層)         (spec§5.<checkpoint> 参照)
                │
                ▼
         steps/common/phase-recovery-spec.md            (規範仕様層 - Normative Spec)
```

一方向の参照関係であり、循環依存は存在しない。

**境界の整理**: 本 Unit の成果物はドキュメントであり、AI エージェントは物理的には複数のファイルを読む。「公開 API」の境界は**論理的な契約層**として定義する:

- **呼び出し層（`compaction.md` / `session-continuity.md`）は `judge()` 契約を介して扱う**: これらのファイルは直接判定ロジックを埋め込まず、「`judge()` の結果を消費する」記述形式で書かれる。つまり `compaction.md` は「`RecoveryJudgmentService.judge()` を呼び、戻り値 `PhaseRecoveryJudgment` の `phase` と `step` に応じて次の行動を決める」という手順記述になる
- **内部実装データとしての `inception/index.md` / `phase-recovery-spec.md`**: これらは `RecoveryJudgmentService` / `PhaseResolver` / `InceptionStepResolver` が内部で読む実装データ（仕様書 + binding テーブル）。AI エージェントは物理的に読み取るが、これは「`judge()` の内部実装を仕様書として読む」行為であり、呼び出し層から見れば内部データへの直接依存ではない
- **手順記述上の区別**: `compaction.md` の本文では「`judge()` を呼んで結果を受け取る」という抽象レベルで記述し、spec 本文や binding テーブルの具体的な判定条件を重複記述しない。実装者（AI エージェント）が `judge()` の内部仕様を知る必要がある場合は、`phase-recovery-spec.md` / `inception/index.md` を参照するが、これは「内部実装の仕様書を読む」行為と位置付ける

## コンポーネント構成

### レイヤー / モジュール構成（ドキュメントファイル単位）

```text
skills/aidlc/steps/
├── common/
│   ├── phase-recovery-spec.md               ← 新規 (§1〜§10、判定規則の本文)
│   ├── compaction.md                        ← 更新 (判定順テーブル削除、暫定ディスパッチャ記述)
│   └── session-continuity.md                ← 更新 (2段レゾルバ構造の案内)
└── inception/
    └── index.md                             ← 更新 (binding 層: TBD セル → 具象値 + spec 参照トークン)
```

### コンポーネント詳細

#### phase-recovery-spec.md（新規・規範仕様層）

- **責務**:
  - 判定規則の正本として判定ロジックの本文を保持する
  - 2段レゾルバ構造（`PhaseResolver` / `PhaseLocalStepResolver`）の責務分離を定義する
  - 戻り値インターフェース契約（`result + diagnostics[]`）を定義する
  - 異常系4系統の分類（blocking/warning）と判定条件を定義する
  - Inception への適用例と Construction/Operations placeholder を提供する
- **依存**: なし（本 Unit ではこのファイルが最下流の参照先）
- **公開インターフェース**: セクション番号（§1〜§10）と `spec§N` 参照トークン形式

#### steps/inception/index.md（更新・Inception binding 層）

- **責務**:
  - Inception フェーズの目次・分岐ロジック・判定チェックポイント骨格を保持する（Unit 001 時点の責務）
  - 本 Unit で追加: 判定チェックポイント表の `TBD` セルを具象値（input_artifacts パス）+ spec 参照トークンで埋める
  - 本 Unit で修正: 正本宣言を「materialized binding」形式に変更する
  - 本 Unit で更新: 論理インターフェース契約セクション（3.1）を `result + diagnostics[]` 分離形式に更新する
- **依存**: `phase-recovery-spec.md`（`spec§N` 参照）
- **公開インターフェース**: 既存の `StepLoadingContract` テーブル + 更新後の `RecoveryCheckpoint` テーブル

#### steps/common/compaction.md（更新・呼び出し層その1）

- **責務**:
  - コンパクション復帰時のスキル再読み込み手順を提供する（既存責務）
  - `automation_mode` 復元手順を提供する（既存責務、不変）
  - 本 Unit で削除: 「復帰フローの確認手順」内の判定順テーブル（判定順1〜4）
  - 本 Unit で追加: `judge()` 契約を介した復帰判定手順記述。「`RecoveryJudgmentService.judge()` を呼び、戻り値 `PhaseRecoveryJudgment` の `phase` と `step` に応じて次の行動を決める」という抽象レベルの記述とし、spec 本文や判定条件を重複記述しない
  - Construction/Operations 復帰時の暫定ルート（`step=None` の場合に現行の成果物ベース判定へ委譲）を明示
- **契約層の依存**: `RecoveryJudgmentService.judge()`（論理的な公開 API）
- **内部実装データへの物理参照**: Construction/Operations 向けの暫定ルートとして、Unit 定義ファイルや `operations/progress.md` への参照は残る（Unit 003/004 で spec 参照形式に置換予定）
- **公開インターフェース**: コンパクション復帰時の手順テキスト

#### steps/common/session-continuity.md（更新・呼び出し層その2）

- **責務**:
  - フェーズ再開時の進捗復元手順の共通エントリポイント（既存責務）
  - 本 Unit で更新: Inception 行を `judge()` 契約経由の記述に更新（`judge()` の結果 `phase=inception` 時の進捗源として `inception/progress.md` を指す）
  - 本 Unit で維持: Construction/Operations 行は現行のまま + Unit 003/004 で更新予定のコメントを追記
- **契約層の依存**: `RecoveryJudgmentService.judge()`
- **公開インターフェース**: フェーズ別進捗源テーブル

## インターフェース設計

### コンポーネント間のインターフェース契約

本 Unit の成果物はドキュメントのため、インターフェースは「参照先のファイルパスとセクション見出し」として表現される。

#### インターフェース: `SpecRule` （phase-recovery-spec.md の公開面）

- **参照方法**: `spec§N` 形式の参照トークン（N はセクション番号）
- **解決方法**: `phase-recovery-spec.md` の該当見出しへのジャンプ
- **提供セクション**:
  - `spec§1`: 仕様の位置付けとスコープ
  - `spec§2`: 2段レゾルバ構造
  - `spec§3`: ArtifactsState 入力モデル
  - `spec§4`: PhaseResolver（フェーズ判定仕様）
  - `spec§5`: PhaseLocalStepResolver（Step 判定仕様）
  - `spec§6`: 戻り値インターフェース契約（`result + diagnostics[]`）
  - `spec§7`: 異常系4系統（blocking/warning 分類）
  - `spec§8`: ユーザー確認必須性ルール
  - `spec§9`: フェーズインデックスからの参照方法
  - `spec§10`: Inception への適用例

#### インターフェース: `RecoveryCheckpoint` （binding 層のスキーマ）

- **所在**: `steps/inception/index.md` セクション3（判定チェックポイント骨格）
- **スキーマ**: Unit 001 で確立された5列（列構造・行構造は不変。ただし各列の意味は Unit 002 の設計に合わせて再定義する）

| 列名（Unit 001） | 型 | Unit 001 時点 | Unit 002 での意味の確定 |
|-----------------|-----|--------------|----------------------|
| `checkpoint_id` | string | 5行分記入済み | 変更なし |
| `input_artifacts` | list of path | `TBD` | 具象パス（ファイル名を含む） |
| `priority_order` | spec ref | `TBD` | **この checkpoint の step 判定規則への参照** = `spec§5.<checkpoint_id>` 形式（checkpoint 単位で異なる値）。phase 全体優先順位への参照ではない |
| `undecidable_return` | spec ref | `TBD` | 戻り値インターフェース契約への参照 = `spec§6`（全 checkpoint 共通） |
| `user_confirmation_required` | spec ref | `TBD` | ユーザー確認必須性ルールへの参照 = `spec§8`（全 checkpoint 共通） |

**列名の意味変更について**: Unit 001 時点では `priority_order` 列は「同点時の優先順位」の spec 参照として想定されていたが、Unit 002 の設計で「phase 優先順位は `PhaseResolver` の固定責務、checkpoint は自身の step 判定規則のみ参照」という原則に整理したため、`priority_order` 列は「checkpoint 単位の step 判定規則参照（`spec§5.<checkpoint_id>`）」として意味を確定する。Unit 001 の骨格スキーマ（列構造・行構造）は維持するため、列名自体は変更しない（互換性保持）。spec §9（フェーズインデックスからの参照方法）に本意味の確定を明記する。

#### インターフェース: `RecoveryCheckpoint` 具体値（Inception 適用後）

| checkpoint_id | input_artifacts | priority_order | undecidable_return | user_confirmation_required |
|---------------|-----------------|----------------|--------------------|----------------------------|
| `inception.setup_done` | 具象パス | `spec§5.setup_done` | `spec§6` | `spec§8` |
| `inception.preparation_done` | 具象パス | `spec§5.preparation_done` | `spec§6` | `spec§8` |
| `inception.intent_done` | 具象パス | `spec§5.intent_done` | `spec§6` | `spec§8` |
| `inception.units_done` | 具象パス | `spec§5.units_done` | `spec§6` | `spec§8` |
| `inception.completion_done` | 具象パス | `spec§5.completion_done` | `spec§6` | `spec§8` |

#### インターフェース: `RecoveryJudgmentService.judge()` の論理契約（唯一の公開 API）

実装コードとしては存在しないが、仕様書内で以下の擬似インターフェースとして記述する:

```text
operation: judge
signature: judge(artifacts_state: ArtifactsState) -> PhaseRecoveryJudgment

input:
  - artifacts_state: ArtifactsState
    - cycleRoot: path
    - fileExistenceMap: Map<path, bool>
    - progressMarks: Map<string, ProgressStatus>
    - phaseProgressStatus: Map<PhaseName, PhaseProgressStatus>   # phase 単位の集約
    - legacyMarkers: List<path>

output:
  - phase_recovery_judgment: PhaseRecoveryJudgment
    - phase: PhaseResolution
      - result: PhaseName | "undecidable:<reason_code>"
      - diagnostics: List<Diagnostic>
    - step: Optional<StepResolution>
      - result: StepId | "undecidable:<reason_code>"
      - diagnostics: List<Diagnostic>

semantics:
  - judge() は復帰判定の唯一の公開 API。呼び出し層 (compaction.md / session-continuity.md) は必ず本 API を入口とする
  - PhaseResolver.resolvePhase() が先に評価される（spec §4）
    - 入力は phaseProgressStatus を含む ArtifactsState
    - 判定順: conflict → Operations (incomplete のみ) → Construction (Inception 完了条件必須) → Inception → 新規開始フォールバック (Inception + diagnostics に new_cycle_start を追加)
  - 結果が Inception の場合のみ InceptionStepResolver.determine_current_step() (spec §5、非公開下位契約) が呼ばれる
  - Construction/Operations と判定された場合、step は None を返し、呼び出し側が現行ルートに委譲する (暫定ディスパッチャ)
  - result が undecidable の場合、diagnostics は空でも可 (blocking と独立)
  - diagnostics に warning/info が含まれても result は継続可能
```

この擬似インターフェースは `phase-recovery-spec.md §6` に記載される。下位契約 `InceptionStepResolver.determine_current_step()` は `§5` に記載され、呼び出し層からは直接参照されない（`judge()` 経由でのみアクセス）。

## スクリプトインターフェース設計

本 Unit の主要成果物はドキュメントだが、検証用の補助スクリプト（検証ケース再現ツール）を作成する。

### verify-inception-recovery.sh（新規・検証用）

#### 概要

Unit 002 の正常系6ケース + 異常系4ケース + #553 再現シナリオを `.aidlc/cycles/vTEST-*` ディレクトリに再現し、`phase-recovery-spec.md` の判定条件に照らして期待 `step_id` が導出されるかを手動で確認するための**セットアップ補助スクリプト**。自動判定ロジックは実装せず、「入力スナップショットを作って人間/AIが spec に照らして判定する」ためのテストフィクスチャ生成器とする。

#### 配置先

`skills/aidlc/scripts/verify-inception-recovery.sh`

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `--case` | 必須 | ケース識別子（`normal-1` / `normal-2` / `normal-3` / `normal-4a` / `normal-4b` / `normal-5` / `abnormal-missing_file` / `abnormal-conflict` / `abnormal-format_error` / `abnormal-legacy_structure` / `i553-1a` / `i553-1b` / `i553-2`） |
| `--dest` | 任意 | セットアップ先ディレクトリ（デフォルト: `.aidlc/cycles/vTEST-<case>`） |
| `--clean` | 任意 | 既存のテストディレクトリを削除してから作成 |
| `--dry-run` | 任意 | 実際のファイル作成は行わず、作成予定のファイルリストのみ表示 |

#### 成功時出力

```text
verify-case:<case>:<dest>:setup-ready
expected_phase:<期待値>
expected_step_id:<期待値>
expected_diagnostics:<warning種別リスト、なければ'none'>
spec_refs:<照合すべきspec§N参照のリスト>
```

- 終了コード: `0`
- 出力先: stdout

#### エラー時出力

```text
【verify-inception-recovery エラー】
理由: <エラー内容>
```

- 終了コード: `1`（一般エラー）、`2`（引数エラー）
- 出力先: stderr

#### 使用コマンド

```bash
# 正常系ケース4a のフィクスチャを作成
scripts/verify-inception-recovery.sh --case normal-4a

# 異常系 conflict のフィクスチャを作成
scripts/verify-inception-recovery.sh --case abnormal-conflict

# #553 再現シナリオ1a のフィクスチャを作成（dry-run で確認）
scripts/verify-inception-recovery.sh --case i553-1a --dry-run

# 既存のテストディレクトリをクリーンアップしてから作成
scripts/verify-inception-recovery.sh --case normal-5 --clean
```

#### 使用しないコマンド置換

スクリプト内では `$(...)` / バッククォートを使用せず、引数はすべて `"$1"` 等の位置パラメータで受ける。`.aidlc/rules.md` のコーディング規約に従う。

## データモデル概要

本 Unit ではデータベーススキーマは扱わない。ドキュメント間の参照関係とファイル形式のみ定義する。

### ファイル形式

| ファイル | 形式 | 主要構造 |
|---------|------|---------|
| `phase-recovery-spec.md` | Markdown | 10セクション階層（H2 が §1〜§10） |
| `inception/index.md`（更新部分） | Markdown + テーブル | 判定チェックポイント表（5列） |
| `compaction.md`（更新部分） | Markdown + テーブル | PhaseResolver 暫定ディスパッチャ記述（判定順テーブル削除後） |
| `session-continuity.md`（更新部分） | Markdown + テーブル | フェーズ別進捗源テーブル（Inception 行更新） |
| `verify-inception-recovery.sh` | Bash shell script | ケース分岐関数 + フィクスチャ生成ロジック |

### 参照トークン形式

本 Unit で確定する正式文法:

| トークン形式 | 用途 | 例 |
|------------|------|------|
| `spec§N` | spec トップレベルセクションへの参照 | `spec§4`（§4 フェーズ判定仕様）、`spec§6`（§6 戻り値契約）、`spec§8`（§8 ユーザー確認ルール） |
| `spec§N.<checkpoint_id>` | spec §N 配下の checkpoint 単位サブルールへの参照 | `spec§5.setup_done`、`spec§5.preparation_done`、`spec§5.intent_done`、`spec§5.units_done`、`spec§5.completion_done` |

**正規化ルール**:

- `spec§5.<checkpoint_id>` の `<checkpoint_id>` は Unit 001 の `checkpoint_id` 列の値と完全一致する文字列（例: `setup_done`）を採用する。フェーズ prefix（`inception.`）は spec §5 内でフェーズ別サブセクションを分ける想定のため省略可。Unit 003/004 で Construction/Operations を追加する際は `spec§5.<phase>.<checkpoint_id>` の拡張形式を使う
- `spec§N.M` 形式（数値サブセクション）は本 Unit では未使用。将来的に spec §N の下位に数値サブセクションを設ける必要が生じた場合のみ導入する
- トークンは常に小文字・アンダースコア区切り。ハイフンは使わない（`step_id` の `01-setup` とは別系統）

## 処理フロー概要

### ユースケース1: コンパクション後の復帰判定（Inception フェーズ）

**ステップ**:

1. コンパクション後、`compaction.md` の手順に従い `automation_mode` を再取得
2. `compaction.md` は `RecoveryJudgmentService.judge(ArtifactsState)` を呼ぶ
3. `judge()` の戻り値 `PhaseRecoveryJudgment` を受け取る
   - 内部では `PhaseResolver.resolvePhase()`（spec §4）→ `InceptionStepResolver.determine_current_step()`（spec §5）が順に呼ばれる
   - 内部実装の仕様は `phase-recovery-spec.md` + `inception/index.md` のチェックポイント表に記述されている
4. `compaction.md` は `PhaseRecoveryJudgment.phase.result` が `inception` であることを確認
5. `PhaseRecoveryJudgment.step.result`（`StepId`）を取得
6. `PhaseRecoveryJudgment.step.diagnostics` を確認し、warning（`legacy_structure`）や info（`new_cycle_start`）があれば表示
7. 決定された `step_id` を元に、詳細ステップファイル（`01-setup.md` 〜 `05-completion.md`）を必要時ロード

**関与するコンポーネント**:

- 呼び出し層: `compaction.md`
- 契約層: `RecoveryJudgmentService.judge()`
- 内部実装データ: `inception/index.md`（binding）/ `phase-recovery-spec.md`（規範仕様）

### ユースケース2: コンパクション後の復帰判定（Construction/Operations フェーズ、暫定ルート）

**ステップ**:

1. 上記ユースケース1 のステップ1〜3 と同じ（`judge()` 呼び出しまで）
2. `PhaseRecoveryJudgment.phase.result` が `construction` または `operations` と判定された場合、`PhaseRecoveryJudgment.step` は `None` となる（本 Unit では phase-local resolver を提供しないため）
3. `compaction.md` は `step=None` を検知し、暫定ルートへフォールバック
4. Construction: Unit 定義ファイルの「実装状態」セクションから再開ポイントを特定
5. Operations: `operations/progress.md` から再開ポイントを特定
6. 以降は現行の `01-setup.md` から順次ロード（Unit 003/004 完了時に `judge()` 内部実装へ置換予定）

**関与するコンポーネント**:

- 呼び出し層: `compaction.md`
- 契約層: `RecoveryJudgmentService.judge()`
- 暫定フォールバック先: 現行の Construction/Operations ステップファイル（Unit 定義ファイル / `operations/progress.md`）

### ユースケース3: #553 再現シナリオ1a の正しい判定

**ステップ**（呼び出し層から見た流れ）:

1. `compaction.md` が `RecoveryJudgmentService.judge(ArtifactsState)` を呼ぶ
   - ArtifactsState: `units/*.md` 存在 + `inception/progress.md`「完了処理」未着手 + `history/inception.md` なし + `phaseProgressStatus[inception]=incomplete`
2. `judge()` が内部で `PhaseResolver.resolvePhase()` を呼ぶ
3. `resolvePhase()` が判定順に評価（内部処理、spec §4 に基づく）:
   - conflict なし
   - `phaseProgressStatus[operations]=unknown` → Operations スキップ
   - Construction 条件: `units/*.md` 存在だが、`phaseProgressStatus[inception]!=completed` のため Construction スキップ（#553 補正ガードが本質的に発動）
   - Phase = Inception と決定
4. `judge()` が内部で `InceptionStepResolver.determine_current_step()` を呼ぶ
5. `determine_current_step()` が `BoundaryClassifier.classify()` を使って 04/05 境界を判定（内部処理、spec §5.units_done / §5.completion_done に基づく）
6. `progress.md`「完了処理」未着手 + `history/inception.md` なし → `inception.04-stories-units` が単一値として返る
7. `judge()` は `PhaseRecoveryJudgment(phase=inception, step=StepResolution(result=inception.04-stories-units))` を返す
8. `compaction.md` は戻り値を消費して次のアクション（`04-stories-units.md` のロード）に進む

**関与するコンポーネント**:

- 呼び出し層: `compaction.md`
- 契約層: `RecoveryJudgmentService.judge()`
- 内部実装: `PhaseResolver`（spec §4） / `InceptionStepResolver`（spec §5） / `BoundaryClassifier`

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 復帰時の追加ロードはインデックスファイル1個のみに限定（Unit 定義の NFR を参照）
- **対応策**:
  - `compaction.md` と `session-continuity.md` は既に常時ロード対象
  - 新設 `phase-recovery-spec.md` は **on-demand ロード**とし、実際に Phase Resolver / Step Resolver の判定ルールが必要になった時点でのみ読み込む
  - `inception/index.md` は Unit 001 で既に on-demand ロード対象。本 Unit の更新でサイズが増加する可能性があるため、Unit 006 の計測で 15,000 tok 制約を再確認

### セキュリティ

- **要件**: ドキュメント変更のため直接的なセキュリティ要件なし
- **対応策**:
  - `verify-inception-recovery.sh` で `--case` / `--dest` 引数をバリデーション（`^[a-z0-9][a-z0-9-]*$` パターン、予約名禁止）
  - heredoc 終端トークンの注入回避（rules.md のコーディング規約に従う）

### スケーラビリティ

- **要件**: 他フェーズ（Construction/Operations）への流用可能性
- **対応策**:
  - `phase-recovery-spec.md §5` に Construction/Operations placeholder セクションを用意
  - Unit 003/004 は placeholder を埋めるだけで機械的に組み込み可能
  - spec 参照トークンの正式文法は本文書「参照トークン形式」節に従う（`spec§N` / `spec§N.<checkpoint_id>` / `spec§5.<phase>.<checkpoint_id>`）

### 可用性・信頼性

- **要件**: 異常系4系統すべてで自動継続を禁止し、ユーザー判断を必須とする（ただし warning は継続可）
- **対応策**:
  - blocking 3系統は `result=undecidable:<reason_code>` を返し、`automation_mode=semi_auto` でもフォールバック条件に該当
  - warning 1系統（`legacy_structure`）は `diagnostics[]` に蓄積し、`result` は継続可（警告表示は必須）
  - `BoundaryClassifier` は境界条件を単値に固定することで、判定結果のブレ（04/05 両方候補など）を排除

### 後方互換性

- **要件**: v2.2.x 以前の成果物構造検出時は警告表示のみ（強制マイグレーションなし）
- **対応策**:
  - `LegacyStructureDetector` が `session-state.md` 等の旧マーカーを検出した場合、`diagnostics[]` に warning として追加
  - `result` 判定は継続可能（blocking 条件と独立）
  - 旧判定テーブルを参照していた既存ドキュメントが残存する可能性を検証手順で grep チェック

## 技術選定

本 Unit の成果物はドキュメント（Markdown）+ Bash シェルスクリプト（検証補助）のみのため、言語・フレームワーク選定は限定的:

- **言語**: Markdown（GFM）+ Bash（POSIX 互換を意識、`dasel` v3 の使用は既存スクリプトと同様）
- **フレームワーク**: なし
- **ライブラリ**: `dasel`（既存プリフライトスクリプトと共通）
- **データベース**: 使用しない

## 実装上の注意事項

### セキュリティ上の注意点

- **スクリプト引数のバリデーション**: `verify-inception-recovery.sh` の `--case` は enum 形式（正規表現でチェック）、`--dest` は `.aidlc/cycles/vTEST-` プレフィックス必須
- **heredoc 終端トークンの無害化**: `rules.md` の rules に従う
- **コマンド置換禁止**: `$(...)` / バッククォート使用禁止（`.aidlc/rules.md` のコーディング規約、CI チェックあり）

### パフォーマンス上の注意点

- **phase-recovery-spec.md のトークン量**: 本仕様書は 10 セクション構成かつ Inception 適用例を含むため、目安として 3,000〜4,000 tok を想定。on-demand ロード前提のため初回ロード対象には含めない
- **inception/index.md のサイズ増加**: 判定チェックポイント表の5セルが具象値になり、論理インターフェース契約セクションが更新される分、Unit 001 時点から増加する。Unit 006 の計測で 15,000 tok 制約を要再確認

### 保守性・拡張性に関する注意点

- **spec 参照トークンの単一責任**: `spec§N` は常に `phase-recovery-spec.md` のセクション N を指す。他のファイルから参照先を変える場合は spec 側の構造変更と同期する必要がある
- **Unit 003/004 接続点**: `phase-recovery-spec.md §5` に Construction/Operations placeholder を明示的に置き、Unit 003/004 の担当者が「どこに追記すればよいか」を迷わないようにする
- **spec_version と binding_schema_version の独立管理**: `phase-recovery-spec.md` の冒頭に `spec_version`（規範仕様本文のコンテンツバージョン、例: `v1.0`）を記載する。一方、`inception/index.md` の先頭コメント（`<!-- phase-index-schema: v1 -->`）は `binding_schema_version`（binding テーブルの列スキーマバージョン）を表し、両者は**独立管理**とする。互換性ルール:
  - `spec_version` の minor 更新（例: `v1.0 → v1.1`、本文の追記・明確化のみ）: binding 側は追随不要
  - `spec_version` の major 更新（例: `v1.x → v2.0`、セクション番号や参照トークンの変更）: binding 側の参照トークンも同期更新が必要
  - `binding_schema_version` の更新（列の追加・削除・型変更）: 全 phase index の同期更新が必要。spec 本文は参照トークン方式を維持する限り追随不要
  - spec §1（位置付けとスコープ）に「`spec_version` と `binding_schema_version` の独立管理ルール」を明記する

### ガイド照合

Unit 定義の技術的考慮事項に基づき、以下の既存ガイドと照合する:

- `guides/exit-code-convention.md`: `verify-inception-recovery.sh` の終了コードが規約（`0`=成功、`1`=一般エラー、`2`=引数エラー）に準拠していることを確認
- `guides/error-handling.md`: blocking と warning の分離が既存のエラーハンドリング規約と矛盾しないことを確認
- `guides/backlog-management.md`: 本 Unit 作業中に発生した気づきはバックログに登録する（即時実装優先ルール適用時は現サイクルで処理）

（ガイドが存在しない場合は該当セクションのみスキップ）

## 不明点と質問（設計中に記録）

[Question] `phase-recovery-spec.md` の配置は `steps/common/` で確定してよいか？ `steps/common/rules-automation.md` 等と同じディレクトリに置く形で統一。
[Answer] Unit 定義および計画で `steps/common/phase-recovery-spec.md` と明記されているため確定。配置を変更しない。

[Question] `verify-inception-recovery.sh` は Phase 2 コード生成ステップで作成するか、それともドキュメント化のみで実スクリプト作成は省略するか？
[Answer] Phase 2 で実スクリプトを作成する。理由: (1) 異常系4系統 + 正常系6ケース + #553 3ケースで合計 13 ケースを手動セットアップするのは現実的でなく再現性が低い、(2) セットアップ補助に留めるため自動判定ロジックは実装せず複雑度を抑えられる、(3) Unit 006 の最終検証でも再利用できる。

[Question] `compaction.md` の暫定ディスパッチャ記述で、Construction/Operations 復帰時の現行ルートは具体的にどの記述を残すか？
[Answer] 現行の「Inception 優先ガード（判定順2）」の記述は削除するが、「Unit 定義ファイルの『実装状態』セクション」「`operations/progress.md`」という参照先情報は残す。これにより PhaseResolver が Construction/Operations と判定した後の具体手順が明確になる。
