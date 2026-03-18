# Unit: aidlc-setup同期タイミング最適化

## 概要
メタ開発時のaidlc-setup同期タイミングをPR Ready化直前に移動する。

## 含まれるユーザーストーリー
- ストーリー 4: aidlc-setup同期タイミング最適化（#352）

## 責務
- docs/cycles/rules.mdのカスタムワークフローセクションを更新
- aidlc-setup実行タイミングをCHANGELOG更新・バージョン更新完了後、PRステータス変更直前に変更
- 実行手順の明確化（aidlc-setup実行→コミット→PRステータス変更）
- aidlc-setup実行失敗時のエラーメッセージ表示と手動対応案内の記述

## 境界
- Operations Phaseプロンプト本体（operations.md, operations-release.md）は変更しない
- prompts/package/ 配下のファイルは変更しない
- スターターキット以外のプロジェクトには影響なし

## 依存関係

### 依存する Unit
- なし（docs/cycles/rules.mdのみの変更で他Unitと独立）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 対象ファイル: `docs/cycles/rules.md`（rsync対象外、直接編集可能）
- Operations Phaseのリリース準備フロー内の正確なステップ位置を特定する必要あり

## 実装優先度
Medium

## 見積もり
小規模（1ファイルのセクション更新）

## 関連Issue
- #352

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
