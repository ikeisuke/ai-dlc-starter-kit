# Unit 001 計画: ドキュメント改善

## 概要

commit-flow.mdのsquashパス表記の明確化と、READMEへの名前付きサイクル説明の追加を行う。

## 変更対象ファイル

1. `prompts/package/prompts/common/commit-flow.md` — squashセクションのパス表記を明確化
2. `README.md` — 名前付きサイクルの説明セクションを追加

## 実装計画

### ストーリー1: commit-flow.mdのsquashパス表記明確化（#356）

- commit-flow.md内の `--message-file /tmp/aidlc-squash-msg.XXXXXX` 表記を `<mktemp生成パス>` のようなプレースホルダー表記に変更
- 対象箇所: squash統合フローセクション内のコマンド例

### ストーリー2: READMEに名前付きサイクルの説明を追加（#355）

- README.mdのサイクル説明部分に名前付きサイクル（Named Cycle）の概要を追記
- 名前付きサイクルの使用例（例: `myproject/v1.0.0`）を記載

## 設計省略の根拠

本Unitはドキュメント修正のみであり、実装コード・テストコードの変更を含まないため、ドメインモデル設計・論理設計をスキップする。

## 完了条件チェックリスト

- [ ] commit-flow.mdのsquash関連セクションにおけるパス表記が明確化されている
- [ ] README.mdに名前付きサイクルの説明セクションが追加されている
