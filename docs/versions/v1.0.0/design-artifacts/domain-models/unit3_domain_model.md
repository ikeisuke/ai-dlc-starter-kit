# ドメインモデル: Unit3 - 新しいディレクトリ構造の作成

## 1. ドメイン概要

このドメインは、AI-DLCプロジェクトにおける**ディレクトリ構造管理**を担当します。共通リソース（プロンプト・テンプレート）とバージョン固有の成果物を適切に分離し、スケーラブルなプロジェクト構造を実現します。

### コアドメイン
- ディレクトリ構造の設計と作成
- バージョン管理
- ファイル配置戦略

### サブドメイン
- Git管理（.gitkeep配置）
- バージョン情報記録

## 2. エンティティ

### 2.1 ProjectStructure（プロジェクト構造）

**責務**: AI-DLCプロジェクト全体のディレクトリ構造を表現

**属性**:
- `rootPath`: プロジェクトルートパス（例: `/Users/.../ai-dlc-starter-kit`）
- `aidlcDirectory`: 共通リソースディレクトリ（`docs/aidlc/`）
- `versionsDirectory`: バージョン別ディレクトリ（`docs/versions/`）

**振る舞い**:
- `createCommonDirectories()`: 共通ディレクトリ（prompts/、templates/）を作成
- `createVersionSpecificDirectories(version)`: バージョン固有ディレクトリを作成
- `recordVersion(version)`: バージョン情報を記録

**不変条件**:
- `aidlcDirectory` と `versionsDirectory` は並列に存在する
- 共通リソースはバージョンに依存しない

### 2.2 AidlcDirectory（共通リソースディレクトリ）

**責務**: 全バージョンで共有されるプロンプトとテンプレートを管理

**属性**:
- `path`: ディレクトリパス（`docs/aidlc/`）
- `promptsSubdirectory`: プロンプトサブディレクトリ（`prompts/`）
- `templatesSubdirectory`: テンプレートサブディレクトリ（`templates/`）
- `versionFile`: バージョン情報ファイル（`version.txt`）

**振る舞い**:
- `createStructure()`: 全サブディレクトリを作成
- `recordCurrentVersion(version)`: 現在のバージョンをversion.txtに記録

**不変条件**:
- promptsSubdirectory と templatesSubdirectory は必ず存在する
- versionFile は必ず存在し、有効なバージョン番号を含む

### 2.3 VersionDirectory（バージョン固有ディレクトリ）

**責務**: 特定バージョンの成果物を管理

**属性**:
- `version`: バージョン番号（例: v1.0.0）
- `path`: ディレクトリパス（`docs/versions/{version}/`）
- `subdirectories`: サブディレクトリリスト
  - `prompts/`: バージョン固有プロンプト
  - `templates/`: バージョン固有テンプレート
  - `plans/`: 実行計画
  - `requirements/`: 要件定義
  - `story-artifacts/units/`: ユーザーストーリー
  - `design-artifacts/domain-models/`: ドメインモデル
  - `design-artifacts/logical-designs/`: 論理設計
  - `design-artifacts/architecture/`: アーキテクチャ
  - `construction/units/`: 構築記録
  - `operations/`: 運用関連

**振る舞い**:
- `createStructure()`: 全サブディレクトリを作成
- `ensureGitTracking()`: 空ディレクトリに.gitkeepを配置

**不変条件**:
- バージョン番号は semver 形式（vX.Y.Z）
- 全サブディレクトリは階層構造を保つ

## 3. 値オブジェクト

### 3.1 Version（バージョン）

**責務**: バージョン番号を表現し、妥当性を保証

**属性**:
- `major`: メジャーバージョン（例: 1）
- `minor`: マイナーバージョン（例: 0）
- `patch`: パッチバージョン（例: 0）

**振る舞い**:
- `toString()`: 文字列表現を返す（例: "v1.0.0"）
- `isValid()`: バージョン番号の妥当性を検証

**不変条件**:
- major、minor、patch は非負整数
- 文字列表現は "v{major}.{minor}.{patch}" 形式

### 3.2 DirectoryPath（ディレクトリパス）

**責務**: ディレクトリパスを表現し、安全性を保証

**属性**:
- `value`: パス文字列

**振る舞い**:
- `isAbsolute()`: 絶対パスか判定
- `join(relativePath)`: 相対パスを結合
- `exists()`: ディレクトリが存在するか確認

**不変条件**:
- パスにパスインジェクション文字列を含まない
- ディレクトリトラバーサル（`../`）を不正に使用しない

## 4. ドメインサービス

### 4.1 DirectoryStructureCreator（ディレクトリ構造作成サービス）

**責務**: ディレクトリ構造全体を作成する調整役

**振る舞い**:
- `createAidlcStructure()`: `docs/aidlc/` 配下の構造を作成
- `createVersionStructure(version)`: `docs/versions/{version}/` 配下の構造を作成
- `ensureAllDirectoriesExist()`: 全ディレクトリの存在を保証

**依存**:
- ProjectStructure
- AidlcDirectory
- VersionDirectory

### 4.2 GitKeepManager（.gitkeep管理サービス）

**責務**: 空ディレクトリのGit追跡を保証

**振る舞い**:
- `placeGitKeepFiles(directories)`: 指定ディレクトリに.gitkeepを配置
- `isDirectoryEmpty(path)`: ディレクトリが空か判定

**依存**:
- DirectoryPath

### 4.3 VersionRecorder（バージョン記録サービス）

**責務**: バージョン情報をファイルに記録

**振る舞い**:
- `recordVersion(version, filePath)`: バージョン番号をファイルに書き込む
- `readCurrentVersion(filePath)`: 現在のバージョンを読み取る

**依存**:
- Version
- DirectoryPath

## 5. リポジトリインターフェース

### 5.1 FileSystemRepository

**責務**: ファイルシステム操作の抽象化

**メソッド**:
- `createDirectory(path)`: ディレクトリを作成
- `createFile(path, content)`: ファイルを作成
- `directoryExists(path)`: ディレクトリの存在確認
- `isDirectoryEmpty(path)`: ディレクトリが空か判定

**実装**:
- Bashコマンド（`mkdir -p`, `touch`, `ls` 等）を使用

## 6. 集約

### 6.1 ProjectStructure集約

**ルートエンティティ**: ProjectStructure

**含まれるエンティティ**:
- AidlcDirectory
- VersionDirectory (複数)

**境界**:
- プロジェクト構造全体の整合性を保証
- ディレクトリ作成の順序を制御

**不変条件**:
- AidlcDirectoryは1つのみ
- VersionDirectoryは複数存在可能だが、バージョン番号は一意

## 7. ドメインイベント

### 7.1 AidlcStructureCreated（共通構造作成完了）

**発生条件**: `docs/aidlc/` 配下の構造作成完了時

**属性**:
- `timestamp`: 作成日時
- `createdDirectories`: 作成されたディレクトリリスト

### 7.2 VersionStructureCreated（バージョン構造作成完了）

**発生条件**: `docs/versions/{version}/` 配下の構造作成完了時

**属性**:
- `version`: 対象バージョン
- `timestamp`: 作成日時
- `createdDirectories`: 作成されたディレクトリリスト

### 7.3 VersionRecorded（バージョン記録完了）

**発生条件**: `docs/aidlc/version.txt` への記録完了時

**属性**:
- `version`: 記録されたバージョン
- `timestamp`: 記録日時

## 8. ユビキタス言語

| 用語 | 定義 |
|------|------|
| 共通リソース | 全バージョンで共有されるプロンプトとテンプレート |
| バージョン固有成果物 | 特定バージョンに紐づく要件・設計・実装成果物 |
| AIDLC構造 | `docs/aidlc/` 配下のディレクトリ構造 |
| バージョン構造 | `docs/versions/{version}/` 配下のディレクトリ構造 |
| .gitkeep | 空ディレクトリをGitで追跡するためのマーカーファイル |
| バージョン記録 | `docs/aidlc/version.txt` に現在のバージョンを記録すること |

## 9. ドメインルール

1. **共通とバージョンの分離**: 共通リソース（AIDLC構造）とバージョン固有成果物（バージョン構造）は明確に分離される
2. **バージョン一意性**: 各バージョンディレクトリは一意のバージョン番号を持つ
3. **ディレクトリ階層の保持**: サブディレクトリは必ず親ディレクトリ配下に作成される
4. **空ディレクトリの追跡**: Git管理のため、空ディレクトリには.gitkeepを配置する
5. **バージョン記録の必須性**: 新しいバージョン構造を作成した場合、必ず `docs/aidlc/version.txt` を更新する

## 10. 境界づけられたコンテキスト

### コンテキスト名: ディレクトリ構造管理コンテキスト

**責務**: AI-DLCプロジェクトのディレクトリ構造を作成・管理

**上流コンテキスト**: なし

**下流コンテキスト**:
- セットアップコンテキスト（setup-prompt.md）: ディレクトリ構造を使用してファイルを配置
- 構築コンテキスト（Construction Phase）: バージョン構造を使用して成果物を配置

**統合方法**: ファイルシステムを介した統合

## 11. [Question] / [Answer] セクション

[Question]
`docs/versions/v1.0.0/` 配下には既にいくつかのディレクトリが存在しますが、このUnit3では全サブディレクトリを作成する（既存は上書きしない）という理解で正しいでしょうか？

[Answer]
はい、その理解で正しいです。`mkdir -p` を使用して、存在しないディレクトリのみを作成し、既存のディレクトリとそのコンテンツはそのまま保持します。
