# ドメインモデル: Unit 001 v3 state スクリプト基盤

## 概要

v3 の cycle state（`.aidlc/state.json`）を「読む / 書く / 検証する」3 操作のドメインを定義する。state.json はサイクルレベルの状態（define 完了・release 状態）を保持する単一ドキュメントであり、本 Unit はその schema validation + atomic write + 許可フィールド更新までを責務とする。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2（コード生成ステップ）で行う。

## ステップ0: 事前コード読込み（新規スクリプト作成のため参照基盤の確認）

本 Unit は `skills/aidlc-v3/scripts/` を新規作成する（改修対象の既存実装は存在しない）。そのため本セクションは「既存実装の挙動把握」ではなく、設計判断の根拠となる**正本・規約・スタイル基盤**の確認として実施する。

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `docs/v3/data-model.md` §3 | state.json schema（フィールド・型・必須・release サブフィールド・書き込みタイミング）の正本確認 |
| `docs/v3/data-model.md` §6 | 破損・不正・矛盾時の扱い（validate が検知すべきパターンの方針）確認 |
| `skills/aidlc/guides/exit-code-convention.md` | 終了コード規約（0=成功 / 1=バリデーション / 2=システム）の確認 |
| `skills/aidlc/scripts/read-config.sh` | 既存 v2 スクリプトの終了コード運用・stderr/stdout 分離・引数処理スタイルの参照 |
| `.aidlc/cycles/v3.0.0-alpha.2/requirements/intent.md` | スコープ境界（schema validation + atomic write + 許可フィールド更新まで、状態遷移ルールは Phase 3）の確認 |

### (b) 設計時に意識すべき挙動

- **atomic 性**: state.json の書き込みは「temp file 生成 → 検証 → `mv` で置換」とし、書き込み途中の中断でも元ファイルが破損しないこと。temp file は**同一ディレクトリ**（同一ファイルシステム）に作成し `mv` の atomic 性を担保する
- **検証の冪等性・副作用なし**: validate / read は state.json を一切変更しない（read-only）
- **release サブフィールドの型差**: `release.pr_number` は `integer or null` の二者を許容する点が他の boolean フィールドと異なる。validate はこの「null 許容」を特別扱いする
- **終了コードの呼び出し元契約**: 呼び出し元（Phase 3 の flow / status.md）が exit code で「有効/無効/エラー」を機械判定する。バリデーション失敗（無効な state）とシステムエラー（jq 未導入等）を別コードに分離する
- **可搬性**: macOS（BSD）/ Linux（GNU）両対応。`mktemp` / `mv` は両環境で動く可搬なオプションのみ使用
- **コマンド置換**: 実 `.sh` 内では `$(...)` の使用は許容される（禁止規約は Markdown プロンプト `*.md` が対象）が、Bash ツール経由実行時のハザード（Issue #697）に留意して適切に記述する

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採用 / 却下 | 根拠 |
|------|------|-----------|------|
| `jq` ベース | JSON の読取・生成・検証を全て jq で行う | **採用** | Unit 定義で jq 前提が明記され環境に存在。JSON ネイティブで型判定も jq で完結 |
| `dasel` 流用 | v2 の TOML 読取で使う dasel を JSON にも流用 | 却下 | dasel は TOML 用途で導入されており JSON 型検証には冗長。jq の方が JSON に対し直接的 |
| sed/grep ベース | テキスト処理で JSON を扱う | 却下 | JSON のネスト・型を正しく扱えずアンチパターン |
| 3 スクリプト分離 | read / write / validate を別ファイルに分ける | **採用** | Unit 定義の責務分割。write が validate を内部利用する依存は一方向で循環なし |

## エンティティ（Entity）

### StateDocument（state.json）

cycle state を表す単一の集約ルート。リポジトリ直下 `.aidlc/state.json` に 1 つ存在する。

- **ID**: ファイルパス（`.aidlc/state.json`。実体はパス引数で受け取る）
- **属性**:
  - `schema_version`: string - schema バージョン（初版 `"3.0"`）
  - `current_cycle`: string - 対象サイクル識別子（例 `"v3.0.0"`）
  - `define_completed`: boolean - define 完了フラグ
  - `release`: ReleaseState（値オブジェクト） - release 状態
  - `updated_at`: string (ISO 8601) - 最終更新時刻
- **振る舞い**（本 Unit のスクリプトが担う操作として表現）:
  - read(field): 指定フィールド値を返す（自身は不変）
  - validate(): 必須フィールド・型・JSON 妥当性を判定し有効/無効を返す（自身は不変）
  - write(field, value): 許可フィールドを更新し atomic に永続化（検証通過時のみ確定）

## 値オブジェクト（Value Object）

### ReleaseState（`release` オブジェクト）

- **属性**:
  - `pr_number`: integer or null - PR 番号（未作成は `null`）
  - `ready`: boolean - PR ready 化フラグ
  - `merge_approved`: boolean - merge 承認記録（merge 済みではない）
- **不変性**: state 更新は StateDocument 経由でのみ行い、ReleaseState 単体では書き換えない（write 操作の単位は StateDocument の atomic 置換）
- **等価性**: 3 サブフィールドの値がすべて等しければ等価

### FieldKey（読取・更新対象フィールドの識別子）

- **属性**: ドット区切りのキーパス文字列（`schema_version` / `current_cycle` / `define_completed` / `release.pr_number` / `release.ready` / `release.merge_approved` / `updated_at`）
- **不変性**: 許容されるキー集合は schema により固定。未知キーは read で「キー不在」、write で「許可外」として扱う
- **等価性**: 文字列一致

## 集約（Aggregate）

### StateDocument 集約

- **集約ルート**: StateDocument
- **含まれる要素**: トップレベルフィールド群 + ReleaseState 値オブジェクト
- **境界**: state.json ファイル 1 つ。書き込みはこの集約全体を単位として atomic に置換する（部分書き込みを許さない）
- **不変条件**:
  - 必須フィールド（`schema_version` / `current_cycle` / `define_completed` / `release` / `updated_at`）が全て存在する
  - 各フィールドが schema 通りの型である（`release.pr_number` は integer または null）
  - `updated_at` は ISO 8601 形式の文字列である
  - ファイル全体が妥当な JSON である

## ドメインサービス

### StateValidationService（`state-validate.sh` が担う）

- **責務**: StateDocument の不変条件（必須フィールド・型・ISO 8601 形式・JSON 妥当性）を検証し、有効/無効を終了コードで返す。状態は変更しない
- **操作**:
  - validate(file): JSON parse → 必須フィールド存在 → 型検証 → `release` サブフィールド検証 → `updated_at` ISO 8601 検証。1 つでも違反すれば無効

### StateWriteService（`state-write.sh` が担う）

- **責務**: 許可フィールドの更新を受け、temp file へ反映 → StateValidationService で検証 → 通過時のみ `mv` で atomic 置換。検証失敗時は temp を破棄し元ファイルを保持
- **操作**:
  - write(file, field, value): 許可フィールド更新（atomic）。許可外フィールドはバリデーションエラー
- **依存**: StateValidationService（write 前後の整合性担保のため。一方向依存・循環なし）

### StateReadService（`state-read.sh` が担う）

- **責務**: 指定フィールド値の抽出（read-only）。状態は変更しない
- **操作**:
  - read(file, field): フィールド値を stdout に出力。キー不在は終了コードで区別

## リポジトリインターフェース

本 Unit はファイルシステム上の単一 JSON ファイルを直接対象とするため、抽象リポジトリ層は設けない（永続化先は `.aidlc/state.json` 固定パスで、パスは引数で受け取る）。永続化操作は各ドメインサービスが jq + atomic mv で直接行う。

## ユビキタス言語

- **cycle state**: サイクルレベルの状態。`state.json` が保持（define 完了・release 状態）
- **atomic write**: temp file 生成 → 検証 → `mv` 置換による、中断耐性のある書き込み
- **許可フィールド**: write で更新を許される state.json のフィールド集合（`define_completed` / `release.*`）。具体的完全リストは論理設計で確定
- **single-actor moment**: state.json への書き込みを define 完了時・release 時に限定し、並行書き込み競合を避ける設計原則（data-model.md §3.3）
- **有効な state / 無効な state**: 必須フィールド・型・ISO 8601・JSON 妥当性をすべて満たすものが有効。1 つでも欠ければ無効

## 不明点と質問（設計中に記録）

[Question] state-write.sh は初期 state.json の新規作成も担うか、既存ファイルの更新専用か。
[Answer] 論理設計で確定する。本 Unit のスコープは「atomic write + 許可フィールド更新」であり、新規作成（define Step 4 相当）の要否は state-read/write/validate の最小 API として両対応にするか更新専用にするかを論理設計の I/F 定義で決める。

[Question] `updated_at` は write 時に自動付与するか、呼び出し元が値を渡すか。
[Answer] 論理設計で確定する。atomic 性・テスト再現性（固定値注入可否）に影響するため、I/F 設計で「自動付与 or 引数受け取り」を明示する。

[Question] `release.pr_number` の null 許容を validate でどう表現するか。
[Answer] jq で `type` を見て `"number"` または `"null"` のいずれかを許容と判定する（論理設計で jq 式を具体化）。
