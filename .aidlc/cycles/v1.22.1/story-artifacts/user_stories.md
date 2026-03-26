# ユーザーストーリー

## Epic 1: session-titleスキル移行

### ストーリー 1: session-titleスキルの外部リポジトリ移行
**優先順位**: Must-have

As a AI-DLCスターターキットのメンテナー
I want to session-titleスキルをclaude-skillsリポジトリに一本化する
So that スキルの重複管理コストを削減し、メンテナンス性を向上できる

**前提条件**:
- session-titleはオプション機能であり、未インストールでも全フェーズが正常動作する（既存仕様）
- claude-skills側への統合は本サイクルのスコープ外。本サイクルではai-dlc-starter-kit側の削除と案内更新のみ実施

**受け入れ基準**:
- [ ] `prompts/package/skills/session-title/` ディレクトリが削除されていること
- [ ] `prompts/package/prompts/inception.md` のStep 1.5がclaude-skillsからのインストールを案内する記述に更新されていること
- [ ] `prompts/package/prompts/construction.md` のStep 2.6, Step 4.5が同様に更新されていること
- [ ] `prompts/package/prompts/operations.md` のStep 2.6が同様に更新されていること
- [ ] `prompts/package/prompts/common/ai-tools.md` のスキルカタログからsession-titleエントリが削除または外部参照に変更されていること
- [ ] `prompts/package/guides/skill-usage-guide.md` のsession-title参照が削除または外部参照に更新されていること
- [ ] session-titleスキルが未インストールの環境でInception Phaseを開始した場合、Step 1.5でスキルエラーが発生せずフェーズが継続すること（session-titleは既存仕様でオプショナルであり、この基準は削除後も既存動作が維持されることの確認）

**技術的考慮事項**:
- メタ開発ルールに従い `prompts/package/` を編集すること（`docs/aidlc/` は直接編集禁止）

---

## Epic 2: スクリプトインフラ堅牢性改善

### ストーリー 2: lib/ディレクトリのrsync同期追加
**優先順位**: Must-have

As a AI-DLCスターターキットの利用者
I want to aidlc-setupの実行時にlib/ディレクトリが自動的に同期される
So that read-config.shやwrite-history.shがlib/validate.sh不在でエラーにならない

**受け入れ基準**:
- [ ] `aidlc-setup.sh` のSYNC_DIRS配列に`lib`が追加されていること
- [ ] `prompts/package/lib/validate.sh` が `docs/aidlc/lib/validate.sh` に正しく同期されること
- [ ] 新規プロジェクトでaidlc-setupを実行した場合、`docs/aidlc/lib/` が作成されること
- [ ] 既存プロジェクトでaidlc-setupを再実行した場合、`docs/aidlc/lib/validate.sh` の内容が `prompts/package/lib/validate.sh` と一致すること（diff差分なし）
- [ ] `prompts/package/lib/` が存在しない場合（将来lib/が削除された場合等）、同期がスキップされ他のディレクトリの同期に影響しないこと

**技術的考慮事項**:
- `aidlc-setup.sh` L327-334の`SYNC_DIRS`配列に`"lib"`を追加するだけで対応可能
- 既存の同期ループが存在しないソースディレクトリをスキップする仕組みを持っているか確認が必要
- 関連Issue: #330

---

### ストーリー 3: 承認プロンプト頻発の原因調査と対策
**優先順位**: Should-have

As a AI-DLCのsemi_autoモードユーザー
I want to 承認プロンプト頻発の原因が特定され対策が講じられている
So that 自動化の効果を最大限享受できる

**前提条件**:
- プロンプトファイル内のBashコードブロックにおける$()違反は0件（Reverse Engineering確認済み）。$()以外の原因を調査する

**受け入れ基準**:
- [ ] 承認プロンプトが発生するコマンドパターンを3種類以上特定し（例: heredoc、長い引数、特定コマンド等）、各パターンの再現手順を `docs/cycles/v1.22.1/requirements/approval-prompt-investigation.md` に記録すること
- [ ] 特定された各原因に対し、対策（修正実施またはIssue番号付きバックログ登録）が明示されていること
- [ ] 修正実施した対策については、該当する再現手順で承認プロンプトが発生しないことを確認すること

**技術的考慮事項**:
- 承認プロンプトの発生はClaude Code側の挙動に依存する部分があり、完全な解消は困難な場合がある
- 調査対象: heredoc構文、複雑なパイプライン、特定のコマンドパターン、長い引数文字列等
- 関連Issue: #329

---

### ストーリー 4: アップグレードチェックスキップ機能
**優先順位**: Should-have

As a AI-DLCの利用者
I want to Inception Phase開始時のアップグレードチェックをスキップできる設定がある
So that バージョンが最新であることがわかっている場合に待ち時間なくサイクルを開始できる

**受け入れ基準**:
- [ ] `docs/aidlc.toml` に `[rules.upgrade_check]` セクションと `enabled` キー（デフォルト: true）が定義されていること
- [ ] `prompts/package/prompts/inception.md` のStep 5で`rules.upgrade_check.enabled = false`の場合、バージョン取得・比較をスキップしStep 5.5に進むこと
- [ ] スキップ時に「アップグレードチェックをスキップしました（設定: rules.upgrade_check.enabled = false）」と表示されること
- [ ] デフォルト動作（enabled = true）では従来通りアップグレードチェックが実行されること
- [ ] `enabled` に非boolean値（文字列、数値等）が設定された場合、警告を表示し`true`（デフォルト）として扱うこと

**技術的考慮事項**:
- 既存の設定パターン（rules.worktree.enabled, rules.linting.markdown_lint等）に合わせたboolean形式を採用
- `prompts/package/prompts/inception.md` のStep 5にread-config.sh呼び出しと条件分岐を追加
- 関連Issue: #331

---

## Epic 3: PRマージ前レビューゲート強化

### ストーリー 5: PRマージ前ローカルレビューとCodexレビューゲート
**優先順位**: Must-have

As a AI-DLCスターターキットの開発者
I want to PRマージ前に/reviewとcodex review --base mainを実行し、Codex PRレビュー完了を待つゲートがある
So that push前に問題を検出し修正サイクルを短縮でき、レビュー品質を担保できる

**受け入れ基準**:

ローカルレビュー:
- [ ] `prompts/package/prompts/operations-release.md` のStep 6.6.7とStep 6.7の間に新ステップ（ローカルレビュー実行）が追加されていること
- [ ] ローカルレビューステップで `/review` コマンドの実行が必須、`codex review --base main` はcodex CLI導入時のみ必須として定義されていること
- [ ] ローカルレビューで指摘がある場合、修正→再レビューフローに遷移すること
- [ ] codex CLIが未インストールの場合、`codex review` がスキップされ `/review` のみで続行する旨がフロー内に明記されていること

Codex PRレビューゲート:
- [ ] push後にCodex PRレビュー（@codex review）の完了を待つゲートが `prompts/package/prompts/operations-release.md` に定義されていること
- [ ] CHANGES_REQUESTEDの場合、修正→push→`@codex review`再トリガー→再確認のフローが定義されていること
- [ ] ユーザーの明示的許可でレビュー待ちをスキップしてマージすることが可能であること

配置と整合性:
- [ ] 正本は `prompts/package/prompts/operations-release.md` に配置し、`docs/cycles/rules.md` の既存PRマージ前レビューコメント確認（L154-202）は `operations-release.md` への参照に変更すること
- [ ] gh CLI未インストール時はCodex PRレビューゲートをスキップし、ローカルレビューのみで続行可能であること

**技術的考慮事項**:
- `/review` はClaude Codeの組み込みレビュー機能
- `codex review --base main` はCodex CLIのローカルレビュー機能
- `rules.md` の既存ゲートはoperations-release.mdに統合し、rules.mdは参照リンクのみとする
- 関連Issue: #332, #325
