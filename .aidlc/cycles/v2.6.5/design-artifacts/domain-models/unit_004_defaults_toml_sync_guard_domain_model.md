# ドメインモデル: Unit 004 defaults.toml 二重 SoT 同期ガード

## ステップ 0: 事前コード読込み

> 適用条件: depth_level != minimal の場合のみ必須。minimal は設計ステップ自体スキップ可のため N/A。

### (a) Read 対象ファイル + 目的

| ファイル | 目的 / 既存実装確認結果 |
|---------|------------------------|
| `bin/check-defaults-sync.sh` | 既存スクリプト。`diff` 行ベース比較。コメント・空行除外。exit 0=`sync:ok` / 1=`sync:mismatch` / 2=`error:not-found` |
| `.github/workflows/pr-check.yml` (line 93 周辺) | 既存 `defaults-sync-check` ジョブ。PR トリガー、`bash bin/check-defaults-sync.sh` を呼ぶ |
| `skills/aidlc/config/defaults.toml` / `skills/aidlc-setup/config/defaults.toml` | 比較対象 2 ファイル。TOML 形式、セクション + key=value 構造 |
| dasel CLI v3 | 既存依存。`-i toml` で TOML パース、`.aliases()` / `-r toml -w json` でキーパス列挙可能 |

### (b) 設計時に意識すべき挙動

- 既存スクリプトはコメント・空行を除外した行ベース diff のため「行順序変更」や「同一キーの値型変更」を構造的に検出できない
- TOML はトップレベル keys / nested table keys を持つ。`dasel` で `.` 区切りキーパスに展開可能
- aidlc-setup 側 defaults.toml は aidlc 側の sync コピーで、`[rules.*]` セクションが共通（一部例外: aidlc-setup ヘッダコメント）
- CI ジョブは PATHS_REGEX で `.toml` 変更時のみ起動。新規 `.toml` 追加でもトリガーされる
- failure contract は machine-readable な形式に固定する（正式契約は本ドメインモデル §3 FailureContract 参照、`in-source` / `in-copy` を区別 + `parse-error` / `tool-missing` を含む拡張版）

### (c) 既存実装に基づく代替案検討

- **採用**: `bin/check-defaults-sync.sh` を `dasel` ベースのキー集合比較に拡張。既存の diff 出力は補助情報として残す
- **却下**: `bin/check-defaults-sync.sh` を完全リライト → 既存 PR テスト群への影響が大きい。後方互換のため exit code / `sync:ok` / `sync:mismatch` 形式は維持
- **却下**: 別ファイル `bin/check-defaults-structure.sh` を新設 → スクリプト分散で SoT 探索コスト増。同一ファイル内で構造比較を追加

## 概要

`skills/aidlc/config/defaults.toml`（正本）と `skills/aidlc-setup/config/defaults.toml`（sync コピー）のキー集合・型一致を構造同値比較で検証する CI ガード。失敗時に machine-readable な failure contract を出力。

## コンポーネント構成（簡素化版 / 集約パターン廃止）

### 1. WorkflowOrchestrator (`.github/workflows/pr-check.yml` の `defaults-sync-check` ジョブ)

- **責務**: PR トリガーで ComparatorScript を起動、exit code から green/red を判定
- **入力**: PR の変更ファイル (PATHS_REGEX で `.toml` 含むかチェック)
- **出力**: GitHub Actions の checks API 経由で PR ステータス通知

### 2. ComparatorScript (`bin/check-defaults-sync.sh`)

- **責務**: 正本 vs コピーの構造比較。キー集合の対称差・型不一致を検出
- **入力**: なし（固定パス参照）
- **出力**: stdout に `sync:ok` または `sync:mismatch` + 差分一覧 + 修復方法、stderr に failure contract

### 3. FailureContract (machine-readable 出力スキーマ / 正式契約)

- **値オブジェクト**: 出力行のフォーマット（正式契約 / `in-source` / `in-copy` を区別）
  - `error:key-missing-in-source:<path>` - コピーにあるが正本にないキー（`<path>` は TOML キーパス、例: `rules.inception.dedup_lookback_cycles`）
  - `error:key-missing-in-copy:<path>` - 正本にあるがコピーにないキー
  - `error:type-mismatch:<path>:<source_type>:<copy_type>` - キーは両方にあるが値型が不一致（型: `int` / `string` / `bool` / `array` / `table` 等）
  - `error:parse-error:<file_path>:<message>` - TOML パース失敗（dasel 実行エラー / 不正な TOML 構文 等）
  - `error:tool-missing:<tool_name>` - 依存ツール不在（`dasel` / `jq` 等）
  - `repair-hint: 手動同期 - aidlc-setup 側に同セクションを追加 / または正本に合わせて削除`
- **exit code 拡張**:
  - 0: ok / 1: mismatch (key-missing or type-mismatch) / 2: error:not-found (既存) / 3: error:parse-error / 4: error:tool-missing

## ドメインサービス

### KeyExtractionService

- **責務**: dasel で TOML から全キーパスを列挙
- **操作**: `extract_keys(toml_file)` - `.` 区切りキーパスのソート済み配列を返す

### TypeComparisonService

- **責務**: 同一キーパスの値型を比較
- **操作**: `compare_types(source_value, copy_value)` - 一致 / 不一致 + (型名, 型名) を返す

### FailureContractRenderer

- **責務**: 差分を failure contract 形式に整形
- **操作**: `render(missing_keys, type_mismatches)` - stdout/stderr 出力文字列を生成

## ユビキタス言語

- **正本 (Source)**: `skills/aidlc/config/defaults.toml`。AI-DLC スターターキット本体の defaults
- **コピー (Copy)**: `skills/aidlc-setup/config/defaults.toml`。consumer 配布用の sync コピー
- **構造比較 (Structural Comparison)**: 行ベース文字列一致ではなく、TOML キーパス集合 + 値型集合の同値比較
- **failure contract**: CI 失敗時の機械可読な出力スキーマ。後段の自動修復スクリプトや CI ログ解析が解釈可能な形式
