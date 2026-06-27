# 論理設計: Unit 003 Merge 承認・実行 + Post-merge cleanup

## 概要

`steps/release.md` の **Step 3「Merge 承認 + 実行」** と **Step 4「Post-merge」** 実装（Unit 001 プレースホルダの差し替え）の構成・手順契約を定義する。

**重要**: コードは書かず、章構成・手順契約・依存スクリプト/コマンドの呼び出し契約のみを定義する。

## アーキテクチャパターン

- **手順ドキュメント + `gh`/git 直接 + 安全境界スクリプト委譲**（Unit 001/002 と同系統）。原子書込は `state-write.sh`、PR/merge/CI は `gh`、branch/tag は git。
- **二層ゲート**: approval gate（承認判断 / ユーザー確認可）と hard gate（CI・PR identity / bypass 不可）を分離。
- **fail-closed**: PR 再検証・review サマリ欠損・hard gate 未充足は停止。
- **SoT 非再定義**: merge_approved 記録タイミング（`workflow.md §3.3`）・complete 判定（`data-model.md §5.1`）・journal（§7）は参照のみ。

## コンポーネント構成

### ドキュメント構成（差分）

```text
steps/release.md（既存 / Step 3・4 を実装に差し替え + 冒頭注記更新）
├── Step 3: Merge 承認 + 実行 ★ merge 承認
│   ├── 3-0 PR 再検証（fail-closed: OPEN + head/base 一致）
│   ├── 3-1 PR ready 化 + release.ready 書込 + 検証
│   ├── 3-2 approval gate（manual=確認 / semi_auto=merge_blocker_any=false 自動 / 欠損は fail-closed ユーザー確認）
│   ├── 3-3 release.merge_approved 書込（merge 前）+ commit + push
│   ├── 3-4 hard gate（PR OPEN + head/base + headRefOid 一致 + 最終 head の CI success / bypass 不可）
│   ├── 3-5 merge 実行（gh pr merge --<merge_method>）
│   └── 3-6 complete 判定注記（merge_approved ∧ PR merged / data-model §5.1 参照）
└── Step 4: Post-merge
    ├── 4-1 統合先へ switch + merged feature branch 削除
    ├── 4-2 journal.md に release 完了追記
    └── 4-3 tag（version_tag 真）/ changelog（changelog 真）opt-in（opt-out でも正常完了）
```

### コンポーネント詳細

#### Step 3-2 approval gate（ApprovalGateService）

- **責務**: review サマリ `merge_blocker_any` + automation_mode から承認判断
- **依存**: release.md の固定マーカー純 YAML（`<!-- aidlc-release-review:start/end -->` 間を parse）/ automation_mode
- **挙動**: manual=ユーザー確認 / semi_auto=`merge_blocker_any==false` で自動 / マーカー不在・parse 不能・欠落・非 boolean は `AskUserQuestion`（fail-closed）

#### Step 3-4 hard gate（HardGateService）

- **責務**: CI・PR identity の健全性確認（bypass 不可）
- **依存**: `gh pr view <N> --json state,headRefName,baseRefName,headRefOid` / `gh`（CI conclusion / `gh run` 系）
- **挙動**: PR OPEN + head/base 一致 + `headRefOid`==push した head + その head の CI conclusion==success のみ passed。未充足は停止（ユーザー確認でも bypass 不可）

## インターフェース設計

### Step 3 手順契約（評価順 / 二層ゲート）

| 順 | 処理 | 入力 | continue | stop |
|----|------|------|----------|------|
| 3-0 | PR 再検証 | `state-read.sh release.pr_number` / `gh pr view <N> --json state,headRefName,baseRefName,headRefOid` | pr_number 整数 + PR OPEN + head/base 一致 | exit 1/2 / CLOSED/MERGED / head・base 不一致 / 取得不能 → fail-closed 停止 |
| 3-1 | ready 化 + ready 書込 | `gh pr ready <N>` → `state-write.sh release.ready true` → `state-validate.sh` | exit 0 + valid | state-write exit 1/2 → 停止 |
| 3-2 | approval gate | release.md review サマリ純 YAML `merge_blocker_any` / automation_mode | manual=ユーザー承認 / semi_auto=false で auto | 欠損・parse 不能・非 boolean → fail-closed ユーザー確認（停止せず確認） |
| 3-3 | merge_approved 書込 + push | `state-write.sh release.merge_approved true` → commit → **PR head branch（feature branch）の remote へ push**（base へ直 push しない / merge ゲート迂回防止） | exit 0 + push 成功 | exit 1/2 / push 失敗 → 停止 |
| 3-4 | hard gate（bypass 不可） | `gh pr checks <N> --required`（**必須**: count>0 & 全 pass）+ `gh pr view <N> --json state,headRefName,baseRefName,headRefOid,mergeStateStatus,statusCheckRollup`（補強: CLEAN & SUCCESS） | PR OPEN + head/base 一致 + headRefOid==push head + **headRefOid 同一 SHA の required check が count>0 かつ全 pass**。充足時 headRefOid を `<final_head_sha>` 保持 | CI failure/未完了/pending/取得不能 / required 0 件（無検証 merge 防止）/ identity 不一致 / MERGED → 停止（bypass 不可） |
| 3-5 | merge 実行 | `gh pr merge <N> --<merge_method> --match-head-commit <final_head_sha>` | merge 成功 | `--match-head-commit` 不一致（hard gate 後 head 進行 = TOCTOU）→ 停止し 3-3 再アンカーへ / その他失敗 → 停止 |

> **approval gate と hard gate の責務分離**: approval gate（3-2）はユーザー確認で解決し得る承認判断のみ。hard gate（3-4）は CI/PR 健全性で **ユーザー確認でも bypass 不可**。

> **CI 確認の SHA 固定（設計レビュー #2）**: hard gate の CI 判定は PR `headRefOid` と**同一 SHA の `statusCheckRollup`**（必要 check すべて success）で行う。`gh run list --branch` のような SHA 非固定参照は別 commit の run / 一部 workflow だけを success 誤認するため使わない。

> **再開経路（merge_approved 既存 true / 設計レビュー #1 / R2）**: Step 3 開始時に `state-read.sh release.merge_approved` が true の場合、承認 commit（`merge_approved:true` を保持する `.aidlc/state.json` の最新 commit / `git log` で特定）と PR `headRefOid` を比較する:
> - **一致（承認後に新規 commit なし）** → 3-1〜3-3 を再実行せず 3-4（hard gate）へ直行。`updated_at` だけの再 push を避け CI 再 stale ループを防ぐ。
> - **不一致（承認後に追加 commit が入った = stale approval）** → `merge_approved` を **false に戻さず**（監査記録を保持）、approval gate（3-2）から再評価し 3-3 で `merge_approved`（true→true / `updated_at` 更新）を**新しい head に再アンカー**してから hard gate へ。新 head に対する承認 commit を安定特定できる。

### Step 4 手順契約

| 順 | 処理 | 入力 | 備考 |
|----|------|------|------|
| 4-1 | 統合先同期 + branch 削除 | git fetch <remote> / git switch <integration-branch> / git pull --ff-only / git branch -d <feature> | remote の merge commit を取り込んでから（ff できないなら停止）merged 確認後に削除。tag/changelog はこの同期済み統合先に対して実行。本リポジトリ git 運用規約（カレントディレクトリ実行）に整合 |
| 4-2 | journal 追記 + commit/push | `.aidlc/cycles/<cycle>/journal.md` | `## YYYY-MM-DD` 配下に `- release completed: ...`（data-model §7）。統合先で commit + push（保護ブランチ時は follow-up PR / 未コミット残留しない） |
| 4-3 | tag / changelog opt-in | config `version_tag` / `changelog` | tag は **merge commit SHA**（`gh pr view --json mergeCommit`）を明示指定して作成（HEAD=bookkeeping commit を避ける）し tag のみ明示 push。changelog は journal と同じ commit/push 方針。偽は skip して正常完了。直接 push でゲート迂回しない |

### 依存スクリプト契約（既存 / read-only でない書込含む）

#### state-write.sh release.ready / release.merge_approved（既存）
- **引数**: `release.ready true` / `release.merge_approved true`（boolean）/ **exit**: 0=`status:written` / 1=値型不正・書込後 invalid・未知 schema_version 拒否 / 2=jq 不在・依存不備
- **利用**: 3-1（ready）/ 3-3（merge_approved）。書込後 `state-validate.sh` で `status:valid` 確認

## スクリプトインターフェース設計

本 Unit では**新規スクリプトを作成しない**（`gh`/git 直接 + 既存 state-write 委譲 / Unit 境界）。

## データモデル概要

- 書込: `release.ready` / `release.merge_approved` のみ（schema 不変）。`pr_number` は Unit 002。
- complete 判定: `merge_approved` ∧ PR merged（`data-model.md §5.1` 評価順 1 / 参照のみ）。

## 処理フロー概要

### Step 3「Merge 承認 + 実行」処理フロー

1. PR 再検証（3-0）→ stale は停止。**`release.merge_approved` 既存 true なら再開経路**（承認 commit = merge_approved:true を保持する最新 state.json commit と PR head 比較 → 一致は 3-1〜3-3 を再実行せず 5 の hard gate へ直行 / 不一致は stale approval → 3-2 から再評価し 3-3 で新 head に再アンカー、false に戻さない）
2. ready 化 + `release.ready` 書込 + 検証（3-1）
3. approval gate（3-2）: semi_auto は `merge_blocker_any==false` で auto / 欠損は fail-closed ユーザー確認
4. `release.merge_approved` を merge 前に書込 + commit + push（3-3）
5. hard gate（3-4 / bypass 不可）: PR OPEN + head/base + headRefOid 一致 + 最終 head（同一 SHA）の statusCheckRollup success
6. merge 実行（3-5）→ Step 4 へ

**関与するコンポーネント**: MergeExecution / ApprovalGateService / HardGateService / 既存 state-write.sh・gh・git

### Step 4「Post-merge」処理フロー

1. 統合先へ switch + merged feature branch 削除（4-1）
2. journal.md に release 完了追記（4-2）
3. tag/changelog opt-in（4-3 / opt-out でも正常完了）

## 非機能要件（NFR）への対応

### 監査性
- `release.merge_approved` を merge 前に記録（3-3）。merge 後にブランチが消えても承認記録が state.json に残る

### 安全性
- merge は approval gate ∧ hard gate 通過後のみ（3-5）。hard gate は bypass 不可。push を伴うため remote 同期・未コミット確認を含める

### 互換性
- state.json schema 不変（`release.ready`/`release.merge_approved` のみ）。既存 v3 テスト green 維持（新規テストは Unit 004）

### クロスプラットフォーム
- `gh`/git の POSIX 互換手順。BSD/GNU 差オプション回避

## 実装上の注意事項
- **境界**: PR 作成・release.md 作成・review は Unit 002。schema 追加なし。SKILL.md 非変更（公開フリップは Unit 004）
- **ドッグフーディング特殊処理の禁止**: 自リポジトリ判定を埋め込まない（branch 操作も汎用表現）
- **Bash ツール安全規約**: 手順内コマンド例に `$(...)` / backtick を含めない
- **CI green は merge 直前の最終 head に対して確認**（push 後 / stale CI 排除）

## 不明点と質問（設計中に記録）

[Question] CI 確認を push の前後どちらに置くか。
[Answer] push の後（hard gate 3-4）。merge_approved commit/push で head が変わるため、最終 head（merge_approved を含む）の CI を `headRefOid` 一致と併せて確認する（計画レビュー #1）。

[Question] hard gate と approval gate の違いは。
[Answer] approval gate（3-2）は承認判断でユーザー確認可。hard gate（3-4）は CI/PR identity で bypass 不可（計画レビュー #2）。

[Question] Step 3 開始時の PR 再検証は必要か。
[Answer] 必要。Unit 002 後に PR が変化（close/merge/head/base 変更）し得るため 3-0 で再検証し stale は fail-closed 停止（計画レビュー #3）。

[Question] hard gate 停止後の再実行はどう設計するか（stale approval の再承認含む）。
[Answer] 承認 commit = `merge_approved:true` を保持する最新 state.json commit。PR head と一致なら 3-1〜3-3 を再実行せず hard gate へ（updated_at ループ防止）。不一致（承認後に追加 commit）なら stale approval として 3-2 から再評価し 3-3 で新 head に再アンカー（`merge_approved` を false に戻さず監査記録を保持 / 設計レビュー #1 / R2）。

[Question] hard gate の CI はどの SHA に対して確認するか。
[Answer] PR `headRefOid` と同一 SHA の `statusCheckRollup`（必要 check すべて success）。`gh run list --branch` 等の SHA 非固定参照は使わない（別 commit / 一部 workflow の誤認防止 / 設計レビュー #2）。
