# release フロー（実行手順 / 骨格 + Step 1）

> **位置づけ（v3.0.0-alpha.6 / Phase 5）**: 本ファイルは release フローの**実行手順**である。
> AI エージェントは各 Step を順に実行し、リリース準備の確認・PR 整備・merge・post-merge 処理を実際に行う。
> `state.json` 操作や frontmatter status の読取のような atomic 性・パース安全性が必要な処理は
> `scripts/state-*.sh` / `scripts/work-item-*.sh` を経由する（RFC P4）。
>
> **本 Unit（001）の対象**: release フローの骨格（Step 1–4 の章立て・ゲート(★)・成果物・スクリプト契約の書式）と
> **Step 1「リリース準備」を実装**する。**Step 2–4 は骨格（プレースホルダ）のみ**であり、PR 整備（Unit 002）/
> merge 承認・実行・post-merge（Unit 003）/ `SKILL.md` の `release` コマンド公開フリップ・express 整合（Unit 004）は
> 後続 Unit で実装する。Step 1 は **read-only**（aidlc 管理状態 = `state.json` / work item frontmatter / journal /
> commit を変更しない）である。

## 目的

全 work item の完了を確認し、main に安全に取り込む（旧 Operations）。

## フロー全体

release は 4 Step で構成される。承認ゲート（★）は Step 2（PR ready 確認）と Step 3（merge 承認）にある。

| Step | 内容 | ゲート / 成果物 |
|------|------|--------------|
| 1 リリース準備 | 全 work item 完了確認（done / withdrawn のみ許容）/ git status / test・CI 状態確認 | -（停止パターンあり / read-only） |
| 2 PR 整備 | PR 作成（既存時は更新）/ `release.pr_number` 記録 / `release.md` 作成 / release-level review ルーティング | ★ PR ready 確認 / PR・`release.md` |
| 3 Merge 承認 + 実行 | PR ready 化 / `release.ready` 記録 / CI パス確認 / `release.merge_approved` を merge 前に記録 / merge 実行 | ★ merge 承認（manual/semi_auto）/ `state.json` |
| 4 Post-merge | 統合先 branch へ switch / merge 済み feature branch 削除 / tag・changelog（opt-in）/ `journal.md` に release 完了追記 | tag・changelog（任意）・`journal.md` |

> フェーズ導出（develop → release → complete）の正本は `docs/v3/data-model.md` §5.1。release-level review perspective
> （premerge / integration / deploy）の正本は `docs/v3/workflow.md` §3.3 / §6。本ファイルはこれらを参照し再定義しない。

## パス解決

`scripts/` は SKILL.md と同じスキルベースディレクトリからの相対パス（例: `scripts/state-read.sh`、
`scripts/work-item-validate.sh`、`scripts/work-item-status.sh`）。cycle 成果物はリポジトリの `.aidlc/` 配下
（`state.json` はリポジトリ直下 `.aidlc/state.json`、cycle 成果物は `.aidlc/cycles/<cycle>/`）。
データモデル・フェーズ導出の正本は `docs/v3/data-model.md`、フェーズ Step 詳細の正本は `docs/v3/workflow.md` §3.3。

## Step 0: 前提確認（clean-worktree + cycle 解決）

Step 1 以降に進む前に必ず実行する（develop.md Step 0 と同じ）。

1. **clean-worktree 確認（前提 / 早期注意）**: git のワーキングツリーが clean かを確認する。dirty なら
   early advisory としてコミット / stash を促す。**リリース準備としての正式な fail-closed 停止判定は Step 1-3
   （および test 後の 1-5）で行う**ため、停止順を 1-3 に一本化し、本確認は前提の早期注意に留める:

   ```bash
   git status --porcelain
   ```

2. **current_cycle 解決**: 永続化された active cycle は `state.json` のみが保持する。`<cycle>` プレースホルダを
   推測・手動置換せず、`state-read.sh` で `current_cycle` を解決して以降の `.aidlc/cycles/<cycle>/...` パスに使う:

   ```bash
   scripts/state-read.sh current_cycle
   ```

   - exit 0 + 値出力 → その値を `<cycle>` として Step 1 以降で使用する。
   - exit 1（`state.json` 不在 / `current_cycle` 欠落 = active cycle なし）→ 「先に `/aidlc-v3 define` を実行してください」と案内して**終了**（mutation なし）。
   - exit 2（jq 不在 / 読取不可）→ エラーを提示して**終了**。

## Step 1: リリース準備（read-only / 停止パターンあり）

全 work item の完了・state 前提・worktree・test/CI を確認し、release を続けてよいかを判定する。**本 Step は read-only**
であり、`state.json` / work item frontmatter / `journal.md` / commit を変更しない（いずれの停止でも副作用を残さない）。
評価は下記 1-1 → 1-5 の順で行い、**停止条件が 1 つでも成立した時点で release を中断**する（fail-closed / 最初の停止を提示）。

### 1-1. state 前提確認（define 完了）

`state-read.sh` で define 完了を確認する:

```bash
scripts/state-read.sh define_completed
```

- exit 0 + `true` → 1-2 へ進む。
- exit 0 + `false` → 「define が未完了です。`/aidlc-v3 develop` で work item を完了してから release してください」と案内して**終了**。
- exit 0 + `true` / `false` 以外の値 → **fail-closed**。`state-read.sh` は schema 妥当性を検証しないため、`state.json` の破損で boolean 以外が返り得る。「`state.json` が不正です（`define_completed` が boolean ではありません）。修正してから release してください」と案内して**終了**。schema を厳密に確認する場合は Step 1 冒頭で `scripts/state-validate.sh` を実行し `status:valid` 以外（exit 1 / 2）を停止に倒してもよい。
- exit 1（`state.json` 不在 / キー欠落）→ 「active cycle がありません。先に `/aidlc-v3 define` を実行してください」と案内して**終了**（Step 0 で解決済みでも防御的に扱う）。
- exit 2（jq 不在 / 読取不可）→ システムエラーとして提示して**終了**。

### 1-2. 全 work item 完了確認（done / withdrawn）

`done` / `withdrawn` のみを完了扱いとする（`pending` / `in_progress` / `blocked` は未完了 / `docs/v3/data-model.md` §5.1 評価順 4）。

1. **schema preflight**: work item frontmatter が schema 健全かを read-only で確認する（status 集計の前提）:

   ```bash
   scripts/work-item-validate.sh ".aidlc/cycles/<cycle>/work-items"
   ```

   - exit 0（`status:valid`）→ 次の status 集計へ進む。
   - exit 1（schema 違反 / work item 0 件 / ディレクトリ不在）→ 検証エラーを提示して**終了**（validation stop）。
   - exit 2（読み取り不可 等）→ システムエラーとして提示して**終了**。

2. **status 集計**: work item を列挙し、各ファイルの status を `work-item-status.sh --read` で読み取る
   （frontmatter の生パース = grep/sed/awk は本ファイルで行わず、安全境界スクリプトに委譲する / develop.md Step 1 と同じ）:

   ```bash
   ls .aidlc/cycles/<cycle>/work-items/*.md
   ```

   列挙した各 `<path>` について:

   ```bash
   scripts/work-item-status.sh --read "<path>"
   ```

   - exit 0 → 出力 `status:<value>` の `<value>` を集計する。`done` / `withdrawn` 以外（`pending` / `in_progress` / `blocked`）は未完了として記録する。
   - exit 1 / exit 2（status 行 0 or 複数 / malformed / enum 不正 / 読取不可）→ エラーを提示して**終了**。

3. **判定**: 未完了 work item が 1 件でもあれば、未完了の id と status を一覧提示して**終了**（mutation なし）。例:

   ```text
   Release blocked: 未完了の work item が残っています。
   - 002-normalize-state: in_progress
   - 004-review-merge: pending

   すべての work item を done または withdrawn に解決してから release してください。
   blocked の work item は done か withdrawn に解決してください（依存解除 / 取り下げの判断は develop で行う）。
   /aidlc-v3 status で現在地を確認できます。
   ```

   全 work item が `done` / `withdrawn` → 1-3 へ進む。

### 1-3. git status 確認（事前）

ワーキングツリーが clean かを確認する（Step 0 を通過済みでも、リリース準備としての明示確認 / `docs/v3/workflow.md` §3.3）:

```bash
git status --porcelain
```

- 空（clean）→ 1-4 へ進む。
- 非空（dirty）→ 「未コミットの変更があります。コミット / stash してから release してください」と案内して**終了**。

### 1-4. test 状態確認

リリース対象**プロジェクトで定義されたテスト**を実行し、結果を確認する（v3 フレームワーク自身のテストではなく、
リリースしようとしているプロジェクトのテスト入口を指す。プロジェクト種別による分岐は本ファイルに埋め込まない）:

- プロジェクトのテスト入口をその場で実行する。
- exit 0 → 1-5 へ進む。
- non-zero（テスト失敗）→ 「テストが失敗しています。修正してから release してください」と案内して**終了**。

> テスト入口が存在しないプロジェクトでは、テストなしである旨をユーザーに確認の上で 1-5 へ進む（停止しない）。

### 1-5. worktree 再評価（test 後）+ CI 状態確認

1. **worktree 再評価**: テスト実行はキャッシュ・生成物で worktree を dirty にし得るため、再度確認する:

   ```bash
   git status --porcelain
   ```

   - 空（clean）→ CI 確認へ進む。
   - 非空（test 生成物等で dirty）→ 生成物を `.gitignore` 等で除外するか commit/stash するよう案内して**終了**（`read-only` は「aidlc 管理状態を変更しない」意味であり、test 生成物の混入はここで検出する）。

2. **CI 状態確認**: `gh` が利用可能な場合のみ、対象ブランチ/コミットの最新 CI の conclusion を参照する（`gh run list` 系）:

   - `success` → リリース準備 OK。Step 2（PR 整備 / 後続 Unit）へ進む。
   - `failure` → 「CI が失敗しています。修正してから release してください」と案内して**終了**。
   - `pending` / 未実行 / 取得不能 / `gh` 不在 / CI 未設定 → 警告を表示して**継続**（停止しない / 可用性のため）:

     ```text
     Warning: CI 状態を確認できません（pending / 未実行 / gh 不在 等）。
     CI を確認のうえ release を続行してください。
     ```

   > **CI の warn-continue が fail-closed の例外である理由**: Step 1 の CI 確認は事前の状態把握であり、`gh` 不在・
   > CI 未設定環境でも release を不当にブロックしないため（可用性 NFR）。**CI パスの強制は Step 3（Merge 承認 + 実行）の
   > 必須ゲート**（`docs/v3/workflow.md` §3.3 Step 3「CI パス確認」）で行うため、Step 1 では `failure` のみ停止し、
   > `pending` / 取得不能等は警告継続とする。未確認 CI のまま merge されることは Step 3 のゲートが防ぐ。

3. すべて充足（または CI が警告継続）→ **Step 2 へ進む**。

> **本 Unit のスコープ境界**: Step 1 が完了して Step 2 に進める状態でも、Step 2 以降は未実装（後続 Unit）である。
> 本 Unit では Step 1 の判定までを実装し、Step 2 の手順は下記プレースホルダに留める。

## Step 2: PR 整備 ★ PR ready 確認（Unit 002 で実装）

> **プレースホルダ（未実装 / Unit 002）**。PR 未作成なら作成・既存（`early_pr: true`）なら本文更新、`release.pr_number` の
> `state-write.sh` 書き込み、`templates/release.md` からの `release.md` 生成、release-level review（premerge 常時 /
> integration 複数完了時 / deploy risky 時）の perspective ルーティングを担う。ゲートは「PR ready 確認」（ready 化操作は
> Step 3）。詳細は `docs/v3/workflow.md` §3.3（Step 2）/ §6、`docs/v3/data-model.md` §3・§8 を参照。

## Step 3: Merge 承認 + 実行 ★ merge 承認（Unit 003 で実装）

> **プレースホルダ（未実装 / Unit 003）**。PR ready 化 + `release.ready` 書き込み、CI パス確認、`release.merge_approved`
> を **merge 前の最終コミット**で書き込み（commit + push）、`gh pr merge`（`merge_method` に従う）を担う。merge 承認ゲートは
> `manual`=明示確認 / `semi_auto`=承認前提充足で自動。`complete` 判定は `merge_approved` + PR 実態（merged）の両方を要する
> （導出規則は `docs/v3/data-model.md` §5.1 を参照 / 再定義しない）。

## Step 4: Post-merge（Unit 003 で実装）

> **プレースホルダ（未実装 / Unit 003）**。統合先ブランチへ switch・merge 済み feature branch 削除、`journal.md` に release
> 完了追記、tag（`version_tag` 真）/ changelog（`changelog` 真）の opt-in 実行を担う（opt-out でも正常完了）。

## 完了後のフェーズ導出

フェーズは `state.json` + PR 実態から導出する（`current_phase` は保持しない / 正本は `docs/v3/data-model.md` §5.1）。
merge 完了後、`release.merge_approved: true` かつ PR が merged 状態なら `complete`（reflect 可能）が導出される
（評価順 1）。`/aidlc-v3 status` で現在地を確認できる。
