# Unit 005: リモートデフォルトブランチ取り込み確認 - 計画

## 概要

Inception Phase開始時にリモートデフォルトブランチ（`origin/main`等）との未取り込み差分を検出し、behind時に警告を表示する。自動マージは行わず、通知のみ。既存の`setup-branch.sh`が持つfetch+behind判定ロジックを活用し、ステップ10-3の責務を拡張する形で実装する。

## 既存インターフェースとの関係

### setup-branch.sh（既存）

`setup-branch.sh`は既に以下のロジックを内包:
- `git fetch origin`（GIT_TERMINAL_PROMPT=0で非対話）
- デフォルトブランチ解決（`git remote show origin`経由）
- behind判定
- `main_status:{up-to-date|behind|fetch-failed}`を出力

### 10-3: main最新化チェック（既存）

ブランチ作成後に`setup-branch.sh`出力の`main_status`をパースして表示。

### 本Unit: 責務の集約

**方針**: 新規にfetch+behind判定ロジックをプロンプトに埋め込まず、既存`setup-branch.sh`の`main_status`出力を活用する。10-3の既存仕組みを拡張し、behind時の警告メッセージに「取り込み推奨」の文言を追加する。

## 変更対象ファイル

- `skills/aidlc/steps/inception/01-setup.md` - ステップ10-3のbehind時メッセージを拡張

## 実装計画

### ステップ10-3の拡張

既存の10-3テーブルを以下のように変更:

| main_status | メッセージ（現行） | メッセージ（変更後） |
|-------------|-------------------|---------------------|
| `up-to-date` | 最新です | 最新です（変更なし） |
| `behind` | 未取り込み変更あり（merge/rebase推奨） | ⚠ リモートデフォルトブランチに未取り込みコミットがあります。作業開始前に最新変更を取り込むことを推奨します（git merge/rebase）。 |
| `fetch-failed` | リモート確認失敗（オフライン等） | ⚠ リモートへの接続に失敗しました。取り込み確認をスキップします。（変更なし） |

### 変更の範囲

- `setup-branch.sh`自体の変更は不要（既存出力で十分）
- `01-setup.md`のステップ10-3のテーブル内容のみ更新
- 新規スクリプトの追加は不要

## 完了条件チェックリスト

- [x] `steps/inception/01-setup.md`のブランチ確認ステップにリモートデフォルトブランチとの差分チェックが追加されている
- [x] behind時に警告が表示される仕様が定義されている
- [x] オフライン時にfetch失敗をスキップして続行する仕様が定義されている（既存のsetup-branch.shの`fetch-failed`出力+フェーズ非ブロック動作で充足）
