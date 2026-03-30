# ユーザーストーリー

## Epic: 開発者体験（DX）向上

### ストーリー 1: エクスプレスモードのインスタント起動
**優先順位**: Must-have
**関連Issue**: #364

As a AI-DLCを使う開発者
I want to 「start express」と指示するだけでエクスプレスモードを起動したい
So that aidlc.toml の事前設定変更なしに小規模修正を素早く開始できる

**受け入れ基準**:
- [ ] 「start express」実行時、aidlc.toml の `rules.depth_level.level` の値に関わらず、セッション内で `depth_level=minimal` として扱われる
- [ ] aidlc.toml の設定値自体は変更されない（セッション内限定のオーバーライド）
- [ ] Inception Phase のステップ4b でUnit数が1の場合、エクスプレスモードが有効化されConstruction Phaseに自動遷移する
- [ ] Unit数が2以上になった場合、フォールバックメッセージが表示され通常のminimalフローに切り替わる
- [ ] Unit数が0の場合、フォールバックメッセージが表示され通常のminimalフローに切り替わる
- [ ] コマンド判定ルール: 入力をtrim後「start express」と完全一致（大文字小文字無視）のみ有効。部分一致（「start express now」等）は無効とし、通常のInception Phaseとして開始する（エラーメッセージなし）
- [ ] Inception Phase 以外で「start express」完全一致が入力された場合、「start express は新規サイクル開始時のみ使用できます。Inception Phase を開始してください」とエラーメッセージが表示される

**初期化シーケンス**: コマンド判定（start express検出）→ モード決定（depth_level=minimalオーバーライド）→ プリフライトチェック → 通常Inceptionフロー → ステップ4bでエクスプレスモード判定

**技術的考慮事項**:
- inception.md の初期化ステップで「start express」からの起動を検出し、コンテキスト変数 `depth_level` を `minimal` にオーバーライドする仕組みが必要
- 既存のエクスプレスモード仕様（rules.md）は変更せず、トリガー方法の追加のみ
- AGENTS.md / CLAUDE.md のフェーズ簡略指示テーブルへの追加は実装タスクとして扱う

---

### ストーリー 2: フェーズ開始時プリフライトチェック（ツール・認証）
**優先順位**: Must-have
**関連Issue**: #320

As a AI-DLCを使う開発者
I want to 各フェーズ開始時に必須ツールの存在と認証状態が自動チェックされるようにしたい
So that セッション途中での環境起因の中断を防止できる

**受け入れ基準**:
- [ ] 各フェーズ（Inception/Construction/Operations）開始時にプリフライトチェックが自動実行される
- [ ] チェック対象: 必須ツール存在（gh, git）
- [ ] チェック対象: レビューツール存在確認（`rules.reviewing.tools` 設定で指定されたツールの `which` 確認）
- [ ] チェック対象: ghの認証状態（`gh auth status` の成功/失敗で判定。失敗時は「ghが未認証です。`gh auth login` を実行してください」と表示）
- [ ] チェック対象: aidlc.toml 必須キー存在チェック（`[project].name` が設定されていること）
- [ ] チェック失敗時、エラー内容と具体的な対処コマンドがユーザーに提示される（例: 「ghが未認証です。`gh auth login` を実行してください」）
- [ ] プリフライト失敗時はフェーズ開始を中断し、次ステップへ進まない。AIがユーザーに「対処後、再チェックしますか？」と確認し、「はい」の場合に同一チェックを再実行する。ユーザーが「中止」を選択した場合はフェーズ開始を中止する
- [ ] プリフライトチェックは `common/preflight.md` として共通化されている
- [ ] プリフライトチェックはストーリー1のエクスプレスモード判定の後に実行される（初期化シーケンス: コマンド判定→モード決定→プリフライト→フェーズフロー）

**技術的考慮事項**:
- `env-info.sh` の既存ツール可用性チェック機能を基盤として再利用
- 各フェーズプロンプトの初期化ステップに `common/preflight.md` への参照を追加

---

### ストーリー 3: フェーズ開始時設定値一括提示
**優先順位**: Must-have
**関連Issue**: #350

As a AI-DLCを使う開発者
I want to 各フェーズ開始時に主要設定値が一覧で表示されるようにしたい
So that 設定値の読み飛ばしによるワークフロー不整合を防げる

**受け入れ基準**:
- [ ] `read-config.sh --keys` で以下の設定値が一括取得・提示される: `rules.depth_level.level`, `rules.automation.mode`, `rules.reviewing.mode`, `rules.reviewing.tools`, `rules.squash.enabled`, `rules.linting.markdown_lint`, `rules.unit_branch.enabled`
- [ ] 設定値の提示はプリフライトチェック（ストーリー2）の一部として `common/preflight.md` 内で実行される。ただし、単体でも `read-config.sh --keys` コマンドにより同等の出力を得ることで検証可能
- [ ] 取得失敗した設定キーはスキップされ、警告が表示される（バッチモードの既存動作）

**技術的考慮事項**:
- `read-config.sh --keys` のバッチモードが既に実装済み
- プリフライトチェックの最終ステップとして設定値を表示

---

### ストーリー 4: Codex PRレビュー絵文字リアクション検出
**優先順位**: Should-have
**関連Issue**: #336

As a AI-DLCを使う開発者
I want to Codex PRレビューの完了状態を絵文字リアクションで自動判定したい
So that PRマージ前ゲートの自動化精度が向上し、レビュー状態の確認が容易になる

**受け入れ基準**:
- [ ] `@codex review` コメントを本文検索で特定し、そのコメントへのリアクションを `gh api` で取得できる
- [ ] リアクション判定ルール: Codexボットアカウント（`login` が `openai-codex` または `codex-bot` に該当）からのリアクションのみを有効とする。それ以外のユーザーからのリアクションは無視する
- [ ] 判定優先順位: 👀（レビュー中）が1件以上あればレビュー中と判定。👀がなく👍が1件以上あればレビュー完了と判定
- [ ] リアクションがない場合、既存のコメントベース判定にフォールバックする
- [ ] PRマージ前ゲート（rules.md 6.6.7相当）にリアクションチェックが統合されている
- [ ] API取得失敗時は既存のコメントベース判定にフォールバックし、「リアクション取得に失敗しました。コメントベースの判定を使用します」と表示する

**技術的考慮事項**:
- GitHub REST API: `gh api repos/{owner}/{repo}/issues/comments/{comment_id}/reactions` でリアクション取得
- `@codex review` コメントの特定: PRコメント一覧から本文に `@codex review` を含むコメントを最新順で検索
- 既存のPRマージ前ゲートロジック（rules.md）に追加統合

---

### ストーリー 5: .kiro/skills → .agents/skills 移行
**優先順位**: Should-have
**関連Issue**: #347

As a AI-DLCを使う開発者
I want to スキルディレクトリが .kiro/skills から .agents/skills に移行されていてほしい
So that セットアップ手順が統一され、AI環境間でのスキル参照の一貫性が向上する

**受け入れ基準**:
- [ ] `setup-ai-tools.sh` が `.agents/skills` にシンボリックリンクを作成する（`.kiro/skills` の代わり）
- [ ] `setup-ai-tools.sh` が `.agents/agents/` にエージェント定義シンボリックリンクを作成する（`.kiro/agents/` の代わり）
- [ ] `setup-prompt.md` 内の `.kiro/skills` 参照がすべて `.agents/skills` に更新されている
- [ ] リポジトリ内の `.kiro/skills` 参照が許可リスト（`docs/cycles/v1.*/`, `CHANGELOG.md` の過去エントリ）以外に0件である。検証コマンド: `rg ".kiro/skills" --glob "!docs/cycles/v1.*/" --glob "!CHANGELOG.md"`
- [ ] リポジトリ内の `.kiro/agents` 参照が許可リスト（`docs/cycles/v1.*/`, `CHANGELOG.md` の過去エントリ）以外に0件である。検証コマンド: `rg ".kiro/agents" --glob "!docs/cycles/v1.*/" --glob "!CHANGELOG.md"`
- [ ] 既存の `.agents/skills` ディレクトリが存在する場合、setup-ai-tools.sh はバックアップを作成してから上書きする（`.agents/skills.bak.YYYYMMDD`）
- [ ] 既存の `.agents/agents` ディレクトリが存在する場合も同様にバックアップを作成する（`.agents/agents.bak.YYYYMMDD`）
- [ ] 破壊的変更としてCHANGELOGに明記されている
- [ ] アップグレード手順が記載されている（旧 `.kiro/skills`, `.kiro/agents` ディレクトリの手動削除案内）
- [ ] `.kiro/agents/aidlc-poc.json`（直接ファイル）は `.agents/agents/` にコピーする

**技術的考慮事項**:
- `setup-ai-tools.sh` の `setup_kiro_skills()` 関数を `setup_agent_skills()` にリネームし、ターゲットディレクトリを `.agents/skills` に変更
- `.kiro/agents/` → `.agents/agents/` への移行も同時に実施
- 自己修復機能（壊れたシンボリックリンク検出・修復）はそのまま引き継ぐ
