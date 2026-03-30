# Unit: クリーンアップ・マイグレーション

## 概要
旧構造（docs/aidlc/, prompts/）を削除し、v1→v2の移行ガイド（`docs/guides/migration-v1-to-v2.md`）を作成する。

## 含まれるユーザーストーリー
- ストーリー 10: 旧構造クリーンアップ

## 責務
- 旧ディレクトリ削除: `docs/aidlc/prompts/`, `docs/aidlc/bin/`, `docs/aidlc/skills/`, `docs/aidlc/templates/`, `docs/aidlc/config/`, `docs/aidlc/tests/`
- 旧ファイル削除: `prompts/package/`（二重構造解消）、`prompts/setup-prompt.md`
- `.claude/skills/` シンボリックリンク削除
- `docs/guides/migration-v1-to-v2.md` 作成
- 廃止対象一覧（計画ファイル参照）の完全実施

## 境界
- 移行ガイドの作成のみ（自動移行ツールの実装はUnit 008のsetup phase内）
- docs/cycles/ 配下のサイクル成果物は削除しない

## 依存関係

### 依存する Unit
- Unit 009: CLAUDE.md / AGENTS.md 刷新（依存理由: 新しいCLAUDE.md/AGENTS.mdが存在してから旧構造を削除する）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 特になし
- **セキュリティ**: 特になし
- **スケーラビリティ**: 特になし
- **可用性**: 特になし

## 技術的考慮事項
- 削除前に全参照パスの更新が完了していることを確認
- `.aidlc/` ディレクトリ構造をこのリポジトリ自身にも適用（ドッグフーディング）

## 実装優先度
Medium

## 見積もり
中

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-27
- **完了日**: 2026-03-27
- **担当**: AI
- **エクスプレス適格性**: -
- **適格性理由**: -
