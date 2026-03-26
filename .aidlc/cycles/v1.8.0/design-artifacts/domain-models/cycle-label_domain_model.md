# ドメインモデル: サイクルラベル操作スクリプト

## 概要

サイクルラベル（cycle:\<version\>）の存在確認と作成を行うCLIスクリプトの設計。
引数で受け取った**単一の**バージョンに対応するラベルの確認・作成を行う。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### CycleVersion

- **属性**: version: String - サイクルバージョン（例: "v1.8.0", "2024.01", "release-1" など）
- **不変性**: 一度生成されたバージョン文字列は変更されない
- **等価性**: 文字列の完全一致で判定
- **バリデーション**: 空文字でないこと（形式の制限はなし）

### LabelName

- **属性**: name: String - ラベル名（例: "cycle:v1.8.0"）
- **生成ロジック**: `cycle:` プレフィックス + CycleVersion
- **不変性**: バージョンから一意に決定される
- **等価性**: 文字列の完全一致で判定

### LabelResult

- **属性**:
  - labelName: LabelName - 対象ラベル名
  - status: ResultStatus - 処理結果
- **ステータス値**:
  - `exists`: ラベルが既に存在
  - `created`: ラベルを新規作成
  - `error`: エラー発生（詳細はstderrへ）

## ドメインサービス

### CycleLabelService

- **責務**: サイクルラベルの存在確認と作成を行う
- **操作**:
  - `checkAndCreate(version)`: バージョンを受け取り、ラベルの確認・作成を実行
  - `checkExists(labelName)`: ラベルの存在確認
  - `create(labelName)`: ラベルの作成

## インフラストラクチャ

### GitHubLabelGateway

- **責務**: GitHub CLI（gh）を介したラベル操作
- **前提条件**:
  - ghコマンドがインストール済み
  - gh auth で認証済み
  - Gitリポジトリ内で実行（カレントディレクトリ）
- **操作**:
  - `listLabels()`: リポジトリの既存ラベル一覧を取得（`--limit 1000`で上限対策）
  - `createLabel(name, color, description)`: ラベルを作成

## 出力形式

**init-labels.shと統一**した形式で標準出力に結果を出力:

```text
label:<label_name>:<status>
```

| status | 説明 |
|--------|------|
| exists | ラベルが既に存在する |
| created | ラベルを新規作成した |
| error | エラー発生（詳細はstderrへ） |

**出力例**:

```text
label:cycle:v1.8.0:exists
label:cycle:v1.8.0:created
label:cycle:v1.8.0:error
```

## エラーケース

| エラー | stdout | stderr | 終了コード |
|--------|--------|--------|-----------|
| 引数不足 | - | error:missing-version | 1 |
| gh未インストール | - | error:gh-not-installed | 1 |
| gh未認証 | - | error:gh-not-authenticated | 1 |
| ラベル一覧取得失敗 | - | error:label-list-failed | 1 |
| ラベル作成失敗 | label:\<name\>:error | [error] \<name\>: \<詳細\> | 2 |

**注**: 環境エラー（引数不足、gh未利用可能）は処理開始前にstderrのみに出力して終了。
ラベル作成失敗時はstdoutにステータス、stderrに詳細を出力。

## ラベル属性

作成するラベルの属性（init-labels.shと同様の形式）:

- **色**: `7057FF`（紫系、サイクルラベルとして識別しやすい色）
- **説明**: `サイクル <version>`

## 既存ラベルの差分対応

既存ラベルが存在するが色/説明が異なる場合:

- **方針**: 無視（existsとして扱う）
- **理由**: ラベル更新は破壊的変更になりうるため、手動対応に委ねる

## ユビキタス言語

このドメインで使用する共通用語:

- **サイクル（Cycle）**: AI-DLCにおける開発の1単位。バージョン番号で識別される
- **サイクルラベル（Cycle Label）**: GitHub上でサイクルを識別するためのラベル。`cycle:<version>` 形式
- **gh**: GitHub公式のコマンドラインツール

## 不明点と質問（設計中に記録）

### AIレビュー指摘への対応

[Question] 出力形式はinit-labels.shと完全一致に寄せるか？
[Answer] はい、統一する（`label:<name>:<status>` + stderrにエラー詳細）

[Question] バージョン形式の制限は？
[Answer] 詳細な制限は不要（vX.X.X以外のサイクル名も許容）
