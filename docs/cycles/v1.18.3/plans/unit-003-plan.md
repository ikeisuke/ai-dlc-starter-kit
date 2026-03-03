# Unit 003 計画: upgrade-aidlc.sh改善（--config廃止 + dasel必須化）

## 概要

upgrade-aidlc.shの不要な`--config`オプションを廃止し、daselを必須依存として明確化する。

## 変更対象ファイル

- `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`

## 実装計画

### 変更1: --configオプション廃止

1. ヘルプテキスト（L46）から `--config PATH` 行を削除
2. コメント（L13）から `--config PATH` 行を削除
3. 引数解析（L61-68）の `--config)` ケースを削除
4. Step 3のCONFIG_PATH非デフォルト時の透過ロジック（L211-213）を削除

### 変更2: dasel必須化

1. 引数解析直後（L90の後）に `command -v dasel` チェックを追加
2. 未インストール時は `error:dasel-required` を出力し、インストール手順を表示して exit 1
3. Step 3の dasel未インストール時フォールバック（L241-245）を削除

### 変更しない箇所

- `CONFIG_PATH="docs/aidlc.toml"` のデフォルト値定義（L31）はそのまま維持
- `read-config.sh` や `check-setup-type.sh` 自体のdaselフォールバック
- migrate-config.sh への `--config` 透過（L279、これは別コマンドへの引数であり問題なし）

## 完了条件チェックリスト

- [ ] `--config` オプションの引数解析が削除されている
- [ ] `--config` を指定するとエラーになる
- [ ] `CONFIG_PATH` は `docs/aidlc.toml` にハードコード
- [ ] 下流への `--config` 透過ロジックが削除されている
- [ ] `command -v dasel` 失敗時にエラーメッセージ+インストール手順が表示される
- [ ] 不要なdaselフォールバック処理が削除されている
