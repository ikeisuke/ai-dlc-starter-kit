# 論理設計: サイクルディレクトリ初期化スクリプト

## 概要

サイクル用ディレクトリ構造を一括作成するシェルスクリプトの論理設計。既存のinit-labels.shと同様のパターンを採用する。

**重要**: この論理設計ではコードは書かず、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

シェルスクリプト標準パターン（init-labels.sh準拠）:
- set -euo pipefail によるエラー処理
- 関数ベースの責務分離
- 出力形式の標準化

## コンポーネント構成

### スクリプト構成

```text
init-cycle-dir.sh
├── ヘッダー（使用方法・オプション説明）
├── 定数定義（ディレクトリリスト）
├── show_help()
├── validate_version()
├── create_directory()
├── init_history_file()
└── main()
```

### コンポーネント詳細

#### show_help()
- **責務**: ヘルプメッセージの表示
- **依存**: なし
- **公開インターフェース**: 標準出力へヘルプを出力

#### validate_version()
- **責務**: バージョン引数の検証（vX.X.X形式）
- **依存**: なし
- **公開インターフェース**: 戻り値 0=有効, 1=無効

#### create_directory()
- **責務**: 単一ディレクトリの作成
- **依存**: mkdir -p
- **公開インターフェース**: 結果を標準出力に出力

#### init_history_file()
- **責務**: history/inception.mdの初期化
- **依存**: date, cat
- **公開インターフェース**: ファイル作成

#### main()
- **責務**: 引数解析、処理フローの制御
- **依存**: 上記すべての関数
- **公開インターフェース**: 終了コード

## インターフェース設計

### コマンドインターフェース

```text
init-cycle-dir.sh <VERSION> [OPTIONS]
```

#### 引数

| 引数 | 必須 | 説明 |
|------|------|------|
| VERSION | Yes | サイクルバージョン（vX.X.X形式） |

#### オプション

| オプション | 説明 |
|----------|------|
| -h, --help | ヘルプを表示 |
| --dry-run | 実際に作成せず、作成予定を表示 |

### 出力形式（stdout）

```text
dir:<パス>:<状態>
file:<パス>:<状態>
```

| 状態 | 説明 |
|------|------|
| created | 新規作成 |
| exists | 既存（スキップ） |
| would-create | 作成予定（--dry-runモード） |
| error | 作成失敗（詳細はstderrへ） |

### エラー出力（stderr）

```text
[error] <対象>: <エラー詳細>
```

init-labels.shと同様の形式を採用。エラー発生時はこの形式でstderrに出力する。

### 終了コード

| コード | 説明 |
|--------|------|
| 0 | 正常終了 |
| 1 | 引数エラー（バージョン未指定/形式不正） |
| 2 | 作成エラー（一部失敗） |

## 処理フロー概要

### メイン処理フロー

**ステップ**:
1. 引数解析（--help, --dry-run, VERSION）
2. バージョン形式を検証
3. 各ディレクトリを順次作成（10個: plans, requirements, story-artifacts/units, design-artifacts/domain-models, design-artifacts/logical-designs, design-artifacts/architecture, inception, construction/units, operations, history）
4. history/inception.md を初期化
5. エラーカウントに応じて終了コードを決定

**関与するコンポーネント**: main, validate_version, create_directory, init_history_file

### ディレクトリ作成フロー

1. 対象パスが存在するか確認
2. 存在する場合: `exists` を出力してスキップ
3. 存在しない場合:
   - --dry-run: `would-create` を出力
   - 通常: mkdir -p で作成、結果を出力

### --dry-run モードの詳細仕様

- **既存判定**: 実行する（ファイルシステムを読み取り、exists/would-createを正確に出力）
- **ディレクトリ作成**: 実行しない（would-createを出力するのみ）
- **ファイル作成（history/inception.md）**: 実行しない（would-createを出力するのみ）
- **出力形式**: 通常モードと同じ形式で出力（状態のみ異なる）

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 即時完了
- **対応策**: 単純なmkdir -pのみ使用

### セキュリティ
- **要件**: N/A
- **対応策**: なし

### 可用性
- **要件**: オフライン環境でも動作
- **対応策**: 外部依存なし（bash標準コマンドのみ）

## 技術選定
- **言語**: Bash
- **依存コマンド**: mkdir, date, cat
- **配置先**: `prompts/package/bin/init-cycle-dir.sh`（init-labels.shと同じディレクトリ）

## setup.md への統合

### 変更箇所

現在の setup.md（lines 535-571）:

```bash
mkdir -p docs/cycles/{{CYCLE}}/plans
mkdir -p docs/cycles/{{CYCLE}}/requirements
...（10個のmkdir）
```

変更後:

```bash
bin/init-cycle-dir.sh {{CYCLE}}
```

### バックログディレクトリについて

共通バックログディレクトリ（`docs/cycles/backlog/`, `docs/cycles/backlog-completed/`）は本スクリプトの対象外。setup.md内で別途処理を継続する。

## 実装上の注意事項
- history/inception.md の日時は実行時に取得（dateコマンド）
- 既存ディレクトリ・ファイルは上書きしない（冪等性）
- init-labels.sh と同様の出力形式を採用（スクリプト間の一貫性）

## 不明点と質問

（なし）
