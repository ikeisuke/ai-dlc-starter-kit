# ドメインモデル: サイクルディレクトリ初期化スクリプト

## 概要

サイクル用ディレクトリ構造を一括作成するシェルスクリプト。サイクルバージョンを引数として受け取り、必要な9個のディレクトリと初期ファイルを作成する。

**重要**: このドメインモデル設計ではコードは書かず、構造と責務の定義のみを行います。

## エンティティ（Entity）

### CycleDirectory

サイクルディレクトリの構造を表すエンティティ。

- **ID**: サイクルバージョン（例: v1.8.0）
- **属性**:
  - version: String - サイクルバージョン（形式: vX.X.X）
  - basePath: String - ベースパス（docs/cycles/{version}）
- **振る舞い**:
  - createStructure: 全ディレクトリを一括作成
  - initializeHistory: history/inception.md を初期化

## 値オブジェクト（Value Object）

### DirectoryPath

作成するディレクトリパスを表す値オブジェクト。

- **属性**: path: String - 相対パス
- **不変性**: パス構造は固定
- **等価性**: パス文字列の完全一致

### DirectoryList

作成するディレクトリの一覧（9個）:

1. `plans/`
2. `requirements/`
3. `story-artifacts/units/`
4. `design-artifacts/domain-models/`
5. `design-artifacts/logical-designs/`
6. `design-artifacts/architecture/`
7. `inception/`
8. `construction/units/`
9. `operations/`
10. `history/`

## ドメインサービス

### DirectoryCreationService

- **責務**: ディレクトリ構造の作成を制御
- **操作**:
  - validateVersion: バージョン形式を検証
  - createDirectories: 全ディレクトリを作成
  - initializeFiles: 初期ファイルを作成

## 入出力仕様

### 入力

- **引数1**: サイクルバージョン（必須、形式: vX.X.X）
- **オプション**:
  - `-h, --help`: ヘルプを表示
  - `--dry-run`: 実際に作成せず、作成予定を表示

### 出力（stdout）

```text
dir:<パス>:<状態>
```

状態:
- `created`: 新規作成
- `exists`: 既存（スキップ）
- `would-create`: 作成予定（--dry-runモード）
- `error`: 作成失敗

### 終了コード

- 0: 正常終了
- 1: 引数エラー
- 2: 作成エラー（一部失敗）

## エラーハンドリング

| エラー種別 | 対処 |
|----------|------|
| バージョン引数なし | ヘルプを表示して終了（exit 1） |
| バージョン形式不正 | エラーメッセージを表示して終了（exit 1） |
| ディレクトリ作成失敗 | stderrにエラー出力、処理継続 |

## 冪等性

- 既存ディレクトリは `exists` として報告しスキップ
- 既存ファイル（history/inception.md）は上書きしない

## ユビキタス言語

- **サイクル**: AI-DLC開発の1イテレーション
- **サイクルバージョン**: vX.X.Xの形式で表現
- **サイクルディレクトリ**: サイクル固有の成果物を格納するディレクトリ構造

## 不明点と質問

（なし - Unit定義で要件が明確化済み）
