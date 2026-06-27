# release フロー（実行手順）

> **位置づけ（v3.0.0-alpha.6 / Phase 5）**: 本ファイルは release フローの**実行手順**である。
> AI エージェントは各 Step を順に実行し、リリース準備の確認・PR 整備・merge・post-merge 処理を実際に行う。
> `state.json` 操作や frontmatter status の読取のような atomic 性・パース安全性が必要な処理は
> `scripts/state-*.sh` / `scripts/work-item-*.sh` を経由する（RFC P4）。
>
> **実装範囲**: Step 1「リリース準備」（read-only）/ Step 2「PR 整備」/ Step 3「Merge 承認 + 実行」/ Step 4「Post-merge」を
> 実装済みで、`SKILL.md` の `release` コマンドが本フローを指す。state 書き込みは Step 2 が `release.pr_number`、Step 3 が
> `release.ready` / `release.merge_approved` のみ（schema 不変 / 既存 `state-write.sh` を利用）。

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

   - `success` → リリース準備 OK。Step 2（PR 整備）へ進む。
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

## Step 2: PR 整備 ★ PR ready 確認

Step 1 を通過したら、PR を整備し `release.md` 成果物と release-level review を用意する。**state 書き込みは `release.pr_number`
のみ**（schema 不変 / `release.ready`・`release.merge_approved` の書き込みは Step 3）。ready 化操作そのものは Step 3 で行い、
本 Step のゲートは「PR ready 確認」に留める。手順は 2-0 → 2-5 の順で実行する。

### 2-0. gh 可用性確認（停止条件）

PR・`release.pr_number` は release の必須成果物であり Step 3（merge）の入力でもあるため、`gh` が使えない場合は**停止**する
（warn-continue にしない）:

- `gh_status == available` → 2-1 へ進む。
- `gh_status != available` → 「`gh` が利用できないため PR を整備できません。`gh auth status` を確認してください」と案内して**終了**。
  - 例外: ユーザーが既存 PR 番号を手動提示した場合に限り、`gh pr view <N> --json state,isDraft,headRefName,baseRefName` で **`state == OPEN` かつ `headRefName` が現在のブランチと一致かつ `baseRefName` が統合先ブランチ `<integration-branch>` と一致**（2-1 と同じ fail-closed 条件）を確認できた場合のみ `release.pr_number` を書き込んで（2-2）続行してよい。`CLOSED`/`MERGED`・別 head ブランチ・別 base ブランチ・取得不能は停止。PR 番号が未確定のまま Step 2 を完了してはならない。

### 2-1. PR 解決（fail-closed / 重複作成防止）

`release.pr_number` と同一 head branch の open PR から、PR を一意に解決する:

```bash
scripts/state-read.sh release.pr_number
```

- exit 1（`release.pr_number` 欠落 / `state.json` 不正 / JSON parse 不能）/ exit 2（jq 不在・読取不可）→ **fail-closed で停止**（state 不整合のまま PR 作成 / adopt に進まない）。
- exit 0 + **整数値**（PR 番号記録済み）→ その PR を `gh pr view` で検証する:

  ```bash
  gh pr view <N> --json state,isDraft,headRefName,baseRefName
  ```

  - `state == OPEN`（draft PR も gh では `state=OPEN` / `isDraft=true` なので含まれる）かつ `headRefName` が現在のブランチと一致かつ `baseRefName` が統合先ブランチ `<integration-branch>` と一致 → **update**（2-2 はスキップし 2-3 へ。PR 本文更新は 2-4 で release.md 生成後に行う）。
  - `state` が `CLOSED` / `MERGED`、`headRefName` 不一致（別 head ブランチ）、`baseRefName` 不一致（別 base への PR）、または取得不能 → **停止**（stale な番号・別ブランチ PR・別 base PR・closed/merged PR の誤採用を防ぐ）。ユーザーに番号の見直しを促す。
- exit 0 + **`null`**（未記録）→ 同一 head branch の open PR を探索する:

  ```bash
  gh pr list --head <current-branch> --base <integration-branch> --state open --json number
  ```

  - open PR が **1 件** → その番号を採用（**adopt**）。`gh pr view <number> --json state,headRefName,baseRefName` で `state == OPEN` かつ `headRefName` 一致かつ `baseRefName == <integration-branch>` を確認（`--base` フィルタの二重確認）したうえで、2-2 で `release.pr_number` に書き込み、2-3 へ。
  - open PR が **0 件** → **create**。`gh pr create --draft --base <integration-branch> --title "[Release] <cycle>" --body-file <一時ファイル>` で作成する。`gh pr create` の標準出力は PR **URL**（番号そのものではない）ため、作成後に `gh pr view --json number,state,headRefName,baseRefName` で**番号を再取得**し、`state == OPEN` かつ `headRefName` 一致かつ `baseRefName == <integration-branch>` を確認したうえで、その `number` を 2-2 で `release.pr_number` に書き込む。
  - open PR が **複数** → **fail-closed で停止**（どの PR を対象にするかをユーザーが解決）。

> `early_pr: true`（define 時に Draft PR を作成済み）の場合も、上記「値あり→検証」または「null→adopt」の経路で番号を確定し、**重複 PR を作らない**。

### 2-2. release.pr_number 書き込み（create / adopt 時）

PR を新規作成した場合、または adopt で番号を確定した場合のみ、`release.pr_number` を書き込み検証する（update 経路はスキップ）:

```bash
scripts/state-write.sh release.pr_number <N>
```

- exit 0（`status:written`）→ `scripts/state-validate.sh` で `status:valid` を確認し 2-3 へ。
- exit 1（値型不正 / 書込後 invalid / 未知 schema_version 拒否）→ 検証エラーを提示して**終了**。
- exit 2（jq 不在 / 依存不備）→ システムエラーとして提示して**終了**。

### 2-3. release-level review ルーティング

work item の完了状況に応じて release-level review を実行する。**集計の安全境界**: `status` は `work-item-status.sh --read`
で読み（`status:done` のみカウント、`withdrawn` は数えない）、deploy 条件用の `size` は Step 1-2 の `work-item-validate.sh` が
exit 0（schema 健全 = `size` enum を検証済み）を返した検証済み frontmatter から参照する。`work-item-validate.sh` が
exit 1/2（schema 不正・読取不可）の場合は集計せず**停止**（fail-closed / release.md 本体で `size` を生パースしない）。
perspective→caller_context→skill の写像は以下（正本: `docs/v3/workflow.md` §6 /
`aidlc` スキルの `review-routing.md` §3（CallerContext マッピング）。本ファイルは再定義せず参照）:

| perspective | 実行条件 | caller_context | skill_name | focus |
|-------------|---------|----------------|-----------|-------|
| premerge | 常時 | PR マージ前 | `reviewing-operations-premerge` | code, security |
| integration | `status:done` の work item が 2 件以上 | 統合とレビュー | `reviewing-construction-integration` | code |
| deploy | `size:risky` かつ `status:done` の work item が 1 件以上 | デプロイ計画承認前 | `reviewing-operations-deploy` | architecture |

- 反復・指摘対応・機密マスク・パス選択は `aidlc` スキルの `review-flow.md` / `review-routing.md` に委譲する。
  `review-routing.md` には `routing_review_mode = [rules.reviewing].mode`（config 値）を渡し、**perspective 名を `review_mode`
  引数に渡さない**（混同回避 / review-flow.md §5.0）。
- 各 perspective の結果（`status` / `unresolved_count` / `max_severity` / `merge_blocker` / `skip_reason`）を正規化し、2-4 の
  release.md 生成で review 結果サマリ（純 YAML）に埋め込む。条件未該当の perspective は `status: skipped` + `skip_reason` を記録する。
- review 結果は **release.md に集約**し、`reviews/*.md` は生成しない（`docs/v3/data-model.md` §8 / §10）。

### 2-4. release.md 成果物の生成

`templates/release.md` を起点に `.aidlc/cycles/<cycle>/release.md` を生成する（review を確定してから生成し placeholder 残留を防ぐ）:

- テンプレート不在 → 「`templates/release.md` が見つかりません」と案内して**終了**。
- セクションを埋める: PR 概要 / work item 完了一覧（done・withdrawn）/ **review 結果サマリ（固定マーカー純 YAML / 2-3 の結果）** /
  CI 状態 / merge 記録（Step 3/4 で追記する枠）。
- review 結果サマリは `<!-- aidlc-release-review:start -->` と `<!-- aidlc-release-review:end -->` のマーカー間に**純 YAML のみ**を
  配置する（Step 3 がそのまま parse する入力契約。マーカー間にコードフェンス・見出し等を置かない）。
- PR 本文は file-based（`gh pr edit <N> --body-file <一時ファイル>` / 2-1 で update/adopt/create のいずれでも本文を更新）。機密情報を含めない。
- **release.md を PR に含める**: 生成した `.aidlc/cycles/<cycle>/release.md` を **PR の head branch（feature branch）に commit + push** する。`release.md` は release の必須成果物（`docs/v3/data-model.md` §10）であり、PR に含めることで merge により統合先へ取り込まれる。base/統合先へ直接 push しない。

### 2-5. Step 2 ゲート（PR ready 確認）

PR が ready 化可能な状態（必須情報が揃い、CI 状態が把握済み）であることを確認する。**ready 化操作（`gh pr ready` /
`release.ready` 書き込み）は Step 3 で行う**ため、本 Step では ready 確認に留めて Step 3 へ進む。

## Step 3: Merge 承認 + 実行 ★ merge 承認

PR を ready 化し、承認ゲートと健全性ゲートを経て merge する。**state 書き込みは `release.ready` / `release.merge_approved`
のみ**（schema 不変）。本 Step は **2 種類のゲートを分離**する: **approval gate**（3-2 / 承認判断 / ユーザー確認で解決し得る）と
**hard gate**（3-4 / CI・PR identity / **ユーザー確認でも bypass 不可**）。手順は 3-0 → 3-5 の順で実行する。

### 3-0. PR 再検証 + 再開判定（fail-closed）

Step 2 完了後に PR が変化している可能性があるため、再検証する:

1. `scripts/state-read.sh release.pr_number`（exit 1/2 は fail-closed 停止）→ PR 番号 `<N>` を得る。
2. `gh pr view <N> --json state,headRefName,baseRefName,headRefOid` で `state == OPEN` かつ `headRefName == 現在のブランチ`
   かつ `baseRefName == 統合先ブランチ` を確認。`CLOSED`/`MERGED`・head/base 不一致・取得不能は **fail-closed 停止**。
3. **再開判定**: `scripts/state-read.sh release.merge_approved` が `true` の場合（中断後の再開）:
   - 承認 commit（`release.merge_approved: true` を保持する `.aidlc/state.json` の最新 commit / `git log` で特定）が PR `headRefOid` と
     **一致** → 承認後に新規 commit なし。**3-1〜3-3 を再実行せず 3-4（hard gate）へ直行**（`updated_at` だけの再 push を避け CI 再 stale ループを防ぐ）。
   - **不一致**（承認後に追加 commit が入った = stale approval）→ `release.merge_approved` を **false に戻さず**、3-2（approval gate）から
     再評価して 3-3 で **新しい head に再アンカー**する（監査記録を保持しつつ新 head に承認 commit を作る）。
   - `false` → 通常どおり 3-1 へ。

### 3-1. PR ready 化 + release.ready 書き込み

```bash
gh pr ready <N>
scripts/state-write.sh release.ready true
```

- `state-write.sh` exit 0（`status:written`）→ `scripts/state-validate.sh` で `status:valid` を確認し 3-2 へ。
- exit 1（値型不正 / 書込後 invalid / 未知 schema_version 拒否）/ exit 2（jq 不在・依存不備）→ 提示して**終了**。

### 3-2. approval gate（承認判断 / ユーザー確認で解決し得る）

「高重要度未解決指摘なし」の承認判断を行う（CI/PR 健全性は 3-4 の hard gate が担う）。Step 2 が `release.md` に記録した
review 結果サマリ（固定マーカー間の純 YAML）を parse し、`merge_blocker_any` を読む:

- `automation_mode == manual` → ユーザーに明示確認（承認を得てから 3-3）。
- `automation_mode == semi_auto` かつ `merge_blocker_any == false` → 自動承認 → 3-3。
- review サマリのマーカー不在・YAML parse 不能・`merge_blocker_any` 欠落/非 boolean → **fail-closed**。自動承認せず
  `AskUserQuestion` でユーザー確認（高重要度未解決の有無を人手で判断）。

### 3-3. release.merge_approved 記録（merge 前）+ commit + push

承認後、**merge 前の最終コミット**で承認を記録する（merge 後にブランチが消えても承認記録が残る = 監査性）:

```bash
scripts/state-write.sh release.merge_approved true
```

- exit 0 → `state-validate.sh` で `status:valid` 確認後、`release.md` の「Merge 記録」セクションの `merge_approved` 行も合わせて更新し、**state.json + release.md の変更を 1 つの commit** にまとめて、**現在のブランチ（PR の head branch = feature branch）の remote へ push** する。base/統合先ブランチへ直接 push しない（PR の merge ゲートを迂回しないため）。これにより必須成果物 `release.md`（`docs/v3/data-model.md` §10）と承認記録が PR に含まれ、merge により統合先へ取り込まれる。
- exit 1/2 → 提示して**終了**。
- push に失敗（remote 同期不可 / 未コミット差分）→ 解消を促して**終了**。

### 3-4. hard gate（CI・PR identity / **ユーザー確認でも bypass 不可**）

push 後の **最終 head（`merge_approved` を含む）** に対して健全性を確認する。**CI は merge 直前の最終コミットに対して見る**
（3-3 の push で head が変わるため、承認前の CI 結果は使わない）:

```bash
gh pr view <N> --json state,headRefName,baseRefName,headRefOid,statusCheckRollup
```

以下を**すべて**満たす場合のみ 3-5 へ:

1. PR `state == OPEN`（既に `MERGED` は停止）かつ `headRefName == 現在のブランチ`・`baseRefName == 統合先`。
2. `headRefOid` が 3-3 で push した最終コミットと一致。
3. **`headRefOid` と同一 SHA の required（必要）check が 1 件以上存在し、すべて成功**であること。SHA 非固定参照（`gh run list --branch`
   等）は使わない。判定は次を**両方**行う:
   - `gh pr checks <N> --required`（**必須確認**）で required check を列挙し、**count > 0 かつ全件 pass** を確認する。required が
     0 件（必須 CI 未設定）・pending・取得不能は **fail-closed で停止**（無検証 merge を防ぐ / `mergeStateStatus=CLEAN` だけでは required 0 件を検出できないため）。
   - 補強として `gh pr view <N> --json mergeStateStatus,statusCheckRollup` で `mergeStateStatus == CLEAN`（`BLOCKED`/`UNSTABLE`/`BEHIND`/`DIRTY` は不可）かつ `statusCheckRollup` 各 entry が `SUCCESS` を確認する。

いずれか未充足（CI `FAILURE`/未完了/pending/取得不能 / required 0 件 / PR identity 不一致 / PR が `MERGED`）→ **停止**（ユーザー確認でも bypass 不可）。

充足時、確認した `headRefOid` を **`<final_head_sha>`** として保持し、3-5 の merge に渡す（TOCTOU 防止）。

### 3-5. merge 実行

hard gate 充足後のみ merge する。**3-4 で確定した `<final_head_sha>` に対して merge する**（hard gate 確認から merge 実行までの
間に PR head が進む TOCTOU を防ぐ）。`merge_method` 設定に従う（`merge` / `squash` / `rebase`）:

```bash
gh pr merge <N> --<merge_method> --match-head-commit <final_head_sha>
```

- merge 成功 → Step 4 へ。
- `--match-head-commit` 不一致で失敗（hard gate 後に head が進んだ）→ **停止**。3-3 の再アンカー（新 head で `merge_approved` を記録）→ 3-4 hard gate からやり直す。
- その他の merge 失敗 → 提示して**終了**。

### 3-6. complete 判定の注記

`release.merge_approved: true` **単独では complete としない**。complete は `merge_approved` ∧ PR が merged 実態の**両方**で
導出される（`docs/v3/data-model.md` §5.1 評価順 1 / 本ファイルは導出規則を再定義せず参照）。`/aidlc-v3 status` で確認できる。

## Step 4: Post-merge

merge 完了後の後片付けを行う。tag / changelog は opt-in であり、**opt-out（設定が偽）でも正常完了**する。

> **Step 4 の commit/push 方針**: `journal.md` / changelog は merge 後の bookkeeping（コードではない記録）であり、4-1 で同期した
> **統合先ブランチに commit + push** する。変更を未コミットのまま残さない。**統合先が保護ブランチで直接 push が拒否される場合は、
> follow-up PR で反映する**（直接 push でゲートを迂回しない）。tag は merge commit を対象に作成し、tag のみを明示的に push する。

### 4-1. 統合先の同期 + merged feature branch 削除

remote の merge commit を取り込んでから後片付けする（stale な統合先での branch 削除失敗・tag/changelog を防ぐ）:

```bash
git fetch <remote>
git switch <integration-branch>
git pull --ff-only
gh pr view <N> --json state,mergedAt   # state=MERGED ∧ mergedAt != null を確認
# merge_method に応じて feature branch を削除:
#   merge           → git branch -d <feature-branch>   （merge commit が feature tip を親に持ち ancestry 成立 / 安全削除）
#   squash / rebase → git branch -D <feature-branch>   （上の gh pr view で merged 実態を確認済みを前提に force 削除）
```

- `git pull --ff-only` で統合先が PR の merge commit を含むことを確認する（ff できない = 統合先が未取込/分岐なら停止し remote 状態を確認）。
- **feature branch 削除は merge_method で分岐する**: `merge`（merge commit 方式）では feature branch tip が統合先の ancestor になるため `git branch -d`（未 merge を拒否する安全削除）で削除できる。一方 `squash` / `rebase`（Step 3-5 で許容）では統合先に作られるコミットが feature branch tip を親に持たず ancestor 関係が成立しないため `-d` は「未 merge」と判定して**必ず削除を拒否する**。この場合は上の `gh pr view` で **PR が merged 実態（state=MERGED ∧ mergedAt != null）であることを確認したうえで** `git branch -D`（force 削除）を使う。**merged 実態が確認できない場合は force 削除せず停止**して remote / PR 状態を確認する。
- 本リポジトリの git 運用規約（カレントディレクトリ実行）に整合させる。ブランチ判定等の自リポジトリ特殊処理は埋め込まない。
- 後続の tag / changelog（4-3）は、この同期済みの統合先に対して行う。

### 4-2. journal.md に release 完了追記

`.aidlc/cycles/<cycle>/journal.md` の当日見出し（`## YYYY-MM-DD`）配下に追記する（`docs/v3/data-model.md` §7）:

```text
- release completed: <cycle> (PR #<N> merged)
```

当日の日付見出しが無ければ追加する。あわせて、統合先に取り込まれた `release.md` の「Merge 記録」セクションの `merged` 行を更新する。追記後、`journal.md`（および `release.md`）を統合先ブランチで commit + push する（上記「Step 4 の commit/push 方針」に従う / 保護ブランチ時は follow-up PR）。

### 4-3. tag / changelog の opt-in 実行

設定（`.aidlc/config.toml` の `[rules.release]`）に従う:

- `version_tag == true` → **merge commit の SHA `<merge_commit_sha>`**（`gh pr view <N> --json mergeCommit` 等で取得 / 4-1 で同期した統合先の PR merge commit）を対象に tag を作成し、tag のみを明示 push する（例: `git tag <cycle> <merge_commit_sha>` → `git push <remote> <cycle>`）。HEAD（4-2 で作る journal/changelog の bookkeeping commit）ではなく **merge commit** を指すようにする。`false` → skip。
- `changelog == true` → changelog を追記し、`journal.md` と同じ commit/push 方針（統合先 commit + push / 保護時は follow-up PR）で反映する。`false` → skip。
- いずれが偽でも release は**正常完了**とする（opt-out は失敗ではない）。

## 完了後のフェーズ導出

フェーズは `state.json` + PR 実態から導出する（`current_phase` は保持しない / 正本は `docs/v3/data-model.md` §5.1）。
merge 完了後、`release.merge_approved: true` かつ PR が merged 状態なら `complete`（reflect 可能）が導出される
（評価順 1）。`/aidlc-v3 status` で現在地を確認できる。
