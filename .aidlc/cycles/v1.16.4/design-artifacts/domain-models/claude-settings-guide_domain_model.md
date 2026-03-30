# ドメインモデル: Claude Code 許可設定推奨パターン策定

## 概要

Claude Code の permissions 設定を分析し、AI-DLC運用に必要なミニマルセットを定義する。

## エンティティ

### PermissionEntry（許可エントリ）
- **属性**:
  - pattern: string - マッチパターン（例: `Bash(git add:*)`）
  - level: enum(allow/ask/deny) - 許可レベル
  - category: string - カテゴリ分類
- **振る舞い**:
  - matches(command): パターンがコマンドにマッチするか判定

## 値オブジェクト

### Category（カテゴリ）
- **属性**: name: string
- **定義済みカテゴリ**（ミニマルセット表と統一）:
  1. **AI-DLC Scripts** - `docs/aidlc/bin/` 配下のスクリプト群
  2. **Git/jj Operations** - バージョン管理操作（Git + jj）
  3. **GitHub CLI** - GitHub連携操作
  4. **AI Review Skills** - レビュースキル
  5. **External Tools** - 外部AIツール・ユーティリティ（オプション）
  6. **Security (deny)** - 機密ファイル保護

### PathStrategy（パス方針）
- **推奨**: 相対パス
- **根拠**:
  - worktree環境で絶対パスが変わる（`.worktree/dev/` 有無）
  - 他の開発者がcloneした場合にパスが異なる
  - settings.local.json をテンプレートとして共有できない

## セクション3との対応表

| セクション3カテゴリ | 推奨パターンカテゴリ | 対応 |
|---|---|---|
| 3.1 読み取り専用（ls/cat/grep等） | - | Claude Code専用ツール(Read/Grep/Glob)がカバーするためBash許可不要。専用ツールが使えない環境では個別にallow追加 |
| 3.1 読み取り専用（git status/log/diff等） | Git/jj Operations | Claude Code専用ツールでカバーされないため個別にallow |
| 3.1 読み取り専用（gh auth/pr/issue等） | GitHub CLI | allow（読み取り系） |
| 3.2 作成系（git add/checkout -b等） | Git/jj Operations | allow |
| 3.2 作成系（mkdir/touch等） | - | Claude Code専用ツール(Write)でカバー |
| 3.3 Git操作（commit/push等） | Git/jj Operations | allow（制限付き: commit は `-m` 必須） |
| 3.4 破壊的操作（branch -D/merge等） | - | ask（既存設定 + gh pr merge等は新規追加推奨） |
| 3.5 除外対象 | Security (deny) | deny |
| - | AI-DLC Scripts | セクション3に未掲載（新規） |
| - | AI Review Skills | セクション3に未掲載（新規） |
| - | External Tools | セクション3に未掲載（新規） |

## ミニマルセット分析

現在の85エントリを整理した結果:

### allow（必須 - 約20エントリ）

| # | カテゴリ | パターン | 統合元・備考 |
|---|---------|---------|--------|
| 1 | AI-DLC Scripts | `Bash(docs/aidlc/bin/:*)` | 個別スクリプト18エントリ + 絶対パス重複を統合。`:*` プレフィックスマッチでbin/以下すべてにマッチ |
| 2 | Git/jj Operations | `Bash(git add:*)` | 既存 |
| 3 | Git/jj Operations | `Bash(git commit -m:*)` | `-m` 必須で `--amend` を除外（既存ガイド準拠） |
| 4 | Git/jj Operations | `Bash(git checkout:*)` | 既存 |
| 5 | Git/jj Operations | `Bash(git pull:*)` | 既存 |
| 6 | Git/jj Operations | `Bash(git push:*)` | 既存（`--force` は既存設定例の ask で制御） |
| 7 | Git/jj Operations | `Bash(jj status:*)` | 読み取り |
| 8 | Git/jj Operations | `Bash(jj log:*)` | 読み取り |
| 9 | Git/jj Operations | `Bash(jj diff:*)` | 読み取り |
| 10 | Git/jj Operations | `Bash(jj bookmark:*)` | ブックマーク操作 |
| 11 | Git/jj Operations | `Bash(jj describe -m:*)` | コミットメッセージ設定 |
| 12 | Git/jj Operations | `Bash(jj new:*)` | 新規変更作成 |
| 13 | Git/jj Operations | `Bash(jj git push:*)` | リモートプッシュ |
| 14 | GitHub CLI | `Bash(gh pr view:*)` | 読み取り |
| 15 | GitHub CLI | `Bash(gh pr create:*)` | PR作成 |
| 16 | GitHub CLI | `Bash(gh pr ready:*)` | ドラフト→Ready |
| 17 | GitHub CLI | `Bash(gh pr list:*)` | 読み取り |
| 18 | GitHub CLI | `Bash(gh issue create:*)` | Issue作成 |
| 19 | GitHub CLI | `Bash(gh issue view:*)` | 読み取り |
| 20 | GitHub CLI | `Bash(gh issue list:*)` | 読み取り |
| 21 | GitHub CLI | `Bash(gh api:*)` | API呼び出し |
| 22 | AI Review Skills | `Skill(reviewing-code)` | 既存 |
| 23 | AI Review Skills | `Skill(reviewing-architecture)` | 既存 |
| 24 | AI Review Skills | `Skill(reviewing-security)` | 既存 |
| 25 | AI Review Skills | `Skill(reviewing-inception)` | 既存 |

### allow（オプション - プロジェクトに応じて追加）

| # | カテゴリ | パターン | 用途 |
|---|---------|---------|------|
| 1 | External Tools | `Bash(codex exec:*)` | Codexレビュー |
| 2 | External Tools | `Bash(claude:*)` | Claudeサブプロセス |
| 3 | External Tools | `Bash(dasel:*)` | TOML設定読み取り |
| 4 | External Tools | `Bash(rsync:*)` | aidlcパッケージ同期 |
| 5 | External Tools | `Bash(prompts/:*)` | セットアップスクリプト |

### ask（破壊的操作）

既存の「設定例（AI-DLC推奨）」のask設定に加え、以下を新規追加推奨:
- `Bash(gh pr merge:*)` - PRマージ（不可逆）**※新規追加推奨**
- `Bash(gh release create:*)` - リリース作成 **※新規追加推奨**

### deny（4エントリ）

| # | パターン | 保護対象 |
|---|---------|---------|
| 1 | `Read(.env)` | 環境変数 |
| 2 | `Read(.env.*)` | 環境変数（派生） |
| 3 | `Read(~/.ssh/**)` | SSH鍵 |
| 4 | `Read(~/.aws/**)` | AWSクレデンシャル |
