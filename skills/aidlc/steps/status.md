# status 出力仕様（現在地表示）

> **位置づけ**: 本ファイルは status コマンドの**出力仕様 + 実行手順**である。
> AI エージェントは `state.json` + work item frontmatter を読み取り、フェーズを導出して現在地・次アクションを
> 表示する。**状態を変更しない（読み取り専用）**。status はスクリプトを持たず、本手順に従って出力を構成する。
>
> **コマンド表記**: 起動表面は `/aidlc`（v3.0.0-rc.1 で本流化済み）。出力例・Suggested command は
> `/aidlc` 表記を用いる。

## 責務

`state.json` + work item frontmatter を読み取り、フェーズを導出して**現在地・次アクション**を表示する。
**状態を変更しない（読み取り専用 / `state-write.sh` を呼ばない）**。

## パス解決

`scripts/` は SKILL.md と同じスキルベースディレクトリからの相対パス（例: `scripts/state-read.sh`、
`scripts/work-item-status.sh`、`scripts/lib/frontmatter.sh`）。診断対象はカレントリポジトリの `.aidlc/`
（`state.json` はリポジトリ直下 `.aidlc/state.json`、cycle 成果物は `.aidlc/cycles/<cycle>/`）。

## フェーズ導出

- フェーズ導出ロジックの**正本（SoT）は `docs/v3/data-model.md` §5**。本ファイルは導出**結果の表示仕様**を
  規定し、導出規則そのものを再定義しない。
- 導出は `state.json`（`define_completed` / `release.*`）と work item frontmatter（各 `status`）から行う。
  `current_phase` は状態として保持しない。

### complete 判定（重要）

`complete`（reflect 可能）の判定には、以下の**両方**が必要:

1. `state.json` の `release.merge_approved: true`（ブランチ上の承認記録）
2. PR が実際に **merged** 状態であること（PR 実態）

`merge_approved` 単独では `complete` としない。PR の merged 実態を確認できない場合は `complete` とせず、
release / 警告扱いとする。

> **非規範サマリ**（正本は data-model §5 / 評価順序・`complete` 最優先は §5.1）:
> `release.merge_approved: true` かつ PR merged → complete /
> `define_completed: false`（または state.json 不在）→ define /
> `define_completed: true` かつ未完了 work item あり → develop /
> `define_completed: true` かつ全 work item が done / withdrawn → release 可能。

## Step 0: 前提確認（state 健全性 / cycle 解決）

出力構成の前に以下を順に確認する。**state.json 不在のみ** を No active cycle とし、破損・未対応 schema・
読取失敗・不正 cycle は `state read error`（doctor 案内）に分離する。

1. **`.aidlc/state.json` 存在確認**:
   - **不在** → 以下を出力して終了（active cycle なし）:

     ```text
     No active cycle found.
     Suggested command: /aidlc define
     ```

2. **schema 検証**（`state-read.sh` は schema 妥当性を検証しないため `state-validate.sh` に委譲）:

   ```bash
   scripts/state-validate.sh .aidlc/state.json
   ```

   - stdout が `status:valid` → 次へ。
   - `status:warn:unsupported-schema-version:*`（未対応 schema / `data-model.md` §6 の復帰不可 WARN）/
     exit 1（破損 / schema 不正）/ exit 2（読取不能）→ **No active cycle にせず**、以下を出力して終了:

     ```text
     state read error
     Suggested command: /aidlc doctor
     ```

3. **cycle 解決 + 安全検証**:

   ```bash
   scripts/state-read.sh current_cycle .aidlc/state.json
   ```

   - `current_cycle` が **非空 string** かつ **`..` を含まず `^[A-Za-z0-9][A-Za-z0-9._-]*$` に一致**（doctor
     `[cycle]` 同基準 / パストラバーサル防止）かつ **`.aidlc/cycles/<cycle>` ディレクトリが存在** → active
     cycle status 構成へ（下記）。
   - 空 / 取得失敗 / 不正識別子 / cycle ディレクトリ不在 → **No active cycle にせず**、上記の `state read error`
     診断案内（`Suggested command: /aidlc doctor`）を出力して終了。

## 出力フォーマット（active cycle 時）

以下の 7 項目を**この順序**で表示する（`docs/v3/workflow.md` §3.5 の出力例とフィールド構造一致）。

| 項目 | 導出 |
|------|------|
| `Cycle` | `state-read.sh current_cycle` の値 |
| `Phase` | `data-model.md §5` の規則で導出（**再定義せず参照**）。導出根拠を併記（例: `define_completed=true, 2/4 items remaining`） |
| `Current work item` | 進行中 work item を `<id> (size: <size>, risk: <risk>, status: <status>)` で表示 |
| `Completed` | done / withdrawn の `<完了数>/<総数>` + 内訳（例: `001-example done, 003-cleanup withdrawn`） |
| `Blocked` | blocked 状態の work item（なければ `none`） |
| `Remaining` | 未完了（pending / in_progress / blocked）の work item id |
| `Suggested command` | 導出フェーズに対応する次コマンド（`/aidlc develop` / `/aidlc release` / `/aidlc reflect` 等） |

### work item フィールドの安全境界読取（重要 / RFC P4）

frontmatter を直接 grep/sed/awk でパースしない。安全境界スクリプト / 公開関数に委譲する:

- **status**: `scripts/work-item-status.sh --read <path>`。exit 0 の stdout は **`status:<value>`** 形式。
  表示（`Current work item` の `status: ...`）・集計（Completed / Blocked / Remaining）では **prefix `status:`
  を剥がした `<value>` のみ**を使用する（stdout 全体を使うと `status: status:in_progress` の不一致になる）。
- **size / risk**: `scripts/lib/frontmatter.sh` を source し、`fm="$(fm_extract_block <path>)"` で frontmatter
  ブロックを抽出（fail-closed: malformed は return 1）→ `fm_scalar "$fm" size '[A-Za-z_]'` /
  `fm_scalar "$fm" risk '[A-Za-z_]'` で値を取得する。専用 `fm_size` / `fm_risk` は実在しないため使わない。
  enum（`tiny|normal|risky` / `low|medium|high`）を表示前に検証する。

出力例:

```text
Cycle: v3.0.0
Phase: develop (derived: define_completed=true, 2/4 items remaining)
Current work item: 002-normalize-state (size: normal, risk: medium, status: in_progress)
Completed: 2/4 (001-example done, 003-cleanup withdrawn)
Blocked: none
Remaining: 002-normalize-state, 004-review-merge
Suggested command: /aidlc develop
```

## state.json 不在時（再掲）

```text
No active cycle found.
Suggested command: /aidlc define
```

## 境界

- フェーズ導出規則そのものは再定義しない（SoT: `docs/v3/data-model.md` §5）。status は導出結果の表示のみ。
- doctor の `[phase]` 導出 code 化は本仕様の対象外（v3.0.0-alpha.8 / #741）。
- status は状態を変更しない（読み取り専用 / `state-write.sh` を呼ばない）。
