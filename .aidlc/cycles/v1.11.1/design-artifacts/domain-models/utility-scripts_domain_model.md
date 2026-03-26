# ドメインモデル: 定型コマンドのスクリプト化

## 概要

AI-DLCで頻繁に使用する定型コマンドをスクリプト化し、許可リスト設定を簡素化する。

## 目的

現在、許可リストガイドには多くの個別コマンドが記載されている（`git status`, `git log`, `git branch --show-current`等）。これらをスクリプトでまとめることで:

1. **許可リスト簡素化**: 個別コマンドの代わりにスクリプト1つを許可するだけで済む
2. **保守性向上**: コマンドの変更・追加がスクリプト内で完結
3. **一貫性確保**: 出力形式が統一される

## スクリプト一覧

### 1. aidlc-env-check.sh

**目的**: 必須ツールの存在確認

**入力**: なし（引数を受け付けない）

**出力形式**:
```text
gh:available|not-installed|not-authenticated
dasel:available|not-installed
jj:available|not-installed
git:available|not-installed
```

**注**: 出力順序は `env-info.sh` と同じ（gh → dasel → jj → git）。

**確認対象ツール**:
| ツール | 確認方法 | 状態 |
|--------|----------|------|
| gh | `command -v` + `gh auth status` | available / not-installed / not-authenticated |
| dasel | `command -v` | available / not-installed |
| jj | `command -v` | available / not-installed |
| git | `command -v` | available / not-installed |

**既存スクリプトとの関係**:
- `env-info.sh` と類似だが、`env-info.sh` は `--setup` オプションで追加情報も出力
- `aidlc-env-check.sh` は環境チェックに特化した最小セット
- 将来的に `env-info.sh` を内部呼び出しする形に統合も検討可能

### 2. aidlc-git-info.sh

**目的**: Git/jjの状態を一括取得

**入力**: なし（引数を受け付けない）

**出力形式**:
```text
vcs_type:<git|jj|unknown>
current_branch:<branch-name|(no bookmark)|(detached)>
worktree_status:<clean|dirty|unknown>
recent_commits_count:<0-3>
recent_commit_1:<hash> <message>
recent_commit_2:<hash> <message>
recent_commit_3:<hash> <message>
```

**注**: `recent_commit_N` は存在するコミット数分のみ出力。

**取得情報**:
| 項目 | コマンド | 説明 |
|------|----------|------|
| vcs_type | `.jj` / `.git` 存在確認 | 使用中のVCS種類 |
| current_branch | git: `git branch --show-current`、jj: `jj log -r @ --no-graph -T 'bookmarks'` の最初の1つ | 現在のブランチ/ブックマーク |
| worktree_status | `git status --porcelain` または `jj diff --stat` | clean（変更なし）/ dirty（変更あり） |
| recent_commits | git: `git log --oneline -3`、jj: `jj log --no-graph -r ::@ -n 3` | 直近3コミット |

**jj対応**:
- `.jj` ディレクトリが存在し、`jj` コマンドが利用可能な場合はjjを優先
- `.jj` 存在するが `jj` コマンドが利用不可の場合、`.git` があればgitにフォールバック
- `.jj` も `.git` も無い場合は `vcs_type:unknown` を出力
- jjで複数ブックマークがある場合は最初の1つを使用
- ブックマークが空の場合は `(no bookmark)` を出力

### 3. aidlc-cycle-info.sh

**目的**: AI-DLCサイクル情報を取得

**入力**: なし（引数を受け付けない）

**出力形式**:
```text
current_cycle:<version|none>
cycle_phase:<inception|construction|operations|unknown>
latest_cycle:<version|none>
cycle_dir:<path|none>
```

**取得情報**:
| 項目 | 取得方法 | 説明 |
|------|----------|------|
| current_cycle | ブランチ名 `cycle/vX.X.X` からバージョン抽出 | 現在作業中のサイクル |
| cycle_phase | `docs/cycles/<version>/` 内のファイル構成から推定 | 現在のフェーズ |
| latest_cycle | `docs/cycles/` 内のバージョンディレクトリを走査 | 最新サイクルバージョン |
| cycle_dir | `docs/cycles/<current_cycle>/` | サイクルディレクトリパス |

**フェーズ判定ロジック**:
```text
サイクルディレクトリなし → unknown
operations/ ディレクトリが存在 → operations
construction/ ディレクトリが存在 → construction
それ以外 → inception
```

**注**: シンプルにディレクトリ存在のみで判定（1秒以内NFR達成のため）。

## 共通仕様

### 出力形式

- **形式**: `key:value` または `key:\n  value1\n  value2`（複数行）
- **目的**: パース可能な形式で、AIエージェントが容易に解釈可能

### エラーハンドリング

- コマンド失敗時は該当項目を `error` または `unknown` として出力
- スクリプト全体は正常終了（exit 0）を維持
- **実装方針**: `set -uo pipefail` を使用し、個別コマンドは `|| true` や明示的なエラーハンドリングで捕捉

### NFR（非機能要件）

| 項目 | 要件 |
|------|------|
| パフォーマンス | 各スクリプトは1秒以内に完了 |
| セキュリティ | 外部入力なし（引数を受け付けない） |
| 移植性 | bash 4.0+、macOS/Linux対応 |

**注**: PATH等のシステム環境変数は使用する。

### 命名規則

- ファイル名: `aidlc-*.sh`（ハイフン区切り）
- 関数名: `snake_case`（既存スクリプトに合わせる）

## 許可リストへの適用

### 現在の設定（許可リストガイドより抜粋）

```json
"allow": [
  "Bash(git status)",
  "Bash(git branch --show-current)",
  "Bash(git log:*)",
  "Bash(git diff:*)",
  "Bash(command -v:*)",
  "Bash(gh auth status)",
  "Bash(jj status:*)",
  "Bash(jj log:*)",
  ...
]
```

### スクリプト活用後の設定例

```json
"allow": [
  "Bash(prompts/package/bin/aidlc-env-check.sh)",
  "Bash(prompts/package/bin/aidlc-git-info.sh)",
  "Bash(prompts/package/bin/aidlc-cycle-info.sh)",
  "Bash(git add:*)",
  "Bash(git commit -m:*)",
  ...
]
```

**注**: スクリプトはPATHに含まれないため、相対パスで指定。
ワイルドカードを使う場合は `Bash(prompts/package/bin/aidlc-*:*)` も可。

**メリット**:
- 読み取り系コマンドがスクリプト3本に集約
- 許可リストの行数が削減
- 新しいコマンド追加時もスクリプト修正だけで対応可能
