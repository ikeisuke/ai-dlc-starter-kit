# AI レビューのルーティング判定

AI レビューの判定テーブル集（スキル名・focus・処理パス・CLI ツール）。純粋参照ファイルで `ReviewRoutingDecision` を呼び出し側に提供する。実行手順は持たない。他ドキュメントへの依存なし（呼び出し側のみが本ファイルを参照する一方向構造）。

## 1. 論理インターフェース契約

```text
Input  ReviewRoutingInput: caller_context (§3 の 9 種) / review_mode (required|recommend|disabled) /
                           automation_mode (manual|semi_auto) / configured_tools[] / available_tools[] /
                           tools_runtime_status (ok|cli_runtime_error|cli_output_parse_error)

Output ReviewRoutingDecision:
  selected_path: 1|2|3                    # 1=外部CLI / 2=セルフ / 3=ユーザー直行
  skill_name, focus[]                      # §3
  tool_name: string|none                   # §4（パス 2/3 は none）
  fallback_policy: { on_cli_missing, on_runtime_error, on_parse_error }  # §6
  skip_reason_required: bool               # required でユーザー承認に落ちるとき true
  user_rejection_allowed: bool             # semi_auto ∧ recommend のとき false
```

**合成順序**: `CallerContextMapping` → `ToolSelection` → `PathSelection` → `FallbackPolicyResolution`。**不変条件**: (1) `selected_path∈{2,3} → tool_name=none` / (2) `selected_path=1 → tool_name≠none` / (3) `required → on_cli_missing=prompt_user_choice` / (4) `recommend → on_cli_missing=fallback_to_self` / (5) `semi_auto ∧ recommend → user_rejection_allowed=false` / (6) 純粋関数的（同一入力 → 同一出力）。

## 2. 設定

`.aidlc/config.toml` の `[rules.reviewing]`: `mode`（デフォルト `recommend`、`required` / `recommend` / `disabled`）/ `tools`（デフォルト `["codex"]`、優先順位リスト = フォールバック順序）/ `exclude_patterns`（機密情報除外、デフォルトに追加）。

**`tools` の許容エントリ**: 外部 CLI 名（例: `"codex"`)、`"self"`(セルフレビュー = サブエージェント方式 / インライン方式での自己評価)、`"claude"`(`"self"` への alias)。**特殊値**: `[]`(空リスト) は許容される（具体的な解決経路と `self_review_forced` の出力動作は §4 参照、本セクションは設定サマリのみ提供）。

**デフォルト除外**: `.env*`, `*.key`, `*.pem`, `credentials.*`, `*secret*`（照合・通知は呼び出し側の手順で実施）。

## 3. CallerContext マッピング

| caller_context | skill_name | focus |
|---------------|-----------|-------|
| 計画承認前 | `reviewing-construction-plan` | architecture |
| 設計レビュー | `reviewing-construction-design` | architecture |
| コード生成後 | `reviewing-construction-code` | code, security |
| 統合とレビュー | `reviewing-construction-integration` | code |
| Intent 承認前 | `reviewing-inception-intent` | inception |
| ストーリー承認前 | `reviewing-inception-stories` | inception |
| Unit 定義承認前 | `reviewing-inception-units` | inception |
| デプロイ計画承認前 | `reviewing-operations-deploy` | architecture |
| PR マージ前 | `reviewing-operations-premerge` | code, security |

## 4. ツール選択（ToolSelection）

`configured_tools` に対して以下を直列に適用する純粋関数:

**前処理1（AliasNormalization）**: 各エントリに `"claude" -> "self"` の単純置換を適用（最小実装、`"self"` / `"claude"` 以外の汎用エイリアス拡張は対象外）。

**前処理2（SelfBackcompatShim）**: 正規化済みリスト内に `"self"` が一度も出現しない場合、暗黙的に末尾へ `"self"` を追加する。`"self"` が一度でも出現する場合（位置・出現回数を問わない）は no-op。これにより既存設定（`tools = ["codex"]` 等）は実質 `["codex", "self"]` 相当として後方互換性を維持する。`tools = []` も本シムの自然な適用結果として `["self"]` に解決され、従来「セルフ直行シグナル」と特殊扱いされていた挙動と統一的に扱う。

**走査（ToolSelectionScan）**: 前処理済みリストを先頭から走査し、`available_tools` と最初に一致したツール名を返す。`"self"` エントリは `available_tools` チェックを skip する（常時 available と扱う）。

**`tool_name` の値域**:

- 解決後リストが `["self"]` 単独 → `tool_name=none` + `self_review_forced=true`(パス 2 はサブエージェント呼び出しで CLI ツール名は不要、不変条件 (1) に整合)
- 走査で外部 CLI 名にヒット → `tool_name="<その名前>"`(パス 1)
- `"self"` を除外した残りが `available_tools` と一致しない → `tool_name=none` + `cli_missing_permanent=true`(§6 の対応ポリシーへ)
- **複合状態**: `["codex", "self"]` 等のリストで外部 CLI が `available_tools` と一致せず走査が `"self"` までスライドしてヒットするケースは、`tool_name=none` + `cli_missing_permanent=true` の複合状態として扱う（走査自体は `"self"` で完結するが、外部 CLI 不在のフラグも併発する）。`recommend` モードでは §6 `fallback_to_self` で `selected_path=2`、`required` モードでは §6 `prompt_user_choice` でユーザー判断（§5 / §6 / §8 補足参照）

## 5. 処理パス決定（PathSelection）

| review_mode | 状態 | selected_path | skip_reason_required |
|-------------|-----|---------------|---------------------|
| `disabled` | - | 3 | false |
| `required` | 非 none ∧ `ok` | 1 | false |
| `required` | 非 none ∧ runtime/parse error | 1 → §6（最終 3 なら true） | 条件付 |
| `required` | `self_review_forced` | 2（失敗時 §6 で 3） | 3 なら true |
| `required` | `cli_missing_permanent` | §6 `prompt_user_choice` → 2/3 | true |
| `recommend` | 非 none ∧ `ok` | 1 | false |
| `recommend` | `self_review_forced` | 2 | false |
| `recommend` | `cli_missing_permanent` | §6 `fallback_to_self` → 2 | false |

**`self_review_forced` / `cli_missing_permanent` の発生経路**: いずれも §4 ToolSelection の前処理（AliasNormalization + SelfBackcompatShim）と走査結果から導出される。`self_review_forced` は前処理結果が `["self"]` 単独になったときに出力。`cli_missing_permanent` は `"self"` を除外した残りが `available_tools` と一致しないときに出力。

**セルフレビュー（パス 2）失敗時の遷移**: `required` × `self_review_forced` 行で「失敗時 §6 で 3」と記載される失敗とは、セルフレビュー実行時の `cli_runtime_error` 相当のランタイムエラー（サブエージェント起動失敗 / 応答異常 等）を指す。§6 の `cli_runtime_error` 行のポリシー（`required` 列 `retry_1_then_user_choice`)を再帰適用し、最終的に `selected_path=3` に降りる場合は `skip_reason_required=true` となる。

**`tool_name` の値域**: `selected_path=1` → `tool_name="<外部 CLI 名>"`(非 none)。`selected_path=2` / `selected_path=3` → `tool_name=none`(走査ヒットが `"self"` であっても `none` を返す。不変条件 (1) と整合)。

**user_rejection_allowed**: `semi_auto ∧ recommend` のみ `false`、他は `true`（`disabled` は概念外）。

## 6. エラーフォールバック対応表（FallbackPolicyResolution）

`cli_missing_permanent` フラグの**発生検出**は §4 ToolSelection 前処理（AliasNormalization + SelfBackcompatShim）の結果として行われる（§4 参照）。本表は発生したフラグへの**対応ポリシー**を定義する（責務分離）。`cli_runtime_error` / `cli_output_parse_error` は CLI 実行時のエラー検出で発生する。

| エラー種別 | recommend | required |
|-----------|----------|---------|
| `cli_missing_permanent` | `fallback_to_self` → 2 | `prompt_user_choice` → 2/3（`skip_reason_required=true`） |
| `cli_runtime_error` | `retry_1_then_prompt`（再試行 1 → ユーザー確認） | `retry_1_then_user_choice`（再試行 1 → ユーザー選択、`skip_reason_required=true`） |
| `cli_output_parse_error` | `fallback_to_self` → 2 | `prompt_user_choice` → 2/3（`skip_reason_required=true`） |

**ツール解決順序の延長としての fallback**: `cli_missing_permanent` の `fallback_to_self` は、§4 で `["codex", "self"]` 相当に解決されたリストを走査する際の「`codex` 不在 → `self` ヒット」と等価に動作する。`fallback_to_self` はこの自然な走査の `recommend` モード時のフォールバック表現として機能する（`required` モードはユーザー判断を挟む）。

`skip_reason_required=true` 時のスキップ理由検査（空文字・禁止パターン）は呼び出し側の手順で実施。

## 7. 呼び出し形式

- パス 1: `skill="reviewing-[stage]", args="[対象ファイル] 優先ツール: [tool]"`
- パス 2: `skill="reviewing-[stage]", args="self-review [対象ファイル]"`
- `focus` は §3 の値を呼び出しコンテキストに付与

**パス 1 → パス 2 の遷移**: §4 のツール解決順序（AliasNormalization + SelfBackcompatShim 適用後リスト）の自然な延長として読める。`["codex", "self"]` 相当のリストで `codex` 走行失敗 → `self` ヒット → パス 2 という流れは、§6 `fallback_to_self` の動作と等価。

## 8. ToolSelection 解決結果テーブル（動作確認 6 パターン）

`[rules.reviewing].tools` の代表的な設定パターンに対する §4 ToolSelection の解決結果を以下に示す。シム適用後リスト → 走査結果 → `selected_path` の対応関係を確認する。

| Pattern | configured_tools | After AliasNormalization | After SelfBackcompatShim | self_review_forced | tool_name (codex available 時) | selected_path (codex available 時) |
|---------|------------------|--------------------------|--------------------------|--------------------|-------------------------------|------------------------------------|
| A | `["codex"]` | `["codex"]` | `["codex", "self"]` | false | `"codex"` | 1 |
| B | `[]` | `[]` | `["self"]` | true | `none` | 2 |
| C | `["codex", "self"]` | `["codex", "self"]` | `["codex", "self"]`(no-op) | false | `"codex"` | 1 |
| D | `["self"]` | `["self"]` | `["self"]`(no-op) | true | `none` | 2 |
| E | `["claude"]` | `["self"]` | `["self"]`(no-op) | true | `none` | 2 |
| F (default) | 未設定 | `defaults.toml` の `["codex"]` 適用 → A と同等 | A と同等 | false | `"codex"` | 1 |

**`tool_name` の値域**: `selected_path=2` 時は `tool_name=none`(走査が `"self"` にヒットしても、パス 2 はサブエージェント呼び出しで外部 CLI ツール名は不要のため、不変条件 (1) と整合)。`selected_path=1` 時は外部 CLI ツール名（A/C/F は `"codex"`)。

**codex 不在時の挙動**: §6 `cli_missing_permanent` 対応ポリシーが適用される。A / C / F では `["codex", "self"]` 相当のリストで `codex` 不在 → `"self"` ヒットにより `selected_path=2`(`recommend` モード `fallback_to_self`)、または `required` モードでは `prompt_user_choice` でユーザー判断（`tool_name=none`）。

**後方互換性の保証**: 既存ダウンストリームプロジェクトの `[rules.reviewing].tools = ["codex"]` 設定（パターン A）は、暗黙シムにより実質 `["codex", "self"]` として動作する。設定変更なしで従来動作を維持する。
