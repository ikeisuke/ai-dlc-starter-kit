# ドメインモデル: シェルスクリプトバグ修正・バリデーション強化

## 概要

AI-DLCスターターキットのCLIユーティリティスクリプト（`check-open-issues.sh`、`suggest-version.sh`）における入力バリデーションとエラー処理の構造・責務を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### LimitValue
- **属性**: limit: 正の整数（1以上）
- **不変性**: 引数として渡された後は変更されない
- **等価性**: 数値の一致
- **バリデーションルール**: `^[1-9][0-9]*$` にマッチすること

### VersionType
- **属性**: type: 文字列（"patch" | "minor" | "major"）
- **不変性**: 関数引数として渡された後は変更されない
- **等価性**: 文字列の一致
- **バリデーションルール**: 上記3値のいずれかであること

## ドメインサービス

### check-open-issues（CLIエントリポイント）
- **責務**: GitHub上のオープンIssue一覧を取得して表示する
- **入力契約**:
  - `--limit N`: オプション。N は LimitValue（正の整数）
  - `--limit` 指定時に値が欠落: エラー
  - `--limit` 指定時に値が不正: エラー
- **出力契約**:
  - 正常（Issue有）: `gh issue list` の出力をそのまま stdout
  - 正常（Issue無）: `open_issues:none` を stdout
  - エラー: `error:<エラー種別>[:<コンテキスト>]` を stdout、詳細は stderr
- **エラー種別一覧**（出力形式: `error:<エラー種別>[:<コンテキスト>]`。エラー種別は固定文字列、コンテキストは付帯情報で一部のエラーにのみ付与）:
  - `unknown-option:<option>` - 未知のオプション（`<option>` は付帯コンテキスト）
  - `missing-limit-value` - `--limit` の値未指定
  - `invalid-limit-value` - `--limit` の値が不正
  - `gh-not-installed` - gh コマンド未インストール
  - `gh-not-authenticated` - gh 未認証
  - `gh-issue-list-failed` - Issue取得失敗（詳細は stderr に出力）

### calculate_next_version（内部関数）
- **責務**: 指定されたバージョンとタイプから次バージョンを計算する
- **入力契約**:
  - `$1`: バージョン文字列（例: "v1.2.3"）
  - `$2`: VersionType（"patch" | "minor" | "major"）
- **出力契約**:
  - 正常: 次バージョン文字列を stdout
  - エラー（不正type）: エラーメッセージを stderr、`return 1`

## ユビキタス言語

- **LimitValue**: Issue取得の上限件数。正の整数のみ有効
- **VersionType**: バージョン計算の種別。patch/minor/major の3種
- **エラー種別**: CLIの出力プロトコルにおける固定文字列部分。機械可読性を保証する（例: `unknown-option`, `gh-not-installed`）
- **コンテキスト**: エラー種別に続く付帯情報。可変値を含む場合がある（例: `unknown-option:<実際のオプション名>`）

## 不明点と質問（設計中に記録）

特になし（要件が明確であるため）
