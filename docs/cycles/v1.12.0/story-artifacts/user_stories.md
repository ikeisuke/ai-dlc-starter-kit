# ユーザーストーリー

## Epic 1: 設定階層化（#30, #27）

### ストーリー 1.1: プロジェクト個人設定
**優先順位**: Must-have
**関連Issue**: #30
**依存関係**: なし

As an AI-DLC利用者
I want to aidlc.toml.localで個人設定を管理したい
So that チーム共有設定と個人の好みを分離でき、コンフリクトを防げる

**受け入れ基準**:
- [ ] docs/aidlc.toml.localファイルが読み込まれること
- [ ] 同一キーが存在する場合、.localの値が優先されること
- [ ] 配列型の値は.localで完全に置換されること
- [ ] ネストしたセクションは再帰的にマージされること
- [ ] .localファイルが存在しない場合でもエラーにならないこと
- [ ] .gitignoreに`docs/aidlc.toml.local`が追加されること

**技術的考慮事項**:
- プロンプト内で設定読み込み時に.localファイルを確認するロジックを追加

---

### ストーリー 1.2: ユーザー共通設定
**優先順位**: Must-have
**関連Issue**: #27
**依存関係**: ストーリー1.1（マージロジックを共有）

As a 複数プロジェクトでAI-DLCを使う開発者
I want to ~/.aidlc/config.tomlで共通設定を管理したい
So that プロジェクトごとに同じ設定を繰り返す手間が省ける

**受け入れ基準**:
- [ ] ~/.aidlc/config.tomlファイルが読み込まれること
- [ ] 読み込み優先順位: ホーム設定(最低) < プロジェクト設定 < .local設定(最高)
- [ ] 3階層のマージが1.1と同じルール（キー単位優先、配列置換、ネスト再帰マージ）で動作すること
- [ ] ホームディレクトリに設定ファイルがなくてもエラーにならないこと
- [ ] セットアップ時に「~/.aidlc/config.tomlを作成しますか？」と案内されること

**技術的考慮事項**:
- 環境変数HOMEを使用してホームディレクトリを特定
- 初回セットアップ時にテンプレート作成のオプションを提供

---

## Epic 2: フェーズ統合（#99）

### ストーリー 2.1: Setup/Inception統合（通常版）
**優先順位**: Must-have
**関連Issue**: #99
**依存関係**: なし

As an AI-DLC利用者
I want to Setup/Inceptionを1回のプロンプト読み込みで完了したい
So that 新規サイクル開始が高速化される

**受け入れ基準**:
- [ ] 統合版プロンプト（setup-inception.md）が作成されること
- [ ] 統合版で以下の成果物が作成されること: サイクルディレクトリ、intent.md、user_stories.md、Unit定義ファイル
- [ ] 旧版setup.mdを読み込むと「統合版setup-inception.mdを読み込んでください」と表示されること
- [ ] 旧版inception.mdを読み込むと「統合版setup-inception.mdを読み込んでください」と表示されること
- [ ] AGENTS.mdの簡略指示が更新されること

**技術的考慮事項**:
- 旧版ファイルはリダイレクト用の短いファイルに置き換え

---

### ストーリー 2.2: Setup/Inception統合（Lite版）
**優先順位**: Must-have
**関連Issue**: #99
**依存関係**: ストーリー2.1（通常版の設計を踏襲）

As a Lite版AI-DLC利用者
I want to Lite版でもSetup/Inceptionを統合したい
So that 通常版との一貫性が保たれる

**受け入れ基準**:
- [ ] Lite版統合プロンプト（lite/setup-inception.md）が作成されること
- [ ] Lite版でサイクル作成からUnit定義まで1回のプロンプト読み込みで完了できること
- [ ] 旧版lite/inception.mdを読み込むと「統合版lite/setup-inception.mdを読み込んでください」と表示されること
- [ ] 通常版2.1と同等のフローがLite版でも実現されること

**技術的考慮事項**:
- Lite版には元々setup.mdがないため、inception.mdへのサイクル作成機能追加が主な変更

---

## Epic 3: AIレビュー改善（#146）

### ストーリー 3.1: Codex resume機能活用
**優先順位**: Should-have
**関連Issue**: #146
**依存関係**: なし

As an AIレビューを利用する開発者
I want to Codex Skillでresume機能を使いたい
So that 同一Unit内で前回のレビューコンテキストを引き継げる

**受け入れ基準**:
- [ ] AIレビュー実行後にセッションIDが出力されること
- [ ] 同一Unit内の2回目以降のレビューで`codex exec resume <session-id>`形式が使用されること
- [ ] 新しいUnitに移行した時は`codex exec -s read-only`で新規セッションが開始されること
- [ ] resume失敗時（セッション期限切れ等）は自動的に新規セッションにフォールバックすること

**技術的考慮事項**:
- セッションIDの保持方法（変数 or 一時ファイル）を検討
- review-flow.mdの修正が必要

---

## Epic 4: Dependabot対応（#96）

### ストーリー 4.1: Dependabot PR確認オプション
**優先順位**: Could-have
**関連Issue**: #96
**依存関係**: なし

As a Dependabotを使用しているプロジェクトの開発者
I want to Inception PhaseでDependabot PRを確認したい
So that セキュリティアップデートをサイクルに含められる

**受け入れ基準**:
- [ ] aidlc.tomlに`[inception.dependabot].enabled`設定が追加されること
- [ ] enabled=trueの場合、Inception PhaseでDependabot PRの一覧が表示されること
- [ ] enabled=false（デフォルト）の場合、Dependabot PR確認ステップがスキップされること
- [ ] PRが存在する場合「これらのPRを今回のサイクルで対応しますか？」と選択肢が表示されること

**技術的考慮事項**:
- 既存のcheck-dependabot-prs.shスクリプトを活用
- デフォルトはfalse（既存の挙動を維持）
