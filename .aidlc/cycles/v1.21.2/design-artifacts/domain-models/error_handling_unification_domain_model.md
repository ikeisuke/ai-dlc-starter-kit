# ドメインモデル: エラーハンドリング方針統一

## 概要

CLIスクリプトのエラー出力を `error:<code>:<message>` 形式に統一するための、エラーコード体系と共通関数の構造定義。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### ErrorCode

- **属性**: code: string - ケバブケース（`[a-z0-9-]+`）のエラー識別子
- **不変性**: 一度定義されたエラーコードは変更しない（後方互換性維持）
- **等価性**: 文字列完全一致

### ErrorMessage

- **属性**: message: string - 単一行の人間向け説明文（改行禁止）
- **不変性**: 出力時に決定される一時的な値
- **等価性**: 使用しない（表示専用）

### ErrorOutput

- **属性**:
  - prefix: "error"（固定値）
  - code: ErrorCode
  - message: ErrorMessage
- **不変性**: 組み立て後は変更しない
- **書式**: `error:<code>:<message>`

## ドメインサービス

### emit_error（共通関数）

- **責務**: ErrorOutput を組み立てて stdout に出力する
- **操作**:
  - emit_error(code, message) → `echo "error:${code}:${message}"` を stdout に出力
- **送信契約**: 新規実装では message 必須。`emit_error "code" "message"` の2引数呼び出しを標準とする
- **受信互換**: パース側は旧形式 `error:<code>`（message なし）も引き続き受信可能
- **制約**:
  - code はケバブケース（`[a-z0-9-]+`）であること
  - message は単一行であること（改行を含まない）
  - 呼び出し側が適切な終了コード（1 または 2）で exit すること

## エラーコード体系

### 命名規則

- ケバブケース: `[a-z0-9-]+`
- カテゴリプレフィックスは使用しない（スクリプト名がコンテキストを提供）
- 既存の準拠済みコードはそのまま維持

### 終了コード対応

| 終了コード | 用途 | 例 |
|-----------|------|-----|
| 1 | バリデーションエラー・入力エラー | missing-cycle, invalid-phase, unknown-option |
| 2 | 操作エラー・外部依存エラー | failed-create-directory, dasel-not-installed |

### スクリプト別エラーコード一覧

#### write-history.sh

| 旧形式 | 新コード | 終了コード |
|--------|---------|-----------|
| `error:--cycle requires a value` | missing-cycle-value | 1 |
| `error:--phase requires a value` | missing-phase-value | 1 |
| `error:--unit requires a value` | missing-unit-value | 1 |
| `error:--unit-name requires a value` | missing-unit-name-value | 1 |
| `error:--unit-slug requires a value` | missing-unit-slug-value | 1 |
| `error:--step requires a value` | missing-step-value | 1 |
| `error:--content requires a value` | missing-content-value | 1 |
| `error:--content-file requires a value` | missing-content-file-value | 1 |
| `error:--artifacts requires a value` | missing-artifacts-value | 1 |
| `error:unknown-option:$1` | unknown-option | 1 |
| `error:unexpected-argument:$1` | unexpected-argument | 1 |
| `error:--cycle is required` | missing-cycle | 1 |
| `error:Invalid cycle name: ${CYCLE}` | invalid-cycle-name | 1 |
| `error:--phase is required` | missing-phase | 1 |
| `error:Invalid phase...` | invalid-phase | 1 |
| `error:--step is required` | missing-step | 1 |
| `error:--content and --content-file are mutually exclusive` | content-mutually-exclusive | 1 |
| `error:file-not-found:$CONTENT_FILE` | content-file-not-found | 1 |
| `error:empty-file:$CONTENT_FILE` | content-file-empty | 1 |
| `error:--content is required` | missing-content | 1 |
| `error:--unit is required for construction phase` | missing-unit-construction | 1 |
| `error:Invalid unit number...` | invalid-unit-number | 1 |
| `error:--unit-name is required for construction phase` | missing-unit-name | 1 |
| `error:--unit-slug is required for construction phase` | missing-unit-slug | 1 |
| `error:failed-to-create-directory:$dir` | failed-create-directory | 2 |
| `error:failed-to-create-file:$filepath` | failed-create-file | 2 |
| `error:failed-to-append-to-file:$filepath` | failed-append-file | 2 |

#### setup-branch.sh

| 旧形式 | 新コード | 終了コード |
|--------|---------|-----------|
| `output "error" ... "ブランチの切り替えに失敗"` | branch-checkout-failed | 1 |
| `output "error" ... "ブランチの作成に失敗"` | branch-creation-failed | 1 |
| `output "error" ... "ディレクトリが存在するがworktreeとして未登録"` | directory-exists-not-registered | 1 |
| `output "error" ... "worktreeの作成に失敗"` | worktree-creation-failed | 1 |
| `output "error" ... "無効なバージョン形式"` | invalid-version-format | 1 |
| `output "error" ... "無効なモード"` | invalid-mode | 1 |

#### read-config.sh

| 旧形式 | 新コード | 終了コード |
|--------|---------|-----------|
| `Error: --default requires a value` | missing-default-value | 1 |
| `Error: Unknown option: $1` | unknown-option | 1 |
| `Error: Multiple keys specified` | multiple-keys | 1 |
| `Error: --keys and positional key are mutually exclusive` | keys-positional-exclusive | 1 |
| `Error: --keys and --default are mutually exclusive` | keys-default-exclusive | 1 |
| `Error: --keys requires at least one key` | keys-requires-keys | 1 |
| `Error: Key is required` | missing-key | 1 |
| `Error: dasel is not installed` | dasel-not-installed | 2 |
| `Error: Config file not found` | config-file-not-found | 2 |
| `Error: Invalid key format` | invalid-key-format | 1 |
| `Error: Failed to create temp file` | temp-file-creation-failed | 2 |
| `Error: Failed to read project config file` | project-config-read-failed | 2 |

#### init-cycle-dir.sh

| 旧形式 | 新コード | 終了コード |
|--------|---------|-----------|
| `[error] VERSION argument is required` | missing-version | 1 |
| `[error] ${version}: Version cannot contain path traversal (..)` | version-path-traversal | 1 |
| `[error] ${version}: Version cannot contain more than one slash` | version-multiple-slashes | 1 |
| `[error] ${version}: Invalid format` | version-invalid-format | 1 |
| `[error] ${path}: Failed to create directory` | failed-create-directory | 2 |
| `[error] ${file_path}: Failed to create file` | failed-create-file | 2 |
| `[error] Unknown option: $1` | unknown-option | 1 |
| `[error] Unexpected argument: $1` | unexpected-argument | 1 |

#### suggest-version.sh

| 旧形式 | 新コード | 終了コード |
|--------|---------|-----------|
| `error: unknown version type: $type` | unknown-version-type | 1 |

#### cycle-label.sh

| 旧形式 | 新コード | 終了コード |
|--------|---------|-----------|
| `error:gh-not-installed` | gh-not-installed | 1 |
| `error:gh-not-authenticated` | gh-not-authenticated | 1 |
| `error:label-list-failed` | label-list-failed | 1 |
| `[error] ${name}: ${error_output}` | label-creation-failed | 2 |
| `Error: Unknown option: $1` | unknown-option | 1 |
| `Error: Too many arguments` | too-many-arguments | 1 |
| `error:missing-version` | missing-version | 1 |

#### validate-git.sh

| 旧形式 | 新コード | 終了コード |
|--------|---------|-----------|
| `error:git-status-failed` + stderr `Error:...` | git-status-failed | 1 |
| `error:branch-unresolved` + stderr `Error:...` | branch-unresolved | 1 |
| `error:fetch-failed` + stderr `Error:...` | fetch-failed | 1 |
| `error:no-upstream` + stderr `Error:...` | no-upstream | 1 |
| `error:log-failed` + stderr `Error:...` | log-failed | 1 |
| stderr `Error: サブコマンドを指定してください` | missing-subcommand | 1 |
| stderr `Error: 不明なサブコマンド: $1` | unknown-subcommand | 1 |

### 準拠済みスクリプト（任意改善）

- **check-open-issues.sh**: `error:<code>` 形式を使用済み。`emit_error` への移行とメッセージフィールド追加は任意改善
- **label-cycle-issues.sh**: `error:<code>` 形式を使用済み。`emit_error` への移行とメッセージフィールド追加は任意改善

### 対象外スクリプト

- **check-gh-status.sh**: ステータスAPI専用（`gh:<status>` 形式、常に exit 0）
- **check-backlog-mode.sh**: ステータスAPI専用（`backlog_mode:<value>` 形式、常に exit 0）

## ユビキタス言語

- **エラーAPI**: `error:<code>:<message>` 形式のエラー出力インターフェース
- **ステータスAPI**: `key:value` 形式の正常系出力インターフェース
- **emit_error**: エラーAPI形式で出力を行う共通関数
- **エラーコード**: ケバブケースのエラー識別子（パース用）
- **エラーメッセージ**: 人間向けの説明文（表示用）
- **後方互換**: 旧形式 `error:<code>` のパース対応を維持すること

## 不明点と質問（設計中に記録）

なし（Unit定義と計画で要件が明確）
