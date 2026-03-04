# ユーザーストーリー - v1.18.4

## Epic: AI-DLCフロー品質改善

### ストーリー 1: セミオートモードでのPhase遷移改善（#267）
**優先順位**: Must-have

As a AI-DLC利用開発者
I want to セミオートモード時にConstruction→Operations遷移が自動で行われること
So that 不要な手動介入なく開発フローを連続実行できる

**受け入れ基準**:
- [ ] `automation_mode=semi_auto` かつ全Unit完了済みの場合、Operations Phase開始時の「全Unit完了確認」がユーザー確認なしで自動通過する
- [ ] `automation_mode=semi_auto` かつ未完了Unitがある場合、fallback(decision_required)としてユーザーに選択を求める
- [ ] `automation_mode=manual` の場合、従来通りユーザー確認が表示される
- [ ] 自動通過時に履歴に「セミオート自動承認」が記録される
- [ ] Unit完了状態の判定が不能な場合（履歴欠損・状態不整合等）、fallback(decision_required)にフォールバックし、判定不能の理由を表示する

**技術的考慮事項**:
- 修正対象: `prompts/package/prompts/operations.md`「6. 全Unit完了確認」セクション
- セミオートゲート仕様（common/rules.md）に準拠

---

### ストーリー 2: エラー時バックログ記録支援（#266）
**優先順位**: Must-have

As a AI-DLC利用開発者
I want to Construction Phase中のビルド/テストエラー発生時にバックログ登録を提案されること
So that エラー情報の追跡漏れを防ぎ、改善項目を確実に管理できる

**受け入れ基準**:
- [ ] ビルド/テストエラー発生時、ユーザーにバックログ登録の要否を確認する
- [ ] ユーザーが「登録する」を選択した場合、バックログモードに応じて記録される（issue/issue-only: Issue作成、git/git-only: ファイル作成）
- [ ] ユーザーが「登録しない」を選択した場合、バックログ登録をスキップしてエラー対応に進む
- [ ] `issue` モードでIssue作成失敗時、`git` 方式にフォールバックする
- [ ] `issue-only` モードでIssue作成失敗時、警告を表示し手動対応を依頼する
- [ ] バックログ種別は `bugfix-` が使用される
- [ ] 登録した場合、履歴に「バックログ登録」が記録される
- [ ] 登録しない場合、履歴に「バックログ登録スキップ」が記録される

**技術的考慮事項**:
- 修正対象: `prompts/package/prompts/construction.md` ステップ6「統合とレビュー」
- 既存のOUT_OF_SCOPE自動登録メカニズム（review-flow.md）を踏襲
- バックログモード確認: `check-backlog-mode.sh` を使用

---

### ストーリー 3: セッションタイトル代替手段（#269）
**優先順位**: Should-have

As a AI-DLC利用開発者
I want to Claude Code環境で複数セッションを判別できること
So that 複数サイクルを並行作業する際に混乱を防げる

**受け入れ基準**:
- [ ] セッション情報（プロジェクト名 `project`、フェーズ `phase`、サイクルバージョン `cycle`）が常時表示される
- [ ] 2セッション同時起動時に `cycle` 値が異なることで各セッションを判別できる
- [ ] 設定失敗時にフロー全体がブロックされない（エラーをスキップして続行）
- [ ] 3フェーズすべて（Inception/Construction/Operations）で適用される

**技術的考慮事項**:
- 実装手段の候補: Claude Code statusline機能、環境変数設定、出力メッセージ等
- 修正対象: 3フェーズのプロンプト（`prompts/package/prompts/inception.md`, `construction.md`, `operations.md`）のステップ1.5/2.6
- statusline設定用スクリプトの作成が必要な場合あり

---

## Epic: プロジェクト固有運用強化

### ストーリー 4: PRマージ前レビューコメント確認（#268）
**優先順位**: Should-have

As a AI-DLCスターターキット開発者
I want to PRマージ前にレビューコメント（Codex自動レビュー等）を確認するステップがあること
So that レビュー指摘を見落とさずにマージできる

**受け入れ基準**:
- [ ] Operations Phaseのステップ6.6.6と6.7の間に「レビューコメント確認」ステップが追加されている
- [ ] `gh api` でPRレビューコメントを取得し、内容を表示する
- [ ] 未対応の指摘がある場合、ユーザーに警告を表示し対応を促す
- [ ] 対応不要と判断した場合、そのまま6.7（PRマージ）へ進める
- [ ] 指摘対応後、修正push → @codex review → 再確認のループが可能
- [ ] `gh api` 呼び出し失敗時（認証切れ・レート制限・ネットワーク障害等）、エラー理由を表示し、マージ可否をユーザーに明示的に選択させる

**技術的考慮事項**:
- プロジェクト固有機能のため `docs/cycles/rules.md` への追記が中心
- `gh api repos/{owner}/{repo}/pulls/{PR番号}/reviews` を使用
- Codex再レビュールール（rules.md）との整合性を保つ
