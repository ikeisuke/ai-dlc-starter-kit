# ユーザーストーリー

## Epic: CLIスクリプト品質改善

### ストーリー 1: カスタムサイクル名での履歴記録 (#312)

**優先順位**: Must-have
**依存**: ストーリー2（共通関数化）完了後に実装・検証

As a AI-DLC利用者
I want to カスタムサイクル名（`feature-auth`, `2026-03` 等）で `write-history.sh` が正常動作する
So that 非SemVer形式のサイクル名でも履歴記録が失敗しない

**受け入れ基準**:
- [ ] `write-history.sh --cycle feature-auth --phase inception --step test --content "test"` が終了コード0で完了する
- [ ] `write-history.sh --cycle 2026-03 --phase inception --step test --content "test"` が終了コード0で完了する
- [ ] 既存のSemVer形式（`v1.21.2`）も引き続き正常動作する
- [ ] 名前付きサイクル形式（`waf/v1.0.0`）も引き続き正常動作する
- [ ] 空文字列やスラッシュのみ等の不正な値はエラーで拒否される

**技術的考慮事項**:
`validate_cycle` の正規表現を緩和する。許可パターン: `^[a-z0-9][a-z0-9._-]*(/v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?)?$`（名前のみ、名前/バージョン、バージョンのみすべて許可）

---

### ストーリー 2: バリデーション正規表現の共通関数化 (#309)

**優先順位**: Must-have

As a スターターキット開発者
I want to サイクル名バリデーションの正規表現が1箇所で管理される
So that 仕様変更時に複数スクリプトの修正漏れが発生しない

**受け入れ基準**:
- [ ] `prompts/package/lib/validate.sh` に `validate_cycle` 関数が定義されている
- [ ] `write-history.sh` が `validate.sh` を `source` して `validate_cycle` を使用している
- [ ] `setup-branch.sh` が `validate.sh` を `source` して `validate_cycle` を使用している
- [ ] 各スクリプト内のインラインバリデーション正規表現が削除されている
- [ ] `validate.sh` のパスは各スクリプトの相対パスで解決される

**技術的考慮事項**:
`prompts/package/lib/` ディレクトリを新設。`source` パスはスクリプト自身の `$0` から相対解決する。

---

### ストーリー 3: CLIエラーハンドリング方針統一 (#310)

**優先順位**: Should-have

As a AI-DLC利用者（AIエージェント含む）
I want to 全CLIスクリプトのエラー出力が統一フォーマットである
So that エラーパースが安定し、プロンプト側のエラーハンドリングが簡潔になる

**受け入れ基準**:
- [ ] 新規・修正するエラー出力は `error:<code>:<message>` 形式で記述する
- [ ] プロンプト側のエラーパースは新形式（`error:<code>:<message>`）と旧形式（`error:<code>`）の両方を受け入れる
- [ ] 正常出力（`history:...`, `status:...` 等）のフォーマットは変更されない
- [ ] エラーコードの命名がケバブケース（`invalid-cycle-name` 等）で統一されている

**対象スクリプト**: `write-history.sh`, `setup-branch.sh`, `read-config.sh`, `init-cycle-dir.sh`, `suggest-version.sh`, `check-open-issues.sh`, `check-gh-status.sh`, `check-backlog-mode.sh`, `cycle-label.sh`, `label-cycle-issues.sh`

**移行ルール**: 旧形式 `error:<code>` は読み取り互換のみ維持。新規実装・修正時は必ず `error:<code>:<message>` を使用。廃止期限は設定しない（自然移行）。

**技術的考慮事項**:
プロンプト内でエラー文字列をパースしている箇所も合わせて更新する必要がある。

---

### ストーリー 4: ローカルCIチェック組み込み (#311)

**優先順位**: Should-have

As a AI-DLC利用者
I want to PRオープン前にBash Substitution CheckがOperations Phaseで自動実行される
So that CIでの初回失敗と手戻りが防止される

**受け入れ基準**:
- [ ] Operations Phaseのステップ6.4で `bin/check-bash-substitution.sh` が実行される
- [ ] 違反検出時にエラーが報告され、修正を求められる
- [ ] 違反がない場合は次のステップに進む
- [ ] 既存のMarkdownlintチェックは引き続き実行される

**技術的考慮事項**:
`prompts/package/prompts/operations-release.md` のステップ6.4に追記する。

---

### ストーリー 5: ブランチ作成方式の設定化

**優先順位**: Should-have

As a AI-DLC利用者
I want to `rules.branch.mode` でブランチ作成方式を事前設定できる
So that サイクル開始時の質問がスキップされ作業効率が向上する

**受け入れ基準**:
- [ ] `rules.branch.mode = "branch"` 設定時、main/masterブランチでのサイクル開始でブランチが自動作成される
- [ ] `rules.branch.mode = "worktree"` 設定時、worktreeが自動作成される（`rules.worktree.enabled=true` の場合）
- [ ] `rules.branch.mode = "ask"` 設定時、従来通りユーザーに質問される
- [ ] 未設定時は `"ask"` にフォールバックする
- [ ] 無効な値が設定された場合は警告を表示し `"ask"` にフォールバックする

**技術的考慮事項**:
`inception.md` のステップ7に既にロジックが記述済み。`aidlc.toml` にデフォルト設定を追加する。

---

### ストーリー 6: 個人設定ファイルのリネーム

**優先順位**: Should-have

As a AI-DLC利用者
I want to 個人設定ファイルが `aidlc.local.toml` という名前である
So that エディタのシンタックスハイライトが正しく動作する

**受け入れ基準**:
- [ ] `read-config.sh` が `docs/aidlc.local.toml` を優先的に読み込む
- [ ] `docs/aidlc.toml.local`（旧名）が存在する場合もフォールバックとして読み込まれる
- [ ] 両方存在する場合は `aidlc.local.toml`（新名）が優先される
- [ ] 旧名のみ存在する場合、警告メッセージが表示される（「aidlc.local.toml へのリネームを推奨します」）
- [ ] `.gitignore` に `docs/aidlc.local.toml` が追加されている
- [ ] プロンプト・ガイド内の参照が `aidlc.local.toml` に更新されている

**更新対象ドキュメント**: `prompts/package/prompts/inception.md`, `prompts/package/prompts/common/rules.md`, `prompts/package/guides/config-merge.md`
**検証方法**: `grep -r "aidlc.toml.local" prompts/package/` で旧名の残存がないこと（`.gitignore` と `read-config.sh` のフォールバック処理を除く）
