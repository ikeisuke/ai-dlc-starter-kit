# ユーザーストーリー

## Epic: AI-DLC開発ワークフローの信頼性向上

### ストーリー 1: worktreeメタ開発でのrsync同期修正 (#274)
**優先順位**: Must-have

As a AI-DLCスターターキット開発者
I want to worktree環境でupgrade-aidlc.shを実行した際にworktree内の最新ファイルが同期される
So that メタ開発時にrsync同期漏れが発生せず、手動修正の手間が不要になる

**受け入れ基準**:
- [ ] `.worktree/dev/`で`prompts/package/`のファイルを編集後、`upgrade-aidlc.sh --force`を実行すると、編集内容が`docs/aidlc/`に反映される
- [ ] worktree以外の通常環境（ブランチ直接チェックアウト）でのupgrade-aidlc.sh実行後、`docs/aidlc/`のファイルが正しく同期される
- [ ] プロジェクトモード（`docs/aidlc/skills/*/bin`から実行）の動作が変わらない
- [ ] `AIDLC_STARTER_KIT_PATH`環境変数によるオーバーライドが引き続き動作する
- [ ] worktree判定に失敗した場合（`.git`ファイルの形式が想定外等）、従来のメタ開発モード動作にフォールバックする

**技術的考慮事項**:
- `resolve_starter_kit_root()`のTier 2パターンマッチでworktree環境を検出する必要がある
- `.git`ファイル（worktreeの場合）の存在で判定可能（通常リポジトリは`.git`ディレクトリ）

---

### ストーリー 2: コンパクション後のセミオートモード引き継ぎ強化 (#273)
**優先順位**: Should-have

As a AI-DLCを使用する開発者
I want to コンパクション後もセミオートモードの挙動が確実に維持される
So that 自動遷移すべき場面で不要なユーザー確認が発生せず、開発フローが中断しない

**受け入れ基準**:
- [ ] コンパクション後に`read-config.sh rules.automation.mode`の再取得が実施され、値がコンテキストに明示的に保持される
- [ ] コンテキスト保持必須情報に`automation_mode`が含まれる
- [ ] コンパクション後の自動継続時にsemi_auto状態であることがユーザーに判別可能な形で通知される
- [ ] `automation_mode=manual`の場合の承認フローは現行通り維持される
- [ ] 設定読取失敗（read-config.shエラー終了コード2）の場合、従来フロー（manual）にフォールバックしユーザーに報告される
- [ ] コンパクション後の次の承認ポイントで、semi_auto/manualの分岐が期待どおり実行される

**技術的考慮事項**:
- `compaction.md`の手順強化が主な対象
- `agents-rules.md`のコンテキスト保持情報にも追加が必要

---

### ストーリー 3: issue-onlyモード時のローカルバックログ操作排除 (#272)
**優先順位**: Must-have

As a AI-DLCを使用する開発者
I want to `backlog.mode=issue-only`設定時にローカルバックログファイルの作成・探索が行われない
So that 設定に忠実な動作が実現され、不要なファイル操作が排除される

**注**: 本ストーリーはUnit分割前提。プロンプト修正（フェーズ別）と既存ファイル削除を別Unitとして定義する。

**受け入れ基準**:
- [ ] `inception.md`のバックログ表示（ステップ6-1）で`backlog.mode`が`issue-only`の場合、ローカルファイル探索をスキップする
- [ ] `inception.md`のバックログ確認（ステップ13）で`backlog.mode`が`issue-only`の場合、ローカルファイル探索をスキップする
- [ ] `inception.md`の対応済みバックログ照合（ステップ13-2）で`backlog.mode`が`issue-only`の場合、ローカルファイル探索をスキップする
- [ ] `construction.md`のバックログ確認で`backlog.mode`が`issue-only`の場合、ローカルファイル探索をスキップする
- [ ] `operations.md`のバックログ整理で`backlog.mode`が`issue-only`の場合、ローカルファイル操作をスキップする
- [ ] `backlog.mode`が`git`または`git-only`の場合は現行動作を維持する
- [ ] 既存のローカルバックログファイル（`docs/cycles/backlog-completed.md` + `docs/cycles/backlog-completed/` 54ファイル）が削除される
- [ ] `backlog.mode`の値が未設定・不正値の場合、`git`として扱い現行動作が維持される
