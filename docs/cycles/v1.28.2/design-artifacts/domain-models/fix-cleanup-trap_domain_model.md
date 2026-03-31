# ドメインモデル: cleanup trap unbound variable 修正

## 対象ドメイン
シェルスクリプトの一時ファイル管理とcleanup処理

## エンティティ
- `_cleanup_files`: 一時ファイルパスを保持する配列。`_mktmp()` 呼び出し時に要素が追加される
- `_cleanup`: EXIT trap に登録されるcleanup関数。`_cleanup_files` の全要素を削除する

## 問題のドメインルール
- Bash の `set -u` (nounset) オプション下では、要素が0件の配列 `"${arr[@]}"` の展開が unbound variable エラーとなる
- `_cleanup_files` は `()` で初期化されるが、`set -u` 下では空配列の `[@]` 展開がエラーとなる

## 解決パターン
- `${arr[@]+"${arr[@]}"}` パターン: 配列が設定済みの場合のみ展開する条件付き展開
- Bash 3.2+ 互換（macOS デフォルトシェル対応）
