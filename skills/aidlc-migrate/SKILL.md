---
name: aidlc-migrate
description: >
  v1からv2へのAI-DLC環境移行を実行するスキル。
  プリフライト検証、データ移行、移行後検証を行う。
  Use when the user says "start migrate", "aidlc migrate", "マイグレーション".
argument-hint: "[追加コンテキスト]"
---

# AI-DLC v1→v2 移行

v1からv2への環境移行フローを実行する。以下のステップファイルを順に読み込んで実行すること。

## ステップ実行

1. `steps/01-preflight.md` を読み込んで実行 — プリフライト検証（未コミット変更チェック、v1環境検出）
2. `steps/02-execute.md` を読み込んで実行 — 移行実行（config移行、データ移行、クリーンアップ）
3. `steps/03-verify.md` を読み込んで実行 — 移行後検証（移行成功確認）

## パス解決

- `steps/` および `scripts/` で始まるパスはスキルのベースディレクトリ（このSKILL.mdと同じディレクトリ）からの相対パスとして解決する
- Bashコマンドで `scripts/` 配下のスクリプトを実行する場合は、解決した絶対パスを使用すること
