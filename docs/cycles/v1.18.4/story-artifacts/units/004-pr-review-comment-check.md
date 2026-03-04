# Unit: PRマージ前レビューコメント確認

## 概要
Operations PhaseのPRマージ前にレビューコメント（Codex自動レビュー等）を確認するステップを追加する。プロジェクト固有機能。

## 含まれるユーザーストーリー
- ストーリー 4: PRマージ前レビューコメント確認（#268）

## 関連Issue
- #268

## 責務
- Operations Phaseのステップ6.6.7（新規）「レビューコメント確認」の手順定義
- `gh api` によるPRレビューコメント取得（レビュー + コメントの両方）
- 未対応指摘の判定（CHANGES_REQUESTED状態、または未返信トップレベルコメント）
- 未対応指摘の警告表示
- 指摘対応→修正push→@codex review→再確認のループ定義
- API失敗時のエラーハンドリング

## 境界
- スターターキット共通プロンプト（operations-release.md）は変更しない
- 修正対象は `docs/cycles/rules.md` のみ（プロジェクト固有ルールとして定義し、Operations Phaseから参照される形）
- Codex以外のレビューツールのコメント取得は対象外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- GitHub CLI（`gh api`）
- GitHub API（`/pulls/{PR番号}/reviews`, `/pulls/{PR番号}/comments`）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: API失敗時にマージ可否をユーザーに明示的に選択させること

## 技術的考慮事項
- レビュー状態取得: `gh api repos/{owner}/{repo}/pulls/{PR番号}/reviews`
- レビューコメント取得: `gh api repos/{owner}/{repo}/pulls/{PR番号}/comments`
- 未対応判定基準（REST APIベースの簡易判定）:
  - レビュー状態が CHANGES_REQUESTED のレビューが存在する
  - 未返信のトップレベルレビューコメントが存在する（`in_reply_to_id` がnullのコメントに返信がないもの）
  - 注: REST APIではスレッドのresolved状態を直接取得できないため、上記の簡易判定を採用。厳密なresolved判定が必要な場合はGraphQL APIへの移行を検討
- レビュー状態種別: APPROVED/CHANGES_REQUESTED/COMMENTED/PENDING/DISMISSED
- Codex再レビュールール（rules.md）との整合性
- 修正対象: `docs/cycles/rules.md`

## 実装優先度
Medium

## 見積もり
中（API仕様調査 + 未対応判定ロジック設計 + rules.mdへの手順追記）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
