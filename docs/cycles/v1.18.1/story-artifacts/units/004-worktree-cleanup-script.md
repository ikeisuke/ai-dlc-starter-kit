# Unit: worktreeクリーンアップスクリプト

## 概要
PRマージ後の手動クリーンアップ作業（5ステップ）を自動化するスクリプトを新規作成する。

## 含まれるユーザーストーリー
- ストーリー 4: worktreeクリーンアップスクリプト (#227)

## 責務
- `post-merge-cleanup.sh`の新規作成
- メインリポジトリの自動検出（git worktree list）
- 5ステップの自動実行（pull、fetch、detach、ブランチ削除×2）
- dry-runサポート
- エラー時の手動復旧手順提示

## 境界
- worktree作成・設定の変更は行わない
- operations.md / operations-release.mdへのスクリプト組み込みは行わない
- ドキュメント追記先は `prompts/package/guides/worktree-usage.md` のみ（スクリプト使用例の追加）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- git worktree機能

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 致命的エラーと非致命的エラーを区別し、可能な限り処理を継続

## 技術的考慮事項
- 正本は `prompts/package/bin/post-merge-cleanup.sh`（新規作成）
- 出力形式: `status:success|warning|error`, `branch:`, `main_repo_path:`, `message:`
- 致命的エラー（メインリポジトリ検出失敗、detach失敗）は即座に中断
- 非致命的エラー（ブランチ削除失敗）はwarning扱いで継続
- 参考スクリプト: setup-branch.sh, pr-ops.sh
- 関連Issue: #227

## 実装優先度
Medium

## 見積もり
中（内訳: スクリプト実装、異常系テスト、worktree-usage.mdへの使用例追記）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-02
- **完了日**: 2026-03-02
- **担当**: @ikeisuke
