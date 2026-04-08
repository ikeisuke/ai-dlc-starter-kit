<!-- phase-index-schema: v1 -->
<!--
Source of Truth 宣言:
  v2.3.0 以降、フェーズの現在位置判定とステップ間分岐ロジックの正本は本インデックスファイルである。
  `steps/common/compaction.md` に残存する現在位置判定テーブルは非正本であり、新規参照は禁止する。
  当該テーブルは Unit 002（汎用復帰判定基盤）で削除予定である。
-->

# Inception Phase インデックス

Inception Phase の入口ファイル。以下4要素を集約する:

1. 全ステップの目次・概要
2. ステップ間分岐ロジック
3. 現在位置判定チェックポイント（骨格のみ、実判定は Unit 002）
4. ステップ読み込み契約（`step_id` → `detail_file` の解決テーブル）

AI エージェントは本ファイルを常時ロードし、詳細手順ファイル（`01-setup.md` 〜 `05-completion.md`）は「ステップ読み込み契約」に従って必要時のみロードする。

---

## 1. 目次・概要

| step_id | タイトル | 目的 |
|---------|---------|------|
| `inception.01-setup` | セットアップ | プリフライト、バージョン・ブランチ決定、サイクルディレクトリ作成、progress.md 初期化 |
| `inception.02-preparation` | インセプション準備 | エクスプレス検出、depth_level 確認、Issue/バックログ確認、既存成果物確認 |
| `inception.03-intent` | Intent 明確化 | Intent 対話作成、brownfield 既存解析、AIレビュー・承認 |
| `inception.04-stories-units` | ストーリー・Unit 定義 | ユーザーストーリー作成、Unit 分解、エクスプレス判定、PRFAQ 作成 |
| `inception.05-completion` | 完了処理 | サイクルラベル、履歴記録、意思決定記録、ドラフト PR、squash、コミット、コンテキストリセット |

各ステップの詳細手順は「4. ステップ読み込み契約」に示された `detail_file` を参照すること。

---

## 2. 分岐ロジック

インセプションフェーズ内で発生する分岐を一元化する。各詳細ステップファイルは本セクションを参照し、分岐判定ロジック自体は重複記載しない。

### 2.1 Part 構成

| Part | 含まれる step_id | 遷移条件 |
|------|-----------------|---------|
| Part 1（セットアップ） | `inception.01-setup` | フェーズ開始時から開始 |
| Part 2（インセプション本体） | `inception.02-preparation` 以降 | サイクルディレクトリ作成完了 / 既存サイクル再開時は progress.md 読み込み完了 |

**再開時**: `.aidlc/cycles/{{CYCLE}}/inception/progress.md` が存在する場合、未完了ステップから再開する。

### 2.2 エクスプレスモード分岐

| 契機 | 条件 | 動作 |
|------|------|------|
| インスタント検出（`inception.02-preparation`） | 初回入力が `start express` と完全一致（case-insensitive） | `express_enabled=true`、`express_source=command`、`depth_level` は変更なし |
| 判定実行（`inception.04-stories-units` ステップ4b） | `express_enabled=true` かつ Unit 数 ≥ 1 かつ全 Unit が `eligible` | エクスプレスモード有効、Inception → Construction 統合フロー適用 |
| フォールバック | Unit 数 0 / 1つでも `ineligible` | 通常フロー継続、履歴に理由記録 |

詳細は `common/rules-automation.md` の「エクスプレスモード仕様」を参照。

### 2.3 depth_level 分岐

| depth_level | 影響範囲 | 動作差分 |
|-------------|---------|---------|
| `minimal` | 受け入れ基準・Intent 記述・PRFAQ | PRFAQ スキップ可、Intent 質問観点最小化、受け入れ基準主要ケースのみ |
| `standard`（デフォルト） | - | 現行動作 |
| `comprehensive` | Intent・ストーリー・Unit 定義 | リスク分析・代替案検討・エッジケース網羅・技術リスク評価を追加 |

詳細は `common/rules-reference.md` の「レベル別成果物要件」を参照。

### 2.4 automation_mode 分岐（ゲート判定）

| automation_mode | ゲート動作 |
|-----------------|----------|
| `manual` | 全承認ポイントでユーザー確認 |
| `semi_auto` | フォールバック条件非該当なら `auto_approved`、該当時は `fallback(reason_code)` |

本 Inception フェーズでのゲート発生箇所:

- Intent 承認（`inception.03-intent` ステップ1 完了時）
- ユーザーストーリー承認（`inception.04-stories-units` ステップ3 完了時）
- Unit 定義承認（`inception.04-stories-units` ステップ4 完了時）

詳細・フォールバック条件テーブル・構造化シグナルは `common/rules-automation.md` の「セミオートゲート仕様」を参照。

### 2.5 cycle_mode 分岐（`inception.01-setup`）

| mode | 動作 |
|------|------|
| `default` | 通常フロー（名前入力なし） |
| `named` | サイクル名入力／既存名付きサイクル選択。バリデーション: `^[a-z0-9][a-z0-9-]{0,63}$`。予約名禁止 |
| `ask` | 通常／名前付きの選択を提示 |

無効値・読み取り失敗時（exit 2）→ `default` にフォールバック。

### 2.6 branch_mode 分岐（`inception.01-setup` ステップ9）

| mode | 動作 |
|------|------|
| `branch` | 自動でブランチ作成 |
| `worktree` | worktree 作成 |
| `ask`（デフォルト） | ユーザーに選択提示 |

無効値 → `ask` にフォールバック。

### 2.7 gh_status 分岐

プリフライトで取得済みの `gh_status` を各ステップが参照する:

| gh_status | 対象機能の動作 |
|-----------|--------------|
| `available` | Issue 確認・バックログ確認・サイクルラベル付与・ドラフト PR 作成をすべて実行 |
| `available` 以外 | 関連機能をスキップし、警告表示して続行 |

### 2.8 brownfield / greenfield 分岐（`inception.03-intent` ステップ2）

- **greenfield**: Reverse Engineering（ステップ2）全体をスキップ
- **brownfield**: ディレクトリ構造・アーキテクチャ・技術スタック・依存関係の4解析を実施し、`existing_analysis.md` に記録

### 2.9 AI レビュー分岐

各承認ポイントで `common/review-flow.md` に従う。`review_mode=disabled` 時は `review-flow.md` のパス3（ユーザーレビュー）へ直行。

対象タイミング（本フェーズ）:

- Intent 承認前
- ユーザーストーリー承認前
- Unit 定義承認前

---

## 3. 判定チェックポイント骨格（Unit 001 段階）

**重要**: Unit 001 時点では `checkpoint_id` のみ埋め、他フィールドは `TBD` プレースホルダとして固定する。Unit 002（汎用復帰判定基盤）が共通判定仕様（`steps/common/phase-recovery-spec.md`）を策定した後、`TBD` セルを実値で埋める。**本テーブルの列構造・行構造は予算都合でも変更不可**（Unit 002 の機械的流し込み前提）。

| checkpoint_id | input_artifacts | priority_order | undecidable_return | user_confirmation_required |
|---------------|-----------------|----------------|--------------------|----------------------------|
| `inception.setup_done` | TBD | TBD | TBD | TBD |
| `inception.preparation_done` | TBD | TBD | TBD | TBD |
| `inception.intent_done` | TBD | TBD | TBD | TBD |
| `inception.units_done` | TBD | TBD | TBD | TBD |
| `inception.completion_done` | TBD | TBD | TBD | TBD |

### 3.1 論理インターフェース契約（Unit 002 接続点）

Unit 002 が実装する「成果物ベース現在ステップ判定」の論理インターフェースを Unit 001 で先行定義する:

```text
operation: determine_current_step
input:
  - phase_index: PhaseIndex               # 本インデックスファイル
  - input_artifacts_state: ArtifactsState # サイクル配下のファイル存在有無 + progress.md 完了マーク等を集約した状態
output:
  - 判定成功時: step_id（例: "inception.04-stories-units"）
  - 判定不能時: "undecidable:<reason_code>"
    - reason_code の4系統:
      - missing_file     : 必須成果物ファイル欠損
      - conflict         : 複数フェーズ成果物の競合
      - format_error     : progress.md 等のパース失敗
      - legacy_structure : v2.2.x 以前の旧構造検出
user_confirmation_connection:
  - 判定不能時はユーザー確認フローへ接続しうる契約点を持つ
  - 実際の確認必須性（真偽値）は Unit 002 が reason_code ごとに決定
  - Unit 001 では接続可能性のみを保証し、固定真偽値は定義しない
```

---

## 4. ステップ読み込み契約

AI エージェントはこのテーブルを参照して詳細ファイルをロードする。**本テーブルの列構造・行構造は予算都合でも変更不可**。

| step_id | detail_file | entry_condition | exit_condition | load_timing |
|---------|-------------|-----------------|----------------|-------------|
| `inception.01-setup` | `steps/inception/01-setup.md` | フェーズ開始時（`step_id` 未指定時の既定開始点） | サイクルディレクトリ作成＋progress.md 初期化完了 | `on_demand` |
| `inception.02-preparation` | `steps/inception/02-preparation.md` | `inception.01-setup` 完了 | エクスプレス検出／depth_level／Issue／バックログ／既存成果物確認完了 | `on_demand` |
| `inception.03-intent` | `steps/inception/03-intent.md` | `inception.02-preparation` 完了 | Intent 承認（`auto_approved` または ユーザー承認） | `on_demand` |
| `inception.04-stories-units` | `steps/inception/04-stories-units.md` | `inception.03-intent` 承認後 | ストーリー・Unit 定義承認 + エクスプレス判定 + PRFAQ 作成（depth_level 分岐） | `on_demand` |
| `inception.05-completion` | `steps/inception/05-completion.md` | `inception.04-stories-units` 承認後 | サイクルラベル／履歴／意思決定記録／PR／squash／コミット／コンテキストリセット完了 | `on_demand` |

### 4.1 既定ルート

- `step_id` が明示指定されている場合: 上記テーブルから解決
- `step_id` 未指定の場合（**新規開始時のみ**）: **`inception.01-setup` を既定開始点**として契約テーブルから解決
- **コンパクション復帰時（再開文脈）**: `inception/progress.md` から未完了ステップ（「進行中」または最初の「未着手」）を特定して `step_id` を決定する。`progress.md` 不在またはパース不能の場合は `inception.01-setup` に戻し、ユーザーに再開点の確認を求める（Unit 002 完了までの暫定ルール、詳細は `steps/common/compaction.md` の復帰フロー参照）
- `06-backtrack.md`（バックトラック用）は初回ロード対象外。バックトラック発動時のみ追加ロードする

### 4.2 SKILL.md 側のルーティング責務

SKILL.md の共通初期化フローは本インデックスファイルのみを常時ロードし、詳細ファイルは上記契約経由で必要時ロードする。**SKILL.md は契約テーブルを参照する薄いルーティング責務のみを持ち、詳細ステップの読み込み条件ロジックを直接持たない**。

---

## 5. 汎用構造仕様（他フェーズへの流用前提）

本インデックスファイルの章構成（1. 目次 / 2. 分岐ロジック / 3. 判定チェックポイント骨格 / 4. ステップ読み込み契約）は、フェーズに依存しない共通構造である。Unit 003（Construction）/ Unit 004（Operations）は本構造をそのまま流用し、フェーズ固有の要素（ステップ名、分岐条件、契約行、チェックポイント行）のみを差し替える。

**共通要素（フェーズ非依存）**:

- 章立て: 目次 / 分岐ロジック / 判定チェックポイント骨格 / ステップ読み込み契約
- `StepLoadingContract` 列スキーマ: `step_id` / `detail_file` / `entry_condition` / `exit_condition` / `load_timing`
- `RecoveryCheckpoint` 列スキーマ: `checkpoint_id` / `input_artifacts` / `priority_order` / `undecidable_return` / `user_confirmation_required`
- Source of Truth 宣言と `<!-- phase-index-schema: v1 -->` スキーマバージョンコメント

**フェーズ固有要素**:

- 各ステップの `step_id` 命名規約: `{phase}.{step-slug}`
- 分岐ロジックセクションの具体的な条件（automation_mode の発生箇所など）
- チェックポイントの具体的な `checkpoint_id`
