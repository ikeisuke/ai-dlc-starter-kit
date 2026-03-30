# ドメインモデル: PRマージ前レビューゲート強化

## エンティティ

- **ローカルレビュー**: Claude Codeの /review コマンドによるPR差分レビュー
- **Codexレビュー**: codex review --base {DEFAULT_BRANCH} によるコードレビュー
- **PRレビュー状態**: GitHub PRの reviewDecision フィールド（APPROVED / CHANGES_REQUESTED / REVIEW_REQUIRED）
- **レビューゲート**: PRマージ前に必要なレビューの完了を確認するチェックポイント

## 振る舞い

- ステップ 6.6.8 として 6.6.7（mainブランチとの差分チェック）の後に挿入
- 3つのサブステップが順次実行され、各サブステップは環境/CLI可用性で条件分岐
- CHANGES_REQUESTED時は修正→再レビューのループ
