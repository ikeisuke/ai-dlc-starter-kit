# ドメインモデル: アップグレード判定修正

## 概要

セットアップスクリプト群におけるバージョン検出・比較ロジックの入力正規化と、セットアップ種別判定のフォールバック改善を設計する。

## エンティティ

### VersionInfo（値オブジェクト相当）

- **属性**:
  - raw_version: String - 取得元（version.txt / aidlc.toml）から読み取った生の値
  - sanitized_version: String - vプレフィックス除去後のバージョン（空白トリムは呼び出し元の前処理）
  - normalized_version: String - メジャー.マイナー.パッチに正規化された値（例: 1.9 → 1.9.0）
- **不変性**: 一度正規化されたら変更しない
- **等価性**: normalized_version の文字列一致（意味的同値: 1.9 と 1.9.0 は同値）

## ドメインサービス

### VersionSanitizer（sanitize_version関数）

- **責務**: 入力バージョン文字列からvプレフィックスを除去する（空白トリムは呼び出し元で実施済み）
- **操作**: sanitize(raw) → sanitized
- **入力**: "v1.22.0", "1.22.0" 等
- **出力**: "1.22.0", "1.22.0"

### VersionComparator（既存のcompare_versions関数）

- **責務**: 2つの正規化済みバージョンを比較する（変更なし）
- **操作**: compare(v1, v2) → -1 / 0 / 1

### SetupTypeResolver（check-setup-type.sh）

- **責務**: 設定ファイルの存在とバージョン状態から、セットアップ種別を決定する
- **判定ロジック変更箇所**:
  - aidlc.toml存在 + not_found → upgrade（現行: initial）
  - aidlc.toml存在 + 未知ステータス → unknown（AIに委ねる）

## ユビキタス言語

- **sanitize**: 入力値のvプレフィックス除去処理（空白トリムは呼び出し元の前処理として分離）
- **normalize**: メジャー.マイナー.パッチ形式への補完（1.9 → 1.9.0）
- **not_found**: バージョン情報が取得できない状態（version.txt欠落、aidlc.tomlにキーなし等）
