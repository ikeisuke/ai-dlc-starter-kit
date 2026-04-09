# ドメインモデル: Unit 005 Tier 2 施策の統合

## 概要

Unit 005 は #519 Tier 2 施策の純粋リファクタリング（新機能追加なし）であり、対象ドメインは「AI-DLC の手順ドキュメント構造」と「Operations リリースフロー」の 2 領域にまたがる。Unit 001-004 で確立した Materialized Binding パターンのような規範仕様 + binding 層の導入ではなく、**既存の肥大化したファイルを責務単位で分離し、依存方向を一方向化する**シンプルな構造改善である。

本 Unit のドメインモデルは、以下の 2 つの独立した成果物を扱う:

1. **OperationsReleaseOrchestrator**: Operations Phase のステップ 7（リリース準備）を、シェルスクリプト化可能な機能群と人間判断が必要な markdown 記述に分離するオーケストレータ
2. **ReviewRoutingDecision**: AI レビューの「ルーティング判定（どのスキル・どのパスで実行するか）」を「実行手順（反復の回し方・指摘対応フロー）」から分離するための論理インターフェース契約

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。

---

## 領域 1: OperationsReleaseOrchestrator（operations-release スクリプト化）

### エンティティ: OperationsReleaseOrchestrator（概念エンティティ）

**位置づけ**: 実体はドキュメント（`operations-release.md`）+ シェルスクリプト（`operations-release.sh`）の 2 ファイルに分散するが、概念的には 1 つのオーケストレータが Operations Phase の「ステップ 7: リリース準備」全体を統括する。

- **責務**:
  - Operations Phase の Step 7 全 13 サブステップ（7.1〜7.13）の実行順序を保持する
  - 各サブステップを「スクリプト化対象（機能群）」または「markdown 記述対象（人間判断）」に分類する
  - 人間判断を要するサブステップの意思決定は markdown に残し、AI エージェントに実行を委譲する
  - 自動化可能なサブステップは `operations-release.sh` のサブコマンドとして実行される
- **不変条件**:
  - 全 13 サブステップのうち、スクリプト化 5 サブコマンド + markdown 残存 6 節 + 事実上 orchestration 済み 1 節（7.4 `/write-history` スキル）+ 事実上 orchestration 対象外 1 節（7.12 対話的レビュー）の分類が固定される
  - スクリプト化対象の節と markdown 残存節は重複しない（排他的分割）
  - スクリプト実行順序は既存 `operations-release.md` の現行順序と完全一致する（純粋リファクタリング制約）

### 値オブジェクト: ReleaseSubcommand

- **責務**: `operations-release.sh` の 1 つのサブコマンドを表す不変値
- **属性**:
  - `name`: サブコマンド名（`version-check` / `lint` / `pr-ready` / `verify-git` / `merge-pr` のいずれか）
  - `coveredSections`: 対応する `operations-release.md` の節番号リスト（例: `verify-git` なら `[7.9, 7.10, 7.11]`）
  - `delegatedScripts`: 呼び出す既存スクリプト名のリスト（例: `pr-ready` なら `[pr-ops.sh]`）
  - `dryRunSupport`: 常に `true`（全サブコマンドで `--dry-run` 必須）
  - `outputContract`: **透過契約**（既存スクリプトの stdout / 終了コードをそのまま透過する）。正規化（0/1/2 への変換等）は行わない。例外的に `pr-ready` の `--body-file` 必須エラーのみ透過ではなくラッパー固有の `exit 1` を返す
  - `stdoutFormat`: 既存スクリプトの stdout をそのまま透過。集約サマリが必要な場合は既存出力の**後**に接頭辞付きで追加（例: `verify-git:summary:uncommitted=warning:remote-sync=ok:default-branch=skipped`）
  - `humanDecisionPoints`: markdown 側に残す人間判断ポイントのリスト（例: `pr-ready` なら `["PR 本文テンプレート生成", "レビューサマリ挿入判断"]`）
- **不変条件**:
  - `name` は全体で一意
  - `coveredSections` 内の節はいずれかの `ReleaseSubcommand` にのみ帰属する（重複禁止）
  - `delegatedScripts` 内のスクリプトは本 Unit では変更しない（Unit 005 スコープ外）
  - `outputContract=透過` の原則により、ラッパーは既存スクリプトの契約（`validate-git.sh` の `status:warning` を exit 0 の stdout で返す、`validate-git.sh` のエラーは `return 2` で返す、`pr-ops.sh merge` は stdout に `merged` / `error:<code>` を返す等）を変更しない

### 値オブジェクト: MarkdownResidualSection

- **責務**: `operations-release.md` 本体に残る節を表す不変値
- **属性**:
  - `sectionNumber`: 節番号（`7.2` / `7.3` / `7.4` / `7.6` / `7.7` / `7.12` のいずれか）
  - `residualReason`: 残存理由の分類（`human_content_writing` / `human_decision` / `already_orchestrated` / `interactive_review`）
- **不変条件**:
  - `residualReason` は固定分類のいずれか
  - 本 Unit では新しい残存理由分類を追加しない

### ドメインサービス: SectionClassification

- **責務**: `operations-release.md` の各節を `ReleaseSubcommand.coveredSections` または `MarkdownResidualSection` に分類するルール
- **分類表**（本 Unit で固定）:

| 節 | 分類 | 帰属 |
|----|------|------|
| 7.1 バージョン確認 | スクリプト化 | `ReleaseSubcommand[name=version-check]` |
| 7.2 CHANGELOG 更新 | markdown 残存 | `human_content_writing` |
| 7.3 README 更新 | markdown 残存 | `human_content_writing` |
| 7.4 履歴記録 | markdown 残存 | `already_orchestrated`（`/write-history` スキル経由） |
| 7.5 Markdownlint 実行 | スクリプト化 | `ReleaseSubcommand[name=lint]` |
| 7.6 progress.md 更新 | markdown 残存 | `human_decision`（ファイル編集の意思決定） |
| 7.7 Git コミット | markdown 残存 | `human_decision`（`commit-flow.md` の責務） |
| 7.8 ドラフト PR Ready 化 | スクリプト化 | `ReleaseSubcommand[name=pr-ready]` |
| 7.9 コミット漏れ確認 | スクリプト化 | `ReleaseSubcommand[name=verify-git]` |
| 7.10 リモート同期確認 | スクリプト化 | `ReleaseSubcommand[name=verify-git]` |
| 7.11 main ブランチ差分チェック | スクリプト化 | `ReleaseSubcommand[name=verify-git]` |
| 7.12 PR マージ前レビュー | markdown 残存 | `interactive_review` |
| 7.13 PR マージ | スクリプト化 | `ReleaseSubcommand[name=merge-pr]` |

### 依存関係（領域 1）

- `OperationsReleaseOrchestrator` → `ReleaseSubcommand`（1 対多 / 5 個）
- `OperationsReleaseOrchestrator` → `MarkdownResidualSection`（1 対多 / 6 個）
- `ReleaseSubcommand` → `delegatedScripts`（参照のみ、実体は既存スクリプトであり本 Unit では変更しない）
- `SectionClassification` は純粋な分類ルールであり、他のエンティティへの依存を持たない

---

## 領域 2: ReviewRoutingDecision（review-flow 簡略化）

### エンティティ: ReviewRoutingRule（概念エンティティ）

**位置づけ**: AI レビューの「どのスキルで実行するか」「どの処理パスを通るか」を決定する純粋な判定ルール集。実体は `steps/common/review-routing.md` に集約される。`review-flow.md` との関係は一方向依存（`review-flow.md` → `review-routing.md`）。

- **責務**:
  - `ReviewRoutingInput`（`caller_context` / `review_mode` / `automation_mode` / `configured_tools` / `available_tools` / `tools_runtime_status`）を受け取り、`ReviewRoutingDecision` を導出する
  - 本ルールは「宣言的な判定テーブル」として記述され、実行時の状態・履歴に依存しない
  - `review-flow.md`（手順の正本）は本ルールの出力（`ReviewRoutingDecision`）を消費する立場であり、`review-routing.md` への依存は持つが、逆方向の依存を持たない
- **不変条件**:
  - `ReviewRoutingRule` は手順記述（反復ロジック、セッション管理、履歴記録、指摘対応フロー）を持たない
  - 入力が同じであれば常に同じ `ReviewRoutingDecision` を返す（純粋関数的）

### 値オブジェクト: ReviewRoutingInput（入力）

- **責務**: `ReviewRoutingRule` の入力を表す不変値
- **属性**:
  - `caller_context`: 9 種の `CallerContext` 列挙値のいずれか
  - `review_mode`: `required` / `recommend` / `disabled`
  - `automation_mode`: `manual` / `semi_auto`
  - `configured_tools`: `.aidlc/config.toml [rules.reviewing].tools` から取得した**優先順位リスト**（例: `["codex", "claude"]`、空配列可）
  - `available_tools`: 実際に `command -v` で検出された **使用可能 CLI の集合**（`configured_tools` のサブセット）
  - `tools_runtime_status`: 選択されたツールの実行時ステータス（`ok` / `cli_runtime_error` / `cli_output_parse_error`）。初回呼び出し時は `ok`

### 値オブジェクト: ReviewRoutingDecision（論理インターフェース契約）

- **責務**: `ReviewRoutingRule` の出力を表す不変値。`review-flow.md` の手順記述が消費する唯一の契約境界
- **属性**:
  - `selected_path`: `1` / `2` / `3`（1=外部 CLI レビュー、2=セルフレビュー、3=ユーザーレビュー直行）
  - `skill_name`: 使用する reviewing スキル名（例: `reviewing-construction-plan`、`reviewing-operations-premerge`）
  - `focus`: focus メタデータのリスト（例: `["architecture"]` / `["code", "security"]`）
  - `tool_name`: 使用する CLI ツール名（パス 1 のみ、パス 2/3 時は none）。`ToolSelection` ドメインサービスが決定する
  - `fallback_policy`: エラー発生時の挙動を定義するサブ値
    - `on_cli_missing`: `fallback_to_self` / `prompt_user_choice`
    - `on_runtime_error`: `retry_1_then_prompt` / `retry_1_then_user_choice`
    - `on_parse_error`: `fallback_to_self` / `prompt_user_choice`
  - `skip_reason_required`: `review_mode=required` でユーザー承認に落ちる場合 `true`
  - `user_rejection_allowed`: `review_mode=recommend` で `automation_mode=semi_auto` 時は `false`（自動継続）
- **不変条件**:
  - `selected_path=3` のとき `tool_name=none`
  - `selected_path=1` のとき `tool_name != none`
  - `review_mode=required` のとき `on_cli_missing = prompt_user_choice`（CLI 不在時は必ずユーザー承認フローへ）
  - `review_mode=recommend` のとき `on_cli_missing = fallback_to_self`（CLI 不在時はセルフレビューへフォールバック）
  - `automation_mode=semi_auto ∧ review_mode=recommend` のとき `user_rejection_allowed=false`

### 値オブジェクト: CallerContext

- **責務**: AI レビューの呼び出し元を識別する不変値
- **列挙値**（現行 9 種、本 Unit では新規追加しない）:
  - `計画承認前` / `設計レビュー` / `コード生成後` / `統合とレビュー`
  - `Intent 承認前` / `ストーリー承認前` / `Unit 定義承認前`
  - `デプロイ計画承認前` / `PR マージ前`
- **不変条件**: 新規 `CallerContext` の追加は本 Unit のスコープ外

### ドメインサービス: CallerContextMapping

- **責務**: `CallerContext` を `{skill_name, focus}` のタプルに写像する
- **マッピング表**（現行 `review-flow.md` §CallerContext マッピングから移管）:

| CallerContext | skill_name | focus |
|--------------|-----------|-------|
| 計画承認前 | `reviewing-construction-plan` | `[architecture]` |
| 設計レビュー | `reviewing-construction-design` | `[architecture]` |
| コード生成後 | `reviewing-construction-code` | `[code, security]` |
| 統合とレビュー | `reviewing-construction-integration` | `[code]` |
| Intent 承認前 | `reviewing-inception-intent` | `[inception]` |
| ストーリー承認前 | `reviewing-inception-stories` | `[inception]` |
| Unit 定義承認前 | `reviewing-inception-units` | `[inception]` |
| デプロイ計画承認前 | `reviewing-operations-deploy` | `[architecture]` |
| PR マージ前 | `reviewing-operations-premerge` | `[code, security]` |

### ドメインサービス: ToolSelection

- **責務**: `{configured_tools, available_tools}` から使用する `tool_name` を決定する（ツール選択責務の独立化）
- **判定ルール**（現行 `review-flow.md` §処理パス「`tools` リスト先頭から `which` で最初に見つかった CLI を使用」を規範化）:
  1. `configured_tools=[]`（空配列） → `tool_name=none`（セルフレビュー直行シグナル）
  2. `configured_tools ≠ []`:
     - `configured_tools` を先頭から走査し、`available_tools` に含まれる最初のツールを `tool_name` として返す
     - どのツールも `available_tools` に含まれない場合 → `tool_name=none`（`cli_missing_permanent` シグナル）

### ドメインサービス: PathSelection

- **責務**: `{review_mode, automation_mode, tool_name（ToolSelection の出力）, tools_runtime_status}` から `selected_path` と `user_rejection_allowed` を決定する
- **入力境界**: `PathSelection` は `tool_name` の**値そのもの**（使用可否）のみを参照し、ツール選択ロジックは持たない
- **判定ルール**（現行 `review-flow.md` §処理パス・§遷移判定から移管）:
  1. `review_mode=disabled` → `selected_path=3`, `user_rejection_allowed=false`
  2. `review_mode=required`:
     - `tool_name != none` → `selected_path=1`
     - `tool_name=none` → `selected_path=2`（失敗時ユーザー承認、`skip_reason_required=true`）
  3. `review_mode=recommend`:
     - `tool_name != none` → `selected_path=1`
     - `tool_name=none` → `selected_path=2`
  4. `automation_mode=semi_auto ∧ review_mode=recommend` → `user_rejection_allowed=false`（拒否スキップ）
  5. それ以外 → `user_rejection_allowed=true`

### ドメインサービス: FallbackPolicyResolution

- **責務**: エラー種類 × `review_mode` から `fallback_policy` を導出する
- **対応表**（現行 `review-flow.md` §パス 1 エラー時フォールバックから移管）:

| エラー種類 | `review_mode=recommend` | `review_mode=required` |
|-----------|------------------------|----------------------|
| CLI 不在（恒久） | `fallback_to_self` | `prompt_user_choice` |
| CLI 実行エラー（一時的） | `retry_1_then_prompt` | `retry_1_then_user_choice` |
| CLI 出力解析不能 | `fallback_to_self` | `prompt_user_choice` |

### 依存関係（領域 2）

- `ReviewRoutingRule` → `CallerContextMapping` / `ToolSelection` / `PathSelection` / `FallbackPolicyResolution`（4 つのドメインサービスを合成して `ReviewRoutingDecision` を生成）
- **評価順序**: `CallerContextMapping`（`caller_context` → `skill_name` + `focus`） + `ToolSelection`（`configured_tools` + `available_tools` → `tool_name`）が先行し、`PathSelection` は `ToolSelection` の出力 `tool_name` に依存する。`FallbackPolicyResolution` は `review_mode` のみに依存する
- `CallerContextMapping` / `ToolSelection` / `FallbackPolicyResolution` は互いに独立（並行評価可能）、`PathSelection` のみ `ToolSelection` の完了を待つ
- `ReviewRoutingRule` → `CallerContext` / `ReviewRoutingInput`（列挙・入力値オブジェクトの参照）

**ドキュメント間の参照方向**（`review-routing.md` / `review-flow.md` / 呼び出し層）:

- **`review-routing.md`**（判定の正本、実体ドキュメント）: 他のどのファイルも参照しない純粋テーブル集
- **`review-flow.md`**（手順の正本、実体ドキュメント）: `ReviewRoutingDecision` 契約を消費するため `review-routing.md` を参照する（一方向）
- **各フェーズ `index.md` / ステップファイル**（呼び出し層）: `review-routing.md` と `review-flow.md` の**両方を直接参照可能**:
  - ルーティング判定の詳細が必要な場合は `review-routing.md` を参照
  - 手順本体を実行する場合は `review-flow.md` を参照
  - これは `review-flow.md` が手順の正本であり、呼び出し層が直接手順を実行する構造を維持するための設計
- **循環依存は存在しない**: 参照の向きは「呼び出し層 → {`review-flow.md`, `review-routing.md`}」および「`review-flow.md` → `review-routing.md`」の単方向のみ

---

## 境界と責務分離

### 境界 1: 「スクリプト化可能な機能群」 vs 「人間判断が必要な markdown 記述」

- **基準**: シェルコマンドの並びのみで完結し、ユーザー入力・コンテンツ生成・対話的判断を含まないサブステップはスクリプト化対象
- **例外**:
  - `7.4 履歴記録`: 既存 `/write-history` スキル経由ですでに orchestration 済みであり、本 Unit で再度ラップする必要はない
  - `7.12 PR マージ前レビュー`: `codex review` / reviewing スキル呼び出しが対話的要素を含み、終了コードでは制御できない
- **判定責任**: `SectionClassification` ドメインサービス（上記分類表）に固定

### 境界 2: 「ルーティング判定」 vs 「実行手順」

- **基準**:
  - **ルーティング判定**: `ReviewRoutingInput`（`caller_context` / `review_mode` / `automation_mode` / `configured_tools` / `available_tools` / `tools_runtime_status`）から `ReviewRoutingDecision` を導出する純粋関数的な判定
  - **実行手順**: `ReviewRoutingDecision` を受け取った後の反復ループ、エラーハンドリング実行、セッション管理、指摘対応判断、履歴記録、サマリ生成等の副作用を伴う処理
- **判定責任**:
  - ルーティング判定: `ReviewRoutingRule`（`review-routing.md` に集約）
  - 実行手順: `review-flow.md` に残存（`ReviewRoutingRule` の出力を消費する立場）
- **一方向依存の担保**: `review-routing.md` は `review-flow.md` を参照しない。参照の向きは `各フェーズ index.md / 各ステップファイル / review-flow.md → review-routing.md` の一方向のみ

### 境界 3: Unit 005 スコープ境界

- **スコープ内**:
  - `operations-release.sh` の新規作成
  - `operations-release.md` の簡略化
  - `review-routing.md` の新規作成
  - `review-flow.md` の簡略化
  - 各フェーズインデックス §2.8 / §2.9 の参照更新
  - 4 ステップファイル（`inception/03-intent.md` / `inception/04-stories-units.md` × 2 / `construction/01-setup.md`）の参照更新
- **スコープ外**:
  - 既存スクリプト（`pr-ops.sh` / `validate-git.sh` / `suggest-version.sh` / `ios-build-check.sh` / `run-markdownlint.sh`）の内部実装変更
  - 新規 reviewing スキルの追加
  - `phase-recovery-spec.md` / 各フェーズインデックスの判定チェックポイント表の変更
  - Unit 001-004 で確立した Materialized Binding 構造の変更
  - 新しい `CallerContext` の追加（現行 9 種のまま）

---

## Unit 001-004 との対比

| 観点 | Unit 001-004 | Unit 005 |
|------|-------------|---------|
| 主目的 | フェーズ判定の規範仕様化と Materialized Binding 導入 | 既存ファイルの純粋リファクタリング |
| 規範仕様導入 | あり（`phase-recovery-spec.md`） | なし |
| 新エンティティ | `PhaseResolver` / `PhaseLocalStepResolver` / `RecoveryCheckpoint` 等 | `OperationsReleaseOrchestrator`（概念のみ）/ `ReviewRoutingRule`（概念のみ） |
| 新インターフェース契約 | `PhaseRecoveryJudgment` / `StepResolution` 等 | `ReviewRoutingDecision` のみ |
| 依存方向 | 一方向（規範 → binding → 呼び出し層） | 一方向（routing → flow → 呼び出し層、および release.sh → 既存スクリプト） |
| Unit 003 Stage 1 のような特殊構造 | Construction の Unit loop | なし（両領域とも単純な分類 + 一方向依存） |
| 動作等価性検証 | fixture ベースの復帰判定検証 | `--dry-run` 引数照合 + ルーティング判定の静的照合 |

---

## まとめ

Unit 005 のドメインモデルは、Unit 001-004 のような新規仕様導入ではなく、**既存の肥大化したファイルを責務単位で分離し、依存方向を一方向化する純粋リファクタリング**として定義される。2 つの独立した領域（`OperationsReleaseOrchestrator` / `ReviewRoutingDecision`）があるが、両者に共通するのは「**境界を明確に引き、一方向依存を担保する**」という構造設計原則である。

新規導入される論理インターフェース契約は `ReviewRoutingDecision` 1 つのみであり、これは `review-routing.md`（判定）と `review-flow.md`（手順）の境界を規範化する役割を持つ。`operations-release.sh` のサブコマンド境界は `SectionClassification` ドメインサービスの分類表として固定され、Unit 005 完了後はこの境界を守りながら保守される。
