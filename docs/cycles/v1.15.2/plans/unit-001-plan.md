# Unit 001 計画: シェルスクリプトバグ修正・バリデーション強化

## 概要

`check-open-issues.sh` と `suggest-version.sh` の入力バリデーション追加およびエラー処理改善を行う。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/bin/check-open-issues.sh` | `--limit` の数値バリデーション追加、`gh issue list` エラー処理改善 |
| `prompts/package/bin/suggest-version.sh` | `calculate_next_version` の case 文に default ケース追加 |

## エラー出力方針

- **CLIエントリポイント** (`check-open-issues.sh`): stdout に `error:<エラーコード>` 形式で出力。外部コマンドの生エラー詳細は stderr に分離し、stdout には固定エラーコードのみ出力する
- **内部関数** (`suggest-version.sh` の `calculate_next_version`): stderr にエラーメッセージ + `return 1`。呼び出し元が戻り値で判断する

## 実装計画

### 1. `check-open-issues.sh` の修正

#### 1a. `--limit` オプションの数値バリデーション追加
- `--limit` の値未指定時（`$#` が 1以下）のチェックを追加し、`error:missing-limit-value` を出力して `exit 1`
- 引数解析部分（`--limit` ケース）で `$2` が正の整数であることを検証
- 正規表現 `^[1-9][0-9]*$` で数値判定（0や負数、空文字を排除）
- バリデーション失敗時は `error:invalid-limit-value` を出力して `exit 1`

#### 1b. `gh issue list` 失敗時のエラー処理改善
- 現状: `result=$(gh issue list ... 2>&1) || { echo "error:${result}"; exit 1; }` でエラー出力を直接表示
- 改善: stdout には固定エラーコード `error:gh-issue-list-failed` のみ出力し、`gh` の生エラー詳細は stderr に出力する

### 2. `suggest-version.sh` の修正

#### 2a. `calculate_next_version` の case 文に default ケース追加
- `case "$type" in` に `*)` ケースを追加
- 不正な type が渡された場合、stderr にエラーメッセージを出力して `return 1`

## 完了条件チェックリスト

- [ ] `check-open-issues.sh` の `--limit` オプションに数値バリデーションを追加（値未指定・不正値の両方をハンドリング）
- [ ] `check-open-issues.sh` の `gh issue list` 失敗時のエラー処理改善（固定エラーコード + 詳細はstderr）
- [ ] `suggest-version.sh` の case 文に default ケースを追加
