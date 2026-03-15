# Unit 005 計画: PRマージ前レビューゲート強化

## 概要

Operations PhaseのPRマージ前に、ローカルレビューとCodexレビューの実行を必須化するゲートをoperations-release.mdに追加する。

## 変更対象ファイル

1. `prompts/package/prompts/operations-release.md` - 6.6.7と6.7の間に新ステップ「6.6.8 PRマージ前レビュー」を追加

## 実装計画

1. `operations-release.md` に新ステップ 6.6.8 を追加
   - サブステップ1: `/review` コマンド実行（Claude Code環境の場合のみ。他の環境ではスキップ）
   - サブステップ2: `codex review --base {DEFAULT_BRANCH}` 実行（codex CLI利用可能時のみ。`DEFAULT_BRANCH` は6.6.7で検出済みの値を使用）
   - サブステップ3: Codex PRレビュー完了待機（gh CLI利用可能時のみ）
2. 各サブステップで環境/CLI可用性を事前チェックし、未対応時はスキップ
3. CHANGES_REQUESTED時の修正→再レビューフローを定義

## 判定ロジック

1. `/review`: 実行主体がClaude Codeの場合のみ実行。Codex CLI/Gemini CLI等の環境ではスキップ
2. `command -v codex` で確認 → 利用可能なら `codex review --base {DEFAULT_BRANCH}` 必須。`DEFAULT_BRANCH` は6.6.7で検出した値を使用。6.6.7がスキップされた場合（fetch失敗等）のフォールバック: `gh pr view --json baseRefName --jq '.baseRefName'` でPRのベースブランチを取得。それも失敗時は `main` を使用
3. `gh:available`（ステップ2.5で確認済み）→ 利用可能なら Codex PRレビューゲート必須
4. 各CLI未インストール時 → 該当サブステップをスキップし次へ

## Codex PRレビュー完了待機の契約

- **完了条件**: `gh pr view {PR番号} --json reviewDecision` の `reviewDecision` が `APPROVED` または `CHANGES_REQUESTED`
- **待機方法**: ユーザーにCodex PRレビュー完了を待つよう案内し、完了確認を求める（自動ポーリングは行わない）
- **タイムアウト**: なし（ユーザー判断でスキップ可能）
- **APPROVED**: 6.7（PRマージ）へ進む
- **CHANGES_REQUESTED**: 修正を実施し、push後にサブステップ2から再実行

## CHANGES_REQUESTEDの状態遷移

- **判定ソース**: `gh pr view` の `reviewDecision` フィールド（GitHub PR全体の最新レビュー状態）
- **終了条件**: `reviewDecision` が `APPROVED` になること
- **フロー**: 修正 → コミット → push → codex review再実行（サブステップ2に戻る）→ Codex PRレビュー再確認

## 出力判断基準

- `/review`: AIが結果を読み取り、指摘の有無を判断（外部ツール出力のためステータス契約は不可）
- `codex review`: AIが結果テキストを解釈（同上）
- `gh pr view`: JSON出力の `reviewDecision` フィールドで機械的に判定

## 完了条件チェックリスト

- [ ] operations-release.md に 6.6.8 ステップ追加
- [ ] /review の環境依存分岐定義
- [ ] codex review --base {DEFAULT_BRANCH} の条件付き必須化
- [ ] Codex PRレビュー完了待機ゲートの契約定義
- [ ] CHANGES_REQUESTED時の状態遷移フロー定義
