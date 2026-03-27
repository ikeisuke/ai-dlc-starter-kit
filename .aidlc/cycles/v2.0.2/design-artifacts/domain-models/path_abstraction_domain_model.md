# ドメインモデル: パス参照の抽象化

## 概要

AI-DLCスターターキットにおけるパス参照の抽象化レイヤーを定義する。物理パス直接参照を論理名に置き換え、パス解決を一元化するドメインモデル。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### PathConfig

設定ファイルから取得されるパス情報の集合。

- **属性**:
  - `aidlc_dir`: String - ドキュメントディレクトリの相対パス（デフォルト: `"docs/aidlc"`）
  - `cycles_dir`: String - サイクルデータディレクトリの相対パス（デフォルト: `".aidlc/cycles"`）
  - `setup_prompt`: String - セットアッププロンプトの相対パス
- **不変性**: 設定ファイルの読み込み時に確定し、セッション中は変更されない
- **等価性**: 各属性値の一致で判定

### ResolvedPath

プロジェクトルートからの絶対パスに解決されたパス。

- **属性**:
  - `absolute_path`: String - 解決済み絶対パス
  - `source_key`: String - 解決元の設定キー（例: `paths.aidlc_dir`）
- **不変性**: 解決後は変更不可
- **等価性**: `absolute_path` の一致で判定

## ドメインサービス

### TomlReader（共有ライブラリ層）

dasel によるTOML値取得の共通インターフェース。`lib/toml-reader.sh` として提供。

- **責務**: dasel v2/v3 互換のTOML値取得関数を提供する
- **操作**:
  - `aidlc_read_toml(file, key)` - 指定ファイルの指定キーから値を取得する。dasel v2/v3 のブラケット記法差異を吸収
- **戻り値**: 値が取得できた場合はその値（クォート除去済み）、取得失敗時は空文字列（終了コード1）
- **制約**: bootstrap.sh に依存しない（bootstrap.sh からも read-config.sh からも利用可能）

### PathResolver（bootstrap層）

シェルスクリプト実行時のパス解決サービス。`bootstrap.sh` 内で動作する。

- **責務**: config.toml の `[paths]` セクションから `AIDLC_DOCS_DIR` を解決し、環境変数として提供する
- **操作**:
  - `resolve_docs_dir()` - `aidlc_read_toml` を使って4階層カスケード（defaults → home → project → local）で `paths.aidlc_dir` を解決し、`AIDLC_PROJECT_ROOT` と結合して絶対パスを返す
- **解決順序**: `read-config.sh` と同一の優先順位（local > project > home > defaults）
- **フォールバック**: 全階層で取得失敗時は `"docs/aidlc"` を使用
- **制約**: `read-config.sh` を呼ばない（循環依存防止）。`lib/toml-reader.sh` のみ利用

### ContextVariableProvider（プリフライト層）

AIエージェント実行時のコンテキスト変数提供サービス。`preflight.md` のフローで動作する。

- **責務**: `read-config.sh` 経由で `paths.aidlc_dir` を取得し、AIエージェントのコンテキスト変数 `aidlc_dir` に格納する
- **操作**:
  - `provide_aidlc_dir()` - `read-config.sh paths.aidlc_dir` を実行し、値を返す
- **フォールバック**: `defaults.toml` のデフォルト値（`"docs/aidlc"`）

### PlaceholderResolver（ステップ読み込み層）

AIエージェントがステップファイルを読み込む際のテンプレート変数解決。

- **責務**: ステップファイル内の `{{aidlc_dir}}` をコンテキスト変数 `aidlc_dir` の値で置換する
- **解決契約**:
  - **解決実行点**: AIエージェントがステップファイルの内容を解釈する時点（既存の `{{CYCLE}}` と同じタイミング）
  - **入力**: 生Markdown テキスト + コンテキスト変数マップ
  - **出力**: プレースホルダー解決済み Markdown テキスト
  - **未解決時の挙動**: `aidlc_dir` コンテキスト変数が未設定の場合、AIエージェントは `"docs/aidlc"`（デフォルト値）で解決する。未知のプレースホルダー（`{{unknown}}` 等）はそのまま残す（既存動作と同一）
- **操作**: AIエージェントの既存テンプレート変数解決メカニズムを利用

## ドメインモデル図

```mermaid
graph TD
    T[lib/toml-reader.sh<br/>aidlc_read_toml] --> B
    T --> R[read-config.sh]
    A[config.toml<br/>paths.aidlc_dir] --> B[PathResolver<br/>bootstrap.sh]
    A --> R
    D[defaults.toml<br/>paths.aidlc_dir] --> B
    D --> R
    B --> E[AIDLC_DOCS_DIR<br/>環境変数]
    R --> C[ContextVariableProvider<br/>preflight.md]
    C --> F[aidlc_dir<br/>コンテキスト変数]
    E --> G[シェルスクリプト]
    F --> H[PlaceholderResolver<br/>{{aidlc_dir}} → 解決済みパス]
    H --> I[ステップファイル]
```

## ユビキタス言語

- **物理パス**: ファイルシステム上の具体的なディレクトリパス（例: `docs/aidlc/`）
- **論理パス**: 設定キー経由で解決される抽象的なパス参照（例: `{{aidlc_dir}}`）
- **パス解決**: 論理パスから物理パスへの変換プロセス
- **4階層カスケード**: defaults → home → project → local の優先順位で設定値を解決する仕組み
- **bootstrap層**: シェルスクリプトの初期化フェーズ。`lib/bootstrap.sh` で提供
- **プリフライト層**: AIエージェントのフェーズ開始時チェック。コンテキスト変数を供給
- **ステップ読み込み層**: AIエージェントがMarkdownステップファイルを解釈する際のテンプレート解決

## 不明点と質問（設計中に記録）

なし（計画フェーズおよびレビュー指摘で解決済み）
