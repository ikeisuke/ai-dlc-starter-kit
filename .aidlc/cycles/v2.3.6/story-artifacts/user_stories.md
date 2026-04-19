# ユーザーストーリー

## Epic 1: Operations Phase のマージ前完結契約の信頼性向上

### ストーリー 1.1: 固定スロットの反映手順が `operations-release.md` から明確に導出できる（#583-A）

**優先順位**: Must-have

As an AI-DLC Operations 担当エージェント（Claude Code 等）
I want to `operations-release.md` §7.6 を読むだけで `release_gate_ready` / `completion_gate_ready` / `pr_number` を §7.7 最終コミットに含めるべきだと判断できる
So that マージ済み main ブランチで固定スロットが `false`/空のまま残るのを防ぎ、session-continuity の新形式判定源が確実に機能する

**受け入れ基準（正常系・観測可能）**:

- [ ] `skills/aidlc/steps/operations/operations-release.md` §7.6 に「`release_gate_ready=true` を progress.md に反映して §7.7 最終コミットに含める」手順が 1 ステップとして追加されている（`git diff` で該当追記を 1 箇所で確認できる）。
- [ ] 同節に `completion_gate_ready=true` および `pr_number=<PR 番号>` の反映タイミングが「§7.6 にて記入、§7.7 でコミット」形式で明示されている（§7.6 と §7.7 の役割分担に曖昧さがない）。
- [ ] §7.2〜§7.6 で参照される progress.md 状態更新の記述が追加ステップと整合し、手順書を上から順に実行した場合に固定スロット反映用の追加コミットが不要になる（観測方法: `git log --oneline cycle/{{CYCLE}}` の最終コミットが 1 回で必要要素を全て含む）。
- [ ] 固定スロット名の表記は `phase-recovery-spec.md` §7 と一致している（`release_gate_ready` / `completion_gate_ready` / `pr_number`、揺れなし）。

**受け入れ基準（異常系）**:

- [ ] PR 番号が §7.5 完了時点で未取得のエッジケースについて、「§7.6 最終コミット前に必ず `pr_number` を埋める（未確定のまま §7.7 へ進まない）」と明示されている。
- [ ] 固定スロットが既に `true` / 値設定済みで §7.6 に入った場合の扱い（上書き不要か明示再確認か）が一文以上で記述されている。
- [ ] §7.6 と §7.7 の記述が矛盾した場合に検知できるよう、共通参照先（`phase-recovery-spec.md` §7）を §7 冒頭またはヘッダから辿れる（リンク／相互参照が 1 箇所以上存在）。

**受け入れ基準（付随条件・限定）**:

- [ ] 「`skills/aidlc/guides/*.md` からの旧 `operations-release.md` 参照」は、Unit 001 実装時に `rg "guides/operations-release"` と `rg "steps/operations/operations-release"` を実行し、旧参照が 0 件であることを PR 本文または Unit 履歴に記録する（本ストーリーの主目的ではなく、副次的な整合性チェック）。

**技術的考慮事項**:

- `operations-release.md` は `steps/operations/` 配下のガイド。`guides/` 配下とは混同しない。
- 固定スロット名は `phase-recovery-spec.md` §7（構造化シグナル）と一致させる。
- 正常系テスト観点: `git diff HEAD~1 HEAD -- skills/aidlc/steps/operations/operations-release.md` で該当追記が 1 箇所の差分に現れること。

---

### ストーリー 1.2: マージ後の `write-history.sh` 呼び出しが拒否される（#583-B）

**優先順位**: Must-have

As an AI-DLC Operations 担当エージェント
I want to Operations Phase の 7.8 以降（マージ後）に誤って `/write-history` を呼び出しても、`history/operations.md` への追記が行われず、明確なエラーで拒否される
So that 削除予定のブランチに「マージ完了ログ」という未コミット差分が残らず、post-merge-sync.sh 実行前の迷いがなくなる

**受け入れ基準（判定契約・正常系）**:

- [ ] `skills/aidlc/scripts/write-history.sh` に新引数 `--operations-stage` が追加され、有効値として少なくとも `pre-merge` / `post-merge` を受け付ける（無指定時は従来動作）。
- [ ] 拒否判定の優先順位は以下の順で評価される:
  1. **第一条件（引数主）**: `--phase operations` かつ `--operations-stage post-merge` が指定されたら即拒否する。
  2. **第二条件（AND フォールバック）**: 第一条件に該当せず、`--phase operations` かつ `.aidlc/cycles/{{CYCLE}}/operations/progress.md` の `completion_gate_ready=true` が読め、さらに `gh pr view` で当該 PR が `state=MERGED` と確認できた場合、警告付きで拒否する（DR-001 の AND 条件）。
  3. **従来動作**: 第一・第二条件のどちらにも該当しない `operations` 呼び出し（7.7 以前・PR 未マージ等）は従来どおり appended / created を返す。`gh` 失敗時（`cli_runtime_error` 等）は第二条件を undecidable 扱いとし従来動作を継続する。
- [ ] 拒否時は標準エラーに `error:post-merge-history-write-forbidden` 形式のメッセージを出力し、exit code `3` で終了する。既存の exit `1`（引数不正）/ `2`（I/O 失敗）の意味は変更しない。
- [ ] `--phase inception` / `--phase construction` の既存呼び出しは挙動を変えない（appended / created のステータス出力と exit 0 を維持）。

**受け入れ基準（異常系・境界）**:

- [ ] `--phase operations --operations-stage post-merge` を `--dry-run` と組み合わせた場合も拒否され、dry-run 時も exit 3 が返る（未コミット差分は発生しない）。
- [ ] `.aidlc/cycles/{{CYCLE}}/operations/progress.md` が存在しない／`completion_gate_ready` 行が空のケース、または `gh pr view` が失敗／PR が `state!=MERGED` のケースでは、第二条件は該当しないと判定し（false 扱い）、従来動作を維持する（偽陽性を避ける）。
- [ ] `--operations-stage` に未定義値が渡された場合は exit 1（引数不正）で拒否され、exit 3 とは区別される（誤用を検出できる）。

**受け入れ基準（テスト観点）**:

- [ ] 新規テストケース（または検証手順）に以下が含まれる:
  - `TC_POST_MERGE_REJECT_EXPLICIT`: `--phase operations --operations-stage post-merge` → exit 3 / `error:post-merge-history-write-forbidden`。
  - `TC_POST_MERGE_REJECT_FALLBACK`: `completion_gate_ready=true` の progress.md + `gh pr view` が `state=MERGED` を返す状態を整え、`--phase operations` のみ指定 → exit 3。
  - `TC_PRE_MERGE_GATE_READY_PASS`: `completion_gate_ready=true` だが `gh pr view` が `state=OPEN`（PR 未マージ）を返すケースで `--phase operations` のみ指定 → 従来どおり appended（第二条件不成立）。
  - `TC_PRE_MERGE_PASS`: `--phase operations --operations-stage pre-merge` → 従来どおり appended。
  - `TC_INCEPTION_PASS`: `--phase inception` → 既存動作維持。
- [ ] `skills/aidlc/steps/operations/04-completion.md` に「7.8〜7.13 以降で `write-history.sh` を呼ばない」明示的禁止と exit 3 拒否の取り扱いが追加されている。
- [ ] `/write-history` スキル SKILL.md（委譲スキル側）の出力表に exit 3（`error:post-merge-history-write-forbidden`）を追記する（整合性確保）。

**技術的考慮事項**:

- `--operations-stage` は後方互換のため省略可能。呼び出し側（Operations フロー）の段階的移行を想定する。
- exit code `3` の新規割り当てを `write-history.sh` 冒頭コメントと `/write-history` スキル SKILL.md の出力表に明記する。
- Operations 手順書（04-completion.md §5 / §7 以降）に禁止記述を追加する際は、重複記述を避け、1 箇所に集約する。

---

## Epic 2: Inception progress.md 表記の統一

### ストーリー 2.1: Inception progress.md の進捗テーブル表記が「ステップ1〜N」に統一されている（#565, 表記変更本体）

**優先順位**: Should-have

As an AI-DLC Inception 担当エージェントおよび進捗を確認する開発者
I want to Inception の各種ドキュメントで参照される progress.md の項目名が「ステップ1〜N」の一貫形式に揃っている
So that Part/ステップ/完了処理の混在による認知負荷がなくなる

**受け入れ基準**:

- [ ] `skills/aidlc/templates/inception_progress_template.md` の進捗テーブル項目名が「ステップ1〜N」で統一されている（「Part X」「完了処理」表記ゼロ）。
- [ ] 以下のファイル群で **progress.md 進捗テーブル文脈**の旧表記が新表記に追従している:
  - `skills/aidlc/steps/inception/index.md`
  - `skills/aidlc/steps/inception/01-setup.md`
  - `skills/aidlc/steps/inception/02-preparation.md`
  - `skills/aidlc/steps/inception/04-stories-units.md`
  - `skills/aidlc/steps/inception/05-completion.md`
  - `skills/aidlc/steps/common/phase-recovery-spec.md`（progress.md 状態参照文脈のみ）
  - `skills/aidlc/steps/common/task-management.md`
  - `skills/aidlc/scripts/verify-inception-recovery.sh`（フィクスチャ生成関数）
  - `skills/aidlc/scripts/verify-construction-recovery.sh` / `verify-operations-recovery.sh`（Inception 進捗参照分のみ）
- [ ] 旧表記検出は以下のパターンで 0 ヒットであることを確認する（progress.md 進捗テーブル文脈に限定）:
  - `rg "Part [0-9]+"`（Part 1〜Part 99）
  - `rg "^\|\s*完了処理"`（テーブル行先頭の「完了処理」）
  - `rg "ステップ[0-9]+-[0-9]+"`（旧「ステップ1-5」表記）
  - `checkpoint` 関連（`completion_done` などの意味論ラベル）はヒットしてもよい（対象外）
- [ ] `phase-recovery-spec.md` の `completion_done` / `setup_done` など checkpoint 名称は変更されていない（意味論維持）。

> 注: Story 2.2（検証・後方互換）は別ストーリーで管理する。Story 2.1 単体の受け入れは 2.2 の成否に依存しない（Independent 原則）。同一 PR での一体実装は Unit 003 の運用上の制約であり、Story 2.1 の受け入れ基準には含めない。

**技術的考慮事項**:

- 進捗モデルは DR-003 により「テンプレートの 6 ステップ構造を正、`verify-*-recovery.sh` のフィクスチャを 6 ステップへ追従」で確定済み（詳細は `.aidlc/cycles/v2.3.6/inception/decisions.md` 参照）。
- 「progress.md 進捗テーブル文脈」の判定は、Markdown テーブル行 `| 1. XXX |` 形式、もしくは fixtures 生成関数内の該当変数定義箇所とする。

---

### ストーリー 2.2: Inception progress.md 命名変更の検証と後方互換が担保される（#565, 検証・互換）

**優先順位**: Should-have

As an AI-DLC 利用者
I want to 命名変更後も既存サイクル（旧表記）の `inception/progress.md` が読み込め、新規サイクルの復帰判定シナリオがすべて合格する
So that 命名統一リファクタによる破壊的影響を心配せずリリースを受け入れられる

**受け入れ基準（新表記の動作検証）**:

- [ ] `skills/aidlc/scripts/verify-inception-recovery.sh` の全シナリオが合格する（新表記テンプレートを使用した状態で）。
- [ ] `skills/aidlc/scripts/verify-construction-recovery.sh` / `verify-operations-recovery.sh` の Inception 進捗参照分も引き続き合格する。

**受け入れ基準（後方互換）**:

- [ ] `v1.x〜v2.3.5` の既存 `inception/progress.md` サンプル（最低 2 バージョン: v1.28.x と v2.3.5）をフィクスチャとして投入し、`RecoveryJudgmentService.judge()` 経由で復帰判定が blocking undecidable を返さずに妥当な step_id を返すことをスポット検証する。
- [ ] 後方互換検証の結果は Unit 003 の履歴 / PR 本文に `旧表記 progress.md 読取互換OK（対象: vX.X.X / vY.Y.Y）` 形式で記録される。

**受け入れ基準（レポーティング）**:

- [ ] Unit 003 の PR 本文に「表記統一の変更概要」「`rg` による旧表記 0 件検証結果」「後方互換スポット検証結果」の 3 項目が含まれる。

> 注: Story 2.1 との同時実装・同一 PR 運用は Unit 003 側の運用制約として管理する（Story 2.2 単体の受け入れは Story 2.1 の実装タイミングに依存しない。Independent 原則を維持）。

**技術的考慮事項**:

- v1.x 系の progress.md はフォーマットが異なる可能性があるため、フィクスチャ投入前に原本を確認する。
- DR-003 に従い `verify-inception-recovery.sh` のフィクスチャ生成関数を 6 ステップ構造へ追従更新する。後方互換検証（v1.x〜v2.3.5 の旧表記 progress.md 読取確認）も同スクリプト内に新規フィクスチャを追加する形で統合する（別スクリプト `verify-legacy-progress.sh` は作成しない）。

---

## Epic 3: CI リソースの最適化

### ストーリー 3.1: Draft PR で GitHub Actions の不要な起動を抑止する（DR-004, Unit 004）

**優先順位**: Should-have

As an AI-DLC スターターキットのメンテナおよび PR 作者
I want to Draft PR の間は `pull_request` トリガーのワークフロー（pr-check / migration-tests / skill-reference-check）のジョブが `skipped` となり runner 分単位を消費しない
So that Inception Phase 時点のまだ不完全な差分で CI runner を消費するのを避け、`ready_for_review` に切り替えた時点で初回実行される運用に寄せられる

**受け入れ基準**:

- [ ] `.github/workflows/pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml` の 3 本で、`on.pull_request.types` が `[opened, synchronize, reopened, ready_for_review]` に統一されている（暗黙のデフォルト依存を避けるため `types` を明示する）。
- [ ] 同 3 本の `jobs.*` 各ジョブに `if: github.event.pull_request.draft == false` が付与されている（複数ジョブがあるワークフローは全ジョブ）。
- [ ] `.github/workflows/auto-tag.yml` は `push` トリガーのため変更されていない。
- [ ] 既存の `paths` フィルタ・`branches` 設定は維持される。
- [ ] 新規 Draft PR で `gh api repos/{owner}/{repo}/actions/runs?event=pull_request&head_branch=<branch>` を実行した際、該当 3 ワークフローの `runs` は存在しても全て `conclusion=skipped` または全ジョブが `skipped` であり、`in_progress` や `queued` を通過した runner 実行がないこと（Actions 分単位 0 消費）。
- [ ] Draft → Ready 遷移（`ready_for_review` イベント）で該当 3 ワークフローが初回実行され（runner 起動 / `in_progress` → `completed`）、以後 `synchronize` でも従来どおり実行される。
- [ ] PR 本文または Unit 004 履歴にスキップ方式（`types` + ジョブレベル `if` の二段ガード、Draft 中は job `skipped`）と検証手順が記録される。

**技術的考慮事項**:

- `types` を明示しないと GitHub のデフォルトは `opened, synchronize, reopened` のみで `ready_for_review` が含まれず、Draft → Ready 遷移で発火しない。`types` 更新は必須。
- ジョブレベル `if` が `false` と評価されるとジョブは `skipped` ステータスになり、runner を割り当てずに完了する。workflow run 自体は作成される可能性があるが、runner 分単位は消費しない（ステップレベル `if` では runner が起動してからスキップされるため分単位消費あり）。
- `.github/workflows/auto-tag.yml` は `push` トリガーで main マージ後に動作するため影響なし。
