# ステップ4: Unit定義 計画

## 概要
ユーザーストーリーを独立した価値提供ブロック（Unit）に分解する

## 作成するファイル
- `docs/cycles/v1.5.1/story-artifacts/units/001-add-project-type-setting.md`
- `docs/cycles/v1.5.1/story-artifacts/units/002-clarify-history-save-timing.md`
- `docs/cycles/v1.5.1/story-artifacts/units/003-add-cycle-name-to-commit.md`
- `docs/cycles/v1.5.1/story-artifacts/units/004-change-setup-entry-point.md`
- `docs/cycles/v1.5.1/story-artifacts/units/005-consolidate-setup-prompts.md`

## Unit一覧

| # | Unit名 | 優先度 | 依存 | 概要 |
|---|--------|--------|------|------|
| 001 | プロジェクトタイプ設定機能の追加 | Medium | なし | 初回セットアップでタイプ選択、aidlc.toml に保存 |
| 002 | 履歴保存タイミングの明確化 | Low | なし | 記録タイミングをドキュメント化 |
| 003 | コミットメッセージへのサイクル名追加 | Low | なし | `feat: [vX.X.X] Unit NNN完了` 形式に変更 |
| 004 | セットアップエントリーポイントの変更 | Medium | なし | operations.md の案内先を変更 |
| 005 | セットアッププロンプトの統合・整理 | Medium | なし | 責務整理、重複排除 |

## 依存関係
全てのUnitは独立しており、並列実装可能

## 完了条件
- 5つのUnit定義ファイルが作成されている
- 各Unitに責務、境界、依存関係が定義されている
