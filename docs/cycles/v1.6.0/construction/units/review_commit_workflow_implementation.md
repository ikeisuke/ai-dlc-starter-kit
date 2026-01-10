# 実装記録: レビュー・コミットワークフロー改善

## 実装日時
2026-01-09

## 作成・変更ファイル

### プロンプトファイル（修正）
- `prompts/package/prompts/inception.md` - AIレビュー優先ルールの処理フロー更新
- `prompts/package/prompts/construction.md` - AIレビュー優先ルールの処理フロー更新
- `prompts/package/prompts/operations.md` - AIレビュー優先ルールの処理フロー更新

### 設計ドキュメント
- `docs/cycles/v1.6.0/design-artifacts/domain-models/review_commit_workflow_domain_model.md`
- `docs/cycles/v1.6.0/design-artifacts/logical-designs/review_commit_workflow_logical_design.md`

### 計画ファイル
- `docs/cycles/v1.6.0/plans/unit003_plan.md`

## ビルド結果
N/A（ドキュメント修正のため）

## テスト結果
N/A（ドキュメント修正のため）

- 整合性確認: 3つのプロンプトファイルで同一構成の処理フローを確認

## コードレビュー結果
- [x] AIレビュー実施済み（Codex MCP）
- [x] 指摘事項を反映

## 技術的な決定事項

1. **処理フローの6ステップ構成**:
   - mode確認 → MCP利用可否チェック → MCP利用可能時の選択 → AIレビューフロー → MCP利用不可時 → 人間レビューフロー

2. **コミット前の変更チェック追加**:
   - `git diff --quiet && git diff --cached --quiet || git add -A && git commit ...` で変更がない場合のエラーを回避

3. **スキップ履歴の記録形式定義**:
   - `required`モードでMCP利用不可時のスキップを履歴に記録する形式を標準化

4. **recommend モードでのユーザー選択明確化**:
   - MCP利用可能時に推奨メッセージを表示し、ユーザーがAIレビュー/人間レビューを選択できるように

## 課題・改善点
なし

## 状態
**完了**

## 備考
- 関連バックログ `feature-commit-around-review.md` を対応済みに移動
