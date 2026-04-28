# ドメインモデル: Unit 002 review-tools-self-integration

## 概要

`[rules.reviewing].tools` のレビューツール解決ロジックに `"self"` を正式エントリとして統合し、`"claude"` を alias として正規化、暗黙末尾 self 補完シムで後方互換性を担保する。本 Unit は文書改訂主体のため、以下のモデルは `review-routing.md §4 ToolSelection` の論理表現として記述する（実装コードは持たない）。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### `ConfiguredTool`

- **ID**: `name: string`(値オブジェクトとしての等価性で識別)
- **属性**:
  - `name`: `string` - レビューツール名（`"codex"` / `"self"` / `"claude"` / その他外部 CLI 名）
- **振る舞い**:
  - `normalize_alias()`: `name == "claude"` の場合に `"self"` へ単純置換した新規 `ConfiguredTool` を返す（最小実装、汎用化対象外）
  - `is_self_marker()`: `normalize_alias()` 適用後の `name == "self"` を判定

### `ReviewToolList`

- **ID**: 順序付きリスト全体（識別子は持たない、値オブジェクトとして扱う）
- **属性**:
  - `entries`: `List<ConfiguredTool>` - `[rules.reviewing].tools` の論理表現
- **振る舞い**:
  - `apply_alias_normalization()`: 各エントリに `normalize_alias()` を適用した新規 `ReviewToolList` を返す
  - `apply_self_shim()`: `SelfBackcompatShim` を適用した新規 `ReviewToolList` を返す
  - `resolve()`: `apply_alias_normalization()` → `apply_self_shim()` の合成順序でツール解決前処理を完了する

## 値オブジェクト（Value Object）

> **注**: 本 Unit は文書改訂主体で実装コードを持たないため、`ToolName` 値オブジェクトは過剰モデル化を避けて廃止する（指摘#3 対応）。`ConfiguredTool.name` は `string` 型として扱い、文字列等価で十分とする。alias 正規化（`"claude" -> "self"`）は `ConfiguredTool.normalize_alias()` の振る舞いとして表現する。

### `SelfBackcompatShim`(後方互換シム)

- **属性**:
  - `applied`: `bool` - シムが暗黙末尾追加を行ったかを示す構造化マーカー
- **不変性**: `applied` は適用結果であり、適用後は変更不可
- **等価性**: 振る舞いベースで等価性判定不要（純粋関数として機能する）
- **振る舞い**:
  - `apply(list: ReviewToolList) -> ReviewToolList`: リスト内に `"self"` が**一度でも出現する**場合は no-op（位置・出現回数を問わない）。一度も出現しない場合は末尾に `ConfiguredTool { name: "self" }` を追加
  - **適用順序**: `apply_alias_normalization()` を先に適用してから本シムを適用する（例: `["claude"]` → 正規化後 `["self"]` → シム判定 no-op）

### `SelfReviewForcedSignal`

- **属性**:
  - `triggered`: `bool` - シム適用結果が `["self"]` 単独の場合に `true`
- **不変性**: 値が決定したら変更不可
- **等価性**: `triggered` の真偽値で判定
- **発生条件**: `ReviewToolList.resolve()` 完了後の `entries` が `[ConfiguredTool { name: "self" }]` と等価な場合

## 集約（Aggregate）

### `ToolResolutionAggregate`

- **集約ルート**: `ReviewToolList`
- **含まれる要素**: `ConfiguredTool`(エンティティ) / `SelfBackcompatShim`(値オブジェクト) / `SelfReviewForcedSignal`(値オブジェクト)
- **境界**: `review-routing.md §4 ToolSelection` の前処理ロジック領域。`available_tools` チェック / `selected_path` 決定（§5）/ `fallback_policy` 適用（§6）はこの集約の外側
- **不変条件**:
  - `apply_alias_normalization()` → `apply_self_shim()` の順序で前処理が完了している
  - 解決後の `ReviewToolList.entries` には `"claude"` が一度も含まれない（alias 正規化済み）
  - 解決後の `ReviewToolList.entries` の末尾は必ず `"self"` を含む位置（シム適用済み）または `["self"]` 単独
  - `"self"` が末尾以外に配置された場合（例: 解決後 `["self", "codex"]`）は許容するが、`§5 PathSelection` で先頭優先により `self_review_forced` が出力される（`SelfReviewForcedSignal.triggered=true` 相当）

## ドメインサービス

### `ToolResolutionService`(`review-routing.md §4 ToolSelection` の実体)

- **責務**:
  - `ReviewToolList.resolve()` を呼び出して前処理を完了する
  - 解決後リストを先頭から走査し、`available_tools` と最初に一致したツール → その名前を `tool_name` として返す
  - `"self"` エントリは `available_tools` チェックを skip する（常時 available と扱う）
  - **走査結果が `"self"` のみで構成される場合（`self_review_forced=true`）→ `tool_name=none` を返す**(指摘#1 対応、パス 2 はサブエージェント呼び出しで外部 CLI ツール名は不要のため。`review-routing.md §1` 不変条件と整合)
  - どれも一致しない → `tool_name=none` + `cli_missing_permanent`(`"self"` を除外した残りが一致しない場合)
- **操作**:
  - `select_tool(configured: ReviewToolList, available: List<string>) -> ToolSelectionResult`: 上記責務を遂行する純粋関数（`available` の型は `List<string>`、`ToolName` 値オブジェクト廃止に伴う指摘#3 対応）

### 関連境界（変更対象外、参照のみ）

- `PathSelectionService`(`review-routing.md §5`): `ToolSelectionResult` を入力として `selected_path` を決定
- `FallbackPolicyService`(`review-routing.md §6`): `cli_runtime_error` / `cli_output_parse_error` の対応表（本 Unit で §6-B 注記化により `cli_missing_permanent` 行が §4 へ吸収される）

## ドメインイベント

> `depth_level=standard` のため、ドメインイベントは最小限とする（`comprehensive` で追加対象）。

### `ToolResolutionPerformed`

- **発生条件**: `ToolResolutionService.select_tool()` が完了して `tool_name` が確定した時
- **属性**: `tool_name`: `string | None` / `self_review_forced`: `bool` / `cli_missing_permanent`: `bool`
- **用途**: `review-routing.md §5 PathSelection` の入力シグナル

### `SelfShimApplied`

- **発生条件**: `SelfBackcompatShim.apply()` が暗黙末尾追加を行った時
- **属性**: `original_list`: `List<string>` / `result_list`: `List<string>`
- **用途**: 文書改訂時の動作確認テーブル / 履歴記録のトレース性

## ユビキタス言語

このドメインで使用する共通用語:

- **暗黙末尾 self 補完シム**: `[rules.reviewing].tools` リスト内に `"self"` が一度も出現しない場合に、暗黙的に末尾へ `"self"` を追加する後方互換ロジック
- **`"self"` エントリ**: `[rules.reviewing].tools` リスト内のツール名 `"self"`(セルフレビュー = サブエージェント方式 / インライン方式での自己評価)
- **`"claude"` alias**: `"self"` の alias として扱われるツール名。ToolSelection 入口で `"self"` に正規化される
- **セルフ直行シグナル（`self_review_forced`）**: `[rules.reviewing].tools` がシム適用後 `["self"]` 単独となる場合に出力されるシグナル。`§5 PathSelection` でパス 2（セルフ）直行を意味する
- **解決順序の延長**: `tools` リストの並び順 = 優先順位 = フォールバック順序という規約。`["codex", "self"]` は「codex 失敗時に self に降りる」を意味する
- **`SelfBackcompatShim` の no-op 条件**: リスト内に `"self"` が一度でも出現する場合（位置・出現回数を問わない）

## 不明点と質問（設計中に記録）

[Question] `"self"` が末尾以外（例: `["self", "codex"]`）に配置された場合の扱いは？
[Answer] 許容する。シムは適用済みリストに `"self"` が含まれるため no-op、ToolSelection の走査が先頭から行われ `"self"` が先にヒットして `self_review_forced` を出力する。用途上は末尾配置を推奨するが、強制ではない。本ドメインモデルの `ToolResolutionAggregate` 不変条件で「許容するが先頭優先」と明記。

[Question] `"claude"` 以外の任意 LLM CLI 名を alias として追加することは？
[Answer] 本サイクルでは対象外。Issue #611 / Unit 定義「境界」で「`"self"` / `"claude"` 以外の汎用ツール名正規化拡張は対象外」と明記済み。汎用化は次サイクル以降の課題。

[Question] alias 正規化とシム適用の合成順序は？
[Answer] `apply_alias_normalization()` を先に適用してから `apply_self_shim()` を適用する。例: `["claude"]` → 正規化後 `["self"]` → シム判定 no-op（リスト内に `"self"` が出現するため）。順序が逆だと `["claude"]` → シム適用 `["claude", "self"]` → alias 正規化 `["self", "self"]` のような重複が発生するため、本順序で固定する。
