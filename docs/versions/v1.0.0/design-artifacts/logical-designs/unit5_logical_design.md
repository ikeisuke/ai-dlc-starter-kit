# 論理設計: Unit5 - 旧構造の削除とバージョン管理

## 概要
Git履歴で保護されていることを確認しながら、旧構造のファイル・ディレクトリを安全に削除し、新構造でのバージョン管理機能を検証する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。具体的なコード（SQL、JSON、実装コード等）はImplementation Phase（コード生成ステップ）で作成します。

## アーキテクチャパターン
**パイプライン処理パターン**を採用。削除前確認 → 削除実行 → 検証という線形のステップを順次実行し、各ステップで安全性を保証する。

選定理由：
- 削除は不可逆的な操作であり、段階的な安全性確認が必須
- 各ステップの責務が明確で、失敗時のロールバック戦略が立てやすい
- 手動作業（Bash操作）が中心のため、シンプルな構成が適切

## コンポーネント構成

### パイプラインステップ構成

```
Unit5 実行パイプライン
├── Phase 1: 設計
│   ├── ドメインモデル設計
│   ├── 論理設計
│   └── 設計レビュー
└── Phase 2: 実装
    ├── 削除前確認（SafetyVerifier）
    ├── 削除実行（FileRemover）
    ├── バージョン管理検証（VersionVerifier）
    ├── 統合レビュー（IntegrationReviewer）
    └── 進捗記録（ProgressRecorder）
```

### コンポーネント詳細

#### SafetyVerifier（削除前確認）
- **責務**: 削除対象ファイルの安全性を検証
- **依存**: GitRepository, FileSystemRepository
- **公開インターフェース**:
  - verifyGitStatus(): void - 未コミット変更の有無を確認
  - verifyFilesMigrated(): void - 削除対象が移行済みか確認
  - verifyInGitHistory(): void - Git履歴に存在するか確認

#### FileRemover（削除実行）
- **責務**: 安全性確認後、ファイル・ディレクトリを削除
- **依存**: SafetyVerifier, FileSystemRepository
- **公開インターフェース**:
  - deleteFile(path): void - 単一ファイルの削除
  - deleteDirectory(path): void - ディレクトリの再帰的削除
  - verifyDeletion(): void - 削除が正しく反映されているか確認

#### VersionVerifier（バージョン管理検証）
- **責務**: 新構造でのバージョン管理機能を検証
- **依存**: FileSystemRepository
- **公開インターフェース**:
  - verifyVersionFile(): void - version.txtの内容確認
  - verifyDirectoryStructure(): void - 新構造の整合性確認
  - verifyPromptReferences(): void - プロンプトの参照が正しいか確認

#### IntegrationReviewer（統合レビュー）
- **責務**: 削除後の全体的な整合性を確認
- **依存**: FileSystemRepository
- **公開インターフェース**:
  - reviewDirectoryStructure(): void - ディレクトリツリーの確認
  - checkBrokenLinks(): void - リンク切れの確認
  - verifyReadmeAccuracy(): void - README.mdの正確性確認

#### ProgressRecorder（進捗記録）
- **責務**: progress.mdの更新とGitコミット
- **依存**: FileSystemRepository, GitRepository
- **公開インターフェース**:
  - updateProgress(): void - progress.mdのUnit5を完了に更新
  - createGitCommit(): void - すべての変更をコミット

## インターフェース設計

### コマンド（Bash操作）

#### git status
- **パラメータ**: なし
- **戻り値**: Git管理下のファイル状態
- **副作用**: なし（読み取り専用）

#### git log --follow <path>
- **パラメータ**: path: String - 確認対象ファイルパス
- **戻り値**: ファイルのGit履歴
- **副作用**: なし（読み取り専用）

#### rm <file>
- **パラメータ**: file: String - 削除対象ファイル
- **戻り値**: なし
- **副作用**: ファイルシステムからファイルを削除

#### rm -rf <directory>
- **パラメータ**: directory: String - 削除対象ディレクトリ
- **戻り値**: なし
- **副作用**: ディレクトリを再帰的に削除

#### ls -R <directory>
- **パラメータ**: directory: String - 確認対象ディレクトリ
- **戻り値**: ディレクトリツリー
- **副作用**: なし（読み取り専用）

#### cat <file>
- **パラメータ**: file: String - 確認対象ファイル
- **戻り値**: ファイル内容
- **副作用**: なし（読み取り専用）

## データモデル概要

### ファイル形式

#### docs/aidlc/version.txt
- **形式**: プレーンテキスト
- **内容**: バージョン番号（例: "1.0.0"）
- **目的**: 使用中のAI-DLCスターターキットのバージョンを記録

#### docs/versions/v1.0.0/construction/progress.md
- **形式**: Markdown
- **主要フィールド**:
  - Unit一覧テーブル（状態、依存関係、優先度、開始日、完了日）
  - 次回実行可能なUnit候補
  - 最終更新日時

## 処理フロー概要

### 削除前確認の処理フロー

**ステップ**:
1. `git status` で未コミット変更を確認
2. 削除対象ファイル（`docs/v1.0.0-intent.md`, `docs/example/`）の存在確認
3. 各ファイルについて `git log --follow` で履歴を確認
4. 移行先ファイル（`docs/versions/v1.0.0/requirements/intent.md`）の存在確認
5. すべての安全性チェックが通過したら次ステップへ

**関与するコンポーネント**: SafetyVerifier, GitRepository, FileSystemRepository

### 削除実行の処理フロー

**ステップ**:
1. `rm docs/v1.0.0-intent.md` で初期Intentファイルを削除
2. `rm -rf docs/example/` でサンプルディレクトリを削除
3. `git status` で削除が正しく反映されているか確認

**関与するコンポーネント**: FileRemover, FileSystemRepository, GitRepository

### バージョン管理検証の処理フロー

**ステップ**:
1. `cat docs/aidlc/version.txt` でバージョン確認（"1.0.0"であること）
2. `ls -R docs/` で新構造が正しく存在するか確認
3. プロンプトファイル（common.md, inception.md等）で参照パスを確認
4. すべての検証が通過したら次ステップへ

**関与するコンポーネント**: VersionVerifier, FileSystemRepository

### 統合レビューの処理フロー

**ステップ**:
1. `ls -R docs/` でディレクトリ構造全体を確認
2. README.mdを読み込み、記載されたディレクトリ構造と実際の構造を比較
3. プロンプトファイル内のパス参照を確認（リンク切れチェック）
4. 問題がなければ実装記録を作成

**関与するコンポーネント**: IntegrationReviewer, FileSystemRepository

### 進捗記録とコミットの処理フロー

**ステップ**:
1. `progress.md` を読み込み
2. Unit5の状態を「完了」に変更、完了日を記録
3. 次回実行可能なUnit候補を更新（全Unit完了）
4. `git add` で変更をステージング（削除含む）
5. `git commit` でコミット作成

**関与するコンポーネント**: ProgressRecorder, FileSystemRepository, GitRepository

## 非機能要件（NFR）への対応

### 安全性
- **要件**: 削除は不可逆的な操作であり、誤削除を防ぐ
- **対応策**:
  - 削除前にGit履歴で保護されていることを必ず確認
  - 移行先ファイルの存在を確認
  - ユーザーに削除対象を明示し、承認を得る

### 可逆性
- **要件**: 削除後も旧構造を復元できる
- **対応策**: Git履歴からいつでも復元可能（`git checkout <commit> -- <path>`）

### 整合性
- **要件**: 削除後のディレクトリ構造が設計通り
- **対応策**:
  - 削除後にディレクトリ構造全体を確認
  - README.mdとの整合性を検証
  - リンク切れチェック

### ドキュメント性
- **要件**: 削除理由と新構造への移行を記録
- **対応策**: 実装記録に削除理由、移行先、検証結果を詳細に記載

## 技術選定
- **言語**: Bash（ファイル操作）、Markdown（ドキュメント）
- **バージョン管理**: Git
- **ファイルシステム**: macOS/Linux標準コマンド（rm, ls, cat等）

## 実装上の注意事項
- **削除の不可逆性**: `rm` コマンドは不可逆的なため、実行前に必ず二重確認
- **Git履歴の重要性**: 削除前に `git log --follow` で履歴を確認し、Git管理下であることを保証
- **パス参照の正確性**: プロンプトファイル内のパス参照が正しいか、実際にファイルが存在するか確認
- **progress.mdの整合性**: Unit5完了後、全Unitが完了状態になることを確認

## 不明点と質問（設計中に記録）

特に不明点はありません。削除対象が明確で、安全性確認の手順も定義されています。
