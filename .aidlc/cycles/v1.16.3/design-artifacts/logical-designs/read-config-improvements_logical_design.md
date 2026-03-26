# 論理設計: read-config.sh 改善

## 概要
read-config.sh の4階層マージロジックを `resolve_key` 関数に抽出し、`--keys` オプションによる複数キー一括取得と key:value 形式出力を実現する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン
既存パターンの拡張（Layered Merge パターン）。トップレベル手続きを関数に抽出し、単一/複数キーの両モードから同一ロジックを呼び出す構成。

## コンポーネント構成

### ファイル構成

```text
prompts/package/
├── bin/
│   └── read-config.sh          # 修正: resolve_key抽出、--keys対応
└── config/
    └── defaults.toml            # 修正: 不足キー追加
```

### コンポーネント詳細

#### ArgumentParser（引数パース部）
- **責務**: コマンドライン引数を解析し、実行モード（single/batch）と対象キーを決定する
- **依存**: なし
- **公開インターフェース**:
  - 結果として以下の変数を設定: `MODE`（single|batch）、`KEY`（単一キー）、`KEYS`（配列）、`DEFAULT_VALUE`、`HAS_DEFAULT`

#### resolve_key 関数
- **責務**: 単一キーの値を4階層マージで解決する。既存のトップレベル手続き（148-247行目）を関数化したもの
- **依存**: `get_value` 関数、`strip_quotes` 関数、設定ファイルパス変数群
- **公開インターフェース**:
  - 引数: key（文字列）
  - 標準出力: 解決された値（存在する場合）
  - 戻り値: 0=存在、1=不在、2=エラー

#### OutputHandler（出力処理部）
- **責務**: 実行モードに応じた出力フォーマットで結果を出力する
- **依存**: `resolve_key` 関数
- **公開インターフェース**:
  - single モード: 値をそのまま出力（従来互換）
  - batch モード: `key:value` 形式で1行1キー出力

## スクリプトインターフェース設計

### read-config.sh

#### 概要
設定値を4階層マージで読み込み、単一または複数キーの値を出力する

#### 引数
| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `<key>` | 条件付き必須 | 単一キー指定（`--keys` と排他） |
| `--default <value>` | 任意 | 単一キーモード時のフォールバック値（`--keys` と排他） |
| `--keys <key1> [key2] ...` | 条件付き必須 | 複数キー一括指定（位置引数・`--default` と排他）。1件以上のキーが必要。`--keys` の後、次の `-*` オプションまたは引数終端までをキーとして読み取る |

#### 成功時出力（単一キーモード）
```text
value
```
- 終了コード: `0`
- 出力先: stdout

#### 成功時出力（一括モード）
```text
key1:value1
key2:value2
```
- 終了コード: `0`（1件以上取得）
- 出力先: stdout
- 存在しないキーの行は出力されない

#### エラー時出力
```text
Error: [エラーメッセージ]
```
- 終了コード: `1`（全キー不在）、`2`（引数エラー/daselエラー等）
- 出力先: stderr

#### 排他エラーの期待メッセージ
| 条件 | エラーメッセージ | 終了コード |
|------|----------------|-----------|
| `--keys` + 位置引数 | `Error: --keys and positional key are mutually exclusive` | 2 |
| `--keys` + `--default` | `Error: --keys and --default are mutually exclusive` | 2 |
| `--keys` 後キー0件 | `Error: --keys requires at least one key` | 2 |
| キーも `--keys` も未指定 | `Error: Key is required`（既存メッセージ） | 2 |

#### 使用コマンド
```bash
# 単一キー（従来互換）
./read-config.sh rules.reviewing.mode
./read-config.sh rules.custom.foo --default "bar"

# 複数キー一括
./read-config.sh --keys rules.reviewing.mode rules.reviewing.tools rules.history.level
```

## 処理フロー概要

### 単一キー取得の処理フロー

**ステップ**:
1. ArgumentParser が引数を解析 → MODE=single, KEY=指定キー
2. `resolve_key(KEY)` を呼び出し
3. 値が存在すれば出力（exit 0）
4. 値が不在なら `--default` 確認 → デフォルト出力（exit 0）またはキー不在（exit 1）

**関与するコンポーネント**: ArgumentParser → resolve_key → stdout

### 複数キー一括取得の処理フロー

**ステップ**:
1. ArgumentParser が引数を解析 → MODE=batch, KEYS=キー配列
2. found_count=0 を初期化
3. KEYS の各キーについて:
   a. `resolve_key(key)` を呼び出し
   b. 値が存在すれば `key:value` をバッファに追加、found_count++
   c. 値が不在ならスキップ
   d. エラー（exit 2）の場合は即座にスクリプト終了（exit 2）
4. バッファ内容を stdout に出力
5. found_count > 0 なら exit 0、そうでなければ exit 1

**関与するコンポーネント**: ArgumentParser → resolve_key（ループ）→ stdout

### resolve_key 関数の内部フロー

**ステップ**:
1. FINAL_VALUE=""、VALUE_EXISTS=false を初期化
2. Layer 0（defaults）: ファイル存在時に get_value → 値あれば更新
3. Layer 1（home）: ファイル存在時に get_value → 値あれば更新
4. Layer 2（project）: get_value → 値あれば更新、エラー時は exit 2
5. Layer 3（local）: ファイル存在時に get_value → 値あれば更新
6. VALUE_EXISTS=true なら strip_quotes(FINAL_VALUE) を出力して return 0
7. VALUE_EXISTS=false なら return 1

## defaults.toml 追加キー定義

### 追加する設定キー

| セクション | キー | デフォルト値 | 説明 | 参照元コンポーネント |
|-----------|------|------------|------|-------------------|
| `[rules.commit]` | `ai_author` | `""` | Co-Authored-By 値（空=自動検出に委譲） | commit-flow.md（検出フロー、ステップ1） |
| `[rules.branch]` | `mode` | `"ask"` | ブランチ作成方式（ask/branch/worktree） | Unit 002 で inception.md ステップ7 に追加予定 |
| `[rules.git]` | `commit_on_unit_complete` | `true` | Unit完了時にコミットするか | construction.md（Unit完了コミット判定）、aidlc.toml.template |
| `[rules.git]` | `commit_on_phase_complete` | `true` | Phase完了時にコミットするか | operations.md（Phase完了コミット判定）、aidlc.toml.template |
| `[rules.documentation]` | `language` | `"日本語"` | ドキュメント記述言語 | 各フェーズプロンプト（出力言語決定）、aidlc.toml.template |

### 配置順序
既存の `[rules.commit]` セクションに `ai_author` を追加。新規セクション `[rules.branch]`, `[rules.git]`, `[rules.documentation]` を末尾に追加。

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: 一括読み取り時、個別呼び出しN回と同等以下の実行時間
- **対応策**: resolve_key 関数内でファイル存在チェックを毎回行うが、dasel呼び出しはキー×レイヤー回で変わらない。プロセス起動オーバーヘッド（N回の bash 起動）を削減する分、一括の方が高速

### セキュリティ
- **要件**: 該当なし
- **対応策**: 入力キーのバリデーションは既存のdaselに委譲

### スケーラビリティ
- **要件**: キー数の増加に対して線形スケール
- **対応策**: O(keys × layers) の線形計算量。各キーの解決は独立

## 技術選定
- **言語**: Bash（既存スクリプトの拡張）
- **依存ツール**: dasel（既存依存、変更なし）

## 実装上の注意事項
- 一時ファイルは現行パターン踏襲（`$$` サフィックス + 都度削除）。resolve_key は逐次処理のため、キーごとの一意化は不要
- `set -e` 環境下での関数呼び出しに注意（既存の `set +e` / `set -e` パターンを踏襲）
- batch モードでは、1つのキーの解決エラー（exit 2）でスクリプト全体を停止する（部分出力を防ぐ）

## 不明点と質問（設計中に記録）

（なし - Unit定義と計画で十分に明確化済み）
