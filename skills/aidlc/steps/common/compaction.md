# コンパクション時の対応【自動要約後】

コンテキストがコンパクション（自動要約）された後は、以下を確認・実行する：

1. このプロンプトファイルの内容が保持されているか確認
2. 保持されていない場合、現在のフェーズのプロンプトを読み込む
3. 作業中の進捗情報を確認して作業を継続

**フェーズごとの再読み込みパス**:

| フェーズ | Claude Code | その他（ステップファイル手動読み込み） | 進捗確認先 |
|---------|------------|-----------------------------------|-----------|
| Inception | `/aidlc inception` | `steps/inception/01-setup.md` から順に読み込み | `.aidlc/cycles/{{CYCLE}}/inception/progress.md` |
| Construction | `/aidlc construction` | `steps/construction/01-setup.md` から順に読み込み | Unit定義ファイル（`.aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md`）の「実装状態」セクション |
| Operations | `/aidlc operations` | `steps/operations/01-setup.md` から順に読み込み | `.aidlc/cycles/{{CYCLE}}/operations/progress.md` |

## スキル再読み込み手順【コンパクション復帰時】

コンパクション後はスキルのコンテキストが失われるため、以下の手順でスキルを再読み込みする。

### 対象スキルと読み込み順序

| 順序 | スキル | 役割 | 再読み込み方法 |
|------|--------|------|--------------|
| 1 | `aidlc` | AI-DLCオーケストレーター | Claude Code: `/aidlc {現在のフェーズ}` で再開。その他: 上記「フェーズごとの再読み込みパス」に従い、ステップファイルを `01-setup.md` から順に読み込み |
| 2 | `reviewing-*` | AIレビュー | レビュー実行時に自動呼び出しされるため、事前の再読み込みは不要 |
| 3 | `squash-unit` | コミットスカッシュ | squash実行時に自動呼び出しされるため、事前の再読み込みは不要 |

### 復帰フローの確認手順

1. **サイクルの特定**: ブランチ名（`git branch --show-current`）から `cycle/vX.X.X` 形式でサイクルを特定
2. **フェーズの特定**: 進行度の高い順に `session-state.md` の存在を確認する（`aidlc-cycle-info.sh` のフェーズ判定ロジックと同じ優先順位）
   - `.aidlc/cycles/{{CYCLE}}/operations/session-state.md` が存在 → Operations Phase
   - `.aidlc/cycles/{{CYCLE}}/construction/session-state.md` が存在 → Construction Phase
   - `.aidlc/cycles/{{CYCLE}}/inception/session-state.md` が存在 → Inception Phase
   - いずれも存在しない場合 → 成果物ベースのフォールバック判定（下記参照）
3. **session-state.md がない場合のフォールバック**: 成果物の存在で進行度の高い順にフェーズを判定する（`aidlc-cycle-info.sh` と同一ロジック）

   | 判定順 | 条件 | 判定フェーズ | 進捗確認先 |
   |-------|------|-----------|-----------|
   | 1 | `.aidlc/cycles/{{CYCLE}}/operations/progress.md` が存在 | Operations | `operations/progress.md` |
   | 2 | `.aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md` が存在 | Construction | Unit定義ファイルの「実装状態」セクション |
   | 3 | 上記いずれも該当しない | Inception | `inception/progress.md`（存在しない場合は新規開始） |

4. **スキルの再読み込み**: 特定したフェーズに応じて `aidlc` スキルを再読み込み（フェーズ再開コマンドの実行またはステップファイルの手動読み込み）
5. **コンテキスト変数の復元**: `automation_mode` 等の設定値は下記「automation_mode の復元」手順で再取得
6. **作業の継続**: session-state.md またはフォールバック進捗源から中断ポイントを特定し、作業を再開

## session-state.md の生成【コンパクション前】

コンパクションが発生した時点で、`common/session-continuity.md` の「session-state.md の生成」セクションに従い、現在の作業状態を保存する。

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
