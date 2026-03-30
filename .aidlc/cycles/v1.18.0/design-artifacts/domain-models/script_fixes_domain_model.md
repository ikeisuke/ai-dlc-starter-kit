# ドメインモデル: スクリプトバグ修正

## 概要

issue-ops.sh、squash-unit.sh、resolve-starter-kit-path.sh の3スクリプトに関するバグ修正・新規作成のドメインモデル。各スクリプトの修正対象コンポーネントの構造と責務を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### GhErrorClassifier（issue-ops.sh 内）

- **ID**: 関数名 `parse_gh_error`
- **属性**:
  - error_output: String - GitHub CLIの標準エラー出力テキスト
- **振る舞い**:
  - classify(error_output): ErrorReason - エラー出力を解析し、適切なエラー理由を返す
  - パターンマッチ順序: 詳細パターン（label-not-found）→ 汎用パターン（not-found, auth-error）→ フォールバック（unknown）

### RootCommitHandler（squash-unit.sh 内）

- **ID**: ルートコミット検出・代替処理ロジック
- **属性**:
  - commit_hash: String - 対象コミットのハッシュ
  - is_root: Boolean - ルートコミットかどうか
- **振る舞い**:
  - detect_root_commit(hash): Boolean - 指定コミットがルートコミット（親なし）か判定
  - build_range_expression(first, last): String - ルートコミット対応のgit log範囲式を構築
  - build_rebase_args(first_commit): Array - ルートコミット対応のrebase引数を構築

### StarterKitPathResolver（resolve-starter-kit-path.sh）

- **ID**: スクリプトファイルパス
- **属性**:
  - script_dir: Path - スクリプト自身のディレクトリ
  - execution_context: ExecutionContext - メタ開発 or 利用プロジェクト
- **振る舞い**:
  - resolve(): Path - スターターキットのルートパスを解決
  - detect_context(): ExecutionContext - 実行コンテキストを判定

## 値オブジェクト（Value Object）

### ErrorReason

- **属性**: reason: String - エラー理由識別子
- **有効値**: `label-not-found`, `not-found`, `auth-error`, `unknown`
- **不変性**: エラー分類結果は不変
- **等価性**: reason文字列で判定

### ExecutionContext

- **属性**: context_type: Enum - 実行コンテキスト種別
- **有効値**:
  - `meta-dev`: スターターキットリポジトリ内（`prompts/package/bin/` から実行）
  - `user-project`: 利用プロジェクト（`docs/aidlc/bin/` から実行）
- **不変性**: 同一実行内で不変
- **等価性**: context_type で判定

### CommitReference

- **属性**:
  - hash: String - コミットハッシュ
  - is_root: Boolean - ルートコミットフラグ
- **不変性**: コミットハッシュは不変
- **等価性**: hash で判定

## 集約（Aggregate）

### ErrorClassification（issue-ops.sh）

- **集約ルート**: GhErrorClassifier
- **含まれる要素**: ErrorReason
- **境界**: GitHub CLIエラー出力の解析と分類
- **不変条件**:
  - ラベル固有のエラーは `label-not-found` として分類され、汎用 `not-found` より優先される
  - 分類結果は必ず有効なErrorReasonのいずれかである

### SquashOperation（squash-unit.sh）

- **集約ルート**: RootCommitHandler
- **含まれる要素**: CommitReference
- **境界**: ルートコミットを含むコミット範囲のsquash操作
- **不変条件**:
  - ルートコミットの場合、`^` 参照を使用しない
  - squash操作前後でtree hashが一致する（データ整合性）

### PathResolution（resolve-starter-kit-path.sh）

- **集約ルート**: StarterKitPathResolver
- **含まれる要素**: ExecutionContext
- **境界**: スクリプト実行位置からスターターキットルートパスの解決
- **不変条件**:
  - `prompts/package/bin/` からの実行ではメタ開発モードとして判定
  - `docs/aidlc/bin/` からの実行では利用プロジェクトモードとして判定
  - symlink・worktree環境でも正しいパスが解決される

## ドメインサービス

### LabelErrorDetection

- **責務**: GitHub CLIのラベル関連エラーを識別
- **操作**:
  - detectLabelError(error_output): ラベル固有のエラーパターンをマッチし、`label-not-found`を返す
  - パターン: `"label" ... "not found"` 等のGitHub API応答パターン

### RootCommitDetection

- **責務**: ルートコミットの検出と代替ロジック提供
- **操作**:
  - isRootCommit(hash): `git rev-list --max-parents=0 HEAD` と比較
  - buildSafeRange(first, last): ルートコミット時は `first..last` を、通常時は `first^..last` を返す
  - buildRebaseArgs(first): ルートコミット時は `--root` を、通常時は `first^` を返す

### MetaDevDetection

- **責務**: スクリプトの実行コンテキストを判定
- **操作**:
  - detectFromScriptDir(script_dir): スクリプトのディレクトリパスからメタ開発モードを判定
  - 判定ロジック: `SCRIPT_DIR` の親ディレクトリ構造から `prompts/package/bin` パターンを検出

## ユビキタス言語

- **ラベルエラー (Label Error)**: GitHub上にラベルが存在しない状態でラベル操作を試みた際のエラー
- **ルートコミット (Root Commit)**: Gitリポジトリの最初のコミット（親コミットが存在しない）
- **メタ開発 (Meta Development)**: AI-DLCスターターキット自体を開発している状態
- **利用プロジェクト (User Project)**: AI-DLCスターターキットを使って別プロジェクトを開発している状態
- **SCRIPT_DIR**: スクリプト自身の絶対ディレクトリパス（`$(cd "$(dirname "$0")" && pwd)`）
- **事後squash (Retroactive Squash)**: HEAD以外の過去Unit範囲をrebase方式でsquashする操作

## 不明点と質問（設計中に記録）

（なし - Issueの詳細とコード分析から要件は明確）
