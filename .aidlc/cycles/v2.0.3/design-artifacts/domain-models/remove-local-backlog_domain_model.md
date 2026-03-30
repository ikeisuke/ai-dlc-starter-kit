# ドメインモデル: ローカルバックログ廃止

## 概念の変更

### Before（現状）

```text
BacklogMode（値オブジェクト）
├── git        : ローカルファイルがデフォルト
├── issue      : GitHub Issueがデフォルト
├── git-only   : ローカルファイルのみ
└── issue-only : GitHub Issueのみ

BacklogStorage（戦略パターン）
├── GitStorage     : .aidlc/cycles/backlog/*.md
└── IssueStorage   : GitHub Issues (gh CLI)

設定: [rules.backlog].mode = "git" | "issue" | "git-only" | "issue-only"
```

### After（変更後）

```text
BacklogStorage（固定）
└── IssueStorage : GitHub Issues (gh CLI)

設定: backlog_mode設定項目は廃止。バックログは常にGitHub Issueに記録。
```

## 影響を受けるドメイン概念

### 1. バックログ記録フロー

- **Before**: `backlog_mode`に応じてファイル作成またはIssue作成を選択
- **After**: 常にGitHub Issueを作成。`gh_status`が`available`でない場合はユーザーに手動作成を案内

### 2. サイクル初期化

- **Before**: `backlog_mode`がgit系の場合、`.aidlc/cycles/backlog/`ディレクトリを作成
- **After**: バックログディレクトリは作成しない

### 3. プリフライトチェック

- **Before**: `check-backlog-mode.sh`を実行し、`backlog_mode`コンテキスト変数を設定
- **After**: `backlog_mode`コンテキスト変数は不要。チェック自体を廃止

### 4. バックログ確認（Unit開始時）

- **Before**: `backlog_mode`に応じてファイル一覧またはIssue一覧を確認
- **After**: 常に`gh issue list --label backlog`で確認

### 5. 移行検出

- **Before**: `backlog_mode`に応じてバックログディレクトリの削除判定
- **After**: バックログディレクトリが存在すれば常に削除候補として報告

### 6. 旧設定の後方互換性

- **resolve-backlog-mode.sh**: 旧設定（`[rules.backlog].mode`や`[backlog].mode`）が残っている場合、stderr警告を出力。戻り値は常に`issue`
- config.tomlから旧設定を自動削除はしない（非破壊的移行）
