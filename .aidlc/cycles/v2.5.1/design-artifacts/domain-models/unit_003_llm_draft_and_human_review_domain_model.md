# ドメインモデル: Unit 003 主因分類 LLM 下書き + 人間確認運用

## 概要

retrospective Issue 起票時の主因分類（プロダクト固有 / AI-DLC 固有 / 両方）と `skill_caused_judgment`（q1/q2/q3 + 引用文）を **`retrospective-drafter` subagent**（AI エージェント側で起動）が下書きし、Unit 002 の `retrospective_body_compose()` に prefill 入力として渡すための共有関数（`retrospective_prefill_hook` / `retrospective_update_hook`）と、起票後の人間確認運用（差分検出 + `[llm-diff]` コメント + `human_reviewed: true` 更新）と、機械検証 CLI（`retrospective-verify.sh`）が依拠するドメイン構造を定義する。

**責務境界の正本（指摘 #1, #6, #9 反映）**:

- AI エージェント手順（main agent）の責務: `retrospective-drafter` subagent 起動 / 30 秒タイムアウト判定 / AskUserQuestion fallback / 環境変数 export
- 本 Unit 003 hook 関数の責務: 環境変数経由のファイル読取 / スキーマ検証 / skip 判定 / I/O / `AIDLC_TEST_MODE` ガード / 差分計算 / `gh` 呼び出し orchestration

本ドメインモデルは hook 関数側の責務を構造化する。AI エージェント手順 documentation は `agents/retrospective-drafter.md` の「呼び出し例」セクションが正本。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2（コード生成）で行う。

---

## 値オブジェクト（Value Object）

### ProblemDraft

単一 Problem に対する主因分類 + `skill_caused_judgment` を表す不変な値オブジェクト。Intent §6.3 スキーマの 1 要素に対応。

- **属性**: `problem_id: integer`（≧ 1）/ `primary_cause: PrimaryCause`（enum）/ `primary_cause_reason: string`（短文 / 空文字列許容）/ `skill_caused_judgment: SkillCausedJudgment` / `confidence: ConfidenceLevel | undefined`
- **値域**: `primary_cause ∈ {"product", "ai_dlc", "both"}`
- **不変性**: 一度生成された値は変更されない
- **等価性**: 全属性の構造一致（problem_id 一致だけでは不十分 / 差分検出に使用）
- **fallback 既定値**: 全フィールドを空文字列または `"no"` で埋め、`primary_cause = "product"` を仮置き（Intent §6.3 fallback 規約準拠）

### PrimaryCause

主因分類 3 値の不変な enum 値オブジェクト。

- **値域**: `{"product", "ai_dlc", "both"}`
- **マッピング**: Intent §「成功基準」の 3 分類「プロダクト固有 / AI-DLC 固有 / 両方」に直接対応

### SkillCausedJudgment

skill 起因判定 q1/q2/q3 を表す不変な値オブジェクト。Intent §6.2 の `skill_caused_judgment` ブロックに対応。

- **属性**: `q1_answer: YesNo` / `q1_quote: string` / `q2_answer: YesNo` / `q2_quote: string` / `q3_answer: YesNo` / `q3_quote: string`
- **値域**: `YesNo ∈ {"yes", "no"}` / `quote` は任意文字列（`answer="no"` の場合は空文字列でも可）
- **不変条件**: 各 `qN_answer` と `qN_quote` のペアは個別に検証（answer=yes で quote=空 を許容するか否かは Phase 2 設計時に確定）

### ConfidenceLevel

LLM 推論の信頼度ヒントを表す不変な enum 値オブジェクト（任意）。

- **値域**: `{"high", "medium", "low", undefined}`
- **既定値**: 出力 YAML で省略時は `undefined`（hook 関数の処理に影響しない / 将来の自動分析メタデータ）

### LLMDraftResultStatus

LLM 下書きの結果ステータスを表す不変な enum 値オブジェクト。

- **値域**: `{"subagent_emitted", "schema_violation_fallback", "test_override", "skip_disabled", "skip_non_interactive", "subagent_unavailable"}`
- **stderr ログ対応**: 各値は `<level>\t<code>\t...` 形式の `<code>` フィールドに直接対応（`llm_draft_subagent_emitted` / `llm_draft_schema_violation` / `llm_draft_test_override` / `llm_draft_skip_disabled` / `llm_draft_skip_non_interactive` / `llm_draft_subagent_unavailable`）

### HumanReviewMarker

`human_reviewed` 状態を表す不変な値オブジェクト。Intent §6.4 の責任分担正本。

- **属性**: `value: bool`
- **不変条件**: Unit 002 起票時は `false` で生成される / Unit 003 update でのみ `true` に変更される（Unit 002 から `true` で生成することは禁止）
- **遷移**: `false → true` のみ許可（一方向）/ 同一 Issue で複数回呼ばれても `true` のまま不変（冪等性）

### LLMDiffSection

LLM 推論結果と人間確認結果の差分を表す不変な値オブジェクト。Issue コメント本体になる。

- **属性**: `markdown: string`
- **構造制約**:
  - 必ず `[llm-diff]` プレフィックスで始まる
  - 続く Markdown 構造で「LLM 推論結果」「人間確認後の最終結果」「差分一覧」の 3 セクションを含む
- **不変性**: 一度生成された値は変更されない / 後段の `gh issue comment` は本値の文字列をそのまま投稿
- **等価性**: `markdown` の文字列一致

### IssueUrl

起票済み Issue の URL を表す不変な値オブジェクト。

- **属性**: `value: string`
- **構造制約**:
  - `https://github.com/<owner>/<repo>/issues/<N>` 形式
  - 空文字列も許容（起票なし = no-op の合図 / `retrospective_update_hook` が exit 0 + skip 動作）
- **不変条件**: 検証は構造のみ（owner / repo の存在チェックは行わない / `gh` 側の責務）

### VerificationOutcome

`retrospective-verify.sh` の単一 Issue に対する検証結果を表す不変な値オブジェクト。

- **属性**: `state: VerificationState` / `issue_number: integer` / `title: string`
- **値域**: `VerificationState ∈ {"verified", "unverified", "skipped"}`（`VerificationStateClassifier` の判定ルールが正本）
  - `verified`: 末尾 YAML ブロック存在 + `human_reviewed: true` が抽出された
  - `unverified`: 末尾 YAML ブロック存在 + (`human_reviewed: false` / 非 bool / キー欠落 / YAML パース失敗) のいずれか
  - `skipped`: 本文に末尾 YAML ブロック自体が存在しない（旧仕様の Issue / v2.5.0 以前 / 検証対象外）
- **stdout 出力**: `<state>\t<issue_number>\t<title>` 形式

### EnvVarSnapshot

hook 関数が起動時にキャプチャする環境変数の集合を表す不変な値オブジェクト。production 侵食ガードと test mode 判定の入力。

- **属性**: `prefill_path: string | undefined` / `override_path: string | undefined` / `test_mode: bool`
- **由来**: `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` / `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` / `AIDLC_TEST_MODE`（`"1"` で `true`、それ以外は `false`）
- **不変条件**: hook 関数の処理開始時にスナップショットされ、関数内では変更されない（production 侵食検出のため）

---

## 集約（Aggregate）

### LLMDraft

LLM 下書きの単位（1 Issue 起票分の Problem 全件）を表す集約。`retrospective_prefill_hook` の処理対象。

- **集約ルート**: `LLMDraft`
- **属性**: `problem_drafts: ProblemDraft[]` / `result_status: LLMDraftResultStatus` / `source_path: string | undefined`（受け取った一時ファイルパス）
- **不変条件**:
  - `result_status = "subagent_emitted"` の場合、`problem_drafts` は Intent §6.3 スキーマ準拠（必須フィールド全て埋まっている）
  - `result_status = "schema_violation_fallback"` の場合、`problem_drafts` は空配列または部分埋め（Unit 002 の空 YAML フォールバックを誘発）
  - `result_status` が `skip_*` / `subagent_unavailable` / `test_override` の場合、`source_path` は適切な値に設定済み
- **責務**:
  - YAML テキストから `problem_drafts` のパース（`LLMDraftSchemaValidator` ドメインサービスに委譲）
  - stdout 出力（hook 関数の戻り値となる YAML）
- **集約境界**: Issue ごとに新規生成。複数 Issue 間で共有しない

### HumanReviewSession

人間確認運用の 1 サイクル（1 Issue に対する確認 → 差分判定 → 更新）を表す集約。`retrospective_update_hook` の処理対象。

- **集約ルート**: `HumanReviewSession`
- **属性**: `issue_url: IssueUrl` / `cycle: string` / `original_drafts: ProblemDraft[]`（Unit 002 が起票時に本文に埋め込んだ LLM 推論結果）/ `final_drafts: ProblemDraft[]`（人間確認後の最終結果 / `AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH` 環境変数経由 / 未設定時は `original_drafts` と同一扱い = 差分なし）/ `marker: HumanReviewMarker`
- **不変条件**:
  - `marker.value` の最終状態は `true`（差分の有無に関わらず、人間が確認した時点で `true`）
  - `original_drafts.length == final_drafts.length`（同一 Problem 集合上の確認）
  - `issue_url.value == ""` の場合は no-op で集約は処理されない（hook 関数が即 skip）
- **責務**:
  - 差分判定（`HumanReviewDiffComputer` ドメインサービスに委譲）
  - `[llm-diff]` コメント生成（`LLMDiffFormatter` ドメインサービスに委譲）
  - gh 操作 orchestration（`HumanReviewIssueWriter` ドメインサービスに委譲）
- **集約境界**: Issue 1 件 + cycle 1 サイクルで閉じる。Issue 間で共有しない

### VerificationReport

`retrospective-verify.sh` の実行結果を表す集約。

- **集約ルート**: `VerificationReport`
- **属性**: `cycle: string` / `outcomes: VerificationOutcome[]` / `strict: bool` / `dry_run: bool`
- **不変条件**:
  - `cycle` が空文字列でない（CLI で `--cycle` 必須化済み or デフォルト解決）
  - `outcomes` の数 = `gh issue list --label retrospective --milestone <cycle>` の結果数
- **派生**:
  - `exit_code: integer`: `outcomes` 内に `unverified` が 1 件以上あれば 1 / 全件 `verified` または 0 件なら 0 / `--strict` 時は `unverified + skipped > 0` で 1
- **責務**:
  - VerificationOutcome の集計
  - exit code の決定
  - stdout レポート生成
- **集約境界**: 1 回の CLI 実行で閉じる

---

## ドメインサービス

### LLMDraftSchemaValidator

LLM 下書き YAML が Intent §6.3 スキーマに準拠するか検証する。

- **入力**: YAML テキスト
- **出力**: `ValidationResult { ok: bool, parsed: ProblemDraft[], violations: string[] }`
- **検証ルール**:
  - 必須キー（`problem_drafts[].problem_id` / `primary_cause` / `primary_cause_reason` / `skill_caused_judgment.{q1,q2,q3}_{answer,quote}`）の存在確認
  - 値域チェック（`primary_cause ∈ {product, ai_dlc, both}` / `qN_answer ∈ {yes, no}`）
  - 失敗時は `violations` に違反内容を記録（stderr 警告で利用）

### LLMDraftPathResolver

環境変数の優先順位 + `AIDLC_TEST_MODE` ガード + production 誤設定検出を担当する。

- **入力**: `EnvVarSnapshot`
- **出力**: `ResolvedSource { path: string | undefined, status: LLMDraftResultStatus, warning: string | undefined }`
- **優先順位ロジック（plan §「失敗 / fallback 経路の網羅」テーブル準拠）**:
  1. `test_mode == true` かつ `override_path != undefined` → `path = override_path` / `status = test_override`
  2. `test_mode == false` かつ `override_path != undefined` → `path = undefined` / `status = subagent_unavailable` / `warning = "llm_draft_override_in_production"`（OVERRIDE 値を無視）
  3. `prefill_path != undefined` → `path = prefill_path` / `status = subagent_emitted`（後続でスキーマ検証）
  4. それ以外 → `path = undefined` / `status` は呼び出し元コンテキストで決定（`disabled` / `skip_non_interactive` / `subagent_unavailable`）

### TestModeGuard

`AIDLC_TEST_MODE` の値検証と production 環境での OVERRIDE 単独設定検出を担当する。

- **入力**: `EnvVarSnapshot`
- **出力**: `GuardOutcome { test_mode: bool, production_misconfiguration: bool }`
- **責務**:
  - `AIDLC_TEST_MODE == "1"` のみ true（その他値は false）
  - `production_misconfiguration` は「test_mode = false かつ override_path != undefined」の場合に true（stderr `error\tllm_draft_override_in_production\t...` の発火条件）

### HumanReviewDiffComputer

LLM 推論結果（`original_drafts`）と人間確認後の最終結果（`final_drafts`）の差分を計算する。

- **入力**: `original_drafts: ProblemDraft[]` / `final_drafts: ProblemDraft[]`
- **出力**: `DiffResult { has_diff: bool, diff_per_problem: { problem_id: integer, fields: string[] }[] }`
- **比較ルール**:
  - 同一 `problem_id` 同士で全フィールド比較（`primary_cause` / `primary_cause_reason` / `skill_caused_judgment.{q1,q2,q3}_{answer,quote}` / `confidence`）
  - 差分があったフィールド名を `fields` に記録
  - `confidence` は LLM 推論メタデータ扱いだが、人間確認で「low → high」のような訂正があれば差分として扱う

### LLMDiffFormatter

`HumanReviewSession` の差分を Markdown コメントに変換する。

- **入力**: `HumanReviewSession`（特に `original_drafts` / `final_drafts` / `cycle`）+ `DiffResult`
- **出力**: `LLMDiffSection`（`[llm-diff]` プレフィックス付き Markdown）
- **構造**: 以下 3 セクションを順に出力
  1. `## LLM 推論結果`: `original_drafts` の YAML ブロック（コードフェンス）
  2. `## 人間確認後の最終結果`: `final_drafts` の YAML ブロック（コードフェンス）
  3. `## 差分一覧`: `DiffResult.diff_per_problem` を Markdown 表で（`problem_id` / `field` / `LLM 推論` / `人間確認後`）
- **不変条件**: `has_diff = false` の場合は `LLMDiffFormatter` を呼ばない（呼び出し元側の判定 / 空コメント投稿は禁止）

### HumanReviewIssueWriter

`gh issue edit` / `gh issue comment` / `gh issue edit --add-label` の orchestration を担当する。順序固定 + 失敗時の継続性を担保。

- **入力**: `HumanReviewSession` + `LLMDiffSection | undefined`
- **処理順序（plan R3 緩和策準拠）**:
  1. 差分ありの場合: `gh issue comment <N> --body <LLMDiffSection>` で `[llm-diff]` コメント追記
  2. コメント追記成功時のみ: `gh issue edit <N> --body-file <new_body>` で本文 update（`human_reviewed: false → true`）
  3. 本文 update 成功時のみ: `gh issue edit <N> --add-label human-reviewed` でラベル付与（任意 / 失敗時は warn のみ）
- **失敗時の挙動**:
  - 全失敗で exit 0 + stderr `warn\thuman_review_gh_*_failed\t...`（warn 種別はコマンド単位）
  - コメント失敗時: 本文 update / ラベル付与をスキップ（次回 retry に委ねる / R3 invariant）
- **冪等性**: 既に `human_reviewed: true` の Issue に対して呼ばれた場合、本文 update / コメント追記 / ラベル付与をすべてスキップ + `info\thuman_review_already_done\t...`

### VerificationScanner

`retrospective-verify.sh` の Issue 列挙と本文解析を担当する。

- **入力**: `cycle: string`
- **出力**: `VerificationOutcome[]`
- **処理**:
  1. `gh issue list --label retrospective --milestone <cycle> --state all --json number,title,body` で Issue 集合取得
  2. 各 Issue の本文から末尾 YAML ブロック（`mirror_state` + `human_reviewed`）を抽出
  3. `human_reviewed` の値で VerificationState を判定
- **失敗時**: `gh` コマンド失敗 → exit 1 + stderr `error\tverify_gh_unavailable\t...`（hook 関数群と同じ規約 / 引数系のみ exit 2）

### VerificationStateClassifier

抽出された YAML から `VerificationState` を判定する純粋関数的サービス。

- **入力**: 本文末尾 YAML 文字列
- **出力**: `VerificationState`
- **判定ルール**（指摘 #2 反映 / VerificationOutcome 定義との整合）:
  - 本文に末尾 YAML ブロック自体が存在しない → `skipped`（旧仕様の Issue / v2.5.0 以前 / 検証対象外）
  - YAML ブロック存在 + `human_reviewed: true` → `verified`
  - YAML ブロック存在 + `human_reviewed: false` または非 bool 値 → `unverified`
  - YAML ブロック存在 + `human_reviewed` キー欠落 → `unverified`（`retrospective` ラベル付きの Issue で必須キーが欠落 = 確認運用がスキップされている）
  - YAML パース失敗（不正な YAML 構造）→ `unverified` + stderr warn（パース失敗を機械検証側で捕捉）

---

## リポジトリインターフェース

### IssueBodyRepository

Issue 本文の取得 / 更新を抽象化する。`gh issue view --json body` / `gh issue edit --body-file` を内部で呼ぶ。

- **操作**:
  - `read(issue_url) → IssueBody`
  - `write(issue_url, IssueBody) → WriteResult { ok: bool, error_code: string | undefined }`

### IssueCommentRepository

Issue コメントの追記を抽象化する。`gh issue comment <N> --body-file` を内部で呼ぶ。

- **操作**:
  - `append(issue_url, LLMDiffSection) → AppendResult { ok: bool, error_code: string | undefined }`

### IssueLabelRepository

Issue へのラベル付与を抽象化する。`gh issue edit <N> --add-label` を内部で呼ぶ。

- **操作**:
  - `add(issue_url, label_name) → AddResult { ok: bool, error_code: string | undefined }`

### LLMDraftFileRepository

環境変数で指定された一時ファイルからの読取を抽象化する。

- **操作**:
  - `read(path) → FileReadResult { ok: bool, content: string, error_code: string | undefined }`
- **責務**: I/O エラー（permission denied / not exist 等）の検出と error_code 付与のみ。スキーマ検証は `LLMDraftSchemaValidator` の責務

### IssueListRepository

retrospective ラベル + Milestone 検索を抽象化する。`gh issue list --label retrospective --milestone <cycle>` を内部で呼ぶ。

- **操作**:
  - `find_by_cycle(cycle) → IssueDescriptor[]`（各要素は `{number, title, body}` を含む）

---

## ドメインモデル図（簡易）

```
[AI エージェント手順 / main agent]
  │ retrospective-drafter subagent 起動
  │ AskUserQuestion fallback
  │ 30 秒タイムアウト判定
  ▼
[一時ファイル: subagent 出力 YAML] ── AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH ───┐
                                                                            │
[一時ファイル: テストモック OVERRIDE] ── AIDLC_RETRO_LLM_DRAFT_OVERRIDE ─┐ │
                                                                          │ │
                              ┌───────────────────────────────────────────┘ │
                              ▼                                              ▼
                   [AIDLC_TEST_MODE] ←────  [TestModeGuard / EnvVarSnapshot]
                              │
                              ▼
                   [LLMDraftPathResolver] → [LLMDraftFileRepository]
                              │                       │
                              ▼                       ▼
                   [LLMDraftSchemaValidator] → [LLMDraft 集約]
                              │
                              ▼
                   stdout（YAML）→ Unit 002 retrospective_body_compose

----- 起票後（Unit 002 起票完了 → IssueUrl 取得） -----

[Unit 002 retrospective_issue_create] ── IssueUrl ──┐
                                                     ▼
[一時ファイル: 人間確認後 YAML] ── AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH ──→ [HumanReviewSession 集約]
                                                                                │
                                                                                ▼
                                                  [HumanReviewDiffComputer] → [DiffResult]
                                                                                │
                                                                                ▼
                                                  has_diff=true ──→ [LLMDiffFormatter] → [LLMDiffSection]
                                                                                │
                                                                                ▼
                                                  [HumanReviewIssueWriter]
                                                       │
                              ┌────────────────────────┼────────────────────────┐
                              ▼                        ▼                        ▼
                   [IssueCommentRepository]  [IssueBodyRepository]   [IssueLabelRepository]
                   gh issue comment           gh issue edit           gh issue edit
                                              --body-file             --add-label

----- 機械検証 CLI（retrospective-verify.sh） -----

[CLI --cycle <CYCLE> [--strict] [--dry-run]]
        │
        ▼
[IssueListRepository.find_by_cycle] ───→ [VerificationScanner]
                                                │
                                                ▼
                                  [VerificationStateClassifier] ──→ [VerificationOutcome[]]
                                                                          │
                                                                          ▼
                                                                  [VerificationReport 集約]
                                                                          │
                                                                          ▼
                                                              stdout レポート + exit code
```

---

## ユビキタス言語

| 用語 | 定義 |
|------|------|
| LLM 下書き（LLM Draft） | `retrospective-drafter` subagent が生成する Intent §6.3 スキーマ準拠の主因分類 + skill_caused_judgment YAML |
| 主因分類（Primary Cause） | プロダクト固有 / AI-DLC 固有 / 両方 の 3 分類 |
| skill 起因判定（Skill-Caused Judgment） | q1/q2/q3 + 引用文での skill 起因の有無の判断 |
| 人間確認（Human Review） | LLM 下書きの内容をユーザーが確認し、訂正があれば最終結果を YAML として渡す運用。`human_reviewed: true` マーカーで完了を示す |
| 確認済みマーカー（`human_reviewed: true`） | Unit 002 起票時 `false` / Unit 003 update で `true` への一方向遷移 |
| LLM 差分コメント（`[llm-diff]`） | LLM 推論結果と人間確認後の差分を `[llm-diff]` プレフィックス付きで Issue コメント追記する仕組み |
| AI エージェント前段手順 | hook 関数を呼び出す前に main agent が subagent 起動 / AskUserQuestion / タイムアウト判定 / 環境変数 export を実施する一連の手順 |
| hook 関数本体 | `retrospective_prefill_hook` / `retrospective_update_hook` の シェル関数。AI エージェント手順の責務を持たず、環境変数経由のファイル読取 / スキーマ検証 / skip 判定 / I/O / `gh` 呼び出しのみ |
| テストモード | `AIDLC_TEST_MODE=1` を export した環境。`AIDLC_RETRO_LLM_DRAFT_OVERRIDE` を経由してテスト用 YAML を hook に注入できる |
| production 誤設定検出 | `AIDLC_TEST_MODE` 未設定で `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` のみ設定された場合の安全性ガード（OVERRIDE 値を無視 + stderr error） |
| 機械検証（Machine Verification） | `retrospective-verify.sh` で `human_reviewed: true` 未付与の Issue を検出する CLI |
| `verified` / `unverified` / `skipped` | VerificationOutcome の 3 状態。`verified=true` 付与済 / `unverified=false` または欠落 / `skipped=`旧仕様 Issue |

---

## 確定事項（Phase 1 設計で決定済 / SSOT）

### subagent 起動の責務分離

- AI エージェント（main agent）が subagent を起動し、結果 YAML を一時ファイルに保存して環境変数 `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` を export する
- hook 関数は環境変数経由でファイルを読むのみ。subagent 起動 / AskUserQuestion / タイムアウト判定の責務は持たない
- 検証手段の分離: hook 関数本体経路は BATS で verify、AI エージェント手順経路は `agents/retrospective-drafter.md` documentation 検証 + review checklist + 目視確認

### exit code 規約（`guides/exit-code-convention.md` 準拠 / 引数系 exit 2 統一）

- 警告付き完了は常に exit 0
- ランタイム異常（I/O エラー / `gh` API 失敗 / Milestone 不在 / cycle 未解決）は exit 1
- 引数系（必須引数欠落 / 引数形式不正 / 不正なオプション / 値域違反）は exit 2
- `retrospective_update_hook` は `gh` 失敗時も exit 0 + stderr `warn\thuman_review_gh_*_failed\t...`（境界仕様 / Unit 002 が継続）

### テストモック production ガード

- `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` は `AIDLC_TEST_MODE=1` が同時設定された場合のみ発動
- `AIDLC_TEST_MODE` 未設定で OVERRIDE のみ設定された場合は OVERRIDE を無視 + stderr `error\tllm_draft_override_in_production\t...`
- BATS setup でのみ `AIDLC_TEST_MODE=1` を export し、本番では決して export しない方針を documentation に明記

### CI / 非対話の扱い

- Intent §「主要設計判断 2」厳守: 非対話 / CI は常に skip（手動入力 fallback も実装しない）
- `mirror-only` を CI で動作させる例外は設けない

### Unit 002 中核ライブラリへの境界

- 本 Unit 003 は `skills/aidlc/scripts/lib/retrospective-issue.sh` / `retrospective-resend.sh` / `templates/retrospective_template.md` を編集しない
- Unit 002 提供の `retrospective_body_compose()` / `retrospective_issue_create()` は呼び出すのみ
- §1.5 ステップ本体（`steps/operations/04-completion.md`）も編集しない（Intent §「主要設計判断 6.5」§1.5 編集主体は Unit 002）

### Unit 003 hook 契約（Unit 002 plan §「Unit 003 フック契約」を cross-unit 正本として採用）

- `retrospective_prefill_hook(cycle, kpt_md_path)`: stdout に YAML / exit 0=成功 / 1=ランタイム異常 / 2=引数エラー
- `retrospective_update_hook(issue_url, cycle)`: stdout 任意 / exit 0=成功（gh 失敗時 warn 含む）/ 1=ランタイム異常 / 2=引数エラー
- 引数 `issue_url == ""` 時は no-op で exit 0 + skip 動作

### `retrospective-verify.sh` の Milestone 解決

- 引数 `--cycle <CYCLE>` 指定時はその値を使用
- 未指定時は `[project].cycle` 設定（`scripts/read-config.sh project.cycle`）→ それも未設定なら最新 open Milestone の `title` を採用 → それも不在なら exit 1 + stderr `error\tverify_cycle_unresolved\t...`（cycle 未解決はランタイム異常扱い / 引数系の exit 2 とは区別）

### 環境変数命名規約

- 本 Unit 003 が新規追加する環境変数: `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` / `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` / `AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH`
- `AIDLC_TEST_MODE` は本 Unit 003 で導入する汎用ガード変数（既存 Unit 001 の `AIDLC_FORCE_INTERACTIVE` 等とは独立 / 命名衝突なし）
- 既存 Unit 001 / 002 の環境変数（`AIDLC_FORCE_INTERACTIVE` / `AIDLC_RETRO_FORCE_TARGET` / `AIDLC_RETRO_SKIP_LOCAL` / `AIDLC_RETRO_CURRENT_COUNT` / `AIDLC_RETRO_LIMIT` / `AIDLC_PROJECT_ROOT`）は変更しない
