# Unit 003 実装計画: develop Step 5（レビュー）+ review routing

- **サイクル**: v3.0.0-alpha.5（Phase 4 = develop normal/risky 分岐）
- **Unit**: 003-develop-review-routing
- **depth_level**: standard（Phase 1 設計あり）
- **automation_mode**: semi_auto / review_mode: required
- **関連 Issue**: #736（部分対応 / Phase 4）
- **依存 Unit**: 001-develop-size-depth-branching（完了）, 002-develop-design-step（完了）

## 1. 目的

`skills/aidlc-v3/steps/develop.md` の Step 5（レビュー）を実装し、Unit 001 が確立した
size×depth_level 判定結果（`MatrixDecision` の `matrix_review_mode`）に応じて、既存の
`reviewing-construction-*` スキルへレビューをルーティングする。結果を Unit 001 配線済みの
`reviews/<id>-<slug>.md` に **perspective 別セクション**（`## Code Review` / `## Design Review`）で
記録する。反復上限 5R と Defer 戦略（`OUT_OF_SCOPE` / `TECHNICAL_BLOCKER` 確定指摘の自動 Issue 起票）を
適用する。

あわせて Unit 002 が設置した **Step 2.3 の review 境界ガード**（review 未実装中の時限停止）を**解除**し、
design 必須セル（normal/risky × standard/comprehensive）が Step 3（実装）→ Step 4（検証）→ Step 5
（レビュー）→ Step 6（完了）まで **end-to-end 完走**できるようにする（Unit 001/002 のスコープ境界ガードを
後続 Unit が外すパターンと一貫）。

判定の正本は `docs/v3/data-model.md` §8。本 Unit は §8 を再解釈せず、Unit 001 が提供する判定結果を消費して
ルーティング先・focus・記録セクションを決める。ルーティングのツール選択・処理パス・フォールバックの正本は
`skills/aidlc/steps/common/review-routing.md`、反復・指摘対応・Defer の手順正本は
`skills/aidlc/steps/common/review-flow.md` を参照する（develop.md には判定ロジックを再定義せず参照に留める）。

### 1.1 用語の二重定義回避【重要 / 指摘 #1 対応】

`review_mode` という名称は2つの異なる概念で衝突するため、本 Unit では以下のとおり明確に区別する:

| 名称（本計画・設計での呼称） | 値域 | 由来 / 役割 |
|------------------------------|------|-------------|
| `matrix_review_mode`（= MatrixDecision の `review_mode` フィールド） | `none` / `code` / `code_security` / `code_security_design` | Unit 001 の `decide_matrix`（§8）が出力。**develop の review 実行制御**（どの perspective/focus を実行するか） |
| `routing_review_mode`（= `[rules.reviewing].mode` / review-routing.md `ReviewRoutingInput.review_mode`） | `required` / `recommend` / `disabled` | config 由来。review-routing.md の**処理パス選択制御**（外部CLI/セルフ/ユーザー） |

**変換境界**: develop Step 5 は `matrix_review_mode` を `caller_context`（=「コード生成後」/「設計レビュー」）+ focus +
perspective 群へ変換し、review-routing.md には `routing_review_mode`（config 値）を `ReviewRoutingInput.review_mode`
として渡す。`matrix_review_mode` の値（`code` 等）を routing の `review_mode` 引数に渡さない（不正 enum の混入防止）。

## 2. 増分境界の明確化【重要】

§8 マトリクスの **review 必須セルはすべて design も必須**であり、Unit 002 で design 生成までは到達済み・
Step 2.3 で停止している。本 Unit はこの停止境界を解除し、review 実行 + 完走を成立させる。

| matrix_case | review_required | matrix_review_mode | 本 Unit でのルーティング先 perspective（focus） |
|-------------|-----------------|--------------------|------------------------------------|
| `normal_standard` | true | `code` | code review（focus: code, security） |
| `normal_comprehensive` | true | `code` | code review（focus: code, security） |
| `risky_standard` | true | `code_security` | code review（focus: code, security / security 重点） |
| `risky_comprehensive` | true | `code_security_design` | code review（focus: code, security / security 重点）+ design review（focus: architecture） |

> 上表は Unit 001 の `decide_matrix` 出力（`review_required` / `matrix_review_mode` フィールド）と厳密一致する。
> 本 Unit は §8 を再判定せず、`matrix_review_mode` 値からルーティングを導くだけ。`tiny_*` / `normal_minimal`
> （`review_required=false`）は Step 5 をスキップして完走する（Unit 001 の現行動作を維持）。
>
> **focus 写像の正本化（指摘 #3 対応）**: `reviewing-construction-code` は code 品質 + security の**複合スキル**であり、
> review-routing.md §3「コード生成後」の focus は `code, security` 固定である。したがって `matrix_review_mode=code_security`
> を **security-only と解釈しない**（通常の code review を落とさない）。`code` / `code_security` はいずれも
> `reviewing-construction-code` を `focus: code, security` で呼び出し、`code_security`（risky 由来）では
> security を重点とする旨を呼び出しコンテキストに付与する（workflow.md §6.2「security focus 含む」と整合）。
> 名称 `code` / `code_security` は §8 マトリクスのセル識別子であり、focus を `code` のみ / `security` のみへ
> 縮約する意味ではない。

**到達境界の変化**:

- Unit 002 まで: review 必須セルは Step 2.3 で停止（design 生成 + `in_progress` 維持 / Step 3-6 未到達）
- 本 Unit 完了後: review 必須セルは Step 3（実装）→ Step 4（検証）→ Step 5（レビュー記録）→ Step 6
  （`done` 遷移 + journal + commit）まで完走する

## 3. 実装アプローチ

### 3.1 対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `skills/aidlc-v3/steps/develop.md` | (1) **Step 5 実装**: `review_required=true` で `matrix_review_mode` に従い `reviewing-construction-*` へルーティング、`reviews_path` に perspective 別セクション（`## Code Review` / `## Design Review`、上書き禁止）で記録、5R 上限・Defer 戦略を適用（手順正本は review-flow.md / review-routing.md 参照）。(2) **Step 2.3 review 境界ガードの解除**: design 承認後 Step 3 へ進ませる（`review_required=true` での時限停止を撤去）。(3) **冒頭の位置づけ注記・フロー全体表・Step 5 注記**を「Unit 003 実装済み・end-to-end 完走可能」に更新。(4) deploy/premerge/integration を develop で実行しないガード注記を明記 |
| `docs/v3/workflow.md` | §6.1 の `plan` perspective 実行条件「develop 開始時（normal/risky）」の文言を §6.2/§8 正本と整合（develop の size×depth review マトリクスには plan review が materialized されないことを明記 / SoT 不整合の確定。詳細は §5 参照） |
| `skills/aidlc-v3/templates/review.md`（新設・**設計で要否確定**） | reviews 成果物の perspective 別セクション骨子（`## Code Review` / `## Design Review`）。templates/design.md（Unit 002）と同じスタイル。インライン記述で足りるなら新設しない判断を Phase 1 設計で確定 |
| `skills/aidlc-v3/scripts/tests/test-develop-flow.sh` | `decide_review_routing` 純粋関数（`matrix_review_mode` → ルーティング先 + 記録セクション）を追加。各 matrix_case の routing assert。**境界ガード解除に伴う既存 rc=26 テストの完走化（rc=0 + `done` + reviews ファイル生成）**。`reviews_path` の perspective 別セクション構造検証。既存テスト群の非回帰確認 |

### 3.2 review routing 決定木（Phase 1 設計で確定 / 概要）

```text
Input: MatrixDecision（review_required / matrix_review_mode / reviews_path）+ designs_path（design review 対象）

1. review_required = false（tiny_* / normal_minimal）→ Step 5 スキップ → Step 6 へ
2. review_required = true:
   2a. matrix_review_mode = code             → reviewing-construction-code（focus: code, security）
                                                 → reviews_path に `## Code Review`
   2b. matrix_review_mode = code_security    → reviewing-construction-code（focus: code, security / security 重点）
                                                 → reviews_path に `## Code Review`
   2c. matrix_review_mode = code_security_design
                                             → reviewing-construction-code（focus: code, security / security 重点）
                                                 → reviews_path に `## Code Review`
                                             + reviewing-construction-design（focus: architecture / 対象 = designs_path）
                                                 → reviews_path に `## Design Review`
```

- `caller_context` 写像: code review = 「コード生成後」（review-routing.md §3）/ design review = 「設計レビュー」
- ツール選択・処理パス（外部CLI/セルフ/ユーザー直行）・フォールバックは review-routing.md §3/§4/§5/§6/§7 に委譲。
  routing に渡す `review_mode` は config の `routing_review_mode`（§1.1）であり `matrix_review_mode` ではない
- 反復上限 5R・`OUT_OF_SCOPE`/`TECHNICAL_BLOCKER` 確定指摘の自動 Issue 起票（Defer）は review-flow.md に委譲
- security focus 記録の公開マスク方針は review-flow.md のマスク方針に従う（NFR セキュリティ）

### 3.2.1 review-flow.md からの委譲範囲の限定【指摘 #2 対応】

review-flow.md は v2 系の commit 規約（レビュー前コミット / レビュー後コミット三段階 / legacy `review-summary` 更新）と
成果物配置を含むが、これらは v3 develop の契約（Step 6 で work item 単位の **1 commit 集約** / 成果物は
`.aidlc/cycles/<cycle>/reviews/<id>-<slug>.md`）と衝突する。本 Unit は review-flow.md から**以下の責務のみ**を利用し、
commit タイミングと成果物保存は **v3 develop（develop.md）側の契約で上書きする**:

| review-flow.md から利用する責務 | 利用する |
|--------------------------------|---------|
| 5R 反復上限・反復レビューの完了判定（`unresolved_count` 等） | ○ |
| Defer 戦略（`OUT_OF_SCOPE` / `TECHNICAL_BLOCKER` 確定指摘の自動 Issue 起票） | ○ |
| 機密情報除外スキャン・公開マスク方針 | ○ |
| 外部CLI/セルフ/ユーザー パス選択（review-routing.md 経由） | ○ |
| レビュー前/後コミット・三段階コミット・`review-summary` 更新 | **×（v3 develop の Step 6 単一 commit が上書き）** |
| 成果物配置（`history/*.md` 等） | **×（v3 develop は `reviews/<id>-<slug>.md` を使用）** |

> develop.md Step 5 にこの「委譲は手順ロジックのみ、commit / 成果物保存は v3 develop が正本」という adapter 境界を
> 明記する。必要に応じて review-flow.md 側にも v3 develop 利用時の注記追加を設計で検討する（review-flow.md 本体の
> 改変は最小限に留め、SoT 二重定義を作らない）。

### 3.3 既存安全境界・契約の利用（局所パース禁止 / SoT 二重定義回避）

- **判定結果の消費**: Unit 001 の `decide_matrix`（§8 materialized view）出力の `review_required` /
  `matrix_review_mode` のみを参照。§8 を再解釈しない
- **出力先パス**: Unit 001 配線済みの `reviews_path`（`basename` + `<id>-` prefix 検証 / `invalid_artifact_path`
  ガード）をそのまま利用。develop.md に新規パスパース・局所 grep/sed を足さない（#733 P1/P2 再発防止）
- **design review 対象**: Unit 002 が生成済みの `designs_path`（`risky_comprehensive` のみ）を design review 入力とする
- **ルーティング/反復ロジック**: review-routing.md / review-flow.md に委譲し、develop.md に判定ロジックを再定義しない
- **frontmatter / status**: 既存 `work-item-status.sh` 経由。develop.md に局所パースを足さない

### 3.4 perspective 別セクション記録の規約

- `reviews_path`（`reviews/<id>-<slug>.md`）に perspective 別セクションで記録する。`## Code Review` /
  `## Design Review` を見出しとする
- design review は `code_security_design`（`risky_comprehensive`）のみ。それ以外は `## Code Review` のみ
- **冪等記録（セクション単位 upsert / 指摘 #4 対応）**: 「追記・上書き禁止」を実装可能な粒度へ落とし、
  Phase 1 設計で以下の upsert 規則を確定する:
  - 各 perspective セクションを状態マーカーで区切る（例: `<!-- aidlc-review:code:start -->` …
    `<!-- aidlc-review:code:end -->`、セクション内に完了状態を持たせる）
  - **complete 済みセクション**: 再 develop（resume）時は再追記・上書きせずスキップ（冪等）
  - **incomplete セクション**: 同一マーカー区間を**置換**（部分書き込みの重複を防ぐ）
  - 実装差分が変わって再レビューが必要なケースの扱い（新 run 区間として明示）を設計で確定する
  - マーカー記法・完了状態キーの具体形は Phase 1 設計で正本化（develop.md と整合）

## 4. 完了条件チェックリスト

Unit 定義「責務」セクションから抽出:

- [ ] develop.md Step 5 を実装: `review_required=true` で `matrix_review_mode` に従い既存 `reviewing-construction-*`
      へルーティングする
- [ ] `matrix_review_mode`（§8 / `code`/`code_security`/`code_security_design`）と `routing_review_mode`
      （config / `required`/`recommend`/`disabled`）を明確に区別し、routing には config 値を渡す（§1.1）。
      `matrix_review_mode` 値を review-routing.md の `review_mode` 引数に渡さない
- [ ] ルーティングが §8 review マトリクスと一致する:
      `normal+standard`/`normal+comprehensive`=code review（focus: code, security）/
      `risky+standard`=code review（focus: code, security / security 重点）/
      `risky+comprehensive`=code review（security 重点）+ design review。
      `code_security` を security-only に縮約しない（reviewing-construction-code の複合 focus を維持 / §1.1・§2 写像）
- [ ] `reviews/<id>-<slug>.md` を Unit 001 配線の `reviews_path`（既存ガード経由）に生成し、perspective 別
      セクション（`## Code Review` / `## Design Review`）で記録する。新規パースを足さない。
      resume 時はセクション単位 upsert（complete はスキップ / incomplete は置換）で冪等に記録する（§3.4）
- [ ] plan / design / code の 3 perspective のルーティング能力を持ちつつ、実行は §8 マトリクスで制御する
      （plan review は §8 review マトリクスに materialized されないため develop では実行しない）
- [ ] 反復上限 5R を適用し、`OUT_OF_SCOPE` / `TECHNICAL_BLOCKER` 確定指摘は自動 Issue 起票（Defer 戦略 /
      手順正本は review-flow.md）
- [ ] review-flow.md からの委譲を「5R/完了判定/Defer/マスク/パス選択」に限定し、commit タイミング（Step 6 単一 commit）と
      成果物保存（`reviews/<id>-<slug>.md`）は v3 develop 側の契約で上書きする旨を develop.md に明記する（§3.2.1）
- [ ] `deploy` / `premerge` / `integration` を develop で実行しない（release 用）ことを注記・保証する
- [ ] Step 2.3 の review 境界ガードを解除し、design 必須セルが Step 3→4→5→6 まで完走する
      （`done` 遷移 + journal 追記 + work item 単位 commit）
- [ ] develop.md 冒頭の位置づけ注記・フロー全体表・Step 5 注記を「Unit 003 実装済み・完走可能」に更新する
- [ ] workflow.md §6.1 の `plan` perspective 実行条件文言を §6.2/§8 正本と整合する（SoT 不整合の確定 / §5 参照）
- [ ] security focus レビューの公開記録はマスク方針（review-flow.md）に従う（NFR セキュリティ）
- [ ] レビュー CLI 不在時は review-routing.md のフォールバック（self/ユーザー）に従う（NFR 可用性）
- [ ] ドッグフーディング特殊処理（自リポジトリ判定）をスキル呼び出しに埋め込まない
- [ ] テストハーネス拡張が緑: `decide_review_routing` の各 matrix_case routing assert /
      境界ガード解除に伴う完走化（旧 rc=26 → rc=0 + `done` + reviews 生成）/ `reviews_path` セクション構造検証。
      既存 test-develop-flow.sh および既存テスト群が緑（非回帰）。shellcheck clean / markdownlint 0 error

## 5. SoT §6.1 不整合の確定【設計で正本化】

Unit 定義「技術的考慮事項」が指す SoT 内不整合を本 Unit の設計で確定する:

- **不整合**: `docs/v3/workflow.md` §6.1（perspective 統合表）は `plan` perspective の実行条件を
  「develop 開始時（normal/risky）」と列挙する。一方 §6.2（size × review マトリクス）/
  `data-model.md` §8（size × depth_level）は develop で追加される review を **code review のみ**とし、
  `matrix_review_mode` 値（`code` / `code_security` / `code_security_design`）に plan review を含まない。
- **確定方針**: **§6.2/§8 を正本**とし、develop の size×depth review マトリクスには **plan review を
  materialized しない**（develop Step 5 は code / design perspective のみ実行）。§6.1 の `plan` 行は
  「将来 `aidlc-review` 統合時の perspective カタログ」であり、§8 由来の develop 自動 review 実行マトリクスとは
  別レイヤである旨を文言で明記して整合させる。
- **routing 能力との関係**: Unit 003 は plan/design/code の 3 perspective の**ルーティング能力**を実装するが、
  develop での**実行**は §8 マトリクス（`matrix_review_mode`）が制御する。plan review は能力としては配線可能だが、
  §8 上 develop では実行されない（責務分離: capability ≠ execution）。

## 6. 境界（本 Unit に含まないもの）

- size×depth_level 判定ロジック本体（Unit 001 実装済みを利用）
- design 成果物の生成（Unit 002 実装済み / design review はその出力を対象とする）
- `aidlc-review`（9→1 統合スキル）の新規作成（本サイクル対象外 / 別サイクル）
- release フェーズのレビュー（`premerge` / `integration` / `deploy` = Phase 5 / release 用）
- 全 size×depth_level 組合せ + 外部レビュー CLI モック/スタブの本格回帰テスト（Unit 004。本 Unit は
  ルーティング決定 + 構造検証の最小確認のみ）

## 7. リスク・考慮事項

- **AI 実行部分とハーネス模擬境界**: Step 5 の review 実行本体（`reviewing-construction-*` 呼び出し・
  対話・反復）は AI 判断であり bash ハーネスでは再現しない（Unit 002 の Design 承認ゲートと同じ扱い）。
  ハーネスは「ルーティング決定（`decide_review_routing`）」と「決定的副作用（reviews ファイルの perspective 別
  セクション生成 + 完走）」を模擬・検証する。実 CLI 依存の回帰は Unit 004 に委譲
- **境界ガード解除の非回帰影響**: Unit 002 が追加した rc=26（review 境界停止）テストは本 Unit で
  「完走（rc=0 + `done` + reviews 生成）」へ変わる。既存テストの**意図的な書き換え**であり、
  漏れなく更新して非回帰を担保する
- **冪等性**: resume（再 develop）時に reviews セクションを二重追記・上書きしない記録形式を設計で確定する
- **SoT 整合**: §8（data-model.md）を唯一の正本とし、routing 先 perspective は `matrix_review_mode` に従う。workflow.md §6.1 は
  文言整合のみ（review 実行マトリクスの正本を §6.2/§8 に一本化）
- **セキュリティ記録**: security focus レビュー結果の公開記録はマスク方針（review-flow.md）に従い、
  機密情報を `reviews_path` に残さない
