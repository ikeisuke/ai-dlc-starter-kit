# ユーザーストーリー

## Epic: ワークフロー改善・バグ修正パッチ

### ストーリー 1: semi_autoモードのゲート自動承認修正
**優先順位**: Must-have

As a AI-DLC利用者（semi_autoモード使用時）
I want to フォールバック条件に該当しないゲート承認が自動で通過すること
So that 不要な確認ダイアログで作業が中断されなくなる

**受け入れ基準**:
- [ ] semi_autoモードでフォールバック条件非該当のゲート承認ポイントにおいて、AskUserQuestionが呼ばれず自動承認される
- [ ] manualモードでは全ゲートで従来どおりAskUserQuestionによるユーザー確認が行われる
- [ ] semi_autoモードでも「ユーザー選択」（PRマージ等）はAskUserQuestion必須のまま変更されない
- [ ] semi_autoモードでも「情報収集」はAskUserQuestion必須のまま変更されない
- [ ] 各ステップファイルのゲート承認ポイントに「セミオートゲート判定」への明示的参照がある

**技術的考慮事項**:
LLMのプロンプト解釈に依存するため、ステップファイル内の記述の明確化が主な修正方法。コード変更ではなくプロンプト改善。

---

### ストーリー 2: 対話UIの「設定に保存」機能
**優先順位**: Should-have

As a AI-DLC利用者
I want to 対話中の設定選択を設定ファイルに永続保存できること
So that 同じ選択を毎回繰り返す必要がなくなる

**受け入れ基準**:
- [ ] `rules.git.merge_method`（ask設定時）の選択で「設定に保存」選択肢が表示される
- [ ] `rules.git.branch_mode`（ask設定時）の選択で「設定に保存」選択肢が表示される
- [ ] `rules.git.draft_pr`（ask設定時）の選択で「設定に保存」選択肢が表示される
- [ ] 保存先として `config.toml`（プロジェクト共有）と `config.local.toml`（個人設定）を選択できる
- [ ] デフォルト保存先が `config.local.toml` である
- [ ] `config.local.toml` 未存在時に新規作成される
- [ ] 対象セクション未存在時に安全に追加される
- [ ] 既存のコメント・他キーが維持される
- [ ] 保存後、次回実行時に `read-config.sh` が保存済みの値を正しく返す
- [ ] 既存の設定読込優先順位（local > project > user > defaults）が不変である

**技術的考慮事項**:
`write-config.sh` の新規作成が必要。TOML書き込みはフォーマットを壊さない安全な実装が必要。

---

### ストーリー 3: PR Closes記載時の部分対応Issue自動判別
**優先順位**: Should-have

As a AI-DLC利用者
I want to 部分対応のIssueがPR ClosesではなくRelatesとして記載されること
So that 部分対応IssueがPRマージ時に誤ってCloseされなくなる

**受け入れ基準**:
- [ ] Unit定義ファイルの「関連Issue」セクションで `#NNN（部分対応）` 記法が使用できる
- [ ] `#NNN` のみの記載は「完全対応」としてClosesに含まれる（既存互換）
- [ ] `#NNN（部分対応）` の記載は「部分対応」としてRelatesに含まれる
- [ ] `get-related-issues` の出力がCloses/Relatesを区別する形式になっている
- [ ] PR Closes記載確認ステップで自動検証が行われ、部分対応Issueが警告表示される
- [ ] 注記のない既存Unit/Issueの動作が変更されない（後方互換）

**技術的考慮事項**:
`pr-ops.sh` の `get-related-issues` コマンドの出力形式変更。呼び出し側（operations-release.md等）の対応が必要。
