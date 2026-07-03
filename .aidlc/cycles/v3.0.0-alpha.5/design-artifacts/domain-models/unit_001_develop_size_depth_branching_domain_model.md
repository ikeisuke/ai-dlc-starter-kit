# ドメインモデル: Unit 001 develop size×depth_level 分岐基盤

## 概要

develop フロー（`skills/aidlc-v3/steps/develop.md`）の Step 1 で、work item の `size`（per-work-item）と cycle の `depth_level`（per-cycle）を解決し、`docs/v3/data-model.md` §8 マトリクスの 1 セルへ写像して「後続 Step の実行可否・成果物要否」を決定する判定基盤の概念モデルを定義する。本 Unit は判定の写像規則を 1 箇所に集約し、後続 Unit 002（design 生成）/ 003（review 実行）が §8 を再解釈せず参照できる単一の判定結果（`MatrixDecision`）を提供する。

**重要**: 本ドメインモデルでは**コードは書かず**、構造と責務の定義のみを行う。実装は Phase 2 で行う。なお本 Unit の「実装」は markdown 実行手順（develop.md）の改訂と既存 bash 安全境界スクリプトの利用配線であり、新規 OOP クラスの追加ではない。

## ステップ0: 事前コード読込み（v2.6.5 / #679 準拠）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-v3/steps/develop.md` | 改修対象本体。Step 0〜6 の現行構造、特に Step 1（行 71-81 の size!=tiny 停止ブロック）と Step 2/4/6 のスキップ・実行配線を把握 |
| `docs/v3/data-model.md` §8 | 判定の正本マトリクス（size×depth_level → 成果物・review 要否）の確認 |
| `docs/v3/data-model.md` §2 / §10 | designs/ reviews/ の配置規約（`<id>-<slug>.md`）と成果物要否ビューの確認 |
| `docs/v3/workflow.md` §3.2 / §6.2 / §6.3 | develop 内 review の正本（§6.2/§8）と §3.2 文言・§6.3 重複表の SoT 整合対象を確認 |
| `skills/aidlc-v3/scripts/work-item-next.sh` | 出力 `next:<id>:<size>:<path>` 契約、size enum 非検証（validate 済み前提）の確認 |
| `skills/aidlc-v3/scripts/work-item-status.sh` | status 読取/atomic 遷移の安全境界契約の確認 |
| `skills/aidlc/scripts/read-config.sh` | depth_level 読取（`rules.depth_level.level`）の exit code 規約（0/1/2）と stdout 契約の確認 |
| `skills/aidlc/steps/common/rules-reference.md` | depth_level 無効値は `standard` フォールバックという既存規定の確認 |

### (b) 設計時に意識すべき挙動

- **副作用なし停止の様式**: 現行 develop.md の size!=tiny 停止ブロック（行 73-79）は frontmatter / journal / commit を一切変更せず案内して終了する。normal/risky 解禁後も「エラー停止」系（risky+minimal / size enum 外）は同じ「mutation なし」様式を厳守する。
- **size の enum 非検証**: `work-item-next.sh` は size の enum 検証をせず出力する（validate 済み前提）。Step 1 判定層へ enum 外 size が到達し得るため、出力トークンの単純 case 検証で防御する（局所 frontmatter パースは足さない）。
- **status 遷移の二重防止**: pending→in_progress は resume 時に二重遷移しない（in_progress はそのまま継続）。normal/risky でも同じ status 取り扱いを踏襲する。
- **clean-worktree 前提**: Step 0 で worktree clean を確認済み。develop は Step 6 で `git add -A` するため、設計成果物・判定中間生成物が予期せぬ commit に混入しないこと（normal/risky で designs/ reviews/ を生成する Unit 002/003 が commit 集約と整合すること）。
- **depth_level はサイクル不変**: depth_level は config.toml 側でサイクル単位固定。develop 実行ごとに読み直すが、サイクル途中で変わらない前提。
- **tiny 非回帰**: tiny+{minimal,standard} は Phase 3 挙動（実装のみ / design・review スキップ）から変化させない。tiny+comprehensive のみ「短い理由記録」を追加する。

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 |
|------|------|------|
| `refactor`（判定を新規 bash スクリプトに外出し） | size×depth_level 判定を `decision-resolve.sh` 等の新スクリプトに実装 | **却下**: v3 は成果物・スクリプト数を増やさない方針。判定は markdown 手順 + 既存スクリプト出力の組合せで表現でき、新スクリプトの安全境界・テスト負荷が過剰 |
| `extend`（develop.md 手順内に判定規則を記述し、既存スクリプト出力を組合せる） | 停止ブロックを §8 写像の分岐手順に置換。size は work-item-next 出力、depth_level は read-config 出力、判定は §8 セル参照 | **採用**: 既存安全境界（next/status/read-config）を活かし局所パースを足さない。v3 の最小成果物方針に合致。判定結果は develop.md 内の明示テーブル（§8 セル→派生要件）で単一の真実を表現 |
| `replace`（workflow.md §6.3 を正本化し data-model.md §8 を削除） | SoT を workflow 側へ移す | **却下**: Inception の DR で §8（data-model.md）を正本と確定済み。§6.3 は非正本ビュー注記に留める |

## エンティティ（概念モデル）

### WorkItem（size の供給元）

- **ID**: work item id（`<id>` / 例: `001`）
- **属性**:
  - `size`: `tiny` / `normal` / `risky` - 作業規模（frontmatter 由来 / per-work-item）
  - `slug`: string - ファイル名 suffix（`<id>-<slug>.md`）
  - `path`: string - work item ファイルパス
- **振る舞い**:
  - 本 Unit は WorkItem を**読み取りのみ**（`work-item-next.sh` 出力経由）。frontmatter の再パースは行わない

### CycleConfig（depth_level の供給元）

- **ID**: current_cycle（`state.json` 由来）
- **属性**:
  - `depth_level`: `minimal` / `standard` / `comprehensive` - 成果物詳細度（config.toml `rules.depth_level.level` / per-cycle / 未設定既定 `standard`）
- **振る舞い**:
  - `resolveDepthLevel()`: read-config.sh 経由で読取り、enum 外（未設定・読取失敗・不正値）は警告付きで `standard` に正規化

## 値オブジェクト（Value Object）

### MatrixDecision（判定結果 / 後続 Step が参照する単一の真実）

§8 マトリクスの 1 セルから機械的に導出される不変の判定結果。Unit 002/003 はこのオブジェクトのみを消費し §8 を再解釈しない。

- **正規化入力**:
  - `normalized_size`: `tiny` / `normal` / `risky`（enum case 検証済み。enum 外は本オブジェクトを生成せずエラー停止）
  - `normalized_depth_level`: `minimal` / `standard` / `comprehensive`（正規化済み）
  - `matrix_case`: §8 セル識別子（例: `normal_standard` / `risky_comprehensive`）。後続 Step の分岐キー
- **派生要件**（§8 セルから決定）:
  - `design_required`: bool（Step 2 実行可否）
  - `design_mode`: `none` / `simple` / `full`（design 詳細度。Unit 002 が消費）
  - `risk_analysis_required`: bool（`## Risk Analysis` 要否）
  - `test_plan_required`: bool（`## Test Plan` 要否 / risky+comprehensive）
  - `rollback_note_required`: bool（`## Rollback Note` 非空要否 / risky 系）
  - `review_required`: bool（Step 5 実行可否）
  - `review_mode`: `none` / `code` / `code_security` / `code_security_design`（§6.2/§8 正本。Unit 003 の routing 入力）
  - `reason_record_required`: bool（tiny+comprehensive の短い理由記録）
- **出力先・エラー**:
  - `designs_path`: `.aidlc/cycles/<cycle>/designs/<artifact_filename>`（Unit 002 が生成）。`artifact_filename = basename(<path>)`（work-item-next 出力の `<path>` 由来 / `<id>-` prefix 検証済み。論理設計「designs_path / reviews_path 導出規則」参照）
  - `reviews_path`: `.aidlc/cycles/<cycle>/reviews/<artifact_filename>`（Unit 003 が生成）
  - `is_error`: bool / `error_reason`: `risky_minimal` / `invalid_size` / `invalid_artifact_path`（エラー停止シグナル / mutation なし）
- **不変性**: 同一 (size, depth_level) からは常に同一 MatrixDecision が導出される（純粋写像 / 二重の正本を作らない）
- **等価性**: `matrix_case` で一意に識別される

#### 表現（materialized view）と論理フィールドの対応

実装（develop.md の §8 写像表）/ テスト（`test-develop-flow.sh` の `decide_matrix` 出力）では、本 MatrixDecision を以下の materialized view で表現する。論理フィールドと materialized 表現は 1:1 対応し、冗長な重複フィールドを持たない:

| 論理フィールド（本ドメインモデル） | materialized 表現（develop.md 表 / decide_matrix 出力） |
|---|---|
| `normalized_size` + `normalized_depth_level` | `matrix_case`（= `<normalized_size>_<normalized_depth_level>`。例: `normal_standard`） |
| `error_reason`（matrix 由来: `risky_minimal` / `invalid_size`） | `decide_matrix` の `error` 列（`none` / `risky_minimal` / `invalid_size`。`unknown_depth` は防御値） |
| `error_reason`（path guard 由来: `invalid_artifact_path`） | `decide_matrix` の対象外。Step 1 の成果物パス導出ガードが付与する materialized error（実装/テストでは path 検証で判定し別段の停止コードとする） |
| `is_error` | 導出値（`is_error = (error_reason != none)`。materialized では別フィールドを持たず error 列または path guard で判定） |
| `design_required` / `design_mode` / `risk_analysis_required` / `test_plan_required` / `rollback_note_required` / `review_required` / `review_mode` / `reason_record_required` | 同名の派生要件列（下記写像表 / `decide_matrix` 出力の各フィールド） |

**error_reason の 2 系統**: `error_reason` は (a) §8 size×depth 写像由来（`risky_minimal` / `invalid_size`）と (b) path guard 由来（`invalid_artifact_path`）に分類される。`decide_matrix` は**純粋な size×depth 写像のみ**を表現するため (a) のみを `error` 列で扱い、(b) `invalid_artifact_path` は写像とは独立に Step 1 の `<path>` 導出ガードで付与される（matrix セルではない）。`decide_matrix` の出力契約は `matrix_case|design_required|design_mode|risk_analysis|test_plan|rollback_note|review_required|review_mode|reason_record|error` であり、matrix 由来の論理フィールドを過不足なく表現する。`designs_path` / `reviews_path` および `invalid_artifact_path` は materialized 写像表の対象外（実行時に `<path>` から導出する Step 1 手順側の責務）。

## 集約（Aggregate）

### SizeDepthDecision（判定集約）

- **集約ルート**: MatrixDecision
- **含まれる要素**: WorkItem（size）/ CycleConfig（depth_level）の解決結果
- **境界**: 「size×depth_level → §8 セル → 派生要件・出力先・エラー」の写像。この境界の外（design 本体生成 / review 実行）は Unit 002/003 の責務
- **不変条件**:
  - `normalized_size=risky ∧ normalized_depth_level=minimal` → 必ず `is_error=true, error_reason=risky_minimal`（MatrixDecision の正常セルを生成しない）
  - size enum 外 → 必ず `is_error=true, error_reason=invalid_size`
  - 成果物ファイル名が `<id>-` prefix 不一致 → 必ず `is_error=true, error_reason=invalid_artifact_path`
  - エラー時は mutation を一切行わない（frontmatter / journal / commit 不変）。エラー判定は status 遷移より前に行う
  - tiny+{minimal,standard} → `design_required=false ∧ review_required=false ∧ reason_record_required=false`（Phase 3 と不変）

## ドメインサービス

### MatrixResolver（§8 写像サービス）

- **責務**: 正規化済み (size, depth_level) を §8 マトリクス 1 セルへ写像し MatrixDecision を構築する単一の写像実装
- **操作**:
  - `resolve(size, depth_level) -> MatrixDecision`: §8 セル参照 → 派生要件決定。risky+minimal / invalid_size はエラー MatrixDecision を返す
- **配置**: develop.md Step 1 内の明示テーブル（§8 セル → 派生要件）として表現。新規スクリプトは作らない（§(c) 採用方針）

## §8 マトリクス → MatrixDecision 写像表（正本ビュー）

| matrix_case | design_required / design_mode | risk_analysis / test_plan / rollback_note | review_required / review_mode | reason_record | エラー |
|-------------|------|------|------|------|------|
| `tiny_minimal` | false / none | - / - / - | false / none | false | - |
| `tiny_standard` | false / none | - / - / - | false / none | false | - |
| `tiny_comprehensive` | false / none | - / - / - | false / none | **true** | - |
| `normal_minimal` | false / none | - / - / - | false / none | false | - |
| `normal_standard` | true / simple | false / false / false | true / code | false | - |
| `normal_comprehensive` | true / full | **true** / false / false | true / code | false | - |
| `risky_minimal` | - | - | - | - | **risky_minimal** |
| `risky_standard` | true / full | false / false / **true** | true / code_security | false | - |
| `risky_comprehensive` | true / full | **true** / **true** / **true** | true / **code_security_design** | false | - |
| （size enum 外） | - | - | - | - | **invalid_size** |

> 注: `normal_minimal` は §8「実装 + テスト」= design/review なし。`risky_standard` の review_mode=code_security は §6.2（risky は security focus 含む code review）に準拠。`risky_comprehensive` は §8「複数 review」= code(security) + design。

## ユビキタス言語

- **size**: work item 単位の作業規模（tiny/normal/risky）。frontmatter 由来
- **depth_level**: サイクル単位の成果物詳細度（minimal/standard/comprehensive）。config.toml 由来
- **matrix_case**: size×depth_level の組合せを表す §8 セル識別子
- **MatrixDecision**: §8 セルから導出される後続 Step 向け判定結果（単一の真実）
- **副作用なし停止**: frontmatter/journal/commit を変更せず案内して終了する停止様式

## 不明点と質問（設計中に記録）

[Question] なし（計画 AI レビュー 3R で判定結果インターフェース・enum 正規化・SoT 整合は確定済み）
[Answer] -
