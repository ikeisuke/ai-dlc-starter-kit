# ユーザーストーリー

## Epic: スクリプトのバグ修正と信頼性向上

### ストーリー 1: setup_claude_permissions失敗時のexit status伝播
**優先順位**: Must-have
**関連Issue**: #343

As a スターターキット利用者
I want to setup_claude_permissions関数が失敗した場合にaidlc-setup.shがエラーを検出できる
So that 不完全なセットアップが通知され、問題を早期に発見・対処できる

**受け入れ基準**:
- [ ] `setup_claude_permissions` が `result:failed` を返す場合、関数の終了コードが非ゼロ（1）になる
- [ ] `setup_claude_permissions` が `result:success` を返す場合、関数の終了コードが0のままである
- [ ] `aidlc-setup.sh` が `setup_claude_permissions` の非ゼロ終了コードを検出し、エラーメッセージを表示する

**技術的考慮事項**:
- 関数の最終行が `echo "result:${result}"` であるため常にexit 0を返す問題
- echoの後にresultに応じたreturn文を追加する方式を検討

---

### ストーリー 2: check-bash-substitution.shのスコープ制限
**優先順位**: Must-have
**関連Issue**: #342

As a スターターキット利用者
I want to check-bash-substitution.shバリデーションがスターターキット開発リポジトリでのみ実行される
So that 他のプロジェクトでOperations Phase実行時にコマンド未検出エラーが発生しない

**受け入れ基準**:
- [ ] `check-bash-substitution.sh` の実行前に `project.name` が `ai-dlc-starter-kit` であることをチェックする条件分岐が存在する
- [ ] `project.name` が `ai-dlc-starter-kit` 以外の場合、バリデーションがスキップされ、正常終了（exit 0）する
- [ ] スターターキット開発リポジトリでは従来通りバリデーションが実行される
- [ ] `project.name` が未設定の場合、バリデーションをスキップし警告メッセージを標準エラー出力に出力して正常終了（exit 0）する
- [ ] `docs/aidlc.toml` の読み取りに失敗した場合、バリデーションをスキップし警告メッセージを標準エラー出力に出力して正常終了（exit 0）する

**技術的考慮事項**:
- Operations Phase のプロンプトまたはスクリプト内でスコープチェックを追加
- `docs/aidlc.toml` の `project.name` を参照する方式

---

## Epic: AI開発プロセスの品質向上

### ストーリー 3: 直接実行優先原則の追加
**優先順位**: Must-have
**関連Issue**: #316

As a AI-DLCを使用する開発者
I want to AIエージェントが直接実行を優先し、間接的なアプローチやバックログ後回しを避ける
So that Claude Code Insightsで検出されたWrong Approachフリクション（14件/40%）の主要パターンに対するガイドラインが明文化され、AIエージェントが参照できる

**受け入れ基準**:
- [ ] `prompts/package/prompts/common/rules.md` に「直接実行優先原則」セクションが追加されている
- [ ] 「直接実行優先」原則が記載されている: タスクを依頼されたら直接実行する。スキルlookupや間接的なアクションを挟まない
- [ ] 「バックログ後回し禁止」原則が記載されている: ユーザーの明示的承認なしにバックログに登録して先に進まない
- [ ] 「最小複雑性」原則が記載されている: 複数のアプローチがある場合、最もシンプルなものを選ぶ
- [ ] 既存の「Overconfidence Prevention原則」の「質問すべき場面」と整合する: 直接実行優先は「要件が明確な場合」に適用し、「要件が曖昧な場合」は従来通り質問する。両原則の適用条件が明文化されている
- [ ] 既存の「改善提案のバックログ登録ルール」との関係が明文化されている: 改善提案時のバックログ登録は引き続き必須であり、直接実行優先原則はユーザーから依頼されたタスクの実行方法に関する原則である

**技術的考慮事項**:
- `prompts/package/prompts/common/rules.md` を編集（`docs/aidlc/` は直接編集禁止）
- 既存ルール（改善提案のバックログ登録ルール、Overconfidence Prevention原則）との整合性を確保

---

## Epic: マルチエージェント環境対応

### ストーリー 4: Kiro agent設定のアップデート
**優先順位**: Should-have
**関連Issue**: #344

As a Kiro環境でAI-DLCを利用する開発者
I want to Kiro agent設定に適切なツール権限とリソース参照が設定されている
So that Kiro環境でもAI-DLCの開発ワークフローが正しく動作する

**受け入れ基準**:
- [ ] `.kiro/agents/aidlc-poc.json` が以下の要件を満たすJSONにアップデートされている
- [ ] `name` フィールドが `"aidlc"` である
- [ ] `description` フィールドが「AI-DLC開発支援エージェント」を含む日本語の説明文である
- [ ] `tools` フィールドが `["@builtin"]` である
- [ ] `allowedTools` に以下が含まれている: `fs_read`, `grep`, `glob`, `code`, `thinking`, `todo_list`, `knowledge`
- [ ] `toolsSettings.execute_bash.allowedCommands` に以下のパターンが含まれている: `docs/aidlc/bin/.*`, `git status`, `git log .*`, `git branch .*`, `git diff .*`, `gh auth status`, `gh issue list .*`, `gh pr list .*`
- [ ] `toolsSettings.execute_bash.autoAllowReadonly` が `true` である
- [ ] `resources` に `file://AGENTS.md` と `file://docs/aidlc/prompts/AGENTS.md` が含まれている
- [ ] 正本は `.kiro/agents/aidlc-poc.json` であり、`prompts/package/kiro/agents/aidlc.json` はOperations Phase時にaidlc-setupで同期される

**技術的考慮事項**:
- 正本: `.kiro/agents/aidlc-poc.json`（直接編集対象）
- `prompts/package/kiro/agents/aidlc.json` はaidlc-setup時にrsyncで同期されるため、今回は `.kiro/agents/aidlc-poc.json` のみ更新
