# ドメインモデル: Unit 003 develop Step 5（レビュー）+ review routing

## 概要

develop フロー Step 5 の「レビュールーティング」ドメインを定義する。Unit 001 の `MatrixDecision`
（`matrix_review_mode`）を入力に、どの perspective（code / design）をどの focus で既存
`reviewing-construction-*` スキルへ流し、結果を `reviews/<id>-<slug>.md` の perspective 別セクションに
冪等記録するかを決める判定構造と責務を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行う。実装（develop.md Step 5 の
手順記述・test-develop-flow.sh の `decide_review_routing`）は Phase 2 で行う。

## 事前コード読込み（v2.6.5 / #679）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/steps/develop.md` | Step 5 の現状（プレースホルダ）・Step 2.3 review 境界ガード・フロー表・冒頭注記の改修箇所特定 |
| `skills/aidlc/steps/common/review-routing.md` | `caller_context`→skill/focus 写像（§3）、ツール選択（§4）、処理パス（§5）、フォールバック（§6）、呼び出し形式（§7）の委譲先契約 |
| `skills/aidlc/steps/common/review-flow.md` | 5R 完了判定（`is_completed()`）、Defer 自動 Issue 起票、機密マスク、レビュー後コミット/サマリ規約（v3 develop が上書きする範囲の特定） |
| `docs/v3/data-model.md` §8 / §10 | `matrix_review_mode` の正本マトリクス、`reviews/*.md` 成果物の保存先規約（develop=work item review / release=release.md） |
| `docs/v3/workflow.md` §6.1 / §6.2 | SoT 不整合（§6.1 plan perspective 実行条件 vs §6.2/§8 review マトリクス）の確定対象 |
| `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` | `decide_matrix` 純粋関数・`run_develop` ドライバ（rc=26 境界停止）・模擬境界の拡張点 |

### (b) 設計時に意識すべき挙動

- `decide_matrix`（test）と develop.md Step 1 step4 の §8 写像表は**単一の真実**として一致を保つ。
  `matrix_review_mode` の値は `none` / `code`（normal_standard・normal_comprehensive）/
  `code_security`（risky_standard）/ `code_security_design`（risky_comprehensive）。
- `reviewing-construction-code` は **code 品質 + security の複合スキル**（review-routing.md §3「コード生成後」は
  focus `code, security` 固定）。`code_security` を security-only と解釈すると通常 code review を落とす。
- review-flow.md の「レビュー前/後コミット三段階」「review-summary 更新」「`history/*.md` 配置」は v2 系規約で、
  v3 develop の「Step 6 単一 commit」「`reviews/<id>-<slug>.md` 成果物」と衝突する（委譲範囲を限定する必要）。
- `reviews_path` は Unit 001 が `basename` + `<id>-` prefix 検証（`invalid_artifact_path` ガード）で配線済み。
  新規パースを足さない（#733 P1/P2 再発防止）。
- `run_develop` は AI 判断（実装内容・承認ゲート対話・レビュー反復）を模擬しない。決定的副作用（ファイル生成・
  status 遷移・commit）のみ再現する（Unit 002 の前例）。
- Step 2.3 の review 境界ガード（rc=26）は Unit 002 が「Unit 003 完了で外す」と明記済み。解除により design 必須
  セルが Step 3→6 まで完走する。

### (c) 既存実装に基づく代替案検討

| 方針候補 | 既存実装との適合性 | 採否 |
|---------|------------------|------|
| **extend**: develop.md Step 5 を実装し、ルーティング判定は review-routing.md / review-flow.md へ委譲 | 既存 SoT（routing/flow）を再利用し develop.md に判定ロジックを再定義しない。SoT 二重定義回避と一致 | **採用** |
| replace: develop.md に独自のルーティング・反復ロジックを記述 | review-routing.md / review-flow.md と二重定義になり SoT 違反。却下 | 却下 |
| reviews 記録を単純追記（マーカーなし） | resume 時に二重追記・部分重複が起き冪等性を損なう（指摘 #4）。却下 | 却下 |
| reviews 記録をセクション単位 upsert（状態マーカー） | resume 時に complete スキップ / incomplete 置換で冪等。採用 | **採用** |

## エンティティ（Entity）

### ReviewArtifact（レビュー成果物）

- **ID**: `reviews_path`（`.aidlc/cycles/<cycle>/reviews/<id>-<slug>.md`、work item と 1:1）
- **属性**:
  - `work_item_id`: String - 対象 work item の id（`<id>-` prefix で reviews_path と整合）
  - `sections`: List<ReviewPerspectiveSection> - perspective 別セクション集合（`## Code Review` / `## Design Review`）
- **振る舞い**:
  - `upsert_section(perspective, body, status)`: 既存セクションを状態マーカーで識別し、`complete` はスキップ・
    `incomplete` は同一マーカー区間を置換する（冪等記録）。新規 perspective は末尾に追加
  - `is_idempotent_on_resume()`: 再 develop（同一 work item）で complete 済みセクションを二重追記しないことを保証

### ReviewPerspectiveSection（perspective 別セクション）

- **ID**: `(work_item_id, perspective)`
- **属性**:
  - `perspective`: ReviewPerspective（`code` / `design`）
  - `heading`: String - `## Code Review` / `## Design Review`
  - `markers`: SectionMarker - **状態を含む**区間境界。開始マーカーに `status=` 属性を持たせ resume 判定を永続化
    （`<!-- aidlc-review:code:start status=complete -->` … `<!-- aidlc-review:code:end -->`）
  - `completion_status`: `complete` / `in_progress`（開始マーカーの `status=` に対応。欠落/不正は安全側 `in_progress`）
  - `body`: String - レビュー結果本文（機密マスク済み）
- **振る舞い**:
  - `mark_complete()`: 反復完了（`unresolved_count=0` または全 defer 化）時に開始マーカーを `status=complete` へ更新
  - **異常系**: duplicate marker / `status` 欠落 / start-end 不整合は「論理設計マーカー仕様」の異常系規則に従う
    （安全側で置換・再生成）

## 値オブジェクト（Value Object）

### MatrixReviewMode（matrix_review_mode）

- **属性**: `value`: enum（`none` / `code` / `code_security` / `code_security_design`）
- **不変性**: Unit 001 の `decide_matrix`（§8）出力をそのまま保持。develop 側で再判定・改変しない
- **等価性**: `value` 文字列で等価判定。`routing_review_mode`（config の `required`/`recommend`/`disabled`）とは
  **別概念**であり混同しない（用語二重定義回避 / 計画 §1.1）

### ReviewPerspective

- **属性**: `value`: enum（`code` / `design`）。**Unit 003 が develop Step 5 で materialize するのは code / design のみ**
- **不変性**: §8 / workflow.md §6.1 由来。develop で materialized される値は code / design に限定
- **plan の所在（指摘 #4）**: `plan` は既存 review-routing.md に `caller_context`（「計画承認前」）として**存在する**が、
  §8 マトリクスが develop で plan review を出力しないため **本 Unit の実行・テスト対象外**。Unit 003 は plan の
  ルーティング先を新規実装せず既存定義の参照に留める（capability は既存資産 / execution は code/design のみ）。
  `integration`・`deploy`・`premerge` は release 用で develop 非対象

### ReviewRuntimeConfig（処理パス選択入力 / 指摘 #3）

- **属性**:
  - `routing_review_mode`: enum（`required` / `recommend` / `disabled` = `[rules.reviewing].mode`）
  - `automation_mode`: enum（`manual` / `semi_auto`）
  - `configured_tools`: List<String>（`[rules.reviewing].tools`）
  - `available_tools`: List<String>（`command -v` 等の検出結果）
  - `tools_runtime_status`: enum（`ok` / `cli_runtime_error` / `cli_output_parse_error`）
- **不変性**: config.toml + ツール検出 + 実行時から取得。review-routing.md `ReviewRoutingInput` の入力契約に対応
- **役割**: **処理パス選択**（外部CLI/セルフ/ユーザー）を担う。`MatrixDecision`（実行対象決定）とは独立入力であり、
  `matrix_review_mode`（§8 値）を `routing_review_mode`（config 値）に混入させない（依存方向の固定 / 計画 §1.1）

### ReviewFocus

- **属性**: `values`: Set<enum>（`code` / `security` / `architecture`）
- **不変性**: review-routing.md §3 の caller_context 写像に従う。code review = `code, security`（複合）、
  design review = `architecture`
- **等価性**: focus 集合で等価。`code_security` は `code, security`（security 重点）であり security-only ではない

## 集約（Aggregate）

### ReviewRoutingDecision（レビュールーティング決定）

- **集約ルート**: ReviewRoutingDecision
- **含まれる要素**: MatrixReviewMode, List<PerspectiveRoute>（各 route = ReviewPerspective + ReviewFocus +
  対象ファイル + 記録セクション heading）
- **境界**: 1 work item の Step 5 ルーティング決定（どの perspective をどの focus・対象で実行し、どのセクションに
  記録するか）を保護する
- **不変条件**:
  - `matrix_review_mode = none`（`review_required=false`）→ route 空（Step 5 スキップ）
  - `matrix_review_mode = code`（normal）→ code route 1 件（focus: code, security / 対象: 実装差分）
  - `matrix_review_mode = code_security`（risky_standard）→ code route 1 件（focus: code, security / security 重点）
  - `matrix_review_mode = code_security_design`（risky_comprehensive）→ code route（security 重点）+ design route
    （focus: architecture / 対象: `designs_path`）の 2 件
  - route の `routing_review_mode` 引数には config 値（`required` 等）を渡し、`matrix_review_mode` 値を渡さない

## ドメインサービス

### ReviewRoutingResolver

- **責務**: `MatrixDecision`（`review_required` / `matrix_review_mode` / `reviews_path` / `designs_path`）から
  `ReviewRoutingDecision`（PerspectiveRoute 群）を導出する純粋判定。§8 を再解釈せず `matrix_review_mode` を写像
- **操作**:
  - `resolve(matrix_decision) -> ReviewRoutingDecision`: 上記不変条件に従い route 群を確定（`decide_review_routing`
    としてテストハーネスに materialized）

### ReviewDelegationAdapter（委譲アダプタ境界 / 指摘 #2）

- **責務**: review-flow.md / review-routing.md への委譲範囲を「手順ロジックのみ」に限定し、commit タイミングと
  成果物保存を v3 develop 契約で上書きする境界を表現する
- **操作**:
  - 利用する責務: 5R 反復完了判定（`is_completed()`）/ Defer 自動 Issue 起票 / 機密マスク / パス選択（外部CLI/
    セルフ/ユーザー）
  - **上書きする責務**: commit（v3 develop は Step 6 で work item 単位 1 commit に集約）/ 成果物保存（v3 develop は
    `reviews/<id>-<slug>.md` を使用し review-summary / `history/*.md` 配置を流用しない）

### ReviewBoundaryGuardRelease（review 境界ガード解除）

- **責務**: Unit 002 が設置した Step 2.3 の時限停止（rc=26 相当）を撤去し、design 必須セルが Step 3→4→5→6 まで
  完走できるようにする（Unit 001/002 のガードを後続 Unit が外すパターンの踏襲）
- **操作**:
  - `release_guard()`: design 承認後に Step 3 へ進ませる（`review_required=true` での停止を撤去）

## ユビキタス言語

- **matrix_review_mode**: §8 由来の develop review 実行制御値（`none`/`code`/`code_security`/`code_security_design`）。
  「どの perspective/focus を実行するか」を決める
- **routing_review_mode**: config（`[rules.reviewing].mode`）由来の処理パス選択制御値（`required`/`recommend`/
  `disabled`）。「外部CLI/セルフ/ユーザーのどのパスでレビューするか」を決める
- **perspective**: レビュー観点（develop では code / design）。release の premerge/integration/deploy は develop 非対象
- **focus**: perspective 内の重点（code / security / architecture）。code review は `code, security` 複合
- **Defer 戦略**: `OUT_OF_SCOPE` / `TECHNICAL_BLOCKER` 確定指摘の自動 Issue 起票（review-flow.md）
- **review 境界ガード**: Unit 002 が設置した「review 未実装中は Step 2 完了で停止」する時限ガード（本 Unit で解除）

## 不明点と質問（設計中に記録）

[Question] reviews_path のセクション状態マーカー記法は HTML コメント（`<!-- aidlc-review:code:start -->`）でよいか。
[Answer] 既存 v3 成果物（design.md / journal.md）は frontmatter / 見出しベースでマーカーコメントは未使用。論理設計で
最小記法（HTML コメント区間 + 見出し）を採用し、markdownlint と整合する形を確定する（実装で検証）。

[Question] develop ハーネスで AI レビュー実行本体（reviewing-construction-* 呼び出し）をどこまで模擬するか。
[Answer] Unit 002 の前例（Design 承認ゲートは非模擬）に従い、ルーティング決定（`decide_review_routing`）と決定的
副作用（reviews セクション生成 + 完走）のみ模擬。実 CLI 依存の反復・Defer は Unit 004（モック/スタブ）へ委譲。
