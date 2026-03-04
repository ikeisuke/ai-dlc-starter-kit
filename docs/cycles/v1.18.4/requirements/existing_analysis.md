# 既存コード分析 - v1.18.4

## #267: セミオートモード Construction→Operations遷移時の不要停止

### 根本原因
Operations Phase開始時の「6. 全Unit完了確認」ステップ（operations.md L196-247）にセミオートゲート判定がない。

### 影響範囲
- **修正対象**: `prompts/package/prompts/operations.md`（「6. 全Unit完了確認」セクション）
- **問題フロー**:
  1. Construction Phase完了 → セミオート適用でコンテキストリセット提示スキップ ✓
  2. Operations Phase開始 → 「全Unit完了確認」で**ユーザー確認を強要** ✗
  3. ステップ0「変更確認」にはセミオート適用済み ✓（到達できない）

### 修正方針
- 全Unit完了確認にセミオートゲート判定を追加
- 全Unit完了済みの場合: auto_approved
- 未完了Unitがある場合: fallback(decision_required)

---

## #266: 実装中エラー発生時のバックログ自動記録

### 現状
- AIレビュー時のOUT_OF_SCOPE指摘: 自動バックログ記録 **実装済み**（review-flow.md L468-625）
- 気づき記録・workaround記録: フロー **定義済み**（construction.md L55-103）
- ビルド/テストエラー: 自動バックログ記録 **未実装**

### 既存メカニズム（活用可能）
- バックログモード確認: `check-backlog-mode.sh`
- ファイル作成/Issue作成: review-flow.md L5a のロジック
- 履歴記録: write-history.sh

### 修正方針
- Construction Phase ステップ6「統合とレビュー」内にエラー時自動バックログ記録フローを追加
- バックログ種別: `bugfix-`（ビルド/テストエラー）
- 既存のOUT_OF_SCOPE自動登録メカニズムを踏襲

---

## #269: セッションタイトル設定の代替手段

### 現在の実装
3フェーズすべてに`printf '\033]0;%s\007'`による実装が存在:
- `prompts/package/prompts/inception.md` L182
- `prompts/package/prompts/construction.md` L215
- `prompts/package/prompts/operations.md` L157

### 代替手段: Claude Code statusline機能
- Claude Code公式UI機能としてステータスバーに情報表示可能
- `~/.claude/settings.json` の `statusLine` フィールドで設定
- ターミナル互換性に依存しない
- シェルスクリプトを実行し、JSON形式のセッション情報を受け取って表示

### 修正方針
- `printf`による既存実装をstatusline機能に置換
- statusline設定用スクリプトを作成（プロジェクト名・フェーズ・サイクル情報を表示）
- フォールバック: statusline設定失敗時はエラーをスキップして続行

---

## #268: PRマージ前のレビューコメント確認（プロジェクト固有）

### 現在のフロー（Operations Phase ステップ6）
6.6 ドラフトPR Ready化 → 6.6.5 コミット漏れ確認 → 6.6.6 リモート同期確認 → **6.7 PRマージ**

### 欠落している確認
- PRに付属するレビューコメント（Codex自動レビュー等）の内容確認
- 指摘がある場合の対応フロー

### 修正方針
- **6.6.6と6.7の間**に新サブステップ「6.6.7 レビューコメント確認」を追加
- `gh api repos/{owner}/{repo}/pulls/{PR番号}/reviews` でレビューコメント取得
- 対応が必要な指摘がある場合: 修正 → push → @codex review → 再確認ループ
- 修正対象: `prompts/package/prompts/operations-release.md`（スターターキット共通）
  **ただし#268はプロジェクト固有機能** → `docs/cycles/rules.md` への追記が中心
