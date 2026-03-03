# ユーザーストーリー

## Epic: AI-DLC品質改善とワークフロー効率化

### ストーリー 1: セミオートモードでのレビューサマリ生成修正 (#262)
**優先順位**: Must-have

As a AI-DLCを使用する開発者
I want to セミオートモードでもConstruction Phaseのレビューサマリファイルが確実に生成される
So that レビュー結果の追跡と品質管理ができる

**受け入れ基準**:
- [ ] `automation_mode=semi_auto` でConstruction Phaseを実行し、AIレビュー指摘0件の場合に `{NNN}-review-summary.md` が `construction/units/` 内に生成される
- [ ] AIレビュー指摘ありで全件対応済みの場合にもレビューサマリが生成される
- [ ] `automation_mode=manual` の既存フローに影響がない（レビューサマリが従来通り生成される）
- [ ] レビューサマリ更新がセミオートゲート判定の前に実行される構造になっている
- [ ] セルフレビューフロー（ステップ5.5）でも同様にレビューサマリが生成される
- [ ] レビューサマリ生成が失敗した場合、エラーメッセージが表示されセミオートゲート判定に進まない

**技術的考慮事項**:
- `prompts/package/prompts/common/review-flow.md` のステップ5・5.5内でレビューサマリ更新を独立ステップとして配置
- 指摘対応判断フロー経由の場合もレビューサマリが生成されることを確認

---

### ストーリー 2: Bashコードブロック内コマンド置換のCI自動検出 (#261)
**優先順位**: Should-have

As a AI-DLCプロンプト開発者
I want to PRのCIチェックでプロンプト内Bashコードブロックのコマンド置換（`$()` およびバッククォート）使用が自動検出される
So that ルール違反のコマンド置換が回帰することを防止できる

**受け入れ基準**:
- [ ] `prompts/package/prompts/**/*.md` 内の ` ```bash ` ～ ` ``` ` ブロックに `$()` が含まれるPRでCIが失敗する
- [ ] 同様にバッククォート（`` `command` ``）によるコマンド置換が含まれるPRでCIが失敗する
- [ ] 説明文やインラインコード内の `$()` やバッククォートは誤検出しない
- [ ] `.sh` スクリプトファイル内の `$()` やバッククォートは対象外
- [ ] 違反検出時にファイル名と行番号が報告される
- [ ] 検出スクリプトがローカルでも実行可能（`bin/check-bash-substitution.sh`）

**技術的考慮事項**:
- `.github/workflows/pr-check.yml` に新規ジョブとして追加
- `bin/check-bash-substitution.sh` を新規作成（`bin/check-size.sh` のパターンに倣う）
- 終了コード: 0=合格, 1=違反検出, 2=スクリプトエラー
- バッククォート検出ではMarkdownインラインコード記法との区別が必要

---

### ストーリー 3: upgrade-aidlc.sh --configオプション廃止 (#264)
**優先順位**: Should-have
**依存関係**: なし（ストーリー4の前提。先にオプション削除を行い、フォールバック処理の削除を容易にする）

As a AI-DLCスターターキットのメンテナー
I want to upgrade-aidlc.shの使われていない--configオプションを廃止する
So that コードが簡素化され、透過問題の根本原因が解消される

**受け入れ基準**:
- [ ] `--config` オプションの引数解析が upgrade-aidlc.sh から削除されている
- [ ] `--config` を指定して実行した場合、不明なオプションとしてエラーメッセージが表示される
- [ ] `CONFIG_PATH` は `docs/aidlc.toml` にハードコードされている
- [ ] 下流スクリプトへの `--config` 透過ロジックが削除されている
- [ ] リリースノートに廃止が明記される

**技術的考慮事項**:
- ストーリー4（dasel必須化）の前提として先に完了すべき

---

### ストーリー 4: upgrade-aidlc.sh dasel必須化 (#263)
**優先順位**: Should-have
**依存関係**: ストーリー3（--config廃止）完了後に実施

As a AI-DLCスターターキットのメンテナー
I want to upgrade-aidlc.shがdasel未インストール時に明確なエラーメッセージで終了する
So that フォールバック処理の複雑さを排除し、コードの堅牢性を向上できる

**受け入れ基準**:
- [ ] `command -v dasel` が失敗する環境で upgrade-aidlc.sh を実行すると `error:dasel-required` が出力される
- [ ] エラーメッセージにdaselのインストール手順（Homebrew等）が含まれる
- [ ] スクリプトがexit 1で終了する（後続処理が実行されない）
- [ ] daselがインストール済みの環境では既存の動作に影響がない
- [ ] 不要になったフォールバック処理が削除されコードが簡素化されている

**技術的考慮事項**:
- スクリプト冒頭（引数解析後）でdaselの存在を確認
- ストーリー3で--config関連コードが削除済みのため、フォールバック処理の特定が容易

---

### ストーリー 5: サイクルバージョン決定時のコンテキスト表示 (#217-A)
**優先順位**: Should-have
**依存関係**: なし

As a AI-DLCを使用する開発者
I want to サイクルバージョン決定時にバックログや過去サイクルの状況を確認できる
So that 十分な情報に基づいて適切なバージョン決定ができる

**受け入れ基準**:
- [ ] Inception Phase ステップ6でバージョン提案前にバックログ件数と上位5件が表示される
- [ ] バックログ表示は `backlog_mode` に応じた取得方法（git: ファイル一覧、issue: `gh issue list`）を使い分ける
- [ ] 直近3サイクルの概要（バージョン、Intent要約1行）がテーブル形式で表示される
- [ ] バックログが0件の場合「バックログ項目なし」と表示される
- [ ] Intent要約の取得に失敗した場合（ファイル不在等）「（Intent不明）」と表示される

**技術的考慮事項**:
- `prompts/package/prompts/inception.md` ステップ6にコンテキスト表示サブステップを追加
- バックログ取得は既存の `check-open-issues.sh` と `ls docs/cycles/backlog/` を活用

---

### ストーリー 6: suggest-version.shの非SemVer対応 (#217-B)
**優先順位**: Should-have
**依存関係**: なし（ストーリー5と独立して実装可能）

As a AI-DLCを使用する開発者
I want to SemVer以外のサイクル命名も使える
So that プロジェクトに合った柔軟なサイクル命名ができる

**受け入れ基準**:
- [ ] `suggest-version.sh` が `docs/cycles/` 配下の全ディレクトリ（SemVer・非SemVer問わず）を `all_cycles:` 行で出力する
- [ ] 既存のSemVerバージョン提案フロー（patch/minor/major）は維持される（出力形式の後方互換性）
- [ ] Inception Phase ステップ6で「自由入力（カスタム名）」が選択肢として提示される（選択肢の文言: 「カスタム名を入力する」）
- [ ] 自由入力時に既存サイクルと重複する名前を入力した場合「このサイクル名は既に使用されています」エラーが表示され再入力を求められる
- [ ] 非SemVer名（例: `feature-auth`, `2026-03`）でサイクルディレクトリとブランチが正常に作成される

**技術的考慮事項**:
- `suggest-version.sh` に `get_all_cycles()` 関数を追加
- `inception.md` ステップ6のバージョン決定フローに自由入力分岐を追加
- `init-cycle-dir.sh` と `setup-branch.sh` は既に非SemVer名を受け付ける

---

### ストーリー 7: マージ後のworktree同期自動化 (#211)
**優先順位**: Could-have

As a worktree環境で開発する開発者
I want to PRマージ後のmain pull・worktree同期・ブランチ削除が自動化される
So that マージ後の手動作業が不要になり、次サイクル開始がスムーズになる

**受け入れ基準**:
- [ ] `bin/post-merge-sync.sh` を実行すると、親リポジトリで `git pull origin main` が実行される
- [ ] worktree（`.worktree/dev`）がdetached HEAD状態になる
- [ ] マージ済みの `cycle/` プレフィックス付きサイクルブランチのみがローカルとリモートから削除される（`cycle/` 以外のブランチは削除禁止）
- [ ] `--yes` オプションなしの場合、リモートブランチ削除前に確認プロンプトが表示される
- [ ] 親リポジトリのパスはworktreeのgit設定から自動検出される
- [ ] いずれかの処理が失敗した場合、エラーメッセージと従来の手動手順が表示され、以降の処理は中断される
- [ ] `docs/cycles/rules.md` の運用手順がスクリプト実行に更新される

**技術的考慮事項**:
- リポジトリ固有スクリプトのため `bin/` に配置（`prompts/package/` には含めない）
- `git worktree list` で親リポジトリのパスを検出
- `git branch -d` でローカル削除、`git push origin --delete` でリモート削除
