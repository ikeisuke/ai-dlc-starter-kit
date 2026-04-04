# Unit 002 計画: post-merge-sync.sh出力ステータス明確化

## 概要
post-merge-sync.shの最終出力ステータスを`status:success(warn:N)`から`status:warning`に変更する。

## 完了条件チェックリスト
- [ ] 警告0件時に `status:success` が出力されること
- [ ] 警告1件以上時に `status:warning` が出力されること（exit 0のまま）
- [ ] 旧形式 `status:success(warn:N)` が出力されないこと

## 変更対象ファイル
- `bin/post-merge-sync.sh` — 最終ステータス出力の変更（269-272行目付近）
