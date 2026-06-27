# ドメインモデル: Unit 002 PR 整備 + release.md テンプレート + review ルーティング

## 概要

release フェーズ **Step 2「PR 整備」** の概念モデル。PR 解決（作成/更新/番号採用/競合停止）、`release.pr_number` の state 書き込み、`release.md` 成果物生成、release-level review（premerge/integration/deploy）のルーティングと結果の機械可読集約を扱う。

**重要**: コードは書かず構造と責務のみ定義する。release.md は実行手順（Markdown）であり、本モデルは Step 2 手順が表現すべきロジックの概念モデルである。

## ステップ0: 事前コード読込み（設計起草前の既存実装把握）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|-----------|
| `skills/aidlc-v3/steps/release.md` | Unit 001 実装済みの Step 1・骨格・Step 2 プレースホルダの書式を把握（Step 2 を実装に差し替える対象） |
| `skills/aidlc-v3/steps/define.md` | `early_pr: true` 時の Draft PR 作成タイミング（Step 4-5）を把握。PR 重複防止の解決順設計の根拠 |
| `skills/aidlc-v3/scripts/state-write.sh` | `release.pr_number` 書き込み usage・exit code（0/1/2）・先頭ゼロ拒否・schema_version ガードを把握 |
| `skills/aidlc-v3/scripts/state-validate.sh` / `state-read.sh` | 書き込み後検証・pr_number 読取の契約把握 |
| `skills/aidlc/steps/common/review-routing.md` §3/§7 | perspective→caller_context→skill_name/focus 写像、呼び出し形式、routing_review_mode を把握 |
| `skills/aidlc/steps/common/review-flow.md` | 反復・指摘対応・機密マスクの委譲範囲を把握 |
| `docs/v3/workflow.md` §3.3 Step 2 / §6 | PR 整備の規定・review perspective 実行条件を把握（SoT） |
| `docs/v3/data-model.md` §3.3 / §8 / §10 | `release.pr_number` 書込タイミング・成果物要否・release review は release.md 集約を把握（SoT） |
| `skills/aidlc-v3/templates/*.md` | 既存テンプレート（design/journal/work-item/intent）の書式を把握（release.md テンプレートの体裁お手本） |

### (b) 設計時に意識すべき挙動

- **`early_pr: true` と pr_number の関係**: define の早期 Draft PR は `release.pr_number` を必ずしも書き込まない可能性がある。よって PR 解決は pr_number だけに依存せず、**同一 head branch の open PR 探索**も併用する（重複作成防止 / 計画レビュー #1）。
- **PR・pr_number は Step 2 の必須成果物 + Unit 003 の merge 入力**。`gh_status != available` は warn-continue ではなく**停止**（計画レビュー #2）。
- **review 結果は release.md に集約**し `reviews/*.md` を生成しない（`data-model.md §8`/§10）。develop の `reviews/*.md`（work item 単位）と混在させない。
- **review_mode 二語の衝突**: `routing_review_mode`（config `[rules.reviewing].mode`）と perspective 名は別物。review-routing には config 値を渡し、perspective 名を `review_mode` 引数に渡さない（計画レビュー #4 / review-flow.md §5.0 と同じ注意）。
- **review 結果サマリは固定マーカー純 YAML**（計画レビュー #3 / R2）。Unit 003 はマーカー間をそのまま YAML として parse。欠損は fail-closed。
- **state.json は `release.pr_number` のみ書き込み**。schema 不変、`ready`/`merge_approved` は触らない（Unit 003 境界）。
- **PR 本文・release.md に機密を含めない**（file-based body / review-flow マスク方針準用）。

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 | 根拠 |
|------|------|------|------|
| `extend`（`gh` 直接 + 最小手順 + 既存 state-write/review-routing 委譲） | PR 解決・pr_number 書込・release.md 生成・review ルーティングを手順で表現し、原子書込/ルーティングは既存資産へ委譲 | **採用** | Unit 境界（schema 不変 / reviewing 本体非改修）に合致。SoT 再定義を避け既存契約を再利用 |
| `replace`（release 専用 PR 管理スクリプト新規作成） | `release-pr.sh` を新規実装し PR 解決/番号書込を一括化 | 却下 | Unit 002 スコープは Step 2 手順 + テンプレート。新規スクリプトは責務肥大・テスト波及（Unit 004）。`gh` 直接 + 最小ラッパ方針（Unit 定義 技術考慮）に反する |
| `refactor`（review-routing.md に release perspective を追記） | ルーティング正本に release 用エントリを足す | 却下 | review-routing.md §3 は既に premerge/integration/deploy を保持（CallerContext マッピング）。再定義不要・SoT 二重定義回避 |

## エンティティ（Entity）

### PRPreparation（PR 整備 / 集約ルート）

- **ID**: cycle 単位（release Step 2 の評価セッション）
- **属性**: cycle / prRef: PullRequestRef / releaseDoc: ReleaseDoc / reviewSummary: ReviewResultSummary
- **振る舞い**:
  - resolvePR(): PRResolution を導出（作成/更新/番号採用/競合停止）
  - persistPrNumber(): PR 作成・番号確定時に `release.pr_number` を書き込み検証
  - routeReviews(): 実行条件に従い perspective をルーティングし結果を集約
  - generateReleaseDoc(): テンプレートから release.md を生成（review サマリ含む）
  - gate(): Step 2 ゲート = PR ready 確認（ready 化は Step 3）

### PullRequestRef（PR 参照）

- **ID**: pr_number（integer / 未確定は null）
- **属性**: number / headBranch / baseBranch（統合先 / `baseRefName`）/ state（`OPEN` / `CLOSED` / `MERGED` / gh の実データ準拠）/ isDraft: boolean（draft は state ではなく独立属性 / 設計レビュー R2）/ bodyPath
- **振る舞い**: create() / update(bodyFile) — いずれも `gh` 経由

### ReleaseDoc（release.md 成果物）

- **ID**: `.aidlc/cycles/<cycle>/release.md`
- **属性**: prOverview / workItemCompletionList / reviewSummaryBlock / ciStatus / mergeRecord
- **振る舞い**: renderFromTemplate(templates/release.md)

### ReviewResultSummary（review 結果サマリ / 機械可読）

- **属性**: schemaVersion / entries: List<ReviewResultEntry> / mergeBlockerAny: boolean
- **振る舞い**: toMarkerBlock() — 固定マーカー間に純 YAML として出力（Unit 003 入力契約）

## 値オブジェクト（Value Object）

### PRResolution（PR 解決結果）

- **属性**: action: enum（`update` / `adopt_and_update` / `create` / `conflict_stop`）/ number: integer|null
- **解釈規則**（計画レビュー #1 + 設計レビュー #1 / fail-closed）:
  - `release.pr_number` あり → `gh pr view <N>` で **state == `OPEN`（draft PR も gh では state=OPEN / isDraft=true なので含まれる）かつ headBranch == current branch かつ baseBranch（`baseRefName`）== 統合先ブランチ** を確認できた場合のみ `update`。不一致（別 head ブランチ）・別 base ブランチ・`CLOSED`/`MERGED`・取得不能 → `conflict_stop`（停止）。stale 番号・別ブランチ PR・別 base PR・closed/merged PR の誤採用を防ぐ（設計レビュー #1 / R2 + コードレビュー base 検証）
  - `null` かつ同一 head branch の open PR が 1 件 → `adopt_and_update`（番号採用 → pr_number 書込 → 更新）
  - `null` かつ open PR なし → `create`（作成 → pr_number 書込）
  - 同一 head branch に open PR 複数 → `conflict_stop`（fail-closed / ユーザー解決）

### ReviewExecutionCondition（review 実行条件）

- **属性**: perspective: enum（premerge/integration/deploy）/ shouldRun: boolean / skipReason: string|null
- **解釈規則**（`workflow.md §6` / 数え方明確化 = 設計レビュー #3）: premerge=常時 run / integration=**実装済み（`status:done`）work item が 2 件以上**で run / deploy=**`size:risky` かつ `status:done` の work item が 1 件以上**で run。`withdrawn` は release 可能判定（`data-model.md §5.1` 評価順 4）には完了扱いで含むが、**review 実行条件の件数には含めない**（実装済み = done のみが review 対象）。本差分は SoT（workflow §6「複数 work item 完了時 / risky 時」）を done ベースで具体化したものであり再定義ではない

### ReviewResultEntry（perspective 別結果 / Unit 002→003 契約）

- **属性**: perspective / status: enum（passed/failed/skipped）/ unresolvedCount: int / maxSeverity: enum（high/medium/low/none）/ mergeBlocker: boolean / skipReason: string|null
- **不変性**: release.md 生成時点のスナップショット
- **解釈規則**: mergeBlocker = (high の未解決指摘あり)。status=skipped 時 skipReason 非 null

### GhAvailability（gh 可用性）

- **属性**: available: boolean
- **解釈規則**（計画レビュー #2）: `available=false` → 停止（PR 未確定で Step 2 完了不可）。例外: ユーザー手動 PR 番号 + `gh pr view` 存在確認で続行

## 集約（Aggregate）

### PRPreparation（PR 整備集約）

- **集約ルート**: PRPreparation
- **含まれる要素**: PullRequestRef / ReleaseDoc / ReviewResultSummary
- **不変条件**:
  - state 書き込みは `release.pr_number` のみ（schema 不変 / `ready`・`merge_approved` 不可侵）
  - PR 解決は fail-closed（複数 open PR は停止 / 重複作成しない）
  - `gh` 不在は停止（PR は必須成果物）
  - review 結果は release.md に集約し `reviews/*.md` を作らない
  - Step 2 は ready 化・merge を行わない（Unit 003 境界）

## ドメインサービス

### PRResolver

- **責務**: `release.pr_number` + open PR 探索から PRResolution を一意に導出（fail-closed）
- **操作**: resolve() → PRResolution

### ReviewRouter

- **責務**: ReviewExecutionCondition を判定し、perspective→caller_context→skill へルーティング（既存 review-routing.md/review-flow.md へ委譲）。結果を ReviewResultEntry に正規化
- **操作**: route() → List<ReviewResultEntry>
- **写像**（`review-routing.md §3`）: premerge→`PR マージ前`/`reviewing-operations-premerge`(code,security) / integration→`統合とレビュー`/`reviewing-construction-integration`(code) / deploy→`デプロイ計画承認前`/`reviewing-operations-deploy`(architecture)

### ReleaseDocGenerator

- **責務**: `templates/release.md` から release.md 成果物を生成。review サマリを固定マーカー純 YAML で埋め込む
- **操作**: generate() → ReleaseDoc

## リポジトリインターフェース

新規永続化リポジトリは設けない。既存スクリプト経由:

- StateWriter（既存 `state-write.sh release.pr_number <N>`）: pr_number 書込（exit 0/1/2）
- StateValidator（既存 `state-validate.sh`）: 書込後 `status:valid` 確認
- StateReader（既存 `state-read.sh release.pr_number`）: pr_number 読取
- PR 操作は `gh`（create/edit/view）に file-based body で委譲

## ユビキタス言語

- **PR 解決（PR resolution）**: pr_number と open PR から作成/更新/番号採用/競合停止を決める fail-closed 判定
- **review 結果サマリ（review result summary）**: release.md 内の固定マーカー純 YAML ブロック。Unit 003 merge ゲートの入力契約
- **merge_blocker**: 当該 perspective に高重要度未解決指摘がある状態
- **perspective**: premerge / integration / deploy（release-level review の観点）

## 不明点と質問（設計中に記録）

[Question] early_pr で Draft PR 済みの場合、pr_number が null のことがあるか。
[Answer] あり得る（define は早期 Draft PR を作るが pr_number 書込タイミングは release 実行者 / data-model §3.3）。よって PR 解決は pr_number 単独依存にせず open PR 探索を併用し fail-closed（計画レビュー #1）。

[Question] gh 不在時の Step 2 の扱いは。
[Answer] 停止（PR・pr_number は必須成果物 + Unit 003 入力 / 計画レビュー #2）。例外は手動 PR 番号提示 + `gh pr view` 確認のみ。

[Question] review 結果サマリの parse 契約は。
[Answer] 固定マーカー間を純 YAML とし Unit 003 がそのまま parse。欠損・parse 不能・enum 外は fail-closed（計画レビュー #3 / R2）。

[Question] pr_number があれば無条件にその PR を更新してよいか。
[Answer] 不可。`gh pr view <N>` で state == `OPEN`（draft PR も含む / draft は `isDraft` 属性で state ではない）かつ headBranch == current branch を確認できた場合のみ update。`CLOSED`/`MERGED`・別ブランチ・取得不能は conflict_stop（設計レビュー #1 / R2）。

[Question] integration/deploy の件数は done のみか withdrawn も含むか。
[Answer] review 実行条件は実装済み = `status:done` の件数で数える（`withdrawn` は含めない）。release 可能判定（done/withdrawn）とは別レイヤ（設計レビュー #3 / workflow §6 を done ベースで具体化）。
