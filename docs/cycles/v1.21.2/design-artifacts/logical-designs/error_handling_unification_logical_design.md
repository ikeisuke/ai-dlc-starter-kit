# 論理設計: エラーハンドリング方針統一

## 概要

CLIスクリプトのエラー出力を `error:<code>:<message>` 形式に統一するための、共通関数の仕様と各スクリプトの変更マッピング。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

共通ライブラリパターン: `validate.sh` に `emit_error` 関数を追加し、各スクリプトが `source` して使用する。プロンプト側は原則としてエラーAPI契約（`error:<code>:<message>`）に依存し、構造化出力スクリプト（setup-branch.sh）に対してはステータスAPI+error_code契約にも依存する。

**例外**: 構造化ステータスAPI（複数フィールド出力）を採用するスクリプト（setup-branch.sh）は `emit_error` を使用せず、`error_code:<code>` フィールド追加でエラーコード体系に参加する。

## コンポーネント構成

### レイヤー構成

```text
prompts/package/
├── lib/
│   └── validate.sh          ← emit_error 関数を追加
├── bin/
│   ├── write-history.sh      ← source validate.sh して emit_error 使用
│   ├── setup-branch.sh       ← output() にerror_codeフィールド追加
│   ├── read-config.sh        ← Error: を emit_error に置換
│   ├── init-cycle-dir.sh     ← [error] を emit_error に置換
│   ├── suggest-version.sh    ← error: を emit_error に置換
│   ├── check-open-issues.sh  ← 任意改善: emit_error移行+メッセージ追加
│   ├── cycle-label.sh        ← Error: を emit_error に置換
│   ├── label-cycle-issues.sh ← 任意改善: emit_error移行+メッセージ追加
│   └── validate-git.sh       ← stderr Error: を emit_error に統合
└── prompts/
    ├── inception.md           ← パース規則更新
    ├── operations-release.md  ← パース規則更新
    └── common/
        └── commit-flow.md     ← パース規則更新
```

### コンポーネント詳細

#### validate.sh（出力整形層）

- **責務**: エラーAPI形式での出力を一元管理
- **依存**: なし
- **公開インターフェース**: `emit_error(code, message)` 関数

#### 各CLIスクリプト（呼び出し層）

- **責務**: エラー条件の検出とエラーコード体系に基づく出力
- **依存**: `validate.sh`
- **変更方針**:
  - 標準: 既存のエラー出力を `emit_error` 呼び出しに置換
  - 構造化ステータスAPI採用スクリプト（setup-branch.sh）: `error_code:<code>` フィールド追加で参加

#### プロンプトファイル（消費層）

- **責務**: スクリプト出力のパースとエラー時の分岐処理
- **依存**:
  - エラーAPI契約（`error:<code>[:<message>]`）: 大部分のスクリプト
  - ステータスAPI+error_code契約（`status:error` + `error_code:<code>`）: setup-branch.sh

## スクリプトインターフェース設計

### emit_error 関数（validate.sh に追加）

#### 概要

エラーメッセージを `error:<code>:<message>` 形式で stdout に出力する共通関数。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `$1` (code) | 必須 | エラーコード（ケバブケース） |
| `$2` (message) | 必須（送信契約） | エラーメッセージ。省略時はコードのみ出力（受信互換のため関数は許容するが、新規実装では必ず指定すること） |

#### 出力

```text
error:<code>:<message>
```

- message 省略時: `error:<code>`
- 出力先: stdout
- 終了コード: 関数自体は exit しない（呼び出し側が exit する）

## 各スクリプトの変更仕様

### 1. write-history.sh

**現状**: 混在（`echo "error:..."` 直接出力）
**変更方針**: `source` で `validate.sh` を読み込み、全 `echo "error:..."` を `emit_error` に置換

**source パス解決**:

```text
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "${SCRIPT_DIR}/../lib/validate.sh"
```

**変換例**:

- `echo "error:--cycle requires a value"` → `emit_error "missing-cycle-value" "--cycle requires a value"`
- `echo "error:unknown-option:$1"` → `emit_error "unknown-option" "Unknown option: $1"`
- `echo "error:failed-to-create-directory:$dir"` → `emit_error "failed-create-directory" "Failed to create directory: $dir"`

### 2. setup-branch.sh

**現状**: 独自 `output()` 関数で `status:error` を出力（複数フィールド: status, branch, worktree_path, message）
**変更方針**: `output()` 関数の構造化出力を維持し、エラー時に `error_code` フィールドを追加出力する。`output()` 関数自体は変更しない（後方互換性維持）。

**出力変更**:

エラー時の既存出力:

```text
status:error
branch:<branch>
worktree_path:<path>
message:<日本語メッセージ>
```

新出力（`error_code` フィールドを追加）:

```text
status:error
branch:<branch>
worktree_path:<path>
message:<日本語メッセージ>
error_code:<kebab-case-code>
```

**注意**: `emit_error` は使用しない。setup-branch.sh はステータスAPI形式（複数フィールド出力）を採用しており、エラーAPI形式（`error:<code>:<message>` 単一行）に置換すると構造化情報（branch, worktree_path）が失われるため。代わりにステータスAPI内に `error_code` フィールドを追加する方式で統一コード体系に参加する。

### 3. read-config.sh

**現状**: `echo "Error: ..."` (大文字E) で stderr に出力
**変更方針**: `emit_error` に置換（stdout 出力に変更）

**変換例**:

- `echo "Error: --default requires a value" >&2` → `emit_error "missing-default-value" "--default requires a value"`
- `echo "Error: dasel is not installed" >&2` → `emit_error "dasel-not-installed" "dasel is not installed"`

**Warning 出力**: `Warning: ...` の出力は変更しない（エラーではないため対象外）

**終了コード修正**: 入力系エラー（unknown-option, missing-key 等）の終了コードを 2 → 1 に変更（終了コードポリシー: 1=入力/バリデーション、2=操作/外部依存）

### 4. init-cycle-dir.sh

**現状**: `echo "[error] ..."` で stderr に出力
**変更方針**: `emit_error` に置換（stdout 出力に変更）

**変換例**:

- `echo "[error] VERSION argument is required" >&2` → `emit_error "missing-version" "VERSION argument is required"`
- `echo "[error] ${path}: Failed to create directory" >&2` → `emit_error "failed-create-directory" "Failed to create directory: ${path}"`

**ステータス出力**: `dir:<path>:<status>` 形式の出力は変更しない（ステータスAPIとして維持）

### 5. suggest-version.sh

**現状**: `echo "error: unknown version type: $type"` (スペース付き)
**変更方針**: `emit_error` に置換

**変換例**:

- `echo "error: unknown version type: $type"` → `emit_error "unknown-version-type" "Unknown version type: $type"`

### 6. check-open-issues.sh（任意改善）

**現状**: `echo "error:<code>"` 形式（新形式準拠済み）
**変更方針**: `emit_error` への移行とメッセージフィールド追加は任意改善。実施する場合:

**変換例**:

- `echo "error:missing-limit-value"` → `emit_error "missing-limit-value" "--limit requires a value"`

### 7. cycle-label.sh

**現状**: 混在（新形式 `error:<code>` + 旧形式 `Error:` + `[error]`）
**変更方針**: すべて `emit_error` に統一

**変換例**:

- `echo "error:gh-not-installed" >&2` → `emit_error "gh-not-installed" "gh is not installed"`
- `echo "Error: Unknown option: $1" >&2` → `emit_error "unknown-option" "Unknown option: $1"`
- `echo "[error] ${name}: ${error_output}" >&2` → `emit_error "label-creation-failed" "Failed to create label ${name}: ${error_output}"`

### 8. label-cycle-issues.sh（任意改善）

**現状**: `echo "error:<code>"` 形式（新形式準拠済み）
**変更方針**: `emit_error` への移行とメッセージフィールド追加は任意改善

### 9. validate-git.sh

**現状**: stdout に `error:<code>` + stderr に `Error: ...` の二重出力
**変更方針**: `emit_error` に統合（stdout のみに出力）、stderr の `Error:` 出力を削除

**変換例**:

- `echo "error:git-status-failed"` + `echo "Error: git status failed" >&2` → `emit_error "git-status-failed" "git status --porcelain failed"`

## プロンプト側パース規則の更新

### 対象ファイル

#### inception.md

**setup-branch.sh の出力パース**: setup-branch.sh はステータスAPI形式を採用しているため、`status:error` 行でエラーを検出し、`error_code:<code>` フィールドでエラー種別を判定する。`error:` 単一行形式ではない点に注意。

#### operations-release.md

**validate-git.sh の出力パース**: `error:<code>:<message>` 形式をパースし、コードに応じたエラーメッセージを表示。旧形式 `error:<code>` も後方互換として対応。

#### common/commit-flow.md

**squash-unit.sh の出力パース**: `squash:error` 等の出力は変更なし（squash固有のステータスAPI）。

### パース規則の統一記述

プロンプト側では以下の2系統のパース規則を適用:

#### 系統1: エラーAPI（大部分のスクリプトが使用）

適用対象: write-history.sh, read-config.sh, init-cycle-dir.sh, suggest-version.sh, check-open-issues.sh, cycle-label.sh, label-cycle-issues.sh, validate-git.sh

1. 出力行が `error:` で始まるか確認
2. 最初の2つのコロンで分割: `error` / `<code>` / `<message>`
3. 2番目のコロンがない場合（旧形式）: コードのみ使用
4. コードに基づいてエラー種別を判定し、適切なメッセージを表示

#### 系統2: ステータスAPI + error_code（構造化出力スクリプトが使用）

適用対象: setup-branch.sh

1. `status:error` 行でエラーを検出
2. `error_code:<code>` 行でエラー種別を取得
3. `branch:`, `worktree_path:`, `message:` 等の構造化フィールドも利用可能

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: 影響なし
- **対応策**: `source` による関数読み込みのオーバーヘッドは無視可能

### セキュリティ

- **要件**: エラーメッセージに機密情報を含めない
- **対応策**: `emit_error` のメッセージにAPIキー・トークン等を含めないことを呼び出し側で保証

## 技術選定

- **言語**: Bash
- **ライブラリ**: validate.sh（既存の共通ライブラリに追加）

## 実装上の注意事項

- `prompts/package/` を編集すること（`docs/aidlc/` は直接編集禁止、rsync でコピーされる）
- 既に `validate.sh` を `source` しているスクリプトは追加の `source` 不要
- 現在 `validate_cycle()` を独自定義しているスクリプト（write-history.sh）は、`source` 移行後に独自定義を削除

## 不明点と質問（設計中に記録）

なし
