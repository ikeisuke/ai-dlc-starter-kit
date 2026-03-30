---
name: aidlc-feedback
description: >
  AI-DLCへのフィードバックを送信するスキル。
  フィードバック内容のヒアリングとGitHub Issue作成を案内する。
  Use when the user says "AIDLCフィードバック", "aidlc feedback", "フィードバック送信".
argument-hint: "[追加コンテキスト]"
---

# AI-DLC フィードバック送信

フィードバック送信フローを実行する。以下のステップファイルを読み込んで実行すること。

## ステップ実行

1. `steps/feedback.md` を読み込んで実行 — 設定確認、フィードバック内容ヒアリング、Issue作成案内

## パス解決

- `steps/` で始まるパスはスキルのベースディレクトリ（このSKILL.mdと同じディレクトリ）からの相対パスとして解決する
