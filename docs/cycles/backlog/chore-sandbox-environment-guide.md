# サンドボックス環境での実行ガイド作成

- **発見日**: 2026-01-10
- **発見フェーズ**: Construction
- **発見サイクル**: v1.7.0
- **優先度**: 中

## 概要

AIエージェントをサンドボックス環境で実行するためのガイドを作成する。

## 詳細

Unit 002（AIエージェント許可リストガイド）の設計時に、許可リスト + denylist よりも「全許可 + sandbox」アプローチが推奨されることが判明。

**背景**:
- 許可リストは複合コマンド（`&&`, `|` 等）で都度承認が必要
- sandboxなら全許可しても被害が限定的
- AI-DLCの複合コマンドも問題なく実行可能

**対象ツール**:
- Claude Code: Docker/コンテナ + `--dangerously-skip-permissions`
- Codex CLI: `sandbox: "workspace-write"` または `"read-only"`
- Kiro CLI: sandbox設定

## 対応案

1. `prompts/package/guides/sandbox-environment.md` を作成
2. 各AIエージェントのsandbox設定方法を記載
3. Docker/コンテナ環境での実行例を記載
4. セキュリティ上の注意事項を記載

## 関連

- Unit 002: AIエージェント許可リストガイド
