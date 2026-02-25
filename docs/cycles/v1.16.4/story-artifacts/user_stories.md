# ユーザーストーリー

## Epic: AI-DLCツールチェーンのバグ修正と改善

### ストーリー 1: dasel v3環境での設定読み取り正常化 (#223)
**優先順位**: Must-have

As a AI-DLC利用者
I want to dasel v3環境で `rules.branch.mode` を正しく読み取れるようにしたい
So that ブランチ作成方式の設定が正しく反映され、サイクル開始時のワークフローが中断しない

**受け入れ基準**:
- [ ] `docs/aidlc/bin/read-config.sh rules.branch.mode` がdasel v3環境で終了コード0を返し、期待値（例: `ask`）が出力される
- [ ] dasel v2環境でも同一コマンドが終了コード0を返し、同じ値が出力される
- [ ] `defaults.toml` に定義された `rules.branch.mode = "ask"` が正しく読み取れる
- [ ] `docs/aidlc.toml` で `rules.branch.mode` を上書きした場合、上書き値が返る
- [ ] 存在しないキー（例: `rules.branch.nonexistent`）を指定した場合、終了コード1が返り、既存設定に副作用がない

**技術的考慮事項**:
- v1.16.3でブラケット記法変換が実装済みだが、実運用で失敗するケースが報告されている
- macOS sedの互換性に注意
- dasel v2/v3両環境でのテストが必要

---

### ストーリー 2: issue-ops.sh認証判定バグの修正 (#225)
**優先順位**: Must-have

As a AI-DLC利用者
I want to gh認証済み環境でissue-ops.shがステータス更新を正常に実行できるようにしたい
So that Issue駆動ワークフロー（ステータス変更、ラベル付与等）が正常に動作する

**受け入れ基準**:
- [ ] `docs/aidlc/bin/issue-ops.sh set-status <issue-number> <status>` が認証済みgh環境で `issue:<number>:status:<status>` を返す
- [ ] gh未インストール環境では `gh-not-available` エラーが返る（従来動作維持）
- [ ] gh未認証環境では `gh-not-authenticated` エラーが返る（従来動作維持）
- [ ] 複数ホスト構成（Enterprise等）でGitHub.comには認証済みの環境でも正常動作する
- [ ] `issue-ops.sh label` 実行後、`gh issue view` で対象Issueにラベルが付与されていることを確認できる
- [ ] `issue-ops.sh close` 実行後、`gh issue view` で対象Issueが `state=closed` であることを確認できる
- [ ] `set-status` 実行後、`gh issue view` で対象Issueにステータスラベルが付与されていることを確認できる

**技術的考慮事項**:
- `check_gh_available()` で `gh auth status --hostname github.com` を使用する方針
- 他のissue-ops.shサブコマンド（label, remove-label, close）も同じ認証チェックを使用しているため全体に影響

---

### ストーリー 3: read-config.shドキュメントの更新 (#224)
**優先順位**: Should-have

As a AI-DLC利用者
I want to read-config.shの最新インターフェース（--keysオプション等）がドキュメントに反映されている
So that 新機能を活用でき、設定取得の効率が向上する

**受け入れ基準**:
- [ ] `prompts/package/guides/config-merge.md` に `--keys` オプションの構文（`read-config.sh --keys key1 key2 ...`）と出力形式（`key:value`）の説明が記載されている
- [ ] config-merge.mdに `--keys` オプションの実行例と期待出力が1件以上記載されている
- [ ] `prompts/package/prompts/common/rules.md` の使用例が最新インターフェースを反映している
- [ ] 単一キー形式の後方互換性についての注記が記載されている
- [ ] `--keys` に不正な引数を渡した場合のエラー動作の記載がある（終了コード2）

**技術的考慮事項**:
- v1.16.3で追加された `--keys` オプションの説明
- 既存の単一キー形式は後方互換として維持

---

### ストーリー 4: サイクル完了メッセージの修正 (#229)
**優先順位**: Should-have

As a AI-DLC利用者
I want to サイクル完了後に「start inception」と正しく案内されるようにしたい
So that 次のサイクル開始時に迷わず正しいコマンドを実行できる

**受け入れ基準**:
- [ ] `prompts/package/prompts/operations.md` 内のサイクル完了メッセージセクションで「start setup」が「start inception」に修正されている（2箇所）
- [ ] `prompts/package/prompts/lite/operations.md` 内のサイクル完了メッセージセクションで「start setup」が「start inception」に修正されている（1箇所）
- [ ] `grep -r "start setup" prompts/package/prompts/operations.md prompts/package/prompts/lite/operations.md` の結果が0件である
- [ ] 修正対象のファイルで `git diff` の差分が「start setup」→「start inception」の置換のみであること

**技術的考慮事項**:
- 単純なテキスト置換（3箇所）
- `docs/aidlc/` への反映はOperations Phase時のrsyncで行われる

---

### ストーリー 5: Claude Code許可設定の推奨パターン策定 (#219)
**優先順位**: Should-have

As a AI-DLC利用者
I want to Claude Codeの `.claude/settings.local.json` に設定すべき推奨allowedToolsパターンがドキュメント化されている
So that 新規セットアップ時に適切な許可設定を行い、定型操作での毎回の許可確認を減らせる

**受け入れ基準**:
- [ ] `prompts/package/guides/ai-agent-allowlist.md` のClaude Codeセクション（4.1）に「AI-DLC運用時の推奨設定パターン」サブセクションが追記されている
- [ ] 推奨パターンにはAI-DLCスクリプト群（`docs/aidlc/bin/*`）の一括許可パターンが含まれている
- [ ] フルパスではなく相対パスを推奨する方針と理由が明記されている
- [ ] allow/ask/denyの使い分け方針（読み取り=allow、書き込み=allow、破壊的操作=ask、機密情報=deny）が記載されている
- [ ] 推奨パターンが有効でない場合（例: 記載漏れのスクリプト）に「ask」に落ちる旨の注記がある

**技術的考慮事項**:
- 既存の77個のエントリの整理・統合パターンの例示
- セキュリティとの両立（allow/ask/denyの使い分け）
- 環境依存（worktree、フルパス等）を排除する推奨
