# Unit: main最新化チェック判定ロジック

## 概要
setup-branch.shにmainブランチの最新化チェック機能を実装する。`git fetch origin` 後に `origin/main` との差分を検出し、ステータス行として出力する。

## 含まれるユーザーストーリー
- ストーリー1a: main最新化チェックの判定ロジック実装（#307）

## 関連Issue
- #307

## 責務
- setup-branch.shにmain最新化チェックロジックを追加
- `main_status:up-to-date` / `main_status:behind` / `main_status:fetch-failed` のステータス行を出力
- fetch失敗時はチェックをスキップして処理続行

## 境界
- プロンプトファイルの変更は含まない（Unit 003で対応）
- Operations Phaseのチェックは含まない（Unit 003で対応）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- git（`git fetch origin`, `git rev-parse`, `git merge-base` 等）

## 非機能要件（NFR）
- **パフォーマンス**: `git fetch` はネットワーク依存のため、タイムアウト処理は不要（gitデフォルトに委ねる）

## 技術的考慮事項
- 既存のsetup-branch.sh出力フォーマット（`key:value` 形式）に合わせてステータス行を追加
- mainブランチ名はデフォルト `main` とし、`master` もフォールバックとしてサポート

## 実装優先度
High

## 見積もり
小〜中（タスク数: スクリプト1ファイルへの機能追加。Unit 001/004/005と並行実装可能）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
