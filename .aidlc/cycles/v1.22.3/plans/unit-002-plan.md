# Unit 002 計画: check-bash-substitution.shスコープ制限

## 概要

`check-bash-substitution.sh` のバリデーションを `project.name = ai-dlc-starter-kit` のリポジトリでのみ実行されるようにスコープを制限する。対象外リポジトリではスキップして正常終了する。

## 変更対象ファイル

- `bin/check-bash-substitution.sh` — `main()` 関数にスコープ判定を追加

## 実装計画

1. `main()` 関数の `REPO_ROOT` 取得後に、スコープ判定関数 `_check_scope()` を呼び出す
2. `_check_scope()` の実装:
   - まず `"$REPO_ROOT/docs/aidlc/bin/read-config.sh" project.name` を `set +e` ブロックで実行（`REPO_ROOT` 絶対パスを使用）
   - `read-config.sh` が成功した場合: 取得値で判定
   - `read-config.sh` が失敗した場合（ファイル不在、dasel未導入等）: 軽量フォールバックとして `grep` で `docs/aidlc.toml` から直接 `project.name` を読み取る
   - フォールバックも失敗した場合: 警告を出力して `exit 0`（スキップ）
3. 取得した `project.name` に応じた分岐:
   - `ai-dlc-starter-kit`: チェック続行
   - 上記以外: スキップメッセージを出力して `exit 0`

## 完了条件チェックリスト

- [ ] `check-bash-substitution.sh` スクリプト内に `project.name` をチェックする条件分岐を追加
- [ ] 対象外リポジトリではスキップして正常終了する
- [ ] `project.name` 未設定・読取失敗時は警告を出力してスキップする
