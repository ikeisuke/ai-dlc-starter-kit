# Reflect: {{cycle}}

<!--
reflect フェーズ Step 2「KPT 抽出」で生成する成果物。
サイクルの振り返りを Keep / Problem / Try で記録し、Try のうち Issue 化した分を「Issue リンク」章に残す。
AI が KPT を提案し、人間が確認・編集する（明示の承認ゲートはない）。
成果物保存先: .aidlc/cycles/<cycle>/reflect.md（必須 / docs/v3/data-model.md §10）。
trace chain: ... -> release.md -> reflect.md -> 次サイクル define input。
機密情報（トークン・認証情報等）は記載しない。
-->

## Keep

- {{続けてよかったこと（うまくいった点 / 維持したい習慣）}}

## Problem

- {{今サイクルの課題（withdrawn / blocked の理由 / 詰まった点。理由が不明なら unknown と記す）}}

## Try

- {{次サイクルで試す改善（Step 3 で Issue 化候補になる）}}

## Issue リンク

<!--
Step 3 で Issue 化した Try のリンクを記録する。
- 起票成功: #<N>（または URL）
- gh 不可用 / 未起票: PENDING_MANUAL（後で手動起票）
- Issue 化しないと判断した Try は本章に載せない（reflect.md の Try 章には残る）。
-->

- {{Try の要約}} -> {{#<N> または PENDING_MANUAL}}
