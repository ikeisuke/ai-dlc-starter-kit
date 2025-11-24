# ドメインモデル: Unit1 - setup-prompt.mdのリファクタリング

## 概要
setup-prompt.mdを新しいディレクトリ構造に対応させ、共通プロンプト・テンプレートとバージョン固有成果物を適切に分離する仕組みをDDDの観点から構造化します。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### SetupProcess（セットアッププロセス）
- **ID**: 実行時のタイムスタンプ（各セットアップ実行を一意に識別）
- **属性**:
  - mode: SetupMode（値オブジェクト） - セットアップの実行モード
  - directoryStructure: DirectoryStructure（値オブジェクト） - ディレクトリ構造定義
  - variables: VariableSet（値オブジェクト） - セットアップに使用する変数群
  - executionStatus: ExecutionStatus - 実行状態（未開始/実行中/完了/エラー）
- **振る舞い**:
  - initialize(): ディレクトリ構造を初期化
  - generatePrompts(): プロンプトファイルを生成
  - generateTemplates(): テンプレートファイルを生成
  - recordHistory(): 履歴を記録
  - validate(): 実行前の検証（カレントディレクトリ確認等）

## 値オブジェクト（Value Object）

### SetupMode
- **属性**:
  - value: String（"setup" / "template" / "list"）
- **不変性**: セットアップ実行中にモードは変更されない
- **等価性**: value の文字列が一致すれば等価
- **ビジネスルール**:
  - setup: 完全な初期化を実行
  - template: 指定されたテンプレートのみ生成
  - list: テンプレート一覧を表示

### DirectoryStructure（ディレクトリ構造）
- **属性**:
  - aidlcRoot: String - 共通ファイルのルートパス（例: "docs/aidlc"）
  - versionsRoot: String - バージョン固有ファイルのルートパス（例: "docs/versions"）
  - currentVersion: String - 現在のバージョン（例: "v1.0.0"）
- **不変性**: 一度決定したディレクトリ構造は変更されない
- **等価性**: 全ての属性が一致すれば等価
- **派生値**:
  - commonPromptsPath(): `${aidlcRoot}/prompts/`
  - commonTemplatesPath(): `${aidlcRoot}/templates/`
  - versionPath(): `${versionsRoot}/${currentVersion}/`
  - versionPromptsPath(): `${versionsRoot}/${currentVersion}/prompts/`（存在チェック用）

### VariableSet（変数セット）
- **属性**:
  - docsRoot: String - ドキュメントのルートディレクトリ（ユーザー指定）
  - version: String - セットアップ対象のバージョン
  - projectName: String - プロジェクト名
  - projectType: String - プロジェクトタイプ（ios/android/web/backend/general）
  - language: String - 使用言語
  - その他のプロジェクト固有変数
- **不変性**: セットアップ実行開始後は変更不可
- **等価性**: 全ての変数が一致すれば等価
- **派生値**:
  - aidlcRoot(): `${docsRoot}/aidlc` - 共通ファイルのルート
  - versionsRoot(): `${docsRoot}/versions` - バージョンファイルのルート
  - directoryStructure(): DirectoryStructure を生成

### PromptFile（プロンプトファイル）
- **属性**:
  - name: String - ファイル名（例: "inception.md"）
  - content: String - ファイルの内容
  - location: FileLocation（共通 or バージョン固有）
  - includesCommon: Boolean - common.mdの内容を含むか
- **不変性**: 生成されたファイル内容は変更されない
- **等価性**: name, content, location が一致すれば等価

### TemplateFile（テンプレートファイル）
- **属性**:
  - name: String - テンプレート名（例: "intent_template"）
  - content: String - テンプレート内容
  - phase: Phase（Inception/Construction/Operations）
- **不変性**: 生成されたテンプレート内容は変更されない
- **等価性**: name と content が一致すれば等価

### FileLocation（列挙型）
- **値**: COMMON（共通） / VERSION_SPECIFIC（バージョン固有）

### Phase（列挙型）
- **値**: INCEPTION / CONSTRUCTION / OPERATIONS

## 集約（Aggregate）

### Setup集約
- **集約ルート**: SetupProcess
- **含まれる要素**:
  - SetupMode（値オブジェクト）
  - DirectoryStructure（値オブジェクト）
  - VariableSet（値オブジェクト）
  - 生成されたPromptFileのコレクション
  - 生成されたTemplateFileのコレクション
- **境界**: 1回のセットアップ実行に関するすべての情報
- **不変条件**:
  - MODEがtemplateの場合、TEMPLATE_NAMEが必須
  - ディレクトリ構造の整合性（aidlcRootとversionsRootがdocsRoot配下に存在）
  - 生成されるファイルのパスが既存ファイルと競合しない（上書き確認が必要な場合を除く）

## ドメインサービス

### DirectoryInitializer（ディレクトリ初期化サービス）
- **責務**: ディレクトリ構造を作成する
- **操作**:
  - createCommonDirectories(directoryStructure): 共通ディレクトリを作成（`${aidlcRoot}/prompts/`, `${aidlcRoot}/templates/`）
  - createVersionDirectories(directoryStructure): バージョン固有ディレクトリを作成（`${versionsRoot}/${version}/plans/`, `requirements/`, 等）
  - ensureDirectoryExists(path): ディレクトリの存在を保証（mkdir -p）

### PromptGenerator（プロンプト生成サービス）
- **責務**: プロンプトファイルを生成する
- **操作**:
  - generateCommonPrompts(directoryStructure, variables): 共通プロンプトを生成（inception.md, construction.md, operations.md）
  - mergeCommonContent(promptContent, commonContent): 各フェーズプロンプトにcommon.mdの内容を統合
  - generateAdditionalRules(location): additional-rules.mdを生成（共通 or バージョン固有）
  - generateHistory(directoryStructure): history.mdを生成

### TemplateGenerator（テンプレート生成サービス）
- **責務**: テンプレートファイルをJIT生成する
- **操作**:
  - generateTemplate(templateName, directoryStructure): 指定されたテンプレートを生成
  - generateIndexTemplate(directoryStructure): templates/index.mdを生成
  - checkTemplateExists(templateName, directoryStructure): テンプレートの存在確認

### VariableSubstitutor（変数置換サービス）
- **責務**: ファイル内容の変数を実際の値に置換する
- **操作**:
  - substitute(content, variables): コンテンツ内の{{変数名}}を実際の値に置換
  - validateVariables(variables): 必須変数の存在確認

### PathMigrator（パス移行サービス）
- **責務**: 旧パス形式から新パス形式への移行ロジック
- **操作**:
  - convertOldPathToNew(oldPath, variables): 旧形式のパス（`{{DOCS_ROOT}}/{{VERSION}}/`）を新形式（`{{AIDLC_ROOT}}/` or `{{VERSIONS_ROOT}}/{{VERSION}}/`）に変換
  - determineFileLocation(filePath): ファイルが共通か バージョン固有かを判定

## リポジトリインターフェース

### FileSystemRepository
- **対象集約**: Setup集約
- **操作**:
  - createDirectory(path): ディレクトリを作成
  - writeFile(path, content): ファイルを書き込み
  - fileExists(path): ファイルの存在確認
  - readFile(path): ファイルの読み込み
  - appendToFile(path, content): ファイルに追記（history.md用）

### VersionRepository
- **対象**: バージョン情報
- **操作**:
  - saveVersion(path, version): version.txtにバージョンを保存
  - readVersion(path): version.txtからバージョンを読み込み

## ユビキタス言語

このドメインで使用する共通用語：

- **AIDLC_ROOT**: 共通プロンプト・テンプレートが配置されるルートディレクトリ（`${DOCS_ROOT}/aidlc`）
- **VERSIONS_ROOT**: バージョン固有の成果物が配置されるルートディレクトリ（`${DOCS_ROOT}/versions`）
- **共通プロンプト**: 全バージョンで共有されるプロンプトファイル（inception.md, construction.md, operations.md）
- **バージョン固有成果物**: 各バージョンの実装記録や進捗管理など、バージョンごとに異なる情報
- **JIT生成**: Just-In-Time生成。必要な時に必要なテンプレートのみを生成する仕組み
- **MODE**: セットアップの実行モード（setup/template/list）
- **マージ**: common.mdの内容を各フェーズプロンプトの先頭に含める処理
- **後方互換性**: 既存の`DOCS_ROOT`、`VERSION`変数も引き続き使用可能にする設計

## 不明点と質問（設計中に記録）

[Question] `AIDLC_ROOT`と`VERSIONS_ROOT`の値はどのように決定しますか？
[Answer] `DOCS_ROOT`配下に配置する。`AIDLC_ROOT = ${DOCS_ROOT}/aidlc`、`VERSIONS_ROOT = ${DOCS_ROOT}/versions`とする。
