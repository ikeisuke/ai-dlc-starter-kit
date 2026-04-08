# コンパクション時の対応【自動要約後】

コンテキストがコンパクション（自動要約）された後は、以下を確認・実行する：

1. このプロンプトファイルの内容が保持されているか確認
2. 保持されていない場合、現在のフェーズのプロンプトを読み込む
3. 作業中の進捗情報を確認して作業を継続

**フェーズごとの再読み込みパス**:

| フェーズ | Claude Code | その他（ステップファイル手動読み込み） | 進捗確認先 |
|---------|------------|-----------------------------------|-----------|
| Inception | `/aidlc inception` | `steps/inception/index.md` を読み込み → `inception/progress.md` から未完了ステップを特定 → 契約テーブル経由で該当 `step_id` の `detail_file` を解決（`progress.md` 不在／新規開始時のみ `inception.01-setup` を既定開始点として解決。詳細は後段「復帰フローの確認手順」参照） | `.aidlc/cycles/{{CYCLE}}/inception/progress.md` |
| Construction | `/aidlc construction` | `steps/construction/01-setup.md` から順に読み込み（Unit 003 でインデックス化予定） | Unit定義ファイル（`.aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md`）の「実装状態」セクション |
| Operations | `/aidlc operations` | `steps/operations/01-setup.md` から順に読み込み（Unit 004 でインデックス化予定） | `.aidlc/cycles/{{CYCLE}}/operations/progress.md` |

## スキル再読み込み手順【コンパクション復帰時】

コンパクション後はスキルのコンテキストが失われるため、以下の手順でスキルを再読み込みする。

### 対象スキルと読み込み順序

| 順序 | スキル | 役割 | 再読み込み方法 |
|------|--------|------|--------------|
| 1 | `aidlc` | AI-DLCオーケストレーター | Claude Code: `/aidlc {現在のフェーズ}` で再開。その他: 上記「フェーズごとの再読み込みパス」に従い、Inception はフェーズインデックス（`index.md`）＋契約テーブル経由、Construction/Operations は `01-setup.md` から順に読み込み |
| 2 | `reviewing-*` | AIレビュー | レビュー実行時に自動呼び出しされるため、事前の再読み込みは不要 |
| 3 | `squash-unit` | コミットスカッシュ | squash実行時に自動呼び出しされるため、事前の再読み込みは不要 |

### 復帰フローの確認手順

1. **サイクルの特定**: ブランチ名（`git branch --show-current`）から `cycle/vX.X.X` 形式でサイクルを特定
2. **フェーズの特定**: 成果物の存在で進行度の高い順にフェーズを判定する

   > **【非正本・暫定】この判定表は v2.3.0 から非正本であり、Unit 002（汎用復帰判定基盤）で削除される予定。** Inception フェーズが正本とするのは `steps/inception/index.md` **全体**（章構成: 目次／分岐ロジック／判定チェックポイント骨格／ステップ読み込み契約）である。現時点の Inception 復帰時の実運用ルールは `steps/inception/index.md` の **「4.1 既定ルート」** に定義されている（`3. 判定チェックポイント骨格` は Unit 002 が埋める予定の骨格であり、Unit 001 時点では `TBD` プレースホルダ）。本表は Unit 002 実装完了までの暫定ガードとして残存する。

   | 判定順 | 条件 | 判定フェーズ | 進捗確認先 |
   |-------|------|-----------|-----------|
   | 1 | `.aidlc/cycles/{{CYCLE}}/operations/progress.md` が存在 | Operations | `operations/progress.md` |
   | 2 | `.aidlc/cycles/{{CYCLE}}/inception/progress.md` が存在 かつ 未完了ステップあり（`04-stories-units` / `05-completion` 等が「進行中」「未着手」） | Inception（優先ガード） | `inception/progress.md` |
   | 3 | `.aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md` が存在 かつ 上記に該当しない | Construction | Unit定義ファイルの「実装状態」セクション |
   | 4 | 上記いずれも該当しない | Inception | `inception/progress.md`（存在しない場合は新規開始） |

   **Inception 優先ガード（判定順2）の理由**: v2.2.3 までは Inception の `04-stories-units` 完了後（`units/*.md` 生成後）でも Inception 途中状態を Construction と誤判定するバグがあった（#553）。Unit 001 では暫定的に `inception/progress.md` の未完了ステップ存在チェックを Construction 判定より優先することで回避する。本格的な判定仕様は Unit 002 で `phase-recovery-spec.md` に定義予定。

3. **スキルの再読み込み**: 特定したフェーズに応じて `aidlc` スキルを再読み込み（フェーズ再開コマンドの実行またはステップファイルの手動読み込み）
   - **Inception 復帰時**: `steps/inception/index.md` を読み込み → `inception/progress.md` から未完了ステップ（「進行中」または最初の「未着手」）を特定 → 契約テーブル経由で該当 `step_id` の `detail_file` を解決。`progress.md` が存在しないかパース不能の場合は `inception.01-setup` を既定開始点としてユーザーに再開点の確認を求める
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
