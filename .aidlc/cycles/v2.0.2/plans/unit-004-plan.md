# Unit 004 計画: `.claude/settings.json` セットアップ生成（改善）

## 概要

`setup-ai-tools.sh` の `.claude/settings.json` 生成機能を改善する。ハードコードされたテンプレートを外部ファイルに分離し、テンプレートドリフト（テンプレートと実際の必要権限の乖離）を修正する。

## 関連Issue

- #416

## 背景（Codexレビューによる計画変更）

当初の計画は新規スクリプト `setup-settings.sh` の追加だったが、Codexレビューにより `setup-ai-tools.sh` に既に完全な実装（生成・マージ・不正JSON処理・jq/python3フォールバック・wildcard包含判定）が存在することが判明。計画を「既存実装の保守性改善」に変更。

## 変更対象ファイル

1. `skills/aidlc/config/settings-template.json` (新規) - パーミッションテンプレートの外部ファイル
2. `skills/aidlc/scripts/setup-ai-tools.sh` (修正) - テンプレートをファイルから読み込むように変更、staleエントリ修正

## 実装計画

### Phase 1: 設計

1. テンプレートの外部ファイル化方針
2. テンプレートドリフトの特定と修正項目整理

### Phase 2: 実装

1. `settings-template.json` 作成（現行heredocからの抽出 + ドリフト修正）
   - `Skill(codex-review)` を削除（対応スキル不在）
   - `Bash(skills/aidlc/scripts/:*)` の不要コロンを修正 → `Bash(skills/aidlc/scripts/*)`
   - 不足している権限の追加検討（`Bash(bin/*)`, `Bash(dasel:*)` 等はプロジェクト固有のため含めない）
2. `setup-ai-tools.sh` の `_generate_template()` を外部ファイル読み込みに変更
3. テスト: `setup-ai-tools.sh` を実行してsettings.jsonが正しく生成されることを確認

## 完了条件チェックリスト

- [x] パーミッションテンプレートを外部ファイル `settings-template.json` に分離
- [x] `setup-ai-tools.sh` がテンプレートファイルから読み込むように変更
- [x] staleエントリ（`Skill(codex-review)`）の削除
- [x] テンプレートの不正パターン修正（`Bash(skills/aidlc/scripts/:*)`のコロン）
- [x] `setup-ai-tools.sh` の実行テストで正常動作を確認
