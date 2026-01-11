# ドメインモデル: セットアッププロンプトパス記録

## 概要

スターターキットセットアップ時に使用したプロンプトのパスを、環境に依存しない形式で記録し、Operations Phase完了時に参照できるようにする。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### SetupPromptPath

セットアッププロンプトファイルへのパスを表す値オブジェクト。

- **属性**:
  - `value`: String - パス文字列
  - `format`: PathFormat - パス形式（RelativePath / GhqPath）
- **不変性**: パスは一度記録されたら変更されない
- **等価性**: `value` と `format` の組み合わせで判定

### PathFormat（列挙型）

パス形式を表す列挙型。

- **RelativePath**: 同一リポジトリ内の相対パス
  - 例: `prompts/setup-prompt.md`
- **GhqPath**: ghq管理下のリポジトリパス
  - 形式: `ghq:{host}/{owner}/{repo}/{path}`
  - 例: `ghq:github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md`
- **AbsolutePath**: 絶対パス（フォールバック）
  - 例: `/home/user/custom/setup-prompt.md`
  - 環境依存のため非推奨だが、ghq未使用環境でのフォールバックとして許容

## ドメインサービス

### PathFormatDetector

セットアッププロンプトのパス形式を検出するサービス。

- **責務**: 実行環境からパス形式を判定し、適切な形式に変換
- **操作**:
  - `detect(promptFilePath, projectRoot)` → SetupPromptPath
    - promptFilePath: セットアッププロンプトの絶対パス
    - projectRoot: プロジェクトルートの絶対パス
    - 戻り値: 適切な形式のSetupPromptPath

**判定ロジック**:
1. promptFilePathがprojectRoot配下にあるか確認
2. 配下にある場合: RelativePath形式で返却
3. 配下にない場合:
   - `ghq root` を取得
   - ghq root配下にある場合: GhqPath形式で返却
   - ghq root配下にない場合: 絶対パスをそのまま記録（フォールバック）

### PathResolver

記録されたパスを実際のファイルパスに解決するサービス。

- **責務**: SetupPromptPathから実際のファイルパスを取得
- **操作**:
  - `resolve(setupPromptPath, projectRoot)` → String (絶対パス)

**解決ロジック**:
1. format = RelativePath の場合: `{projectRoot}/{value}` を返却
2. format = GhqPath の場合: `$(ghq root)/{value without 'ghq:' prefix}` を返却
3. それ以外: value をそのまま返却（絶対パスとみなす）

## ユビキタス言語

- **セットアッププロンプト**: AI-DLCスターターキットの初期設定を行うプロンプトファイル
- **ghq**: Goで書かれたリポジトリ管理ツール。`ghq root` でリポジトリのルートディレクトリを取得可能
- **ghq形式パス**: `ghq:{host}/{owner}/{repo}/{path}` 形式のパス表現。環境に依存しない
- **相対パス**: プロジェクトルートからの相対パス

## 不明点と質問（設計中に記録）

（なし - 計画段階で確認済み）
