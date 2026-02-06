# Unit: セルフアップデート処理の簡略化

## 概要

Operations Phaseのセルフアップデート処理（メタ開発用）を `/aidlc-upgrade` スキル呼び出しに簡略化する。

## 含まれるユーザーストーリー

- US5: セルフアップデート処理の簡略化

## 関連Issue

- なし（改善対応）

## 責務

- `docs/cycles/rules.md` のカスタムワークフロー（Operations Phase完了時の必須作業）を簡略化
- `/aidlc-upgrade` スキル呼び出しへの置き換え

## 境界

- `docs/cycles/rules.md` の変更のみ
- `prompts/package/prompts/operations.md` は変更しない（汎用手順のため）
- `aidlc-upgrade` スキル自体の変更は行わない（既存を活用）

## 依存関係

### 依存するUnit

- なし（独立して実装可能）

### 外部依存

- `docs/aidlc/skills/aidlc-upgrade/SKILL.md` が存在すること（前提条件）

## 非機能要件（NFR）

- **UX**: 手順が1行で完結
- **一貫性**: スキル経由で統一されたアップグレードフロー

## 技術的考慮事項

- 変更対象: `docs/cycles/rules.md`（プロジェクト固有）
- 前提: `aidlc-upgrade` スキルが既に存在し動作すること
- スキル実行時に「`prompts/setup-prompt.md` を読み込んでください」が案内される

## 実装優先度

Medium

## 見積もり

極小（テキスト変更のみ）

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-02-07
- **完了日**: -
- **担当**: @claude
