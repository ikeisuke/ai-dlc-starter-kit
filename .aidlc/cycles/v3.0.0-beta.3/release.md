# Release: v3.0.0-beta.3

<!--
release フェーズ Step 2「PR 整備」で生成する成果物。
PR 概要 / work item 完了一覧 / review 結果サマリ（機械可読）/ CI 状態 / merge 記録を集約する。
release-level review（premerge / integration / deploy）の結果は本ファイルに集約し reviews/*.md は生成しない
（docs/v3/data-model.md §8 / §10）。merge 記録は Step 3/4 で追記する。
-->

## PR 概要

- PR: #750
- base: main
- head: cycle/v3.0.0-beta.3
- release hard gate の required CI 0 件フォールバック（#745）明文化、v3 config.toml 終端キー集合の確定（data-model.md §11 / SoT ギャップ解消）、v2 → v3 migration 実装（new-cycle-only + archive-only）を main に取り込む。Phase 7 本流化（7-e）の残り前提を完成させる（Epic #736 7-c / 7-d）。

## Work Item 完了一覧

| id | status | size |
|----|--------|------|
| 001 | done | normal |
| 002 | done | normal |
| 003 | done | risky |

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
    status: passed
    unresolved_count: 0
    max_severity: none
    merge_blocker: false
    skip_reason: null
merge_blocker_any: false
<!-- aidlc-release-review:end -->

### Review 経過（参考）

- ツール: codex（外部 CLI / mode: required）
- integration（統合とレビュー / focus: code）: 3 rounds。R1 指摘 1 件（中 / archive-only 定義乖離疑い → 検証の結果、migration.md §2 の表現が誤読誘発と判断し明確化注記を追加）→ R2 指摘 1 件（低 / §3.1 適用対象の archive-only 欠落 → 修正）→ R3 指摘 0 件
- deploy（デプロイ計画承認前 / focus: architecture）: 3 rounds。R1 指摘 2 件（中 / preflight の state-init 未検証 → preflight に解決検証 + テスト 2 件追加で修正、archive-only プレビュー API 不一致 → 検証の結果事実誤認と確認）→ R2 指摘 1 件（低 / override 解決契約の不一致 → Step 5 に同一契約を明記）→ R3 指摘 0 件
- premerge（PR マージ前 / focus: code, security）: R1 指摘 1 件（中 / release.pr_number 未コミット + release.md 不在 → 本ファイル生成 + state.json コミットで解消）→ R2 で解消確認
- 対応コミット: c421ade9 / 9d545a3f

## CI 状態

- conclusion: success
- PR #750（head: cycle/v3.0.0-beta.3）の checks 全 pass を gh pr checks で確認（Analyze / Bash Substitution Check / CodeQL / Defaults TOML Sync Check / Markdown Lint / Marketplace Version Check / Migration Script Tests / Skill Reference Check 等）。merge 直前の最終 head に対する required check 確認は Step 3-4 hard gate で実施する。
- ローカル検証: bats 913 件 pass（0 fail / 4 skip: 意図的）/ shellcheck green / 構造チェック（skill-references / bash-substitution / test-isolation / frontmatter-parse-guard）green

## Merge 記録

<!-- merge 記録は release Step 3/4 で追記する（テンプレート生成時点では未記録）。 -->

- merge_approved: true（2026-07-11 / semi_auto 自動承認: merge_blocker_any=false / release.ready=true 記録済み）
- merged: 未記録（Step 4 で記録）
