# Unit 002: AIエージェント許可リストガイド 計画

## 概要

各種AIエージェント（Claude Code、Codex、Cline、Windsurf等）向けに、AI-DLCで使用する安全なコマンドの許可リストをドキュメント化する。

## Phase 1: 設計

### ステップ1: ドメインモデル設計

AI-DLCで使用するコマンドを以下のカテゴリに分類:

1. **読み取り専用（完全に安全）**
   - git: `git status`, `git log`, `git branch`, `git diff`, `git show`, `git rev-parse`, `git show-ref`, `git worktree list`, `git remote`, `git branch --show-current`
   - ファイル: `ls`, `cat`, `head`, `tail`, `grep`, `find`
   - システム: `date`, `pwd`, `command -v`, `echo`, `curl`（読み取り用）
   - GitHub CLI: `gh pr list`, `gh issue list`, `gh auth status`, `gh pr view`

2. **作成系（可逆・安全）**
   - git: `git checkout -b`, `git switch`, `git worktree add`, `git add`
   - ファイル: `mkdir -p`, `tee`, `touch`
   - 同期: `rsync`（セットアップ・アップグレード時）

3. **Git操作（歴史改変なし・可逆）**
   - `git commit`（コミット作成）
   - `git push`（--forceなし）
   - `git checkout`（ブランチ切り替え）
   - `git worktree remove`
   - `git stash`

4. **除外対象（破壊的・歴史改変）**
   - `git push --force`（履歴上書き）
   - `git reset --hard`（変更完全破棄）
   - `git clean -fd`（未追跡ファイル削除）
   - `git rebase -i`（履歴書き換え）
   - `rm -rf`（ファイル削除）

### ステップ2: 論理設計

**ドキュメント構成**:
```
prompts/package/guides/ai-agent-allowlist.md
├── はじめに（目的・適用範囲）
├── コマンドカテゴリ一覧
│   ├── 読み取り専用（許可推奨）
│   ├── 作成系（許可推奨）
│   ├── Git操作（条件付き許可）
│   └── 除外対象（許可非推奨）
├── AIエージェント別設定方法
│   ├── Claude Code
│   ├── Codex CLI
│   ├── Cline
│   ├── Cursor
│   └── その他
└── 備考・注意事項
```

### ステップ3: 設計レビュー

設計ドキュメントをユーザーに提示し承認を得る

## Phase 2: 実装

### ステップ4: コード生成

1. `prompts/package/guides/` ディレクトリを作成
2. `prompts/package/guides/ai-agent-allowlist.md` を作成

### ステップ5: テスト生成

- ドキュメントの内容検証（記載漏れがないか）
- 各AIエージェントの設定パス確認

### ステップ6: 統合とレビュー

1. ドキュメントレビュー
2. `prompts/setup-prompt.md` に案内メッセージを追加
3. ビルド確認（Markdownの構文チェック）

## 成果物

- [ ] `prompts/package/guides/ai-agent-allowlist.md` - 許可リストガイド
- [ ] `prompts/setup-prompt.md` への案内追加

## 見積もり

中（ガイドドキュメント作成 + セットアッププロンプト修正）

## 依存関係

なし
