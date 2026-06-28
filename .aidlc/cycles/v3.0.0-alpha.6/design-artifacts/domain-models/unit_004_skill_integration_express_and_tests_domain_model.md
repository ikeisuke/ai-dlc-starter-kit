# ドメインモデル: Unit 004 SKILL.md 統合・express 整合・テスト・回帰

## 概要

release フロー実装の仕上げ。`SKILL.md` の `release` 公開フリップ・express 整合・release フロー検証テストの追加・回帰・SoT 非再定義の概念モデル。本 Unit は機能を新規実装せず、**統合・検証・整合**を担う。

**重要**: コードは書かず構造と責務のみ定義する。

## ステップ0: 事前コード読込み（設計起草前の既存実装把握）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|-----------|
| `skills/aidlc-v3/SKILL.md` | `release` の「予約」記述・コマンド表・express セクション・パス解決リスト・位置づけ注記/frontmatter（stale 箇所）を把握（フリップ対象） |
| `skills/aidlc-v3/scripts/tests/test-activation.sh` | 自己完結ハーネスの書式（pass/fail / bash -n / shellcheck / jq / stale 注記チェック）を把握（新規テストのお手本） |
| `skills/aidlc-v3/steps/release.md` | Step 1–4 の見出し・依存契約・merge ゲート要素・review ルーティング・post-merge 方針を把握（テスト assertion の対象） |
| `skills/aidlc-v3/templates/release.md` | review 結果サマリの固定マーカー・必須フィールドを把握（構造検証 assertion の対象 / Unit 002→003 契約） |
| `docs/v3/workflow.md §2/§3.3/§6` / `docs/v3/data-model.md §3/§5` | SoT（再定義しないことの確認対象） |

### (b) 設計時に意識すべき挙動

- **stale 注記を残さない**: `test-activation.sh` は SKILL.md の stale 注記（`本 Unit で作成` / `Unit 005 で行う` / 旧 Phase 表記）が残っていないことを検証する。release フリップ時に位置づけ注記を実態同期し、新たな stale を作らない。
- **develop の「tiny のみ」表記は alpha.5 で normal/risky 実装済み**のため実態に合わせて訂正する（SKILL.md 注記同期の一環 / 過剰主張しない）。
- **express は既に release を参照**（SKILL.md express セクションは `define → develop → release`）。release.md 実装で初めて連続実行が release まで到達する。記述の矛盾がないか確認し、不足のみ修正。
- **テストは自己完結・ネットワーク非依存**: 実 gh / merge を行わず、release.md / templates / SKILL.md の **構造・契約文字列を静的検証**する。jq は YAML 非対応のため、マーカー間は parse でなく構造検証（コードフェンス/見出しなし・マーカー重複なし・必須キー存在・enum/boolean 文字列）。
- **SoT 非再定義**: テスト・SKILL.md は data-model §3/§5・workflow §6 を参照同期するのみ。schema/perspective 条件を再定義しない。

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 | 根拠 |
|------|------|------|------|
| `extend`（SKILL.md フリップ + test-activation.sh 同型の新規テスト） | release 行フリップ + パス解決追記 + 注記同期、`test-release-flow.sh` を既存ハーネス書式で追加 | **採用** | Unit 境界（統合・検証）に合致。既存テスト方式を踏襲し回帰リスク最小 |
| `replace`（test-activation.sh に release 検証を統合） | 既存 activation テストに release assertion を足す | 却下 | 単一テストの責務肥大。release 専用テストとして分離する方が保守的（既存 flow 別テストと一貫） |
| `refactor`（YAML parser 依存テスト / ruby・python） | マーカー間を実 YAML parse する | 却下 | 既存ハーネスは jq 前提（ruby/python 非前提）。依存追加は回帰・移植性リスク。構造静的検証で契約を担保 |

## エンティティ（Entity）

### SkillIntegration（SKILL.md 統合 / 集約ルート）

- **ID**: `skills/aidlc-v3/SKILL.md`
- **属性**: releaseRouting: ReleaseCommandRouting / pathResolution / positioningNote / expressSection
- **振る舞い**:
  - flipRelease(): `release` を「予約」→ `steps/release.md` に更新
  - syncNotes(): 位置づけ注記/frontmatter を実態同期（stale 除去）
  - verifyExpressReachesRelease(): express が release まで到達する記述を確認

### ReleaseFlowTest（release フロー検証テスト / エンティティ）

- **ID**: `skills/aidlc-v3/scripts/tests/test-release-flow.sh`
- **属性**: assertions: List<TestAssertion>
- **振る舞い**: run() → pass/fail 集計（exit 0/1/2）

## 値オブジェクト（Value Object）

### ReleaseCommandRouting（release ルーティング）

- **属性**: target（`steps/release.md`）/ reserved: boolean
- **解釈規則**: フリップ後 reserved=false かつ target が実在ファイルを指す

### StaleNoteCheck（stale 注記検査）

- **属性**: patterns: List<string>。`test-activation.sh` の既存 3 パターンに加え、Unit 004 後に SKILL.md に残してはいけないパターンを `test-release-flow.sh` に**明示追加して自動回帰検出**する（設計レビュー #1）: `v3.0.0-alpha.3 / Phase 3`（旧 Phase）/ `tiny フローのみ`（develop stale）/ `release` 行の `予約` / release を「後続 Phase で実装」とする記述。`reflect` / `doctor` の `予約` は実態として残るため対象外。
- **解釈規則**: SKILL.md に上記 stale パターンが残っていない

### TestAssertion（テスト assertion）

- **種別**:
  - 静的検査: `test-release-flow.sh` 自身が `bash -n` / shellcheck（あれば）通過
  - 存在: `steps/release.md` / `templates/release.md` 存在
  - 見出し: release.md が Step 1–4 見出しを持つ
  - マーカー構造（**perspective 単位** / 設計レビュー #2）: start/end が各 1 回・マーカー間にフェンス/見出しなし。`premerge`/`integration`/`deploy` が各 1 回出現し、**各ブロックに `status`/`unresolved_count`/`max_severity`/`merge_blocker`/`skip_reason` がある**。`merge_blocker_any` が reviews リスト外に 1 回。グローバル grep ではなく perspective 単位で検証（premerge だけに全キーがあり他で欠落、を見逃さない）
  - ルーティング: SKILL.md の release が `steps/release.md` を指す（release 行に「予約」なし）
  - 依存契約: release.md が state-write/read・work-item-validate/status・merge ゲート要素（merge_blocker_any / --match-head-commit / gh pr checks --required）を参照
  - review ルーティング（**スモーク** / 設計レビュー #3）: release.md が `docs/v3/workflow.md` への参照 + perspective 名（premerge/integration/deploy）+ 主要ゲート語彙を含む（条件文の完全一致ではなく SoT 参照 + キーワードの存在確認 / 厳密な条件定義は docs に閉じる）
  - post-merge（**スモーク**）: `version_tag`/`changelog`・tag・journal の主要語彙と SoT 参照の存在確認（条件を再記述しない）

## 集約（Aggregate）

### ReleaseFinalization（release 仕上げ集約）

- **集約ルート**: SkillIntegration
- **不変条件**:
  - 機能の新規実装をしない（Unit 001–003 の成果物を変更しない / 統合・検証のみ）
  - SoT（state schema / data-model §5 / workflow §6）を再定義しない（参照同期のみ）
  - SKILL.md に stale 注記を残さない
  - テストは自己完結・ネットワーク非依存（実 gh/merge なし）
  - v2（`skills/aidlc`）を変更しない

## ドメインサービス

### SotReferenceCheck（SoT 非再定義確認）

- **責務**: release.md / templates / SKILL.md が data-model §3/§5・workflow §6 を参照に留め、再定義していないことを確認
- **操作**: verify()

## リポジトリインターフェース

新規永続化リポジトリは設けない。検証は `test-release-flow.sh`（自己完結 / jq 前提）が担う。

## ユビキタス言語

- **公開フリップ（release flip）**: SKILL.md の `release` を「予約」から実装済み（`steps/release.md`）へ更新する利用者向け有効化
- **stale 注記**: 実態と乖離した SKILL.md の注記（`test-activation.sh` が残存を検出）
- **構造静的検証**: マーカー間を YAML parse せず、構造（フェンス/見出しなし・必須キー・enum/boolean）で契約を確認する jq 非依存検証

## 不明点と質問（設計中に記録）

[Question] develop の「tiny のみ」表記を本 Unit で訂正してよいか（スコープ）。
[Answer] SKILL.md 注記同期の一環として訂正する。develop normal/risky は alpha.5 で実装済みであり、release フリップ時に位置づけ注記を実態同期する責務に含まれる（過剰主張せず実態に合わせる）。

[Question] マーカー間の検証を実 YAML parse にするか。
[Answer] しない。既存ハーネスは jq 前提（ruby/python 非前提）であり、依存追加は移植性リスク。構造静的検証（フェンス/見出しなし・マーカー重複なし・必須キー・enum/boolean 文字列）で契約を担保する。

[Question] テストで review ルーティング条件・opt-in をどう検証するか（SoT 第二正本化を避けつつ）。
[Answer] スモーク検証に寄せる（設計レビュー #3）。条件文の完全一致ではなく、release.md が `docs/v3/workflow.md`/`docs/v3/data-model.md` への SoT 参照と perspective 名・主要ゲート語彙（premerge/integration/deploy / version_tag/changelog / tag / journal 等）を含むことを確認。厳密な条件（done≥2 等）の正本は docs に閉じ、テストに再記述しない。

[Question] マーカー構造検証はグローバル grep でよいか。
[Answer] 不可（設計レビュー #2）。premerge だけに全キーがあり integration/deploy で欠落しても pass し得るため、perspective 単位（各 perspective 1 回・各ブロックに 5 キー・merge_blocker_any は reviews 外に 1 回）で検証する。

[Question] SKILL.md の stale 回帰はどう自動検出するか。
[Answer] `test-release-flow.sh` に Unit 004 後に残してはいけない SKILL.md パターン（旧 Phase 表記 / develop tiny / release の予約・後続 Phase）を明示追加して検出する（設計レビュー #1 / reflect・doctor の予約は対象外）。
