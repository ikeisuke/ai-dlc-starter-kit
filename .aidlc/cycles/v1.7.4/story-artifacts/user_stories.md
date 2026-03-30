# ユーザーストーリー

## Epic 1: バグ修正

### ストーリー 1: issue-only モードの正常動作 (#66)
**優先順位**: Must-have

As a AI-DLC開発者
I want to `backlog.mode = "issue-only"` 設定でGitHub CLI検証とサイクルラベル作成が正常動作する
So that issue-onlyモードでも安定した開発フローを維持できる

**受け入れ基準**:
- [ ] `prompts/package/prompts/setup.md` 内の `if [ "$BACKLOG_MODE" = "issue" ]` が `if [ "$BACKLOG_MODE" = "issue" ] || [ "$BACKLOG_MODE" = "issue-only" ]` に修正されている
- [ ] `prompts/package/prompts/inception.md` 内の同様の条件が修正されている
- [ ] `backlog.mode = "issue-only"` 設定で `gh label create "cycle:vX.X.X"` コマンドが実行される（または既存ラベルが検出される）

**技術的考慮事項**:
- 該当箇所: setup.md:170付近、inception.md:661付近
- 他にも `issue` のみをチェックしている箇所がないか全体検索が必要

---

### ストーリー 2: 未追跡ファイルのコミット対応 (#63)
**優先順位**: Must-have

As a AI-DLC開発者
I want to 未追跡ファイル（untracked files）のみ存在する場合でもコミットが正常に実行される
So that 新規ファイル作成時もワークフローが中断されない

**受け入れ基準**:
- [ ] プロンプト内のコミットコマンドが `git status --porcelain` で未追跡ファイルも検出するように修正されている
- [ ] 新規ファイルのみ作成した場合でもコミットが実行される
- [ ] 変更が一切ない場合（`git status --porcelain` が空）はコミットが実行されない

**技術的考慮事項**:
- 現状のコマンド: `git diff --quiet && git diff --cached --quiet || git add -A && git commit -m "message"`
- 修正案: `[ -n "$(git status --porcelain)" ] && git add -A && git commit -m "message"` または同等のロジック

---

## Epic 2: ドキュメント・ガイド改善

### ストーリー 3: 必要ツールのインストール案内 (#65)
**優先順位**: Should-have

As a 初めてAI-DLCを使う開発者
I want to 必要なツール（gh, dasel等）のインストール方法を案内される
So that セットアップでつまずかずに開発を開始できる

**受け入れ基準**:
- [ ] `prompts/package/prompts/setup-prompt.md` に必要ツール一覧セクションが追加されている
- [ ] gh（GitHub CLI）のインストールコマンドが記載されている（必須ツール）
- [ ] dasel（TOML読み込み用）のインストールコマンドが記載されている（オプションツール、AIが直接読み取り可能なため）
- [ ] 必須/オプションの区別が明記されている
- [ ] インストール確認方法（バージョン確認コマンド等）が記載されている

**技術的考慮事項**:
- brew、apt等の主要パッケージマネージャーを記載
- 必須: gh（PR作成、Issue作成に必要）
- オプション: dasel、jq、curl（AIが代替可能）

---

### ストーリー 4: バックログ追加時のサブエージェント活用ガイド (#64)
**優先順位**: Should-have

As a AI-DLC開発者
I want to バックログ追加処理をサブエージェントで実行する方法を知る
So that メインの作業フローを中断せずにバックログを記録できる

**受け入れ基準**:
- [ ] バックログ追加処理をサブエージェントで実行する推奨ガイドが追加されている
- [ ] 「気づき記録フロー」セクションにサブエージェント活用の記載がある
- [ ] Task Toolを使用したサブエージェント指示のテンプレート例が含まれている

**技術的考慮事項**:
- 追加先: `prompts/package/prompts/` 内の適切なファイル（construction.md等）

---

### ストーリー 5: Construction Phaseのサブエージェント委任ガイド (#62)
**優先順位**: Should-have

As a AI-DLC開発者
I want to Construction Phaseでサブエージェントに作業を委任する方法を知る
So that 複数のタスクを効率的に処理できる

**受け入れ基準**:
- [ ] `prompts/package/prompts/construction.md` またはガイドファイルにサブエージェント委任ルールが追加されている
- [ ] 委任可能な作業（ファイル編集、lint実行等）が明記されている
- [ ] メインで処理すべき作業（設計レビュー、承認待ち等）が明記されている
- [ ] 直列実行を推奨する旨が記載されている（並列実行は編集衝突リスクあり）

**技術的考慮事項**:
- 人間の承認が必要なステップはメインエージェントで処理
- MCPレビューもメインエージェントで処理

---

### ストーリー 6: KiroCLI対応 (#57)
**優先順位**: Should-have

As a KiroCLIを使用する開発者
I want to KiroCLIでAI-DLCを使用するための設定方法を知る
So that Claude Code以外のツールでもAI-DLCを活用できる

**受け入れ基準**:
- [ ] `prompts/package/prompts/AGENTS.md` にKiroCLI向けの案内が追加されている
- [ ] AGENTS.mdの `@` 参照記法がKiroCLIでは機能しない旨が説明されている
- [ ] Kiroエージェントに `resources` 設定を確認・追加してもらう手順が記載されている

**技術的考慮事項**:
- 参照: <https://kiro.dev/docs/cli/custom-agents/configuration-reference/#resources-field>
- 追加先: `prompts/package/prompts/AGENTS.md`
- 読み込むべきファイル: `docs/aidlc/prompts/AGENTS.md`

---

## Epic 3: プロンプト最適化

### ストーリー 7: 質問深掘りプロンプトの移動 (#58)
**優先順位**: Could-have

As a AI-DLC開発者
I want to 質問深掘りのプロンプトがAGENTS.mdに集約されている
So that AIエージェントが一貫した質問スタイルで対話できる

**受け入れ基準**:
- [ ] `prompts/package/prompts/AGENTS.md` に質問深掘りルールが追加されている
- [ ] 「具体的には？」「例えば？」で詳細を引き出すルールが含まれている
- [ ] 前提条件や制約を確認するルールが含まれている
- [ ] 元のファイルから重複を削除（または参照に変更）

**技術的考慮事項**:
- inception.md のステップ1に関連記述あり
- AGENTS.mdは全フェーズで参照されるため、共通ルールの集約先として適切

---

### ストーリー 8: ユーザーストーリーの受け入れ基準具体化 (#56)
**優先順位**: Could-have

As a AI-DLC開発者
I want to ユーザーストーリーの受け入れ基準を具体的に書くガイダンスがある
So that AIレビューで「曖昧」という指摘を受けにくくなる

**受け入れ基準**:
- [ ] `prompts/package/prompts/inception.md` のステップ3に受け入れ基準の書き方ガイダンスが追加されている
- [ ] 「主観的な表現を避ける」ルールが含まれている
- [ ] 「検証可能な条件を記載する」ルールが含まれている
- [ ] 具体例（良い例・悪い例）が含まれている

**技術的考慮事項**:
- 悪い例: 「改善されている」「適切」
- 良い例: 「ファイルXにセクションYが追加されている」「コマンドZが実行可能」
