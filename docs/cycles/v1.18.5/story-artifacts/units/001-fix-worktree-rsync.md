# Unit: worktreeメタ開発rsync同期修正

## 概要

worktree環境でupgrade-aidlc.shを実行した際に、worktree内の`prompts/package/`を正しくrsyncソースとして使用するよう修正する。

## 含まれるユーザーストーリー

- ストーリー 1: worktreeメタ開発でのrsync同期修正 (#274)

## 関連Issue

- #274

## 責務

- `upgrade-aidlc.sh`の`resolve_starter_kit_root()`関数でworktree環境を検出し、worktreeルートを返すよう修正
- worktree判定失敗時のフォールバック実装

## 境界

- プロジェクトモード（Tier 3）の変更は含まない
- `sync-package.sh`の変更は含まない

## 依存関係

### 依存するUnit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- **パフォーマンス**: 既存の処理速度を維持
- **セキュリティ**: パストラバーサルリスクなし
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

- worktreeでは`.git`がファイル（`gitdir: ...`の内容）であり、通常リポジトリでは`.git`がディレクトリ
- worktree内のスクリプト実行パスからworktreeルートを正しく解決する必要がある

## 実装優先度

High

## 見積もり

小（スクリプト1ファイルの関数修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-05
- **完了日**: 2026-03-06
- **担当**: @ai
