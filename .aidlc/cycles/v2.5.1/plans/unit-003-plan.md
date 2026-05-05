# Unit 003 計画: 主因分類 LLM 下書き + 人間確認運用

## 概要

retrospective Issue 起票時に、各 Problem 項目に対して主因分類（プロダクト固有 / AI-DLC 固有 / 両方）と `skill_caused_judgment`（q1/q2/q3 + 引用文）を **Claude Code の `retrospective-drafter` subagent** が下書き生成し、Unit 002 の `retrospective_body_compose()` に prefill 入力として渡す。LLM 失敗 / タイムアウト時は AskUserQuestion による手動入力 fallback、CI / 非対話環境では skip（Unit 001 `feedback_mode_resolve()` の `disabled` 判定に従う）。

Issue 起票後は **人間確認運用**として、ユーザーが LLM 下書きの内容を確認し、訂正があれば `gh issue edit` で本文 YAML を更新して `human_reviewed: true` に変える。LLM 推論結果と最終結果に差分があれば `[llm-diff]` プレフィックス付きコメントで記録し、将来の自動分析で抽出可能にする。

`human_reviewed: true` 未付与の Issue を CI で検出する `scripts/retrospective-verify.sh` を新規実装し、振り返り運用の品質を機械的に担保する。

## 関連 Issue

- #592 partial（Unit 007 主因切り分け 3 分類、v2.5.0 で導入済 → 本 Unit で LLM 下書き化）

## 関連サイクル設計判断（Intent 参照）

- §「主要設計判断 2」LLM 下書き実行マトリクス: 本 Unit が `retrospective-drafter` subagent を primary、AskUserQuestion を fallback として実装する正本
- §「主要設計判断 6.3」LLM 下書き出力契約: 本 Unit が出力する YAML スキーマ（必須キー + fallback 既定値）の正本。Unit 002 `retrospective_body_compose()` がこれを prefill 入力として受理
- §「主要設計判断 6.4」`human_reviewed` 付与責任: 本 Unit は Issue 起票後の本文更新（`false → true`）を担当。Unit 002 は起票時に `false` 初期値で埋め込むのみ
- §「成功基準」LLM 下書き prefilled 確認: 本 Unit のテストが `gh issue view <N> --json body | jq` で抽出可能なことを verify
- §「リスク 2」緩和策（LLM 出力に対する `human_reviewed` マーカー）: 本 Unit が Issue 本文の YAML キーで保持

## 関連 Unit 提供 I/F（呼び出し側）

| I/F 提供元 | I/F | 利用シーン |
|-----------|-----|-----------|
| Unit 001 | `feedback_mode_resolve()` | LLM 下書き実行可否判定（`disabled` 時は subagent 起動せず skip） |
| Unit 002 | `retrospective_body_compose(draft_yaml_path, kpt_md_path, cycle)` | LLM 下書き YAML を本文に prefill 埋め込み |
| Unit 002 | `retrospective_issue_create(body_path, feedback_mode, cycle)` | Issue 起票（Unit 003 は呼び出さず、§1.5 Step 5 が呼ぶ） |
| Unit 002 | §1.5 Step 3 prefill フック差し込み口 | hook 呼び出し口に Unit 003 hook 関数実装を接続（subagent 起動は AI エージェント前段手順 / hook 関数自身は責務外） |
| Unit 002 | §1.5 Step 6 起票後 update フック差し込み口 | hook 呼び出し口に Unit 003 hook 関数実装を接続。`human_reviewed` 本文更新 + 差分コメント追記は hook 内部で実行 |

## 変更対象ファイル

### 新規作成

#### サブエージェント / ヘルパー

- `skills/aidlc/agents/retrospective-drafter.md`（または `agents/retrospective-drafter/SKILL.md`）: `retrospective-drafter` subagent 定義。入力（Problem 一覧）+ 出力契約（Intent §6.3 YAML スキーマ）+ プロンプトテンプレート + 失敗判定ルール（30 秒応答なし / スキーマ違反 → fallback 要求）
- `skills/aidlc/scripts/lib/retrospective-llm-draft.sh`: 04-completion §1.5 Step 3 から Unit 002 経由で呼ばれる prefill フック実装。**公開関数 `retrospective_prefill_hook(cycle, kpt_md_path)`**（Unit 002 plan §「Unit 003 フック契約」と完全一致する I/F）。環境変数 `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` から subagent 出力 YAML を受け取って stdout に流す（subagent 経路）/ 環境変数未設定時は空 stdout フォールバック / `AIDLC_TEST_MODE=1` + `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` のテストモック対応。AskUserQuestion 起動 / subagent 起動の責務は持たない（AI エージェント手順側で前段準備）
- `skills/aidlc/scripts/lib/retrospective-human-review.sh`: 04-completion §1.5 Step 6 から Unit 002 経由で呼ばれる起票後 update フック実装。**公開関数 `retrospective_update_hook(issue_url, cycle)`**（Unit 002 plan §「Unit 003 フック契約」と完全一致する I/F）。本文 update（`human_reviewed: false → true`）+ 差分検出 + `[llm-diff]` コメント追記 + Issue ラベル `human-reviewed` 付与（任意）。差分検出に必要な「人間確認後の最終 YAML」は `AIDLC_RETRO_HUMAN_REVIEW_FINAL_PATH` 環境変数で受け取り、未設定時は「差分なし」扱い。`gh` 失敗時は exit 0 + stderr `warn\thuman_review_gh_*_failed\t...`
- `skills/aidlc/scripts/retrospective-verify.sh`: 新規 CLI。`--cycle <CYCLE>`（任意 / 既定は `[project].cycle` 設定 or 最新 Milestone）/ `--strict`（任意 / `human_reviewed: false` 全件で exit 1）/ `--dry-run`。`gh issue list --label retrospective --milestone <CYCLE>` で取得した Issue を走査し、本文 YAML から `human_reviewed` を抽出して `true` 未満を検出。終了コード `0=全件確認済み or 0 件 / 1=未確認あり / 2=引数エラー / gh 不可`

#### テスト

- `tests/retrospective-llm-draft.bats`: **hook 関数本体の試験のみ**（環境変数入力 / スキーマ検証 / `disabled` / 非対話 skip 判定 / `AIDLC_TEST_MODE` ガード / production 誤設定検出 / I/O エラー）。AskUserQuestion fallback 経路 / 30 秒タイムアウト判定 / subagent 起動経路は **AI エージェント手順側の責務**であり、`agents/retrospective-drafter.md` 内の呼び出し例 documentation の検証項目（review チェックリスト + Construction Phase 完了処理での目視確認）として切り分ける（hook 関数の bats からは除外）
- `tests/retrospective-human-review.bats`: 差分なし時の更新（`human_reviewed: true` のみ）/ 差分あり時の `[llm-diff]` コメント追記 / `gh issue edit` 失敗時の警告のみ継続（§1.5 を止めない）/ Issue ラベル付与失敗時のフォールバック
- `tests/retrospective-verify.bats`: 全件 `human_reviewed: true` の正常系 / 1 件 `false` で exit 1 / `--dry-run` で副作用なし / `--strict` 動作 / `gh` 不可時の exit 2 / Milestone 解決の正常系・異常系

### 変更

- `.github/workflows/migration-tests.yml`（または既存 BATS workflow）: 新規 BATS 3 ファイルを CI に追加
- `.github/workflows/`（新規 or 既存追加）: `retrospective-verify.sh` を CI で実行する workflow（`schedule` で月次 or `workflow_dispatch` 手動）

### 編集しない（境界保護）

- `skills/aidlc/steps/operations/04-completion.md`: **§1.5 ステップ本体は Unit 003 では編集しない**（Intent §「主要設計判断 6.5」§1.5 編集主体は Unit 002）。Unit 002 が用意した hook 呼び出し口（`command -v retrospective_prefill_hook` / `command -v retrospective_update_hook`）に対し、本 Unit 003 は hook 関数の **実装ファイル（`scripts/lib/retrospective-llm-draft.sh` 等）を提供** することで責務を果たす。subagent 起動の AI エージェント手順は `agents/retrospective-drafter.md` subagent 定義ファイルに呼び出し例として記載する
- `skills/aidlc/scripts/lib/retrospective-issue.sh`（Unit 002 中核ライブラリ。本 Unit は呼び出すのみで編集しない）
- `skills/aidlc/scripts/retrospective-resend.sh`（Unit 002 の spool 再送 CLI）
- `skills/aidlc/scripts/lib/feedback-mode.sh` / `feedback-mode-wizard.sh`（Unit 001）

## I/F 正本の統一規則（Unit 002 plan §「Unit 003 フック契約」を上位正本として採用）

本計画 / 論理設計 / ドメインモデルの 3 資料で I/F 記述が混在しないよう、Unit 002 plan §「Unit 003 フック契約」を **cross-unit 正本**として採用し、本 Unit 003 はそこで定義された関数名・引数・戻り値・exit code を踏襲する。アダプタ層は設けない（hook 関数として直接公開）。

### `retrospective_prefill_hook(cycle, kpt_md_path)` （Unit 002 契約準拠）

- **入力**: `cycle: string` / `kpt_md_path: string`（KPT セクション本文の Markdown ファイルパス）
- **出力**: stdout に Intent §6.3 スキーマの YAML を出力（成功時）。skip / fallback の場合は空 stdout（Unit 002 が空 YAML フォールバックで本文構築継続）
- **戻り値（exit code）**: `0=成功（成功 / fallback / skip いずれも、警告は stderr）` / `1=ランタイム異常（書き込み失敗等）` / `2=引数エラー`
- **状態通知（stderr 警告）**: 各 fallback 経路では `<level>\t<code>\t<detail>` 形式（プロジェクト規約準拠 / `<level>` ∈ `{info, warn, error}`）で stderr に状態を出力。`<code>` は `llm_draft_subagent_skip` / `llm_draft_subagent_timeout` / `llm_draft_schema_violation` / `llm_draft_fallback_user_input` / `llm_draft_skip_disabled` / `llm_draft_skip_non_interactive` 等
- **副作用**: 環境変数 `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` / `AIDLC_RETRO_LLM_DRAFT_OVERRIDE`（テストモード時）が指す一時ファイルの読取のみ。**AskUserQuestion / subagent 起動の責務は持たない**（責務分離: AI エージェント前段手順 / `agents/retrospective-drafter.md` 内の呼び出し例参照）

### `retrospective_update_hook(issue_url, cycle)` （Unit 002 契約準拠）

- **入力**: `issue_url: string`（起票済み Issue URL / 空文字列時は no-op）、`cycle: string`
- **出力**: stdout は任意（指定しない / 状態は stderr に出力）
- **戻り値（exit code）**: `0=成功（差分なし / 差分ありで更新成功 / `gh` 失敗時の警告継続を含む、警告付き完了は常に exit 0）` / `1=ランタイム異常（引数 issue_url が無効 URL 形式で URL 検証失敗等）` / `2=引数エラー（必須引数欠落）`
- **状態通知（stderr 警告）**: `<level>\t<code>\t<detail>` 形式で stderr に出力。`<code>` は `human_review_skip_no_diff` / `human_review_diff_recorded` / `human_review_gh_edit_failed` / `human_review_gh_comment_failed` / `human_review_label_failed` 等
- **副作用**: `gh issue edit <N> --body-file ...` で本文置換 / `gh issue comment <N> --body ...` で `[llm-diff]` コメント追記 / `gh issue edit <N> --add-label human-reviewed` でラベル付与（任意 / 失敗時は warn のみ / 失敗コード `human_review_label_failed`）

#### exit code 設計（指摘 #4 対応 / `guides/exit-code-convention.md`「警告付き完了は exit 0」準拠）

| 状況 | exit code | stderr 出力 |
|------|-----------|-------------|
| 差分なしで本文更新スキップ（`human_reviewed` だけ true 化） | 0 | `info\thuman_review_skip_no_diff\t...` |
| 差分ありで `gh issue edit` + `[llm-diff]` comment 成功 | 0 | `info\thuman_review_diff_recorded\t...` |
| `gh issue edit` 失敗（API レート制限等） | 0 | `warn\thuman_review_gh_edit_failed\t...` |
| `gh issue comment` 失敗（コメント追記不可） | 0 | `warn\thuman_review_gh_comment_failed\t...` |
| `human-reviewed` ラベル付与失敗 | 0 | `warn\thuman_review_label_failed\t...` |
| 引数 issue_url 形式不正（http(s) 以外） | 1 | `error\thuman_review_invalid_url\t...` |
| 必須引数欠落（issue_url 未指定 = 0 引数） | 2 | `error\thuman_review_missing_args\t...` |

これにより Unit 002 は `retrospective_update_hook` 失敗（非 0）を「警告のみで継続」する境界仕様を維持しつつ、本 hook 自体は正常系で常に exit 0 を返す。

### `retrospective-verify.sh`（CLI）

- **入力（引数）**: `--cycle <CYCLE>`（任意）/ `--strict`（任意）/ `--dry-run`（任意）/ `--help`
- **出力**: stdout に Issue ごとの状態を `<state>\t<issue_number>\t<title>` 形式で出力（`state` ∈ `{verified, unverified, skipped}`）/ stderr に warn 行（`<level>\t<code>\t<detail>` プロジェクト規約準拠）
- **終了コード**: `0=全件確認済み or 0 件 / 1=未確認あり（`unverified` ≥ 1）/ 2=引数エラー / gh 不可 / Milestone 不在`

### subagent 出力 YAML スキーマ（Intent §6.3 正本）

- 必須キー: `problem_drafts[].problem_id` / `primary_cause` / `primary_cause_reason` / `skill_caused_judgment.{q1,q2,q3}_{answer,quote}`
- 任意キー: `confidence`
- fallback 既定値: 全フィールドを空文字列または `"no"` で埋め、`primary_cause = "product"` を仮置き

## §1.5 Step 3 / Step 6 の責務分担（Unit 003 は §1.5 ステップ本体を編集しない）

§1.5 ステップ本体の編集主体は Unit 002（Intent §「主要設計判断 6.5」）。Unit 003 は §1.5 を編集せず、Unit 002 が既に組み込んだ hook 呼び出し口（`command -v retrospective_prefill_hook` / `command -v retrospective_update_hook`）に対し、hook 関数の **実装ファイル**を提供することで責務を果たす。

| Step | Unit 002 が §1.5 に記述済 | Unit 003 が本計画で提供する |
|------|---------------------------|-----------------------------|
| Step 3 | `command -v retrospective_prefill_hook` で関数存在を確認し、定義済なら呼び出して stdout の YAML を取得（失敗時は空 YAML フォールバック） | `retrospective_prefill_hook(cycle, kpt_md_path)` の **関数本体実装**（`scripts/lib/retrospective-llm-draft.sh`）+ subagent 起動経路の AI エージェント手順（`agents/retrospective-drafter.md` 内の呼び出し例として記載） |
| Step 6 | `command -v retrospective_update_hook` で関数存在を確認し、定義済なら呼び出す（失敗時は警告のみで §1.5 継続） | `retrospective_update_hook(issue_url, cycle)` の **関数本体実装**（`scripts/lib/retrospective-human-review.sh`）+ 人間確認 AskUserQuestion 手順（AI エージェント側）+ 差分検出 + `gh issue edit --body-file` / `gh issue comment` / `gh issue edit --add-label` 呼び出し |

`disabled` モード時は Step 3 / 6 ともスキップ（hook 関数自体が `feedback_mode_resolve()` の `disabled` 戻り値を見て即 exit 0 + `info\tllm_draft_skip_disabled\t...` を stderr に出力。subagent 起動なし / `human_reviewed` 更新なし）。

**hook 関数のロード経路**: Unit 003 が提供する実装ファイルを `04-completion.md §1.5` 実行前に source する手順は、Unit 002 が §1.5 内で記述する（Unit 002 plan の責務範囲）。Unit 003 は実装ファイルのパスを Unit 002 に伝達するのみ。

## subagent 化方針（指摘想定で先回り）

- **subagent 化を採用**（Unit 定義「技術的考慮事項」推奨に従う）。理由: メインエージェントの context 肥大を防ぎ、retrospective 下書き専用のプロンプトと出力契約に集中させる
- **subagent 定義の場所**: `skills/aidlc/agents/retrospective-drafter.md`（プラグイン同梱）
- **責務分離（境界保護）**: subagent 起動は Claude Code の AI エージェント（main agent）が担う。Unit 003 が提供する **シェル関数 `retrospective_prefill_hook` は subagent 起動の責務を持たない**。代わりに、AI エージェントが §1.5 実行前に subagent を起動して結果 YAML を一時ファイルに保存し、`AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` 環境変数にそのパスをセットしてから §1.5 を実行する。`retrospective_prefill_hook` は環境変数の有無で挙動分岐:
  - `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` が定義済かつファイルが Intent §6.3 スキーマ準拠 → そのファイル内容を stdout に流す（subagent 経路）
  - 環境変数未定義 / ファイル不在 / スキーマ違反 → stderr に `warn\tllm_draft_subagent_unavailable\t...` を出力した上で空 stdout を返す（Unit 002 の空 YAML フォールバック経路に乗せる）。AskUserQuestion での fallback は、AI エージェントが **§1.5 実行前**にユーザーに確認を取って結果を環境変数に書き戻す形で実現（hook 関数自身は AskUserQuestion を直接起動しない / シェル関数のステートレス性を保つ）
- **AI エージェント手順の記載場所**: subagent 起動 / 環境変数受け渡し / AskUserQuestion 経由 fallback の手順は **`agents/retrospective-drafter.md` subagent 定義ファイルの『呼び出し例』セクション** に記載する（§1.5 ステップ本体に記載しない）。Operations Phase 実行時、Claude Code エージェントは subagent 定義をロードしてから §1.5 を実行する運用を確立
- **テストモック経路（指摘 #5 反映 / production 侵食ガード）**: `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` 環境変数によるテストモックは **`AIDLC_TEST_MODE=1` が同時に設定されている場合のみ発動**。production で `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` が設定されていても `AIDLC_TEST_MODE` が未設定なら無視 + stderr に `error\tllm_draft_override_in_production\t...` を出力（誤設定検出 + production 安全性確保）。BATS テストの setup でのみ `AIDLC_TEST_MODE=1` を export し、本番運用では決して export しない方針を documentation に明記

## 失敗 / fallback 経路の網羅（指摘 #3 反映: Intent §「主要設計判断 2」実行マトリクス準拠 / CI 例外なし）

`retrospective_prefill_hook` の動作経路を、AI エージェント手順（subagent 起動 / AskUserQuestion 起動）と hook 関数本体の責任で分離して整理する:

### AI エージェント手順による前段準備（§1.5 実行前）

| 経路 | 発動条件 | 担当 | AI エージェントの動作 | hook 入力 |
|------|---------|------|----------------------|----------|
| subagent 経路 | 対話セッション + `feedback_mode_resolve()` ≠ `disabled` + LLM 利用可能 | AI エージェント | retrospective-drafter subagent を起動 → Intent §6.3 スキーマ準拠 YAML を取得 → 一時ファイルに保存 → `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH=<path>` を export | `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` 環境変数（パス） |
| AskUserQuestion fallback 経路 | subagent タイムアウト（30 秒）/ スキーマ違反 / 起動失敗 | AI エージェント | AskUserQuestion で 3 分類選択 + q1/q2/q3 yes/no を対話取得 → Intent §6.3 fallback 既定値で構造を埋めた YAML を一時ファイルに保存 → `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH=<path>` を export | 同上（fallback 既定値入りファイル） |
| skip (CI / 非対話) | tty 不在（Intent §「判断 2」の非対話セッション / CI に該当） | AI エージェント | subagent 起動 / AskUserQuestion 起動を行わず、`AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` を export しない | （未設定） |

### hook 関数本体の挙動（`retrospective_prefill_hook` 内部分岐）

| 経路 | 発動条件 | 動作 | exit code | stderr |
|------|---------|------|----------|--------|
| subagent / fallback 経路 | `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` 定義済 + ファイル存在 + スキーマ準拠 | ファイル内容を stdout に流す | 0 | `info\tllm_draft_subagent_emitted\t...` |
| skip (disabled) | `feedback_mode_resolve()` が `disabled` を返却 | 空 stdout（Unit 002 が空 YAML フォールバックで継続） | 0 | `info\tllm_draft_skip_disabled\t...` |
| skip (非対話) | tty 不在 + 環境変数未設定（CI / 非対話セッション） | 空 stdout | 0 | `info\tllm_draft_skip_non_interactive\t...` |
| 環境変数未設定（対話だが AI エージェント手順未実施） | tty あり + 環境変数未設定 | 空 stdout（Unit 002 が空 YAML フォールバックで継続）+ AI エージェントへの誤設定警告 | 0 | `warn\tllm_draft_subagent_unavailable\t...` |
| ファイル不在 / スキーマ違反 | `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` 定義済だが内容が無効 | 空 stdout（Unit 002 が空 YAML フォールバックで継続） | 0 | `warn\tllm_draft_schema_violation\t<detail>` |
| 引数エラー | 引数 < 2（cycle / kpt_md_path 欠落） | （何もしない） | 2 | `error\tllm_draft_missing_args\t...` |
| ランタイム異常 | 環境変数で指定された一時ファイル読み込みで I/O エラー（permission denied 等） | 空 stdout + 警告 | 1 | `error\tllm_draft_io_error\t<detail>` |
| テストモード | `AIDLC_TEST_MODE=1` + `AIDLC_RETRO_LLM_DRAFT_OVERRIDE=<path>` 設定済 | `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` のファイル内容を stdout に流す（環境変数 `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` より優先） | 0 | `info\tllm_draft_test_override\t...` |
| production 誤設定検出 | `AIDLC_TEST_MODE` 未設定 + `AIDLC_RETRO_LLM_DRAFT_OVERRIDE=<path>` 設定済 | OVERRIDE 値を無視 + 通常経路で評価 | 0 | `error\tllm_draft_override_in_production\t<detail>` |

**Intent §「主要設計判断 2」整合**: 「対話セッション → primary は subagent / fallback は手動入力」「非対話 / CI → skip（手動入力 fallback も実装しない）」「LLM 失敗 / タイムアウト → 手動入力 fallback」を上記 2 表で網羅。**`mirror-only` を CI で動作させる例外は設けない**（Intent 厳守）。

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**（`design-artifacts/domain-models/unit_003_llm_draft_and_human_review_domain_model.md`）
   - `LLMDraft` 集約: `problem_drafts[]` / `confidence` / `result_status`（success / fallback / skip）
   - `ProblemDraft` 値オブジェクト: `problem_id` / `primary_cause` / `primary_cause_reason` / `skill_caused_judgment`
   - `SkillCausedJudgment` 値オブジェクト: q1/q2/q3 の `{answer, quote}`
   - `HumanReviewMarker` 値オブジェクト: `human_reviewed: bool` + 更新タイミング不変条件
   - `LLMDiffComment` 値オブジェクト: `[llm-diff]` プレフィックス + 差分セクション + LLM 推論 vs 確認後の対比
   - `RetrospectiveVerification` 集約: 検証対象 Issue 集合 + `unverified` 検出ロジック
   - `RetrospectiveDrafterAgent` ドメインサービス: subagent 起動 / タイムアウト判定 / スキーマ検証
   - `HumanReviewOrchestrator` ドメインサービス: AskUserQuestion 取得 → 差分判定 → gh 更新の workflow
2. **論理設計**（`design-artifacts/logical-designs/unit_003_llm_draft_and_human_review_logical_design.md`）
   - `retrospective-drafter.md` subagent プロンプト（Problem 一覧入力 → Intent §6.3 スキーマ YAML 出力）
   - `retrospective_prefill_hook()` の処理フロー（環境変数による subagent 結果受け取り / `AIDLC_TEST_MODE` ガード / production 誤設定検出 / fallback 分岐）
   - `retrospective_update_hook()` の処理フロー（差分検出アルゴリズム / `gh issue edit --body-file` / `gh issue comment` / `gh issue edit --add-label` API 呼び出し順序 / `[llm-diff]` コメント生成 / 失敗時 exit 0 維持）
   - **AI エージェント手順**（subagent 起動 / 30 秒タイムアウト判定 / AskUserQuestion fallback / 環境変数 export）の `agents/retrospective-drafter.md` 内 documentation 仕様
   - `retrospective-verify.sh` の処理フロー（Milestone 解決 / Issue 列挙 / YAML パース / 状態判定 / exit code 規約）
   - 04-completion.md §1.5 Step 3 / Step 6 の **Unit 002 既存改修内容との整合確認（参照のみ / Unit 003 では §1.5 ステップ本体を編集しない）**。設計成果物にスナップショット引用 + ギャップ判定（Unit 002 改修のままで Unit 003 hook が問題なく呼ばれるか）を記載
   - BATS テストケース一覧 + `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` モック経路の仕様
3. **設計レビュー**（`reviewing-construction-design` スキル / 優先ツール codex）
4. **設計承認**（`semi_auto` → 自動承認 or fallback）

### Phase 2: 実装

5. **コード生成**
   - `skills/aidlc/agents/retrospective-drafter.md` 新規作成（subagent 定義 + 呼び出し例セクション）
   - `skills/aidlc/scripts/lib/retrospective-llm-draft.sh` 新規作成（`retrospective_prefill_hook(cycle, kpt_md_path)` 実装）
   - `skills/aidlc/scripts/lib/retrospective-human-review.sh` 新規作成（`retrospective_update_hook(issue_url, cycle)` 実装）
   - `skills/aidlc/scripts/retrospective-verify.sh` 新規作成
   - **`skills/aidlc/steps/operations/04-completion.md` §1.5 ステップ本体は編集しない**（Unit 002 が記述済の hook 呼び出し口を利用するのみ。Unit 003 の境界保護）
6. **コード AI レビュー**（`reviewing-construction-code` スキル / 優先ツール codex）
7. **テスト生成**
   - `tests/retrospective-llm-draft.bats`（hook 関数本体の分岐のみ: env 入力 / スキーマ検証 / `disabled` skip / 非対話 skip / I/O 異常 / `AIDLC_TEST_MODE` ガード / production 誤設定検出。AskUserQuestion / タイムアウト / subagent 起動は対象外で、`agents/retrospective-drafter.md` 内 documentation 検証項目として切り分け）
   - `tests/retrospective-human-review.bats`（差分なし / 差分あり / `gh` 失敗時の継続性 / ラベル付与失敗）
   - `tests/retrospective-verify.bats`（正常系 / `false` 検出 / `--dry-run` / `--strict` / `gh` 不可 / Milestone 不在）
8. **ビルド・テスト実行**（BATS / shellcheck / markdownlint / `bin/check-bash-substitution.sh`。Self-Healing ループで修正）
9. **統合 AI レビュー**（`reviewing-construction-integration` スキル / 優先ツール codex）
10. **実装承認**（`semi_auto` → 自動承認 or fallback）

### 完了処理

11. 完了条件チェック / 設計・実装整合性チェック / 意思決定記録参照確認 / AI レビュー実施確認
12. Unit 定義ファイル状態を「完了」に更新
13. 履歴記録（`/write-history` で `history/construction_unit03.md`）
14. Markdownlint 実行（`markdown_lint=true`）
15. Squash（`squash_enabled=true` / `squash-unit.sh`）
16. Git コミット
17. コンテキストリセット提示

## 完了条件チェックリスト

Unit 定義「責務」セクション + Intent §「成功基準」+ Intent §「主要設計判断 2 / 6.3 / 6.4」+ Intent §「リスク 2」から抽出。

### Unit 責務由来

- [ ] `retrospective-drafter` subagent 定義が `skills/aidlc/agents/retrospective-drafter.md` で提供される
- [ ] 主因分類 3 値 + `skill_caused_judgment` q1/q2/q3 引用文の自動下書き生成ロジックが Intent §6.3 スキーマで Unit 002 に出力される
- [ ] LLM 失敗 / タイムアウト時の AskUserQuestion fallback が動作し、Intent §6.3 fallback 既定値で構造を埋める
- [ ] CI / 非対話環境での skip 判定が Unit 001 `feedback_mode_resolve()` の戻り値に従う（`disabled` 動作と同等）
- [ ] Issue 起票後、本 Unit が Issue 本文を更新して `human_reviewed: true` を付与する（Unit 002 起票時 `false` からの遷移）
- [ ] LLM 推論 vs 人間確認結果の差分検出 + `[llm-diff]` プレフィックス付き Issue コメント記録が動作する
- [ ] `scripts/retrospective-verify.sh` が `human_reviewed: true` 未付与の Issue を検出して exit ≥ 1 を返す
- [ ] **境界保護**: 04-completion §1.5 ステップ本体への変更は **行われていない**（`git diff skills/aidlc/steps/operations/04-completion.md` で本 Unit のコミットでの変更が 0 件）。Unit 003 は hook 関数実装ファイル（`scripts/lib/retrospective-llm-draft.sh` / `scripts/lib/retrospective-human-review.sh`）と subagent 定義（`agents/retrospective-drafter.md`）を提供するのみ
- [ ] hook 関数（`retrospective_prefill_hook` / `retrospective_update_hook`）が Unit 002 plan §「Unit 003 フック契約」と完全一致する I/F（関数名・引数・stdout・exit code）で実装されている

### Intent 主要設計判断由来

- [ ] **判断 2 実行マトリクス**: primary が `retrospective-drafter` subagent、fallback が手動入力（AskUserQuestion）、CI / 非対話は skip、LLM 失敗は手動入力 fallback、の 4 経路がすべて documented されている。**hook 関数本体に関わる経路（`disabled` / 非対話 / I/O 異常 / `AIDLC_TEST_MODE` ガード）は BATS で verify**、**AI エージェント手順に関わる経路（subagent 起動 / AskUserQuestion 起動 / 30 秒タイムアウト判定）は `agents/retrospective-drafter.md` 内の documentation 検証**（review checklist + 完了処理での目視確認）として責務分離
- [ ] **判断 6.3 スキーマ**: 出力 YAML が必須キーを満たし、fallback 既定値が定義通り（`primary_cause = "product"` 仮置き、空文字列 / `"no"` で埋める）（BATS で verify）
- [ ] **判断 6.4 責任分離**: Unit 002 が起票時 `false` で埋め込み、Unit 003 が起票後に `true` へ更新することを `git diff` + BATS で確認できる

### Intent 成功基準由来

- [ ] **LLM 下書き prefilled**: 起票された Issue 本文に主因分類 + `skill_caused_judgment` の YAML ブロックが含まれ、`gh issue view <N> --json body | jq` で抽出可能（BATS でモック gh 経由で verify）

### Intent リスクと代替案検討由来

- [ ] **リスク 2 緩和**: LLM 出力に対する `human_reviewed: true` マーカーが Issue 本文に保持され、`retrospective-verify.sh` で機械検証可能であることが BATS で verify される

### NFR 由来

- [ ] **応答性**: LLM 下書きが 30 秒以内に応答しない場合は手動入力 fallback に切り替わる（タイムアウト判定 + AskUserQuestion fallback は AI エージェント手順の責務のため、`agents/retrospective-drafter.md` の documentation 検証 + review checklist で確認）
- [ ] **観測性**: LLM 推論失敗時に明示的なエラーメッセージ（stderr `<level>\t<code>\t<detail>`）が出力される
- [ ] **学習可能性**: 差分コメント（`[llm-diff]` プレフィックス）が将来の自動分析で抽出可能なフォーマット（プレフィックス固定 + Markdown 構造）

### 境界・責務由来（逆方向非依存検証）

- [ ] **Unit 002 中核ライブラリの呼び出しのみ**: `git diff` で `skills/aidlc/scripts/lib/retrospective-issue.sh` / `retrospective-resend.sh` / `templates/retrospective_template.md` への変更が含まれていない（Unit 002 の境界を侵していない）
- [ ] **Unit 001 の I/F 呼び出しのみ**: `git diff` で `skills/aidlc/scripts/lib/feedback-mode.sh` / `feedback-mode-wizard.sh` への変更が含まれていない（Unit 001 の境界を侵していない）
- [ ] **Unit 002 への prefill 入力**: `retrospective_body_compose()` が要求する Intent §6.3 スキーマで YAML を出力する（モック gh で verify）
- [ ] **Unit 002 から提供される `issue_url`**: `retrospective_update_hook(issue_url, cycle)` が `issue_url` を必須引数として受け取り、空文字列時は no-op（exit 0 + `info\thuman_review_skip_no_issue\t...` を stderr に出力して §1.5 を継続）
- [ ] **逆方向非依存テスト（consumer モック固定）**: Unit 003 BATS テストは以下のモックのみで成立する:
  - `retrospective_body_compose` / `retrospective_issue_create` → モック関数で固定 YAML / 固定 Issue URL を返す
  - subagent 起動 → `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` 環境変数で固定 YAML 注入
  - AskUserQuestion → モック関数で固定回答を返す
  - `gh` CLI → bats stub で `gh issue edit --body-file` / `gh issue comment` / `gh issue edit --add-label` / `gh issue list` の応答を固定
- [ ] **逆方向非依存検証**: Unit 003 BATS テストが Unit 001 / 002 の **実装ファイル**を参照しない（`grep` で確認）。本 Unit の I/F 契約（呼び出し）と Unit 001/002 の公開関数のみで成立する

### `bin/check-bash-substitution.sh` 規約準拠

- [ ] 新規スクリプト・テストファイルで `$()` / バッククォート使用 0（CI で violation 0 を verify）

## NFR

- **応答性**: LLM 下書き 30 秒タイムアウト fallback（Unit 定義 NFR 由来）
- **観測性**: LLM 推論失敗時の明示的エラーメッセージ（stderr フォーマット規約準拠）
- **学習可能性**: 差分コメントの `[llm-diff]` プレフィックス固定（将来の自動分析互換）
- **冪等性**: `retrospective_update_hook()` を同一 Issue に複数回呼んでも `human_reviewed: true` のまま不変（既に true なら no-op + exit 0 + `info\thuman_review_already_done\t...`）
- **CI 互換**: `retrospective-verify.sh` が GitHub Actions で実行可能（exit code でステータスを表現）

## リスク

- **R1**: subagent 起動契約が Claude Code 側で未確定（Task ツール / 別経路）。**緩和**: subagent 起動は AI エージェント（main agent）の責務とし、シェル関数 `retrospective_prefill_hook` は環境変数 `AIDLC_RETRO_LLM_DRAFT_PREFILL_PATH` 経由で結果を受け取る境界設計（指摘 #1 反映）。subagent 起動失敗 / タイムアウト時の AskUserQuestion fallback も AI エージェント側で実施し、結果ファイルに書き戻して環境変数で hook に渡す。`agents/retrospective-drafter.md` 内の呼び出し例セクションに具体手順を documentation。これにより Claude Code の Task ツール仕様変更があっても hook 関数本体への影響は局所化される
- **R2**: `gh issue edit` / `gh issue comment` の API レート制限。**緩和**: `retrospective_update_hook` は失敗時も exit 0 + stderr `warn\thuman_review_gh_*_failed\t...` を返す（指摘 #4 反映 / `guides/exit-code-convention.md`「警告付き完了は exit 0」準拠）。Unit 002 は exit 0 を「成功」として §1.5 を継続。失敗時 spool 退避は本 Unit 範囲外（Unit 002 の起票自体はすでに完了している前提）
- **R3**: `human_reviewed` 更新と `[llm-diff]` コメントの整合性破れ（一方失敗 / 他方成功）。**緩和**: コメント追記 → 本文 update の順序を固定（コメント失敗時は本文 update もスキップして次回 retry に委ねる）+ BATS で順序を verify。両方成功した場合のみ本文 `human_reviewed: true` 更新が完了することを invariant として保持
- **R4**: `retrospective-verify.sh` の Milestone 解決が `[project].cycle` 設定不在環境で失敗。**緩和**: Milestone 引数を `--cycle` 必須にする選択肢を残し、設計フェーズでデフォルト解決ルールを確定
- **R5**（指摘 #5 反映）: テストモック環境変数 `AIDLC_RETRO_LLM_DRAFT_OVERRIDE` の production 侵食リスク。**緩和**: `AIDLC_TEST_MODE=1` 必須ガード + production 誤設定時の `error\tllm_draft_override_in_production\t...` stderr 出力 + BATS setup でのみ `AIDLC_TEST_MODE=1` を export する規約を documentation。既存 Unit 001 の `AIDLC_FORCE_INTERACTIVE` 等のテスト用エスケープハッチとも統合的に整理（必要に応じて Unit 003 設計フェーズで命名規約を確認）

## 出力先（参考）

- 設計: `.aidlc/cycles/v2.5.1/design-artifacts/domain-models/unit_003_llm_draft_and_human_review_domain_model.md` / `.aidlc/cycles/v2.5.1/design-artifacts/logical-designs/unit_003_llm_draft_and_human_review_logical_design.md`
- 履歴: `.aidlc/cycles/v2.5.1/history/construction_unit03.md`
- レビューサマリ: `.aidlc/cycles/v2.5.1/construction/units/003-review-summary.md`
