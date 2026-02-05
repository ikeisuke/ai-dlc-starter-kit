# Unit: Issue管理プロセス改善

## 概要
Issueライフサイクル管理を明文化し、PRマージ時の自動クローズとラベル・マイルストーン活用を導入して、Issue管理の可視化と追跡性を向上させる。

## 含まれるユーザーストーリー
- ストーリー4: Issueライフサイクル管理の明文化
- ストーリー5: PRマージ時の自動クローズ
- ストーリー6: ラベル・マイルストーン活用

## 責務
- 各フェーズでのIssue取り扱いを明文化
- PR作成時に「Closes #XX」を含めるガイダンス追加
- ステータスラベルの定義と運用フロー追加

## 境界
- GitHub Projects連携は対象外（#31で別途検討）
- 既存のcycle-label.sh、label-cycle-issues.shの大幅な改修は対象外

## 依存関係

### 依存するUnit
- Unit 003: label-cycle-issues.shバグ修正（依存理由: ラベル付けが正しく動作する前提で運用フローを定義）

### 外部依存
- GitHub CLI（gh）

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- `prompts/package/prompts/inception.md`にIssue管理セクション追加
- `prompts/package/prompts/construction.md`にIssue管理セクション追加
- `prompts/package/prompts/operations.md`にIssue管理セクション追加
- ドラフトPR作成時のテンプレートに「Closes #XX」を含める
- ステータスラベル定義ドキュメント作成（in-progress, blocked等）

## 実装優先度
Medium

## 見積もり
中（複数プロンプトの修正、ドキュメント作成）

## 関連Issue
Closes #28

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
