# 実装記録: Unit 003 - アップグレードチェックスキップ機能

## 実装概要

aidlc.tomlの設定でInception Phase開始時のアップグレードチェック（curl）をスキップ可能にした。

## 変更ファイル一覧

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `docs/aidlc.toml` | 修正 | `[rules.upgrade_check]` セクション追加（enabled = true） |
| `prompts/package/prompts/common/rules.md` | 修正 | 「アップグレードチェック設定」仕様セクション追加 |
| `prompts/package/prompts/inception.md` | 修正 | ステップ5冒頭に条件分岐追加 |

## 設計判断

- デフォルト `true` で従来動作を維持（後方互換性）
- 仕様定義は rules.md に集約し、inception.md には参照のみ記載（Single Source of Truth パターン踏襲）
- 既存の boolean 設定パターン（rules.squash.enabled, rules.feedback.enabled 等）と統一した構造
