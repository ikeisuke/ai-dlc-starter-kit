# ユーザーストーリー

## Epic: v2基盤クリーンアップ＆品質改善

### ストーリー 1: Lite版ルーティングの廃止 (#425)
**優先順位**: Must-have

As a AI-DLC利用者
I want to Lite版の廃止済みエントリがルーティングテーブルから削除されていること
So that 利用不可なコマンドが案内されず混乱しない

**受け入れ基準**:
- [ ] SKILL.mdの引数ルーティングテーブルから`lite inception`/`lite construction`/`lite operations`の3行が削除されている
- [ ] SKILL.mdのフェーズステップ読み込みセクションからLite条件分岐が削除されている
- [ ] CLAUDE.mdのフェーズ簡略指示テーブルからLite版の3行が削除されている
- [ ] AGENTS.mdのフェーズ簡略指示テーブルからLite版の3行が削除されている
- [ ] Liteプロンプトファイル（`steps/*/lite-*.md`パターン）が存在しない
- [ ] `/aidlc lite ...` の旧Lite指示を受けた場合、「Lite版は廃止されました。対応する通常コマンド（`/aidlc {フェーズ名}`）を使用してください。」と表示して処理を中断する

**技術的考慮事項**:
- prompts/package/ 配下の同期対象ファイルも同時に更新が必要（メタ開発）

---

### ストーリー 2: ローカルバックログの廃止 (#423)
**優先順位**: Must-have

As a AI-DLC利用者
I want to バックログ管理がGitHub Issue一本化されていること
So that バックログの管理先が分散せず運用が簡素化される

**受け入れ基準**:
- [ ] defaults.tomlの`backlog_mode`デフォルト値が`issue`に変更されている
- [ ] `backlog_mode`の有効値が`issue`/`issue-only`のみになっている
- [ ] 旧値`git`/`git-only`が設定されている場合、警告メッセージ「【警告】backlog_mode '{旧値}' は廃止されました。'issue' にフォールバックします。」を表示し`issue`として動作する
- [ ] `issue`/`issue-only`設定時は警告を出さずに正常動作する
- [ ] 通常運用ではローカルbacklogディレクトリ（`.aidlc/cycles/backlog/`）を参照・更新しない（移行処理では既存資産検出のための読み取りのみ許可）
- [ ] プロンプトファイル（steps/common/rules.md、steps/inception/02-preparation.md等）からローカルファイル操作のコードブロック・条件分岐が削除されている
- [ ] agents-rules.mdのバックログ管理テーブルから`git`/`git-only`行が削除されている
- [ ] check-backlog-mode.shが旧値に対してフォールバック＋警告を返す
- [ ] init-cycle-dir.shがバックログディレクトリ作成をスキップする（全モード共通）
- [ ] migrate-detect.shのバックログディレクトリ検出ロジックが更新されている

**技術的考慮事項**:
- 既存の`.aidlc/cycles/backlog/`ディレクトリは自動削除しない（データ安全性）

---

### ストーリー 3: Construction Phaseバックログチェック改善 (#424)
**優先順位**: Should-have

As a AI-DLC利用者
I want to Construction PhaseのバックログチェックがUnit関連Issueの詳細確認に限定されていること
So that 不要な全バックログ一覧表示がなくなり作業フローが効率化される

**前提条件**: ストーリー2（ローカルバックログ廃止）が完了していること

**受け入れ基準**:
- [ ] construction/01-setup.mdのステップ8が、Unit定義ファイルの「関連Issue」セクションからIssue番号を抽出する方式に変更されている
- [ ] 抽出したIssue番号に対して`gh issue view`で詳細を取得・表示する
- [ ] 関連Issueが0件の場合は「関連Issueなし」と表示してスキップする
- [ ] `gh_status`が`available`でない場合は「GitHub CLIが利用できないためスキップします」と表示する
- [ ] 関連IssueセクションのパースでIssue番号が取得できない場合は「関連Issueの解析に失敗しました。スキップします」と表示して続行する
- [ ] `gh issue view`が404/権限不足/ネットワークエラーの場合は「Issue #{番号} の取得に失敗しました」と警告を表示し、残りのIssueの処理を続行する

**技術的考慮事項**:
- ステップ8のプロンプト変更のみ（スクリプト変更なし）

---

### ストーリー 4: Kiro設定ドキュメント矛盾解消 (#426)
**優先順位**: Should-have

As a AI-DLC利用者
I want to Kiro設定に関するドキュメントが実装と一致していること
So that セットアップ時に矛盾した情報で混乱しない

**受け入れ基準**:
- [ ] examples/kiro/README.mdが「setup-ai-tools.shによりシンボリックリンクで自動管理される」と記載されている
- [ ] 「手動コピーが必要」の記述が削除または「setup-ai-tools.shで自動化済み」に修正されている
- [ ] 手動セットアップ手順は「setup-ai-tools.shが利用できない場合のフォールバック」として残す

**技術的考慮事項**:
- setup-ai-tools.shの実際の動作（シンボリックリンク作成、JSONマージ）がドキュメントの記述と一致すること

---

### ストーリー 5: v1→v2移行スクリプトE2Eテスト追加 (#427)
**優先順位**: Should-have

As a AI-DLC開発者
I want to v1→v2移行スクリプトのE2Eテストが存在すること
So that 移行スクリプトの変更時にリグレッションを検出できる

**受け入れ基準**:
- [ ] fixtureベースのE2Eテストが作成されている（v1ディレクトリ構造のfixture → migrate-detect.sh → migrate-apply-*.sh → migrate-verify.shの一連フロー）
- [ ] migrate-detect.shの8リソースタイプすべて（symlink_agents, symlink_kiro×2, file_kiro, backlog_dir, github_template, config_update, data_migration）がテストされている
- [ ] migrate-verify.shの3検証チェック（config_paths, v1_artifacts_removed, data_migrated）がテストされている
- [ ] CIジョブで対象テストスイートが自動実行され成功すること（既存のbats-coreテスト基盤を利用）

**技術的考慮事項**:
- bats-coreフレームワークを使用
- テスト用のv1構造fixtureディレクトリを`tests/fixtures/`に作成
- SHA256ハッシュ検証を含むファイル完全性テスト
