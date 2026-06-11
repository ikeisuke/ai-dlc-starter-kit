# 論理設計: Unit 001 v3 state スクリプト基盤

## 概要

`skills/aidlc-v3/scripts/` に置く 3 本のシェルスクリプト（`state-read.sh` / `state-write.sh` / `state-validate.sh`）のコンポーネント構成・CLI インターフェース・処理フロー・終了コードを定義する。設計正本は `docs/v3/data-model.md` §3、終了コード規約は `skills/aidlc/guides/exit-code-convention.md`。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行う。jq 式・実装コードは Phase 2（コード生成ステップ）で作成する。

## ステップ0: 事前コード読込み（新規スクリプト作成のため参照基盤の確認）

本 Unit は新規スクリプトを作成し改修対象の既存実装が無いため、本セクションは設計判断の根拠となる正本・規約・スタイル基盤の確認として実施する（3 観点の詳細はドメインモデル `design-artifacts/domain-models/unit_001_v3_state_scripts_domain_model.md` のステップ0 に記載。本論理設計は以下の要点を踏まえて起草した）。

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `docs/v3/data-model.md` §3 | state.json schema（フィールド・型・必須・release サブフィールド・書き込みタイミング表）の正本確認 |
| `docs/v3/data-model.md` §6 | validate が検知すべき破損・不正パターンの方針確認 |
| `skills/aidlc/guides/exit-code-convention.md` | 終了コード規約（0=成功 / 1=バリデーション / 2=システム）の確認 |
| `skills/aidlc/scripts/read-config.sh` | 既存 v2 スクリプトの終了コード運用・stdout/stderr 分離・引数処理スタイルの参照 |

### (b) 設計時に意識すべき挙動

- atomic write は temp file（同一ディレクトリ）+ `mv` で中断耐性を担保する
- read / validate は state.json を変更しない（read-only・副作用なし）
- `release.pr_number` は `integer or null` を許容し、他の boolean フィールドと型判定を分ける
- バリデーション失敗（exit 1）とシステムエラー（jq 未導入等, exit 2）を終了コードで分離する
- macOS（BSD）/ Linux（GNU）両対応の可搬オプションのみ使用する

### (c) 既存実装に基づく代替案検討

- **JSON 処理基盤**: jq（採用） vs dasel 流用（却下: TOML 用途で JSON 型検証に冗長） vs sed/grep（却下: JSON ネスト・型を正しく扱えずアンチパターン）
- **検証の配置**: validate を独立 SoT 化し write が内部呼び出し（採用） vs write 内に検証を内包（却下: 検証ロジック二重化）
- **作成/更新**: 更新専用（採用: intent スコープに整合） vs 初期作成も担う（却下: define フロー = Phase 3 の責務）

## アーキテクチャパターン

**単機能 CLI スクリプト + 共有検証サービス**（小規模シェルツール）。

- 3 スクリプトは各々独立した CLI エントリポイント（read / write / validate）。
- `state-validate.sh` を検証の Single Source of Truth とし、`state-write.sh` は書き込み確定前に `state-validate.sh` を内部呼び出しする（検証ロジックの二重実装を避ける一方向依存）。
- 状態は `.aidlc/state.json`（JSON ファイル）に永続化。JSON の読取・生成・型判定は `jq` で完結する。

選定理由: Unit の責務（read/write/validate の最小 API）に対し、レイヤードアーキテクチャ等は過剰。検証ロジックの一元化（DRY）と atomic write のみが構造上の要点。

## コンポーネント構成

### モジュール構成

```text
skills/aidlc-v3/scripts/
├── state-read.sh       (read-only: フィールド抽出)
├── state-write.sh      (atomic write: 許可フィールド更新 → validate → mv)
└── state-validate.sh   (read-only: schema validation / 検証 SoT)
```

### コンポーネント詳細

#### state-validate.sh

- **責務**: state.json の妥当性（JSON parse・必須フィールド・型・`release` サブフィールド・`updated_at` の ISO 8601 形式）を検証し、有効/無効を終了コードで返す。状態は変更しない（read-only）
- **依存**: `jq`
- **公開インターフェース**: `state-validate.sh [file]`

#### state-read.sh

- **責務**: 指定フィールド値を stdout に抽出する（read-only）。状態は変更しない
- **依存**: `jq`
- **公開インターフェース**: `state-read.sh <field> [file]`

#### state-write.sh

- **責務**: 許可フィールドのみを更新し、`updated_at` を自動更新したうえで atomic（temp file + mv）に書き込む。書き込み確定前に `state-validate.sh` で検証する
- **依存**: `jq`, `state-validate.sh`（同一ディレクトリ）
- **公開インターフェース**: `state-write.sh <field> <value> [file]`

## スクリプトインターフェース設計

### 共通仕様

- **対象ファイルのデフォルト**: 第 2/第 3 引数で `file` を省略した場合、`.aidlc/state.json`（カレントディレクトリ基準）を対象とする
- **stdout / stderr 分離**: 結果値・ステータスは stdout、エラーメッセージは stderr（`>&2`）。終了コード規約に準拠
- **`set -euo pipefail`** を全スクリプトで設定
- **jq 不在時**: いずれのスクリプトも起動時に `command -v jq` を確認し、不在なら stderr にメッセージを出して **exit 2**（システムエラー）

### 終了コード規約（`skills/aidlc/guides/exit-code-convention.md` 準拠）

| コード | 意味 | 本 Unit での用途 |
|--------|------|----------------|
| `0` | 成功 | 読取成功 / 検証で有効 / 書き込み完了 |
| `1` | バリデーションエラー | 引数不正・未知/許可外フィールド・入力ファイル不存在・JSON parse 不能・schema invalid・キー不在 |
| `2` | システムエラー | jq 未導入・ファイル読み取り不能・`mv`/`mktemp` 等の外部コマンド失敗 |

### state-validate.sh

#### 概要

state.json が schema に適合する有効な state かを検証する（検証 SoT）。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `file` | 任意 | 検証対象パス（デフォルト: `.aidlc/state.json`） |

#### 検証項目（順に評価。1 つでも違反で無効）

1. **ファイル存在**: 対象ファイルが存在しなければ exit 1（入力ファイル不存在）。存在するが読み取り不可（permission denied 等）は exit 2（システムエラー / 規約: 読み取りエラー = システムエラー）
2. **JSON 妥当性**: jq でパース不能なら exit 1。**検証契約**: 本 Unit は jq を唯一の JSON ツールとする（Unit 制約）ため、「JSON 妥当性」は jq が受理する入力をもって妥当とする（jq は先頭ゼロ数値 `001` 等を `1` にコアースする寛容性を持つ）。RFC 8259 strict 構文検証（別 parser 依存の追加）は本 Unit のスコープ外であり、state.json は state-write.sh が機械生成する前提のため手書き非標準 JSON 混入経路は限定的
3. **必須トップレベルフィールド存在**: `schema_version` / `current_cycle` / `define_completed` / `release` / `updated_at` のいずれか欠落で exit 1
4. **型検証**:
   - `schema_version`: string
   - `current_cycle`: string
   - `define_completed`: boolean
   - `release`: object
   - `updated_at`: string
5. **release サブフィールド存在検証**: `release` オブジェクトが `pr_number` / `ready` / `merge_approved` の 3 キーを **すべて保持しているか**を `has()` で確認する。1 つでも欠落で exit 1。
   - **根拠**: jq は欠落キー（`.release.pr_number` 自体が無い）と明示 `null`（`"pr_number": null`）をともに `null` / `type == "null"` として返すため、型検証だけでは欠落を有効扱いしてしまう。`release | has("pr_number")` 等でキー存在を**型検証の前に**確認する（data-model.md §3.2 で 3 サブフィールドは必須、§6 で必須フィールド欠落は無効）
6. **release サブフィールド型検証**:
   - `release.pr_number`: number（整数: `. % 1 == 0`）または null
   - `release.ready`: boolean
   - `release.merge_approved`: boolean
7. **updated_at の ISO 8601 形式検証**: 下記「ISO 8601 許容形式」に一致しなければ exit 1

#### ISO 8601 許容形式（本 Unit の確定範囲）

`updated_at` は次の正規表現に一致する UTC タイムスタンプを許容する（data-model.md の例示 `2026-06-04T00:00:00Z` に整合）。各フィールドは**桁数だけでなく基本範囲も制約**する（`2026-99-99T99:99:99+99:99` のような明らかに不正な値を弾く）:

```text
^[0-9]{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])T(0[0-9]|1[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9](\.[0-9]+)?(Z|[+-](0[0-9]|1[0-9]|2[0-3]):[0-5][0-9])$
```

- 月 `01-12` / 日 `01-31` / 時 `00-23` / 分・秒 `00-59` / オフセット時 `00-23`・分 `00-59` を範囲制約
- 日付 + `T` + 時刻（秒まで必須）+ 任意の小数秒 + タイムゾーン（`Z` または `±HH:MM` オフセット）を許容
- カレンダー上の実在日（例: 2 月 30 日・うるう年判定）までは検証しない（形式 + 基本範囲検証に留める。厳密日付検証は本 Unit のスコープ外。`updated_at` は state-write.sh が `date -u` で自動生成する値であり外部不正入力の経路は限定的）

#### 成功時出力 / エラー時出力

```text
# 有効
status:valid        (stdout) / exit 0

# 無効
（無効理由を stderr に 1 行で出力。例: "invalid: missing field: updated_at"）
exit 1

# jq 未導入
"error: jq not found" (stderr) / exit 2
```

### state-read.sh

#### 概要

state.json から指定フィールド値を抽出して stdout に出力する。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `field` | 必須 | 抽出対象フィールド（許容キー: `schema_version` / `current_cycle` / `define_completed` / `release.pr_number` / `release.ready` / `release.merge_approved` / `updated_at`） |
| `file` | 任意 | 対象パス（デフォルト: `.aidlc/state.json`） |

#### 挙動

- 許容キー以外を指定 → stderr にメッセージ、exit 1（引数不正）
- ファイル不存在 → stderr にメッセージ、exit 1
- **指定キーがファイル内に存在しない**（破損・不完全な state）→ stderr にメッセージ、exit 1。jq `has()`（ネストキーは `.release | has("pr_number")` 等）でパス存在を確認し、**欠落と明示 `null` を区別する**（jq は両者をともに `null` として返すため、`has()` を使わないと欠落を誤って `null` 出力してしまう）
- **キーは存在し**値が `null`（例: `release.pr_number` は `release` 内にキーとして存在するが値は `null`）→ `null` を stdout に出力、exit 0
- 正常 → 値を stdout に出力（boolean は `true`/`false`、number はそのまま、string は引用符なしの素値）、exit 0
- jq 未導入 → exit 2

> **read と validate の責務分担**: read はキー存在のみを `has()` で確認し（欠落 → exit 1）、state 全体の schema 妥当性検証は行わない（それは `state-validate.sh` の責務）。「個別キーの欠落検知」は read、「state 全体の有効性判定」は validate という分担とする。JSON parse 不能時は parse 失敗を捕捉して exit 1（入力不正）とする。

#### 成功時出力 / エラー時出力

```text
# 例: state-read.sh define_completed
false               (stdout) / exit 0

# 例: state-read.sh release.pr_number （未作成）
null                (stdout) / exit 0

# 未知フィールド
"error: unknown field: foo" (stderr) / exit 1
```

### state-write.sh

#### 概要

許可フィールドを更新し、`updated_at` を更新したうえで atomic に書き込む。

#### 引数

| 引数 | 必須/任意 | 説明 |
|------|----------|------|
| `field` | 必須 | 更新対象フィールド（**許可フィールド**のみ。下記参照） |
| `value` | 必須 | 設定値（型は field に応じて解釈。下記参照） |
| `file` | 任意 | 対象パス（デフォルト: `.aidlc/state.json`） |

#### 許可フィールド（完全リスト / data-model.md §3.3 の書き込みタイミング表に一致）

| field | 受け取る value | jq での型変換 |
|-------|---------------|--------------|
| `define_completed` | `true` / `false` | boolean |
| `release.pr_number` | 整数 または `null` | number または null |
| `release.ready` | `true` / `false` | boolean |
| `release.merge_approved` | `true` / `false` | boolean |

- 上記以外の field（`schema_version` / `current_cycle` / `updated_at` を含む）を指定 → stderr にメッセージ、exit 1（許可外フィールド）。`schema_version` / `current_cycle` は state 作成時に確定する値であり本 Unit の更新対象外。`updated_at` は自動更新のため直接指定不可
- value の型不正（例: `define_completed` に `true`/`false` 以外）→ exit 1

#### updated_at の扱い

- 書き込み成功時、`updated_at` を**現在の UTC 時刻**（`date -u +%Y-%m-%dT%H:%M:%SZ` 相当）に自動更新する
- **テスト・再現性のための上書き**: 環境変数 `AIDLC_STATE_NOW`（ISO 8601 文字列）が設定されている場合はその値を `updated_at` に使う。CI / テストで決定的な値を注入可能にする（未設定時のみ `date` を呼ぶ）

#### 作成 / 更新の境界

- **本 Unit のスコープは「既存 state.json の更新」**。対象ファイルが存在しなければ exit 1（入力ファイル不存在）とし、新規初期 state の生成は行わない
- 初期 state.json の生成（define Step 4 相当）は Phase 3（define フロー実装）へ defer する（intent スコープ「含まれないもの」と整合）

#### 処理フロー（atomic write）

1. jq 存在確認（不在 → exit 2）
2. **依存スクリプト確認**: 同一ディレクトリの `state-validate.sh` が**存在し実行可能**かを確認（`[ -x "$dir/state-validate.sh" ]` 相当）。不在 / 実行権限なし → stderr にメッセージ、exit 2（システムエラー）。`set -euo pipefail` のまま依存呼び出しを素通しすると、存在しないコマンドの 127 / 実行権限なしの 126 が外部へ漏れ、終了コード規約の 0/1/2 契約を破るため、起動時に明示確認して exit 2 に正規化する
3. 引数検証（field が許可フィールドか / value の型整合 / file 存在）→ 不正なら exit 1
4. temp file を**対象ファイルと同一ディレクトリ**に作成（`mktemp` / 同一 FS で `mv` の atomic 性を担保）
5. jq で対象 field を更新 + `updated_at` を更新した JSON を temp file に書き出す
6. `state-validate.sh` を temp file に対して実行（検証 SoT 再利用）。**rc を捕捉**（`set -e` を発火させない条件文脈で呼ぶ）し、終了コードを次のとおり正規化:
   - `0`（有効）→ 次へ
   - `1`（検証失敗）→ temp file を削除し、元ファイルを保持して exit 1
   - `2`（validate 側のシステムエラー）→ temp file を削除して exit 2
   - **上記以外（126 / 127 等の想定外）→ temp file を削除し exit 2 に正規化**（依存スクリプト起動失敗の漏れ防止）
7. 検証成功 → `mv temp file → 対象ファイル`（atomic 置換）→ exit 0
8. 失敗時は必ず temp file を後始末する（trap で cleanup）

#### 成功時出力 / エラー時出力

```text
# 成功
status:written      (stdout) / exit 0

# 許可外フィールド
"error: field not writable: schema_version" (stderr) / exit 1

# 検証失敗（書き込み後の state が invalid）
"error: validation failed after write" (stderr) / exit 1（元ファイル保持）
```

## データモデル概要

### ファイル形式

- **形式**: JSON（`.aidlc/state.json`）
- **主要フィールド**: `docs/v3/data-model.md` §3.2 の schema に一致（`schema_version` / `current_cycle` / `define_completed` / `release{pr_number, ready, merge_approved}` / `updated_at`）
- **正本**: `docs/v3/data-model.md` §3。本スクリプト群は実装側として準拠する

## 処理フロー概要

### write の検証連携フロー

**ステップ**:
1. `state-write.sh` が引数検証 → temp file 生成
2. jq で field 更新 + `updated_at` 更新 → temp file
3. `state-write.sh` が `state-validate.sh <temp file>` を呼ぶ
4. 有効 → `mv` で atomic 置換 / 無効 → temp 破棄・元ファイル保持

**関与するコンポーネント**: state-write.sh, state-validate.sh, jq

## 非機能要件（NFR）への対応

### atomic 性

- **要件**: write は中断時の破損を防ぐ（Unit NFR）
- **対応策**: temp file（同一ディレクトリ）+ `mv` による atomic 置換。検証通過後のみ `mv`。失敗時は trap で temp を後始末

### 可搬性（macOS / Linux 両対応）

- **要件**: `bash -n` 通過、shellcheck 重大警告なし、BSD/GNU 両対応（Unit NFR）
- **対応策**: `mktemp`（テンプレート引数を渡す可搬形式）/ `mv` / `date -u` の POSIX 互換オプションのみ使用。`date` のフォーマット文字列は両環境共通の `+%Y-%m-%dT%H:%M:%SZ` を使用

### 共存（v2 非影響）

- **要件**: 成果物は `skills/aidlc-v3/scripts/` に限定し v2 に非影響（Unit NFR）
- **対応策**: 新規ディレクトリ配下にのみファイルを作成。`skills/aidlc/` には一切触れない

### 検証の一元化（保守性）

- **要件**: 検証ロジックの二重実装回避
- **対応策**: `state-validate.sh` を検証 SoT とし、write は内部でこれを呼ぶ

## 技術選定

- **言語**: Bash（`#!/usr/bin/env bash`、`set -euo pipefail`）
- **JSON 処理**: `jq`（読取・生成・型判定）
- **時刻**: `date -u`（ISO 8601 UTC。テスト時は `AIDLC_STATE_NOW` で上書き可能）
- **一時ファイル**: `mktemp`（対象ファイルと同一ディレクトリ）

## 実装上の注意事項

- **stderr/stdout 分離の徹底**: 呼び出し元が stdout をパースするため、エラーは必ず stderr
- **trap による temp 後始末**: write 中の異常終了でも temp file を残さない
- **null 許容の jq 表現**: `release.pr_number` は `type == "number"`（かつ整数）または `type == "null"` を許容
- **コマンド置換の扱い**: 実 `.sh` 内での `$(...)` は許容（禁止規約は Markdown プロンプト対象）。ただし AI が Bash ツール経由で実行する際のハザード（Issue #697）に留意
- **shellcheck**: 実装後に shellcheck を通し重大警告を解消する

## 不明点と質問（設計中に記録）

[Question] state-write.sh は初期 state.json の新規作成を担うか。
[Answer] 担わない（更新専用）。対象ファイル不存在は exit 1。初期生成は Phase 3 define フローへ defer（intent スコープと整合）。

[Question] updated_at は自動付与か引数受け取りか。
[Answer] 自動付与（現在 UTC）。テスト再現性のため環境変数 `AIDLC_STATE_NOW` で上書き可能とする。

[Question] ISO 8601 検証の厳密範囲は。
[Answer] 上記「ISO 8601 許容形式」の正規表現に確定（日付+T+時刻〔秒必須〕+任意小数秒+Z/オフセット）。実在日検証はスコープ外。
