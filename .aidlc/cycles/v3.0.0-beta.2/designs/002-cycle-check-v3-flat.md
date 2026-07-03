# Design 002: cycle-phase-completion-check の v3-flat 構造対応

- trace: work item 002-cycle-check-v3-flat
- matrix_case: normal_standard
- design_mode: simple

## Goal

`bin/check-cycle-phase-completion.sh` を v3-flat 構造（`intent.md` / `work-items/` + リポジトリ直下 `state.json`）で完了判定できるようにし、`cycle/*` 命名の v3 サイクル main 宛て PR が CI（`cycle-phase-completion-check.yml`）を通過できるようにする（#747）。v2 サイクル向けの既存判定は非影響で維持する。

## Context

- 既存 CLI は v2 構造（`inception/progress.md` / `story-artifacts/units/` / `operations/progress.md`）専用。v3-flat サイクルに実行すると `inception:incomplete:reason=progress_md_missing` で fail する。
- CI workflow は `cycle/*` head branch の非 draft PR でのみ起動し、`--pr-number` に PR 番号を渡す。v2 判定は `AIDLC_CYCLES_BASE` 環境変数でフィクスチャ差し替え可能（bats 16 ケース既存）。
- v3 のフェーズ導出正本は `docs/v3/data-model.md` §5.1（first-match）。本チェックは **merge 前の CI ゲート**であるため「complete（merged）」ではなく「**release 可能（評価順 4）+ release 記録あり**」を合格条件とする（merged を要求すると merge 前ゲートが恒久 fail する）。
- v3 release フロー（`skills/aidlc-v3/steps/release.md`）では Step 2-2 で `release.pr_number` 記録、2-4 で `release.md` を head branch に commit + push、3-3 で `state.json` を含む最終 commit を push する。したがって PR の最終 head（merge 直前の hard gate 3-4 が見る SHA）では本設計の全条件が充足される。
- リポジトリ設計原則「ドッグフーディング特殊処理を本体に埋めない」により、v2 / v3 の判別は **opt-in シグナル**（成果物の存在に基づく汎用分岐）で行う。starter kit 自身か否かの判定は導入しない。

## Design

### 1. 構造判別（opt-in シグナル方式）

| シグナル | 判定 |
|---------|------|
| `<cycle_dir>/work-items/` ディレクトリが存在 | v3-flat 判定パスへ |
| 上記なし | v2 判定パス（既存ロジック / 変更なし） |
| `work-items/` と `inception/` が両方存在 | 曖昧構造として `error:ambiguous-cycle-structure` で exit 2（fail-closed） |

v2 サイクルは `work-items/` を持たないため既存フィクスチャ・実サイクルの挙動は不変。consumer プロジェクトでも「成果物があれば v3 として判定」の汎用論理のみで動く。

### 2. v3-flat 完了判定（評価順 / fail-fast で最初の未充足を報告）

| # | 検査 | 未充足時の出力（exit 1） |
|---|------|------------------------|
| 1 | state file 存在（`AIDLC_STATE_FILE` 環境変数 / 既定 `${REPO_ROOT}/.aidlc/state.json`） | `v3:incomplete:reason=state_json_missing` |
| 2 | `current_cycle` == CLI 引数 `<cycle>` | `v3:incomplete:reason=current_cycle_mismatch:expected=<cycle>:actual=<値>` |
| 3 | `define_completed` == `true` | `v3:incomplete:reason=define_not_completed` |
| 4 | `work-items/*.md` が 1 件以上 | `v3:incomplete:reason=no_work_items` |
| 5 | 全 work item の frontmatter `status` が `done` / `withdrawn`（ソート順で最初の未完了を報告） | `v3:incomplete:reason=item_status_pending:item=<basename>:status=<値>` |
| 6 | `release.md` が cycle dir に存在（release 記録） | `v3:incomplete:reason=release_md_missing` |
| 7 | `release.pr_number` が正整数（null は未記録） | `v3:incomplete:reason=pr_number_not_recorded` |
| 8 | `--pr-number N` 指定時、`release.pr_number` == N | `v3:incomplete:reason=pr_number_mismatch:expected=N:actual=<値>` |

全充足で `v3:complete` を出力して exit 0。`ready` / `merge_approved` は要求しない（merge 前ゲートのため / merged 実態の検証は release Step 3-4 hard gate と doctor `[phase]` の責務）。

### 3. パース・読取の安全境界（既存スクリプト再利用 / 生パース禁止）

| 読取対象 | 使用スクリプト | 失敗時 |
|---------|--------------|--------|
| `state.json`（`current_cycle` / `define_completed` / `release.pr_number`） | `skills/aidlc-v3/scripts/state-read.sh <field> <file>`（file 引数で対象指定） | exit 1 → 判定不能として `v3:incomplete:reason=state_unreadable:field=<field>` exit 1 / exit 2（jq 不在等）→ exit 2 透過 |
| work item `status` | `skills/aidlc-v3/scripts/work-item-status.sh --read <path>` | exit 1（malformed / enum 不正）→ `v3:incomplete:reason=work_item_malformed:item=<basename>` exit 1 / exit 2 → exit 2 透過 |

frontmatter / JSON の生パース（grep/sed/awk/jq 直書き）を本 CLI に足さず、v3 の安全境界スクリプトへ委譲する（doctor / release フローと同じ読取経路 = 導出規則の再実装を避ける）。`bin/ → skills/` の依存は既存（`validate.sh` source 済み）と同方向。

### 4. CLI インターフェース（後方互換）

- 引数仕様（`<cycle>` / `--pr-number N` / `--help`）と exit code 規約（0 / 1 / 2）は不変。
- 環境変数: 既存 `AIDLC_CYCLES_BASE` に加え、テスト用に `AIDLC_STATE_FILE`（v3 state file の場所差し替え / 既定はリポジトリ直下）を追加。
- usage 文面に v3-flat 対応と `AIDLC_STATE_FILE` を追記。

### 5. テスト（bats 追加 / 既存 16 ケース非影響）

フィクスチャ: `tests/fixtures/cycle-phase-completion/v3-*/`（`state.json` + `cycles/<cycle>/` の 2 階層で `AIDLC_STATE_FILE` / `AIDLC_CYCLES_BASE` を差し替え）。

追加ケース: (1) v3 全充足で exit 0 / (2) in_progress 残で exit 1 + 理由 / (3) release.md 欠落で exit 1 / (4) pr_number 未記録で exit 1 / (5) `--pr-number` 不一致で exit 1 / (6) current_cycle 不一致で exit 1 / (7) state.json 不在で exit 1 / (8) 曖昧構造（work-items/ + inception/ 両在）で exit 2 / (9) 既存 v2 ケース全 pass（回帰）。

### 6. AC-5（実 PR での CI 成功）の充足経路

本サイクル PR の**最終 head**（release Step 3-3 push 後）は「全 work item done + release.md + pr_number 記録」を満たすため、Step 3-4 hard gate が見る required check として本 job が成功する。develop 中のローカル実行では未充足理由（release_md_missing 等）を正しく報告する（これは正常動作）。
