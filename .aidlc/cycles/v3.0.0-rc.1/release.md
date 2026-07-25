# Release: v3.0.0-rc.1

<!--
release フェーズ Step 2「PR 整備」で生成する成果物。
PR 概要 / work item 完了一覧 / review 結果サマリ（機械可読）/ CI 状態 / merge 記録を集約する。
release-level review（premerge / integration / deploy）の結果は本ファイルに集約し reviews/*.md は生成しない
（docs/v3/data-model.md §8 / §10）。merge 記録は Step 3/4 で追記する。
-->

## PR 概要

- PR: #755
- base: main
- head: cycle/v3.0.0-rc.1
- `/aidlc` = v3 のフル本流化（Epic #736 7-e）を RC として main に反映する。skills/aidlc-v3 → skills/aidlc 置換 / v2 実装の撤去（v2-maintenance branch へ保全済み）/ marketplace `3.0.0-rc.1` 化 / README・docs の v3 刷新を含む。

## Work Item 完了一覧

| id | status | size |
|----|--------|------|
| 001-v2-maintenance-branch | done | tiny |
| 002-v3-mainline-replacement | done | risky |
| 003-readme-docs-renewal | done | normal |

## Review 結果サマリ

<!--
固定マーカー間（start の次行から end の前行まで）は純 YAML のみ。release Step 3 の merge ゲートがこの範囲を
そのまま YAML として parse する（入力契約）。
-->

<!-- aidlc-release-review:start -->
schema_version: "1.0"
reviews:
  - perspective: premerge
    status: passed
    unresolved_count: 1
    max_severity: low
    merge_blocker: false
    skip_reason: null
  - perspective: integration
    status: passed
    unresolved_count: 1
    max_severity: medium
    merge_blocker: false
    skip_reason: null
  - perspective: deploy
    status: passed
    unresolved_count: 0
    max_severity: none
    merge_blocker: false
    skip_reason: null
merge_blocker_any: false
<!-- aidlc-release-review:end -->

### Review 詳細（人間可読）

いずれも codex（`[rules.reviewing].mode = required` / tools = codex）で実行。

- **premerge**（focus: code, security / Round 1）: 指摘 2 件（中 1 / 低 1）
  - 指摘 #1（中）: 撤去済み v2 スクリプトを参照する stale bats テスト（bin/tests/aidlc-paths / squash-unit / operations-712-squash）→ **撤去して解消**（commit 2ee683da）
  - 指摘 #2（低）: skills/aidlc/config の v2 前提資産（config.toml.example / defaults.toml）→ **Issue #756 で追跡**（unresolved 1 件として計上）
- **integration**（focus: code / Round 1）: 指摘 2 件（中 1 / 低 1）
  - 指摘 #1（中）: migrate-path-traversal.bats 撤去が Design 002 D8 と乖離 / path-guard.sh の回帰テスト喪失 → 設計変更を D8 に反映（commit 0668c663）、テスト移植は **Issue #757 で追跡**（unresolved 1 件として計上）
  - 指摘 #2（低）: marketplace skills 件数の記録不整合（10 vs 実体 9）→ **D5 / 検証表 / journal を訂正して解消**（commit 0668c663）
- **deploy**（focus: architecture / Round 1 → Round 2）: R1 指摘 3 件（高 1 / 中 2）→ 全件解消（commit 494a97cb）、R2 新規 低 1 件 → 解消（commit 572e01b1）。R2 で R1 全 3 件の解消を確認済み
  - #1（高）: Rollback Note の配布モデル矛盾（tag 単位前提 → main 追従の実態へ訂正 / revert PR + 単調増加 hotfix version の緊急手順を定義）
  - #2（中）: tag と CHANGELOG の非原子性（CHANGELOG rc.1 エントリを merge 前の PR に追加 / auto-tag 正規経路を明記）
  - #3（中）: 破壊的変更の列挙不足（README / CHANGELOG に撤去 v2 スキル → v3 代替の対応表を追加）
  - R2 #1（低）: aidlc-retrospective の区分表現（非 marketplace）を訂正

## CI 状態

- conclusion: pending
- head branch cycle/v3.0.0-rc.1 の CI は PR トリガーのため Step 2 時点では未実行（gh run list 0 件）。CI パスの強制は Step 3 hard gate（`gh pr checks --required` / merge 直前の最終 head に対して判定）で行う
- ローカル検証: bats 113/113 pass（tests/migration / config-defaults / feedback-route-resolution / check-cycle-phase-completion）/ markdownlint 0 issues（変更 md）

## Merge 記録

<!-- merge 記録は release Step 3/4 で追記する（テンプレート生成時点では未記録）。 -->

- merge_approved: true（2026-07-26 / semi_auto 自動承認: merge_blocker_any = false）
- merged: true（2026-07-26 / merge commit a3c12bb1 / merge method: merge / tag v3.0.0-rc.1 は auto-tag.yml が自動作成）
- 補足: merge 前に main ruleset の stale required context（Defaults TOML Sync Check / D7 で job 撤去済み）を ruleset 11757623 から除去して hard gate を通過（required 4 件全 pass + CLEAN / --match-head-commit 11160c83）
