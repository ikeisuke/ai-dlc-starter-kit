# 論理設計: コード品質向上

## 概要

既存シェルスクリプトの内部実装を改善するリファクタリング。外部インターフェースは変更しない。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

変更なし。既存のシェルスクリプト構造（関数ベース）を維持する。

## コンポーネント構成

### 変更対象コンポーネント

```text
prompts/package/bin/
├── aidlc-git-info.sh   ← IFS初期化追加
└── env-info.sh          ← cat|dasel → stdinリダイレクト
```

### コンポーネント詳細

#### aidlc-git-info.sh

- **責務**: VCS状態情報の取得と出力（変更なし）
- **依存**: git, jj（変更なし）
- **変更箇所**: 初期化セクション（L18付近）
- **変更内容**: `set -uo pipefail` の直前に `IFS=$' \t\n'` を追加

#### env-info.sh - get_project_name 関数

- **責務**: docs/aidlc.toml から project.name を取得（変更なし）
- **変更箇所**: L103
- **変更内容**: `cat docs/aidlc.toml | dasel -i toml 'project.name'` → `dasel -i toml 'project.name' < docs/aidlc.toml`

#### env-info.sh - get_backlog_mode 関数

- **責務**: docs/aidlc.toml から backlog.mode を取得（変更なし）
- **変更箇所**: L120
- **変更内容**: `cat docs/aidlc.toml | dasel -i toml 'backlog.mode'` → `dasel -i toml 'backlog.mode' < docs/aidlc.toml`

#### env-info.sh - get_starter_kit_version 関数

- **責務**: docs/aidlc.toml から starter_kit_version を取得（変更なし）
- **変更箇所**: L205
- **変更内容**: `cat "$toml_file" | dasel -i toml 'starter_kit_version'` → `dasel -i toml 'starter_kit_version' < "$toml_file"`

## スクリプトインターフェース設計

### aidlc-git-info.sh（インターフェース変更なし）

#### 成功時出力

```text
vcs_type:<git|jj|unknown>
current_branch:<branch-name|(no bookmark)|(detached)>
worktree_status:<clean|dirty|unknown>
recent_commits_count:<0-3>
recent_commit_N:<hash> <message>
```

- 終了コード: `0`

### env-info.sh（インターフェース変更なし）

#### 成功時出力（基本）

```text
gh:<available|not-installed|not-authenticated>
dasel:<available|not-installed>
jj:<available|not-installed>
git:<available|not-installed>
starter_kit_version:<version>
```

#### 成功時出力（--setup）

基本出力に加えて:

```text
project.name:<name>
backlog.mode:<mode>
current_branch:<branch>
latest_cycle:<version>
```

- 終了コード: `0`

## 非機能要件（NFR）への対応

### 互換性

- **要件**: 既存の出力・動作を完全に維持
- **対応策**: 修正前後でスクリプトの出力を比較し、差分がないことを確認

### 可読性

- **要件**: コードの可読性向上
- **対応策**: UUOC（Useless Use of Cat）パターンの除去、IFS明示初期化による意図の明確化

## 技術選定

- **言語**: bash
- **外部依存**: dasel（既存、変更なし）

## 実装上の注意事項

- `dasel -i toml 'key' < file 2>/dev/null` の `2>/dev/null` は維持すること（エラー抑制のため）
- `|| { echo ""; return; }` のフォールバックパターンも維持すること
- IFS初期化は `$' \t\n'` 形式（ANSI-C Quoting）を使用すること

## 不明点と質問（設計中に記録）

なし
