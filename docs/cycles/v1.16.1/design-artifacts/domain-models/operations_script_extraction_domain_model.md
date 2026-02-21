# ドメインモデル: operations.md定型処理スクリプト化

## 概要

operations.mdの定型検証処理（コミット漏れ確認・リモート同期確認）をシェルスクリプトとして外部化するための入出力仕様・エラーハンドリング・責務境界を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（スクリプト）

### validate-uncommitted.sh

- **責務**: 作業ディレクトリに未コミット変更が存在するかを検出する
- **入力**: なし（カレントディレクトリのgit状態を検査）
- **出力仕様**:

  | キー | 必須/任意 | 値形式 | 出力条件 |
  |------|----------|--------|----------|
  | `status` | 必須 | `ok` / `warning` | 常に出力 |
  | `files_count` | 任意 | 数値 | warning時のみ |
  | `file` | 任意 | porcelain行そのもの（例: `M docs/x.md`）（複数行可） | warning時のみ |

- **終了コード**:
  - 0: 正常終了（ok/warning）
  - 非0: インフラエラー（gitコマンド自体の失敗等。`set -euo pipefail`により即終了。出力契約外）
- **依存コマンド**: `git status --porcelain`

### validate-remote-sync.sh

- **責務**: ローカルの全コミットがリモートにpush済みかを検証する
- **入力**: なし（カレントブランチのgit状態を検査）
- **出力仕様**:

  | キー | 必須/任意 | 値形式 | 出力条件 |
  |------|----------|--------|----------|
  | `status` | 必須 | `ok` / `warning` / `error` | 常に出力 |
  | `remote` | 必須（warning/error時） | 単一値（例: origin） | warning/error時 |
  | `branch` | 必須（warning/error時） | 単一値（取得不可時: `unknown`） | warning/error時 |
  | `unpushed_commits` | 任意 | 数値 | warning時のみ |
  | `error` | 必須（error時） | `fetch-failed` / `no-upstream` / `log-failed` / `branch-unresolved` | error時のみ |

- **終了コード**:
  - 0: ok / warning
  - 1: error（stderrにエラーメッセージも出力）
- **依存コマンド**: `git config`, `git fetch`, `git rev-parse`, `git show-ref`, `git log`, `git branch`

## 値オブジェクト

### ValidationStatus

- **属性**: `ok` / `warning` / `error`
- **不変性**: 各スクリプトの出力は1回の実行で1つのステータスを返す
- **等価性**: 文字列一致

### ErrorType

- **属性**: `fetch-failed` / `no-upstream` / `log-failed` / `branch-unresolved`
- **不変性**: エラー種別はvalidate-remote-sync.shの既知の異常系に限定
- **等価性**: 文字列一致

## ドメインサービス

### operations.md（呼び出し元プロンプト）

- **責務**: スクリプト出力を解釈し、ユーザー向けの復旧ガイダンスを提示
- **操作**:
  - `status:ok` 受信時 → 次のステップへ進行
  - `status:warning` 受信時 → 警告文と対処手順をユーザーに提示、対処後に再実行を促す
  - `status:error` 受信時 → エラー文と復旧手順をユーザーに提示、マージを停止

## 責務境界

```text
┌──────────────────────┐    key:value     ┌──────────────────────┐
│  validate-*.sh       │ ──────────────→  │  operations.md       │
│                      │                  │                      │
│ - git状態の検査      │                  │ - 出力の解釈         │
│ - 機械可読な事実出力 │                  │ - ユーザー向け文面   │
│ - エラー検出         │                  │ - 復旧ガイダンス     │
│                      │                  │ - フロー制御         │
└──────────────────────┘                  └──────────────────────┘
```

- スクリプトはユーザー向けメッセージを出力**しない**
- ユーザーへの指示・警告・エラーメッセージはoperations.mdが責務を持つ
- stderrへのエラーメッセージはデバッグ用であり、AIが直接解釈する対象ではない

## 既存スクリプトとの整合性

### 命名規則

| カテゴリ | 命名パターン | 例 |
|---------|-------------|-----|
| 状態確認 | `check-*.sh` | check-gh-status.sh, check-backlog-mode.sh |
| PRマージ前検証 | `validate-*.sh`（新設） | validate-uncommitted.sh, validate-remote-sync.sh |
| 操作実行 | `*-ops.sh` | pr-ops.sh, issue-ops.sh |
| 情報取得 | `*-info.sh` | env-info.sh, aidlc-git-info.sh |

### ヘッダコメント規約

既存の `check-*.sh` と同一スタイル:

```text
#!/usr/bin/env bash
#
# {script-name}.sh - {1行説明}
#
# 使用方法:
#   ./{script-name}.sh
#
# 出力形式:
#   {key}:{value}
#   - {値1}: {説明}
#   - {値2}: {説明}
#
```

### シェル設定

- `set -euo pipefail` を使用（既存スクリプトと統一）
- **stdoutルール**: stdoutには契約で定義されたkey:value行のみを出力する。gitコマンドの標準出力は `>/dev/null` で抑制する

## ユビキタス言語

- **コミット漏れ**: git作業ディレクトリに未コミットの変更が存在する状態
- **リモート同期**: ローカルの全コミットがリモートリポジトリにpush済みである状態
- **追跡ブランチ**: `@{u}` または `{remote}/{branch}` で参照できるリモートブランチ
- **key:value形式**: `キー名:値` のコロン区切り出力（AI-DLCスクリプト共通の出力規約）
