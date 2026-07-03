# Release: v3.0.0-beta.2

<!--
release フェーズ Step 2「PR 整備」で生成する成果物。
PR 概要 / work item 完了一覧 / review 結果サマリ（機械可読）/ CI 状態 / merge 記録を集約する。
release-level review（premerge / integration / deploy）の結果は本ファイルに集約し reviews/*.md は生成しない
（docs/v3/data-model.md §8 / §10）。merge 記録は Step 3/4 で追記する。
-->

## PR 概要

- PR: #748
- base: main
- head: cycle/v3.0.0-beta.2
- v3 ベータの既知バグと CI 非互換を解消する: doctor `[phase]` の merged 判定を `gh pr view --json state` ベースへ修正し gh stub を忠実化（#744）、`bin/check-cycle-phase-completion.sh` を v3-flat 構造対応（#747）。

## Work Item 完了一覧

| id | status | size |
|----|--------|------|
| 001-doctor-phase-merged-fix | done | tiny |
| 002-cycle-check-v3-flat | done | normal |

<!--
全 work item が done / withdrawn（release 可能 / docs/v3/data-model.md §5.1 評価順 4）であることを Step 1 で確認済み。
本表は done / withdrawn の内訳を記録する。
-->

## Review 結果サマリ

<!--
固定マーカー間（start の次行から end の前行まで）は純 YAML のみ。release Step 3 の merge ゲートがこの範囲を
そのまま YAML として parse する（入力契約）。マーカー間に markdown コードフェンス・見出し・装飾を置かないこと。
status: passed | failed | skipped / max_severity: high | medium | low | none。
status=skipped は skip_reason を非 null にする（実行条件未該当の理由）。
merge_blocker は当該 perspective に高重要度（high）の未解決指摘があれば true。
merge_blocker_any はいずれかの perspective が merge_blocker=true なら true。
マーカー不在・純 YAML として parse 不能・必須フィールド欠落・enum 外は release Step 3 側で fail-closed。
-->

<!-- aidlc-release-review:start -->
schema_version: "1.0"
reviews:
  - perspective: premerge
    status: passed
    unresolved_count: 0
    max_severity: none
    merge_blocker: false
    skip_reason: null
  - perspective: integration
    status: passed
    unresolved_count: 0
    max_severity: none
    merge_blocker: false
    skip_reason: null
  - perspective: deploy
    status: skipped
    unresolved_count: 0
    max_severity: none
    merge_blocker: false
    skip_reason: "size:risky の done が 0 件のため未実行（条件: 1 件以上）"
merge_blocker_any: false
<!-- aidlc-release-review:end -->

<!--
premerge（codex / 高 1 件）・integration（codex / 中 1 件）の指摘はいずれも
「release.md 未追加 + state.json の release.pr_number 未反映で cycle-phase-completion-check が exit 1 になる」
という同一論点であり、本 release.md と state.json（release.pr_number: 748）を head branch に commit することで解消済み
（bin/check-cycle-phase-completion.sh v3.0.0-beta.2 --pr-number 748 の exit 0 で検証）。設計乖離の指摘なし。
-->

## CI 状態

- conclusion: pending
- Step 1 時点で cycle/v3.0.0-beta.2 の run は未実行（gh run list 0 件 / CI は PR イベントで起動）。CI パスの強制は Step 3 hard gate（gh pr checks --required）で行う。

## Merge 記録

<!-- merge 記録は release Step 3/4 で追記する（テンプレート生成時点では未記録）。 -->

- merge_approved: true（2026-07-04 / semi_auto 自動承認: merge_blocker_any=false）
- merged: true（2026-07-03T16:27:35Z / merge commit c0b3f09a02092b09fa09b81a5098a5a0b01b2f37 / merge method: merge）
