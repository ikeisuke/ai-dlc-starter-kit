# ドメインモデル: Operations Phaseサイズチェック

## 概要

プロンプトファイルのサイズを測定し、閾値を超えた場合に警告を出力するスクリプトの概念設計。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### FileSize

- **属性**:
  - bytes: Integer - ファイルサイズ（バイト数）
  - lines: Integer - ファイル行数
- **不変性**: 測定時点のスナップショットとして不変
- **等価性**: bytesとlinesが同一であれば等価

### Threshold

- **属性**:
  - max_bytes: Integer - バイト数の閾値（デフォルト: 150000）
  - max_lines: Integer - 行数の閾値（デフォルト: 1000）
- **不変性**: 設定ファイルから読み込んだ値として不変
- **等価性**: max_bytesとmax_linesが同一であれば等価

### SizeCheckConfig

- **属性**:
  - enabled: Boolean - 機能の有効/無効（デフォルト: true）
  - threshold: Threshold - 閾値設定
  - target_pattern: String - 対象ファイルパターン（デフォルト: "*.md"）
- **不変性**: 設定ファイルから読み込んだ値として不変
- **等価性**: 全属性が同一であれば等価

### SizeCheckResult

- **属性**:
  - file_path: String - 対象ファイルパス
  - size: FileSize - 測定結果
  - threshold: Threshold - 適用された閾値
  - exceeds_bytes: Boolean - バイト数超過フラグ
  - exceeds_lines: Boolean - 行数超過フラグ
- **等価性**: 全属性が同一であれば等価

## ドメインサービス

### SizeChecker

- **責務**: ファイルサイズの測定と閾値比較
- **操作**:
  - measure_file(path) → FileSize - 単一ファイルのサイズを測定
  - measure_directory(dir_path, pattern) → List[SizeCheckResult] - ディレクトリ内の該当ファイルを再帰的に測定し結果を返す
  - check_threshold(file_path, file_size, threshold) → SizeCheckResult - 閾値との比較

### ConfigLoader

- **責務**: 設定ファイルから設定を読み込む
- **操作**:
  - load_config(config_path) → SizeCheckConfig - aidlc.tomlから設定を取得
  - is_enabled(config) → Boolean - 機能が有効か確認

### ReportGenerator

- **責務**: チェック結果の整形と出力
- **操作**:
  - format_warning(result) → String - 警告メッセージを整形
  - format_summary(results) → String - サマリーを整形
  - output(message) - 標準出力に出力

## ユビキタス言語

- **閾値（Threshold）**: ファイルサイズの上限値。これを超えると警告が発生する
- **サイズチェック（Size Check）**: ファイルサイズと閾値を比較する処理
- **警告（Warning）**: 閾値超過時に表示されるメッセージ
- **バイト数（Bytes）**: ファイルサイズをバイト単位で測定した値
- **行数（Lines）**: ファイルの行数
- **有効化（Enabled）**: 機能のON/OFF状態
- **対象パターン（Target Pattern）**: チェック対象ファイルを指定するglobパターン

## 不明点と質問

[Question] aidlc.tomlが存在しない場合の動作
[Answer] デフォルト値（enabled=true, max_bytes=150000, max_lines=1000, pattern="*.md"）を使用

[Question] bin/ディレクトリの除外
[Answer] 対象パターン"*.md"により、.shファイルは自動的に除外される

[Question] シンボリックリンクの扱い
[Answer] 通常ファイルのみ対象とし、シンボリックリンクは除外
