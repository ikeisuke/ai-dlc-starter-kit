# AIエージェント向け許可リスト推奨機能

- **発見日**: 2026-01-10
- **発見フェーズ**: セットアップ
- **発見サイクル**: v1.6.1
- **優先度**: 中

## 概要

各種AIエージェント（Claude Code、Cursor、Cline、Windsurf等）向けに、安全なコマンドの許可リストを推奨・設定できる仕組みを提供する。

## 詳細

**背景**:
- AI-DLCでは多くのgitコマンドやファイル操作を実行する
- 毎回の確認は開発体験を損なう
- 破壊的なコマンドは除外しつつ、安全なコマンドは自動許可したい
- 使用するAIエージェントは開発者によって異なる

**対象AIエージェント**:
| エージェント | 設定ファイル |
|-------------|-------------|
| Claude Code | `.claude/settings.local.json` |
| Cursor | `.cursor/rules` または設定 |
| Cline | `.cline/settings.json` |
| Windsurf | 要調査 |
| Aider | `.aider.conf.yml` |

## 許可リスト候補

### 読み取り専用（完全に安全）
- `git status`, `git log`, `git branch`, `git diff`
- `git worktree list`, `git remote`, `git show`
- `ls`, `cat`, `grep`
- `date`, `command -v`
- `gh pr list`, `gh issue list`, `gh auth status`

### 作成系（可逆・安全）
- `git checkout -b`, `git switch`
- `git worktree add`, `git add`, `mkdir`
- `tee` - ファイル追記（履歴記録等で使用）
- `rsync` - ファイル同期（セットアップ・アップグレード時に使用）

### Git操作（歴史改変なし・可逆）
- `git commit` - コミット作成
- `git push` - リモートにプッシュ（--forceなし前提）
- `git reset --soft` - コミット取り消し（変更は保持）
- `git worktree remove`, `git stash`

### 除外（破壊的・歴史改変）
- `git push --force` - 履歴を上書き
- `git reset --hard` - 変更を完全に破棄
- `git clean -fd` - 未追跡ファイル削除
- `git rebase` - 履歴書き換え
- `rm -rf` - ファイル削除

### 備考: git管理下のファイル操作
git管理下であればファイルの書き換えは `git checkout -- <file>` で復元可能なため、危険度は低いと判断できる。

## 対応案

### Phase 1: ドキュメント整備
1. 許可リスト推奨コマンド一覧をドキュメント化
2. 各AIエージェントごとの設定方法を記載
3. `docs/aidlc/guides/ai-agent-allowlist.md` として配置

### Phase 2: セットアップ統合
1. `setup-prompt.md` で使用AIエージェントを質問
2. 対応する設定ファイルのテンプレートを提供
3. 初回セットアップ時に自動設定（オプション）

### Phase 3: ルール統合
1. `rules.md` に許可リストのガイドラインを追記
2. 新規コマンド追加時の判断基準を明文化

## 備考

- `.claude/settings.local.json` は `.gitignore` 対象（ローカル設定）
- プロジェクト共有の設定は `.claude/settings.json` を使用
- 各エージェントの設定ファイル形式は異なるため、テンプレート方式が現実的
