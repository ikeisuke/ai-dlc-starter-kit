# Unit: rules.md MD040 違反修正

## 概要

`.aidlc/rules.md` L107 / L122 の fenced code block に言語指定を追加し、markdownlint-cli2 の MD040 違反を 0 件にする。最も小さい修正で着手しやすく、Construction Phase のヒート目的に適する。

## 含まれるユーザーストーリー

- ストーリー 6: rules.md L107/L122 の MD040 違反修正

## 責務

- `.aidlc/rules.md` の対象 fenced code block への言語指定追加（`text` 等）
- markdownlint-cli2 で MD040 違反 0 件を確認
- 内容（コマンド表記）は不変、言語指定追加のみ

## 境界

- 他の lint ルール違反の修正は対象外（MD040 のみに限定）
- `rules.md` の他の場所（L107 / L122 以外）は対象外
- markdownlint 設定（`.markdownlint.json` / `markdownlint-cli2` config）の変更は対象外

## 依存関係

### 依存する Unit

- なし（独立して実装可能）

### 外部依存

- `markdownlint-cli2`（既存依存、`.aidlc/config.toml [rules.linting]` で `enabled = true` / `command = "npx markdownlint-cli2"`）

## 非機能要件（NFR）

- **可読性**: コードブロックがレンダリング時に従来通り表示されること
- **互換性**: rules.md の意味的内容（指示文・コマンド・手順）が変化しないこと

## 技術的考慮事項

- 言語指定は `text` を採用（コマンド名のみのプレーンテキストブロックのため）。シンタックスハイライト不要
- 修正前後で markdownlint 全体出力が green になることを確認

## 関連Issue

- #614

## 実装優先度

Low

## 見積もり

10〜15 分（修正 5 分 + lint 確認 5 分 + コミット）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 完了
- **開始日**: 2026-05-09
- **完了日**: 2026-05-09
- **担当**: AI-DLC (Claude Code)
- **エクスプレス適格性**: -
- **適格性理由**: -
