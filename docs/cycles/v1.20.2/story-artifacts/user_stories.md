# ユーザーストーリー

## Epic: ガイドドキュメント精査・修正

### ストーリー 1: AIエージェント許可リストの刷新

**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to ai-agent-allowlist.md がClaude CodeとKiro CLIのみの正確な設定ガイドになっている
So that 使用するツールに適した許可リスト設定を迷わず構築できる

**受け入れ基準**:

- [ ] `## Codex CLI` 見出しとその配下の設定方法が削除されている
- [ ] `## Cline` 見出しとその配下の設定方法が削除されている
- [ ] `## Cursor` 見出しとその配下の設定方法が削除されている
- [ ] 「はじめに」の適用範囲リストからCodex CLI、Cline、Cursorが削除されている
- [ ] コマンドカテゴリ一覧からjj関連コマンド（`jj status`、`jj log`等）が全て削除されている
- [ ] Claude Code設定例のJSON内からjj関連エントリが全て削除されている
- [ ] 推奨アプローチのsandbox設定表からCodex CLI行が削除されている
- [ ] 参考リンクからCodex CLI、Kiro CLI以外のツールのリンクが削除されている
- [ ] ミニマル推奨セットのjj関連パターンが全て削除されている
- [ ] 削除後もClaude CodeとKiro CLIの設定例・ワイルドカード説明・使い分け指針が記載されている

**技術的考慮事項**:

- 編集対象は `prompts/package/guides/ai-agent-allowlist.md`（デプロイ後: `docs/aidlc/guides/ai-agent-allowlist.md`）
- Kiro CLIの設定情報は残す

---

### ストーリー 2: サンドボックス環境ガイドのツール記述整理

**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to sandbox-environment.md がClaude CodeとKiro CLIに絞った内容になっている
So that 利用するツールの設定方法に集中して参照できる

**受け入れ基準**:

- [ ] Codex CLIの認証設定・sandbox設定記述が削除されている
- [ ] Codex CLI、Cline、Cursor、Gemini CLIの記述が0件である
- [ ] Claude CodeとKiro CLIのサンドボックス設定のみが記載されている
- [ ] 参考リンクから削除したツールのリンクが削除されている
- [ ] 削除後もClaude CodeとKiro CLIのサンドボックス設定手順・セキュリティ注意事項が記載されている

**技術的考慮事項**:

- 編集対象は `prompts/package/guides/sandbox-environment.md`

---

### ストーリー 3: スキル利用ガイドのツール記述整理

**優先順位**: Must-have

As a AI-DLCスターターキット利用者
I want to skill-usage-guide.md がClaude CodeとKiro CLIに絞った内容になっている
So that スキルの利用方法を正確に把握できる

**受け入れ基準**:

- [ ] Gemini CLIの使用方法記述が削除されている
- [ ] Codex CLIの使用方法記述が削除されている
- [ ] Codex CLI、Gemini CLIの記述が0件である
- [ ] Claude CodeとKiro CLIのスキル利用方法のみが記載されている
- [ ] 削除後もClaude CodeとKiro CLIのスキル配置場所・呼び出し方法・セットアップ手順が記載されている

**技術的考慮事項**:

- 編集対象は `prompts/package/guides/skill-usage-guide.md`

---

### ストーリー 4: スクリプト参照の整合性確認

**優先順位**: Should-have

As a AI-DLCスターターキット利用者
I want to ガイドドキュメントのスクリプト参照が全て実在するファイルを指している
So that ガイドの手順を実行した際にスクリプトが見つからないエラーに遭遇しない

**受け入れ基準**:

- [ ] backlog-management.md 内のスクリプトパス参照が全て正本（`prompts/package/bin/`）に実在するファイルと一致している
- [ ] issue-management.md 内のスクリプトパス参照が全て正本に実在するファイルと一致している
- [ ] worktree-usage.md 内のスクリプトパス参照（`setup-branch.sh`、`post-merge-cleanup.sh`等）が全て正本に実在するファイルと一致している
- [ ] 各参照について `ls prompts/package/bin/<script-name>` で存在確認済み

**技術的考慮事項**:

- 各ファイルの精査は `prompts/package/guides/` 配下（正本）で実施
- ガイド内のパス表記は `docs/aidlc/bin/*`（デプロイ後パス）だが、存在確認は `prompts/package/bin/`（正本パス）で行う
- 参照先が存在しない場合は正しいスクリプト名に修正するか、記述を削除する

---

### ストーリー 5: その他ガイドの事実誤記確認

**優先順位**: Should-have

As a AI-DLCスターターキット利用者
I want to 残りのガイドファイルに事実誤記がない
So that ガイドドキュメント全体を信頼して参照できる

**受け入れ基準**:

- [ ] glossary.md の用語定義（Depth Level等）が `prompts/package/prompts/common/rules.md` の定義と一致している
- [ ] error-handling.md の各エラーパターンに「前提条件」「実行コマンド」「期待結果」が記載されている
- [ ] backlog-registration.md の出力テンプレートが `prompts/package/guides/backlog-management.md` と整合している
- [ ] config-merge.md のマージルールが `prompts/package/bin/read-config.sh` の実装と整合している
- [ ] ios-version-update.md は `prompts/package/prompts/inception.md` のiOS関連手順と整合していることを確認済み
- [ ] plan-mode.md はClaude Code専用であることが明記され、機能説明に誤りがないことを確認済み
- [ ] subagent-usage.md はClaude Code専用であることが明記され、参照パスが正しいことを確認済み
- [ ] 変更がないファイルは「確認済み・変更なし」をチェックログに記録済み

**技術的考慮事項**:

- 各ファイルの精査は `prompts/package/guides/` 配下（正本）で実施
- 照合元は各ファイルの技術的考慮事項に記載の正本ファイル

---

### ストーリー 6: 名前付きサイクル継続確認機能の追加

**優先順位**: Should-have

As a AI-DLCスターターキット利用者
I want to 新規サイクル開始時にバージョン決定前に既存の名前付きサイクルがあれば継続利用を提案される
So that 既存の名前付きサイクルを見落とさずに継続開発できる

**受け入れ基準**:

- [ ] ステップ6（バージョン決定）の前に、`docs/cycles/` 配下の名前付きサイクル（`v[0-9]` で始まらないディレクトリ）の存在を確認している
- [ ] 名前付きサイクルが1つ以上存在する場合、「既存の名前付きサイクルを継続しますか？」とユーザーに確認している
- [ ] 「はい」が選択された場合、選択したサイクル名をもとにバージョン提案フロー（ステップ6の名前付きサイクルモード）に遷移する
- [ ] 「いいえ」が選択された場合、従来のバージョン決定フローに遷移する
- [ ] 名前付きサイクルが0件の場合、確認をスキップして従来フローに遷移する
- [ ] `cycle_mode` が既に `named` の場合（名前入力済み）、この確認をスキップする

**技術的考慮事項**:

- 編集対象は `prompts/package/prompts/inception.md` のステップ5.5〜6の間
- 名前付きサイクルの検出: `docs/cycles/` 配下で `v[0-9]` で始まらず `backlog` でもないディレクトリを対象とする
- `suggest-version.sh` の `all_cycles` 出力からも名前付きサイクルを抽出可能

---

### ストーリー 7: mktempでの$()使用禁止の徹底

**優先順位**: Should-have

As a AI-DLCスターターキット利用者
I want to テンポラリファイル規約でmktempを使用する際に`$()`が使われていない
So that Claude Codeの許可プロンプト問題を回避し、一貫した手順でテンポラリファイルを利用できる

**受け入れ基準**:

- [ ] `prompts/setup-prompt.md` 内の `TEMP_FILE=$(mktemp)` パターン（3件）が `$()` を使わない方式に修正されている
- [ ] `prompts/package/prompts/common/rules.md` のテンポラリファイル規約で、mktemp実行時に `$()` を使わないことが明記されている
- [ ] 手順説明が「Bashツールで `mktemp` コマンドを単独実行し出力されたパスを取得」という流れで統一されている

**技術的考慮事項**:

- 編集対象: `prompts/setup-prompt.md`、`prompts/package/prompts/common/rules.md`
- `.sh` スクリプト内の `$(mktemp)` は既存例外ルールにより対象外
