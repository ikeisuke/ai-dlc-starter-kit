# ユーザーストーリー

## Epic: オートモード互換性向上と開発ワークフロー改善

### ストーリー 1: $()パターン排除とwrite-history.sh --content-file追加 (#258)
**優先順位**: Must-have

As a セミオートモードでAI-DLCを使用する開発者
I want to プロンプト内のBash実行例から`$()`コマンド置換を排除したい
So that Claude Codeの許可プロンプトなしでセミオートモードが動作する

**受け入れ基準**:

Phase A: write-history.sh --content-file実装
- [ ] write-history.shに`--content-file <filepath>`オプションが追加され、ファイルからコンテンツを読み込めること
- [ ] `--content-file`にファイルパスを渡し、`--content`と同等の履歴記録が行われること
- [ ] `--content`と`--content-file`を同時指定した場合にエラーメッセージ（終了コード1）が出力されること
- [ ] `--content-file`に存在しないファイルを指定した場合にエラーメッセージ（終了コード1）が出力されること
- [ ] 既存の`--content`引数による呼び出しが引き続き動作すること（後方互換性）

Phase B: 主要フロー置換
- [ ] commit-flow.mdの`git commit -m "$(cat <<'EOF'...)"` パターンが、Writeツール+`git commit -F <tmpfile>`方式の記述に置き換わっていること
- [ ] review-flow.mdのwrite-history.sh呼び出しが、Writeツール+`--content-file`方式の記述に置き換わっていること
- [ ] rules.mdのwrite-history.sh呼び出し例が新方式に更新されていること
- [ ] inception.md、construction.md、operations.md、operations-release.mdの`gh pr create/edit --body "$(cat <<'EOF'...)"` パターンがWriteツール+`--body-file`方式に置き換わっていること

Phase C: 横断クリーンアップ検証
- [ ] `grep -rn '\$(' prompts/package/prompts/ --include='*.md'` で検出された箇所を確認し、コードブロック（```bash...```）内の`$()`が0件であること。判定手順: (1) grepで全`$()`を検出、(2) 各検出箇所がコードブロック内かprose/インラインコードかを文脈で判定、(3) コードブロック内の残存があればIssue化

**技術的考慮事項**:
- 正本は`prompts/package/`。`docs/aidlc/`はrsyncコピーなので直接編集しない
- jj環境の`jj describe -m "$(cat <<'EOF'...)"` も同様に置き換える
- `SQUASH_MESSAGE="$(cat <<'EOF'...)"` パターンはWriteツール+ファイル読み込みに変更
- gh CLIの`--body-file`オプションはgh v2.0+でサポート

---

### ストーリー 2: upgrading-aidlcスキルのスクリプト化 (#256)
**優先順位**: Should-have

As a AI-DLCスターターキットの利用者
I want to /upgrading-aidlcのアップグレード処理をスクリプトで自動実行したい
So that 毎サイクルのアップグレード作業が高速で確実になる

**受け入れ基準**:
- [ ] アップグレードスクリプト（`upgrade-aidlc.sh`）が作成され、バージョン更新・設定マイグレーション・rsync同期を一括実行できること
- [ ] `--dry-run`オプションで実行予定の操作を事前確認できること（実際の変更は行わない）
- [ ] 出力形式が既存スクリプト慣例（`status:success`, `sync_updated:`, etc.）に準拠すること
- [ ] サブスクリプト（migrate-config.sh, sync-package.sh等）の失敗時に、失敗したステップ名とエラー内容が出力され、終了コード1で終了すること
- [ ] 途中失敗後の再実行時に、既に完了したステップは再実行されても追加差分が発生せず、出力が`status:success`（終了コード0）になること（冪等性）
- [ ] SKILL.mdが新スクリプトを呼び出す形に更新されていること
- [ ] `resolve-starter-kit-path.sh`（既存）を利用してスターターキットパスを解決すること

**技術的考慮事項**:
- 正本は`prompts/package/skills/upgrading-aidlc/`
- 既存の`sync-package.sh`, `migrate-config.sh`, `check-setup-type.sh`を活用
- スクリプト配置: `prompts/package/skills/upgrading-aidlc/bin/upgrade-aidlc.sh`
- スクリプト内部の`$()`はClaude Codeの許可対象外のため制約なし（シェルスクリプトの内部ロジック）

---

### ストーリー 3: upgrading-aidlcのPR分離とBash許可自動化 (#213, #212)
**優先順位**: Should-have
**依存**: ストーリー2完了後

As a worktree環境でAI-DLCを使用する開発者
I want to アップグレード変更を開発変更と別のPRで管理したい
So that レビュー時にアップグレード差分と開発差分を区別できる

**受け入れ基準**:
- [ ] SKILL.mdのフローにアップグレード用ブランチ作成ステップが含まれていること
- [ ] アップグレード完了後にPR作成コマンドが生成・実行されること。`gh`未認証時は「gh auth loginで認証してください」のメッセージを表示し、PR作成をスキップすること（終了コード0、warning出力）。ネットワークエラー・権限不足等のPR作成失敗時はエラーメッセージを表示し、手動PR作成の案内を出力すること（終了コード0、warning出力。アップグレード自体は成功扱い）
- [ ] SKILL.md内のBashコマンドに`$()`が含まれないこと（ストーリー1の$()排除ルールに準拠。Claude Codeの許可プロンプト回避）
- [ ] `$(ghq root)`パターンが`resolve-starter-kit-path.sh`の呼び出しに置き換わっていること
- [ ] `$(read-config.sh ...)`パターンが変数代入不要な形に変更されていること

**技術的考慮事項**:
- ブランチ名: `upgrade/vX.X.X`（アップグレード対象バージョン）
- PRマージ後に開発ブランチへのrebase/mergeが必要
- SKILL.md内の記述はClaude Codeが直接実行するため$()回避が必須

---

### ストーリー 4: AIレビューフロー機密情報マスキング手順追加 (#255)
**優先順位**: Should-have

As a 外部AIレビューツールを使用する開発者
I want to AIレビュー前に機密情報を含むファイルが自動的に除外されるようにしたい
So that 外部AIへの機密情報漏洩リスクを低減できる

**受け入れ基準**:
- [ ] review-flow.mdのAIレビュー実行前（ステップ5の反復レビュー開始前）に機密情報スキャンステップが追加されていること
- [ ] 除外パターンとして`.env*`, `*.key`, `*.pem`, `credentials.*`, `*secret*`がデフォルトで定義されていること
- [ ] `docs/aidlc.toml`の`[rules.reviewing]`セクションに`exclude_patterns`設定が追加可能であること
- [ ] 除外されたファイルがある場合、ファイル名一覧がユーザーに表示されること
- [ ] セルフレビュー（ステップ5.5）では機密情報スキャンをスキップすること（同一エージェント内のため不要）
- [ ] スキャン結果に機密情報の内容自体が含まれないこと（ファイル名のみ表示）

**技術的考慮事項**:
- 正本は`prompts/package/prompts/common/review-flow.md`
- 許可リスト方式（`docs/**`, `prompts/**`のみ送信可能）も検討するが、まず拒否リスト方式を優先
- 外部ツール（codex等）呼び出し時のargs内にファイル内容は含まれないことを確認済み（パスのみ渡す）

---

### ストーリー 5: セッションタイトル表示 (#215)
**優先順位**: Could-have

As a 複数リポジトリ・複数サイクルを並行作業する開発者
I want to セッションのタイトルにリポジトリ名・フェーズ・サイクルが表示されてほしい
So that どのセッションがどの作業かを一目で判別できる

**受け入れ基準**:
- [ ] 各フェーズプロンプト（inception.md, construction.md, operations.md）の初期化処理でターミナルタイトルが設定されること
- [ ] タイトル形式が `{プロジェクト名} / {フェーズ名} / {サイクル}` であること（例: `ai-dlc-starter-kit / Inception / v1.18.2`）
- [ ] `env-info.sh`の出力（`project.name`, `current_branch`）を利用してタイトル文字列を生成すること
- [ ] タイトル設定がエラーになっても、フェーズの処理が中断されないこと（エラー時はサイレントにスキップ）
- [ ] ブランチ名がサイクル形式（`cycle/vX.X.X`）でない場合やdetached HEAD時は、サイクル部分を`unknown`と表示すること
- [ ] タイトル設定コマンドに`$()`が含まれないこと

**技術的考慮事項**:
- `printf '\033]0;%s\007' "title"` でターミナルタイトルを設定
- `env-info.sh`の出力からproject.nameとcurrent_branchを取得（ステップ1で既に実行済み）
- IDE統合（VS Code等）でのタイトル表示はターミナルタブのタイトルに反映される

---

### ストーリー 6: update-version.sh rsync対象外ディレクトリへ移動 (#210)
**優先順位**: Could-have

As a AI-DLCスターターキットの利用先プロジェクトの開発者
I want to スターターキット固有のupdate-version.shが配布されないようにしたい
So that 不要なスクリプトがプロジェクトに含まれない

**受け入れ基準**:
- [ ] `prompts/package/bin/update-version.sh`が`bin/update-version.sh`（リポジトリルート直下）に移動していること
- [ ] `docs/cycles/rules.md`の参照パスが`bin/update-version.sh`に更新されていること
- [ ] `.claude/settings.local.json`のallowedToolsの参照パスが更新されていること
- [ ] `/upgrading-aidlc`実行（rsync同期）後に`docs/aidlc/bin/update-version.sh`が存在しないこと
- [ ] `bin/update-version.sh --version v1.0.0 --dry-run` が正常動作すること

**技術的考慮事項**:
- `bin/`ディレクトリはリポジトリルートに既存（`check-size.sh`が存在）
- rsync対象は`prompts/package/`配下のみなので、`bin/`に移動すれば自動的に対象外になる
- sync-package.shの`--delete`オプションにより、移動後のrsyncで`docs/aidlc/bin/update-version.sh`は自動削除される
