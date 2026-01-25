# Unit: KiroCLI Skills対応

## 概要

KiroCLI Skills機能を調査し、AI-DLC用スキルファイルを作成する。

## 含まれるユーザーストーリー

- ストーリー5: KiroCLI Skills対応

## 責務

- KiroCLI Skills機能の調査
- 調査レポートの作成
- KiroCLI用スキルファイルの作成
- 既存スキルとの共存確認

## 対象ファイル

- `prompts/package/skills/kiro/SKILL.md`（新規作成）
- `docs/aidlc/skills/kiro/SKILL.md`（Operations Phaseでrsync同期）
- `docs/cycles/v1.9.2/research/kirocli-skills.md`（調査レポート）

## 境界

- KiroCLI本体の機能追加は対象外
- 既存スキル（codex, claude, gemini）の変更は対象外

## 依存関係

### 依存する Unit

なし（依存する他のUnitがない）

### 外部依存

- KiroCLI v1.24.0以降
- KiroCLI公式ドキュメント

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項

- 調査項目: フロントマター形式、必須セクション、resources指定方法
- スキルファイル保存先: prompts/package/skills/kiro/SKILL.md
- 調査レポート保存先: docs/cycles/v1.9.2/research/kirocli-skills.md

## 実装優先度

Medium

## 見積もり

調査 + 実装

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-01-26
- **完了日**: 2026-01-26
- **担当**: Claude
