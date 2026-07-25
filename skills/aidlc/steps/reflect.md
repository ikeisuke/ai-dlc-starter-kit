# reflect フロー（実行手順）

> **位置づけ（v3.0.0-alpha.7 / Phase 6）**: 本ファイルは reflect フローの**実行手順**である。
> AI エージェントは各 Step を順に実行し、サイクルの振り返り（KPT 抽出 → 改善 Issue 化 → `reflect.md` 記録 →
> `journal.md` 追記）を行う。
>
> **state 非変更 / 承認ゲートなし**: reflect は **`state.json` を一切変更しない**（`state-write.sh` を呼ばない /
> read + 成果物生成のみ）。明示の承認ゲートは持たず、**Step 2 で人間が KPT を編集**し、**Step 3 で Try の Issue 化を
> 人間が確認**する（この 2 点が人間関与点）。
>
> **任意実行 / 前提**: reflect は任意実行であり、`complete` 状態（`release.merge_approved: true` かつ PR merged）の
> サイクルでのみ実行する（前提確認は Step 0 / 正本 `docs/v3/data-model.md` §5.1）。
>
> **frontmatter 安全境界**: work item status の読取は `scripts/work-item-status.sh --read` を経由する（frontmatter の
> 生パース = grep/sed/awk を本ファイルで行わない / RFC P4）。

## 目的

サイクルの振り返りを行い、改善を次の行動（Issue）に変える（旧 Retrospective）。正本: `docs/v3/workflow.md` §3.4。

## フロー全体

reflect は 5 Step（Step 0 前提確認 + Step 1–4）で構成される。**承認ゲート（★）は持たない**（Step 2 人間編集 /
Step 3 Issue 化確認が人間関与点）。

| Step | 内容 | 成果物 / 関与点 |
|------|------|----------------|
| 0 前提確認 | cycle 解決 + `complete` 前提確認（`release.merge_approved` / PR merged） | -（read-only / 停止パターンあり） |
| 1 材料収集 | `journal.md` / `release.md` / work item の `withdrawn`・`blocked` を読み込む | -（read-only） |
| 2 KPT 抽出 | AI が Keep / Problem / Try を提案 → 人間が確認・編集 | `reflect.md`（Keep / Problem / Try 章） |
| 3 行動化 | Try を Issue 化するか確認（承認しない→作らない / 一部→必要分） | 改善 Issue（任意）+ `reflect.md`（Issue リンク章） |
| 4 完了 | `journal.md` に reflect 完了を追記 | `journal.md` 追記 |

> フェーズ導出（`complete`（reflect 可能））の正本は `docs/v3/data-model.md` §5.1。reflect の成果物保存先
> （`reflect.md` 必須 / Issue 任意）の正本は `docs/v3/data-model.md` §10。本ファイルはこれらを参照し再定義しない。

## パス解決

`scripts/` / `templates/` は SKILL.md と同じスキルベースディレクトリからの相対パス（例: `scripts/state-read.sh`、
`scripts/work-item-status.sh`、`templates/reflect.md`）。cycle 成果物はリポジトリの `.aidlc/` 配下（`state.json` は
リポジトリ直下 `.aidlc/state.json`、cycle 成果物は `.aidlc/cycles/<cycle>/`）。データモデル・フェーズ導出の正本は
`docs/v3/data-model.md`、reflect Step 詳細の正本は `docs/v3/workflow.md` §3.4。

## core から外す（実装しない）

`docs/v3/workflow.md` §3.4 末尾「core から外す（廃止）」の **4 項目は reflect core で実装しない**:

- upstream mirror（starter kit 固有）
- cap 管理
- dialog token
- aggregate retrospective issue（集約振り返り Issue）

加えて、本 Unit 境界として **推定値検出ガード等の重い振り返り補助ロジックも実装しない**（§3.4 の 4 項目とは別根拠 /
core を手順ベースに保つため）。

## Step 0: 前提確認（cycle 解決 + complete 前提）

Step 1 以降に進む前に必ず実行する。

1. **current_cycle 解決**: `<cycle>` プレースホルダを推測・手動置換せず、`state-read.sh` で解決する:

   ```bash
   scripts/state-read.sh current_cycle
   ```

   - exit 0 + 値出力 → その値を `<cycle>` として Step 1 以降で使用する。
   - exit 1（`state.json` 不在 / `current_cycle` 欠落 = active cycle なし）→ 「先に `/aidlc define` を実行してください」と案内して**終了**。
   - exit 2（jq 不在 / 読取不可）→ エラーを提示して**終了**。

2. **`complete` 前提確認**（reflect は complete 状態でのみ実行可 / `docs/v3/data-model.md` §5.1）:

   ```bash
   scripts/state-read.sh release.merge_approved
   scripts/state-read.sh release.pr_number
   ```

   - `release.merge_approved` が `true` かつ `release.pr_number` が整数 → PR merged 実態を確認する:

     ```bash
     gh pr view <release.pr_number> --json state,mergedAt   # state == MERGED ∧ mergedAt != null を確認
     ```

     - `state == MERGED` かつ `mergedAt != null` → `complete`。Step 1 へ進む。
     - `MERGED` でない / 取得不能 → 「このサイクルはまだ完了（merge 済み）していません。先に `/aidlc release` を完了してください」と案内して**終了**。
   - `release.merge_approved` が `true` でない / `release.pr_number` 欠落 → 「reflect は release 完了後に実行します。`/aidlc status` で現在地を確認してください」と案内して**終了**（mutation なし）。
   - **gh 不可用時の扱い（complete 判定）**: PR merged 確認に必要な `gh` が利用できない場合は、complete を自動判定できないため **skip せず停止**し、ユーザーに「PR #<release.pr_number> が merged 済みか手動確認のうえ reflect を続行してください」と**明示の手動確認**を求める（complete 判定は SoT 必須前提のため、Issue 化の skip-continue とは区別する）。

## Step 1: 材料収集（read-only）

振り返りの材料を 3 ソースから読み込む（いずれも read-only）。

1. **`journal.md`**: `.aidlc/cycles/<cycle>/journal.md` の当該サイクル作業証跡を読む（不在時は空として継続）。
2. **`release.md`**: `.aidlc/cycles/<cycle>/release.md`（release 結果 / review サマリ）を読む。**`complete` 前提下で
   `release.md` は必須成果物（`docs/v3/data-model.md` §10）**のため、**不在は不整合として停止**し、ユーザーに release
   成果物の欠落を提示する（空扱いで先に進めない）。
3. **未完了 work item の `withdrawn` / `blocked`**: work item を列挙し status を安全境界スクリプトで読む:

   ```bash
   ls .aidlc/cycles/<cycle>/work-items/*.md
   ```

   列挙した各 `<path>` について:

   ```bash
   scripts/work-item-status.sh --read "<path>"
   ```

   - 出力 `status:<value>` のうち `withdrawn` / `blocked` を振り返り対象として収集する。
   - **理由（reason）の扱い**: frontmatter に `withdrawn`/`blocked` の理由専用キーは存在しない（`docs/v3/data-model.md`
     §4）。理由は work item 本文（Implementation Notes 等）/ `journal.md` / `release.md` から **非構造データとして抽出**し、
     見つからなければ `unknown` と記録する（data-model に新キーを追加しない）。

## Step 2: KPT 抽出（AI 提案 → 人間編集）

Step 1 の材料から AI が **Keep / Problem / Try** を提案し、**人間が確認・編集**する。

- `templates/reflect.md` を起点に `.aidlc/cycles/<cycle>/reflect.md` を生成する（テンプレート不在 → 「`templates/reflect.md`
  が見つかりません」と案内して**終了**）。
- Keep（続けてよかったこと）/ Problem（課題）/ Try（次に試すこと）を各章に記録する。Try は Step 3 で Issue 化候補になる。

## Step 3: 行動化（Try の Issue 化 / 人間確認）

各 Try について Issue 化するかを**人間に確認**し、確定分のみ Issue 化する。

### 3-0. gh 可用性判定（`gh_status`）

Step 3 冒頭で `gh` の可用性を判定し、以降の分岐に使う:

```bash
command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1
```

- 両方成功（exit 0）→ `gh_status = available`（3-1 で Issue 起票可能）。
- いずれか失敗 → `gh_status = unavailable`（Issue 化を skip し `PENDING_MANUAL` 記録へ）。

### 3-1. Try の Issue 化分岐

- **承認しない場合** → Issue を作らない（`reflect.md` の記録は継続）。
- **一部のみ承認** → 承認された Try のみ Issue 化する（必要な Issue だけ作成）。
- **Issue 起票**（`gh_status == available` 時）: 下記「機密情報マスク」を適用したうえで
  `gh issue create --body-file <一時ファイル>`（file-based）。標準出力の `https://github.com/.../issues/<N>` URL から
  **Issue 番号 / URL を確定**し、`reflect.md` の「Issue リンク」章に記録する。
  - **必須ラベル検証は行わない**（reflect Issue の必須ラベルは SoT / Unit 定義に未定義のため、未定義ラベル前提の検証を
    導入しない）。
- **gh 不可用時（Issue 化）**: `gh_status != available` の場合は **Issue 化を skip（停止ではない）** し、`reflect.md` の
  記録は継続する。Issue 化できなかった Try は「Issue リンク」章に `PENDING_MANUAL` として記録する（後で手動起票）。

### 3-2. 機密情報マスク（Issue body 作成前 / 必須）

`journal.md` / `release.md` / work item 本文から抽出した内容を外部公開 Issue に出すため、body-file 作成前に以下を適用する
（review-flow のマスク方針 + 本リポジトリ「外部公開コンテンツでのローカルパス取扱い」規約を準用）:

- raw ログ・スタックトレースをそのまま貼らない（要約する）。
- token / API key / `Authorization` ヘッダ / 秘密鍵 / 接続文字列内の認証情報を redact（例: `sk-****`、`Bearer ****`）。
- ホーム配下絶対パス（`/Users/<name>/...` / `/home/<name>/...` / `C:\Users\<name>\...`）・内部 host 名を repo-relative
  path / `~/...` / `<placeholder>` に置換する。
- **body-file 作成後に簡易チェック**（例: `grep -nE '/Users/|/home/[^/]+/|sk-|Bearer |PRIVATE KEY' <body-file>`）を行い、
  ヒットした場合は起票せず停止して内容を見直す。

> complete 判定（Step 0）の gh 不可用は停止/手動確認だが、Issue 化（任意成果物）の gh 不可用は skip-continue である点に
> 注意（前提の必須性が異なる）。

## Step 4: 完了（journal.md 追記）

`.aidlc/cycles/<cycle>/journal.md` の当日見出し（`## YYYY-MM-DD`）配下に追記する（`docs/v3/data-model.md` §7）:

```text
- reflect completed: <cycle>
```

当日の日付見出しが無ければ追加する。**reflect は `state.json` を変更しない**ため、`state-write.sh` は呼ばない。

## 完了後のフェーズ導出

reflect は任意実行であり `complete` 状態を変更しない（`state.json` を書き換えない）。reflect 完了後もフェーズは
`complete` のままで、その成果物 `reflect.md` は次サイクルの `define` 入力となる（trace chain /
`docs/v3/data-model.md` §10・`docs/v3/workflow.md` §3.4）。`/aidlc status` で現在地を確認できる。
