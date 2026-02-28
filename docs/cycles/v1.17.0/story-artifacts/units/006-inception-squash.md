# Unit: Inception Phase完了時のsquashルール追加

## 概要
Inception Phase完了時に中間コミットを1つのfeatコミットにsquashするルールをcommit-flow.mdとinception.mdに追加する。

## 含まれるユーザーストーリー
- ストーリー 1: Inception Phase完了時のsquash (#234)

## 関連Issue
- #234

## 責務
- commit-flow.md にInception Phase完了時のsquash統合フローを追加
- inception.md の完了時手順（ステップ5: Gitコミット）をsquash統合フロー参照に変更
- squash設定確認 → VCS判定 → ユーザー確認 → squash実行のフロー記載

## 境界
- squash-unit.sh 自体のコード変更は行わない（既存の `--base` 指定で呼び出す）
- Operations Phase完了時のsquash対応はスコープ外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし（プロンプト変更のみ）

## 技術的考慮事項
- squash-unit.sh を `--base` 明示指定で呼び出す（起点: `git merge-base origin/main HEAD`）
- Unit型のsquash統合フローと手順を共通化してDRY原則を維持
- `rules.squash.enabled = false` の場合は通常コミットにフォールバック
- 確認: `git log --oneline $(git merge-base origin/main HEAD)..HEAD` で `feat:` コミットが1件

## 実装優先度
Medium

## 見積もり
中（commit-flow.md + inception.md 修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-27
- **完了日**: 2026-02-27
- **担当**: -
