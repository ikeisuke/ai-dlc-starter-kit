# 論理設計: Unit 003 主因分類 LLM 下書き + 人間確認運用

## 概要

Unit 003 は AI エージェント（main agent）が前段で `retrospective-drafter` subagent を起動し、結果 YAML を一時ファイル + 環境変数経由で hook 関数に渡す境界設計を採用する。hook 関数本体は環境変数読取 + スキーマ検証 + skip 判定 + I/O + `gh` 呼び出しのみを担当し、subagent 起動 / AskUserQuestion / 30 秒タイムアウト判定の責務は持たない。本論理設計は hook 関数 / subagent 定義 / 機械検証 CLI の処理フロー / インターフェース / データ構造を定義し、04-completion §1.5 ステップ本体は **編集対象外**（Unit 002 既存改修との整合確認のみ）。

**重要**: このドキュメントでは**コードは書かず**、処理フローと I/F の定義のみを行う。実装は Phase 2（コード生成）で行う。

---

## アーキテクチャパターン

| パターン | 採用箇所 | 採用理由 |
|---------|---------|---------|
| **Layered Architecture（責務階層分離）** | AI エージェント手順層 / hook 関数層 / `gh` 呼び出し層 / 検証 CLI 層 | subagent 起動の不確実性を hook 関数本体から切り離し、テスト容易性と境界保護を確保 |
| **Strategy Pattern**（環境変数による経路選択） | `LLMDraftPathResolver` の優先順位ロジック（test_override / production / subagent_emitted / skip） | 同一 hook 関数で本番 / テスト / fallback の各経路を切り替えるため |
| **Pipeline Pattern**（差分計算 → コメント生成 → gh 更新） | `HumanReviewIssueWriter` の処理順序固定 | コメント追記成功時のみ本文 update に進む invariant（R3 緩和策）を構造的に保証 |
| **Adapter Pattern**（gh CLI への薄いラッパー） | `IssueBodyRepository` / `IssueCommentRepository` / `IssueLabelRepository` | `gh` CLI 仕様変更や mock 化が hook 関数本体に波及しないよう抽象化 |
| **Pure Function**（純粋関数の内部公開） | `LLMDraftSchemaValidator` / `HumanReviewDiffComputer` / `LLMDiffFormatter` / `VerificationStateClassifier` | テスト容易性と再利用性を最大化（Unit 002 の `_pure_compose_body` パターンを踏襲） |

---

## コンポーネント構成

### レイヤー / モジュール構成

```
┌─────────────────────────────────────────────────────────────────────┐
│ Operations Phase 04-completion §1.5（Unit 002 編集主体 / Unit 003 編集対象外）│
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ command -v retrospective_prefill_hook / _update_hook
                              │
┌─────────────────────────────────────────────────────────────────────┐
│ AI エージェント前段手順層（agents/retrospective-drafter.md documentation）   │
│  - retrospective-drafter subagent 起動                                 │
│  - 30 秒タイムアウト判定                                                  │
│  - AskUserQuestion fallback（タイムアウト / スキーマ違反時）                  │
│  - 結果 YAML を一時ファイルに保存 + AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH export │
│  - human review 確認 → AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH export       │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ 環境変数受け渡し
                              │
┌─────────────────────────────────────────────────────────────────────┐
│ hook 関数層（scripts/lib/retrospective-llm-draft.sh / retrospective-human-review.sh）│
│  - retrospective_prefill_hook(cycle, kpt_md_path)                     │
│  - retrospective_update_hook(issue_url, cycle)                        │
│                                                                       │
│ ドメインサービス層:                                                       │
│  - TestModeGuard / LLMDraftPathResolver / LLMDraftSchemaValidator     │
│  - HumanReviewDiffComputer / LLMDiffFormatter / HumanReviewIssueWriter │
│  - VerificationScanner / VerificationStateClassifier                  │
└─────────────────────────────────────────────────────────────────────┘
                              │
                              ▼ gh CLI 呼び出し
                              │
┌─────────────────────────────────────────────────────────────────────┐
│ Adapter 層（gh CLI ラッパー）                                            │
│  - IssueBodyRepository / IssueCommentRepository                       │
│  - IssueLabelRepository / IssueListRepository                         │
│  - LLMDraftFileRepository（tmp file I/O）                              │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│ 検証 CLI 層（scripts/retrospective-verify.sh）                            │
│  - 引数パース / Milestone 解決 / VerificationReport 集約                  │
│  - VerificationScanner → VerificationStateClassifier → exit code      │
└─────────────────────────────────────────────────────────────────────┘
```

### コンポーネント詳細

| コンポーネント | ファイルパス | 種別 | 責務 |
|---------------|-------------|------|------|
| `retrospective-drafter` subagent | `skills/aidlc/agents/retrospective-drafter.md` | subagent 定義 + documentation | LLM 推論プロンプト / 出力スキーマ / AI エージェント呼び出し例（subagent 起動 + AskUserQuestion fallback + 30 秒タイムアウト判定 + 環境変数 export） |
| LLM 下書き hook | `skills/aidlc/scripts/lib/retrospective-llm-draft.sh` | hook 関数（公開）+ 内部ユーティリティ | `retrospective_prefill_hook` 公開関数 / 環境変数読取 / スキーマ検証 / skip 判定 / production ガード |
| 人間確認 hook | `skills/aidlc/scripts/lib/retrospective-human-review.sh` | hook 関数（公開）+ 内部ユーティリティ | `retrospective_update_hook` 公開関数 / 差分計算 / コメント生成 / `gh` 呼び出し orchestration |
| 検証 CLI | `skills/aidlc/scripts/retrospective-verify.sh` | CLI スクリプト | 引数パース / Milestone 解決 / Issue 列挙 / YAML パース / 状態判定 / exit code |

---

## インターフェース設計

### `retrospective_prefill_hook(cycle, kpt_md_path)`（公開関数 / Unit 002 plan §「Unit 003 フック契約」準拠）

```text
retrospective_prefill_hook <cycle> <kpt_md_path>
```

#### 入力

- `cycle`: サイクル名（例: `v2.5.1`）。Unit 002 が呼び出し時に指定
- `kpt_md_path`: KPT セクション本文 Markdown のファイルパス（subagent 入力には使用せず、互換性のためインターフェースに残す。AI エージェント前段手順が同じ kpt_md を subagent に渡している前提）

#### 副作用

- 環境変数 `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` / `AIDLC_RETRO_LLM_DRAFT_OVERRIDE`（テストモード時）が指す一時ファイルの読取のみ
- `AIDLC_TEST_MODE` の参照（読取のみ / 変更しない）
- stdout に Intent §6.3 スキーマ準拠 YAML を出力（成功時 / fallback 時）
- stderr に状態通知（`<level>\t<code>\t<detail>` 形式）

#### 戻り値（exit code）

- `0`: 成功（subagent 経路 / fallback 既定値経路 / skip 経路 / test_override 経路 / production 誤設定検出含む。警告付き完了は常に exit 0）
- `1`: ランタイム異常（一時ファイル I/O エラー: permission denied / disk full 等）
- `2`: 引数エラー（cycle / kpt_md_path 欠落）

#### stderr メッセージ仕様

| `<level>` | `<code>` | 発生条件 |
|-----------|----------|---------|
| info | `llm_draft_subagent_emitted` | 環境変数指定の subagent 出力 YAML がスキーマ検証を pass し stdout 出力 |
| info | `llm_draft_test_override` | test_mode + OVERRIDE 設定 → OVERRIDE のファイル内容を stdout 出力 |
| info | `llm_draft_skip_disabled` | `feedback_mode_resolve()` が `disabled` を返却 |
| info | `llm_draft_skip_non_interactive` | tty 不在 + 環境変数未設定（CI / 非対話セッション） |
| warn | `llm_draft_subagent_unavailable` | tty あり + 環境変数未設定（AI エージェント前段手順未実施 = AI エージェント側の運用ミス） |
| warn | `llm_draft_schema_violation` | 環境変数指定ファイルが Intent §6.3 スキーマ違反 |
| error | `llm_draft_override_in_production` | `AIDLC_TEST_MODE` 未設定 + `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` 設定済（production 侵食検出） |
| error | `llm_draft_io_error` | 環境変数指定ファイルの I/O エラー（permission denied / 不在ファイル等） |
| error | `llm_draft_missing_args` | 引数 < 2 |

### `retrospective_update_hook(issue_url, cycle)`（公開関数 / Unit 002 plan §「Unit 003 フック契約」準拠）

```text
retrospective_update_hook <issue_url> <cycle>
```

#### 入力

- `issue_url`: 起票済み Issue の URL（空文字列時は no-op + skip 動作 / `https://github.com/...` 形式以外は引数形式不正で exit 2）
- `cycle`: サイクル名

#### 副作用

- 環境変数 `AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH` が指す一時ファイルの読取（人間確認後の最終 YAML / 未設定時は「差分なし」扱い）
- **順序不変条件**（plan §「リスク R3 緩和」/ ドメインサービス `HumanReviewIssueWriter` 準拠）: 差分あり時は **`gh issue comment` → `gh issue edit --body-file` → `gh issue edit --add-label`** の順序で呼び出す。前段失敗時は後段スキップ:
  - 1) `gh issue comment <N> --body ...` で `[llm-diff]` コメント追記（差分ありの場合のみ）
  - 2) コメント成功時のみ: `gh issue edit <N> --body-file ...` で本文置換（`human_reviewed: false → true`）
  - 3) 本文置換成功時のみ: `gh issue edit <N> --add-label human-reviewed` でラベル付与（任意 / 失敗時 warn のみ）
- 差分なし時はコメント追記をスキップし、`gh issue edit --body-file`（`human_reviewed: false → true` のみ）→ `gh issue edit --add-label` の 2 段
- stderr に状態通知（`<level>\t<code>\t<detail>` 形式）

#### 戻り値（exit code）

- `0`: 成功（差分なしで本文だけ更新 / 差分ありで全成功 / `gh` 失敗時の警告継続 / 既に `human_reviewed: true` の冪等 skip / `issue_url == ""` の skip。警告付き完了は常に exit 0）
- `1`: ランタイム異常（一時ファイル I/O エラー: permission denied / not exist 等）
- `2`: 引数エラー（必須引数欠落 / `issue_url` 形式不正: `https://github.com/<owner>/<repo>/issues/<N>` 以外）

#### stderr メッセージ仕様

| `<level>` | `<code>` | 発生条件 |
|-----------|----------|---------|
| info | `human_review_skip_no_issue` | `issue_url == ""`（起票なし） |
| info | `human_review_skip_no_diff` | 差分なしで本文更新スキップ（`human_reviewed` のみ true 化） |
| info | `human_review_diff_recorded` | 差分ありで `gh issue edit` + `gh issue comment` 成功 |
| info | `human_review_already_done` | 既に `human_reviewed: true` の Issue（冪等 skip） |
| warn | `human_review_gh_edit_failed` | `gh issue edit --body-file` API 失敗 |
| warn | `human_review_gh_comment_failed` | `gh issue comment` API 失敗 |
| warn | `human_review_label_failed` | `gh issue edit --add-label` API 失敗 |
| error | `human_review_invalid_url` | `issue_url` が `https://github.com/<owner>/<repo>/issues/<N>` 形式でない（exit 2 / 引数形式不正） |
| error | `human_review_io_error` | `AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH` 指定ファイルの I/O エラー（exit 1 / ランタイム異常） |
| error | `human_review_missing_args` | 引数 < 2（exit 2 / 引数欠落） |

### `retrospective-verify.sh`（CLI）

```text
retrospective-verify.sh [--cycle <CYCLE>] [--strict] [--dry-run] [--help]
```

#### オプション

- `--cycle <CYCLE>`: 検証対象サイクル。未指定時は `[project].cycle` 設定 → 最新 open Milestone の順で解決
- `--strict`: `skipped` も未確認扱い（旧仕様 Issue を未確認として exit 1 にする）
- `--dry-run`: 副作用なし（stdout レポートのみ / `gh` API 呼び出しは行うが結果集計のみ）
- `--help`: usage 表示 + exit 0

#### 出力

- stdout: 各 Issue 1 行 `<state>\t<issue_number>\t<title>` 形式（`state ∈ {verified, unverified, skipped}`）
- 末尾サマリ: `summary\tverified=<n>\tunverified=<n>\tskipped=<n>` 形式
- stderr: `<level>\t<code>\t<detail>` 形式

#### 戻り値（exit code）

hook 関数群と同じ規約（指摘 #1 反映 / `guides/exit-code-convention.md` 準拠）:

- `0`: 全件 `verified` または対象 Issue 0 件
- `1`: 未確認あり（`unverified ≥ 1`、`--strict` 時は `unverified + skipped ≥ 1`）/ ランタイム異常（`gh` 不可 / Milestone 不在 / cycle 未解決 / I/O エラー）
- `2`: 引数エラー（不正なオプション / 必須引数欠落 / 値域違反）

詳細な分類:

| 状況 | exit code | stderr |
|------|-----------|--------|
| 全件 `verified` または対象 Issue 0 件 | 0 | `info\tverify_summary\t...` |
| 未確認あり（`unverified ≥ 1`） | 1 | （unverified の Issue が stdout に列挙される） |
| `--strict` 時の skipped 検出（`unverified + skipped ≥ 1`） | 1 | （該当 Issue が stdout に列挙される） |
| `gh` コマンド失敗（auth エラー / API 失敗等） | 1 | `error\tverify_gh_unavailable\t...` |
| Milestone 不在 | 1 | `error\tverify_milestone_not_found\t...` |
| cycle 未解決（`--cycle` 未指定 + 設定不在 + Milestone 不在） | 1 | `error\tverify_cycle_unresolved\t...` |
| I/O エラー（一時ファイル / 設定ファイル読取失敗） | 1 | `error\tverify_io_error\t...` |
| 不正なオプション / 値域違反 | 2 | `error\tverify_invalid_args\t...` |
| 必須引数欠落 | 2 | `error\tverify_missing_args\t...` |

---

## データモデル概要

### `retrospective-drafter` subagent 入力フォーマット

AI エージェント前段手順が subagent に渡すデータ。本 Unit 003 では subagent 起動を AI エージェントに委譲するため、入力フォーマット仕様は `agents/retrospective-drafter.md` に記述する。論理設計レベルでは下記スキーマ準拠とする:

```yaml
input:
  cycle: <string>
  problems:
    - id: <integer>
      title: <string>
      what_happened: <string>
      why_happened: <string>
      impact: <string>
```

### `retrospective-drafter` subagent 出力フォーマット（Intent §6.3 スキーマ）

```yaml
problem_drafts:
  - problem_id: <integer>
    primary_cause: "product" | "ai_dlc" | "both"
    primary_cause_reason: <string>
    skill_caused_judgment:
      q1_answer: "yes" | "no"
      q1_quote: <string>
      q2_answer: "yes" | "no"
      q2_quote: <string>
      q3_answer: "yes" | "no"
      q3_quote: <string>
    confidence: "high" | "medium" | "low"  # 任意
```

### `[llm-diff]` コメント本文構造

```markdown
[llm-diff] LLM 推論結果と人間確認後の差分（cycle: <CYCLE>）

## LLM 推論結果

```yaml
problem_drafts:
  - problem_id: 1
    primary_cause: product
    ...
```

## 人間確認後の最終結果

```yaml
problem_drafts:
  - problem_id: 1
    primary_cause: ai_dlc  # ← 訂正
    ...
```

## 差分一覧

| problem_id | field | LLM 推論 | 人間確認後 |
|------------|-------|----------|-----------|
| 1 | primary_cause | product | ai_dlc |
| 1 | primary_cause_reason | "..." | "..." |
```

---

## 処理フロー概要

### ユースケース 1: §1.5 で `retrospective_prefill_hook` 経由 LLM 下書き取得（subagent 経路 / 対話セッション）

```
[main agent: §1.5 実行前準備]
  1. feedback_mode_resolve() で disabled でないことを確認
  2. tty あり（対話セッション）を確認
  3. retrospective-drafter subagent を起動（Task ツール）
       入力: cycle / problems[]（KPT セクションの Problem 配列）
       30 秒タイムアウト監視
  4. subagent 出力 YAML を一時ファイルに保存
       例: /tmp/aidlc-retro-llm-draft-<uuid>.yaml
  5. AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH=<path> を export
  6. §1.5 を実行（Unit 002 が記述済の Step 3 で hook 呼び出し）

[hook: retrospective_prefill_hook v2.5.1 cycle/.../kpt.md]
  1. 引数検証 → OK（exit code は呼出元で判定）
  2. EnvVarSnapshot 取得（PREFILL_PATH = /tmp/.../yaml / OVERRIDE = undefined / TEST_MODE = false）
  3. TestModeGuard 評価 → production_misconfiguration = false
  4. LLMDraftPathResolver:
     - test_mode=false かつ OVERRIDE=undefined → skip
     - PREFILL_PATH 設定済 → path = PREFILL_PATH / status = subagent_emitted
  5. LLMDraftFileRepository.read(path) → ファイル内容取得
  6. LLMDraftSchemaValidator.validate(content) → ok=true / parsed=ProblemDraft[]
  7. stdout に YAML 内容をそのまま出力
  8. stderr に info\tllm_draft_subagent_emitted\t...
  9. exit 0
```

### ユースケース 2: subagent タイムアウト → AskUserQuestion fallback（対話セッション）

```
[main agent: §1.5 実行前準備]
  1. retrospective-drafter subagent 起動 → 30 秒経過しても応答なし
  2. AskUserQuestion を起動して 3 分類 + q1/q2/q3 を対話取得
  3. 取得した値で Intent §6.3 fallback 既定値構造を埋める（primary_cause="product" 仮置き等）
  4. 一時ファイルに保存 → AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH=<path> を export
  5. §1.5 を実行

[hook: retrospective_prefill_hook] （ユースケース 1 と同じ経路）
  ※ hook 関数自体は subagent タイムアウトを認識しない（AI エージェント手順側の責務）
  ※ stderr では info\tllm_draft_subagent_emitted\t... を出す（fallback YAML も「emitted」扱い）
```

### ユースケース 3: スキーマ違反検出（subagent 出力が Intent §6.3 違反）

```
[main agent: §1.5 実行前準備]
  1. subagent 起動 → 30 秒以内に応答ありだが必須キー欠落
  2. AskUserQuestion fallback を起動（ユースケース 2 と同じ）
  ※ または hook 関数側がスキーマ違反検出 → 空 stdout fallback

[hook: retrospective_prefill_hook]
  1-5. ユースケース 1 と同じまで進む
  6. LLMDraftSchemaValidator.validate(content) → ok=false / violations=[...]
  7. 空 stdout（Unit 002 が空 YAML フォールバックで本文構築継続）
  8. stderr に warn\tllm_draft_schema_violation\t<violations>
  9. exit 0
```

### ユースケース 4: `disabled` モード時の skip

```
[main agent: §1.5 実行前準備]
  ※ §1.5 は feedback_mode_resolve() で disabled なら Step 1.5 全体をスキップ
  ※ AI エージェント前段手順も実行しない（subagent 起動なし）

[hook: retrospective_prefill_hook] （呼ばれない）
  ※ §1.5 が disabled で hook 自体を呼ばない
```

### ユースケース 5: 非対話 / CI

```
[main agent: §1.5 実行前準備]
  1. tty 不在を検出
  2. AI エージェント前段手順をスキップ（subagent も AskUserQuestion も起動しない）
  3. AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH を export しない
  4. §1.5 を実行

[hook: retrospective_prefill_hook]
  1. 引数検証 → OK
  2. EnvVarSnapshot 取得（PREFILL_PATH = undefined / OVERRIDE = undefined / TEST_MODE = false）
  3. TestModeGuard 評価 → production_misconfiguration = false
  4. LLMDraftPathResolver → path = undefined / status = （呼出元で決定）
  5. tty 判定:
     - tty 不在 → status = skip_non_interactive
  6. 空 stdout
  7. stderr に info\tllm_draft_skip_non_interactive\t...
  8. exit 0
```

### ユースケース 6: production 誤設定検出

```
[main agent: §1.5 実行前準備]
  ※ ユーザーが誤って AIDLC_RETRO_LLM_DRAFT_OVERRIDE を export
  ※ AIDLC_TEST_MODE は設定していない

[hook: retrospective_prefill_hook]
  1. 引数検証 → OK
  2. EnvVarSnapshot 取得（PREFILL_PATH = undefined / OVERRIDE = /tmp/foo.yaml / TEST_MODE = false）
  3. TestModeGuard 評価 → production_misconfiguration = true
  4. stderr に error\tllm_draft_override_in_production\tOVERRIDE specified without AIDLC_TEST_MODE=1 (ignored)
  5. LLMDraftPathResolver → OVERRIDE 値を無視 + 通常経路（PREFILL_PATH = undefined → skip）
  6. tty 判定で次のステータス決定（対話なら subagent_unavailable / 非対話なら skip_non_interactive）
  7. 空 stdout
  8. exit 0（誤設定はあくまで警告 / hook 自体の機能は維持）
```

### ユースケース 7: 起票後の人間確認運用（差分なし）

```
[Unit 002: §1.5 Step 5 で retrospective_issue_create() が created を返却]
  1. issue_url を取得（例: https://github.com/owner/repo/issues/123）
  2. §1.5 Step 6 で command -v retrospective_update_hook → 定義済を確認

[main agent: §1.5 Step 6 実行前準備]
  1. ユーザーに「LLM 下書き内容を確認してください」と AskUserQuestion で提示
  2. ユーザーが「訂正なし」を選択 → AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH を export しない（差分なし）
  3. retrospective_update_hook を呼び出し

[hook: retrospective_update_hook https://.../issues/123 v2.5.1]
  1. 引数検証 → OK
  2. EnvVarSnapshot 取得（FINAL_PATH = undefined）
  3. issue_url 形式検証 → OK
  4. IssueBodyRepository.read(issue_url) → 現在の本文取得
  5. 本文 YAML から human_reviewed 抽出 → false（既に true なら冪等 skip）
  6. AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH 未設定 → 差分なし扱い
  7. HumanReviewDiffComputer → has_diff=false
  8. LLMDiffFormatter は呼ばない（コメント追記なし）
  9. IssueBodyRepository.write(issue_url, 新本文)
     - 新本文 = 既存本文の human_reviewed:false → human_reviewed:true 置換のみ
  10. IssueLabelRepository.add(issue_url, "human-reviewed") → 成功 / 失敗時 warn
  11. stderr に info\thuman_review_skip_no_diff\t...
  12. exit 0
```

### ユースケース 8: 起票後の人間確認運用（差分あり）

```
[main agent: §1.5 Step 6 実行前準備]
  1. AskUserQuestion で「LLM 推論結果に訂正がある？」と提示
  2. ユーザーが「訂正あり」を選択 → 訂正後の YAML を一時ファイルに保存
  3. AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH=<path> を export
  4. retrospective_update_hook を呼び出し

[hook: retrospective_update_hook https://.../issues/123 v2.5.1]
  1-5. ユースケース 7 と同じ
  6. AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH 設定済 → ファイル読取
  7. LLMDraftSchemaValidator で final_drafts を検証 → ok / 違反時は warn のみで継続
  8. HumanReviewDiffComputer → has_diff=true / diff_per_problem=[...]
  9. LLMDiffFormatter → LLMDiffSection 生成
  10. IssueCommentRepository.append(issue_url, LLMDiffSection)
      - 失敗時: stderr warn\thuman_review_gh_comment_failed + 本文 update / ラベル付与をスキップ + exit 0
  11. コメント成功時のみ: IssueBodyRepository.write(issue_url, 新本文)
      - 新本文 = `human_reviewed: false → true` 置換のみ（実 Issue 本文は Markdown 展開で `problem_drafts:` を直接保持しないため、final_path 内容の差分は前段 `[llm-diff]` コメントが canonical な記録経路 / 本文の Markdown 再生成は将来サイクルで検討）
      - 失敗時: stderr warn\thuman_review_gh_edit_failed + ラベル付与をスキップ + exit 0
  12. 本文 update 成功時のみ: IssueLabelRepository.add(issue_url, "human-reviewed")
      - 失敗時: stderr warn\thuman_review_label_failed + exit 0
  13. stderr に info\thuman_review_diff_recorded\t...
  14. exit 0
```

### ユースケース 9: 機械検証 CLI

```
[CLI: retrospective-verify.sh --cycle v2.5.1]
  1. 引数パース
  2. cycle 解決（--cycle 指定済なので v2.5.1）
  3. IssueListRepository.find_by_cycle("v2.5.1")
     - gh issue list --label retrospective --milestone v2.5.1 --state all --json number,title,body
  4. 各 Issue で:
     - VerificationScanner.parse(issue.body) → 末尾 YAML 抽出
     - VerificationStateClassifier.classify(yaml) → state
     - VerificationOutcome 生成
  5. VerificationReport 集約
  6. stdout に各 Issue 1 行 `<state>\t<number>\t<title>`
  7. 末尾サマリ `summary\tverified=N\tunverified=M\tskipped=K`
  8. exit code:
     - --strict なし: unverified=0 なら 0 / それ以外 1
     - --strict あり: unverified+skipped=0 なら 0 / それ以外 1
```

---

## `retrospective-drafter` subagent 定義仕様（`agents/retrospective-drafter.md`）

### 構造

```markdown
---
name: retrospective-drafter
description: ...
---

# Retrospective Drafter

[プロンプト本体]
- 役割: retrospective Issue の主因分類 + skill_caused_judgment 下書き生成
- 入力: cycle / problems[]
- 出力: Intent §6.3 スキーマ準拠 YAML
- 制約: 30 秒以内に応答 / スキーマ違反禁止 / 推測根拠を primary_cause_reason に記載

# 呼び出し例（AI エージェント手順 documentation）

## 通常呼び出し（対話セッション / 成功経路）

1. main agent が Task ツールで retrospective-drafter subagent を起動
2. 入力に cycle / problems[] を渡す
3. 30 秒タイムアウト監視（main agent 側で wall clock 計測）
4. 出力 YAML を一時ファイルに保存
5. AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH=<path> を export
6. §1.5 ステップを実行（Unit 002 が記述済の Step 3 が retrospective_prefill_hook を呼ぶ）

## タイムアウト時の fallback

1. 30 秒経過しても subagent から応答なし
2. main agent が AskUserQuestion で 3 分類 + q1/q2/q3 を対話取得
3. Intent §6.3 fallback 既定値構造を埋めた YAML を一時ファイルに保存
4. AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH を同様に export

## スキーマ違反時の fallback

1. subagent 出力が必須キー欠落 / 値域違反
2. AskUserQuestion fallback を起動（タイムアウト時と同じ）

## 非対話セッション / CI

1. main agent は subagent 起動 / AskUserQuestion 起動を実行しない
2. AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH を export しない
3. hook 関数側で skip_non_interactive 判定

## human review 確認運用（§1.5 Step 6 前）

1. main agent が AskUserQuestion で「LLM 下書きの内容に訂正があるか」を確認
2. 訂正なし: AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH を export しない（差分なし）
3. 訂正あり: 訂正後 YAML を一時ファイルに保存 → AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH=<path> を export
4. retrospective_update_hook を呼ぶ
```

---

## 04-completion.md §1.5 整合確認（参照のみ / 編集対象外）

Unit 003 は §1.5 ステップ本体を編集しない（Intent §「主要設計判断 6.5」§1.5 編集主体は Unit 002）。本セクションでは Unit 002 が記述済の §1.5 が Unit 003 hook を問題なく呼び出せるかをギャップ判定する。

### Unit 002 §1.5 改修内容のスナップショット（参照）

Unit 002 plan §「§1.5 改修案（最終形）」より:

- Step 3: cap 判定 + Unit 003 prefill フック呼び出し（`command -v retrospective_prefill_hook >/dev/null 2>&1` で関数存在確認 → 定義済なら呼び出して stdout 取得 / 失敗時は空 YAML フォールバック）
- Step 6: Unit 003 update フック呼び出し（`command -v retrospective_update_hook >/dev/null 2>&1` で関数存在確認 → 定義済なら呼び出し / 失敗時は警告のみで §1.5 継続）

### ギャップ判定

| 観点 | Unit 002 §1.5 改修内容 | Unit 003 hook 仕様 | 整合性 |
|------|------------------------|---------------------|--------|
| 関数名 | `retrospective_prefill_hook` / `retrospective_update_hook` | 同上 | ✓ 完全一致 |
| 引数 | Step 3: `(cycle, kpt_md_path)` / Step 6: `(issue_url, cycle)` | 同上 | ✓ 完全一致 |
| stdout 出力 | Step 3: YAML / Step 6: 任意 | 同上 | ✓ 完全一致 |
| exit code | 非 0 = 失敗（警告のみで継続） | 警告付き完了は exit 0 / ランタイム異常 1 / 引数エラー 2 | ✓ Unit 003 hook は警告付き完了は exit 0 を返し、異常時のみ非 0（exit 1: I/O エラー、exit 2: 引数欠落 / URL 形式不正など引数系全般）。Unit 002 は非 0 受領時を「警告のみで継続」する境界仕様で吸収するため、ランタイム異常時も §1.5 全体は止まらない（互換性あり） |
| `disabled` 時の動作 | §1.5 全体スキップ → hook 呼ばれない | hook 呼ばれた場合も skip_disabled で exit 0 | ✓ 二重防御（§1.5 で先に弾く + hook 内でも skip） |
| hook ファイル source | Unit 002 plan で「§1.5 ステップ実行前に Unit 003 提供の hook 実装ファイルを source する」記述（Unit 002 plan §「Unit 003 フック契約」末尾） | Unit 003 が `scripts/lib/retrospective-llm-draft.sh` / `retrospective-human-review.sh` を提供 | ✓ Unit 002 が source 手順を §1.5 に記述 / Unit 003 はファイルを提供 |
| AI エージェント前段手順の実行 | §1.5 ステップ本体には記述なし | `agents/retrospective-drafter.md` の呼び出し例セクションが正本 | ✓ 主 agent が agents/retrospective-drafter.md を documentation で参照して実施 |

### 結論

**Unit 002 §1.5 改修のままで Unit 003 hook が問題なく呼ばれる**。Unit 003 で §1.5 ステップ本体を編集する必要なし。

---

## 非機能要件（NFR）への対応

### 応答性

- LLM 下書き 30 秒タイムアウト: AI エージェント前段手順の責務（main agent が wall clock を計測）。タイムアウト時は AskUserQuestion fallback に切り替わる
- hook 関数本体は I/O 時間のみ（環境変数 + ファイル読取 + `gh` API）/ subagent 起動を含まないため軽量

### 観測性

- 全経路で stderr に `<level>\t<code>\t<detail>` 形式の状態通知を出す（プロジェクト規約準拠）
- AI エージェント側のタイムアウト / スキーマ違反検出も AskUserQuestion 起動経由で結果が hook に届くため、AI エージェント手順自体の動作確認は documentation review + 目視確認で担保

### 学習可能性

- `[llm-diff]` プレフィックスを固定 → 将来の自動分析で `gh issue list` の結果から「LLM 推論と人間確認の乖離」を抽出可能
- `LLMDiffSection` の Markdown 表構造を固定（problem_id / field / LLM 推論 / 人間確認後）→ パースが安定

### 冪等性

- `retrospective_update_hook` を同一 Issue に複数回呼んでも `human_reviewed: true` のまま不変（既に true なら no-op + info\thuman_review_already_done\t...）
- `retrospective_prefill_hook` は副作用なし（stdout のみ）/ 複数回呼んでも同じ stdout

### CI 互換

- `retrospective-verify.sh` が GitHub Actions で実行可能（exit code でステータス表現 + stdout/stderr で詳細情報）
- 非対話 / CI 環境では `retrospective_prefill_hook` が skip_non_interactive で exit 0 を返し、Unit 002 の本文構築は空 YAML フォールバックで継続

### production 安全性

- `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` は `AIDLC_TEST_MODE=1` 必須 → production 環境で誤って設定されても OVERRIDE 値は無視される（侵食ガード）
- production 誤設定時は stderr error で検出を伝える（運用者が気づける）

---

## BATS テストケース一覧

**重要（指摘 #9 / #10 反映）**: `retrospective-llm-draft.bats` は **hook 関数本体の試験のみ**。AskUserQuestion / subagent 起動 / 30 秒タイムアウト判定は AI エージェント手順の責務であり、`agents/retrospective-drafter.md` documentation の検証 + review checklist + 目視確認で担保する（BATS スコープ外）。

### `tests/retrospective-llm-draft.bats`（hook 関数本体のみ）

| ID | 観点 | 動作 |
|----|------|------|
| L1 | 環境変数経由の subagent 出力 YAML が stdout 出力される | PREFILL_PATH 設定 / 内容スキーマ準拠 → stdout = ファイル内容 / exit 0 |
| L2 | スキーマ違反時は空 stdout + warn ログ | PREFILL_PATH 設定 / 必須キー欠落 → stdout 空 / stderr warn / exit 0 |
| L3 | `disabled` モード時は skip | feedback_mode = disabled → stdout 空 / stderr info\tllm_draft_skip_disabled / exit 0 |
| L4 | 非対話セッション skip | tty 不在 + 環境変数未設定 → stdout 空 / stderr info\tllm_draft_skip_non_interactive / exit 0 |
| L5 | I/O エラー時は exit 1 | PREFILL_PATH 設定 / ファイル不在 → stderr error\tllm_draft_io_error / exit 1 |
| L6 | 引数欠落は exit 2 | 引数 < 2 → stderr error\tllm_draft_missing_args / exit 2 |
| L7 | テストモード OVERRIDE 経路 | AIDLC_TEST_MODE=1 + OVERRIDE 設定 → stdout = OVERRIDE 内容 / stderr info\tllm_draft_test_override / exit 0 |
| L8 | production 誤設定検出 | AIDLC_TEST_MODE 未設定 + OVERRIDE 設定 → OVERRIDE 無視 + stderr error\tllm_draft_override_in_production + 通常経路評価 / exit 0 |
| L9 | 環境変数優先順位 | TEST_MODE=1 + OVERRIDE + PREFILL_PATH 全設定 → OVERRIDE 優先 / stderr info\tllm_draft_test_override |
| L10 | 対話セッションで AI エージェント前段手順未実施 | tty あり + 環境変数未設定 → stdout 空 / stderr warn\tllm_draft_subagent_unavailable / exit 0 |

### `tests/retrospective-human-review.bats`

| ID | 観点 | 動作 |
|----|------|------|
| H1 | 差分なしで本文だけ更新（human_reviewed: false → true） | FINAL_PATH 未設定 / 既存 false → gh issue edit のみ呼ばれる / コメント追記なし / stderr info\thuman_review_skip_no_diff / exit 0 |
| H2 | 差分ありでコメント追記 + 本文更新 + ラベル付与 | FINAL_PATH 設定 / diff あり → gh issue comment / edit / add-label の順で呼ばれる / stderr info\thuman_review_diff_recorded / exit 0 |
| H3 | コメント追記失敗時は本文 update / ラベルをスキップ | gh issue comment 失敗 → stderr warn\thuman_review_gh_comment_failed / 本文 update 呼ばれない / exit 0 |
| H4 | 本文 update 失敗時はラベル付与をスキップ | gh issue edit 失敗 → stderr warn\thuman_review_gh_edit_failed / ラベル付与呼ばれない / exit 0 |
| H5 | ラベル付与失敗は warn のみで継続 | gh issue edit --add-label 失敗 → stderr warn\thuman_review_label_failed / exit 0 |
| H6 | 既に human_reviewed: true の冪等 skip | 既存本文 true → 全 gh 呼び出しなし / stderr info\thuman_review_already_done / exit 0 |
| H7 | issue_url == "" は no-op skip | 引数 issue_url 空 → 全 gh 呼び出しなし / stderr info\thuman_review_skip_no_issue / exit 0 |
| H8 | issue_url 形式不正は exit 2 | issue_url が `ftp://...` 等 → stderr error\thuman_review_invalid_url / exit 2（引数形式不正は引数系 exit 2 で統一） |
| H9 | 引数欠落は exit 2 | 引数 < 2 → stderr error\thuman_review_missing_args / exit 2 |
| H10 | FINAL_PATH の I/O エラーは exit 1 | FINAL_PATH 指定 / ファイル不在 → stderr error\thuman_review_io_error / exit 1 |
| H11 | コメント追記 → 本文 update の順序固定 | bats stub の呼び出し順序を assert（comment が先 / edit が後） |

### `tests/retrospective-verify.bats`

| ID | 観点 | 動作 |
|----|------|------|
| V1 | 全件 human_reviewed: true で exit 0 | gh issue list で 3 件 verified → stdout サマリ / exit 0 |
| V2 | 1 件 unverified で exit 1 | gh issue list で 1 件 false → stdout 各 Issue / exit 1 |
| V3 | 旧仕様 Issue は skipped | gh issue list で本文に YAML ブロックなし → state=skipped / exit 0（--strict なし） |
| V4 | --strict 時は skipped で exit 1 | --strict + skipped 1 件 → exit 1 |
| V5 | --dry-run は副作用なし | --dry-run → gh issue edit 呼ばれない / stdout レポートのみ |
| V6 | gh 不可で exit 1 | gh コマンド失敗 → stderr error\tverify_gh_unavailable / exit 1 |
| V7 | Milestone 不在で exit 1 | --cycle 指定だが Milestone 不在 → stderr error\tverify_milestone_not_found / exit 1 |
| V8 | --cycle 未指定時の解決 | 設定 [project].cycle あり → そちらを使用 |
| V9 | --cycle 未指定 + 設定不在で最新 Milestone | 設定不在 + open Milestone あり → 最新 title を使用 |
| V10 | cycle 未解決で exit 1 | --cycle 不在 + 設定不在 + Milestone 不在 → stderr error\tverify_cycle_unresolved / exit 1 |
| V11 | --help は exit 0 | --help → usage 表示 / exit 0 |
| V12 | YAML 存在 + human_reviewed キー欠落で unverified（指摘 #2 反映） | 本文に末尾 YAML ブロックあり / `human_reviewed` キー欠落 → state=unverified / exit 1（VerificationStateClassifier の判定ルール検証） |
| V13 | YAML パース失敗で unverified + warn（指摘 #2 反映） | 不正な YAML 構造 → state=unverified / stderr warn / exit 1 |

---

## 技術選定

| 項目 | 選定 | 理由 |
|------|------|------|
| YAML パース | `dasel` または `yq`（既存 Unit 002 で使用済み） | プロジェクト既存依存。シェルから扱いやすい |
| 一時ファイル | `mktemp` | POSIX 互換 / プロジェクト既存スクリプトで使用済み |
| 文字列正規化 | bash builtin（パラメータ展開 / 正規表現） | 外部依存最小化 |
| `gh issue` API | `gh issue edit --body-file` / `gh issue comment --body-file` / `gh issue edit --add-label` | gh CLI の正規 API |
| URL 検証 | bash 正規表現 `^https?://` | 外部依存なし |
| BATS テスト | bats-core | プロジェクト既存テストフレームワーク |
| `gh` モック | bats setup で stub 関数定義（`function gh() { ... }`） | プロジェクト既存パターン（Unit 001 / 002 と同じ） |

---

## 実装上の注意事項

- **コマンド置換禁止**: 全シェルコードで `$()` / バッククォート使用禁止（`.aidlc/rules.md` 規約）。代替手段:
  - 動的値はパラメータ展開 / リダイレクト + read 形式
  - Unit 001 / Unit 002 と同じパターンを踏襲
- **`bin/check-bash-substitution.sh` 違反 0**: 新規スクリプト・テストファイルで CI チェックを必ず pass
- **環境変数命名**: `AIDLC_RETRO_LLM_DRAFT_*` / `AIDLC_RETRO_HUMAN_REVIEW_*` / `AIDLC_TEST_MODE` を採用。既存 `AIDLC_RETRO_*`（Unit 002 由来）/ `AIDLC_FORCE_INTERACTIVE`（Unit 001 由来）/ `AIDLC_PROJECT_ROOT` との衝突なし
- **shellcheck warning ゼロ**: 新規スクリプト・テストファイルで shellcheck の warning 以上を 0 件に維持
- **markdownlint pass**: 新規 `agents/retrospective-drafter.md` を含む Markdown ファイルが markdownlint pass
- **gh CLI フェイク stub**: BATS では `function gh() { ... }` で stub 関数を定義し、引数パターンに応じて固定応答を返す（Unit 002 BATS と同じ手法）

---

## 不明点と質問（設計中に記録）

（現時点で不明点なし。Phase 2 実装中に判明したものはここに追記）
