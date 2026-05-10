# 論理設計: Unit 005 `squash-unit.sh` の CI 構造チェックスクリプト設定駆動化

## 概要

`skills/aidlc/scripts/squash-unit.sh` の `run_internal_ci_checks_or_skip()` を設定駆動化し、starter kit 固有のチェックスクリプト名・配置の知識を本体スクリプトから完全排除する。`.aidlc/config.toml` の `[rules.squash.internal_ci_checks].scripts` 設定キーから `read-config.sh` 経由で動的に解決し、配列パース・パス正規化バリデーション・実体存在チェック・実行・出力契約をひとまとまりのフローとして再構成する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。具体的なコードは Phase 2 で作成する。

## アーキテクチャパターン

**レイヤード構成（既存スクリプト内 / 軽量）**: 本 Unit の変更は `squash-unit.sh` 内に閉じる。新たなパターン導入はせず、既存のフラットな関数群構造に「設定読取 → 配列パース → エントリ評価 → 実行」の単方向データフロー層を追加する形で再構成する。Strategy / Plugin パターンは過剰なため採用しない。

選定理由: 単一スクリプト内の局所改修であり、ファイル分割や共有ライブラリ化を伴わない。設計原則「ドッグフーディング特殊処理を本体に埋めない」の最小実現として、本体スクリプトから固有知識を排除し外部設定 + 局所ヘルパに分解するのが適切。

## コンポーネント構成

### レイヤー / モジュール構成

```text
skills/aidlc/scripts/squash-unit.sh
├── run_internal_ci_checks_or_skip(repo_root)   # メイン関数（再構成）
│   ├── (1) 設定読取層
│   │   └── bash scripts/read-config.sh rules.squash.internal_ci_checks.scripts
│   │       （exit 0/1/2 を解釈、外部呼び出し）
│   ├── (2) 配列パース層（局所ヘルパ）
│   │   └── parse_config_array(rawString)
│   │       （Python 風 list literal → 改行区切り行配列）
│   ├── (3) エントリ評価層（インライン処理）
│   │   ├── パス正規化チェック（4 条件 OR）
│   │   ├── リポジトリルート相対の実体存在チェック
│   │   └── bash 実行
│   └── (4) 出力契約層（インライン処理）
│       ├── 集約 skip 出力（2 行契約）
│       ├── 個別 skip 出力（1 行 / 各エントリ）
│       └── 集約エラー出力（既存トークン維持）
└── （main / 他関数群: 既存維持、変更なし）

.aidlc/config.toml
└── [rules.squash.internal_ci_checks]
    └── scripts = [...]   # starter kit 既定 3 種（本 Unit で追加）

bin/tests/squash-unit/
├── internal_ci_checks_optin.bats              # 既存（v2.6.0 Unit 007 / 維持）
└── internal_ci_checks_config_driven.bats      # 新規（本 Unit）
```

### コンポーネント詳細

#### `run_internal_ci_checks_or_skip(repo_root)`

- **責務**: 設定駆動で CI チェックスクリプト群を実行し、結果を安定トークンとして出力する。本体スクリプトに固有知識（特定スクリプト名）を持たない
- **依存**: `parse_config_array`（局所ヘルパ）/ `bash scripts/read-config.sh`（外部スクリプト経由）/ 各 `bin/check-*.sh`（設定で指定された任意のスクリプト）
- **公開インターフェース**:
  - 引数: `repo_root` (String) — `git rev-parse --show-toplevel` の結果（既存契約と同じ）
  - 戻り値: 終了コード `0`（全成功 or 集約 skip）/ `2`（チェック失敗）
  - 副作用: stdout に安定トークン群を出力。stderr に info / warning ログを出力

#### `parse_config_array(rawString)`

- **責務**: `read-config.sh` の現行配列出力形式（Python 風 list literal `['a', 'b']`）を改行区切り行配列にデコードし、想定外フォーマット入力をエラーとして検出する責務に閉じる局所ヘルパ
- **依存**: なし（純粋な文字列処理）
- **公開インターフェース**（設計レビュー Round 2 指摘 #2 反映 / IF を一本化）:
  - 引数: `rawString` (String) — `read-config.sh` の生 stdout
  - 戻り値（stdout）:
    - 正常時: 改行区切り行配列（空配列 `[]` / 空文字列 → 0 行）
    - 異常時: 0 行（出力なし）
  - 戻り値（exit code）:
    - `0`: 正常パース完了（要素 0 件以上）
    - `1`: 想定外フォーマット入力検出（`[` で始まらない / `]` で終わらない / 制御文字混入）
  - 副作用: なし（純粋関数）
- **将来の置換条件**: `read-config.sh` 側に `--format=lines` 等の配列安全出力モードが追加された段階で本ヘルパは削除可能（責務が設定読取層へ移管）

## インターフェース設計

### コマンド

#### `run_internal_ci_checks_or_skip(repo_root)`

- **パラメータ**: `repo_root` (String) — リポジトリルートの絶対パス
- **戻り値（終了コード）**:
  - `0`: 全成功 / 集約 skip / 個別 skip 後の残り全成功（squash 続行可）
  - `2`: いずれかのチェックスクリプトが失敗（squash 中止）
- **副作用**:
  - stdout: 安定トークン（`StableTokenContract` の出力契約に従う）
  - stderr: info / warning ログ（人間可読 / 機械判定対象外）

#### `parse_config_array(rawString)`

- **パラメータ**: `rawString` (String) — `read-config.sh` の生 stdout（例: `['a', 'b']` / `[]` / 空文字列）
- **戻り値**:
  - stdout: 正常時 = 改行区切り行配列 / 異常時 = 0 行
  - exit code: `0` = 正常 / `1` = 想定外フォーマット
- **副作用**: なし（純粋関数）

### スクリプトインターフェース設計

#### `skills/aidlc/scripts/squash-unit.sh`（外部 IF は変更なし）

本 Unit では `squash-unit.sh` の CLI インターフェース（`--cycle` / `--unit` / `--message` 等）に変更を加えない。内部関数 `run_internal_ci_checks_or_skip()` の実装変更のみ。既存の引数・終了コード・出力フォーマット契約は完全維持。

#### `bash scripts/read-config.sh rules.squash.internal_ci_checks.scripts`（外部依存）

- **引数**: `rules.squash.internal_ci_checks.scripts`（単一キー）
- **戻り値**: stdout に Python 風 list literal `['a', 'b', 'c']` または `[]`、終了コード 0
- **キー不在時**: 終了コード 1（出力なし）
- **エラー時**: 終了コード 2（dasel 未インストール / TOML 破損等）

## データモデル概要

### ファイル形式

#### `.aidlc/config.toml` への追加セクション

- **形式**: TOML 配列
- **主要フィールド**:
  - `[rules.squash.internal_ci_checks]`（新規セクション）
    - `scripts` (Array of String): リポジトリルート相対パスの順序付きリスト

実例（starter kit リポジトリ既定）:

```toml
[rules.squash.internal_ci_checks]
# squash-unit.sh が Unit 完了時に opt-in で実行する CI 構造チェックスクリプト一覧
scripts = [
    "bin/check-skill-references.sh",
    "bin/check-bash-substitution.sh",
    "bin/check-test-isolation.sh",
]
```

## 処理フロー概要

### `run_internal_ci_checks_or_skip(repo_root)` のメイン処理フロー

**ステップ**:

1. `bash scripts/read-config.sh rules.squash.internal_ci_checks.scripts` を呼び出し、`rawString` と終了コードを取得
2. 終了コード分岐:
   - `2`（read-config.sh 実行系エラー: dasel 未インストール / TOML 破損等）→ 警告 (stderr) + 集約 skip 出力（**reason=config-read-error** / 設定不在と分離 / 設計レビュー Round 1 指摘 #2 反映）+ return 0（squash 続行 / 安全側）
   - `1`（キー不在 = consumer プロジェクト想定）→ 集約 skip 出力（reason=no-config）+ return 0
   - `0`（成功）→ ステップ 3 へ
3. `parse_config_array(rawString)` を呼び出して `entries[]` と exit code を取得
   - exit 1（想定外フォーマット = 配列開始 `[` がない / 閉じ括弧 `]` がない / 制御文字混入等）→ 警告 (stderr) + 集約 skip 出力（**reason=invalid-config-format** / 設計レビュー Round 1 指摘 #3 反映）+ return 0
   - exit 0 → ステップ 4 へ
4. `entries[]` が空 → 集約 skip 出力（reason=empty-config）+ return 0
5. 各 entry をループ（順序維持）:
   - パス正規化チェック（4 条件 OR）:
     - 空文字、絶対パス（`/` で始まる）、`..` 含む、許容文字外
     - 不正 → 個別 skip 出力（reason=invalid-path）+ stderr 警告 + 次の entry へ
   - 実体存在チェック: `${repo_root}/${entry}`
     - 不在 → 個別 skip 出力（reason=script-not-found）+ 次の entry へ
   - bash 実行: `bash "${repo_root}/${entry}" >&2`
     - 成功 → `executed_count++` + 次の entry へ
     - 失敗 → 集約エラートークン出力（`squash:error:<basename>-failed`）+ return 2
6. ループ終了後、`executed_count == 0` の場合 → 集約 skip 出力（reason=no-script-present）+ return 0
7. `executed_count > 0` → return 0（成功）

**関与するコンポーネント**: `run_internal_ci_checks_or_skip` / `parse_config_array` / `read-config.sh`（外部）/ 各 `bin/check-*.sh`

### `parse_config_array(rawString)` の処理フロー

**ステップ**:

1. 入力 `rawString` の前後空白を trim
2. 入力が空文字 → 0 行出力で return（exit 0 / 防御的処理）
3. **フォーマット検証**（設計レビュー Round 1 指摘 #3 反映）:
   - 入力が `[` で始まらない、または `]` で終わらない → exit 1（reason=invalid-config-format）
   - 入力に制御文字（タブ・改行を除く `\x00-\x1F`）が含まれる → exit 1
4. 入力が `[]` の場合 → 0 行出力で return（exit 0）
5. `[` と `]` を除去
6. `'` と `"` を除去
7. カンマで分割
8. 各要素の前後空白を trim
9. 空要素はスキップ
10. 改行区切りで stdout 出力で return（exit 0）

**関与するコンポーネント**: `parse_config_array` のみ（純粋関数 / 外部依存なし）

**戻り値契約**: exit 0 = 正常パース完了（要素 0 件以上）/ exit 1 = 想定外フォーマット検出。呼び出し元は exit 1 を `invalid-config-format` reason の集約 skip にマッピングし、`config-read-error`（read-config.sh 自体の障害）と区別する。

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: Unit 定義 NFR「設定読取オーバーヘッドは squash 実行ごとに 1 回（数 ms 程度で許容）」
- **対応策**: `read-config.sh` 呼び出しは squash 実行あたり 1 回のみ。各 entry のパス正規化 + 実体存在チェックは O(N) で entry 数に比例（N=3 で実用上ゼロコスト）

### セキュリティ

- **要件**: Unit 定義 NFR「設定値（スクリプトパス）の正規化（リポジトリルート相対のみ許容、絶対パス・上位パス traversal 禁止）を維持」
- **対応策**: パス正規化チェックを 4 条件 OR で実装（絶対パス reject / `..` traversal reject / 許容文字外 reject / 空エントリ reject）。不正検出時は個別 skip + 警告で squash 自体は中断しない（攻撃 surface を最小化）。bats テストで `../etc/passwd` / `/etc/passwd` / `bin/../bin/x.sh` を検証

### スケーラビリティ

- **要件**: Unit 定義 NFR「設定リストのスクリプト数増加に対してリニアスケール（既存挙動維持）」
- **対応策**: シンプルなループ実装。並列実行は導入しない（順序保証 + 既存挙動互換優先）

### 可用性

- **要件**: Unit 定義 NFR「設定不在時の fallback で v2.6.0 と同等の挙動を保証（後方互換）」
- **対応策**: 設定不在時は集約 skip + 既存トークン `squash:info:internal-ci-checks-skipped` を 1 行目に必ず出力し、reason は別行で 2 行契約。既存 grep ルールは無改修で互換。`read-config.sh` exit 2 時は安全側で集約 skip にフォールバック（squash 自体を阻害しない）

## 技術選定

- **言語**: bash 4.x+（既存 `squash-unit.sh` の前提を踏襲）
- **外部依存**: `bash scripts/read-config.sh`（公開 API スクリプト層 / Unit 004 で確立）/ dasel CLI v3（read-config.sh の下位依存）
- **テスト**: bats 1.5.0+（既存 `bin/tests/squash-unit/internal_ci_checks_optin.bats` の前提を踏襲）

## 実装上の注意事項

### セキュリティ

- パス正規化バリデーションは「許容文字セット」と「`..` 排除」を**独立条件**として OR 評価する（許容文字セットだけでは `..` を排除できない / 計画レビュー Round 2 確定事項）
- 設定値のスクリプトパスは `bash` 引数として渡すため、quote 処理に注意（既存の `bash "${repo_root}/${check_script}.sh"` パターンを踏襲）

### パフォーマンス

- `read-config.sh` 呼び出しは 1 回のみ。ループ内で再呼び出ししない
- `parse_config_array` は純粋関数で sub-shell を最小化（`tr` / `awk` / `sed` の組み合わせを避け、bash 内文字列操作で完結する設計を Phase 2 で検討）

### 保守性・拡張性

- `parse_config_array` は将来 `read-config.sh --format=lines` 移行時に削除する前提で、責務を「文字列デコードのみ」に閉じる（実体存在チェックや正規化を内部で行わない）
- 安定トークン体系は計画の表に従い、既存 `squash:info:internal-ci-checks-skipped` を 1 行目に維持しつつ reason は別行で出力（後方互換）
- `bin/check-*.sh` の固有名は本体スクリプトに一切残さない（`grep -nE 'check-skill-references|check-bash-substitution|check-test-isolation' skills/aidlc/scripts/squash-unit.sh` が exit 1）

### 後方互換（設計レビュー Round 1 指摘 #4 反映）

- **既存トークン保持**: `squash:info:internal-ci-checks-skipped` は集約 skip 時の 1 行目として常に出力。既存パーサ（CI ログ集約 / 監視ルール）の grep / prefix match 互換性を維持
- **追加トークンのみ**: 本 Unit で追加されるのは reason 別行（`squash:info:internal-ci-checks-skipped:reason=<reason>`）と個別 skip トークン（`squash:warn:internal-ci-check-skipped:reason=invalid-path:script=<entry>` / `squash:info:internal-ci-check-skipped:reason=script-not-found:script=<entry>`）。既存トークンの形式・順序は変更しない
- **strict parser 向けの推奨**: 既存利用側が stdout の厳密比較（行数 / 行内容完全一致）をしている場合、本 Unit の追加トークン分行数が増える。互換性確保のため、利用側は **prefix match**（例: `^squash:info:internal-ci-checks-skipped` で grep）または **トークン名集合比較**（特定の安定トークン名の存在チェック）を推奨。bats テストでも prefix match パターンを採用する
- `.aidlc/config.toml` への設定追加で starter kit 自身は従来挙動維持（dogfood 確認を完了条件に追加）
- 既存 bats テスト `internal_ci_checks_optin.bats`（v2.6.0 Unit 007 由来 / GATE-8 starter kit 3 種揃い保証）は本 Unit の実装挙動と互換性がない（旧テストは「config 不在で個別判定」前提だったが、新仕様では config 不在時 = 集約 skip）。**実装フェーズで旧ファイルを削除し、GATE-8 4 ケース（3 種ファイル存在 + config に 3 種定義保証）を新規ファイル `bin/tests/squash-unit/internal_ci_checks_config_driven.bats` 末尾に移植**（コードレビュー Round 1 指摘 #2 反映 / 設計レビュー時点の方針から実装方針へ更新）。新規ファイルが設定駆動分岐 24 ケース（内訳: parse_config_array 単体 9 / is_invalid_check_path 単体 6 / config-driven 統合 8 / backward-compat 1）+ GATE-8 4 ケース = **計 28 ケース**を統合的に検証する

## 不明点と質問

[Question] 論理設計に関する不明点はあるか
[Answer] 計画レビュー Round 1〜4 およびドメインモデルで論点整理済み。論理設計では新規不明点なし。Phase 2（実装）への移行可能。
