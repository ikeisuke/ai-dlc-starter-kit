# ドメインモデル: Unit 004 §1.5 Issue 起票フロー Try ループ化 + predecessor 互換 + dogfooding 検証

## 概要

`retrospective` 振り返り skill の §1.5 Step 4 を **「集約 Issue 1 件起票」から「Try 件数分のループ起票」** に再定義する Unit。Unit 001 が SoT として定義した `aggregate_issue_enabled` フラグ（既定 `false`）と cap 仕様（サイクル内 T Issue 起票合計の上限）を **利用する側** として実装し、各 T Issue 本文に 5 必須セクション（背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連）を保証する。

同時に、集約 Issue 廃止に伴い `scripts/lib/predecessor-issue.sh` の既存 5 経路を破壊せず、集約 Issue 不在時の retrospective ラベル付き T Issue 群集計経路（内部サブ分岐 `t_issue_milestone_scope` / `t_issue_label_fallback`）を新規追加する。

本ドメインモデルは **「Try ドラフトから T Issue Draft への構造化変換」「5 セクション本文構築」「ループ起票オーケストレーション」「predecessor 経路の決定木拡張（後段追加）」** の 4 つを中核とし、Intent §「patch として許容する条件」（後方互換 opt-in / 既存 5 経路不変）を構造で担保する。

**重要**: 本ドメインモデル設計では **コードは書かず**、構造と責務の定義のみを行う。

---

## ステップ0 事前コード読込み

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|----------|
| `skills/aidlc-retrospective/steps/retrospective.md` §1.5 Step 4 周辺（L324-380）+ §1.2.5 セルフレビュー（L151-188）+ §1.2 主因切り分け（L130-138）+ aggregate_issue_enabled 説明（L219-241）| (i) 既存集約 Issue 起票フロー（dialog token → cap 判定 → create → update）の遷移点 / (ii) `aggregate_issue_enabled` 既存分岐の埋め込み位置 / (iii) セルフレビュー応答 history 記録フォーマットを踏襲するため |
| `skills/aidlc/scripts/lib/predecessor-issue.sh`（特に純粋関数 `_pure_classify_resolution_path` L67-100 と実装 `predecessor_resolve_issue` L290-349）| (i) 既存 5 経路の評価順序（純粋関数で決定 → 実装側 case 分岐）/ (ii) NDJSON 出力フィールド契約（`issue_url` / `candidates_json` / `file_path` / `resolution_path`）/ (iii) `__pred_gh_query` 経由の gh CLI 集計パターン / (iv) `printf -v` 系 result-out 関数の `_local_<関数省略名>_<名>` 命名規約 を踏襲するため |
| `skills/aidlc/scripts/lib/retrospective-api.sh` | (i) Facade 公開関数（`retrospective_api_create_issue` / `retrospective_api_check_cap` / `retrospective_api_aggregate_enabled` / `retrospective_dialog_token_verify` / `retrospective_api_ensure_label`）の引数・stdout・exit code 契約 / (ii) Type B 関数の fail-safe 出力規約 を踏襲するため |
| `skills/aidlc/templates/retrospective_template.md`（特に L25-31 Try 表）| (i) 現行 Try セクションが単一表（優先度 / 施策 / 反映先）であること / (ii) 5 見出し再構成での影響範囲（h3 → h4 階層化、各 Try のセクション分化）を把握するため |
| `tests/predecessor-issue-handoff.bats`, `tests/retrospective-issue-create.bats`, `tests/retrospective-aggregate-enabled.bats`（既存）| (i) fixture / mock パターン（gh CLI スタブ・対話確認トークン bypass）/ (ii) 既存 5 経路の `resolution_path` 期待値 を踏襲するため |
| `.aidlc/cycles/v2.6.5/inception/retrospective/*`（旧サイクル振り返り fixture）| 旧サイクル維持テスト（`resolution_path = milestone_and_label` 維持 + 新動作経路に入らない）の fixture 源として参照 |
| `CLAUDE.md`（本リポジトリ）「AI エージェント Bash ツール経由の安全パターン」「printf -v 系 result-out 関数の local 命名規約」| helper 内部実装 / steps/retrospective.md 内 Bash ブロック / テスト fixture 作成いずれでも `$(...)` / backtick を Bash ツール引数文字列に直書きしない規約、および result-out 関数の dynamic scope shadowing 回避規約遵守のため |

### (b) 設計時に意識すべき挙動

- §1.5 Step 4 の既存集約 Issue 起票フローは **dialog token 検証 → cap 判定 → `retrospective_api_create_issue` → update フック** の 5 段階で構成され、各段階で exit code（特に exit 4 = dialog-required）による短絡が定義済み。Try ループ化後も **各 T 起票ごとに dialog token を再検証** し、exit 4 時はループ自体を中断する（既存契約を維持）
- `aggregate_issue_enabled` は Unit 001 で `retrospective_api_aggregate_enabled` helper として実装済 / `true` → 集約 1 件（既存フロー） / `false` → T 件数分ループ（本 Unit）。Step 4 冒頭で本 helper を呼び、分岐先を決定する構造
- cap 仕様（Unit 001 SoT）は「サイクル内 T Issue 起票合計の上限」として定義され、ループ起票では **各 T 起票直前に `retrospective_api_check_cap` を再評価**（cap 到達時は当該 T 以降の起票を拒否し warn ラベル付与で記録）
- 「構造課題昇格根拠」セクションへの自動転記は §1.2.5 セルフレビュー応答（3 観点 yes/no 選択 + verdict `pass`/`rebuttal`/`capped`/`undecidable`）を history/operations.md から read し、選択肢ラベルを引用する形で組み立てる。verdict=`capped` 時は 5 セクション必須を満たしつつ `selfreview-capped` ラベルを付与
- 既存 5 経路のうち `warn_continue` は「全 4 経路 0 件時のフォールバック」として最下流に配置されている。**新動作経路は warn_continue の直前（4 経路すべて 0 件ヒット後）に挿入** することで、新経路発火時も warn_continue は実質オーバーライドされず、warn_continue 自体のロジックは変更しない（既存挙動を構造で保護）
- 新動作経路の内部サブ分岐は集計クエリ条件で分かれる: (i) `t_issue_milestone_scope` = `gh issue list --label retrospective --milestone <ms>` でヒット ≥ 1 / (ii) `t_issue_label_fallback` = `gh issue list --label retrospective`（milestone 無）でヒット ≥ 1。サブ分岐名は既存 5 経路名（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）と名前空間が衝突しないよう `t_issue_` プレフィックスで分離
- `candidates_json` 配列は既存経路 1/1' と同じく `__pred_gh_query` の結果を `jq 'sort_by(.closedAt) | reverse'` で closedAt 降順ソートして構築。新経路では `closedAt` が null のケース（OPEN T Issue が混入）があり得るため、null 安全ソート（null を末尾）を追加要件として明示
- テンプレ改修（`retrospective_template.md`）は 1 Try = 1 Issue 単位への構造化のため、見出し階層を h3 → h4 へ引き上げ、各 Try ごとに 5 必須セクションのスケルトンを配置する。`aggregate_issue_enabled = true` 時用の旧構造（単一 Try 表）は後方互換のため別ブロック（あるいは別テンプレファイル）として保持

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 | 根拠 |
|------|------|------|------|
| `refactor` 集約フロー本体を loop 化 | `retrospective_api_create_issue` 自体を内部 loop 化して 1 呼び出しで全 T を起票 | **却下** | (i) Type B 関数の「1 呼び出し 1 起票」契約を破壊する (ii) cap 判定 / dialog token 検証 / exit 4 短絡が単一呼び出し内で多段に起こり、エラー回復が複雑化する (iii) Unit 001 が public API 変更なしを SoT 化済 |
| `extend` §1.5 Step 4 のみで分岐 | Step 4 冒頭で `aggregate_issue_enabled` を判定し、分岐先で集約 or ループ起票を選択 | **採用** | (i) Step 4 が分岐点となる Unit 001 設計と整合 (ii) `retrospective_api_create_issue` の契約は不変 (iii) ループ起票が Step 4 内で完結する透過的な構造 (iv) ループ各回で既存契約（dialog token / cap / update フック）を 1 つも壊さない |
| `replace` predecessor 既存経路を再設計 | 既存 5 経路を新動作経路に統合し、`resolution_path` 列挙を簡素化 | **却下** | Intent §「明示的に除外するもの」で「`predecessor_resolve_issue` の経路再設計は v2.7.0+ defer」と明示。後方互換破壊禁止 |
| `add` predecessor に後段追加 | 既存 5 経路を一切変更せず、warn_continue 直前に新動作経路 2 サブ分岐を挿入 | **採用** | (i) 既存 5 経路の挙動は構造で不変保証 (ii) 旧サイクル fixture（`Retrospective: {cycle}` 集約あり）は経路 1 で resolve され新経路に到達しない (iii) 集約廃止の新サイクル（経路 1〜4 すべて 0 件）でのみ新経路発火 |

---

## エンティティ（Entity）

### `RetrospectiveCycle`

- **ID**: `cycle_id`: string（`v{major}.{minor}.{patch}` 形式 / 識別子）
- **属性**:
  - `aggregate_enabled`: bool - Unit 001 helper `retrospective_api_aggregate_enabled` の解決結果
  - `cap_limit`: int - `feedback_max_per_cycle` 設定値（Unit 001 SoT）
  - `cycle_dir`: filesystem path - `.aidlc/cycles/{cycle_id}/` の絶対パス
- **振る舞い**:
  - `resolveCreationStrategy()` - aggregate_enabled に応じて `AggregatedCreationStrategy` または `TryLoopCreationStrategy` を返す
  - `cap()` - 現在の起票数と limit から `CapDecision` を返す

### `TryDraft`

- **ID**: `try_id`: string（KPT テンプレ内 Try 表の行番号由来 / 識別子）
- **属性**:
  - `summary_line`: string - Try 表「施策」列の生テキスト（1 行）
  - `priority`: string - Try 表「優先度」列
  - `target`: string - Try 表「反映先」列
  - `related_kp`: List<{kind: K|P, summary: string}> - 紐づく K / P エントリ
- **振る舞い**:
  - `toTitle(cycle_id)` - `[Retrospective: {cycle_id}] {summary_line から導出された 1 行要約}` 形式の `IssueTitle` を返す
  - `extractTitleSeed()` - `summary_line` から引用記号 / 箇条書きマーカー除去 + 80 文字 truncate

### `TIssueDraft`

- **ID**: `(cycle_id, try_id)` の複合キー
- **属性**:
  - `title`: IssueTitle
  - `body_sections`: RequiredSectionSet - 5 必須見出し集合
  - `labels`: Set<string> - 既定 `[retrospective]` / verdict=`capped` 時に `selfreview-capped` 追加
  - `relations`: List<IssueRelation> - milestone / 関連 Issue へのリンク（`aggregate_issue_enabled = true` 時のみ `Relates: #<集約>` 追加）
- **振る舞い**:
  - `validateSectionsNonEmpty()` - 5 見出しすべて非空（最低 1 行 / 明示的「該当なし」記載は非空扱い）か検証 → `SectionValidation` を返す
  - `compose()` - 5 必須セクションを order 固定で結合し最終本文を生成

### `PredecessorIssueQuery`

- **ID**: `(cycle_id, query_kind)` の複合キー（query_kind ∈ {legacy_5_routes, t_issue_milestone, t_issue_label}）
- **属性**:
  - `gh_args`: List<string> - `gh issue list` 呼び出し引数
  - `expected_label`: string - `retrospective` 固定
  - `expected_milestone`: string|nil - milestone scope のみ
- **振る舞い**:
  - `execute()` - `__pred_gh_query` 経由で gh CLI 呼び出し → 生 JSON 配列を返す
  - `normalizeCandidates(raw_json)` - closedAt 降順ソート（null 安全） + `Candidate` 値オブジェクト集合を返す

---

## 値オブジェクト（Value Object）

### `IssueTitle`

- **属性**: `cycle_prefix`: `[Retrospective: {cycle_id}]` / `summary`: 1 行要約 / `max_length`: 80
- **不変条件**: 改行を含まない / `cycle_prefix` で始まる / 全体 ≤ 200 文字

### `RequiredSectionSet`

- **必須要素**（順序固定）:
  1. `## 背景` - 該当 K/P 要旨
  2. `## 主因切り分け` - §1.2 の 3 分類（プロダクト固有 / AI-DLC 固有 / 両方）+ 根拠
  3. `## 構造課題昇格根拠` - §1.2.5 セルフレビュー verdict + 選択肢ラベル引用
  4. `## 想定対策` - Try 本文
  5. `## 関連` - サイクル番号 / 関連 Issue / milestone リンク
- **不変条件**: 5 見出しすべて存在 / 各見出し配下に最低 1 行非空テキスト（「該当なし」明示記載は非空扱い）

### `SectionValidation`

- **属性**: `non_empty_count`: int / `missing_sections`: List<string> / `verdict`: `pass` | `incomplete`
- **不変条件**: `verdict=pass` ⇔ `non_empty_count == 5` ∧ `missing_sections == []`

### `CapDecision`

- **属性**: `mode`: `t_issue_loop` | `aggregate` / `current_count`: int / `limit`: int / `over`: bool
- **不変条件**: `over == true` ⇔ `current_count >= limit`（cap 到達以降の追加起票拒否）

### `Candidate`

- **属性**: `issue_number`: int / `title`: string / `closed_at`: ISO timestamp|nil / `url`: string
- **不変条件**: `issue_number > 0` / `url` は GitHub Issue URL 形式

### `ResolutionPath`

- **列挙値**:
  - 既存（Unit 004 で不変）: `milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`
  - 新規（本 Unit 追加）: `t_issue_milestone_scope` / `t_issue_label_fallback`
- **不変条件**: 既存 5 経路の出力値は文字列完全一致で v2.6.5 と同一

### `SelfReviewVerdict`

- **属性**: `verdict`: `pass` | `rebuttal` | `capped` | `undecidable` / `responses`: {A, B, C} → yes|no|none
- **不変条件**: `verdict=capped` ⇒ `selfreview-capped` ラベル付与を強制

---

## 集約（Aggregate）

### `RetrospectiveIssueCreation` 集約

- **集約ルート**: `RetrospectiveCycle`
- **構成要素**: `TryDraft[]` / `TIssueDraft[]` / `CapDecision` / `Map<try_id, SelfReviewVerdict>`（Try 単位の verdict 集合）
- **責務**:
  - cycle に紐づく全 Try について **start → cap 判定 → dialog token 検証 → TIssueDraft 構築 → validateSectionsNonEmpty → create → update** の遷移を整合性をもって実行
  - aggregate_enabled に応じて単一 Aggregate Issue（旧）または Try 件数分の TIssueDraft（新）を生成
  - **Try 単位 verdict モデル**: §1.2.5 セルフレビューは Try 単位で実施される（3 観点 × Try 件数分の応答）。verdict は `Map<try_id, SelfReviewVerdict>` として保持し、compose / label 付与 / skip 判定は Try ごとに参照する

### `PredecessorResolution` 集約

- **集約ルート**: `PredecessorIssueQuery`
- **構成要素**: `ResolutionPath` / `Candidate[]` / `NdjsonOutput`
- **責務**:
  - 既存 5 経路 → 新動作 2 サブ分岐 → warn_continue の順で経路を評価し、最初にヒットした経路の `resolution_path` と `candidates` を確定
  - 既存 5 経路の挙動を介入せず後段追加で新経路を評価する

---

## ドメインサービス（Domain Service）

### `TryLoopCreationStrategy`

- **責務**: `aggregate_enabled = false` 時に Try 件数分のループ起票を統括
- **入力**: `RetrospectiveCycle` + `TryDraft[]` + `Map<try_id, SelfReviewVerdict>`（Try 単位の verdict 集合）
- **処理フロー**:
  1. cycle 単位で対話確認トークンを発行（`retrospective_api_record_response`）
  2. Try 集合をループ:
     - cap 判定（`retrospective_api_check_cap`）→ over 時は **`break`（残 Try 一括停止）** + 残 Try 件数を `skipped_count(cap_reached)` に計上
     - dialog token 検証（`retrospective_dialog_token_verify`）→ exit 4 で **`break`（残 Try 一括停止）** + 残 Try 件数を `skipped_count(dialog_required)` に計上
     - verdict := verdict_map[try.try_id]（Try 単位 verdict 取得）
     - TIssueDraft を build（verdict を SectionComposer に渡す）+ 5 セクション validate → invalid 時は `selfreview-incomplete` warn ラベル付き skip（`continue`、当該 1 件のみ skip）
     - `retrospective_api_create_issue` で起票
     - verdict.verdict=`capped` 時に `retrospective_api_ensure_label selfreview-capped` を当該 Issue に付与
     - update フック（`retrospective_api_update_issue`）
  3. ループ完了後、`creation_summary { created_count, skipped_count: { cap_reached, dialog_required, section_invalid }, cap_reached: bool }` を返す
- **不変条件**: 各 Try の起票は他 Try の成否に影響しない（独立性 / 既存契約継承）。cap 到達と dialog token 失敗は `break`（残 Try 一括停止）/ section invalid は `continue`（当該 1 件のみ skip）と明確に分ける

### `AggregatedCreationStrategy`

- **責務**: `aggregate_enabled = true` 時に既存の単一集約 Issue 起票を保持
- **入力**: `RetrospectiveCycle` + `TryDraft[]`
- **処理フロー**: 既存 §1.5 Step 4 と完全同一（v2.6.5 fixture と diff 0）
- **不変条件**: 入出力契約・stdout フォーマット・exit code は v2.6.5 と一致

### `SectionComposer`

- **責務**: TIssueDraft の 5 必須セクション本文を組み立てる
- **入力**: `TryDraft` + `SelfReviewVerdict`（**当該 Try の verdict 単数**。`Map<try_id, SelfReviewVerdict>` から caller が当該 try_id で lookup して渡す）+ 該当 KP エントリ + cycle metadata
- **処理フロー**:
  1. `## 背景` ← related_kp の要旨
  2. `## 主因切り分け` ← §1.2 マトリクスの該当行
  3. `## 構造課題昇格根拠` ← SelfReviewVerdict.responses の選択肢ラベル + verdict
  4. `## 想定対策` ← TryDraft.summary_line + priority + target
  5. `## 関連` ← cycle_id / milestone link / `aggregate_enabled = true` 時のみ `Relates: #<集約>`
- **不変条件**: 5 セクションすべてに最低 1 行非空テキストを保証（補完不能時は `該当なし` 明示記載）

### `TIssueGroupSearchService`

- **責務**: predecessor 新動作経路で retrospective ラベル付き T Issue を集計
- **入力**: cycle metadata（milestone 任意）
- **処理フロー**:
  1. `t_issue_milestone_scope`: milestone 指定 + `--label retrospective` でクエリ → ヒット ≥ 1 で確定
  2. `t_issue_label_fallback`: milestone 無 + `--label retrospective` でクエリ → ヒット ≥ 1 で確定
  3. いずれも 0 件 → warn_continue に委譲
- **不変条件**: 既存 5 経路すべて 0 件ヒット後にのみ評価される（既存挙動を介入しない）

### `PredecessorResolutionDecider`

- **責務**: 経路評価順序の決定木
- **処理フロー**: `_pure_classify_resolution_path` を後段拡張し、`milestone_and_label` → `label_fallback` → `spool_fallback` → `v2_5_0_compat` → **`t_issue_milestone_scope` → `t_issue_label_fallback`**（新規）→ `warn_continue` の順で評価
- **不変条件**: 既存 5 経路の評価順序・判定条件は v2.6.5 と完全一致

---

## ドメインイベント（Domain Event）

> `depth_level = standard` のため、本 Unit はドメインイベントを最小限に記述する（`comprehensive` で追加）

- `TIssueCreated(cycle_id, try_id, issue_url, labels)`: Try ループ起票で 1 件成功時
- `TIssueSkipped(cycle_id, try_id, reason)`: cap 到達 / dialog token 失敗 / 5 セクション非空 fail 時
- `CapReached(cycle_id, current_count, limit)`: cap 到達検知時
- `NewPredecessorPathTaken(cycle_id, sub_branch, candidates_count)`: 新動作経路 2 サブ分岐のいずれかが発火した時

---

## 不変条件（横断 / Invariants）

1. **後方互換**: `aggregate_enabled = true` 時の出力は v2.6.5 fixture と完全一致（同等性 5 項目 / Unit 001 fixture）
2. **既存 5 経路不変**: predecessor `resolution_path` の既存 5 列挙値の出力は v2.6.5 と文字列一致
3. **dialog token 維持**: 各 T 起票は dialog token 検証を経由（exit 4 でループ中断）
4. **cap 単一性**: cycle 内の T Issue 起票合計が cap 上限を超えない（cap 到達後は warn + skip）
5. **5 セクション非空**: TIssueDraft.validateSectionsNonEmpty が `pass` でないと起票しない（`selfreview-incomplete` ラベル付き skip 経路へ）
6. **AI 透過性**: ループ各回でユーザー対話を介在させない（cycle 単位 1 回の対話確認のみ）

---

## スコープ境界（Out of Scope）

- `aggregate_issue_enabled` フラグ仕様 SoT 定義 / cap 仕様 SoT 定義 → Unit 001（本 Unit は利用側）
- §1.2.5 セルフレビュー観点と判別ガイド整備 → Unit 002
- 三層検証 helper（fact-extract）の実装 → Unit 003
- 既存 5 経路の挙動変更 / 経路再設計 → v2.7.0+ defer
- `Retrospective: {cycle}` タイトル運用の完全廃止 → v2.7.0+ defer
- `retrospective_api_*` 破壊的シグネチャ変更 → v2.7.0+ defer
- dogfooding 検証の実行（4C）→ Operations Phase §1 retrospective ステップに委譲（Construction 内は 4A/4B 完了ゲートまで）
