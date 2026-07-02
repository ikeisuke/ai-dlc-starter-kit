# ドメインモデル: Unit 001 doctor `[phase]` / `[trace]` 領域

## 概要

doctor 診断コマンドに「フェーズ導出の整合診断（`[phase]`）」と「design 必須 work item の design ファイル存在診断（`[trace]`）」の 2 つの診断領域を追加する。本ドメインは「診断（read-only diagnosis）」であり、状態を変更しない。診断概念（導出フェーズ・severity・design 要否）と既存 doctor の診断要素（領域・report 契約・exit code 集約）の関係を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。

## ステップ0: 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/scripts/doctor.sh` | 既存 9 領域の wrap パターン・`report()` 契約・`STATE_PRESENT`/`CYCLE_DIR`/`GH_AVAILABLE` グローバル伝播・exit code 集約（`HAS_ERROR`/`HAS_UNDIAGNOSABLE`）・順序実行ブロックの構造把握 |
| `skills/aidlc-v3/scripts/state-read.sh` | `define_completed` / `release.merge_approved` / `release.pr_number` の取得 API（許容フィールド・exit code・明示 null は `"null"` 出力）の確認 |
| `skills/aidlc-v3/scripts/lib/frontmatter.sh` | work item frontmatter から `status` / `size` を取得する `fm_extract_block` + `fm_scalar` の契約（loose/strict・return code・引用符剥がし）の確認 |
| `skills/aidlc-v3/scripts/tests/test-doctor.sh` | 契約テストの構造（`build_fixture` / `make_valid_state` / `make_valid_work_item` / `assert_area` / `assert_rc` / jq 注入）の把握 |
| `docs/v3/data-model.md` §5.1 / §6 / §8 | フェーズ導出規則（first-match）/ 破損時方針 / size×depth_level マトリクスの SoT 確認 |

### (b) 設計時に意識すべき挙動

- `report()` は `printf '%-14s%-6s%s'`（領域名 14 桁左詰）。`[phase]`（7 文字）/ `[trace]`（7 文字）は `[parse-guard]`（13 文字）より短く、固定幅に収まる。
- 前段領域の結果はグローバル変数で後段へ伝播する確立パターンがある（`STATE_PRESENT` / `CYCLE_DIR` / `GH_AVAILABLE`）。新領域もこの慣習に従う。
- 既存 `diagnose_work_items` は ERROR 時に `HAS_ERROR=1`（または `HAS_UNDIAGNOSABLE=1`）を立てるのみで、「work item が invalid だった」事実を後段へ伝える変数は**存在しない**（レビュー#3 で追加が必要）。
- `state-read.sh` は明示 null を `"null"` 文字列として出力し exit 0。フィールド欠落は exit 1。`pr_number` 未作成は null。
- `fm_scalar` は malformed/enum 不正でも loose では値（または空）を返す。enum 値の妥当性検証は frontmatter.sh の責務外（consumer 責務）。
- doctor は read-only。`gh pr view` も read-only。complete 判定の PR merged 確認は core 範囲（§9 DG-5）。
- `gh pr list --state open` は **merged PR を拾えない**ため、merged 確認は `release.pr_number` での一意特定が必須（レビュー#1）。
- severity と exit code: OK/WARN/SKIP → exit 0、ERROR(バリデーション) → exit 1、診断不能 → exit 2。本 Unit の `[phase]`/`[trace]` は **WARN 止まり（exit 0 維持）** が原則で、ERROR/診断不能フラグは立てない。

### (c) 既存実装に基づく代替案検討

| 方針 | 既存実装との適合性 | 採否 |
|------|-------------------|------|
| `extend`: 既存 `diagnose_*` 関数群と同じ wrap パターンで `diagnose_phase` / `diagnose_trace` を新設し、順序実行ブロックへ追加 | 既存 9 領域すべてが同一パターン。グローバル伝播・report 契約・exit 集約をそのまま再利用でき、最小差分 | **採用** |
| `refactor`: フェーズ導出を独立スクリプト（例 `phase-derive.sh`）に切り出し doctor から wrap | data-model §5 の導出規則は他 consumer（status / 引数なしルーティング）も使うため将来的価値はあるが、本 Unit の責務（doctor への 2 領域追加）を超える。SoT 二重定義リスク + スコープ拡大 | 却下（スコープ外） |
| `replace`: work item status/size の取得に新規 grep/sed を書く | `lib/frontmatter.sh:24-30` の新規パース禁止規約に違反 | 却下 |

## エンティティ（診断対象の概念モデル）

> 本 Unit は手続き型シェルスクリプトであり OO エンティティは持たない。ここでは「診断が評価する概念」をエンティティ相当として定義する。

### DiagnosisArea（診断領域）

- **ID**: 領域名（`phase` / `trace`、文字列）
- **属性**:
  - name: string - 領域名（`report` の第1引数）
  - severity: Severity - 診断結果の重大度
  - detail: string - 導出結果・根拠の説明
- **振る舞い**:
  - diagnose(): 入力（state / work items / config / gh）を読み、severity と detail を決定して `report` 出力する。状態は変更しない（read-only）

### CycleState（サイクル状態 / 既存 state.json の読取ビュー）

- **ID**: なし（リポジトリに 1 つの `.aidlc/state.json`）
- **属性**（`[phase]` が参照する範囲）:
  - define_completed: boolean - define 完了フラグ
  - release.merge_approved: boolean - merge 承認記録（merge 済みではない）
  - release.pr_number: integer | null - 対象 PR 番号（未作成は null）
- **振る舞い**: read-only（`state-read.sh` 経由で個別フィールド取得）

### WorkItem（work item / 既存 frontmatter の読取ビュー）

- **ID**: ファイル名の `<id>` 部（`<id>-<slug>.md`）
- **属性**（本 Unit が参照する範囲）:
  - status: enum(pending/in_progress/blocked/done/withdrawn) - `[phase]` の develop/release 判定に使用
  - size: enum(tiny/normal/risky) - `[trace]` の design 要否判定に使用
- **振る舞い**: read-only（`fm_scalar` 経由で取得）

## 値オブジェクト（Value Object）

### Phase（導出フェーズ）

- **属性**: value: enum(`define` / `develop` / `release 可能` / `complete`)
- **不変性**: 導出のたびに state + work item から計算する純粋導出値（`current_phase` として永続化しない / §5.1）
- **等価性**: value の文字列一致

### Severity（重大度）

- **属性**: value: enum(`OK` / `WARN` / `ERROR` / `SKIP`)
- **不変性**: 既存 doctor の severity トークンと同一語彙
- **本 Unit での使用範囲**: `[phase]` / `[trace]` は `OK` / `WARN` / `SKIP` のみを使う（ERROR・診断不能は使わず exit 0 を維持）

### DesignRequirement（design 要否）

- **属性**: required: boolean / invalid_combo: boolean（`risky × minimal`）
- **算出規則**（§8 マトリクスの code 化 / SoT は data-model §8）:

  | size \ depth_level | minimal | standard | comprehensive |
  |--------------------|---------|----------|---------------|
  | tiny | required=false | required=false | required=false |
  | normal | required=false | required=true | required=true |
  | risky | invalid_combo=true | required=true | required=true |

- **不変性**: size × depth_level の組から一意に決まる

## 集約（Aggregate）

### PhaseDiagnosis 集約

- **集約ルート**: `[phase]` 診断（DiagnosisArea）
- **含まれる要素**: CycleState 読取ビュー + WorkItem.status の集合 + PR merged 実態（gh）
- **境界**: フェーズ導出の整合性判定（§5.1 first-match + §6 矛盾検知）
- **不変条件**:
  - first-match 評価順（complete → define → develop → release 可能）を厳守
  - `complete` は `merge_approved=true` **かつ** `pr_number` 非 null **かつ** PR merged 確認成功の三条件すべて成立時のみ（§5.1 含意 / §6）
  - 矛盾・確認不能時は安全側（define / develop 継続可能側）に倒し WARN 併記、状態は変更しない（§6 原則）

### TraceDiagnosis 集約

- **集約ルート**: `[trace]` 診断（DiagnosisArea）
- **含まれる要素**: WorkItem.size の集合 + depth_level(config) + designs ディレクトリの存在実態
- **境界**: design 必須 work item と `designs/<id>-<slug>.md` の存在整合
- **不変条件**:
  - design 要否は §8 マトリクスに一致
  - 欠落 / `risky × minimal` / depth_level enum 外 → WARN（exit 0 維持）
  - 状態は変更しない（read-only）

## ドメインサービス

### PhaseDerivationService（フェーズ導出 / §5.1 の code 化）

- **責務**: state + work item status 集合から first-match でフェーズを導出し、矛盾を検知する
- **操作**:
  - derive(): 評価順 1〜4 を順に評価し最初に成立したフェーズを返す
  - detectContradiction(): `define_completed=false` × `done` work item 存在 → 安全側 define + WARN（§6）

### PrMergedConfirmService（complete 確認 / レビュー#1）

- **責務**: `merge_approved=true` のとき対象 PR の merged 実態を read-only 確認する
- **操作**:
  - confirm(pr_number): `pr_number` 非 null かつ gh 利用可能なとき `gh pr view <pr_number> --json merged,state`（read-only）で merged=true を確認。確認できなければ complete 非導出 + WARN

### DesignRequirementService（design 要否判定 / §8 の code 化）

- **責務**: size × depth_level から design 要否を算出し、`designs/<id>-<slug>.md` 存在を照合する
- **操作**:
  - evaluate(size, depth_level): DesignRequirement を返す
  - checkDesignFile(work_item): design 必須なら対応 design ファイル存在を確認

### WorkItemsValidityGate（領域間整合ゲート / レビュー#3）

- **責務**: `[work-items]` が invalid（ERROR）と判定した場合、後段 `[phase]` / `[trace]` が壊れた入力で導出を続けないようゲートする
- **操作**:
  - markInvalid(): `diagnose_work_items` の ERROR 経路でフラグを立てる
  - isInvalid(): `[phase]` / `[trace]` が前段で参照し、invalid なら SKIP/WARN（導出不能）

## ユビキタス言語

- **領域（area）**: doctor が診断する 1 単位。`[name] severity detail` で 1 行出力する
- **フェーズ導出（phase derivation）**: state + work item から現在フェーズを first-match で算出すること（永続化しない）
- **complete 確認**: merge 承認記録（state）と PR merged 実態（gh）の両方が揃って初めて complete とすること
- **design 要否**: size × depth_level マトリクスで work item が design ファイルを必要とするか
- **領域間ゲート**: 前段領域の結果（グローバル変数）を後段領域が前提条件として参照する仕組み
- **安全側に倒す（fail-safe）**: 矛盾・確認不能時に define/develop 継続可能側へ導出し WARN で報告、状態は変更しない（§6 原則）

## 不明点と質問（設計中に記録）

[Question] レビュー#3 のゲート用グローバル変数名は計画では `WORK_ITEMS_VALID` だが、「未作成（define 前の正常状態）」と「invalid（ERROR で壊れている）」を区別する必要がある。`VALID` 名だと未作成も invalid 扱いになり phase の define フォールバックと衝突しないか。
[Answer]（設計判断）後段ゲートが対象とするのは「work item が存在するが ERROR で壊れている」ケースのみ。未作成・0 件・state 不在等の define 前正常状態はゲート対象外（phase は通常導出で define/develop を出す）。そのため変数は invalidity を表す `WORK_ITEMS_INVALID`（ERROR 経路でのみ 1）として実装し、計画の `WORK_ITEMS_VALID` 要件を意味的に充足する。論理設計に明記する。

[Question] `[trace]` で work item が 0 件 / work-items 未作成のときの severity は？
[Answer]（設計判断）design 要否を判定する対象が存在しないため SKIP（`[work-items]` が WARN 済みで重複報告を避ける）。state 不在・cycle dir 未解決も SKIP。論理設計の前段ゲートに明記する。
