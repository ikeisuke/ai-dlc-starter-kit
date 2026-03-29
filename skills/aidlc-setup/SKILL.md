---
name: aidlc-setup
description: >
  AI-DLC環境の初期セットアップを実行するスキル。
  プロジェクトの検出、config.toml生成、AIツールセットアップを行う。
  Use when the user says "start setup", "aidlc setup", "セットアップ".
argument-hint: "[追加コンテキスト]"
---

# AI-DLC セットアップ

初期セットアップフローを実行する。以下のステップファイルを順に読み込んで実行すること。

## ステップ実行

1. `steps/01-detect.md` を読み込んで実行 — 環境検出（config.toml存在チェック、v1環境検出）
2. `steps/02-generate-config.md` を読み込んで実行 — 設定生成（プロジェクト情報推論、config.toml生成）
3. `steps/03-migrate.md` を読み込んで実行 — AIツールセットアップ・データ移行

## パス解決

- `steps/` および `scripts/` で始まるパスはスキルのベースディレクトリ（このSKILL.mdと同じディレクトリ）からの相対パスとして解決する
- Bashコマンドで `scripts/` 配下のスクリプトを実行する場合は、解決した絶対パスを使用すること
- `templates/` 配下のテンプレートファイルも同様にベースディレクトリからの相対パスで解決する
