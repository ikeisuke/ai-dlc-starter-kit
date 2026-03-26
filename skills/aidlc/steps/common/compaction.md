# コンパクション時の対応【自動要約後】

コンテキストがコンパクション（自動要約）された後は、以下を確認・実行する：

1. このプロンプトファイルの内容が保持されているか確認
2. 保持されていない場合、現在のフェーズのプロンプトを読み込む
3. 作業中の進捗情報を確認して作業を継続

**フェーズごとの再読み込みパス**:

| フェーズ | プロンプトパス | 進捗確認先 |
|---------|-------------|-----------|
| Inception | `/aidlc inception` | `.aidlc/cycles/{{CYCLE}}/inception/progress.md` |
| Construction | `/aidlc construction` | Unit定義ファイル（`.aidlc/cycles/{{CYCLE}}/story-artifacts/units/*.md`）の「実装状態」セクション |
| Operations | `/aidlc operations` | `.aidlc/cycles/{{CYCLE}}/operations/progress.md` |

## session-state.md の生成【コンパクション前】

コンパクションが発生した時点で、`common/session-continuity.md` の「session-state.md の生成」セクションに従い、現在の作業状態を保存する。

## automation_mode の復元【コンパクション後 必須】

コンパクション後は `automation_mode` が失われるため、**モードに関わらず**以下の手順1〜5を必ず実行する（`common/rules.md` のセミオートゲート仕様を参照）:

### 手順1: automation_mode の再取得【必須】

事前にBashで以下を実行し、結果を確認する:

```bash
skills/aidlc/scripts/read-config.sh rules.automation.mode
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

- `semi_auto` の場合: セミオートゲート判定（`common/rules.md`）に従い自動承認が実行されるか
- `manual` の場合: ユーザー承認フローが実行されるか
