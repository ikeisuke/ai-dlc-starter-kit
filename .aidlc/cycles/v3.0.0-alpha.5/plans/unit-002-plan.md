# Unit 002 実装計画: develop Step 2（設計生成）+ design テンプレート

- **サイクル**: v3.0.0-alpha.5（Phase 4 = develop normal/risky 分岐）
- **Unit**: 002-develop-design-step
- **depth_level**: standard（Phase 1 設計あり）
- **automation_mode**: semi_auto / review_mode: required
- **関連 Issue**: #736（部分対応 / Phase 4）
- **依存 Unit**: 001-develop-size-depth-branching（完了）

## 1. 目的

`skills/aidlc-v3/steps/develop.md` の Step 2（計画 + 設計）を実装し、Unit 001 が確立した
size×depth_level 判定結果（`MatrixDecision` / `decide_matrix`）に基づいて `designs/<id>-<slug>.md`
に design 成果物を生成する。`skills/aidlc-v3/templates/` に design テンプレートを新設し、
depth_level に応じて条件付きセクション（`## Risk Analysis` / `## Test Plan` / `## Rollback Note`）を
含める。Step 2 完了時に Design 承認ゲートを発火させる。

判定の正本は `docs/v3/data-model.md` §8。本 Unit は §8 を再解釈せず、Unit 001 が提供する
派生要件フィールド（`design_mode` / `risk_analysis` / `test_plan` /
`rollback_note` 等）を消費して design 本体の詳細度・含むセクションを決める。

## 2. 増分境界の明確化【重要】

§8 マトリクスの **design 必須セル（normal/risky × standard/comprehensive）はすべて review も必須**である:

| matrix_case | design_required | review_required |
|-------------|-----------------|-----------------|
| normal_standard | true (simple) | true (code) |
| normal_comprehensive | true (full) | true (code_security_design) |
| risky_standard | true (full + rollback) | true (code_security) |
| risky_comprehensive | true (full + risk + test + rollback) | true (code_security_design) |

そのため **Unit 002 単体では end-to-end で「完了」に到達するセルは存在しない**。
Unit 002 の到達境界は **Step 2 完了直後で停止**（案A）に一意化する。具体的には:

1. Unit 001 の現行スコープ境界ガード（Step 1 末尾 = status 遷移前で `design_required=true || review_required=true`
   を副作用なし停止）を **Step 2 と Step 3 の間へ移設**する。これにより design 生成（Step 2）は通り、実装（Step 3）
   には進まない
2. Step 2 で design 成果物を生成し、Design 承認ゲートを発火（`automation_mode` に従う）
3. design 必須セルは全て `review_required=true` であり Unit 003（review 実行）が未実装のため、
   **Step 2 完了直後（Step 3 実装に進む前）で停止**する。status は `done` に遷移させず `in_progress` のまま留める

> **境界の一意化（指摘 #2 対応）**: develop.md は Step 3（実装）/ Step 4（検証）を「常に実行」と定義しているが、
> design 必須セルは review（Unit 003）なしでは完走できないため、実装・検証の副作用を起こすことに利得がない。
> よって Unit 002 では **Step 2→Step 3 の間に「Unit 003 未実装中は Step 2 完了後に停止する時限ガード」を明記**し、
> Step 3（実装）/ Step 4（検証）/ Step 5（レビュー）には進ませない。
> - **発生する副作用**: status の `in_progress` 化（pending 開始時のみ `pending→in_progress` 遷移。Step 2 で design を
>   生成するには work item を作業中にする必要があるため。Unit 001 は design 必須セルを status 遷移前に停止していたので
>   in_progress 化していなかった点が本 Unit との差分）+ design ファイル生成（Step 2）。`done` 遷移・実装/検証/レビュー
>   （Step 3/4/5）の副作用は発生しない
> - **status**: `in_progress`（`done` 遷移なし。pending 開始時は `in_progress` へ遷移、resume 時は `in_progress` 維持）
> - **解除**: Unit 003（review）完了時にこの時限ガードを外し、design 必須セルが Step 3→4→5→6 まで完走できるようにする
>   （Unit 001 のスコープ境界ガードを後続 Unit が外すパターンと一貫）

## 3. 実装アプローチ

### 3.1 対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-v3/templates/design.md`（新設） | design テンプレート。必須セクション（Goal/Context/Design 本体）+ 条件付きセクション（`## Risk Analysis` / `## Test Plan` / `## Rollback Note`）。既存テンプレート（work-item.md）のスタイルに合わせる（プレースホルダ `{{ }}`、見出し構造、条件付きセクションはコメントで明示） |
| `skills/aidlc-v3/steps/develop.md` | Unit 001 のスコープ境界ガード（現行 Step 1 末尾 行 148-154）を **Step 2 と Step 3 の間** へ移設（design 生成は通し、Step 3 実装には進ませない「Unit 003 未実装中の時限ガード」）。Step 2（現行 行 178-186 のプレースホルダ）を実装: `design_required=true` で `designs_path` に design テンプレートを起点に生成、`design_mode`/`risk_analysis`/`test_plan`/`rollback_note` で条件付きセクションを充足/省略、Design 承認ゲート発火。さらに行 183 付近の散文が使う `*_required` 表記（`risk_analysis_required` 等）を decide_matrix 契約名（行 116 の表が正本 = `risk_analysis`/`test_plan`/`rollback_note`）に表記統一する（指摘 #1 対応 / エイリアス非導入） |
| `docs/v3/workflow.md` | §3.2 の design 記述に depth_level 注記を補強（`risky+standard` は risk analysis / test plan を含まず rollback note のみ等、§8 正本との差分を明記）。SoT は §8（data-model.md）に一本化、§3.2/§6.3 は非正本ビュー注記を維持 |
| `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` | design 生成の最小動作確認テストを追加（design ファイルが `designs_path` に生成される / depth_level 別に条件付きセクションの有無が正しい / 生成後 Step 2 完了直後で停止し status は in_progress 維持）。本格的な全マトリクス回帰は Unit 004 に委譲。既存テストの非回帰確認 |

### 3.2 既存安全境界・契約の利用（局所パース禁止 / SoT 二重定義回避）

- **判定結果の消費**: Unit 001 の `decide_matrix`（§8 materialized view）出力を消費する。本 Unit は §8 を
  再解釈せず、`design_mode` / `risk_analysis` / `test_plan` / `rollback_note` /
  `designs_path` フィールドのみを参照する
- **出力先パス**: Unit 001 配線済みの `designs_path`（`basename` + `<id>-` prefix 検証 / `invalid_artifact_path`
  ガード）をそのまま利用。develop.md に新規パスパース・局所 grep/sed を足さない（#733 P1/P2 再発防止）
- **frontmatter / status**: 既存 `work-item-next.sh` / `work-item-status.sh` 経由。develop.md に局所パースを足さない
- **テンプレート不在ガード**: design テンプレート不在時は明示エラー停止（暗黙のデフォルト生成をしない / NFR 可用性）

### 3.3 design_mode と条件付きセクションの写像（§8 派生要件 → design 本体）

Unit 001 の派生要件フィールドを design 本体の構成に写像する（写像は §8 セル由来であり本 Unit で再判定しない）:

| matrix_case | design_mode | Risk Analysis | Test Plan | Rollback Note |
|-------------|-------------|---------------|-----------|---------------|
| normal_standard | simple | 省略 | 省略 | 省略 |
| normal_comprehensive | full | 含む | 省略 | 省略 |
| risky_standard | full | 省略 | 省略 | 含む（非空） |
| risky_comprehensive | full | 含む | 含む | 含む（非空） |

> 上表は Unit 001 の `decide_matrix` 出力（`risk_analysis` / `test_plan` / `rollback_note` フィールド）と
> 一致する。本 Unit は判定をせず、フラグに従って条件付きセクションを充足/省略するだけ。

## 4. 完了条件チェックリスト

Unit 定義「責務」セクションから抽出:

- [ ] `skills/aidlc-v3/templates/design.md` を新設（design 本体 + 条件付きセクション `## Risk Analysis` /
      `## Test Plan` / `## Rollback Note`）。既存テンプレートのスタイル（プレースホルダ・見出し構造）に整合
- [ ] develop.md Step 2 を実装: Unit 001 の `design_required=true` 判定で `designs_path` に design 成果物を生成
- [ ] depth_level 別の design 構成が §8 派生要件と一致する:
      `normal+standard`=簡易 design / `normal+comprehensive`=design+リスク分析 /
      `risky+standard`=design+rollback note（非空） / `risky+comprehensive`=design+リスク分析+test plan+rollback note
- [ ] `designs/<id>-<slug>.md` を Unit 001 配線の `designs_path`（既存ガード経由）に生成する。新規パースを足さない
- [ ] Design 承認ゲート発火（`automation_mode` に従う / semi_auto は条件付き auto）
- [ ] スコープ境界ガードを **Step 2→Step 3 の間** へ移設し、design 生成（Step 2）は通すが Step 3 実装には進ませない。
      design 必須セルは review 必須かつ Unit 003 未実装のため Step 2 完了直後で停止し、status は `done` に遷移させず
      `in_progress` のまま留める（Step 3/4/5 の副作用なし。Unit 003 完了でガードを外し完走）
- [ ] develop.md の MatrixDecision 条件フィールドを decide_matrix 契約名に表記統一する（行 116 の表が正本 =
      `risk_analysis`/`test_plan`/`rollback_note`、行 183 付近散文の `*_required` 表記を是正。`design_required`/
      `review_required` はサフィックス付きが正本のため変更しない / エイリアス非導入）
- [ ] design テンプレート不在時は明示エラー停止（暗黙のデフォルト生成をしない）
- [ ] design 文書に機密情報を含めない（review-flow.md のマスク方針準用）
- [ ] workflow.md §3.2 の文言差を §8 正本に整合（`risky+standard` の risk analysis/test plan 不含を明記）。
      §6.3 の非正本ビュー注記を維持し SoT 二重定義を作らない
- [ ] ドッグフーディング特殊処理（自リポジトリ判定）を埋め込まない
- [ ] design 生成の最小動作確認テストが緑（生成有無 / 条件付きセクションの有無 / 生成後 Step 2 完了直後で停止 /
      status は pending 開始時 `pending→in_progress`・resume 時 `in_progress` 維持で `done` 非遷移 / Step 3/4 副作用なし）。
      既存 test-develop-flow.sh および既存テスト群が緑（非回帰）。shellcheck clean / markdownlint 0 error

## 5. 境界（本 Unit に含まないもの）

- size×depth_level 判定ロジック本体（Unit 001 実装済みを利用）
- レビューのルーティング・実行（reviewing-construction-design 等 / Unit 003）
- review 必須セルの end-to-end 完走（Unit 003 完了後に成立）
- 全 size×depth_level 組合せの回帰テスト（Unit 004。本 Unit は最小の動作確認のみ）
- `normal + minimal` での本 Step スキップ（Unit 001 の分岐で制御済み）

## 6. リスク・考慮事項

- **増分境界の非完走性**: design 必須セルは全て review 必須のため、本 Unit 単体で完走するセルはない。
  到達境界（Step 2 完了直後で停止 / Step 3 実装に進まない）をテストで明示的に検証する
- **副作用様式の変化**: Unit 001 の design 必須セル「status 遷移前の副作用なし停止」から、Unit 002 では
  「status の `in_progress` 化（pending 開始時は `pending→in_progress`）+ design 生成」へ境界が変わる。
  テストで「design ファイル生成済み」「status が `done` に遷移せず `in_progress`」「実装・検証（Step 3/4）の
  副作用が発生していない」を assert する。**status 観点は pending 開始時（`pending→in_progress`）と resume 時
  （`in_progress` 維持）を区別して検証する**
- **SoT 整合**: §8（data-model.md）を唯一の正本とし、design 本体の条件付きセクションは Unit 001 の派生要件
  フィールドに従う。workflow.md §3.2 は注記参照に留める
- **テンプレート不在の可用性**: design テンプレート不在時は暗黙生成せず明示エラー（NFR 可用性）
