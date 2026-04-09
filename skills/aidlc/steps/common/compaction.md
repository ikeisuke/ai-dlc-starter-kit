# コンパクション時の対応【自動要約後】

コンテキストがコンパクション（自動要約）された後は、以下を確認・実行する：

1. このプロンプトファイルの内容が保持されているか確認
2. 保持されていない場合、現在のフェーズのプロンプトを読み込む
3. 作業中の進捗情報を確認して作業を継続

**フェーズごとの再読み込みパス**:

| フェーズ | Claude Code | その他（ステップファイル手動読み込み） | 進捗確認先 |
|---------|------------|-----------------------------------|-----------|
| Inception | `/aidlc inception` | `steps/inception/index.md` を読み込み → `judge()` 契約経由で `step_id` を決定 → 契約テーブルから `detail_file` を解決。判定ロジックの本文は `steps/common/phase-recovery-spec.md` §5.1 参照 | `.aidlc/cycles/{{CYCLE}}/inception/progress.md` |
| Construction | `/aidlc construction` | `steps/construction/index.md` を読み込み → `judge()` 契約経由で `step_id` を決定 → 契約テーブルから `detail_file` を解決。判定ロジックの本文は `steps/common/phase-recovery-spec.md` §5.2 参照 | Unit定義ファイル（`.aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md`）の「実装状態」セクション（Stage 1 で参照）＋ `.aidlc/cycles/{{CYCLE}}/history/construction_unit{NN}.md`（Stage 2 で参照） |
| Operations | `/aidlc operations` | `steps/operations/01-setup.md` から順に読み込み（Unit 004 でインデックス化予定。現時点は `judge()` の暫定ディスパッチャで現行ルート維持） | `.aidlc/cycles/{{CYCLE}}/operations/progress.md` |

## スキル再読み込み手順【コンパクション復帰時】

コンパクション後はスキルのコンテキストが失われるため、以下の手順でスキルを再読み込みする。

### 対象スキルと読み込み順序

| 順序 | スキル | 役割 | 再読み込み方法 |
|------|--------|------|--------------|
| 1 | `aidlc` | AI-DLCオーケストレーター | Claude Code: `/aidlc {現在のフェーズ}` で再開。その他: 上記「フェーズごとの再読み込みパス」に従い、Inception / Construction はフェーズインデックス（`index.md`）＋契約テーブル経由、Operations は `01-setup.md` から順に読み込み |
| 2 | `reviewing-*` | AIレビュー | レビュー実行時に自動呼び出しされるため、事前の再読み込みは不要 |
| 3 | `squash-unit` | コミットスカッシュ | squash実行時に自動呼び出しされるため、事前の再読み込みは不要 |

### 復帰フローの確認手順

1. **サイクルの特定**: ブランチ名（`git branch --show-current`）から `cycle/vX.X.X` 形式でサイクルを特定
2. **フェーズと step の判定**: `RecoveryJudgmentService.judge(ArtifactsState)` 契約に従い、復帰すべきフェーズと step を決定する
   - 判定ロジックの本文は `steps/common/phase-recovery-spec.md`（§2〜§8）に定義されている
   - 呼び出し層（本ドキュメント）は `judge()` の戻り値 `PhaseRecoveryJudgment` を消費する形式で記述する
   - `PhaseRecoveryJudgment.phase.result` と `PhaseRecoveryJudgment.step.result` に応じて次の行動を決める

   **戻り値の扱い**:

   | `phase.result` | `step.result` | 次の行動 |
   |---------------|---------------|---------|
   | `inception` | `StepId`（例: `inception.04-stories-units`） | `steps/inception/index.md` の契約テーブルから `step_id` に対応する `detail_file` を解決してロード |
   | `construction` | `StepId`（例: `construction.02-design`） | `steps/construction/index.md` の契約テーブルから `step_id` に対応する `detail_file` を解決してロード |
   | `construction` | `None`（非 blocking。`diagnostics[].type=user_selection_required` と 1 対 1 対応） | Stage 1 で `\|executable_units\| ≥ 2 ∧ automation_mode=manual` のときに発生。`steps/construction/index.md` のみロードし、候補 Unit 一覧を提示してユーザー選択を待つ。選択後は Stage 1 を再評価し Stage 2 へ進む |
   | `construction` | `undecidable:<reason_code>`（例: `undecidable:conflict`, `undecidable:dependency_block`） | Stage 1 / Stage 2 で決着不能（blocking）。`phase-recovery-spec.md` §7.1 の `reason_code` に応じてユーザー確認必須（`automation_mode=semi_auto` でも自動継続禁止、spec §8）。候補 Unit 一覧・依存関係ブロック理由の提示を行い、`steps/construction/index.md` のみロードして再入力を待つ |
   | `operations` | `None`（Unit 002 時点の暫定ディスパッチャ） | 現行ルートに委譲: `.aidlc/cycles/{{CYCLE}}/operations/progress.md` から再開ポイントを特定し、`steps/operations/01-setup.md` から順次ロード |
   | `undecidable:<reason_code>` | - | PhaseResolver 側で決着不能（例: `phase_ambiguous`, `legacy_undecidable`）。ユーザー確認必須（`automation_mode=semi_auto` でも自動継続禁止、spec §8）。`reason_code` に応じて再開点の提示・優先順位ルール表示・修復手順の案内を行う |

   **diagnostics の扱い**:

   | `diagnostics[].type` | severity | 扱い |
   |---------------------|----------|------|
   | `legacy_structure` | warning | 警告表示 + マイグレーション案内（強制しない）。`result` が有効なら判定継続 |
   | `new_cycle_start` | info | 情報表示 + 新規サイクル開始として Inception を開始 |
   | `user_selection_required` | info | 候補 Unit 一覧を表示し、ユーザーに選択を促す（`construction.step.result=None` と対） |
   | `construction_complete` | info | 情報表示 + Construction Phase 完了として Operations Phase への遷移を案内 |

   **注意**: 本ステップの判定ロジックそのもの（フェーズ優先順位、#553 補正、checkpoint 判定条件、Unit 選定アルゴリズム等）は `phase-recovery-spec.md` §4 / §5 に集約されている。本ファイルでは重複記述せず、`judge()` 契約を介した結果消費のみを記述する。Operations の step 判定は Unit 004 完了時に `judge()` 内部実装に統合され、現行ルート委譲は解消される予定。

3. **スキルの再読み込み**: 特定したフェーズに応じて `aidlc` スキルを再読み込み（フェーズ再開コマンドの実行またはステップファイルの手動読み込み）
   - **Inception 復帰時**: `steps/inception/index.md` を読み込み → `judge()` 経由で決定された `step_id` の `detail_file` を契約テーブルから解決
   - **Construction 復帰時**: `steps/construction/index.md` を読み込み → `judge()` 経由で決定された `step_id` の `detail_file` を契約テーブルから解決
4. **コンテキスト変数の復元**: `automation_mode` 等の設定値は下記「automation_mode の復元」手順で再取得
5. **作業の継続**: 進捗源から中断ポイントを特定し、作業を再開

## automation_mode の復元【コンパクション後 必須】

コンパクション後は `automation_mode` が失われるため、**モードに関わらず**以下の手順1〜5を必ず実行する（`common/rules-automation.md` のセミオートゲート仕様を参照）:

### 手順1: automation_mode の再取得【必須】

事前にBashで以下を実行し、結果を確認する:

```bash
scripts/read-config.sh rules.automation.mode
```

**終了コードに基づく処理**:

| 終了コード | 意味 | 処理 |
|-----------|------|------|
| 0 | 値取得成功（defaults.toml のデフォルト値 `manual` が適用される） | 出力値（`semi_auto` または `manual`）を `automation_mode` として保持 |
| 0以外 | エラー（読取エラー、コマンド未検出等） | `automation_mode=manual` にフォールバックし、ユーザーに以下を通知 |

**終了コード 0以外の通知**:

```text
【コンパクション後の設定再取得】
automation_mode の読取に失敗しました（read-config.sh 終了コード: {実際のコード}）。
manual モードにフォールバックします。以降の承認ポイントではユーザー確認を実施します。
```

### 手順2: automation_mode のコンテキスト記録【必須】

再取得した `automation_mode` の値を明示的にコンテキストに記録する:

```text
【コンパクション後の状態確認】
automation_mode = {取得した値}（read-config.sh 終了コード: {実際のコード}）
```

### 手順3: プロンプト・進捗の再読み込み

上記の再読み込み手順（フェーズごとのプロンプトパスと進捗確認先）を実行する。

### 手順4: 作業継続判定

- `automation_mode=semi_auto` の場合: ユーザーに再開確認を求めずに自動的に作業を継続する
- `automation_mode=manual` の場合: ユーザーに状況を報告し、従来フローで作業を継続する

### 手順5: 次の承認ポイントでの検証

コンパクション後の**最初の承認ポイント**で、`automation_mode` に基づく分岐が正しく実行されることを確認する:

- `semi_auto` の場合: セミオートゲート判定（`common/rules-automation.md`）に従い自動承認が実行されるか
- `manual` の場合: ユーザー承認フローが実行されるか
