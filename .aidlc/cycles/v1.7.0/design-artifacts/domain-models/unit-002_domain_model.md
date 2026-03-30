# ドメインモデル設計: AIエージェント許可リストガイド

## 概要

AI-DLCで使用するコマンドを分類し、各AIエージェントの許可リスト設定方法をドキュメント化する。

## ドメインモデル

### エンティティ

#### 1. コマンドカテゴリ (CommandCategory)

AI-DLCで使用するコマンドを安全性に基づいて分類。

| カテゴリ | 説明 | 許可推奨度 |
|---------|------|-----------|
| ReadOnly | 読み取り専用、状態を変更しない | 許可推奨 |
| Create | ファイル/ブランチ作成、可逆 | 許可推奨 |
| GitOperation | Git履歴操作（改変なし） | 条件付き許可 |
| Destructive | 破壊的・履歴改変 | 許可非推奨 |

#### 2. コマンド (Command)

個別のシェルコマンド。

| 属性 | 型 | 説明 |
|------|-----|------|
| name | string | コマンド名（例: `git status`） |
| category | CommandCategory | 所属カテゴリ |
| description | string | コマンドの説明 |
| usedIn | Phase[] | 使用されるフェーズ |

#### 3. AIエージェント (AIAgent)

許可リスト設定が可能なAIエージェント。

| 属性 | 型 | 説明 |
|------|-----|------|
| name | string | エージェント名 |
| settingsPath | string | 設定ファイルパス |
| format | SettingsFormat | 設定フォーマット |
| wildcardSupport | WildcardSpec | ワイルドカード仕様 |
| compoundCommandHandling | CompoundHandling | 複合コマンドの扱い |

### 値オブジェクト

#### WildcardSpec

| 属性 | 型 | 説明 |
|------|-----|------|
| prefixMatch | boolean | プレフィックスマッチ対応（`:*`） |
| anywhereMatch | boolean | 任意位置マッチ対応（`*`） |
| shellOperatorAware | boolean | シェル演算子を認識してブロック |

#### CompoundHandling

複合コマンド（`&&`, `||`, `;`, `|`）の扱い。

| 値 | 説明 |
|-----|------|
| Block | シェル演算子を認識してブロック |
| PassThrough | 複合コマンドも単一コマンドとして扱う（脆弱） |
| SubstringDeny | denylistでsubstring matchingによりブロック可能 |
| Unknown | 仕様未確定 |

## コマンド一覧

### ReadOnly（読み取り専用）

| コマンド | 説明 | 使用フェーズ |
|---------|------|-------------|
| `git status` | 作業ツリー状態表示 | 全フェーズ |
| `git log` | コミット履歴表示 | 全フェーズ |
| `git branch` | ブランチ一覧表示 | 全フェーズ |
| `git branch --show-current` | 現在ブランチ表示 | 全フェーズ |
| `git diff` | 差分表示 | 全フェーズ |
| `git show` | コミット内容表示 | Construction, Operations |
| `git rev-parse` | Git参照解決 | Setup |
| `git show-ref` | 参照一覧表示 | Setup |
| `git worktree list` | worktree一覧表示 | Setup |
| `git remote` | リモート一覧表示 | Operations |
| `ls` | ファイル一覧表示 | 全フェーズ |
| `cat` | ファイル内容表示 | 全フェーズ |
| `grep` | テキスト検索 | 全フェーズ |
| `date` | 日時取得 | 全フェーズ |
| `pwd` | 現在ディレクトリ表示 | Setup |
| `command -v` | コマンド存在確認 | Setup, Operations |
| `gh auth status` | GitHub CLI認証状態 | Inception, Operations |
| `gh pr list` | PR一覧表示 | Inception, Operations |
| `gh pr view` | PR詳細表示 | Operations |
| `gh issue list` | Issue一覧表示 | Inception |

### Create（作成系）

| コマンド | 説明 | 使用フェーズ |
|---------|------|-------------|
| `git checkout -b` | ブランチ作成・切り替え | Setup, Inception |
| `git switch -c` | ブランチ作成・切り替え | Setup |
| `git worktree add` | worktree作成 | Setup |
| `git add` | ステージング | 全フェーズ |
| `mkdir -p` | ディレクトリ作成 | Setup |
| `tee` | ファイル書き込み（履歴記録） | 全フェーズ |
| `touch` | 空ファイル作成 | Setup |
| `rsync` | ファイル同期 | Setup（アップグレード） |

### GitOperation（Git操作）

| コマンド | 説明 | 使用フェーズ |
|---------|------|-------------|
| `git commit` | コミット作成 | 全フェーズ |
| `git push` | リモートにプッシュ | Operations |
| `git checkout` | ブランチ切り替え | 全フェーズ |
| `git worktree remove` | worktree削除 | Operations |
| `git stash` | 変更一時退避 | Construction |
| `git tag` | タグ作成 | Operations |
| `gh pr create` | PR作成 | Inception, Operations |
| `gh pr ready` | PRをReady化 | Operations |
| `gh pr merge` | PRマージ | Construction（Unit PR） |
| `gh release create` | リリース作成 | Operations |

### Destructive（破壊的・許可非推奨）

| コマンド | 説明 | 理由 |
|---------|------|------|
| `git push --force` | 強制プッシュ | 履歴上書き |
| `git reset --hard` | ハードリセット | 変更完全破棄 |
| `git clean -fd` | 未追跡ファイル削除 | ファイル削除 |
| `git rebase -i` | インタラクティブリベース | 履歴書き換え |
| `rm -rf` | 再帰的強制削除 | ファイル削除 |
| `curl` / `wget` | 外部URL取得 | セキュリティリスク |

## AIエージェント別仕様

### Claude Code

| 項目 | 値 |
|------|-----|
| 設定ファイル | `.claude/settings.json`（プロジェクト）、`~/.claude.json`（ユーザー） |
| 形式 | JSON（`allow`, `deny` 配列） |
| パターン例 | `Bash(git status)`, `Bash(git commit:*)` |
| プレフィックスマッチ | `:*` で対応 |
| 任意位置マッチ | `*` で対応 |
| シェル演算子認識 | **対応**（v1.0.20+） |
| 複合コマンド | ブロック（`&&`, `||`, `;`, `|`） |

### Codex CLI

| 項目 | 値 |
|------|-----|
| 設定ファイル | `~/.codex/rules/*.rules` |
| 形式 | ルールファイル |
| sandbox | OS強制サンドボックス |
| approval policy | `untrusted`, `on-failure`, `on-request`, `never` |
| テストコマンド | `codex execpolicy check` |

### Kiro CLI

| 項目 | 値 |
|------|-----|
| 設定ファイル | `~/.kiro/settings.json`（macOS）、`~/.config/kiro/settings.json`（Linux） |
| 形式 | JSON（`allowedCommands`, `deniedCommands` 配列） |
| denylist方式 | **substring matching** |
| シェル演算子認識 | **非対応**（Issue #1602で議論中） |
| 複合コマンド対策 | `deniedCommands: ["&&", "||", ";"]` で防御可能 |

### Cline / Cursor

| 項目 | Cline | Cursor |
|------|-------|--------|
| 設定ファイル | Claude Codeと同様 | 専用設定なし |
| 現状 | VSCode拡張で設定が反映されない問題あり | 承認ベース |

## セキュリティ上の注意事項

### 1. シェル演算子の扱い（安全優先）

以下の演算子を含むコマンドは注意が必要：

| 演算子 | 用途 | リスク |
|--------|------|--------|
| `&&` | AND実行 | コマンドチェイン |
| `\|\|` | OR実行 | コマンドチェイン |
| `;` | 順次実行 | コマンドチェイン |
| `\|` | パイプ | データ流出 |
| `&` | バックグラウンド | 制御外実行 |

**注**: Claude Codeの検出対象は非公式情報のため、安全のため全演算子を注意対象とする。

### 2. ワイルドカードの限界

- `Bash(git:*)` は `git status` にマッチ
- しかし変数経由 `URL=... && curl $URL` はバイパス可能
- プロセス置換 `<(...)` やコマンド置換 `$(...)` でもバイパス可能
- 複合コマンド全体をパターン化しても効果は限定的

### 3. 推奨アプローチ

#### アプローチA: 許可リスト + denylist（細かい制御）

1. **Claude Code**: 個別コマンドを許可、シェル演算子は都度承認
2. **Kiro CLI**: `deniedCommands: ["&&", "||", ";", "|", "&"]` を設定
3. **全ツール**: 破壊的コマンド（`rm -rf`, `curl`, `wget`）は明示的にdenylistに追加

#### アプローチB: 全許可 + sandbox（推奨）

**最も安全で効率的なアプローチ**:
- コマンドは全許可（承認の手間を省く）
- sandbox環境で実行（被害を限定）

| ツール | sandbox設定 |
|--------|------------|
| Claude Code | `--dangerously-skip-permissions` + Docker/コンテナ |
| Codex CLI | `sandbox: "workspace-write"` または `"read-only"` |
| Kiro CLI | sandbox設定あり |

**利点**:
- 承認の手間がない
- 万が一の悪意あるコマンドも被害が限定的
- AI-DLCの複合コマンドも問題なく実行可能

## Q&A

[Question] AI-DLCプロンプト内の複合コマンドは許可リストで対応可能か？
[Answer] 現状では困難。複合コマンドは都度承認が必要になる設計。プロンプト修正による複合コマンド削減を別途検討（バックログ追加）。
