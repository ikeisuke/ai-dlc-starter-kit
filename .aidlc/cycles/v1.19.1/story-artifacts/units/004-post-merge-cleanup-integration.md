# Unit: post-merge-cleanup.sh運用組み込み

## 概要

Operations PhaseのPRマージ後手順に `post-merge-cleanup.sh` の実行を組み込み、worktree環境でのクリーンアップ自動化を実現する。

## 含まれるユーザーストーリー

- ストーリー 5: post-merge-cleanup.sh運用組み込み（#288）

## 責務

- `operations.md` のPRマージ後手順にworktree環境判定を追加
- worktree環境時の `post-merge-cleanup.sh` 呼び出しフロー（dry-run → 本実行）を追加
- 非worktree環境での従来手順を維持

## 境界

- `post-merge-cleanup.sh` スクリプト自体の変更は含まない
- バージョンタグ付けロジックは変更しない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- `prompts/package/bin/post-merge-cleanup.sh`（既存スクリプト）

## 非機能要件（NFR）

- **パフォーマンス**: N/A（プロンプトファイル変更のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- 変更対象: `prompts/package/prompts/operations.md`
- worktree環境判定は `.git` ファイルの存在で判定（ディレクトリなら通常、ファイルならworktree）
- `--dry-run` 失敗時は本実行をスキップする旨を明記

## 実装優先度

Medium

## 見積もり

小（operations.mdの1セクション修正のみ）

## 関連Issue

- #288

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-08
- **完了日**: 2026-03-08
- **担当**: @ai
