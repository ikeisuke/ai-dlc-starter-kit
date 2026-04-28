# 論理設計: Unit 002 review-tools-self-integration

## 概要

`review-routing.md` および `review-flow.md` の文書改訂を主体とし、`[rules.reviewing].tools` のレビューツール解決ロジックに `"self"` を正式統合する論理設計。実装は文書改訂であり、コード変更は持たない。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

---

## 設計判断記録（Phase 1 確定事項）

計画書で Phase 1 確定とした 3 箇所の A/B 判断を、実態調査の結果に基づき以下のように確定する。本セクションは `history/construction_unit02.md` でも要約参照される。

### §6 改訂方針: §6-B（注記化）採用

- **判定根拠**: 計画書「§6-A/B 判定トリガー」に従い、`review-flow.md` および `review-flow-reference.md` から `review-routing.md §6` への明示参照箇所を grep 集計
- **使用 grep パターン**(計画書 Phase 1 ステップ 4 で定義): `(review-routing\.md.*§6|FallbackPolicyResolution|fallback_to_self|cli_missing_permanent|cli_runtime_error|cli_output_parse_error)`
- **実態調査結果**(集計範囲を明示):
  - `skills/aidlc/steps/common/review-flow.md`: **1 件**(L11 の `Codex セッション管理` エラー時 → `§6 fallback_policy` 参照)
  - `skills/aidlc/steps/common/review-flow-reference.md`: **0 件**(§6 直接参照および上記 grep キーワードへの一致なし)
  - 合計: 1 件
- **判定**: 2 箇所以下 → §6-B（注記化）
- **改訂内容（実装時に責務分離注記による吸収方式に確定、コードレビュー指摘#2 対応）**: §6 の表は既存 3 行（`cli_missing_permanent` / `cli_runtime_error` / `cli_output_parse_error`)を維持し、冒頭注記で「`cli_missing_permanent` フラグの**発生検出**は §4 ToolSelection 前処理の結果として行う / 本表は**対応ポリシー**を定義（責務分離）」と明示する。これにより `cli_missing_permanent` の `on_cli_missing` 参照（§1 不変条件 (3)/(4)）を破壊せずに、§4 への論理的吸収を実現する。`review-flow.md` L11 の `§6 fallback_policy` 参照は維持される

### defaults.toml 改訂方針: defaults-A（現状維持 + 注記）採用

- **判定根拠**: 計画書「defaults-A/B 判定トリガー」に従い、`aidlc-setup` 経由の `.aidlc/config.toml` テンプレートに `tools = ["codex"]` 文字列が含まれるかを grep で確認
- **実態調査結果**:
  - `skills/aidlc-setup/config/defaults.toml` L14: `tools = ["codex"]` を含む
  - `skills/aidlc-setup/templates/config.toml.template` L65: `tools = ["codex"]` を含む
- **トリガー判定**: 含まれる → defaults-B（明示化）が一次判定
- **スコープ保護による上書き**: 計画書「主対象ファイル」は `skills/aidlc/config/defaults.toml` のみで、`skills/aidlc-setup/` 配下は対象外。defaults-B 採用すると aidlc-setup 配下の `defaults.toml` および `config.toml.template` の同期更新が必要となり、Unit 002 のスコープ拡大を伴う。本サイクルではスコープ保護のため **defaults-A（現状維持 + 注記）** に上書き判定する
- **改訂内容**:
  - `skills/aidlc/config/defaults.toml` の `tools = ["codex"]` 行に「暗黙末尾 self 補完シムにより実質 `["codex", "self"]` 相当として動作する」旨のコメントを追加
  - `skills/aidlc-setup/` 配下の同期更新は本 Unit 対象外。次サイクル以降で必要なら別 Issue 化（バックログ登録の要否は完了処理時に判定）
- **既存動作への影響**: なし（暗黙シムで実質等価のため、defaults を変更せずとも `tools = ["codex"]` 設定はシム適用後 `["codex", "self"]` として動作）

### 検証方針: 検証-A（擬似実行表）採用

- **判定根拠**: 計画書「検証-A/B 判定トリガー」に従い、`tests/` 配下の bats テストインフラと CI 連動状況を確認
- **実態調査結果**:
  - `tests/migration/` 配下に bats テスト 6 ファイル（`migrate-apply-config.bats` 等、migration 関連のみ）
  - review-routing 関連の bats テストは未存在
  - CI 連動: `pr-check.yml` の bats job 状況は本 Unit 範囲外（`tests/migration/` 限定で運用されている可能性）
- **判定**: review-routing と整合する bats インフラなし、文書改訂主体に整合 → **検証-A（擬似実行表）**
- **改訂内容**: `review-routing.md` 末尾に「ToolSelection 解決結果テーブル」セクション（または同等の擬似実行表）を追加し、6 パターン（A〜F）の入力 → 出力（解決後 tools / `selected_path` / `tool_name`）を明示する

---

## アーキテクチャパターン

**純粋関数型ツール解決パイプライン**(`ReviewRoutingDecision` 合成順序の延長)。`review-routing.md §1 論理インターフェース契約` に既定の合成順序「`CallerContextMapping` → `ToolSelection` → `PathSelection` → `FallbackPolicyResolution`」を維持し、`ToolSelection` の前処理として alias 正規化 → 暗黙シム適用を直列に追加する。

**選定理由**:

- 既存合成順序を保ちつつ前処理を追加するだけで `"self"` 統合を実現可能
- 副作用なし（純粋関数）のため、テスト容易性と推論容易性が維持される
- 不変条件の追加（`ToolResolutionAggregate` の不変条件）が文書のみで完結し、実装影響は無い

## コンポーネント構成

### レイヤー / モジュール構成

```text
review-routing.md（純粋参照ファイル）
├── §2 設定（[rules.reviewing] の許容値定義）
│   └── tools の許容値: 外部CLI名 / "self" / "claude"(alias)
├── §4 ToolSelection（前処理を追加した本 Unit の主対象）
│   ├── 前処理1: AliasNormalization（"claude" → "self"）
│   ├── 前処理2: SelfBackcompatShim（末尾 self 暗黙補完）
│   └── 走査: configured_tools を先頭から走査、available_tools と一致確認
├── §5 PathSelection（self_review_forced / cli_missing_permanent 経路を§4と整合）
├── §6 FallbackPolicyResolution（§6-B 注記化により2行縮約）
│   ├── cli_runtime_error 行
│   └── cli_output_parse_error 行
│   （cli_missing_permanent 行は §4 前処理側に吸収）
└── §7 呼び出し形式（パス1/パス2 の文字列形式は維持）

review-flow.md（純粋参照ファイル）
└── パス1 → パス2 遷移記述を「ツール解決の延長」として読める表現に整合

review-flow-reference.md（変更可能性低）
└── §6 直接参照なし（grep 結果0件）→ 整合確認のみ、変更不要の見込み

defaults.toml（skills/aidlc/config/）
└── tools = ["codex"] にコメント注記を追加（defaults-A）
```

### コンポーネント詳細

#### `AliasNormalization`(前処理1, `review-routing.md §4` 内)

- **責務**: `[rules.reviewing].tools` の各エントリに対して `"claude" -> "self"` の単純置換を行う
- **依存**: なし（純粋関数）
- **公開インターフェース**:
  - `normalize(entries: List<string>) -> List<string>`: 各エントリを正規化した新規リストを返す
- **入出力例**:
  - `["claude"]` → `["self"]`
  - `["codex", "claude"]` → `["codex", "self"]`
  - `["codex"]` → `["codex"]`(no-op)

#### `SelfBackcompatShim`(前処理2, `review-routing.md §4` 内)

- **責務**: 正規化済みリスト内に `"self"` が一度も出現しない場合、暗黙的に末尾へ `"self"` を追加する
- **依存**: `AliasNormalization` の出力を入力とする（直列接続）
- **公開インターフェース**:
  - `apply(entries: List<string>) -> List<string>`: シム適用後のリストを返す
- **no-op 条件**: リスト内に `"self"` が一度でも出現する場合（位置・出現回数を問わない）
- **入出力例**:
  - `[]` → `["self"]`(末尾追加 = 単独追加。**`tools = []` の特殊値も本シムの自然な適用結果として `["self"]` に解決される**。従来「セルフ直行シグナル」と特殊扱いされていた挙動を、シム適用結果と統一的に扱う)
  - `["codex"]` → `["codex", "self"]`(末尾追加)
  - `["self"]` → `["self"]`(no-op)
  - `["codex", "self"]` → `["codex", "self"]`(no-op)
  - `["self", "codex"]` → `["self", "codex"]`(no-op、末尾以外配置でも適用済み判定)

#### `ToolSelectionScan`(走査ロジック、`review-routing.md §4` 内、現行維持)

- **責務**: 前処理済みリストを先頭から走査し、`available_tools` と最初に一致したツール名を返す
- **依存**: `SelfBackcompatShim` の出力を入力とする
- **公開インターフェース**:
  - `select(entries: List<string>, available: List<string>) -> ToolSelectionResult`
- **特殊規則**:
  - `"self"` エントリは `available_tools` チェックを skip する（常時 available と扱う）。ただし `selected_path` 決定時の意味は「セルフレビュー（パス 2）= サブエージェント呼び出し」であり、外部 CLI ツール名ではない
  - 走査結果が `"self"` のみで構成される場合は `self_review_forced=true` シグナルを出力し、**`tool_name=none` を返す**（パス 2 はサブエージェント呼び出しで CLI ツール名は不要のため、`review-routing.md §1` 不変条件 (1) 「`selected_path=3 → tool_name=none`」と整合する形で「パス 2 でも `tool_name=none`」とする）
  - 走査で先頭が `"self"` 以外の外部 CLI ツール名にヒットした場合は `tool_name="<その名前>"`(パス 1)
  - どれも一致しない場合は `cli_missing_permanent`(現状の §4 で `"self"` を除外した残りが一致しない場合)
- **`tool_name` の値域（明示）**:
  - `selected_path=1`(外部 CLI 利用) → `tool_name="<外部 CLI 名>"`
  - `selected_path=2`(セルフ) → `tool_name=none`(走査ヒットが `"self"` であっても `none` を返す)
  - `selected_path=3`(ユーザー直行) → `tool_name=none`(現行維持)

#### `§6 FallbackPolicyResolution`(注記化、実装時に責務分離注記方式へ確定)

- **責務**: `cli_missing_permanent` / `cli_runtime_error` / `cli_output_parse_error` の対応ポリシーを定義
- **改訂内容（コードレビュー指摘#2 対応で確定）**: 既存の表 3 行はそのまま維持する。`cli_missing_permanent` 行を削除すると §1 不変条件 (3) `required → on_cli_missing=prompt_user_choice` および (4) `recommend → on_cli_missing=fallback_to_self` の参照が壊れるため、行は維持しつつ責務分離注記による論理的吸収を実現する
- **§4 への参照（責務分離注記）**: 表の冒頭で「`cli_missing_permanent` フラグの**発生検出**は §4 ToolSelection 前処理（AliasNormalization + SelfBackcompatShim）の結果として行う。本表は発生したフラグへの**対応ポリシー**を定義（責務分離）」と明示。これにより「ツール解決順序の延長として self に降りる」表現が §6 fallback_to_self の動作と等価であることを明文化

#### `§5 PathSelection 改訂方針`(指摘#2 対応)

- **改訂内容（計画書 Phase 1 ステップ 3 / 設計判断記録に基づく確定）**:
  - **表のフォーマット**: 現行 6 行（`disabled` / `required` × 4 状態 / `recommend` × 3 状態）を**そのまま維持**。行の追加・削除は行わない
  - **説明欄の調整**: 各行の「状態」列で参照される `self_review_forced` / `cli_missing_permanent` の発生経路を、改訂版 §4 の前処理（AliasNormalization + SelfBackcompatShim + ToolSelectionScan）と整合する文言に書き換える
    - `self_review_forced`: 「ToolSelection の前処理結果として `["self"]` が解決された場合に出力されるシグナル」と明記
    - `cli_missing_permanent`: 「`configured_tools` から `"self"` を除外した残りが `available_tools` と一致しない場合に発生」と明記
  - **`tool_name` の値域**: 改訂版 §4 の `ToolSelectionScan` 特殊規則に従い、`selected_path=2` 時も `tool_name=none` であることを §5 表または前後注記で明示
- **行 vs 列の責務**: 行は `review_mode × 状態` の組合せ（純粋関数の入力空間）、列は `selected_path` / `skip_reason_required` の出力（純粋関数の出力空間）。本責務分離は現行から変更しない

## インターフェース設計

### 設定インターフェース（`[rules.reviewing].tools`）

#### 許容値（`review-routing.md §2`）

- **型**: `List<string>`
- **許容エントリ**:
  - 外部 CLI 名（例: `"codex"` / `"claude-code"` 等の `available_tools` で登録されたもの）
  - `"self"`(セルフレビュー = サブエージェント方式 / インライン方式での自己評価)
  - `"claude"`(`"self"` への alias、ToolSelection 入口で正規化)
- **デフォルト**: `["codex"]`(暗黙シムにより実質 `["codex", "self"]` 相当)
- **特殊値**: `[]`(空リスト) は「シム適用結果 `["self"]` 相当」として `self_review_forced` を出力

### `ReviewRoutingDecision` インターフェース（`review-routing.md §1`、現行維持）

- 既存の論理インターフェース契約は変更しない
- 内部実装の `ToolSelection` 部分（前処理追加）のみ改訂

### 呼び出し形式（`review-routing.md §7`、現行維持）

- パス 1: `skill="reviewing-[stage]", args="[対象ファイル] 優先ツール: [tool]"`
- パス 2: `skill="reviewing-[stage]", args="self-review [対象ファイル]"`
- 注記追加: 「パス 1 → パス 2 の遷移は ToolSelection の自然な延長として読み替えられる」

## 処理フロー概要

### ツール解決フロー（改訂版 `review-routing.md §4` 内部処理）

**ステップ**:

1. `[rules.reviewing].tools`(`configured_tools`) を入力として受け取る
2. **前処理1（AliasNormalization）**: 各エントリに `"claude" -> "self"` 正規化を適用
3. **前処理2（SelfBackcompatShim）**: 正規化済みリスト内に `"self"` が一度も出現しない場合は末尾追加、出現する場合は no-op
4. **走査（ToolSelectionScan）**: 前処理済みリストを先頭から走査し、`available_tools` と最初に一致したツール名を `tool_name` として確定
5. シグナル出力（指摘#1 対応で `tool_name` 値域を明示）:
   - 解決後リストが `["self"]` 単独 → `self_review_forced=true`、**`tool_name=none`**(パス 2 はサブエージェント呼び出しで CLI ツール名不要)
   - `"self"` を除外した残りが一致しない → `cli_missing_permanent=true`、`tool_name=none`(`§5/§6` で `selected_path=2/3` に振り分け)
   - 走査で外部 CLI ツール名にヒット → `tool_name="<その名前>"`(パス 1 へ)

**関与するコンポーネント**: `AliasNormalization` / `SelfBackcompatShim` / `ToolSelectionScan`

### 6 パターン擬似実行表（検証-A）

`review-routing.md` 末尾または独立セクションとして以下のテーブルを追加する。

| Pattern | configured_tools | After AliasNormalization | After SelfBackcompatShim | self_review_forced | tool_name (codex available 時) | selected_path (codex available 時) |
|---------|------------------|--------------------------|--------------------------|--------------------|-------------------------------|------------------------------------|
| A | `["codex"]` | `["codex"]` | `["codex", "self"]` | false | `"codex"` | 1 |
| B | `[]` | `[]` | `["self"]` | true | `none` | 2 |
| C | `["codex", "self"]` | `["codex", "self"]` | `["codex", "self"]`(no-op) | false | `"codex"` | 1 |
| D | `["self"]` | `["self"]` | `["self"]`(no-op) | true | `none` | 2 |
| E | `["claude"]` | `["self"]` | `["self"]`(no-op) | true | `none` | 2 |
| F (default) | 未設定 | `defaults.toml` の `["codex"]` 適用 → A と同等 | (defaults-A 採用のため A と同等) | false | `"codex"` | 1 |

**`tool_name` の値域（指摘#1 対応）**: `selected_path=2` 時は `tool_name=none`(走査が `"self"` にヒットしても、パス 2 はサブエージェント呼び出しで外部 CLI ツール名は不要のため)。**B/D/E は `selected_path=2` で `tool_name=none`**(前述ルール)。**A/C/F は `selected_path=1` で `tool_name="codex"`**(`selected_path=1` 時の外部 CLI ツール名)。

**補足**: codex 不在時は §6 縮約版の `cli_missing_permanent` 吸収ロジックにより `["codex", "self"]` の走査が `"self"` でヒットして `selected_path=2` に降りる（A / C / F 共通、`tool_name=none`)。

## データモデル概要

本 Unit はデータベース変更なし。設定ファイル（`.aidlc/config.toml` / `defaults.toml`）の TOML 形式は現行維持。

### 設定ファイル形式

- **形式**: TOML（`.aidlc/config.toml` / `defaults.toml`）
- **主要フィールド**:
  - `[rules.reviewing].tools`: `List<string>` - 上記「許容値」を参照

## 非機能要件（NFR）への対応

### パフォーマンス

- **要件**: Unit 定義 NFR「O(N) リスト走査で N≦数件のため影響なし」
- **対応策**: 前処理（alias 正規化 + シム適用）も O(N) で追加する。N≦数件のため計算量増加の影響なし

### セキュリティ

- **要件**: Unit 定義 NFR「影響なし」
- **対応策**: 文書改訂のみのため新規セキュリティ表面なし。既存の `exclude_patterns`(機密情報除外) は現行維持

### スケーラビリティ

- **要件**: Unit 定義 NFR「alias 機構は最小実装で将来の汎用化を妨げない」
- **対応策**: `AliasNormalization` を独立コンポーネントとして記述することで、将来 `"gemini"` 等の alias 追加時に同コンポーネントの拡張で対応可能

### 可用性

- **要件**: Unit 定義 NFR「既存設定の後方互換性を維持」
- **対応策**: 暗黙末尾 self 補完シムにより、既存 `tools = ["codex"]` 設定が変更なしで従来通り動作する。6 パターン擬似実行表のパターン A で動作確認済み

## 技術選定

- **言語**: 文書改訂のため対象外
- **フレームワーク**: 対象外
- **ライブラリ**: 対象外
- **データベース**: 対象外

## 実装上の注意事項

### 文書改訂時の注意

- **章番号統一**: 計画書「章番号の統一方針」に従い、現行 `review-routing.md` の章番号（§2 / §4 / §5 / §6 / §7）を維持
- **`review-flow.md` L11 の §6 参照**: §6 縮約後も「`fallback_policy` に従う」表現が破綻しないよう、注記を更新
- **`review-flow-reference.md` 整合確認**: §6 直接参照なし（grep 0 件）→ 変更不要を Phase 2 で確認し、`history` に明記。**ただし指摘#6 対応**: 表の「フォールバック」列の分類名（`CLI出力解析不能` / `CLI実行エラー` 等）が、§6 縮約後の `cli_runtime_error` / `cli_output_parse_error` 分類と論理的に整合していることを Phase 2 で必ず確認する（直接参照は 0 件だが、間接参照として表内の分類名が §6 と接続している）
- **`defaults.toml` コメント**: 1〜2 行の注記で「暗黙シムにより実質 `["codex", "self"]` 相当」を表現。過度な説明は避ける

### スコープ保護

- `skills/aidlc-setup/` 配下（`defaults.toml` / `config.toml.template`）の同期更新は本 Unit 対象外
- 同期未実施でも、暗黙シムで既存設定は従来通り動作する（パターン A 〜 F の動作確認で保証）
- 次サイクル以降で必要なら別 Issue 化（完了処理時にバックログ登録要否を判定）

### 後方互換性の保証

- 既存ダウンストリームプロジェクトの `.aidlc/config.toml` は変更不要（`tools = ["codex"]` のままで OK）
- 6 パターン擬似実行表のパターン A（`["codex"]`）が「シム適用 `["codex", "self"]` → codex available 時 selected_path=1 / 不在時 selected_path=2」と表現されることで、既存動作の論理的等価性を担保

## 不明点と質問（設計中に記録）

[Question] §6 縮約版で `cli_missing_permanent` 行を削除するが、§5 PathSelection の表で `cli_missing_permanent` 行（現行 L57-58）はどう扱うか？
[Answer] §5 の `cli_missing_permanent` 行は維持する（経路としては存在し続けるため）。§6 から削除されるのは「§6 が `cli_missing_permanent` の `fallback_policy` を別表として持つ」という重複部分で、§4 ToolSelection 前処理で発生 → §5 で `selected_path=2/3` の振り分け、という流れに統一する。§6 の縮約版冒頭に「`cli_missing_permanent` の処理は §4 で吸収され、§5 の表で `selected_path` が決定される」旨を注記する。

[Question] `available_tools` リストへの `"self"` の含め方は？
[Answer] `"self"` は `available_tools` チェックを skip する（常時 available と扱う）と §4 で明記する。これは `ToolSelectionScan` の特殊規則として記述する。`available_tools` リスト自体には `"self"` を含めない（呼び出し側の構成負担を避ける）。

[Question] defaults-A 選択により aidlc-setup の `tools = ["codex"]` テンプレートと skill の `defaults.toml` が「実装注釈の有無」で一見差分が出るが問題ないか？
[Answer] 問題ない。`skills/aidlc/config/defaults.toml` は AI-DLC スキル本体のデフォルト値、`skills/aidlc-setup/` 配下のテンプレートはダウンストリーム生成用テンプレートで、注釈の有無は機能差ではない（暗黙シムで両者の挙動は等価）。次サイクルで aidlc-setup 側にも注釈を同期するかは別 Issue 検討課題とする。
