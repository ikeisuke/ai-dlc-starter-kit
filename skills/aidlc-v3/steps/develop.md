# develop フロー（実行手順 / size×depth_level 分岐）

> **位置づけ（v3.0.0-alpha.5 / Phase 4）**: 本ファイルは develop フローの**実行手順**である。
> AI エージェントは各 Step を順に実行し、work item の status 遷移・実装・検証・work item 単位
> commit・`journal.md` 追記を実際に行う。frontmatter status の読取／遷移のような atomic 性・
> パース安全性が必要な処理は `scripts/work-item-status.sh` を経由する（RFC P4）。
>
> **Phase 4（本サイクル / Unit 001）の対象**: work item の `size`（tiny/normal/risky）と cycle の
> `depth_level`（minimal/standard/comprehensive）を解決し、`docs/v3/data-model.md` §8 マトリクスへ
> 写像して後続 Step の実行可否を決める分岐基盤を確立する。`normal + minimal`（実装 + テストのみ）は
> 本 Unit 単体で end-to-end 完走する。design 成果物の生成（Step 2）と review の実行（Step 5）は
> 後続 Unit 002 / 003 の責務であり、それらを要する組合せ（design_required / review_required = true）は
> 本 Unit の時点では「Unit 002 / 003 で実装予定」として副作用なしで停止する。

## 目的

次の work item を 1 件選び、安全に完了させる（1 実行 = 1 work item）。`size` と `depth_level` の
組合せ（`docs/v3/data-model.md` §8 が**唯一の正本**）に応じて design / review の要否を判定し、
不要な組合せは該当 Step をスキップして実装・検証・完了まで進める（size × review の正本は §8 と
`docs/v3/workflow.md` §6.2）。

## フロー全体

各 Step の実行可否は Step 1 で構築する判定結果（MatrixDecision）に従う。`design_required` /
`review_required` / `reason_record_required` のフィールドが後続 Step の分岐を一意に制御する。

| Step | 内容 | 実行可否 |
|------|------|---------|
| 1 Work Item 選定 + 判定 | 次 item 選定 + size enum 検証 + depth_level 解決 + §8 写像（MatrixDecision 構築）+ status 読取 + in_progress 化 | 常に実行 |
| 2 計画 + 設計 | design / risk analysis 生成 | `design_required` で分岐（生成本体は Unit 002） |
| 3 実装 | acceptance criteria に沿って実装 | 常に実行 |
| 4 検証 | acceptance criteria チェック | 常に実行 |
| 5 レビュー | code / security / design review | `review_required` で分岐（実行本体は Unit 003） |
| 6 完了 | status done + journal 追記 + 理由記録（条件付き）+ work item 単位 commit + 次アクション案内 | 常に実行 |

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

## Step 1: Work Item 選定 + size×depth_level 判定 + 現在 status 読取

判定（1〜4）はすべて **mutation を伴わない読み取り・解決のみ**。status 遷移（5）は判定が
正常完了（エラー停止しない）した場合にのみ行う。これによりエラー停止系（`risky_minimal` /
`invalid_size` / `invalid_artifact_path`）は frontmatter / journal / commit を一切変更しない
（副作用なし）ことを保証する。

1. 次 work item を選定する（依存解決 + resume 優先 / Step 0 で解決した `<cycle>` を使用）:

   ```bash
   scripts/work-item-next.sh ".aidlc/cycles/<cycle>/work-items"
   ```

   - 出力 `next:none`（選定可能 item なし / exit 0）→ 「完了後のフェーズ導出」に従い案内して**終了**（frontmatter / journal / commit を一切変更しない）。`next:none` を release 可能の根拠に**しない**。
   - 出力 `next:<id>:<size>:<path>` → `<id>` / `<size>` / `<path>` を取り出して次の 2 に進む。
   - exit 1（入力エラー: ディレクトリ不在 / work item 0 件）/ exit 2（システムエラー）→ エラーを提示して**終了**（mutation なし）。

2. **size enum を検証する**（出力 `<size>` を使用 / frontmatter 再パース不要）:

   `work-item-next.sh` は size の enum 検証を行わない（validate 済み前提）。`<size>` を以下の case で検証する（局所 frontmatter パースは足さず、**出力トークンの case 照合のみ**）:

   - `<size>` が `tiny` / `normal` / `risky` のいずれか → 次の 3 に進む。
   - 上記以外（enum 外 = `invalid_size`）→ 以下を案内して**終了**（副作用なし）:

     ```text
     選定された work item <id> の size: <size> は不正です（有効値: tiny / normal / risky）。
     work item frontmatter を修正してください（define の検証を参照）。
     ```

3. **depth_level を解決する**（cycle 単位 / config.toml 由来）:

   ```bash
   bash skills/aidlc/scripts/read-config.sh rules.depth_level.level
   ```

   出力（stdout）と exit code を**正規化契約**に従って `<depth_level>` に確定する。無効値・未設定・読取失敗はすべて安全側 `standard` に正規化し、停止しない（NFR 可用性）:

   | read-config.sh 結果 | `<depth_level>` |
   |---------------------|------------------|
   | exit 0 + stdout ∈ {`minimal`, `standard`, `comprehensive`} | その値 |
   | exit 0 + stdout が上記以外（enum 外） | 警告を表示して `standard` |
   | exit 1（キー不在 / 未設定） | `standard`（既定） |
   | exit 2（読取失敗） | 警告を表示して `standard` |

4. **§8 マトリクスへ写像し判定結果（MatrixDecision）を構築する**（正本: `docs/v3/data-model.md` §8）:

   `<size>` × `<depth_level>` を以下の写像表（§8 の materialized ビュー / 正本は §8）の 1 行に対応させ、`matrix_case` と派生要件を確定する。後続 Step はこの判定結果のみを参照し、§8 を再解釈しない。

   **MatrixDecision フィールド対応**: `matrix_case` は正規化済みの `<normalized_size>_<normalized_depth_level>`（size enum 検証済み × depth_level 正規化済み）を表す。下表の `エラー` 列は **§8 size×depth 写像由来の `error_reason`**（`-` = `none` / `risky_minimal` / `invalid_size`）のみを扱う。`invalid_artifact_path` は写像セルではなく、後述の「成果物パスの導出」ガードが付与する別系統の `error_reason` である。`is_error = (error_reason != none)` を導出する。これらは設計（ドメインモデル MatrixDecision）の論理フィールドの materialized 表現である:

   | matrix_case（normalized_size_depth_level） | design_required / design_mode | risk_analysis / test_plan / rollback_note | review_required / review_mode | reason_record | エラー（error_reason） |
   |-------------|------|------|------|------|------|
   | `tiny_minimal` | false / none | - / - / - | false / none | false | - |
   | `tiny_standard` | false / none | - / - / - | false / none | false | - |
   | `tiny_comprehensive` | false / none | - / - / - | false / none | **true** | - |
   | `normal_minimal` | false / none | - / - / - | false / none | false | - |
   | `normal_standard` | true / simple | false / false / false | true / code | false | - |
   | `normal_comprehensive` | true / full | true / false / false | true / code | false | - |
   | `risky_minimal` | - | - | - | - | **risky_minimal** |
   | `risky_standard` | true / full | false / false / true | true / code_security | false | - |
   | `risky_comprehensive` | true / full | true / true / true | true / code_security_design | false | - |

   - `risky_minimal`（risky は minimal 不可）→ 以下を案内して**終了**（副作用なし）:

     ```text
     選定された work item <id> は size: risky ですが、depth_level: minimal は許可されていません。
     depth_level を standard 以上に設定してください（docs/v3/data-model.md §8）。
     ```

   - **成果物パスの導出**（design_required または review_required が true の組合せで使用 / `<path>` から導出）:
     1. `artifact_filename = basename "<path>"`（例: `<path>` が `.aidlc/cycles/<cycle>/work-items/001-example.md` なら `001-example.md`）
     2. `artifact_filename` が `<id>-` で始まることを検証（work item ファイル名規約）。不一致（`invalid_artifact_path`）→ 以下を案内して**終了**（副作用なし）:

        ```text
        work item ファイル名 <artifact_filename> が id プレフィックス <id>- と一致しません。
        work item ファイル名規約（<id>-<slug>.md）を確認してください。
        ```

     3. `designs_path = .aidlc/cycles/<cycle>/designs/<artifact_filename>` / `reviews_path = .aidlc/cycles/<cycle>/reviews/<artifact_filename>`

   - 正常（エラー停止しない）→ MatrixDecision（`matrix_case` + 派生要件 + 該当時の `designs_path` / `reviews_path`）を確定する。

   **本 Unit（001）スコープ境界ガード**: design 生成（Step 2 / Unit 002）・review 実行（Step 5 / Unit 003）は本サイクル時点で未実装である。`design_required = true` または `review_required = true` の組合せ（`normal_standard` / `normal_comprehensive` / `risky_standard` / `risky_comprehensive`）は、**status 遷移（次の 5）を行う前にここで案内して終了**する（副作用なし＝ frontmatter / journal / commit 不変）:

   ```text
   選定された work item <id>（matrix_case: <matrix_case>）は design / review を要します。
   develop Step 2（設計生成 / Unit 002）・Step 5（レビュー実行 / Unit 003）は未実装です。
   生成先: <designs_path> / 記録先: <reviews_path>
   ```

   - `design_required = false` かつ `review_required = false`（`tiny_minimal` / `tiny_standard` / `tiny_comprehensive` / `normal_minimal`）→ 本 Unit 単体で end-to-end 完走可能。次の 5 に進む。

5. **現在 status を読取り、必要なら遷移する**（`work-item-next.sh` 出力に status は含まれないため別途読取 / パースは安全境界スクリプトに集約。**判定が正常完了した場合のみ実行**）:

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

> **ドッグフーディング特殊処理の禁止**: size×depth_level 判定・depth_level 解決に「自リポジトリが starter kit 自身か consumer か」の判定を埋め込まない（リポジトリ規約）。判定は work item frontmatter（size）と config.toml（depth_level）のみを入力とする。

## Step 2: 計画 + 設計（`design_required` で分岐）

Step 1 の MatrixDecision を参照する:

- `design_required = false`（`tiny_*` / `normal_minimal`）→ 本 Step は実行しない（**repo への追記なし** / 実行ログ・会話通知のみ）。Step 3 へ進む。
- `design_required = true`（`normal_standard` / `normal_comprehensive` / `risky_standard` / `risky_comprehensive`）→ `designs_path` に design 成果物を生成する（`design_mode` / `risk_analysis_required` / `test_plan_required` / `rollback_note_required` を消費 / 生成本体は **Unit 002 の責務**）。

  > **本 Unit（001）時点**: `design_required = true` の組合せは Step 1 のスコープ境界ガードで status 遷移前に副作用なし停止済みのため、本フローが Step 2 に到達するのは `design_required = false` の場合のみである。Unit 002 が Step 2 の生成本体を実装した時点で、Step 1 ガードを解除し本分岐（design 生成）が実行される。

## Step 3: 実装

1. 対象 work item の本文（Goal / Scope / Acceptance Criteria）を読み、acceptance criteria を満たす実装を行う。
2. 実装変更はこの時点で staging してよいが、**最終 commit は Step 6 で 1 つに集約する**（後述）。

## Step 4: 検証

1. work item の Acceptance Criteria（本文 `## Acceptance Criteria` のチェックリスト）と Traceability の
   Verification（test command / manual check）に従って検証する。
2. lint / test / ビルドが該当する変更であれば実行し、パスを確認する。
3. 検証が通らない場合は Step 3 に戻って修正する（解決困難なら work item を `blocked` 等に
   する判断は本フロー外 = 中断してユーザーに相談）。

## Step 5: レビュー（`review_required` で分岐）

Step 1 の MatrixDecision を参照する:

- `review_required = false`（`tiny_*` / `normal_minimal`）→ 本 Step は実行しない（**repo への追記なし** / 実行ログ・会話通知のみ）。Step 6 へ進む。
- `review_required = true`（`normal_*` / `risky_*` の standard 以上）→ `review_mode`（`code` / `code_security` / `code_security_design`）に従い、`reviews_path` に perspective 別セクションでレビューを記録する（実行本体は **Unit 003 の責務**）。

  > **本 Unit（001）時点**: `review_required = true` の組合せは Step 1 のスコープ境界ガードで status 遷移前に副作用なし停止済みのため、本フローが Step 5 に到達するのは `review_required = false` の場合のみである。Unit 003 が Step 5 の routing / 実行本体（既存 `reviewing-construction-*` への配線・5R 上限・Defer 戦略）を実装した時点で、Step 1 ガードを解除し本分岐（review 実行）が実行される。
  >
  > 注: `normal + minimal` は `review_required = false` のため本 Step をスキップし、Step 6 まで完走する（Unit 001 の end-to-end 対象）。

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

   **理由記録（`reason_record_required` で分岐）**: Step 1 の MatrixDecision を参照する:

   - `reason_record_required = true`（`tiny_comprehensive` のみ / §8）→ 上記 completed 行に続けて「短い理由記録」を 1 行追記する（comprehensive で tiny を選んだ判断の短い根拠）:

     ```text
     - develop reason (tiny+comprehensive): <この work item を tiny とした短い理由>
     ```

   - `reason_record_required = false`（上記以外すべて）→ 理由記録は追記しない（§8 の成果物要件を増やさない）。

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
