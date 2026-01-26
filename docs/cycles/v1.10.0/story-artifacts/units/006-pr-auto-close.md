# Unit: PRによるIssue自動Close機能

## 概要
Operations PhaseのPR作成時に `Closes #xx` を自動記載し、PRマージ時に対応Issueが自動でCloseされるようにする。

## 含まれるユーザーストーリー
- ストーリー 4: PRによるIssue自動Close (#114)

## 責務
- Operations PhaseのPR作成セクション更新
- 対応Issue番号の取得ロジック追加
- PR本文テンプレートへの `Closes #xx` 組み込み

## 境界
- PRマージ後のIssue Close処理自体はGitHub標準機能に依存
- Issue番号の自動取得は Intent/Unit定義からの参照に限定

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub標準機能（キーワード: `Closes`, `Fixes`, `Resolves`）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 対象ファイル: `prompts/package/prompts/operations.md`
- PR作成コマンド: `gh pr create`

**AIレビュー指摘への対応（Unit定義で特定）**:
- 記載位置: Operations Phaseの「PRの作成」または「リリース準備」セクション
- フォーマット:
  ```markdown
  ## Closes

  - Closes #126
  - Closes #128
  - ...
  ```
- Issue番号の取得元:
  1. `docs/cycles/{{CYCLE}}/requirements/intent.md` の対象Issue一覧
  2. または `docs/cycles/{{CYCLE}}/requirements/setup-context.md` の対象Issue
- 複数Issueがある場合は各行に `Closes #xx` を記載

## 実装優先度
Medium

## 見積もり
小規模（プロンプト修正）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
