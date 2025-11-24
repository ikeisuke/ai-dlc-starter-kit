# 論理設計: Unit3 - 新しいディレクトリ構造の作成

## 概要
共通リソース（プロンプト・テンプレート）とバージョン固有成果物を適切に分離するディレクトリ構造を作成し、スケーラブルなAI-DLCプロジェクト基盤を構築する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なBashスクリプトはImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン
**スクリプトベースのファイルシステム操作アーキテクチャ**

- Bashスクリプトによるディレクトリ作成とファイル配置
- 冪等性を保証する設計（`mkdir -p` による既存ディレクトリの保護）
- エラーハンドリングを含む堅牢な実装

選定理由：
- シンプルで保守性が高い
- Gitと統合しやすい
- すべての環境で実行可能

## コンポーネント構成

### レイヤー / モジュール構成

```
DirectoryCreationScript
├── VariableDefinition（変数定義）
│   ├── PathVariables
│   └── VersionVariable
├── DirectoryCreation（ディレクトリ作成）
│   ├── AidlcDirectoryCreator
│   └── VersionDirectoryCreator
├── FileGeneration（ファイル生成）
│   ├── GitKeepGenerator
│   └── VersionFileGenerator
└── Validation（検証）
    ├── DirectoryValidator
    └── ErrorHandler
```

### コンポーネント詳細

#### VariableDefinition（変数定義）
- **責務**: 必要なパス変数を定義し、スクリプト全体で使用可能にする
- **依存**: なし
- **公開インターフェース**:
  - `AIDLC_ROOT`: 共通リソースのルートパス（`docs/aidlc`）
  - `VERSIONS_ROOT`: バージョン固有成果物のルートパス（`docs/versions`）
  - `VERSION`: 対象バージョン（`v1.0.0`）

#### AidlcDirectoryCreator（共通ディレクトリ作成）
- **責務**: `docs/aidlc/` 配下の共通ディレクトリを作成
- **依存**: VariableDefinition
- **公開インターフェース**:
  - `createPromptsDirectory()`: `docs/aidlc/prompts/` を作成
  - `createTemplatesDirectory()`: `docs/aidlc/templates/` を作成

#### VersionDirectoryCreator（バージョン固有ディレクトリ作成）
- **責務**: `docs/versions/v1.0.0/` 配下のバージョン固有ディレクトリを作成
- **依存**: VariableDefinition
- **公開インターフェース**:
  - `createPlansDirectory()`: `plans/` を作成
  - `createRequirementsDirectory()`: `requirements/` を作成
  - `createStoryArtifactsDirectory()`: `story-artifacts/units/` を作成
  - `createDesignArtifactsDirectory()`: `design-artifacts/` 配下を作成
  - `createConstructionDirectory()`: `construction/units/` を作成
  - `createOperationsDirectory()`: `operations/` を作成

#### GitKeepGenerator（.gitkeep生成）
- **責務**: 空ディレクトリに .gitkeep ファイルを配置
- **依存**: AidlcDirectoryCreator、VersionDirectoryCreator
- **公開インターフェース**:
  - `generateGitKeepFiles(directories)`: 指定されたディレクトリに .gitkeep を配置

#### VersionFileGenerator（バージョンファイル生成）
- **責務**: `docs/aidlc/version.txt` を作成し、現在のバージョンを記録
- **依存**: VariableDefinition
- **公開インターフェース**:
  - `generateVersionFile(version)`: バージョン番号をファイルに書き込む

#### DirectoryValidator（ディレクトリ検証）
- **責務**: ディレクトリ作成後に正しく作成されたことを検証
- **依存**: すべてのCreator
- **公開インターフェース**:
  - `validateDirectoryStructure()`: 全ディレクトリの存在を確認
  - `validateVersionFile()`: version.txt の内容を確認

#### ErrorHandler（エラーハンドリング）
- **責務**: エラー発生時の適切な処理とユーザーへのメッセージ表示
- **依存**: すべてのコンポーネント
- **公開インターフェース**:
  - `handleDirectoryCreationError(path, error)`: ディレクトリ作成エラーを処理
  - `handleFileCreationError(path, error)`: ファイル作成エラーを処理

## インターフェース設計

### Bashスクリプトインターフェース

このUnitでは、Bashコマンドによるファイルシステム操作を行います。

#### ディレクトリ作成コマンド
- **コマンド**: `mkdir -p <path>`
- **説明**: ディレクトリを再帰的に作成（既存の場合はエラーなし）
- **パラメータ**: `<path>` - 作成するディレクトリのパス
- **戻り値**: 成功時は0、失敗時は非0
- **エラー**: 権限不足、ディスク容量不足等

#### ファイル作成コマンド
- **コマンド**: `touch <file>` または `echo "<content>" > <file>`
- **説明**: 空ファイルまたは内容を持つファイルを作成
- **パラメータ**: `<file>` - 作成するファイルのパス、`<content>` - ファイルの内容
- **戻り値**: 成功時は0、失敗時は非0
- **エラー**: 権限不足、ディスク容量不足等

#### ディレクトリ検証コマンド
- **コマンド**: `test -d <path>` または `[ -d <path> ]`
- **説明**: ディレクトリが存在するか確認
- **パラメータ**: `<path>` - 確認するディレクトリのパス
- **戻り値**: 存在する場合は0、存在しない場合は1

#### ファイル検証コマンド
- **コマンド**: `test -f <file>` または `[ -f <file> ]`
- **説明**: ファイルが存在するか確認
- **パラメータ**: `<file>` - 確認するファイルのパス
- **戻り値**: 存在する場合は0、存在しない場合は1

## データモデル概要

### ディレクトリ構造データ

#### 共通ディレクトリ（docs/aidlc/）

```
docs/aidlc/
├── prompts/
│   └── .gitkeep
├── templates/
│   └── .gitkeep
└── version.txt
```

- **prompts/**: 共通プロンプトファイル用（inception.md, construction.md, operations.md, additional-rules.md）
- **templates/**: 共通テンプレートファイル用（11種類のテンプレート + index.md）
- **version.txt**: スターターキットのバージョン情報（内容: "v1.0.0"）

#### バージョン固有ディレクトリ（docs/versions/v1.0.0/）

```
docs/versions/v1.0.0/
├── plans/
│   └── .gitkeep
├── requirements/
│   └── .gitkeep
├── story-artifacts/
│   └── units/
│       └── .gitkeep
├── design-artifacts/
│   ├── domain-models/
│   │   └── .gitkeep
│   ├── logical-designs/
│   │   └── .gitkeep
│   └── architecture/
│       └── .gitkeep
├── construction/
│   └── units/
│       └── .gitkeep
└── operations/
    └── .gitkeep
```

**注**: 既存のディレクトリは保持され、存在しないディレクトリのみが作成されます。

### バージョンファイルフォーマット

**ファイル**: `docs/aidlc/version.txt`

**内容**:
```
v1.0.0
```

**説明**:
- 1行のみ、バージョン番号を記録
- semver形式（vX.Y.Z）

## 処理フロー概要

### ユースケース1: 新しいディレクトリ構造の作成

**ステップ**:
1. 変数を定義（AIDLC_ROOT、VERSIONS_ROOT、VERSION）
2. 共通ディレクトリを作成（docs/aidlc/prompts/、docs/aidlc/templates/）
3. バージョン固有ディレクトリを作成（docs/versions/v1.0.0/ 配下の全サブディレクトリ）
4. .gitkeep ファイルを配置（空ディレクトリ用）
5. version.txt を作成（docs/aidlc/version.txt）
6. 作成されたディレクトリとファイルを検証
7. エラーがある場合はユーザーに通知

**関与するコンポーネント**:
- VariableDefinition
- AidlcDirectoryCreator
- VersionDirectoryCreator
- GitKeepGenerator
- VersionFileGenerator
- DirectoryValidator
- ErrorHandler

### ユースケース2: 既存ディレクトリの確認と冪等性の保証

**ステップ**:
1. 各ディレクトリ作成前に存在確認（`test -d` コマンド）
2. 既存のディレクトリはスキップ（`mkdir -p` により自動的に処理）
3. 新規作成されたディレクトリのみログに記録
4. 既存のファイルはそのまま保持

**関与するコンポーネント**:
- DirectoryValidator
- ErrorHandler

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: ディレクトリ作成は高速（数秒以内）
- **対応策**:
  - `mkdir -p` による一括作成
  - 不要な確認処理を省略
  - シンプルなBashスクリプトによる高速実行

### セキュリティ
- **要件**: 適切な権限設定、パスインジェクション対策
- **対応策**:
  - パス変数のハードコーディング（ユーザー入力を使用しない）
  - 相対パスではなく、プロジェクトルートからの明示的なパス指定
  - ディレクトリトラバーサル（`../`）の排除

### スケーラビリティ
- **要件**: 新バージョン追加時にも同じ構造を使用可能
- **対応策**:
  - VERSION 変数を変更するだけで新バージョンに対応
  - 共通ディレクトリ（docs/aidlc/）は1つのみ
  - バージョン固有ディレクトリ（docs/versions/{version}/）は複数作成可能

### 可用性
- **要件**: エラーハンドリング、ユーザーへの適切なメッセージ
- **対応策**:
  - 各ステップでエラーチェック
  - エラー発生時は処理を中断し、ユーザーに通知
  - エラーメッセージには具体的な問題と解決策を含める

## 技術選定

- **言語**: Bash
- **コマンド**:
  - `mkdir -p`: ディレクトリ作成
  - `touch`: 空ファイル作成
  - `echo >`: ファイルへの書き込み
  - `test -d` / `test -f`: ディレクトリ/ファイルの存在確認
  - `find`: ディレクトリツリーの表示（検証用）
- **ツール**:
  - Git: バージョン管理
  - tree または find: ディレクトリ構造の表示（検証用）

## 実装上の注意事項

### セキュリティ
- パス変数は信頼できる値のみを使用（ユーザー入力を直接使用しない）
- シェルインジェクション対策として、変数展開時に引用符を使用

### パフォーマンス
- `mkdir -p` は冪等性を保証し、既存ディレクトリでもエラーを発生しないため、事前チェック不要
- 一括作成により、個別のチェックと作成を繰り返すよりも高速

### 保守性・拡張性
- 変数定義を先頭に集約し、変更が容易
- ディレクトリリストを配列で管理し、追加が容易
- コメントを適切に配置し、意図を明確化

### エラーハンドリング
- `set -e`: エラー発生時にスクリプトを即座に終了
- `set -u`: 未定義変数の使用をエラーとする
- エラーメッセージには、問題の箇所と解決策を含める

## ディレクトリ作成順序

1. **共通ディレクトリ作成**:
   - `docs/aidlc/`
   - `docs/aidlc/prompts/`
   - `docs/aidlc/templates/`

2. **バージョン固有ディレクトリ作成**:
   - `docs/versions/`
   - `docs/versions/v1.0.0/`
   - `docs/versions/v1.0.0/plans/`
   - `docs/versions/v1.0.0/requirements/`
   - `docs/versions/v1.0.0/story-artifacts/`
   - `docs/versions/v1.0.0/story-artifacts/units/`
   - `docs/versions/v1.0.0/design-artifacts/`
   - `docs/versions/v1.0.0/design-artifacts/domain-models/`
   - `docs/versions/v1.0.0/design-artifacts/logical-designs/`
   - `docs/versions/v1.0.0/design-artifacts/architecture/`
   - `docs/versions/v1.0.0/construction/`
   - `docs/versions/v1.0.0/construction/units/`
   - `docs/versions/v1.0.0/operations/`

3. **.gitkeep ファイル配置**:
   - `docs/aidlc/prompts/.gitkeep`
   - `docs/aidlc/templates/.gitkeep`
   - 各バージョン固有ディレクトリ内の末端ディレクトリに配置

4. **バージョンファイル作成**:
   - `docs/aidlc/version.txt`

## 検証方法

### ディレクトリ構造の検証
- **コマンド**: `find docs -type d | sort` または `tree docs`
- **期待結果**: 上記の全ディレクトリが表示される

### .gitkeep ファイルの検証
- **コマンド**: `find docs -name ".gitkeep"`
- **期待結果**: 全末端ディレクトリに .gitkeep が存在

### バージョンファイルの検証
- **コマンド**: `cat docs/aidlc/version.txt`
- **期待結果**: `v1.0.0` が表示される

## 不明点と質問（設計中に記録）

[Question]
（設計に関する不明点はすべて対話で解決済み）

[Answer]
（すべて解決済み）
