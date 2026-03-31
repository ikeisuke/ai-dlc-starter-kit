# Unit 001 計画: cleanup trap unbound variable 修正

## 概要
`prompts/package/bin/migrate-config.sh` の `_cleanup` 関数で、`set -u` 下で空配列 `_cleanup_files` の展開時に unbound variable エラーが発生するバグを修正する。

## 変更対象ファイル
- `prompts/package/bin/migrate-config.sh` - `_cleanup` 関数（34行目）

## 実装計画

### Phase 1: 設計
1. `set -u` 下で安全な配列展開パターンを選定する（`${arr[@]+"${arr[@]}"}` vs 配列長チェック）
2. 既存 cleanup 動作への影響点を確認する（trap 経由の呼び出し、一時ファイル有無の分岐）

### Phase 2: 実装
1. `_cleanup` 関数内の `"${_cleanup_files[@]}"` を `set -u` 安全なパターンに修正
2. 検証: dry-run 経路（一時ファイル未生成） → cleanup が `exit 0` で終了すること
3. 検証: 通常経路（一時ファイル生成あり） → 一時ファイルが正しく削除されること
4. 検証: trap 経由の cleanup 呼び出し → エラーシグナル時も cleanup が動作すること

## 完了条件チェックリスト
- [ ] `_cleanup` 関数内の空配列展開を `set -u` 安全にする
- [ ] dry-run 経路（一時ファイル未生成）での正常終了を確認する
- [ ] 通常経路（一時ファイル生成あり）での回帰がないことを確認する
