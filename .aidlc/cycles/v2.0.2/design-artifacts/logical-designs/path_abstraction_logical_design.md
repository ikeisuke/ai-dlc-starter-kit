# 論理設計: パス参照の抽象化

## 概要

物理パス `docs/aidlc/` の直接参照を抽象化するための、設定・スクリプト・ステップファイルの変更設計を定義する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

**設定駆動パス解決（Configuration-Driven Path Resolution）**

パス情報を設定ファイルに集約し、各層（スクリプト、ステップファイル）がそれぞれの解決メカニズムで参照する。共有ライブラリ `lib/toml-reader.sh` でTOML解析ロジックを一元化し、bootstrap層とpreflight層が同一の4階層カスケード優先順位で解決する。

## コンポーネント構成

### レイヤー構成

```text
共有ライブラリ層 (Shared Library)
└── lib/toml-reader.sh     dasel v2/v3 互換のTOML値取得関数

設定層 (Configuration)
├── defaults.toml          [paths].aidlc_dir のデフォルト値
├── ~/.aidlc/config.toml   ホーム設定（オプション）
├── config.toml            [paths].aidlc_dir のプロジェクト値
└── config.local.toml      [paths].aidlc_dir のローカルオーバーライド

解決層 (Resolution)
├── bootstrap.sh           AIDLC_DOCS_DIR 環境変数の供給（toml-reader.sh + 4階層カスケード）
├── read-config.sh         汎用設定値取得（toml-reader.sh + 4階層カスケード）
└── preflight.md           aidlc_dir コンテキスト変数の供給（read-config.sh経由）

消費層 (Consumption)
├── scripts/*.sh           ${AIDLC_DOCS_DIR} を参照
└── steps/**/*.md          {{aidlc_dir}} プレースホルダーを参照
```

### コンポーネント詳細

#### lib/toml-reader.sh（新規）

- **責務**: dasel v2/v3 互換のTOML値取得関数を提供する共有ライブラリ
- **公開関数**:
  - `aidlc_read_toml(file, key)` - 指定ファイルから指定キーの値を取得
  - `aidlc_detect_dasel_version()` - dasel バージョン検出（v2/v3 ブラケット記法判定）
- **依存**: dasel（任意。不在時は終了コード2）
- **制約**: bootstrap.sh に依存しない。状態を持たない純粋関数群

#### defaults.toml（変更）

- **責務**: `paths.aidlc_dir` のデフォルト値を提供
- **変更内容**: `[paths]` セクションに `aidlc_dir = "docs/aidlc"` を追加
- **依存**: なし

#### bootstrap.sh（変更）

- **責務**: `AIDLC_DOCS_DIR` 環境変数の供給
- **変更内容**: `lib/toml-reader.sh` を source し、4階層カスケードで `paths.aidlc_dir` を解決
- **解決順序（read-config.sh と同一）**: local > project > home > defaults
- **依存**: `lib/toml-reader.sh`（bootstrap.sh に依存しない共有ライブラリ）
- **公開インターフェース**: `AIDLC_DOCS_DIR` 環境変数（exported）

#### read-config.sh（リファクタリング）

- **責務**: 汎用設定値取得（既存の4階層マージ対応）
- **変更内容**: dasel v2/v3 互換ロジックを `lib/toml-reader.sh` の `aidlc_read_toml()` に委譲
- **依存**: `lib/bootstrap.sh`（パス定数）、`lib/toml-reader.sh`（TOML解析）

#### preflight.md（変更）

- **責務**: AIエージェントのコンテキスト変数 `aidlc_dir` の供給
- **変更内容**: ステップ4の `read-config.sh --keys` バッチに `paths.aidlc_dir` を追加
- **依存**: `read-config.sh`

#### check-setup-type.sh（変更）

- **責務**: セットアップ種別の判定
- **変更内容**: `PROJECT_TOML="docs/aidlc/project.toml"` を `PROJECT_TOML="${AIDLC_DOCS_DIR}/project.toml"` に置換
- **依存**: `bootstrap.sh`（`AIDLC_DOCS_DIR`）

#### migrate-config.sh（変更）

- **責務**: 設定ファイルの移行
- **変更内容**: エラーメッセージ内の `docs/aidlc/` 参照を `${AIDLC_DOCS_DIR}` に置換
- **依存**: `bootstrap.sh`（`AIDLC_DOCS_DIR`）

## スクリプトインターフェース設計

### lib/toml-reader.sh（新規）

#### 概要

dasel v2/v3 互換のTOML値取得共有ライブラリ。bootstrap.sh と read-config.sh の両方から利用可能。

#### 公開関数

##### aidlc_detect_dasel_version()

- **引数**: なし
- **出力**: グローバル変数 `_AIDLC_DASEL_BRACKET` を設定（`"true"` = v3 ブラケット記法、`"false"` = v2 ドット記法）
- **終了コード**: 0=dasel利用可能、2=dasel未インストール

##### aidlc_read_toml(file, key)

- **引数**:
  - `$1` (file): TOMLファイルパス
  - `$2` (key): ドット区切りキー（例: `paths.aidlc_dir`）
- **出力**: stdout に値を出力（クォート除去済み）
- **終了コード**: 0=値取得成功、1=キー不在、2=ファイル不在またはdaselエラー

### bootstrap.sh（追加部分）

#### 追加される環境変数

| 変数名 | 説明 | 解決方法 |
|--------|------|---------|
| `AIDLC_DOCS_DIR` | ドキュメントディレクトリの絶対パス | toml-reader.sh + 4階層カスケードで `paths.aidlc_dir` を取得、`AIDLC_PROJECT_ROOT` と結合 |

#### 解決ロジック（4階層カスケード）

1. `lib/toml-reader.sh` を source
2. 以下の順で `aidlc_read_toml(file, "paths.aidlc_dir")` を実行:
   a. `AIDLC_LOCAL_CONFIG`（最優先）
   b. `AIDLC_CONFIG`
   c. `~/.aidlc/config.toml`
   d. `AIDLC_DEFAULTS`（最低優先）
3. 最初に値が取得できた時点で解決完了
4. 全階層で取得失敗: ハードコードフォールバック `"docs/aidlc"`（stderr に警告出力）
5. 結果を `${AIDLC_PROJECT_ROOT}/${取得値}` として `AIDLC_DOCS_DIR` にexport

#### エラー時出力

```text
warn:aidlc-docs-dir-fallback:docs/aidlc
```

- 終了コード: フォールバック使用時も正常終了（bootstrap は初期化のため中断しない）
- 出力先: stderr

### preflight.md（ステップ4 設定値取得への追加）

#### 追加キー

`read-config.sh --keys` のバッチに以下を追加:

| 設定キー | コンテキスト変数名 | デフォルト値 |
|---------|-------------------|------------|
| `paths.aidlc_dir` | `aidlc_dir` | `docs/aidlc` |

#### プリフライトチェック結果への追加

「主要設定値」セクションに `aidlc_dir: {value}` を追加表示。

## データモデル概要

### ファイル形式: defaults.toml（追加部分）

```toml
[paths]
aidlc_dir = "docs/aidlc"
```

### ステップファイルのプレースホルダー解決契約

| 項目 | 仕様 |
|------|------|
| **プレースホルダー表記** | `{{aidlc_dir}}` |
| **解決実行点** | AIエージェントがステップファイルの内容を解釈する時点（`{{CYCLE}}` と同一タイミング） |
| **入力** | 生Markdown テキスト + コンテキスト変数マップ |
| **出力** | プレースホルダー解決済み Markdown テキスト |
| **コンテキスト変数の供給元** | プリフライトチェック ステップ4（`read-config.sh` 経由） |
| **未解決時（変数未設定）** | デフォルト値 `"docs/aidlc"` で解決（defaults.toml の値と一致） |
| **未知プレースホルダー** | そのまま残す（既存動作と同一） |
| **preflight 非依存性** | `read-config.sh` 単体でも `defaults.toml` から値が取得可能。preflight は効率化手段 |

### 例外管理コメント規約

```html
<!-- AIDLC-PATH: physical-path-required (reason: rsync-target) -->
<!-- AIDLC-PATH: physical-path-required (reason: v1-migration) -->
<!-- AIDLC-PATH: physical-path-required (reason: git-add) -->
```

## 処理フロー概要

### スクリプト実行時のパス解決フロー

1. スクリプトが `source lib/bootstrap.sh` を実行
2. bootstrap.sh が `source lib/toml-reader.sh` を実行
3. bootstrap.sh が `aidlc_read_toml` で4階層カスケード解決
4. `AIDLC_DOCS_DIR` が環境変数として設定される
5. スクリプトが `${AIDLC_DOCS_DIR}` を使ってパスを構築

### AIエージェント実行時のパス解決フロー

1. プリフライトチェック（ステップ4）で `read-config.sh` が `paths.aidlc_dir` を取得（`read-config.sh` も内部で `lib/toml-reader.sh` を利用）
2. AIエージェントが `aidlc_dir` コンテキスト変数に格納
3. ステップファイル読み込み時に `{{aidlc_dir}}` を変数値で置換
4. 置換後のパスでガイド等を参照

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: パス解決のオーバーヘッドが体感可能でないこと
- **対応策**: bootstrap.sh での dasel 呼び出しは最大4回（4階層分。最初にヒットすれば1回）。プリフライトチェックでは既存の `--keys` バッチに1キー追加するだけ

### スケーラビリティ

- **要件**: 将来のディレクトリ構造変更時に `[paths]` の値変更のみで対応可能
- **対応策**: 全パス参照が設定経由になるため、config.toml の `[paths].aidlc_dir` 値変更のみで追従可能

## 技術選定

- **言語**: Bash（既存スクリプトと同一）
- **ツール**: dasel（既存依存、TOML パース用）
- **フレームワーク**: N/A

## 実装上の注意事項

- bootstrap.sh は `read-config.sh` を **絶対に呼ばない**（循環依存防止）。`lib/toml-reader.sh` のみ利用
- `lib/toml-reader.sh` は bootstrap.sh に依存しない（ファイルパスは引数で受け取る）
- read-config.sh のリファクタリングは dasel 互換ロジックの委譲のみ。既存の API（引数、終了コード、出力形式）は変更しない
- ステップファイルの置換は `skills/aidlc/steps/` のみ対象（`prompts/` はスコープ外）
- setup フェーズの rsync 同期先は物理パスを維持（例外コメント付与）

## ガイド照合結果

- `docs/aidlc/guides/exit-code-convention.md`: bootstrap.sh のフォールバック時に正常終了（exit 0）する設計は規約に準拠（初期化層は中断しない）。toml-reader.sh の終了コード（0/1/2）も規約に準拠
- `docs/aidlc/guides/config-merge.md`: defaults.toml への `[paths]` 追加は既存マージ仕様に準拠。bootstrap層の4階層カスケードも同一優先順位

## AIレビュー対応

Codex 設計レビュー（セッション: 019d3000-47a0-7753-8563-e06b57ce6f44）の指摘3件に対応:

1. **高: 解決順序の不一致** → `lib/toml-reader.sh` を新設し、bootstrap層も4階層カスケード（local > project > home > defaults）で解決するよう統一
2. **中: PlaceholderResolver の契約不明確** → 「ステップファイルのプレースホルダー解決契約」テーブルを追加し、解決実行点・入出力・未解決時挙動を明文化
3. **低: dasel互換ロジックの重複** → `lib/toml-reader.sh` に共通化し、bootstrap.sh と read-config.sh の両方が同一関数を利用

## 不明点と質問（設計中に記録）

なし（計画フェーズおよびレビュー指摘で解決済み）
