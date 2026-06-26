# ドメインモデル: Unit 002 develop Step 2（設計生成）+ design テンプレート

## 概要

develop フロー（`skills/aidlc-v3/steps/develop.md`）の Step 2 で、Unit 001 が確立した `MatrixDecision`（size×depth_level → §8 セル → 派生要件）を消費し、`designs/<id>-<slug>.md` に design 成果物を生成する概念モデルを定義する。`skills/aidlc-v3/templates/design.md` を新設し、`design_mode` と条件付きセクションフラグ（`risk_analysis` / `test_plan` / `rollback_note`）に従って design 本体の詳細度と含むセクションを決める。Step 2 完了時に Design 承認ゲートを発火し、design 必須セルは全て review 必須（Unit 003 未実装）のため Step 3 に進まず停止する。

**重要**: 本ドメインモデルでは**コードは書かず**、構造と責務の定義のみを行う。本 Unit の「実装」は markdown 実行手順（develop.md Step 2）の改訂・design テンプレート（markdown）新設・既存テスト harness の拡張であり、新規 OOP クラスや新規 bash スクリプトの追加ではない。

## ステップ0: 事前コード読込み（v2.6.5 / #679 準拠）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/steps/develop.md` | 改修対象本体。Step 1 の MatrixDecision 構築（行 110-176）・成果物パス導出（行 135-145）・Step 1 末尾スコープ境界ガード（行 148-154）・Step 2 プレースホルダ（行 178-186）の現行構造を把握 |
| `docs/v3/data-model.md` §8 | design 要否・含むセクションの正本マトリクス確認 |
| `docs/v3/data-model.md` §2 / §10 | designs/ の配置規約（`<id>-<slug>.md`）と成果物一覧（normal=designs/*.md / risky=designs/*.md + rollback note）確認 |
| `docs/v3/workflow.md` §3.2 / §5.1 / §6.3 | Design 承認ゲート（§5.1）、§3.2 の design 記述（Unit 001 が §8 注記済み）、§6.3 非正本ビューの SoT 整合状況を確認 |
| `skills/aidlc-v3/templates/work-item.md` / `intent.md` / `journal.md` | design.md 新設の参考（frontmatter 有無・見出し構造・プレースホルダ `{{ }}` 記法・任意セクションのコメント様式） |
| `.aidlc/cycles/v3.0.0-alpha.5/design-artifacts/.../unit_001_*` | Unit 001 の MatrixDecision 契約（消費する派生要件フィールドの正確な materialized 名）の確認 |
| `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` | `decide_matrix`（行 172-189）/ `run_develop`（行 206-264）の構造、rc 規約（21=design/review 必須停止 等）、副作用検出 snapshot の確認 |

### (b) 設計時に意識すべき挙動

- **MatrixDecision は Unit 001 が単一の真実**: 本 Unit は §8 を再解釈せず、`decide_matrix` の materialized 出力（`matrix_case|design_required|design_mode|risk_analysis|test_plan|rollback_note|review_required|review_mode|reason_record|error`）の該当フィールドのみを消費する。条件付きセクションの要否は `risk_analysis` / `test_plan` / `rollback_note`（materialized 名 / サフィックスなし）で一意に決まる。
- **全 design 必須セルは review 必須**: §8 上 `design_required=true` のセル（`normal_standard` / `normal_comprehensive` / `risky_standard` / `risky_comprehensive`）はすべて `review_required=true`。design without review / review without design のセルは存在しない。よって Unit 002 で design を生成しても、review（Unit 003）未実装のため Step 3 へは進めない。
- **副作用様式の変化**: Unit 001 は design 必須セルを status 遷移前（Step 1 末尾）で「副作用なし停止」していた。Unit 002 では design を生成するため work item を `in_progress` にする必要があり、停止点が Step 2 後へ移る。発生する副作用は「status の `in_progress` 化（pending 開始時のみ `pending→in_progress`）+ design ファイル生成」に限定し、`done` 遷移・実装/検証（Step 3/4）の副作用は発生させない。
- **成果物パス導出は Unit 001 配線済み**: `designs_path = .aidlc/cycles/<cycle>/designs/<artifact_filename>`（`artifact_filename = basename(<path>)` / `<id>-` prefix 検証 / 不一致は `invalid_artifact_path` で副作用なし停止）。Unit 002 は新規パース・新規パス導出を足さず、この `designs_path` をそのまま使う（#733 P1/P2 再発防止）。
- **clean-worktree 前提と commit 集約**: Step 0 で worktree clean を確認済み。Step 6 で `git add -A` する設計のため、design ファイルが work item 単位 commit に整合して含まれること。ただし Unit 002 段階では Step 6 に到達しない（Step 2 後停止）ため、design ファイルの commit は Unit 003 完了後の完走時に行われる（Unit 002 のテスト harness では生成のみ検証し commit は別途）。
- **テンプレート不在は status 遷移前に検出**: design テンプレート不在時は暗黙のデフォルト生成をせず副作用なし停止する。design 生成は work item を in_progress にしてから行うため、テンプレート存在は **status 遷移前（Step 1 preflight）** に検証し、不在なら status を遷移させずに停止する（環境設定不備で work item 状態だけが進む部分状態を避ける / NFR 可用性）。

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 |
|------|------|------|
| `extend`（develop.md Step 2 に生成手順 + 単一 design テンプレート） | Step 2 を MatrixDecision 消費 → design テンプレートを起点に条件付きセクションを充足/省略して `designs_path` に生成。停止ガードを Step 2→3 間へ移設 | **採用**: Unit 001 の判定結果を消費するだけで §8 再解釈なし。既存安全境界・パス配線を活かし局所パースを足さない。v3 の最小成果物方針に合致 |
| `refactor`（design 生成を新規 bash スクリプト化） | `design-generate.sh` 等を新設 | **却下**: design 生成は AI エージェントの文章生成であり機械的 atomic 処理ではない。新スクリプトの安全境界・テスト負荷が過剰。v3 はスクリプト数を増やさない方針 |
| `replace`（rollback note / risk analysis を別ファイル化） | `rollback-note.md` / `risk-analysis.md` を designs/ と別に生成 | **却下**: Unit 定義「rollback note は別ファイルを作らず designs/*.md 内の必須セクション」（v3 の成果物数を増やさない方針）。条件付きセクションとして design 本体内に含める |
| 停止ガードを Step 2 後 / Step 5 前のどちらに置くか | Step 3/4 実装・検証を実行してから Step 5 前で止める案 vs Step 2 直後で止める案 | **Step 2 直後採用（計画 AI レビュー R1 #2 で確定 / 案A）**: design 必須セルは review なしで完走できないため、実装・検証の副作用を起こす利得がない。Step 2→3 間に「Unit 003 未実装中の時限ガード」を置き Step 3 に進ませない |

## エンティティ（概念モデル）

### WorkItem（design 生成対象）

- **ID**: work item id（`<id>` / 例: `001`）
- **属性**: `size` / `path` / `slug`（`<id>-<slug>.md`）。本 Unit は `work-item-next.sh` 出力経由で読み取りのみ（frontmatter 再パースなし）
- **振る舞い**: design 生成のため `status:pending` → `in_progress` 遷移（resume 時は in_progress 維持）。`done` には遷移しない（Step 2 後停止）

## 値オブジェクト（Value Object）

### MatrixDecision（Unit 001 提供 / 本 Unit は消費のみ）

Unit 001 が構築する判定結果。本 Unit が消費するフィールド（materialized 名 = `decide_matrix` 出力列）:

- `matrix_case`: 分岐キー（`normal_standard` / `normal_comprehensive` / `risky_standard` / `risky_comprehensive` が design 対象）
- `design_required`: bool（Step 2 実行可否）
- `design_mode`: `simple` / `full`（design 本体の詳細度）
- `risk_analysis`: bool（`## Risk Analysis` を含めるか）
- `test_plan`: bool（`## Test Plan` を含めるか）
- `rollback_note`: bool（`## Rollback Note` を非空で含めるか）
- `review_required`: bool（本 Unit では Step 2 後の停止判定に使用。design 必須セルは全て true）
- `designs_path`: 生成先（Unit 001 配線済み）

> **materialized 名の遵守**: 条件付きセクションフラグは Unit 001 / `decide_matrix` 契約の materialized 名 `risk_analysis` / `test_plan` / `rollback_note`（サフィックスなし）を使う。`design_required` / `review_required` はサフィックス付きが契約名。本 Unit はエイリアスを導入しない（計画 AI レビュー R1 #1 で確定）。

### DesignComposition（design 構成 / MatrixDecision から導出）

design 本体に含めるセクションの集合。MatrixDecision から機械的に導出され、§8 を再解釈しない:

- **必須セクション**（design_mode に関わらず常時）: `## Goal` / `## Context` / `## Design`（design 本体）
- **design_mode による本体詳細度**: `simple`（簡易 design = 要点のみ）/ `full`（詳細 design）
- **条件付きセクション**（フラグ true のときのみ）:
  - `risk_analysis=true` → `## Risk Analysis`
  - `test_plan=true` → `## Test Plan`
  - `rollback_note=true` → `## Rollback Note`（**非空必須**）
- **不変性**: 同一 matrix_case からは常に同一 DesignComposition が導出される（純粋写像）

### DesignArtifact（生成される成果物）

- **配置**: `designs_path`（`.aidlc/cycles/<cycle>/designs/<id>-<slug>.md`）
- **構成**: DesignComposition に従い design テンプレートを充足したもの
- **不変条件**: `rollback_note=true` のとき `## Rollback Note` は非空。条件付きセクションは対応フラグが false なら出力しない（§8 成果物要件を増やさない）

## 集約（Aggregate）

### DesignGeneration（design 生成集約）

- **集約ルート**: DesignArtifact
- **含まれる要素**: MatrixDecision（消費）/ DesignComposition（導出）/ DesignTemplate（起点）
- **境界**: 「MatrixDecision → DesignComposition → designs_path への DesignArtifact 生成 + Design 承認ゲート発火」。review 実行（Unit 003）・実装/検証（Step 3/4）は境界外
- **不変条件**:
  - `design_required=true` のセルでのみ DesignArtifact を生成する（false セルは Step 2 をスキップし repo 追記なし）
  - **design テンプレート不在 → status 遷移前（Step 1 preflight）に検出し副作用なし停止**（`in_progress` 化しない / DesignArtifact 未生成）。環境設定不備（テンプレート不在）だけで work item 状態を進めない（status だけ進む部分状態を構造的に排除）
  - DesignArtifact 生成後、Design 承認ゲートが `approved`（`semi_auto` の auto 承認を含む）かつ `review_required=true`（design 必須セルは全て該当）かつ Unit 003 未実装なら Step 3 に進まず停止し、status は `done` に遷移させない（`in_progress` 維持）。ゲートが `needs_changes` なら design を修正して再生成・再ゲート
  - 条件付きセクションの有無は MatrixDecision のフラグと厳密に一致する（過剰生成・欠落をしない）

## ドメインサービス

### DesignComposer（DesignComposition 写像サービス）

- **責務**: MatrixDecision（`design_mode` / `risk_analysis` / `test_plan` / `rollback_note`）を DesignComposition へ写像する
- **操作**: `compose(MatrixDecision) -> DesignComposition`（design_mode で本体詳細度、3 フラグで条件付きセクション集合を決定）
- **配置**: develop.md Step 2 内の明示規則 + design テンプレートのセクション構造として表現。新規スクリプトは作らない

### ReviewBoundaryGuard（時限停止ガード / Step 2→Step 3 間）

- **責務**: design 生成後、`review_required=true` かつ Unit 003 未実装なら Step 3 に進ませず停止する
- **操作**: `guard(MatrixDecision) -> stop | proceed`（`review_required=true` ∧ Unit003_unimplemented → stop / それ以外 → Step 3 へ）
- **配置**: develop.md Step 2 末尾（Step 3 の手前）。Unit 003 実装時にこのガードを解除する（Unit 001 のスコープ境界ガードを後続 Unit が解除するパターンと一貫）

## matrix_case → DesignComposition 写像表（正本ビュー / §8 由来）

| matrix_case | design_mode | Risk Analysis | Test Plan | Rollback Note | Step 2 後の挙動 |
|-------------|-------------|---------------|-----------|---------------|----------------|
| `normal_standard` | simple | 省略 | 省略 | 省略 | design 生成 → review 境界で停止（in_progress） |
| `normal_comprehensive` | full | 含む | 省略 | 省略 | design 生成 → review 境界で停止（in_progress） |
| `risky_standard` | full | 省略 | 省略 | 含む（非空） | design 生成 → review 境界で停止（in_progress） |
| `risky_comprehensive` | full | 含む | 含む | 含む（非空） | design 生成 → review 境界で停止（in_progress） |
| `tiny_*` / `normal_minimal` | （design_required=false） | - | - | - | Step 2 スキップ（repo 追記なし）→ Step 3 へ（Unit 001 完走経路 / 不変） |

> 上表は `decide_matrix` 出力（`design_mode` / `risk_analysis` / `test_plan` / `rollback_note`）と 1:1 で一致する。本 Unit は判定をせず、フラグに従って条件付きセクションを充足/省略するだけ（§8 二重正本を作らない）。

## Design 承認ゲート（workflow.md §5.1）

- **発火点**: Step 2 で DesignArtifact 生成完了直後
- **挙動**: `automation_mode` に従う（`manual`: ユーザー承認 / `semi_auto`: フォールバック非該当なら条件付き auto）。v3 ゲートモデル（workflow.md §5.1「Design 承認」）に準拠
- **結果状態と接続**（rc=26 との接続を一意化）:

  | ゲート結果 | 発生条件 | 後続 |
  |-----------|---------|------|
  | `approved` | `manual` で承認 / `semi_auto` でフォールバック非該当の auto 承認 | ReviewBoundaryGuard → rc=26 停止（status: in_progress） |
  | `needs_changes` | `manual` で修正要求 / `semi_auto` でフォールバック該当 | design を修正して再生成・再ゲート |
  | `pending` | `manual` で承認待ち（対話中） | ユーザー応答を待つ（停止しない） |

  - **rc=26 の成立条件**: 「DesignArtifact 生成済み **かつ ゲート approved** かつ review 境界停止」。`needs_changes` / `pending` では rc=26 に到達しない
- **本 Unit / テスト harness の扱い**: Design ゲートは AI エージェントとの対話イベントであり、テスト harness（`run_develop`）では再現しない（AI 判断はテスト対象外 / Unit 001 と同方針）。harness 上の rc=26 は「**承認ゲートを模擬しない DesignArtifact 生成済み + review 境界停止**」を表す制御コードとし、ゲート approved は実フローの AI 対話レイヤで成立する前提とする。develop.md の手順記述としてゲート結果分岐を明示する

## ユビキタス言語

- **MatrixDecision**: Unit 001 が §8 セルから導出する判定結果（本 Unit は消費のみ）
- **DesignComposition**: MatrixDecision から導出する design セクション構成（必須 + 条件付き）
- **DesignArtifact**: `designs/<id>-<slug>.md` に生成される design 成果物
- **条件付きセクション**: `## Risk Analysis` / `## Test Plan` / `## Rollback Note`（対応フラグ true のときのみ出力）
- **ReviewBoundaryGuard**: design 生成後 review（Unit 003）未実装で Step 3 に進ませない時限停止ガード
- **Design 承認ゲート**: Step 2 完了時の承認ポイント（automation_mode 準拠）

## 不明点と質問（設計中に記録）

[Question] なし（計画 AI レビュー 3R で増分境界・フィールド名・副作用様式は確定済み）
[Answer] -
