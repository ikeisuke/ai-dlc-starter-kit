# ユーザーストーリー

## Epic: ステップファイル・スクリプトの記述と実動作の乖離解消

### 横断的受け入れ基準（全ストーリー共通）

以下の基準は全ストーリーに適用される:
- [ ] 既存CLIの引数体系が変更されていない（新規引数追加は許可、既存引数の削除・変更は不可）
- [ ] 既存のテスト・CIが通過する
- [ ] 対象ファイル/スクリプト単位で修正前後の差分が確認済みである
- [ ] script-design-guideline.md に準拠している（スクリプト変更がある場合）

---

### ストーリー 1: Inception Phase ステップファイルの乖離修正
**優先順位**: Must-have

As a AIエージェント
I want to ステップファイルの記述がスクリプトの実際の出力・動作と一致していること
So that ステップファイルに従ってフェーズを誤判定なく実行できる

**受け入れ基準**:
- [ ] steps/inception/01-setup.md のステップ10コンテキスト表示で、check-open-issues.sh の出力例がスクリプトの実際の出力形式（タブ区切り: `番号 状態 タイトル ラベル 日時`）と一致している（#471）
- [ ] steps/inception/01-setup.md のステップ13で、init-cycle-dir.sh のバックログディレクトリに関する記述が「作成」ではなく実動作（`skipped-issue-only`）を反映している（#472）
- [ ] steps/inception/01-setup.md のステップ11 setup-branch.sh 出力例に、名前付きサイクル時の worktree_path 形式（例: `.worktree/cycle-waf-v1.0.0`、スラッシュ→ハイフン置換）が記載されている（#473）
- [ ] 修正対象のステップファイルに、旧記述（修正前の不一致表現）が残存していない

---

### ストーリー 2: Construction Phase ステップファイルの乖離修正
**優先順位**: Must-have

As a AIエージェント
I want to Construction Phaseのステップファイルにissue-ops.shの出力形式が記載されていること
So that スクリプト実行結果の成功/失敗を正しく判定して次のステップに進める

**受け入れ基準**:
- [ ] steps/construction/01-setup.md のステップ11に、issue-ops.sh の出力形式（`status:success`/`status:error` + 詳細行）が追記されている（#474）

---

### ストーリー 3: テンプレート・スクリプトの形式統一
**優先順位**: Must-have

As a AIエージェント
I want to テンプレートのプレースホルダ形式が統一され、スクリプトの出力形式が標準化されていること
So that テンプレート適用時やスクリプト出力解析時に誤判定なく処理を継続できる

**受け入れ基準**:
- [ ] implementation_record_template.md 内のプレースホルダが `{{PLACEHOLDER}}` 形式に統一されている（`<unit>` 等の山括弧形式が残っていない）（#475）
- [ ] run-markdownlint.sh 実行時、終了条件ごとに `markdownlint:success`/`markdownlint:skipped`/`markdownlint:error` のいずれか1行を標準出力に返す（#476）
- [ ] 旧プレースホルダ形式（`<unit>` 等の山括弧形式）がテンプレート内に残存していない（grep確認）

---

### ストーリー 4: Operations Phase 乖離一括修正
**優先順位**: Must-have

As a AIエージェント
I want to Operations Phaseのステップファイルとスクリプトの記述が実動作と一致していること
So that Operations Phaseの各ステップを誤判定なく実行できる

**受け入れ基準**:
- [ ] 02-deploy.md 内の成果物ファイル名が `distribution_feedback.md` に統一されている（テンプレート名 `distribution_feedback_template.md` と一致）（#477-1）
- [ ] 01-setup.md 内の write-history.sh 使用例に複数 `--artifacts` 指定の記述が追加されている（#477-2）
- [ ] operations-release.md 内の pr-ops.sh `get-related-issues` の出力形式（`issue:番号:タイトル` 等）が明記されている（#477-3）
- [ ] post-merge-cleanup.sh のgitコマンドから不要な `--` が除去されている（#477-4）
- [ ] post-merge-cleanup.sh の出力で `step_result:4:ok:skipped-branch-not-found` の意味と発生条件が定義されている（#477-5）
- [ ] 04-completion.md のworktreeフロー説明で「ステップスキップ」の記述が実際の動作と一致している（#477-6）
- [ ] ios-build-check.sh の出力キーが `file` または `files` に統一されている（#477-7）

---

### ストーリー 5: aidlc-setup 乖離一括修正
**優先順位**: Must-have

As a セットアップ利用者（AIエージェント）
I want to aidlc-setupのステップファイルとスクリプトの記述が実動作と一致していること
So that セットアップフローを手戻りなく完了できる

**受け入れ基準**:
- [ ] 02-generate-config.md で初回モードと移行モードの分岐条件が箇条書きで列挙され、各分岐先のステップ番号が記載されている（#478-1）
- [ ] setup-ai-tools.sh が参照する `config/settings-template.json` について、不在時のフォールバック動作が記述されている（#478-2）
- [ ] 02-generate-config.md で config.toml 生成時の TOML 配列フォーマット（例: `checks = ["gh", "review-tools"]`）が明記されている（#478-3）
- [ ] migrate-config.sh 内の bootstrap.sh 非依存コメントに、脱却理由とscript-design-guideline.md への参照が追加されている（#478-4）

---

### ストーリー 6: update-version.sh のスキル内 version.txt 更新対応
**優先順位**: Must-have

As a リリース担当者
I want to update-version.sh がスキル内の version.txt も自動更新すること
So that リリース時にversion.txtの更新漏れが発生しない

**受け入れ基準**:
- [ ] `update-version.sh --version X.Y.Z` 実行後、skills/aidlc/version.txt の内容が `X.Y.Z` に更新されている（#479）
- [ ] `update-version.sh --version X.Y.Z` 実行後、skills/aidlc-setup/version.txt の内容が `X.Y.Z` に更新されている（#479）
- [ ] `update-version.sh --version X.Y.Z --dry-run` 実行時、skills/aidlc/version.txt と skills/aidlc-setup/version.txt が更新対象として表示される（#479）
- [ ] `--dry-run` 実行後に version.txt ファイルの内容が変更されていない（#479）

---

### ストーリー 7: migrate-*.sh のscript-design-guideline準拠確認
**優先順位**: Must-have

As a 開発者
I want to migrate-*.shのパス解決がscript-design-guideline.mdに準拠していること
So that スキル間の内部実装依存なく、任意のプロジェクトで自己完結的に動作する

**受け入れ基準**:
- [ ] 対象スクリプト（migrate-detect.sh, migrate-apply-config.sh, migrate-apply-data.sh, migrate-verify.sh, migrate-cleanup.sh, migrate-backlog.sh）が `AIDLC_PROJECT_ROOT="$(git rev-parse --show-toplevel ...)"` パターンでパス解決している（#480）
- [ ] 各スクリプトに `source "${SCRIPT_DIR}/../../other-skill/..."` 等の他スキル内部パス参照が含まれていない（#480）
- [ ] `set -euo pipefail` と `SCRIPT_DIR` 定義がスクリプト冒頭にある（#480）

---

### ストーリー 8: agents-rules.md のMCPレビュー推奨削除
**優先順位**: Must-have

As a AIエージェント
I want to レビュー手順がreview-flow.mdに一元化されていること
So that レビュー実行時に矛盾する手順を参照して判定を誤らない

**受け入れ基準**:
- [ ] agents-rules.md の「実行前の検証」セクションから「MCPレビュー推奨: Codex MCP利用可能時は重要な変更前にレビュー」の行が削除されている
- [ ] agents-rules.md 内にMCPレビューへの参照が残っていない（grep確認）
- [ ] agents-rules.md のレビュー関連記述がreview-flow.mdの手順と相反しないことをgrep/目視で確認済みである

---

### ストーリー 9: review-flow.md のAIレビュー指摘却下禁止ルール追加
**優先順位**: Must-have

As a AIエージェント
I want to review-flow.mdの外部入力検証ルールに「AIレビュワー指摘のAI自己判断による却下禁止」が明記されていること
So that AIレビュワーの指摘が修正→再レビューまたは指摘対応判断フローを経ずに無視されることがない

**受け入れ基準**:
- [ ] review-flow.md の「外部入力検証ルール」セクションに、AIレビュワーの指摘をAIエージェントの自己判断で却下して指摘0件扱いにすることを明示的に禁止するルールが追記されている
- [ ] 指摘がある場合は「修正→再レビュー」または「指摘対応判断フロー」を必ず経由することが義務化されている
- [ ] 「AIレビュー応答の検証」がコンテキスト外のサブエージェントに委譲される方式に変更されている（メインエージェントは検証結果に介入不可）
- [ ] サブエージェントの責務（レビュー結果の構造チェック、明らかな誤検出の判定）と、メインエージェントの責務（サブエージェントの検証結果に基づく修正→再レビューフローの実行）が分離されている

---

### ストーリー 10: メタ開発ルール定義の現行化
**優先順位**: Must-have

As a AIエージェント
I want to メタ開発のルール定義がv2.0.5以降のskills/aidlcプラグイン構成を反映していること
So that ファイル参照境界ルールに従って正しいパスでファイルを編集できる

**受け入れ基準**:
- [ ] `.aidlc/rules.md`「メタ開発の意識」セクションが `prompts/package/` → `skills/aidlc/` の移行を反映している
- [ ] `docs/aidlc/` rsyncコピーに関する記述が削除されている（ディレクトリ廃止済み）
- [ ] プラグイン前提の構成原則が明記されている: プロジェクト相対パスでのスキル内リソース参照禁止
- [ ] スキル間依存ルールが追加されている: 他スキルの内部実装への依存禁止（インターフェイス依存はOK）
- [ ] ファイル参照境界ルールのMETA-001/META-002が現行構成に更新されている
- [ ] 既存Unit定義ファイル（001〜007）の「技術的考慮事項」から古い `prompts/package/` 参照が修正されている
