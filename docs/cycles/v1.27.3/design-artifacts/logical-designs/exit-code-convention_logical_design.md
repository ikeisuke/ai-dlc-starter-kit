# 論理設計: 終了コード規約統一

## 概要

シェルスクリプトの終了コード規約（0: 成功 / 1: バリデーションエラー / 2: システムエラー・警告）を統一する。

## 終了コード規約

| コード | 意味 | 用途 |
|--------|------|------|
| 0 | 成功 | 正常完了 |
| 1 | バリデーションエラー | 引数不正、入力値不正、前提条件不成立 |
| 2 | システムエラー・警告 | 環境エラー、外部コマンド失敗、警告付き完了 |

## 変更仕様

### 1. squash-unit.sh（exit 2 → exit 1 修正）

**変更理由**: 引数バリデーションエラーで exit 2 を使用しているが、規約では exit 1 が正しい。

**変更対象**: `parse_args()` 関数と `validate_*` 関数内の引数バリデーション用 exit 2（23箇所）を exit 1 に変更。

**変更しないもの**: 実行時エラーの exit 1（4箇所: validate_base_format, validate_from_to_args 内の git コマンド失敗系）はそのまま維持。

### 2. post-merge-cleanup.sh（警告時 exit 2 追加）

**変更理由**: 警告条件発生時に OVERALL="warning" を設定するが exit 0 で終了している。規約では警告付き完了は exit 2。

**変更内容**: migrate-config.sh のゴールドスタンダード（`_has_warnings` フラグパターン）に合わせる。

1. `OVERALL` 変数はそのまま維持（出力メッセージ生成に使用）
2. スクリプト末尾の exit 処理で `OVERALL="warning"` の場合 exit 2 を返す

**注意**: `prompts/package/bin/post-merge-cleanup.sh`（正本）を編集。`docs/aidlc/bin/` は直接編集禁止。

### 3. 終了コード規約ガイド文書

**ファイル**: `prompts/package/guides/exit-code-convention.md`

**内容**:
- 終了コード規約の定義（0/1/2）
- 各コードの使い分け基準
- ゴールドスタンダード（migrate-config.sh）への参照
- 呼び出し元での終了コードハンドリングパターン

## 呼び出し元との整合性

- `rules.md` の `read-config.sh` 終了コード記述（0: 値あり, 1: キー不在, 2: エラー）→ 規約に準拠済み
- `inception.md` / `construction.md` のスクリプト呼び出し時の終了コード参照 → 変更不要
