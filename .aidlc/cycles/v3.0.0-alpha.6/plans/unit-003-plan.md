# Unit 003 実装計画: Merge 承認・実行 + Post-merge cleanup

## 対象 Unit

`003-merge-approval-execution-and-post-merge` — release フェーズ **Step 3「Merge 承認 + 実行」** と **Step 4「Post-merge」** を `steps/release.md` に実装する（Unit 001 のプレースホルダを差し替え）。PR ready 化と `release.ready` 書き込み、CI パス確認、`release.merge_approved` の merge 前記録、merge 実行、merge 後の branch cleanup・journal 追記・tag/changelog（opt-in）を担う。

- **サイクル**: v3.0.0-alpha.6 / **depth_level**: standard / **automation_mode**: semi_auto / **review_mode**: required
- **依存 Unit**: 002（完了 / Step 2 の PR・`release.pr_number`・review 結果サマリが前提）
- **関連 Issue**: #736（部分対応 / Relates）

## スコープ

### 含まれるもの（本 Unit で実装）

1. **Step 3「Merge 承認 + 実行」**（`steps/release.md` の Step 3 プレースホルダを実装に差し替え）
   - PR を ready 化（`gh pr ready`）し `release.ready: true` を `state-write.sh` で書き込む（`data-model.md §3.3`「ready 化時に書き込み」）。
   - CI パス確認（merge 前の必須ゲート / `workflow.md §3.3` Step 3）。
   - **merge 承認ゲート**: `manual`=明示確認必須 / `semi_auto`=承認前提（CI green・高重要度未解決指摘なし・未 merged）充足で自動、未充足はユーザー確認へ。**「高重要度未解決指摘なし」の判定入力は Unit 002 が release.md に記録した review 結果サマリ（固定マーカー純 YAML）の `merge_blocker_any` を読む**（Unit 002→003 データ契約 / 欠損・parse 不能・enum 外は fail-closed でユーザー確認）。
   - `release.merge_approved: true` を **merge 前の最終コミット**で `state-write.sh` 書き込み、commit + push してから `gh pr merge`（`merge_method` 設定に従う）。
   - complete 判定が `merge_approved` + PR 実態（merged）の両方を要する旨を手順に明記（導出規則は再定義せず `data-model.md §5.1` を参照）。
2. **Step 4「Post-merge」**
   - 統合先ブランチへ switch・merge 済み feature branch 削除。
   - `journal.md` に release 完了を追記。
   - tag（`version_tag` 真）・changelog（`changelog` 真）を opt-in 実行。**opt-out でも正常完了**。

### 含まれないもの（境界 / 後続 Unit）

- PR 作成・`release.pr_number` 記録・release.md 作成・review ルーティング（Unit 002 / 実装済み）。
- state.json schema 変更（既存 `release.ready` / `release.merge_approved` のみ書き込み）。
- フェーズ導出規則の定義（`data-model.md §5.1` を参照するのみ、再定義しない）。
- `SKILL.md` の `release` 公開フリップ・express 整合・新規テスト本格追加（Unit 004）。本 Unit は既存 v3 テスト green の sanity 確認に留める。

## 設計 SoT（再定義せず参照）

- `docs/v3/workflow.md §3.3`（Step 3・4 / merge_approved の記録タイミング）
- `docs/v3/data-model.md §3.3`（`release.ready` / `release.merge_approved` 書き込みタイミング）/ `§5.1`（complete 判定 = merge_approved + PR merged の両方）/ `§7`（journal 形式）
- Unit 002 の `templates/release.md` review 結果サマリ（固定マーカー純 YAML / `merge_blocker_any`）= merge ゲート入力契約

## 実装アプローチ

1. **Step 3 の構成**（release.md に節として実装 / 既存 Step と同じ書式）。**hard gate（bypass 不可）と approval gate（承認判断）を分離する**（レビュー #2）:
   - 3-0 PR 再検証（fail-closed / stale 入力防止 = レビュー #3）: `state-read.sh release.pr_number`（exit 1/2 は停止）→ `gh pr view <N> --json state,headRefName,baseRefName,headRefOid` で `state == OPEN` かつ `headRefName == 現在ブランチ` かつ `baseRefName == 統合先` を確認。不一致・`CLOSED`/`MERGED`・取得不能は **fail-closed 停止**（Unit 002 後に PR が変化した stale 入力で ready 化/merge に進まない）。
   - 3-1 PR ready 化: `gh pr ready <N>` → `state-write.sh release.ready true`（exit 0/1/2）→ `state-validate.sh` 検証。
   - 3-2 merge 承認ゲート（**approval gate** / 承認判断のみ）: `manual`=ユーザー明示確認 / `semi_auto`=（`merge_blocker_any == false`）充足で自動承認。review 結果サマリのマーカー不在・YAML parse 不能・`merge_blocker_any` 欠落/非 boolean は自動承認せず `AskUserQuestion` でユーザー確認（fail-closed）。本ゲートは「高重要度未解決指摘なし」の承認判断のみを扱う（CI/PR 健全性は 3-4 の hard gate が担う）。
   - 3-3 merge_approved 記録 + push: `state-write.sh release.merge_approved true` を **merge 前の最終コミット**で書き込み、commit + push（remote 同期）。
   - 3-4 最終 hard gate（CI green / PR identity / PR open / **bypass 不可** = レビュー #1・#2）: push 後に `gh pr view <N> --json state,headRefName,baseRefName,headRefOid` で PR が `OPEN`・head/base 一致・`headRefOid` が **push した最終コミット（merge_approved を含む head）と一致**を確認し、**その head commit の CI conclusion が `success`** であることを確認する。これにより「merge 直前の最終コミットに対する CI green」を保証する（merge_approved commit で head が変わっても再確認するため stale CI を排除）。CI `failure`・未完了・取得不能、PR identity 不一致、PR が既に `MERGED` は **ユーザー確認でも bypass 不可で停止**。
   - 3-5 merge 実行: hard gate 充足後のみ `gh pr merge <N> --<merge_method>`（`merge_method` 設定に従う）。
   - 3-6 complete 判定の注記: `merge_approved` 単独では complete としない（`data-model.md §5.1` 評価順 1 = merge_approved ∧ PR merged）。
2. **Step 4 の構成**:
   - 4-1 統合先へ switch + merged feature branch 削除（merge 済み確認後）。
   - 4-2 `journal.md` に release 完了追記（`## YYYY-MM-DD` 配下 / `data-model.md §7`）。
   - 4-3 tag（`version_tag` 真時）・changelog（`changelog` 真時）opt-in。設定が偽なら skip して正常完了。
3. **merge 承認ゲートの fail-closed**: review サマリのマーカー不在・parse 不能・`merge_blocker_any` 欠落/enum 外 → 自動承認せずユーザー確認。
4. **安全性**: merge は承認ゲート通過後のみ。push を伴うため未コミット・remote 同期の事前確認を含める。
5. **監査性**: `release.merge_approved` を merge 前に記録し、merge 後にブランチが消えても承認記録が残る。
6. **Bash ツール安全規約**（`$(...)` / backtick 不使用）・**クロスプラットフォーム**（git/gh の POSIX 互換）・**ドッグフーディング特殊処理を埋め込まない**。

## 変更ファイル

| ファイル | 操作 | 内容 |
|---------|------|------|
| `skills/aidlc-v3/steps/release.md` | 編集 | Step 3・4 プレースホルダを実装に差し替え + 冒頭の実装範囲注記更新 |

- `SKILL.md` は変更しない（公開フリップは Unit 004）。state.json schema・既存スクリプトは変更しない。

## merge ゲートの二層構造（hard gate と approval gate の分離）

merge までに 2 種類のゲートを通す。**両者は責務が異なり、混同しない**（レビュー #2）:

### approval gate（3-2 / 承認判断 / ユーザー確認で解決し得る）

- 扱う対象: 「高重要度未解決指摘なし」の承認判断のみ。
- `semi_auto` の自動承認条件: Unit 002 が release.md に記録した review 結果サマリ（固定マーカー純 YAML）の `merge_blocker_any == false`。
- review サマリのマーカー不在・YAML parse 不能・`merge_blocker_any` 欠落/非 boolean → 自動承認せず `AskUserQuestion` でユーザー確認（fail-closed）。`manual` は常にユーザー明示確認。

### hard gate（3-4 / 健全性ゲート / ユーザー確認でも bypass 不可）

- 扱う対象: CI 健全性と PR identity。**ユーザー確認でも bypass できない**（merge の安全性に直結するため）。
- 充足条件（すべて必須）:
  1. PR が `OPEN`（既に `MERGED` は停止）かつ headRefName==現在ブランチ・baseRefName==統合先一致
  2. PR の `headRefOid` が 3-3 で push した最終コミット（`merge_approved` を含む head）と一致
  3. その head commit の CI conclusion == `success`
- いずれか未充足（CI `failure`・未完了・取得不能 / PR identity 不一致 / PR が `MERGED`）→ **停止**（ユーザー確認でも続行不可）。

> **設計意図（レビュー #1）**: CI green は **merge 直前の最終コミット（`merge_approved` を含む head）** に対して確認する。`merge_approved` の commit/push で PR head が更新されるため、3-2 以前に古い head の CI を見て判断すると stale になる。よって CI 確認は 3-3（push）の **後**（3-4）に置き、`headRefOid` 一致と併せて確認する。

## テスト方針

- 新規テストファイルの本格追加は Unit 004。本 Unit では release.md Step 3/4 手順が依存する既存スクリプト（`state-write.sh release.ready` / `release.merge_approved`）の挙動が前提どおりであることを確認し、既存 v3 テスト 7 スイートを実行して green（回帰ゼロ）を sanity 確認する。
- merge / push / tag 等の git・gh 操作はドライ検証（実 merge を行わない）で扱い、ネットワーク非依存にする。

## NFR

- **監査性**: `release.merge_approved` を merge 前に記録し、merge 後にブランチが消えても承認記録が残る。
- **互換性**: state.json schema 不変。既存 v3 テスト green 維持。
- **安全性**: merge は承認ゲート通過後のみ。push を伴うため未コミット・remote 同期の事前確認を含める。
- **クロスプラットフォーム**: コマンド例は macOS / Linux 両対応。

## 完了条件チェックリスト

- [ ] `steps/release.md` の Step 3「Merge 承認 + 実行」が実装され、Step 3 プレースホルダが置き換わっている
- [ ] Step 3 開始時に PR 再検証（`state-read.sh release.pr_number` の exit 1/2 停止 + `gh pr view` で OPEN・head/base 一致）を行い、stale 入力は fail-closed 停止する
- [ ] PR ready 化 + `release.ready: true` を `state-write.sh` で書き込み `state-validate.sh` で検証する手順がある
- [ ] approval gate（3-2）が manual=明示確認 / semi_auto=`merge_blocker_any=false` で自動、欠損・parse 不能・enum 外は fail-closed でユーザー確認（Unit 002 の review 結果サマリ純 YAML を読む）
- [ ] `release.merge_approved: true` を merge 前の最終コミットで書き込み commit + push する
- [ ] hard gate（3-4）が push 後に PR OPEN・head/base 一致・`headRefOid` が push した head と一致・その head commit の CI conclusion==success を確認し、**ユーザー確認でも bypass 不可**で停止する（merge 直前コミットの CI green を保証）
- [ ] hard gate 充足後のみ `gh pr merge`（`merge_method` に従う）を実行する
- [ ] complete 判定が merge_approved + PR merged の両方を要する旨が明記され、導出規則は data-model §5.1 を参照（再定義しない）
- [ ] Step 4「Post-merge」が実装され、統合先 switch・merged branch 削除・journal 追記・tag/changelog opt-in を行う
- [ ] tag（version_tag 真）/ changelog（changelog 真）が opt-in で、opt-out でも正常完了する
- [ ] state.json schema 変更なし（`release.ready` / `release.merge_approved` のみ書き込み）
- [ ] Bash ツール安全規約（`$(...)` / backtick 不使用）を手順内コマンド例に適用
- [ ] SoT（docs/v3）を再定義していない / 既存 v3 テスト green（回帰ゼロ）/ SKILL.md 非変更

## 見積もり

1 日（Step 3 merge + Step 4 post-merge）
