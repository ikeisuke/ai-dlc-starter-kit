# 論理設計: 終了コード規約統一

## 概要

シェルスクリプトの終了コード規約（0: 成功 / 1: バリデーションエラー / 2: システムエラー）を統一する。

## 基本原則

- **処理が完了したら exit 0**（警告があっても完了は完了）
- **処理できないなら 0 以外**
- **エラーメッセージは標準エラー出力**（`>&2`）に出す

## 終了コード規約

| コード | 意味 | 用途 |
|--------|------|------|
| 0 | 成功 | 正常完了（警告付き完了を含む） |
| 1 | バリデーションエラー | 引数不正、入力値不正、前提条件不成立 |
| 2 | システムエラー | 環境エラー、外部コマンド失敗、読み取りエラー |

## 変更仕様

### 1. squash-unit.sh（exit 2 → exit 1 修正）

**変更理由**: 引数バリデーションエラーで exit 2 を使用しているが、規約では exit 1 が正しい。

**変更対象**: `parse_args()` 関数と `validate_*` 関数内の引数バリデーション用 exit 2（22箇所）を exit 1 に変更。

**変更しないもの**: 実行時エラーの exit 1（4箇所: validate_base_format, validate_from_to_args 内の git コマンド失敗系）はそのまま維持。

### 2. post-merge-cleanup.sh（変更なし）

**判断**: post-merge-cleanup.sh は警告時に `OVERALL="warning"` を設定し exit 0 で終了する。これは「処理完了したら exit 0」原則に合致するため、変更不要。警告内容は stdout の `status:warning` で通知済み。

### 3. 終了コード規約ガイド文書

**ファイル**: `prompts/package/guides/exit-code-convention.md`

**内容**:
- 基本原則（完了=0、処理不可=非0、エラーは stderr）
- 終了コード規約の定義（0/1/2）
- 各コードの使い分け基準
- エラーメッセージの出力先ルール
- 呼び出し元での終了コードハンドリングパターン
- migrate-config.sh の警告時 exit 2 は本規約に反する旨を注記

## 呼び出し元との整合性

- `rules.md` の `read-config.sh` 終了コード記述（0: 値あり, 1: キー不在, 2: エラー）→ 規約に準拠済み
- `operations.md` の post-merge-cleanup.sh 判定基準 → exit 0 = 成功（warning 含む）、非0 = 失敗
- `inception.md` / `construction.md` のスクリプト呼び出し時の終了コード参照 → 変更不要

## 今後の対応（バックログ候補）

- migrate-config.sh の警告時 exit 2 → exit 0 + status:warning への修正
