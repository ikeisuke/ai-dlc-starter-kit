# define フロー（実行手順）

> **位置づけ（v3.0.0-alpha.3 / Phase 3）**: 本ファイルは define フローの**実行手順**である。
> AI エージェントは各 Step を順に実行し、cycle ディレクトリ作成・成果物生成・`state.json`
> 初期化・`journal.md` 追記・git branch / commit を実際に行う。`state.json` 操作のような
> atomic 性が必要な処理のみ `scripts/state-*.sh` を経由する（RFC P4）。
>
> develop / release / reflect フローおよび `early_pr: true` 時の Draft PR 整備詳細は
> 後続 Phase の責務（本フローは通常パス = PR を作らないを実装する）。

## 目的

作るもの・作らないもの・完了条件・作業単位（work item）を決め、cycle を初期化する（旧 Inception）。

## フロー全体

define は 4 Step で構成される。承認ゲート（★）は Step 2（Intent 承認）と
Step 3（Work Item 承認）にある。Step 4 は決定的な初期化処理であり、検証ゲートを含む。

| Step | 内容 | ゲート / 成果物 |
|------|------|--------------|
| 1 環境チェック | 前提確認 | - |
| 2 Intent 定義 | 目的・スコープ・完了条件 | ★ Intent 承認 / `intent.md` |
| 3 Work Item 分割 | 作業単位への分割 | ★ Work Item 承認 / `work-items/*.md` |
| 4 初期化 | state / cycle / branch 初期化 | `state.json`・`journal.md`・branch |

## パス解決

`scripts/` / `templates/` は SKILL.md と同じスキルベースディレクトリからの相対パス
（例: `scripts/state-init.sh`、`templates/work-item.md`）。cycle 成果物は
リポジトリの `.aidlc/` 配下（`state.json` はリポジトリ直下 `.aidlc/state.json`、
cycle 成果物は `.aidlc/cycles/<cycle>/`）。データモデルの正本は `docs/v3/data-model.md`。

## Step 1: 環境チェック

1. `.aidlc/config.toml` の存在を確認する（不在ならセットアップを案内して中断）。
2. git のワーキングツリーが clean かを確認する（`git status --porcelain` が空）。dirty の場合は
   コミット / stash をユーザーに促してから進む。
3. 前サイクルの `journal.md` / `reflect.md` が存在すれば読み込み、define の入力とする。

## Step 2: Intent 定義 ★ Intent 承認

1. 対象サイクル識別子（`current_cycle`）を確定する。形式は `vX.Y.Z` 系（例 `v3.0.0` /
   `v3.0.0-alpha.3`）。**許容文字集合は `^[A-Za-z0-9][A-Za-z0-9._-]*$`**（`/`・空白・制御文字を
   含まない / cycle ディレクトリ名・ブランチ suffix の同一キーになるため）。
2. 目的を **1 文**で確認する（AI が提案し、人間が承認する）。
3. スコープを「含むもの」「含まないもの」で整理する。
4. 受け入れ基準（acceptance criteria）を定義する。
5. テンプレート `templates/intent.md` を基に、cycle・目的・スコープ・受け入れ基準・制約を埋めて
   `intent.md` の内容を確定する（Step 4 で `.aidlc/cycles/<cycle>/intent.md` に配置）。
6. **★ 承認ゲート**: Intent を人間が承認するまで次 Step に進まない。

## Step 3: Work Item 分割 ★ Work Item 承認

1. Intent を work item に分割する（AI が提案し、人間が承認する）。
2. 各 work item に以下を付与する（`docs/v3/data-model.md` §4 が正本）:
   - `id`（3 桁ゼロ埋め推奨 / 例 `"001"`）
   - `size`（`tiny` / `normal` / `risky`）
   - `risk`（`low` / `medium` / `high`）
   - `status`（**初期値は必ず `pending`**）
   - `assigned`（未割当は `null`）
   - `dependencies`（依存する work item ID のリスト / **実在する ID のみ** / 空配列可）
3. テンプレート `templates/work-item.md` を基に、frontmatter（必須 6 キー）と本文の必須 6 セクション
   （Goal / Scope / Acceptance Criteria / Traceability / Size / Risk / Dependencies）を埋めて
   各 work item の内容を確定する（Step 4 で `.aidlc/cycles/<cycle>/work-items/<id>-<slug>.md` に配置）。
4. **★ 承認ゲート**: Work Item 分割を人間が承認するまで次 Step に進まない。

## Step 4: 初期化（決定的 / 検証ゲートを含む）

承認済みの Intent / Work Item を成果物として永続化し、cycle と state を初期化する。
以下を順に実行する。

### 4-1. cycle ディレクトリと成果物の作成

1. cycle ディレクトリを作成する（**v3 フラット構造** / v2 の inception/construction/operations
   サブディレクトリは持たない）:

   ```bash
   mkdir -p ".aidlc/cycles/<cycle>/work-items"
   ```

2. 承認済み Intent を `.aidlc/cycles/<cycle>/intent.md` に配置する。
3. 承認済み Work Item を `.aidlc/cycles/<cycle>/work-items/<id>-<slug>.md` に配置する
   （status 初期値 `pending`）。
4. テンプレート `templates/journal.md` を基に `.aidlc/cycles/<cycle>/journal.md` を作成し、
   日付見出し（`## YYYY-MM-DD`）配下に define 完了を追記する
   （例: `- define completed: intent and N work items created`）。

### 4-2. work item 完了前検証ゲート【define 完了の前提条件】

`state.json` の `define_completed` を `true` にする**前に**、`scripts/work-item-validate.sh`
で全 `work-items/*.md` が `docs/v3/data-model.md` §4 に準拠することを検証する。
`expected_status` に `pending` を渡し、define 初期値（全 work item が `pending`）も併せて検証する:

```bash
scripts/work-item-validate.sh ".aidlc/cycles/<cycle>/work-items" pending
```

- 成功時 stdout: `status:valid` / 終了コード 0。
- バリデーション違反（後述）・work item 0 件・ディレクトリ不在は exit 1。
- ディレクトリ読み取り不可等は exit 2。

スクリプトが検証する項目（`docs/v3/data-model.md` §4 / §6 が正本）:

1. frontmatter 必須 6 キー（`id` / `status` / `size` / `risk` / `assigned` / `dependencies`）が存在する。
2. enum 値域に従う（`status ∈ {pending,in_progress,blocked,done,withdrawn}` /
   `size ∈ {tiny,normal,risky}` / `risk ∈ {low,medium,high}`）。
3. `status` の初期値が `pending` である（`expected_status pending` 指定時）。
4. `assigned` の型が `string or null` である（配列・マップ・空値は違反）。
5. `dependencies` の型が `array`（`[...]` 形式）である（非配列・壊れた配列は違反）。
6. `id` とファイル名（`<id>-<slug>.md` の `<id>` 部）が整合する。
7. 本文に必須 6 セクション（Goal / Scope / Acceptance Criteria / Traceability /
   Size / Risk / Dependencies）が存在する。
8. `dependencies` が**実在する work item ID のみ**を参照する（存在しない ID 参照は
   `docs/v3/data-model.md` §6 の trace 整合エラー）。

**exit 0 以外（検証失敗）の場合は 4-3（`state-init.sh`）・4-4（`state-write.sh define_completed true`）を
実行せず、define を未完了に留める**（`define_completed` は `false` のまま）。失敗内容を提示し、
該当 work item を修正してから再実行する。

### 4-3. 初期 state.json の生成

`scripts/state-init.sh` で `.aidlc/state.json` を atomic に生成する（`define_completed: false`
の skeleton を create-only で生成 / 既存があれば exit 1）:

```bash
scripts/state-init.sh "<cycle>"
```

- 成功時 stdout: `status:initialized` / 終了コード 0。
- `current_cycle` が許容文字集合外 / 既存 state.json がある場合は exit 1。
- jq 未導入・依存不備等は exit 2。

**state.json 初期化済み環境での resume 経路**: `.aidlc/state.json` が既に存在し、その
`current_cycle` が Step 2 で確定した cycle と一致し、かつ `define_completed` が `false` の
場合（例: v2→v3 migration が state.json を初期化済みの環境）、本 4-3 を skip して 4-4 に
進む（`scripts/state-read.sh current_cycle` / `scripts/state-read.sh define_completed` で
確認する）。`current_cycle` が不一致の場合は両方の値を提示して**停止**する（上書きしない /
ユーザーが state.json か cycle 識別子のどちらかを見直してから再実行する）。

### 4-4. define 完了マーク（single-actor moment）

4-2 の検証ゲートを全 work item が通過した場合のみ、`scripts/state-write.sh` で
`define_completed` を `true` にする（`docs/v3/data-model.md` §3.3 の書き込みタイミング）:

```bash
scripts/state-write.sh define_completed true
```

- `updated_at` は自動更新される。

### 4-5. branch 作成 + 初回 commit

1. cycle ブランチを作成する（consumer の通常フロー）:

   ```bash
   git checkout -b "cycle/<cycle>"
   ```

   > ドッグフーディング等で既に対象ブランチ上にいる場合はブランチ作成を skip する。
   > 本フローはブランチ運用の特殊処理を define.md 本体に埋め込まない（リポジトリ規約
   > 「ドッグフーディング特殊処理を本体に埋めない」）。

2. 成果物と state を初回 commit する:

   ```bash
   git add -A
   git commit -m "define: <cycle> 初期化（intent + N work items）"
   ```

3. `early_pr: true` の場合のみ Draft PR を作成する（**通常時は PR を作らず**、PR 整備は
   release フェーズで行う）。

## 完了後のフェーズ導出

`define_completed: true` 書き込み後、フェーズは `state.json` + work item frontmatter から
自動導出される（`current_phase` は保持しない）。導出規則の正本は `docs/v3/data-model.md` §5。
define 完了後、未完了 work item があれば `develop`、全 work item が `done` / `withdrawn` なら
`release 可能` が導出される（`/aidlc status` で確認 / status 実行実装は後続 Phase）。

> **state.json 書き込み・検証の参照**: 初期生成は `scripts/state-init.sh`（create-only / `ln`）、
> field 更新は `scripts/state-write.sh`（atomic-replace / `mv`）、schema 検証は
> `scripts/state-validate.sh`。初期生成と更新で原子化プリミティブが分岐する点に注意。
