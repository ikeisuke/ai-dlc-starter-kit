# 論理設計: PRマージ前レビューゲート強化

## 変更: operations-release.md

6.6.7と6.7の間に新ステップ 6.6.8 を追加。

### 6.6.8 PRマージ前レビュー【推奨】

3つのサブステップで構成:

#### サブステップ1: ローカルレビュー（/review）

- Claude Code環境の場合: `/review` コマンドを実行
- その他の環境（Codex CLI/Gemini CLI等）: スキップ
- 指摘があれば修正を実施

#### サブステップ2: Codexレビュー

- `command -v codex` で利用可能性を確認
- 利用可能: `codex review --base {DEFAULT_BRANCH}` を実行
  - `DEFAULT_BRANCH`: 6.6.7で検出した値。未検出時は `gh pr view --json baseRefName --jq '.baseRefName'`。それも失敗時は `main`
- 利用不可: スキップして次のサブステップへ

#### サブステップ3: Codex PRレビュー完了待機

- `gh:available` の場合のみ実行
- `gh pr view {PR番号} --json reviewDecision` で状態を確認
- APPROVED: 6.7へ進む
- CHANGES_REQUESTED: 修正→push→サブステップ2に戻る
- REVIEW_REQUIRED / レビュー未完了: ユーザーに待機を案内し、完了確認を求める
- gh利用不可: スキップして6.7へ進む
