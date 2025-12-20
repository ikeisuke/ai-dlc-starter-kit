# セットアップエントリーポイントの変更

- **発見日**: 2025-12-20
- **発見フェーズ**: Operations
- **発見サイクル**: v1.5.0
- **優先度**: 中

## 概要

通常のサイクル開始時は `docs/aidlc/prompts/setup.md` を呼び出し、アップデートの場合のみスターターキットの `prompts/setup-prompt.md` を呼び出すようにする。

## 詳細

現在の案内:
- 次サイクル開始時に `prompts/setup-prompt.md` を案内している

問題点:
- セットアップ済みプロジェクトでは `docs/aidlc/prompts/setup.md` を使うべき
- `prompts/setup-prompt.md` はアップデート確認やバージョン判定を行うため、毎回呼び出す必要はない

あるべき姿:
- **通常のサイクル開始**: `docs/aidlc/prompts/setup.md` を使用
- **アップデート時のみ**: `prompts/setup-prompt.md` を使用

## 対応案

- operations.md の「次のサイクルを開始するプロンプト」を修正
- README.md の案内を修正
- 各フェーズの完了メッセージを修正
