# ドメインモデル: Unit 003 Merge 承認・実行 + Post-merge cleanup

## 概要

release フェーズ **Step 3「Merge 承認 + 実行」** と **Step 4「Post-merge」** の概念モデル。**二層ゲート**（approval gate = 承認判断 / hard gate = CI・PR identity の bypass 不可健全性）を経て merge し、merge 前に `merge_approved` を記録（監査性）、merge 後に branch cleanup・journal・tag/changelog（opt-in）を行う。

**重要**: コードは書かず構造と責務のみ定義する。release.md は実行手順（Markdown）であり、本モデルは Step 3/4 が表現すべきロジックの概念モデルである。

## ステップ0: 事前コード読込み（設計起草前の既存実装把握）

### (a) Read 対象ファイル + 目的

| ファイル | Read 目的 |
|---------|-----------|
| `skills/aidlc-v3/steps/release.md` | Unit 001/002 実装済みの Step 1/2、Step 3/4 プレースホルダ、PR 解決の gh pr view 検証パターンを把握（差し替え対象） |
| `skills/aidlc-v3/templates/release.md` | review 結果サマリの固定マーカー純 YAML（`merge_blocker_any`）= approval gate 入力契約を把握 |
| `skills/aidlc-v3/scripts/state-write.sh` | `release.ready` / `release.merge_approved` 書き込み usage・exit code（0/1/2）・schema_version ガードを把握 |
| `skills/aidlc-v3/scripts/state-validate.sh` | 書込後検証契約を把握 |
| `docs/v3/workflow.md` §3.3 Step 3/4 | ready 化・CI・merge_approved 記録タイミング・post-merge の規定を把握（SoT） |
| `docs/v3/data-model.md` §3.3 / §5.1 / §7 | 書込タイミング・complete 判定（merge_approved ∧ PR merged）・journal 形式を把握（SoT） |
| `.aidlc/config.toml` | `merge_method` / `version_tag` / `changelog` / `branch_mode` の値を把握（opt-in 分岐） |

### (b) 設計時に意識すべき挙動

- **CI green は merge 直前の最終コミット（`merge_approved` を含む head）に対して確認する**（計画レビュー #1）。`merge_approved` の commit/push で head が更新されるため、承認前の CI を見ると stale。CI 確認は push の **後** に置く。
- **二層ゲートの分離**（計画レビュー #2）: approval gate（承認判断 / ユーザー確認で解決し得る）と hard gate（CI success・PR identity / **ユーザー確認でも bypass 不可**）を混同しない。
- **Step 3 開始時に PR 再検証**（計画レビュー #3）: Unit 002 後に PR が close/merge・head/base 変化・stale 番号の可能性があるため、`state-read.sh release.pr_number` + `gh pr view` で OPEN・head/base 一致を fail-closed 確認してから進む。
- **`merge_approved` は merge 前に記録**（監査性）。merge 後はブランチが消えるため、merge 前の最終コミットで書き込み push する。
- **complete 判定は `merge_approved` ∧ PR merged の両方**（`data-model.md §5.1` 評価順 1 / 再定義せず参照）。`merge_approved` 単独では complete としない。
- **state 書込は `release.ready` / `release.merge_approved` のみ**（schema 不変 / Unit 003 境界）。`pr_number` は Unit 002。
- **tag/changelog は opt-in**。`version_tag` / `changelog` が偽なら skip して正常完了（opt-out でも成功）。
- **gh の PR state は `OPEN`/`CLOSED`/`MERGED`、draft は `isDraft`**（Unit 002 設計 R2 と同じ）。
- **review サマリ欠損は fail-closed**（マーカー不在・parse 不能・`merge_blocker_any` 欠落/非 boolean → 自動承認せずユーザー確認）。
- **merge_approved=true での再開（idempotency / 設計レビュー #1 / R2）**: hard gate 停止（CI pending 等）後の再実行で 3-3 を無条件再実行すると `updated_at` だけの再 commit/push で head が変わり CI が再び stale/pending になるループに陥る。`release.merge_approved` が既に true の場合は **再開経路**に入り、承認 commit（`merge_approved:true` を保持する最新 state.json commit）と PR head を比較する。**一致なら 3-3 を再実行せず** hard gate へ（ループ防止）。**不一致なら stale approval** として approval gate から再評価し、3-3 で新 head に再アンカーする（`merge_approved` を false に戻さない / 監査記録を保持）。
- **CI 確認は exact head SHA に固定（設計レビュー #2）**: `headRefOid` と同一 SHA の status/check rollup を見る。`gh run list --branch` のような SHA 非固定参照で別 commit の run / 一部 workflow だけを success 誤認しない。

### (c) 既存実装に基づく代替案検討

| 方針 | 内容 | 採否 | 根拠 |
|------|------|------|------|
| `extend`（`gh` 直接 + 既存 state-write 委譲 + 手順で二層ゲート表現） | ready 化/CI/merge_approved/merge/post-merge を手順で表現し原子書込は既存 state-write へ委譲 | **採用** | Unit 境界（schema 不変 / 新規スクリプトなし）に合致。SoT 再定義回避 |
| `replace`（merge 専用スクリプト新規作成） | `release-merge.sh` で承認/merge/cleanup を一括化 | 却下 | Unit 境界（新規スクリプト追加なし / テストは Unit 004）。`gh` 直接方針に反する |
| `refactor`（state schema に merge 状態を追加） | merge 完了フラグ等を schema に足す | 却下 | schema 不変が境界。complete は merge_approved ∧ PR 実態で導出（schema 追加不要 / data-model §5.1） |

## エンティティ（Entity）

### MergeExecution（Merge 承認・実行 / 集約ルート）

- **ID**: cycle 単位（release Step 3 の評価セッション）
- **属性**: cycle / prIdentity: PrIdentity / approvalVerdict: ApprovalVerdict / hardGateResult: HardGateResult / mergeApprovedRecord: MergeApprovedRecord
- **振る舞い**:
  - revalidatePR(): Step 3 開始時の PR 再検証（fail-closed）
  - resumeIfApproved(): `release.merge_approved` 既存 true 時の再開判定（承認 commit と PR head 一致確認 / 3-3 再実行回避 / stale approval 検出）
  - readyAndRecordReady(): ready 化 + `release.ready` 書込
  - evaluateApprovalGate(): approval gate を評価（承認判断）
  - recordMergeApprovedAndPush(): `merge_approved` を merge 前に書込 + commit + push
  - evaluateHardGate(): hard gate を評価（CI/PR identity / bypass 不可）
  - merge(): hard gate 充足後のみ `gh pr merge`

### PostMergeCleanup（Post-merge / エンティティ）

- **ID**: cycle 単位
- **属性**: integrationBranch / featureBranch / tagEnabled / changelogEnabled
- **振る舞い**: switchAndDeleteBranch() / appendJournal() / optInTagChangelog()

## 値オブジェクト（Value Object）

### PrIdentity（PR 同一性）

- **属性**: number / state（`OPEN`/`CLOSED`/`MERGED`）/ headRefName / baseRefName / headRefOid
- **解釈規則**: 健全 = `state==OPEN` ∧ headRefName==現在ブランチ ∧ baseRefName==統合先。Step 3-0 と hard gate（3-4）の両方で検証

### ApprovalVerdict（承認判断結果 / approval gate）

- **属性**: approved: boolean / source: enum（`auto` / `user` / `fallback_user`）
- **解釈規則**（approval gate / 承認判断のみ）:
  - `manual` → ユーザー明示確認
  - `semi_auto` → review サマリ `merge_blocker_any == false` で `auto`
  - review サマリのマーカー不在・YAML parse 不能・`merge_blocker_any` 欠落/非 boolean → 自動承認せず `AskUserQuestion`（fail-closed / `fallback_user`）

### HardGateResult（健全性ゲート結果 / bypass 不可）

- **属性**: passed: boolean / reason: string
- **解釈規則**（hard gate / **ユーザー確認でも bypass 不可**）: 以下すべて充足で passed:
  1. PR `state==OPEN`（既に `MERGED` は不可）∧ head/base 一致
  2. `headRefOid` が 3-3 で push した最終コミット（`merge_approved` を含む head）と一致
  3. その head commit（`headRefOid` と同一 SHA）の status/check rollup が必要 check すべて `success`（`gh pr view <N> --json statusCheckRollup` 等で **exact head SHA に紐づく** rollup を確認。`gh run list --branch` のような SHA 非固定参照で別 commit の run / 一部 workflow だけを success 誤認しない / 設計レビュー #2）
  いずれか未充足（CI `failure`/未完了/pending/取得不能 / PR identity 不一致 / `MERGED`）→ passed=false（停止）

### MergeApprovedRecord（merge 承認記録 / 監査）

- **属性**: written: boolean / beforeMerge: boolean
- **不変性**: merge 前の最終コミットで `release.merge_approved: true` を記録（merge 後にブランチが消えても残る）

### ApprovalCommitRef（承認コミット参照 / 再開・stale approval 検出）

- **属性**: sha（`release.merge_approved: true` を保持する `.aidlc/state.json` の **最新 commit** / `git log` で特定。false→true への遷移 commit に限らず、承認操作として state.json を更新した最新 commit を指す）
- **解釈規則**（設計レビュー #1 / R2）: `release.merge_approved` 既存 true での再開時、承認 commit を特定し PR `headRefOid` と比較する:
  - **一致（承認後に新規 commit なし）** → 3-1〜3-3 を再実行せず hard gate（3-4）へ。hard gate が CI pending で停止した後の再実行でも `updated_at` だけの再 push を行わず、CI 再 stale ループを防ぐ。
  - **不一致（承認後に追加 commit が入った = stale approval）** → `merge_approved` を **false に戻さず**（監査記録の意味を壊さない）、approval gate（3-2）から再評価し、3-3 で `merge_approved`（true→true / `updated_at` 更新）を **新しい head に再アンカー**してから hard gate へ。これにより新 head に対する承認 commit を安定して特定できる。

### CiConclusion / MergeMethod / OptInFlags

- CiConclusion: enum（`success`/`failure`/`pending`/`none`/`unavailable`）
- MergeMethod: config `merge_method`（`merge`/`squash`/`rebase`/`ask`）
- OptInFlags: `version_tag` / `changelog`（偽なら該当処理 skip / opt-out でも正常完了）

## 集約（Aggregate）

### MergeExecution（Merge 実行集約）

- **集約ルート**: MergeExecution
- **不変条件**:
  - state 書込は `release.ready` / `release.merge_approved` のみ（schema 不変）
  - merge は **approval gate ∧ hard gate の両方**を通過した後のみ
  - **hard gate（CI success / PR identity / PR open）はユーザー確認でも bypass 不可**
  - `merge_approved` は merge 前に記録（merge 後にブランチが消えても承認記録が残る）
  - CI green は `merge_approved` を含む最終 head に対して確認（stale CI 排除）
  - complete は `merge_approved` ∧ PR merged の両方（`data-model.md §5.1` / 再定義しない）

## ドメインサービス

### ApprovalGateService

- **責務**: review サマリ `merge_blocker_any` と automation_mode から ApprovalVerdict を導出（承認判断のみ / fail-closed）
- **操作**: evaluate() → ApprovalVerdict

### HardGateService

- **責務**: PrIdentity・headRefOid 一致・CI conclusion から HardGateResult を導出（bypass 不可）
- **操作**: evaluate() → HardGateResult

### PostMergeService

- **責務**: branch cleanup・journal 追記・tag/changelog opt-in
- **操作**: cleanup()

## リポジトリインターフェース

新規永続化リポジトリは設けない。既存スクリプト経由:

- StateWriter（既存 `state-write.sh release.ready|release.merge_approved <bool>`）: exit 0/1/2
- StateValidator（既存 `state-validate.sh`）: 書込後 `status:valid` 確認
- StateReader（既存 `state-read.sh release.pr_number`）: PR 再検証用
- PR/merge/CI 操作は `gh`（pr ready / pr view / pr merge / run）、git（switch / branch -d / tag / push）に委譲

## ユビキタス言語

- **approval gate**: 「高重要度未解決指摘なし」の承認判断ゲート（ユーザー確認で解決し得る）
- **hard gate**: CI success・PR identity の健全性ゲート（**ユーザー確認でも bypass 不可**）
- **merge_approved（merge 承認記録）**: merge してよいと承認したことの記録（merge 済みではない / merge 前に記録）
- **complete**: `merge_approved` ∧ PR merged の両方（`data-model.md §5.1` 評価順 1）

## 不明点と質問（設計中に記録）

[Question] CI green はいつの commit に対して確認するか。
[Answer] `merge_approved` を含む最終 head（push 後）に対して。承認前に確認すると merge_approved commit で head が変わり stale になるため、CI 確認は push の後（hard gate 3-4）に置く（計画レビュー #1）。

[Question] hard gate はユーザー確認で bypass できるか。
[Answer] 不可。CI success・PR identity・PR open は merge 安全性に直結するため bypass 不可で停止。ユーザー確認で解決し得るのは approval gate（承認判断）と review サマリ欠損時のみ（計画レビュー #2）。

[Question] tag/changelog が opt-out のとき Step 4 は失敗扱いか。
[Answer] 正常完了。`version_tag`/`changelog` が偽なら該当処理を skip して成功（opt-out でも release 完了）。

[Question] hard gate 停止後に再実行するとどうなるか（idempotency）。
[Answer] `release.merge_approved` 既存 true 時は再開経路に入る。承認 commit（`merge_approved:true` を保持する最新 state.json commit）と PR head が **一致なら 3-3 を再実行せず** hard gate へ（updated_at 再 push ループ防止）。**不一致（承認後に追加 commit）なら stale approval** として approval gate から再評価し、3-3 で新 head に再アンカー（`merge_approved` を false に戻さず監査記録を保持 / 設計レビュー #1 / R2）。

[Question] hard gate の CI 確認はどの commit に対して行うか。
[Answer] PR `headRefOid` と同一 SHA の status/check rollup（`gh pr view --json statusCheckRollup` 等）。SHA 非固定の `gh run list --branch` で別 commit / 一部 workflow を success 誤認しない（設計レビュー #2）。
