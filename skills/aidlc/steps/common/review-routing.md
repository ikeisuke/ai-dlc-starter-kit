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

**合成順序**: `CallerContextMapping` → `ToolSelection` → `PathSelection` → `FallbackPolicyResolution`。**不変条件**: (1) `selected_path=3 → tool_name=none` / (2) `selected_path=1 → tool_name≠none` / (3) `required → on_cli_missing=prompt_user_choice` / (4) `recommend → on_cli_missing=fallback_to_self` / (5) `semi_auto ∧ recommend → user_rejection_allowed=false` / (6) 純粋関数的（同一入力 → 同一出力）。

## 2. 設定

`.aidlc/config.toml` の `[rules.reviewing]`: `mode`（デフォルト `recommend`、`required` / `recommend` / `disabled`）/ `tools`（デフォルト `["codex"]`、優先順位リスト、`[]` はセルフ直行シグナル）/ `exclude_patterns`（機密情報除外、デフォルトに追加）。

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

- `configured_tools=[]` → `tool_name=none` + `self_review_forced`（パス 2 直行）
- `configured_tools` を先頭から走査し `available_tools` に最初に一致したツール → その名前
- どれも一致しない → `tool_name=none` + `cli_missing_permanent`

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

**user_rejection_allowed**: `semi_auto ∧ recommend` のみ `false`、他は `true`（`disabled` は概念外）。

## 6. エラーフォールバック対応表（FallbackPolicyResolution）

| エラー種別 | recommend | required |
|-----------|----------|---------|
| `cli_missing_permanent` | `fallback_to_self` → 2 | `prompt_user_choice` → 2/3（`skip_reason_required=true`） |
| `cli_runtime_error` | `retry_1_then_prompt`（再試行 1 → ユーザー確認） | `retry_1_then_user_choice`（再試行 1 → ユーザー選択、`skip_reason_required=true`） |
| `cli_output_parse_error` | `fallback_to_self` → 2 | `prompt_user_choice` → 2/3（`skip_reason_required=true`） |

`skip_reason_required=true` 時のスキップ理由検査（空文字・禁止パターン）は呼び出し側の手順で実施。

## 7. 呼び出し形式

- パス 1: `skill="reviewing-[stage]", args="[対象ファイル] 優先ツール: [tool]"`
- パス 2: `skill="reviewing-[stage]", args="self-review [対象ファイル]"`
- `focus` は §3 の値を呼び出しコンテキストに付与
