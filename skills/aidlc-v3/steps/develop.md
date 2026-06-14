# develop フロー（実行手順 / tiny）

> **位置づけ（v3.0.0-alpha.3 / Phase 3）**: 本ファイルは develop フローの**実行手順**である。
> AI エージェントは各 Step を順に実行し、work item の status 遷移・実装・検証・work item 単位
> commit・`journal.md` 追記を実際に行う。frontmatter status の読取／遷移のような atomic 性・
> パース安全性が必要な処理は `scripts/work-item-status.sh` を経由する（RFC P4）。
>
> **本 Unit（003）の対象は `size: tiny` のみ**。`normal` / `risky` の design / risk analysis /
> review ルーティングは Phase 4 の責務であり、本フローでは未サポート案内で停止する（副作用なし）。

## 目的

次の work item を 1 件選び、安全に完了させる（1 実行 = 1 work item）。tiny は design / review を
スキップして実装・検証・完了まで進める（size × review マトリクスは `docs/v3/workflow.md` §6.2 が正本）。

## フロー全体

develop tiny は Step 1 / 3 / 4 / 6 を実行する。Step 2（設計）と Step 5（レビュー）は tiny ではスキップする。

| Step | 内容 | tiny での扱い |
|------|------|--------------|
| 1 Work Item 選定 | 次 item 選定 + size 判定 + status 読取 + in_progress 化 | 実行 |
| 2 計画 + 設計 | design / risk analysis | **スキップ（tiny）** |
| 3 実装 | acceptance criteria に沿って実装 | 実行 |
| 4 検証 | acceptance criteria チェック | 実行 |
| 5 レビュー | code / security review | **スキップ（tiny）** |
| 6 完了 | status done + journal 追記 + work item 単位 commit + 次アクション案内 | 実行 |

## パス解決

`scripts/` は SKILL.md と同じスキルベースディレクトリからの相対パス（例: `scripts/work-item-next.sh`、
`scripts/work-item-status.sh`、`scripts/state-read.sh`）。cycle 成果物はリポジトリの `.aidlc/` 配下
（`state.json` はリポジトリ直下 `.aidlc/state.json`、cycle 成果物は `.aidlc/cycles/<cycle>/`）。
データモデル・フェーズ導出の正本は `docs/v3/data-model.md`。

## Step 0: 前提確認（clean-worktree + cycle 解決）

Step 1 以降に進む前に必ず実行する。

1. **clean-worktree 確認**: git のワーキングツリーが clean かを確認する（`git status --porcelain` が空 /
   define.md Step 1 と同じ）。dirty の場合はコミット / stash をユーザーに促してから進む。develop は
   Step 6 で work item 単位に `git add -A` するため、事前の未コミット差分が混入しないよう本チェックを必須とする。

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

## Step 1: Work Item 選定 + 現在 status 読取

1. 次 work item を選定する（依存解決 + resume 優先 / Unit 002 / Step 0 で解決した `<cycle>` を使用）:

   ```bash
   scripts/work-item-next.sh ".aidlc/cycles/<cycle>/work-items"
   ```

   - 出力 `next:none`（選定可能 item なし / exit 0）→ 「完了後のフェーズ導出」に従い案内して**終了**（frontmatter / journal / commit を一切変更しない）。`next:none` を release 可能の根拠に**しない**。
   - 出力 `next:<id>:<size>:<path>` → 次の 2 に進む。
   - exit 1（入力エラー: ディレクトリ不在 / work item 0 件）/ exit 2（システムエラー）→ エラーを提示して**終了**（mutation なし）。

2. **size を判定する**（出力 `<size>` を使用 / frontmatter 再パース不要）:

   - `size != tiny`（`normal` / `risky`）→ 以下を案内して**終了**。frontmatter / journal / commit を一切変更しない（副作用なし）。選定経路が resume（in_progress）でも fresh（pending）でも同様に停止する:

     ```text
     選定された work item <id> は size: <size> です。
     normal / risky フローは未サポートです（Phase 4 で対応予定）。
     develop tiny フロー（本 Unit）では tiny のみ実装します。
     ```

   - `size == tiny` → 次の 3 に進む。

3. **現在 status を読取る**（`work-item-next.sh` 出力に status は含まれないため別途読取 / パースは安全境界スクリプトに集約）:

   ```bash
   scripts/work-item-status.sh --read "<path>"
   ```

   - exit 1 / exit 2（status 行 0 or 複数 / malformed / enum 不正 / 読取不可）→ エラーを提示して**終了**（mutation なし＝副作用なし）。
   - 出力 `status:<value>` で経路を分岐:
     - `status:pending`（fresh / 新規着手）→ in_progress 化する:

       ```bash
       scripts/work-item-status.sh "<path>" pending in_progress
       ```

       `status:written`（exit 0）で次 Step へ。exit 非 0 はエラー提示して終了。
     - `status:in_progress`（resume / 中断再開）→ status を遷移せず継続する（既に in_progress / 二重遷移しない）。次 Step へ。
     - それ以外（理論上 `work-item-next.sh` は pending / in_progress のみ返すが、防御的に）→ 想定外として案内して**終了**（mutation なし）。

## Step 2: 計画 + 設計（tiny はスキップ）

tiny は design / risk analysis を行わない（`docs/v3/workflow.md` §6.2）。本 Step は実行しない。

## Step 3: 実装

1. 対象 work item の本文（Goal / Scope / Acceptance Criteria）を読み、acceptance criteria を満たす実装を行う。
2. 実装変更はこの時点で staging してよいが、**最終 commit は Step 6 で 1 つに集約する**（後述）。

## Step 4: 検証

1. work item の Acceptance Criteria（本文 `## Acceptance Criteria` のチェックリスト）と Traceability の
   Verification（test command / manual check）に従って検証する。
2. lint / test / ビルドが該当する変更であれば実行し、パスを確認する。
3. 検証が通らない場合は Step 3 に戻って修正する（tiny のため軽量 / 解決困難なら work item を `blocked` 等に
   する判断は本フロー外 = 中断してユーザーに相談）。

## Step 6: 完了

1. status を done に遷移する:

   ```bash
   scripts/work-item-status.sh "<path>" in_progress done
   ```

   `status:written`（exit 0）を確認する。

2. `journal.md` に完了を追記する（`docs/v3/data-model.md` §7 / `## YYYY-MM-DD` 見出し配下に箇条書き）:

   ```text
   - develop completed: <id>-<slug>
   ```

   当日の日付見出しが無ければ追加する。

3. **work item 単位で最終 commit を 1 つに集約する**（計画 D4）。実装変更 + 検証後の `status: done` +
   journal 追記をまとめて 1 commit にする。Step 3 で中間 commit を作っている場合は `git commit --amend`
   または squash で最終 commit 単体に集約し、追加 commit を残さない。`git add -A` は Step 0 で
   clean-worktree を確認済みである前提に成立する（事前の未コミット差分が無いため、ステージされる差分は
   本 work item の実装・状態遷移・journal に限定される）:

   ```bash
   git add -A
   git commit -m "develop: <id>-<slug> <要約>"
   ```

   > ブランチ判定等の自リポジトリ特殊処理は本フローに埋め込まない（define.md と同様 / リポジトリ規約
   > 「ドッグフーディング特殊処理を本体に埋めない」）。

4. 「完了後のフェーズ導出」に従い次アクションを案内する。

## 完了後のフェーズ導出

フェーズは `state.json` + 全 work item frontmatter status から導出する（`current_phase` は保持しない /
正本は `docs/v3/data-model.md` §5.1 評価順 first-match）。`scripts/state-read.sh` で
`define_completed` / `release.*` を読み、全 `work-items/*.md` の status を走査して判定する:

- `define_completed: true` かつ done / withdrawn 以外の work item が残る（評価順 3）→ **develop 継続**。
  次の着手候補があれば `/aidlc-v3 develop` を案内する。
- `define_completed: true` かつ全 work item が done / withdrawn（評価順 4）→ **release 可能**。
  `/aidlc-v3 release` を案内する。

> **`next:none` を release の根拠にしない**: `next:none` は「選定可能 item なし」を意味するのみで、
> blocked 相当（withdrawn 依存 / 未充足依存）の pending が残る状態でも発生する（§5.2 別レイヤ）。
> release 可能判定は必ず全 work item frontmatter status の走査で行う。blocked が残る場合は
> develop 継続（依存解決待ち）を案内する。
>
> **state.json は develop tiny では変更しない**: develop tiny フローは work item frontmatter（status）と
> journal.md のみを変更し、`state.json`（define / release 状態）には書き込まない。
