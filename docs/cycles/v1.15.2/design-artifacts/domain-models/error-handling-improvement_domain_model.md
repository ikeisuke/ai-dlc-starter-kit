# ドメインモデル: エラー処理改善

## 概要

`issue-ops.sh`、`cycle-label.sh`、`setup-branch.sh` の3スクリプトについて、エラー分類・コメント・パス変換の改善に関わる概念と責務を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### GhErrorReason
- **属性**: reason: string - ghコマンドのエラー出力から判別されたエラー理由
- **取り得る値**:
  - `not-found` - Issue/リソースが存在しない
  - `auth-error` - 認証・権限エラー（401, 403, token失効等）
  - `unknown` - 上記に該当しないエラー
- **不変性**: ghエラー出力から一意に決定される
- **等価性**: reason文字列の一致

### AbsolutePath
- **属性**: path: string - ファイルシステムの絶対パス
- **不変性**: 変換元の相対パスから一意に決定される
- **等価性**: パス文字列の一致

## ドメインサービス

### GhErrorParser (`parse_gh_error` 関数)
- **責務**: ghコマンドのエラー出力を解析し、GhErrorReasonを返す
- **操作**: parse(error_output) → GhErrorReason
- **分類ルール**:
  1. `not found` / `could not find` / `could not resolve` → `not-found`
  2. `authentication` / `401` / `403` / `token` / `credential` → `auth-error`
  3. 上記いずれにも該当しない → `unknown`
- **注意**: `gh-not-authenticated`（`check_gh_available`によるプレチェック）とは別の関数。`parse_gh_error`はコマンド実行時のエラーを分類する。

### PathResolver (`worktree_exists` 内のパス変換ロジック)
- **責務**: 相対パスを絶対パスに変換する
- **操作**: resolve(relative_path) → AbsolutePath
- **解決戦略**:
  1. `realpath` コマンドが利用可能かつ成功する場合 → `realpath` を使用
  2. フォールバック → `cd $(dirname path) && pwd` / `$(basename path)` を使用
- **制約**: 未存在パスでは `realpath` が失敗する可能性があるため、必ずフォールバックを用意

## ユビキタス言語

- **GhErrorReason**: ghコマンドのエラー出力から判別されたエラーの種類
- **認証エラー**: gh CLIの操作中に発生する認証・権限に関するエラー（プレチェックの `gh-not-authenticated` とは区別）
- **プレチェック**: コマンド実行前の `gh auth status` による認証確認
- **フォールバック**: 優先手段が失敗した場合の代替手段

## 不明点と質問

なし（変更内容はIssue #194の指摘に基づき明確）
