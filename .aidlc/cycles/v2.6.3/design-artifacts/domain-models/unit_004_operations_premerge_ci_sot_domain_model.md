# ドメインモデル: Unit 004 / Operations Phase マージ前 CI 通過確認フロー SoT 化

## 概要

Operations Phase の PR マージ前段階における「CI 通過確認 + 失敗時修復経路」を概念モデルとして表現する。本 Unit は SoT 化を目的としたドキュメント中心の Unit であり、永続化や状態管理の対象は存在しない。エンティティ・値オブジェクトは「会話の語彙固定」のために定義する。

**重要**: 本ドメインモデルでは**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2（`steps/operations/operations-release.md` への記述追加）で行う。

## エンティティ（Entity）

### PullRequestCIStatus

- **ID**: PR 番号（GitHub PR の `number`、整数）
- **属性**:
  - `pr_number`: integer — GitHub PR 番号
  - `head_sha`: string — PR の HEAD コミット SHA（40 桁）
  - `head_ref`: string — PR のソースブランチ名（命名規約に依存しない）
  - `check_state`: enum(`pass` / `fail` / `pending` / `none` / `unknown`) — 全 CI ジョブの集約状態（**`source=ci_job` のみを対象とする集約状態**であり、`structural_check` 起因の失敗とは独立）
  - `failed_jobs`: list of FailedJob — **CI 起因（`source=ci_job`）と構造チェック起因（`source=structural_check`）の失敗集合の和**（Round 2 指摘 #1 反映: 統合後のモデルに整合）。`source=ci_job` サブセットと `check_state` の対応は集約「PreMergeCIVerification」の不変条件で定義（Round 3 指摘 #1 反映: 不変条件側に一本化、属性側では数量制約を再掲しない）。`source=structural_check` サブセットは `check_state` と独立に存在しうる
- **振る舞い**:
  - `is_all_pass()`: `check_state=pass` **かつ** `failed_jobs` の `source=structural_check` サブセットも空のとき true（マージへ進む条件）
  - `is_blocking()`: `check_state ∈ {fail, unknown}` または `failed_jobs` 内に `source=structural_check` 要素が存在するとき true（修復経路へルーティング）

### FailedJob

- **ID**: `source` + `run_id`（または擬似 ID）+ ジョブ名の複合キー
- **属性**:
  - `source`: enum(`ci_job` / `structural_check`) — 失敗の発生源（Round 1 指摘 #1 反映: 構造チェック失敗を擬似ジョブとして同一モデルに統合）
  - `run_id`: integer? — Actions の workflow run ID（`source=structural_check` のとき null、`source=ci_job` のとき必須）
  - `job_name`: string — ジョブ識別子（`source=structural_check` のときは `check-cycle-phase-completion` のような固定識別子）
  - `log_excerpt`: string — 失敗理由の根拠ログ抜粋（環境要因判定の入力）
  - `classification_reason`: enum(`reproducible_local` / `flaky_or_env` / `cross_unit_structural`) — 失敗分類基準テーブルで正規化されたキー
- **不変条件**:
  - `source=structural_check` の `FailedJob` は `classification_reason=cross_unit_structural` 固定（ドメイン約束）
  - `source=ci_job` の `FailedJob` は `classification_reason` を分類サービスで動的に確定する
- **振る舞い**:
  - `classify()`: 失敗分類基準テーブル（論理設計参照）に従い `classification_reason` を確定（`source=structural_check` のときは固定値を返すのみ）
  - `resolved_branch()`: `classification_reason` から修復分岐 ID（`A` / `B` / `C`）を返す

## 値オブジェクト（Value Object）

### ClassificationReason

- **属性**: enum 値（`reproducible_local` / `flaky_or_env` / `cross_unit_structural`）
- **不変性**: 一度確定したら同一 `FailedJob` 上で再分類はリトライ後の再評価時のみ許容（規約外の再分類禁止）
- **等価性**: enum 値で比較

### RepairBranchId

- **属性**: enum 値（`A`=修復可能 / `B`=修復不能 / `C`=構造的不整合）
- **不変性**: `ClassificationReason` との写像で一意に決定（A↔reproducible_local / B↔flaky_or_env / C↔cross_unit_structural）
- **等価性**: enum 値で比較

### StructuralCheckResult

- **属性**:
  - `script_exists`: bool — `bin/check-cycle-phase-completion.sh` 存在判定
  - `exit_code`: int? — 存在時のスクリプト終了コード
- **不変性**: `script_exists=false` のときは `exit_code=null`（opt-in シグナル方式）
- **等価性**: 両属性の組で判定
- **`FailedJob` への変換規則**（Round 1 指摘 #1 反映）: `script_exists=true ∧ exit_code ≠ 0` のとき、`source=structural_check` の `FailedJob` を 1 件生成して `failed_jobs` に追加する。`script_exists=false` または `exit_code=0` のときは `failed_jobs` に何も追加しない

## 集約（Aggregate）

### PreMergeCIVerification

- **集約ルート**: PullRequestCIStatus
- **含まれる要素**: PullRequestCIStatus、FailedJob のリスト（`source=ci_job` と `source=structural_check` を統合）、StructuralCheckResult（変換前の生情報として保持）
- **境界**: 1 つの PR に対するマージ前 CI 通過確認 1 ラウンドの状態空間
- **不変条件**（Round 1 指摘 #1 + Round 2 指摘 #2 反映済み: 片方向制約に弱めて `pending` / `unknown` を許容）:
  - `check_state=fail` ⇒ `failed_jobs` 内に `source=ci_job` 要素が 1 件以上存在する（**片方向制約**、双方向同値は採用しない）
  - `check_state=pass` ⇒ `failed_jobs` 内に `source=ci_job` 要素は 0 件（pass は CI 集約状態として失敗ゼロを意味する）
  - `check_state ∈ {pending, none, unknown}` の場合の `source=ci_job` 集合は **未定義**（pending は判定中、none は CI 未設定、unknown は取得失敗時の不明状態。失敗ジョブの有無は本不変条件の対象外）
  - 任意の `FailedJob` の `classification_reason` は確定後イミュータブル（リトライ時は新規 `FailedJob` インスタンスとして扱う）
  - `StructuralCheckResult.script_exists=true ∧ exit_code ≠ 0` のとき、`failed_jobs` 内に `source=structural_check ∧ classification_reason=cross_unit_structural` の `FailedJob` がちょうど 1 件存在する（変換規則による帰結）
  - 構造チェック失敗は CI ジョブ失敗と独立事象であり、`failed_jobs` 内の `source=ci_job` が空（`check_state=pass` 含む）でも `source=structural_check` の要素が存在しうる

## ドメインサービス

### CIStatusFetchService

- **責務**: PR コンテキストから CI 状態を取得し `PullRequestCIStatus` を構成する
- **操作**:
  - `fetch_by_pr(pr_number)`: PR 番号起点で取得（第一推奨）
  - `fetch_by_commit(head_sha)`: HEAD SHA 起点で取得（補助）
  - `fetch_by_branch(branch)`: ブランチ命名規約準拠時のフォールバック
- **委譲先**: `gh pr checks` / `gh pr view --json statusCheckRollup` / `gh run list --commit` / `gh run list --branch`（実装は `operations-release.md` 内のコマンド列挙）

### FailureClassifier

- **責務**: `FailedJob.log_excerpt` を入力に「失敗分類基準テーブル」と照合し `ClassificationReason` を確定する
- **操作**:
  - `classify(failed_job)` → `ClassificationReason`
  - `retry_eligible(failed_job)`: `flaky_or_env` 仮判定時に同 SHA リトライを許可するかを判定（上限 1 回）
- **協調者**: AI とユーザー（協調判定）。判定根拠は履歴記録（`history/operations.md`）に保存

### RepairRouter

- **責務**: `ClassificationReason` 集合から最重分岐を選択しルーティング決定（**C > B > A**、Round 1 指摘 #2 反映: 構造的不整合を環境要因より先に収束させる）
- **操作**:
  - `route(reasons: list<ClassificationReason>)` → `RepairBranchId`
- **規則**:
  - 優先順位 **C > B > A**（C=cross_unit_structural > B=flaky_or_env > A=reproducible_local）
  - 複数失敗ジョブから集合 `reasons` を構成し、上記優先順で最も高位の分岐を選択
  - **C 検出時のガード**（Round 1 指摘 #2 反映）: `cross_unit_structural` が `reasons` に含まれる場合、`flaky_or_env` が併存していても **B の `AskUserQuestion` には進まない**。C を先に収束させ、再走後の `reasons` 集合で再判定する
  - 分岐 `B` 確定時のみ `AskUserQuestion` 呼び出し（破壊的決定）
  - 設計判断: 「構造的不整合」を未解決のまま「環境要因としてマージブロック解除」する経路を構造的に閉じることで、サイクル横断の不整合を持ち越すリスクを排除する

### StructuralIntegrityChecker（opt-in）

- **責務**: starter kit リポジトリで `bin/check-cycle-phase-completion.sh` 存在時のみ実行され、サイクル横断の構造整合性を検証する
- **操作**:
  - `check()` → `StructuralCheckResult`
- **opt-in 規約**: 存在判定 `[ -x bin/check-cycle-phase-completion.sh ]` のみで分岐。consumer プロジェクトでは自然にスキップ（CLAUDE.md「ドッグフーディング特殊処理を本体に埋めない」原則）

## リポジトリインターフェース

本 Unit はドキュメント中心であり、永続化対象の集約は存在しない。ただし以下の「読み取り専用情報源」をリポジトリ相当として扱う:

### PullRequestCIStatusSource（読み取り専用）

- **対象集約**: PullRequestCIStatus
- **操作**:
  - `fetch(pr_number | head_sha | branch)` — 上述 `CIStatusFetchService` が委譲する gh CLI 経由の取得
- **永続化**: なし（リアルタイム取得のみ）

## ファクトリ（必要な場合のみ）

該当なし（gh CLI の出力から `PullRequestCIStatus` を構成するのは `CIStatusFetchService` の責務）。

## ドメインモデル図（概念図）

```text
PreMergeCIVerification (Aggregate Root)
├── PullRequestCIStatus
│   ├── pr_number / head_sha / head_ref
│   └── check_state
├── failed_jobs: [FailedJob...] （ci_job 起因 + structural_check 擬似ジョブを統合）
│   ├── FailedJob#1 (source=ci_job, classification_reason=reproducible_local) ───┐
│   ├── FailedJob#2 (source=ci_job, classification_reason=flaky_or_env)         │
│   └── FailedJob#3 (source=structural_check, classification_reason=             │
│                    cross_unit_structural)  ← StructuralCheckResult から変換    │
│                                                                                ▼
└── StructuralCheckResult                                              RepairRouter.route()
    (opt-in: script_exists ? exit_code : null)                                   │
                                                                                 ▼
                                                          RepairBranchId（優先 C > B > A）
                                                                                 │
                                                                                 ▼
                                ┌──────────┬──────────────────┬──────────────────┘
                                ▼          ▼                  ▼
                         C:構造的不整合  B:修復不能          A:修復可能
                         (サイクル内修正  (AskUserQuestion   (修正→再走)
                          →§7.12.6 再走)   ※C 併存時は到達不可)
```

## 用語・責務境界

- **マージ前 CI 通過確認**（本 Unit のスコープ）: 上記ドメインサービス群が表現する「マージ実行前」の事前確認 1 ラウンド
- **マージ実行時 CI 最終確認**（既存 §7.13）: `scripts/operations-release.sh merge-pr` 内の `error:checks-status-unknown` ハンドリング。本ドメインモデルの対象外（多層防御の最終防衛線として併存）
- **PR 全体品質レビュー**（既存 §7.12）: `reviewing-operations-premerge` スキルが担う差分内容・セキュリティ確認。本ドメインモデルの対象外（観点分担マトリクスで明示）
