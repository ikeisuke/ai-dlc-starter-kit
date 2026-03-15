# 実装記録: Unit 005 - PRマージ前レビューゲート強化

## 実装概要

Operations PhaseのPRマージ前に、ローカルレビューとCodexレビューの実行を必須化するゲート（ステップ6.6.8）をoperations-release.mdに追加した。

## 変更ファイル一覧

| ファイル | 変更種別 | 内容 |
|---------|---------|------|
| `prompts/package/prompts/operations-release.md` | 修正 | ステップ6.6.8追加、6.6.7の遷移先を6.6.8に更新 |

## 設計判断

- /reviewはClaude Code環境のみ実行（他環境ではスキップ）
- codex review --base {DEFAULT_BRANCH}は6.6.7で検出したDEFAULT_BRANCHを使用（フォールバック: gh pr view → main）
- Codex PRレビュー完了待機はサブステップ2実行時かつgh:available時のみ
- reviewDecisionの判定にnull/空文字列/REVIEW_REQUIREDの3パターンを明記
- ステップは【推奨】として設計（スキップ可能）
