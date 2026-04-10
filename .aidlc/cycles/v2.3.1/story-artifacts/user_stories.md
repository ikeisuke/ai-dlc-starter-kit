# ユーザーストーリー

## Epic: Operations/Inception ワークフロー改善

### ストーリー 1: PRマージのユーザー判断化
**優先順位**: Must-have

As a AI-DLC利用者（semi_autoモード）
I want to PRマージの実行前に必ず確認を求められる
So that 意図しないマージを防止し、リリース直前の最終チェックを確実に行える

**受け入れ基準**:
- [ ] Operations Phase ステップ 7.13 で `automation_mode=semi_auto` 時もマージ実行前に `AskUserQuestion` でユーザー確認が表示される
- [ ] 確認メッセージにマージ方法（merge/squash/rebase）、CI状態、PR番号が含まれる
- [ ] 「マージする」「マージしない」「GitHub UIで手動マージ」の選択肢が提示される
- [ ] `automation_mode=manual` 時の既存動作が退行しない
- [ ] PR番号未取得時はマージ確認を出さずエラー案内する（既存の `pr-ops.sh` エラーハンドリングを維持）
- [ ] 「GitHub UIで手動マージ」選択時は以降の自動マージ処理を実行しない

**技術的考慮事項**:
- `steps/operations/02-deploy.md` または `operations-release.md` のステップ 7.13 を変更
- `operations/index.md` の分岐ロジックセクション更新
- `AskUserQuestion使用ルール` の「ユーザー選択」分類に準拠

### ストーリー 2: コンパクション復帰時の不変ルール違反防止
**優先順位**: Must-have

As a AI-DLC利用者（長時間セッション）
I want to コンパクション復帰時にステップファイル再読み込みのガイダンスが確実に表示される
So that 不完全な手順で作業が進行するリスクを最小化できる

**受け入れ基準**:
- [ ] `compaction.md` の復帰フローに「通常フロー継続を案内せず、`/aidlc <phase>` の再実行を案内する」指示が記載される
- [ ] 復帰テンプレートに「ステップファイル再読み込みのため `/aidlc <phase>` を再実行してください。サマリーの記憶のみで手順を継続しないでください」の禁止文言が含まれる
- [ ] `session-continuity.md` のコンパクション復帰判定セクションで `compaction.md` 読み込みが明示的にトリガーされる

**技術的考慮事項**:
- `steps/common/compaction.md` のコンパクション復帰フロー変更
- `steps/common/session-continuity.md` の復帰フロー説明更新
- LLM の振る舞いを技術的に完全制御することはできないため、プロンプトレベルでの強制力を最大化する（検証は復帰テンプレート文言の存在確認で行う）

### ストーリー 3: ドラフトPR作成設定の固定化
**優先順位**: Should-have

As a AI-DLC利用者
I want to ドラフトPR作成の方針を設定ファイルで固定化できる
So that 毎サイクルの繰り返し確認を省略できる

**受け入れ基準**:
- [ ] `config/defaults.toml` に `rules.git.draft_pr` キーが追加される（デフォルト: `ask`）
- [ ] `draft_pr=always` 時: `gh_status=available` なら自動でドラフトPR作成、available 以外ならスキップ
- [ ] `draft_pr=never` 時: 常にスキップ
- [ ] `draft_pr=ask` 時: 従来どおりユーザー確認
- [ ] 未設定時はデフォルト値 `ask` で動作する（後方互換）
- [ ] `automation_mode` より `draft_pr` 設定が優先される（例: `automation_mode=manual` かつ `draft_pr=always` でもドラフトPR作成確認は省略される）
- [ ] `draft_pr` に不正値（`always/never/ask` 以外）が設定された場合、警告を表示して `ask` にフォールバックする

**技術的考慮事項**:
- `config/defaults.toml` に新キー追加
- `steps/inception/05-completion.md` のステップ5に設定分岐実装
- `read-config.sh` での値取得・バリデーション
- #551 を #557 に統合してクローズ
