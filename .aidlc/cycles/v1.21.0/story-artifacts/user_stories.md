# ユーザーストーリー

## Epic 1: スキルのマーケットプレイス対応（#292）

### ストーリー 1: マーケットプレイスからのスキルインストール
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to マーケットプレイス方式でAI-DLCスキルをインストールしたい
So that 必要なスキルだけを選択的に導入でき、プロジェクトをスリムに保てる

**受け入れ基準**:
- [ ] `marketplace.json` にAI-DLCスキルのカタログが定義されている（カタログIDはスキルスラッグと一致）
- [ ] `/plugin marketplace add` でAI-DLCスキルリポジトリを登録できる
- [ ] `/plugin install <スキル名>` で個別スキルをインストールできる
- [ ] インストールされたスキルが `.claude/skills/` に配置され、呼び出し可能である
- [ ] 存在しないスキル名を指定した場合、エラーメッセージが表示されインストールされない
- [ ] 既にインストール済みのスキルを再インストールした場合、上書き更新される

**技術的考慮事項**:
- `claude-skills` リポジトリの `.claude-plugin/marketplace.json` パターンを参考にする
- 埋め込み方式との共存はストーリー2で検証する

---

### ストーリー 2: 埋め込み方式との共存
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to 従来の埋め込み方式でセットアップしたプロジェクトがそのまま動作してほしい
So that 既存プロジェクトを壊さずにマーケットプレイス方式を段階的に導入できる

**受け入れ基準**:
- [ ] `prompts/package/skills/` からの同期パイプライン（sync-package.sh → setup-ai-tools.sh）が引き続き動作する
- [ ] マーケットプレイス未使用のプロジェクトで、`/aidlc-setup` を実行するとスキル同期とシンボリックリンク作成が完了する
- [ ] 同期後、`.claude/skills/` 配下のシンボリックリンクが `../../docs/aidlc/skills/<name>` を指している
- [ ] reviewing-*, session-title, squash-unit スキルが呼び出し可能である
- [ ] シンボリックリンク先ディレクトリが存在しない場合、エラーメッセージが表示されセットアップが中断しない（スキップして続行）

**技術的考慮事項**:
- setup-ai-tools.sh のシンボリックリンク作成ロジックは変更不要（新スキル名のディレクトリに対してリンクを作成するため自動対応）
- aidlc-setup.sh のパス解決ロジック（resolve_script_dir）はリネーム後のディレクトリ名でテストする

---

### ストーリー 3: upgrading-aidlc → aidlc-setup リネーム
**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to セットアップとアップグレードが統合された `aidlc-setup` スキルを使いたい
So that スキル名が直感的で、初回セットアップと更新の区別を意識せずに使える

**受け入れ基準**:
- [ ] `prompts/package/skills/upgrading-aidlc/` が `prompts/package/skills/aidlc-setup/` にリネームされている
- [ ] スクリプト内部（upgrade-aidlc.sh → aidlc-setup.sh）もリネームされている
- [ ] CLAUDE.md, AGENTS.md, ai-tools.md, operations.md のスキル参照が `aidlc-setup` に更新されている
- [ ] `.claude/skills/aidlc-setup` シンボリックリンクが作成され、旧名 `.claude/skills/upgrading-aidlc` が削除されている
- [ ] 旧名 `upgrading-aidlc` のディレクトリ・シンボリックリンクが `prompts/package/skills/`, `docs/aidlc/skills/`, `.claude/skills/` から完全に削除されている
- [ ] リネーム後にコードベース内に旧名 `upgrading-aidlc` への参照が残っていないことが `grep -r` で確認できる

**技術的考慮事項**:
- aidlc-setup.sh 内の `resolve_script_dir()` がシンボリックリンクを追跡するため、リネーム後のパスでの動作確認が必要
- 旧名は本リリースで完全削除（v1.19.0で非推奨化済みのため互換期間不要）

---

### ストーリー 4: スキル名前空間の分離
**優先順位**: Should-have

As a AI-DLCスターターキット利用者
I want to AI-DLC固有スキルと汎用ツールスキルが名前空間で区別されてほしい
So that スキルの出所と用途が明確になり、管理しやすくなる

**受け入れ基準**:
- [ ] AI-DLC固有スキルに `aidlc:` プレフィックスが定義されている（例: `aidlc:setup`, `aidlc:reviewing-code`）
- [ ] 汎用ツールスキルに `tools:` プレフィックスが定義されている（例: `tools:session-title`）
- [ ] 既存のプレフィックスなし名前でも引き続き呼び出し可能である（後方互換）
- [ ] 名前衝突時の解決規則が定義されている（完全一致を優先し、衝突時はエラーメッセージで候補を提示）
- [ ] ai-tools.md のスキルカタログに名前空間マッピング（カタログID、表示名、呼び出し名）が反映されている
- [ ] カタログ上の表示名（`aidlc:setup`）から実行名（`aidlc-setup`）への対応が明確に定義されている
- [ ] `/skill aidlc-setup` でスキルが実行される（ディレクトリ名ベースの呼び出し）

**技術的考慮事項**:
- 名前空間はスキルの論理的な分類。ディレクトリ構造は変更せず、ai-tools.md と marketplace.json のカタログで管理する
- Claude Codeの `/skill` 呼び出しではディレクトリ名がそのまま使用されるため、プレフィックスはカタログ上の表示名であり、実行時の呼び出し名はディレクトリ名（例: `aidlc-setup`）となる

---

## Epic 2: jjサポートの外部化（#276）

### ストーリー 5: jj関連コードの削除
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to jj関連コードをスターターキット本体から削除したい
So that コードベースがスリムになり、非推奨機能のメンテナンスコストがなくなる

**受け入れ基準**:
- [ ] `prompts/package/skills/versioning-with-jj/` ディレクトリが削除されている
- [ ] `aidlc-git-info.sh` から `.jj` 検出と `jj log`/`jj diff` 分岐が削除されている
- [ ] `aidlc-cycle-info.sh` から jj検出と `jj log -r @` 分岐が削除されている
- [ ] `squash-unit.sh` から `--vcs jj` オプション、`find_base_commit_jj()`, `squash_jj()` が削除されている
- [ ] `aidlc-env-check.sh` から `jj` コマンドチェックが削除されている
- [ ] `docs/aidlc.toml` の `[rules.jj]` セクションが削除されている
- [ ] `common/rules.md`, `common/commit-flow.md` のjj関連記述が削除されている
- [ ] `inception.md`, `construction.md`, `operations.md` のjj参照が削除されている
- [ ] `.claude/skills/versioning-with-jj` および `.kiro/skills/versioning-with-jj` シンボリックリンクが削除されている
- [ ] jj環境を使用していた利用者向けの移行案内が表示される仕組みがある（`aidlc-setup` 実行時に旧jj設定を検出した場合、skillsリポジトリからのインストールを案内）
- [ ] 削除後にコードベース内にjj関連コード（`.jj`検出、`jj log`、`jj diff`、`jj describe`等）が残っていないことが確認できる

**技術的考慮事項**:
- 削除対象ファイルは `prompts/package/` 側を編集（メタ開発ルール）
- 移行案内は `aidlc-setup.sh` のマイグレーション処理に組み込む

---

### ストーリー 6: jjスキルのskillsリポジトリへの移動
**優先順位**: Should-have

As a jjを使用するAI-DLC利用者
I want to jjサポートをskillsリポジトリからオプトインでインストールしたい
So that jjを使い続けつつ、スターターキット本体のアップデートに影響されない

**受け入れ基準**:
- [ ] 本リポジトリにjjスキルの移行元ファイル一式（SKILL.md、jj-support.md）が `docs/cycles/v1.21.0/` に退避・記録されている
- [ ] 移行手順ドキュメント（`docs/aidlc/guides/jj-migration.md`）が作成されている
  - skillsリポジトリへのインストール手順（マーケットプレイス方式）
  - 手動インストール手順（マーケットプレイス未使用の場合）
- [ ] skillsリポジトリへの追加は別リポジトリ作業として Issue を作成済みである

**技術的考慮事項**:
- 本サイクルのスコープは本リポジトリ側の作業（削除、移行ドキュメント作成、Issue作成）に限定
- skillsリポジトリへのPR作成・マージは別作業として切り出す

---

## Epic 3: マルチプラットフォーム対応調査（#281）

### ストーリー 7: マルチプラットフォーム対応状況の調査・文書化
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to AIエージェント別の対応状況を体系的に把握したい
So that 今後の対応優先順位を判断でき、ロードマップを策定できる

**受け入れ基準**:
- [ ] 対応状況マトリクス（AIエージェント × 機能）が作成されている
  - 対象エージェント: Claude Code, KiroCLI, Codex CLI, Gemini CLI, Cursor, Cline, Windsurf
  - 対象機能: 設定ファイル, スキル連携, コミット属性, レビュー, サブエージェント, Plan Mode
  - 各セルは「対応済み / 部分対応 / 未対応」で記載
- [ ] ギャップ分析として、各「未対応」「部分対応」項目に対して具体的な不足内容が記載されている
- [ ] 共有プロンプト内のClaude Code固有表現（Writeツール, Readツール, AskUserQuestion, TodoWrite等）の使用箇所一覧が作成されている
- [ ] 次期サイクルへの優先対応提案が、優先度（高/中/低）と理由付きで記載されている
- [ ] 成果物は `docs/cycles/v1.21.0/requirements/multi-platform-analysis.md` に作成される

**完了条件**: 1ドキュメントに以下4セクションがすべて含まれていること: (1) 対応状況マトリクス、(2) ギャップ分析、(3) Claude Code固有表現の使用箇所一覧、(4) 次期サイクルへの優先対応提案。レビュー承認で完了とする。

**技術的考慮事項**:
- 既存の `docs/aidlc/guides/ai-agent-allowlist.md` およびステップ2の既存分析結果を基に調査
- `docs/cycles/v1.18.0/requirements/amazon-aidlc-report.md` の調査結果も参照
