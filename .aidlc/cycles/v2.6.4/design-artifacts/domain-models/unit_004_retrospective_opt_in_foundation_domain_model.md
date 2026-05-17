# ドメインモデル: Unit 004 - 振り返り opt-in 基盤導入

## 概要

`aidlc-retrospective` スキルにおける「振り返り集約 Issue 自動起票」の意思決定責務を、既存の `feedback_mode` 5 値 enum とは独立した **opt-in 基盤フラグ** として明示的にモデル化する。本 Unit ではフラグの導入とその評価ルールを定義し、`feedback_mode=disabled` との実行優先関係を明確化する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装は Phase 2 で行います。

## 値オブジェクト（Value Object）

### AutoIssueCreationFlag

- **属性**: `value`: Boolean - 振り返り集約 Issue 起票の自動実行可否
- **不変性**: `config.toml` の `[rules.retrospective].auto_issue_creation` から都度読み取って構築される一過性の値オブジェクトであり、ランタイム中に状態を変更しない
- **等価性**: `value` のみで判定
- **デフォルト**: `true`（既存動作互換）
- **取得元**: 4 階層マージ（project-local / project-shared / user-global / defaults）の `[rules.retrospective].auto_issue_creation` キー
- **取得失敗時の解決**:
  - `read-config.sh` exit 0: `value` をパース
  - exit 1（キー不在）: `true` で fallback（defaults.toml の存在保証下では通常発生しないが、保険として定義）
  - exit 2+（取得失敗）: warn 出力 + `true` で fallback（fail-open）

### FeedbackMode

- **属性**: `value`: Enum `{ "interactive", "local-issue-only", "mirror-only", "local-and-mirror", "disabled" }`
- **既存定義**: `skills/aidlc/scripts/lib/feedback-mode.sh` で正規化される既存の値オブジェクト
- **本 Unit での追加責務**: なし。ただし `AutoIssueCreationFlag` との関係を明示するため値オブジェクトとして再記載する

### CapState

- **属性**: `current_count`: Integer / `limit`: Integer / `over`: Boolean
- **既存定義**: §1.5 Step 2 の cap 判定（`retrospective_api_check_cap`）で生成される値
- **本 Unit での追加責務**: なし。`AutoIssueCreationFlag` との論理 OR で起票スキップを決定する側として参照

### DialogToken

- **属性**: `cycle`: String / `response`: Enum `{ "approved", "denied" }` / `recorded_at`: Timestamp
- **既存定義**: `retrospective_dialog_token_record_response` / `retrospective_dialog_token_verify`
- **本 Unit での追加責務**: なし。opt-out 経路では Step 4 に到達しないため token 検証はスキップされるが、token 機構自体は変更しない

## 集約（Aggregate）

### RetrospectiveIssueCreationPolicy

- **集約ルート**: `IssueCreationDecision`（後述のエンティティ）
- **含まれる要素**: `FeedbackMode`, `AutoIssueCreationFlag`, `CapState`, `DialogToken`
- **境界**: 「振り返り 1 回の実行において、集約 Issue を起票するか / スキップするか」の意思決定全体
- **不変条件**:
  - 不変条件 1: `FeedbackMode == "disabled"` が確定したら、`AutoIssueCreationFlag` は評価されない（§1.0 で即時 exit 0）
  - 不変条件 2: `FeedbackMode != "disabled"` の場合、`AutoIssueCreationFlag.value == false` または `CapState.over == true` のいずれかが成立すれば §1.5 Step 3/4/5 をスキップする
  - 不変条件 3: スキップ判定が成立した場合、`DialogToken` の記録 / 検証経路（Step 4 内部）には到達しない
  - 不変条件 4: `AutoIssueCreationFlag` と `CapState` の評価順序は不問（いずれが先に true になっても結果は同じ）

## エンティティ（Entity）

### IssueCreationDecision

- **ID**: `cycle` + 実行時刻（実態は一過性のため永続化されない）
- **属性**:
  - `cycle`: String - 振り返り対象サイクル名
  - `mode_resolved`: FeedbackMode - §1.0 で確定済の値
  - `auto_issue_flag`: AutoIssueCreationFlag - §1.5 Step 2 で評価
  - `cap_state`: CapState - §1.5 Step 2 で評価
  - `decision`: Enum `{ "skip_disabled", "skip_cap", "skip_opt_out", "proceed" }` - 最終判定結果
- **振る舞い**:
  - `evaluate()`: 上記不変条件に従って `decision` を確定する
    - `mode_resolved == "disabled"` → `decision = "skip_disabled"`（§1.0 で完結 / 本判定には到達しない）
    - `mode_resolved != "disabled"` かつ `cap_state.over == true` → `decision = "skip_cap"`
    - `mode_resolved != "disabled"` かつ `auto_issue_flag.value == false` かつ `cap_state.over == false` → `decision = "skip_opt_out"`
    - `mode_resolved != "disabled"` かつ `cap_state.over == false` かつ `auto_issue_flag.value == true` → `decision = "proceed"`
  - `should_skip_issue_creation()`: `decision in {skip_cap, skip_opt_out}` のとき true（§1.5 Step 3/4/5 をスキップする）
  - `decision_reason()`: ユーザー表示用の文言を返す（opt-out 経路では「auto_issue_creation=false により集約 Issue 起票をスキップしました」）

## ドメインサービス

### RetrospectivePredecessorResolver（既存・本 Unit では変更なし）

- **責務**: 前サイクル振り返り Issue を 5 経路で解決する（`predecessor_resolve_issue`）
- **本 Unit での扱い**: 既存実装の `resolution_path` 出力（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）の不変性を **後方互換性として保護** する。本 Unit はサービスのシグネチャ・出力契約を変更しない

## リポジトリインターフェース

### ConfigRepository

- **対象集約**: 4 階層マージ後の `.aidlc/config.toml` 値群
- **操作**:
  - `read(key) -> (value, exit_code)`: `scripts/read-config.sh <key>` 経由で TOML 値を読み取る。exit_code（0=値あり / 1=キー不在 / 2+=取得失敗）を区別して返す
- **本 Unit での追加責務**: `rules.retrospective.auto_issue_creation` キーの読み取りに本リポジトリを介する。新規 API 追加は不要（既存 `read-config.sh` をそのまま利用）

### DialogTokenStore（既存・本 Unit では変更なし）

- **対象集約**: `DialogToken`
- **本 Unit での扱い**: opt-out 経路ではトークン記録 / 検証経路（Step 4）に到達しないため、本リポジトリへの呼び出しは発生しない。既存契約は維持

## ユビキタス言語

このドメインで使用する共通用語:

- **opt-in 基盤**: v2.6.4 / #710 で導入する集約 Issue 起票の opt-in / opt-out 切り替え機構。デフォルトは既存動作（起票）を維持する「opt-in」フラグだが、`false` 設定時の集約 Issue 起票スキップ経路（opt-out 経路）の実装基盤を意味する
- **集約 Issue 起票**: `Retrospective: {cycle}` という単一 Issue に KPT 全体を集約する起票形態（v2.5.0 以来の現行運用）。v2.7.0+ で「Try/改善単位の個別起票」へ移行予定
- **opt-out 経路**: `auto_issue_creation=false` が設定されたとき、§1.5 Step 3/4/5 をスキップする経路
- **fail-open**: 設定取得失敗時に既存動作（起票継続）にフォールバックする方針。診断可能性は warn ログで担保
- **`resolution_path` の 5 経路**: `predecessor_resolve_issue` が前サイクル振り返り Issue を解決する際に出力する経路識別子。本 Unit の後方互換性保護対象

## 不明点と質問（設計中に記録）

[Question] `auto_issue_creation=false` 経路で、ユーザー向け表示は何を出すか（warn / info / silent）
[Answer] info レベル（標準出力）に「集約 Issue 起票をスキップしました（auto_issue_creation=false / v2.6.4 / #710 opt-in 基盤）」を表示。KPT 自体はローカル記録される旨も併記する（計画ファイル §retrospective.md 改訂方針 §挿入内容 のメッセージ部参照）

[Question] opt-out 経路で対話必須トークン（`retrospective_api_record_response`）を呼ぶべきか
[Answer] 呼ばない。Step 4 の `retrospective_api_create_issue` を実行しないので、その直前にある token 記録もスキップされる。意味論的には「起票しないので対話確認も不要」で一貫する（計画ファイル §既存ガードへの影響 表 §対話必須トークン 行 参照）
