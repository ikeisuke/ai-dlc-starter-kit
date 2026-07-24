# Release: {{cycle}}

<!--
release フェーズ Step 2「PR 整備」で生成する成果物。
PR 概要 / work item 完了一覧 / review 結果サマリ（機械可読）/ CI 状態 / merge 記録を集約する。
release-level review（premerge / integration / deploy）の結果は本ファイルに集約し reviews/*.md は生成しない
（docs/v3/data-model.md §8 / §10）。merge 記録は Step 3/4 で追記する。
-->

## PR 概要

- PR: #{{pr_number}}
- base: {{integration_branch}}
- head: {{head_branch}}
- {{この release で main に取り込む内容の要約（1-3 行）}}

## Work Item 完了一覧

| id | status | size |
|----|--------|------|
| {{id}} | {{done または withdrawn}} | {{tiny / normal / risky}} |

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
    status: skipped
    unresolved_count: 0
    max_severity: none
    merge_blocker: false
    skip_reason: "status:done が 1 件のため未実行（条件: 2 件以上）"
  - perspective: deploy
    status: skipped
    unresolved_count: 0
    max_severity: none
    merge_blocker: false
    skip_reason: "size:risky の done が 0 件のため未実行（条件: 1 件以上）"
merge_blocker_any: false
<!-- aidlc-release-review:end -->

## CI 状態

- conclusion: {{success|failure|pending|none|unavailable}}
- {{CI 確認に使ったブランチ / コミット / 補足。gh 不在・CI 未設定時はその旨}}

## Merge 記録

<!-- merge 記録は release Step 3/4 で追記する（テンプレート生成時点では未記録）。 -->

- merge_approved: {{未記録（Step 3 で記録）}}
- merged: {{未記録（Step 4 で記録）}}
