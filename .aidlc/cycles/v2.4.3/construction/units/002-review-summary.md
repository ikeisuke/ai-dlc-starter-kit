# レビューサマリ: Unit 002 - レビューツール設定への self 正式統合と後方互換シム（#611）

## 基本情報

- **サイクル**: v2.4.3
- **フェーズ**: Construction
- **対象**: Unit 002 - レビューツール設定への self 正式統合と後方互換シム（#611）
- **対象ファイル**:
  - `.aidlc/cycles/v2.4.3/design-artifacts/domain-models/unit_002_review_tools_self_integration_domain_model.md`
  - `.aidlc/cycles/v2.4.3/design-artifacts/logical-designs/unit_002_review_tools_self_integration_logical_design.md`

---

## Set 1: 2026-04-28（設計レビュー）

- **レビュー種別**: 設計レビュー（Phase 1）
- **使用ツール**: self-review(skill) / general-purpose subagent（Codex usage limit のためフォールバック、`review-routing.md §6` `cli_runtime_error → retry_1_then_user_choice` 経由でユーザー選択）
- **反復回数**: 2（反復1: 6件、反復2: 0件で承認可能判定）
- **結論**: 指摘対応判断完了（合計 6件 全件「修正する」で対応、反復2回目で構造的指摘ゼロを確認）

### 反復1 指摘（6件 / 中2 低4）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | 6 パターン擬似実行表（B/D/E）で `tool_name=none` と表記、`ToolSelectionScan` 特殊規則と `ToolResolutionService` 責務記述で `tool_name` の値域（`"self"` か `none` か）が統一されていない | 修正済み（論理設計 `ToolSelectionScan` 特殊規則・`tool_name の値域` を追加、6 パターン擬似実行表に注記、処理フロー概要シグナル出力で `selected_path=2 → tool_name=none` を明示。ドメインモデル `ToolResolutionService` 責務にも明記） | - |
| 2 | 中 | §5 PathSelection 改訂方針が論理設計内に具体化されていない（行を維持するか説明欄のみ調整するか曖昧）、計画書 Phase 1 ステップ 3 の方針確定が未反映で Phase 2 実装時の解釈ぶれリスク | 修正済み（論理設計 §コンポーネント詳細 に「§5 PathSelection 改訂方針」小節を新規追加、表 6 行は維持、説明欄を改訂版 §4 と整合する文言に調整、`tool_name` 値域の明示も §5 に反映） | - |
| 3 | 低 | ドメインモデル `ConfiguredTool`（エンティティ）と `ToolName`（値オブジェクト）の関係（`ConfiguredTool.name` の型）が明示されておらず、文書改訂主体の Unit に対して過剰モデル化の懸念 | 修正済み（`ToolName` 値オブジェクトを廃止、`ConfiguredTool.name` を `string` 型として扱い、論理設計の `List<ToolName>` も `List<string>` に修正、過剰モデル化を回避） | - |
| 4 | 低 | `[]` 特殊値の挙動が SelfBackcompatShim の自然な適用結果から導かれることが明示されておらず、Phase 2 実装者の理解を妨げる可能性 | 修正済み（論理設計 `SelfBackcompatShim` 入出力例の `[]` → `["self"]` 行に注記追加、「シムの自然な適用結果として `["self"]` に解決される」「従来『セルフ直行シグナル』と特殊扱いされていた挙動を、シム適用結果と統一的に扱う」と明示） | - |
| 5 | 低 | §設計判断記録 §6 改訂方針の「実態調査結果」で grep 検索パターンと集計範囲の対応が論理設計内に明示されていない、トレース性が低い | 修正済み（論理設計 §設計判断記録 §6 改訂方針に grep パターン定義（`(review-routing\.md.*§6\|FallbackPolicyResolution\|fallback_to_self\|cli_missing_permanent\|cli_runtime_error\|cli_output_parse_error)`）と集計結果（review-flow.md: 1件 / review-flow-reference.md: 0件）を明示） | - |
| 6 | 低 | `review-flow-reference.md` 整合確認が「§6 直接参照なし → 変更不要」と即断されているが、表の「フォールバック」列の分類名（`CLI出力解析不能` / `CLI実行エラー`）と §6 縮約後分類（`cli_runtime_error` / `cli_output_parse_error`）の論理的整合確認が必要 | 修正済み（論理設計 §実装上の注意事項 §文書改訂時の注意 の「`review-flow-reference.md` 整合確認」項目に「フォールバック列分類名と §6 縮約後分類の論理整合を Phase 2 で必ず確認する」を追記） | - |

### 反復2 指摘（0件）

すべての反復1指摘が反映済み。新規矛盾・不整合なし。ドメインモデルと論理設計の相互整合性、Phase 2 実装者の解釈ぶれ可能性なし。

### シグナル

- `review_detected`: true（反復1で6件検出）
- `deferred_count`: 0
- `resolved_count`: 6
- `unresolved_count`: 0
- `auto_approved`: true 候補（フォールバック条件非該当、`semi_auto`）

### フォールバック記録

- **イベント**: Codex CLI ランタイムエラー（usage limit / API rate limit、April 29 復旧予定）
- **`review-routing.md §6` 適用**: `cli_runtime_error` × `required` → `retry_1_then_user_choice`
- **ユーザー選択**: セルフレビュー（パス2 / `selected_path=2`）
- **代替手段**: general-purpose サブエージェント方式（読み取り専用の指示テンプレート）

### Phase 1 設計判断確定（Phase 1 設計レビューで A/B 確定とした 3 箇所）

- **§6 改訂方針**: §6-B（注記化）採用 — review-flow.md / review-flow-reference.md からの §6 grep 集計 1 件（≦2 件）に基づき注記化。**実装時に「責務分離注記による吸収方式」に確定**（コードレビュー指摘#2 対応、表 3 行維持 + 冒頭注記で発生検出/対応ポリシーの責務分離を明示、不変条件 (3)/(4) を破壊しない）
- **defaults.toml 改訂方針**: defaults-A（現状維持 + 注記）採用 — `aidlc-setup/` 配下に `tools = ["codex"]` を含むテンプレート 2 ファイル存在するが、本 Unit のスコープ保護のため defaults-A に上書き判定（aidlc-setup 同期は次サイクル別 Issue 候補）
- **検証方針**: 検証-A（擬似実行表）採用 — `tests/migration/` 配下のみで review-routing 関連 bats インフラなし、文書改訂主体に整合

---

## Set 2: 2026-04-28（コードレビュー）

- **レビュー種別**: コードレビュー（Phase 2 / focus: code, security）
- **使用ツール**: self-review(skill) / general-purpose subagent（Codex usage limit のためフォールバック継続）
- **反復回数**: 3 + 反復後修正1（反復1: 3件、反復2: 3件、反復3: 1件、反復後修正で全件解消）
- **結論**: 指摘対応判断完了（合計 7 件 全件「修正する」で対応、最終的に未解消ゼロ）

### 反復1 指摘（3件 / 低3、N/A 1）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 低 | review-routing.md §4 走査ロジック L57-L59 の三分岐で、`["codex", "self"]` 構成かつ codex 不在のケースが境界条件として読み取りづらい（`tool_name=none` + `cli_missing_permanent=true` の複合状態） | 修正済み（§4 値域記述に「複合状態」項目を追加、recommend / required モード別の §6 遷移先を明記） | - |
| 2 | 低 | review-routing.md §6 表 3 行残存と論理設計「2 行縮約」表現の表面的不一致（実態は責務分離注記による吸収で等価） | 修正済み（論理設計 §設計判断記録 §6 改訂方針 と §コンポーネント詳細 §6 FallbackPolicyResolution の文言を「責務分離注記による吸収方式」に書き換え、不変条件 (3)/(4) 維持を理由として明記） | - |
| 3 | 低 | review-routing.md §2 と §4 の `tools=[]` 説明の重複（DRY 原則） | 修正済み（§2 を「許容エントリ + 特殊値（詳細は §4 参照）」に簡素化、`tools=[]` 意味論詳細は §4 SelfBackcompatShim に集約） | - |
| 4 | N/A | 文書改訂主体のため OWASP / 認証・認可 / 依存脆弱性 / ログ・監視 / ネットワーク / セキュアデザインの直接該当なし。defaults.toml に機密情報混入なし、`exclude_patterns` の機密情報除外と矛盾なし | N/A | - |

### 反復2 指摘（3件 / 中1 低2）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 中 | 論理設計 L204 の `selected_path=1` 例示誤記（B/D/E は `selected_path=2` のため例として不適切） | 修正済み（「B/D/E は `selected_path=2` で `tool_name=none`、A/C/F は `selected_path=1` で `tool_name="codex"`」に修正） | - |
| 2 | 低 | review-routing.md §8 表ヘッダの `selected_path` 列に条件明示なし（`tool_name (codex available 時)` と非対称） | 修正済み（`selected_path (codex available 時)` にリネーム、`tool_name` 列との命名一貫性確保） | - |
| 3 | 低 | review-routing.md §5 `required × self_review_forced` 失敗時の遷移が §6 表に対応行なし、境界条件曖昧 | 修正済み（§5 表直後に「セルフレビュー（パス 2）失敗時の遷移」セクションを追加、`cli_runtime_error` 行のポリシー再帰適用と `skip_reason_required=true` の扱いを明示） | - |

### 反復3 指摘（1件 / 低1）

| # | 重要度 | 内容 | 対応 | バックログ |
|---|--------|------|------|-----------|
| 1 | 低 | review-routing.md §8 ヘッダ修正が論理設計の擬似実行表ヘッダに同期していない（列名差分） | 修正済み（論理設計の擬似実行表ヘッダを `selected_path (codex available 時)` にリネーム、両ファイル間で列名統一） | - |

### 反復後修正の確認

反復 3 の指摘は「ヘッダ列名の統一」のみで内容変更なし。新規問題発生リスクなし。3 回反復制限内で全件「修正する」対応により未解消ゼロを実現。

### シグナル

- `review_detected`: true（反復1で3件、反復2で3件、反復3で1件検出）
- `deferred_count`: 0
- `resolved_count`: 7（指摘実体への修正対応）
- `unresolved_count`: 0
- `auto_approved`: true 候補（フォールバック条件非該当、`semi_auto`）

### フォールバック記録

- Set 1 と同じ（Codex usage limit による継続的セルフレビュー）

---

## Set 3: 2026-04-28（統合レビュー）

- **レビュー種別**: 統合レビュー（Phase 2 完了時 / focus: code）
- **使用ツール**: self-review(skill) / general-purpose subagent（Codex usage limit のためフォールバック継続）
- **反復回数**: 1（指摘0件で承認可能判定）
- **結論**: 指摘0件（設計→実装→検証の追跡可能性 / 完了条件達成 / Issue #611 解消 / 後方互換性すべて整合）

### 反復1 指摘（0件）

設計→実装→検証の統合的整合性が確認された。具体的な確認事項:

- ドメインモデルのエンティティ・値オブジェクト・集約・ドメインサービスがすべて review-routing.md §4 の AliasNormalization / SelfBackcompatShim / ToolSelectionScan として実装に対応
- 論理設計の §6 責務分離注記方式が review-routing.md §6 冒頭注記で「発生検出は §4 / 対応ポリシーは §6」と明記済み
- §5 PathSelection 表 6 行維持 + 説明欄の §4 整合が実装に反映
- §8 6 パターン擬似実行表（A〜F）が review-routing.md §8 と論理設計擬似実行表で完全一致
- 計画レビュー（反復3、unresolved_count=0）/ 設計レビュー（反復2、6件全件解消）/ コードレビュー（反復3 + 反復後修正、7件全件解消）すべて履歴記録から確認
- markdownlint 7ファイル0件 / grep 検証 3 系統（fallback_to_self 9箇所 / self-review・self_review_forced 8箇所 / claude alias 4箇所）すべて整合
- 計画書「完了条件チェックリスト」機能要件 11 項目および Issue #611 終了条件 5 項目すべて達成
- 不変条件 (1)〜(6)（特に (1) の `selected_path∈{2,3} → tool_name=none` 拡張）が §1 / §4 / §5 / §8 で一貫して維持
- 後方互換性: パターン A（`["codex"]`）が「シム適用 → `["codex", "self"]` → codex available 時 selected_path=1 / tool_name="codex"」で従来動作維持を保証

### シグナル

- `review_detected`: false
- `deferred_count`: 0
- `resolved_count`: 0
- `unresolved_count`: 0
- `auto_approved`: true 候補（フォールバック条件非該当、`semi_auto`）

### フォールバック記録

- Set 1 / 2 と同じ（Codex usage limit による継続的セルフレビュー）

---
