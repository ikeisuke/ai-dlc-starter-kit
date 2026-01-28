# ユーザーストーリー

## Epic A: プロンプト改善

### ストーリー A-1: Operations Phase確認削減 (#98)
**優先順位**: Must-have

**私は** AI-DLCを使用する開発者として、Operations Phaseで変更がない場合に確認をスキップしたい。なぜなら、繰り返しサイクルを高速に回せるから。

**受け入れ基準**:
- [ ] `prompts/package/prompts/operations.md` のステップ0冒頭に、変更有無を問う選択肢が追加される
- [ ] 選択肢の文言: 「変更したい項目はありますか？」（はい/いいえ）
- [ ] 「いいえ」を選択した場合、ステップ1-5の確認をスキップして自動進行する
- [ ] 「はい」を選択した場合、ステップ1（デプロイ準備）→ステップ2（CI/CD）→ステップ3（リリース）→ステップ4（運用）→ステップ5（振り返り）の順に各ステップで確認が入る

**技術的考慮事項**:
- 対象ファイル: `prompts/package/prompts/operations.md`
- 既存の確認フローとの後方互換性を維持

---

### ストーリー A-2: タスク管理機能活用 (#129)
**優先順位**: Must-have

**私は** AI-DLCを使用する開発者として、各フェーズ・Unitでタスク管理機能を活用する指示を得たい。なぜなら、タスク漏れを防止し、進捗を可視化できるから。

**受け入れ基準**:
- [ ] `prompts/package/prompts/inception.md` の各ステップ見出し直後に「タスク管理機能を活用してください。」の指示が追加される
- [ ] `prompts/package/prompts/construction.md` の各Unit開始時（ステップ0見出し直後）に同様の指示が追加される
- [ ] `prompts/package/prompts/operations.md` の各ステップ見出し直後に同様の指示が追加される
- [ ] 指示文言: 「タスク管理機能を活用してください。」（ツール非依存、この文言で固定）

**技術的考慮事項**:
- 対象ファイル: `prompts/package/prompts/inception.md`, `construction.md`, `operations.md`
- Claude Code（TaskCreate/TaskUpdate）、KiroCLI等、各ツールで解釈可能な表現にする

---

### ストーリー A-3: AIレビュー完了条件明示化 (#137)
**優先順位**: Must-have

**私は** AI-DLCを使用する開発者として、AIレビュー完了時に明示的な完了メッセージを確認したい。なぜなら、再レビュー漏れを防止できるから。

**受け入れ基準**:
- [ ] `prompts/package/prompts/common/review-flow.md` の「AIレビューフロー」セクション内、条件分岐ブロック直前に完了メッセージ出力指示が追加される
- [ ] AIレビューで指摘0件の場合のみ「【AIレビュー完了】指摘0件」形式のメッセージが出力される
- [ ] 指摘がある場合は「修正を実施」→「AIに再レビューを依頼」→「指摘0件になるまで繰り返し」のフローが動作する
- [ ] 指摘0件時は再レビュー分岐に進まない（完了メッセージ出力後、人間レビューステップへ遷移）

**技術的考慮事項**:
- 対象ファイル: `prompts/package/prompts/common/review-flow.md`

---

## Epic B: セキュリティガイド整備

### ストーリー B-1: サンドボックス環境ガイド (#26)
**優先順位**: Should-have

**私は** AIエージェントを使用する開発者として、サンドボックス環境での実行方法を知りたい。なぜなら、安全にAIエージェントを活用できるから。

**受け入れ基準**:
- [ ] `prompts/package/guides/sandbox-environment.md` が作成される
- [ ] 以下のセクションが含まれる:
  - 概要: サンドボックスの目的（意図しないファイル変更・コマンド実行の防止）と利点
  - Claude Code: Docker環境での実行方法、`--dangerously-skip-permissions` フラグの説明と注意事項
  - Codex CLI: `sandbox` 設定オプション（`"read-only"`, `"workspace-write"`, `"danger-full-access"`）の説明
  - KiroCLI: サンドボックス関連の設定方法（※KiroCLIにサンドボックス機能がない場合は「現時点で未対応」と明記）
  - Docker/コンテナ: 汎用的なコンテナ環境でのAIエージェント実行例（Dockerfile例を含む）
  - セキュリティ注意事項: サンドボックス無効化時のリスク、推奨設定

---

### ストーリー B-2: AIエージェント許可リストガイド (#29)
**優先順位**: Should-have

**私は** AIエージェントを使用する開発者として、安全なコマンドの許可リストを知りたい。なぜなら、毎回の確認を減らしつつ安全性を保てるから。

**受け入れ基準**:
- [ ] `prompts/package/guides/ai-agent-allowlist.md` が作成される
- [ ] 以下のセクションが含まれる:
  - 許可リスト推奨コマンド:
    - 読み取り専用: `cat`, `ls`, `find`, `grep`, `head`, `tail` 等
    - 作成系: `mkdir`, `touch`, `echo` 等
    - Git操作: `git status`, `git diff`, `git log`, `git add`, `git commit` 等
  - 除外すべきコマンド: `rm -rf`, `git push --force`, `git reset --hard`, `sudo` 等（破壊的・歴史改変）
  - 各AIエージェントの設定方法:
    - Claude Code: `.claude/settings.json` の `allowedTools` 設定
    - Cursor: `.cursorrules` または設定ファイル
    - Cline: 設定ファイルでの許可リスト
    - Windsurf: 設定ファイルでの許可リスト
    - Aider: 設定ファイルでの許可リスト
  - 設定ファイルテンプレート: 各ツール向けのコピー可能なテンプレート例

---

## Epic C: 設定管理改善

### ストーリー C-1: aidlc.tomlテンプレート化 (#90)
**優先順位**: Should-have

**私は** AI-DLCスターターキットのユーザーとして、新規セットアップ時にaidlc.tomlをテンプレートから生成したい。なぜなら、設定項目の一元管理と新規セットアップの簡素化ができるから。

**受け入れ基準**:
- [ ] `prompts/package/templates/aidlc.toml.template` が作成される
- [ ] テンプレートには全設定項目（`[project]`, `[rules]`, `[backlog]` 等）とコメントが含まれる
- [ ] `prompts/setup-prompt.md` の新規セットアップ時にテンプレートから `docs/aidlc.toml` が生成される
- [ ] 既存プロジェクトのアップグレード時は `prompts/setup-prompt.md` 内のマイグレーションセクションで新規設定項目が差分追加される（既存設定値は保持）

**技術的考慮事項**:
- 対象ファイル: `prompts/package/templates/aidlc.toml.template`, `prompts/setup-prompt.md`
- 後方互換性を維持

---

## Epic D: ドキュメント完全性向上

### ストーリー D-1: README.mdバージョン情報追加 (#136)
**優先順位**: Could-have

**私は** AI-DLCスターターキットのユーザーとして、README.mdで全バージョンの情報を確認したい。なぜなら、各バージョンの変更内容を把握できるから。

**受け入れ基準**:
- [ ] README.mdに v1.0.1 のセクションが追加される
- [ ] README.mdに v1.1.0 のセクションが追加される
- [ ] README.mdに v1.7.0〜v1.7.4 のセクションが追加される
- [ ] README.mdに v1.9.0〜v1.9.3 のセクションが追加される
- [ ] README.mdに v1.10.0 のセクションが追加される
- [ ] 配置順序: セマンティックバージョン降順（例: v1.10.0 → v1.9.3 → ... → v1.0.1）
- [ ] 見出しレベル: `##` で各バージョンのセクションを作成

**技術的考慮事項**:
- 各バージョンのリリース内容はgit log、CHANGELOG.md等から確認
