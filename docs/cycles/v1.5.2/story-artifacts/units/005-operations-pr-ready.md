# Unit: Operations Phase 全Unit完了確認とPR Ready化

## 概要
Operations Phase開始前に全Unitが完了していることを確認し、完了時にドラフトPRをReady for Reviewにする。

## 含まれるユーザーストーリー
- ストーリー 1.3: Operations Phase開始前の全Unit完了確認
- ストーリー 1.4: ドラフトPRのReady for Review化

## 責務
- Operations Phase開始時の全Unit完了確認
- 未完了Unit警告表示
- Operations Phase完了時のドラフトPR Ready化
- PR本文へのサイクル成果追記

## 境界
- Unitの実装状態変更は含まない（参照のみ）
- PRレビュー・マージは含まない（ユーザーが実施）

## 依存関係

### 依存する Unit
- Unit 004: Construction Phase Unit PR作成・マージ（依存理由: Unit PR機能が動作していることが前提）

### 外部依存
- GitHub CLI（gh）
- Gitリポジトリ
- Unit定義ファイル

## 非機能要件（NFR）
- **パフォーマンス**: Unit完了確認は数秒以内
- **セキュリティ**: なし
- **スケーラビリティ**: 大量のUnit（50件以上）にも対応
- **可用性**: GitHub CLI利用不可時は手動操作案内

## 技術的考慮事項
- Unit定義ファイルの「実装状態」セクションを参照
- `gh pr ready` コマンドの使用
- PR本文にUnit一覧、変更ファイル等を追記
- エラーハンドリング（PR not found等）

## 実装優先度
High

## 見積もり
2時間

---
## 実装状態

- **状態**: 完了
- **開始日**: 2025-12-25
- **完了日**: 2025-12-25
- **担当**: -
