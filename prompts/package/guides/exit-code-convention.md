# 終了コード規約

AI-DLC シェルスクリプトの終了コード規約を定義する。

## 基本原則

- **処理が完了したら exit 0**（警告があっても完了は完了）
- **処理できないなら 0 以外**
- **エラーメッセージは標準エラー出力**（`>&2`）に出す

## 終了コード定義

| コード | 意味 | 用途 |
|--------|------|------|
| 0 | 成功 | 正常完了（警告付き完了を含む） |
| 1 | バリデーションエラー | 引数不正、入力値不正、前提条件不成立 |
| 2 | システムエラー | 環境エラー、外部コマンド失敗、読み取りエラー |

## 使い分け基準

### exit 0: 成功（警告付き完了を含む）

- 処理が正常に完了した場合
- 警告が発生したが処理は完了した場合（警告内容は stdout の `status:warning` 等で通知）
- ヘルプ表示（`--help`）

### exit 1: バリデーションエラー

引数や入力値が不正で、処理を開始できない場合:

- 必須引数の欠落（`--cycle is required`）
- 引数値の形式不正（`--unit must be a 3-digit number`）
- 排他引数の同時指定（`--message and --message-file are mutually exclusive`）
- 不明なオプション（`unknown option`）
- 入力ファイルの不存在・空ファイル
- 前提条件の不成立（`--from is not an ancestor of --to`）

### exit 2: システムエラー

環境や外部コマンドの問題で処理を完了できない場合:

- 外部コマンドの実行失敗（git, curl 等）
- 設定ファイルの読み取りエラー
- 環境未構成（必要なツール未インストール）

## エラーメッセージの出力先

| 種類 | 出力先 | 例 |
|------|--------|-----|
| エラーメッセージ | 標準エラー（`>&2`） | `echo "Error: --cycle is required" >&2` |
| ステータス・結果 | 標準出力 | `echo "status:success"` |
| 警告通知 | 標準出力 | `echo "status:warning"`, `echo "step_result:4:warning:..."` |

**理由**: 呼び出し元が stdout をパースしてステータスを判定するため、エラーメッセージが混入すると誤動作する。

## 呼び出し元でのハンドリングパターン

```text
終了コード 0 → 成功。stdout の status: を確認し、warning なら内容を表示して続行
終了コード 1 → ユーザーに入力修正を求める
終了コード 2 → エラー内容を表示し、ユーザーに対応を求める
```

プロンプト（`rules.md` 等）での記述例:

```text
**終了コード**:
- 0: 値あり
- 1: キー不在
- 2: エラー
```

## ゴールドスタンダード

`bin/migrate-config.sh` を規約準拠の参考実装とする。

**注意**: migrate-config.sh は警告時に `exit 2` を使用しているが、これは本規約の「処理完了したら exit 0」原則に反する。将来のサイクルで `exit 0` + `status:warning` パターンに修正を検討する。

## 準拠状況

| スクリプト | 準拠状態 | 備考 |
|-----------|---------|------|
| read-config.sh | 準拠 | 0=値あり, 1=キー不在, 2=エラー |
| post-merge-sync.sh | 準拠 | |
| update-version.sh | 準拠 | |
| issue-ops.sh | 準拠 | |
| migrate-backlog.sh | 準拠 | |
| pr-ops.sh | 準拠 | |
| check-issue-templates.sh | 準拠 | |
| aidlc-setup.sh | 準拠 | |
| squash-unit.sh | 準拠 | v1.27.3 で exit 2→exit 1 修正 |
| post-merge-cleanup.sh | 準拠 | 警告時 exit 0 + status:warning |
| migrate-config.sh | 要修正 | 警告時 exit 2（本規約では exit 0 が正しい） |
