# PRFAQ: AI-DLC Starter Kit v2.6.6 — aidlc-retrospective skill 本質的振り返り化

## Press Release（プレスリリース）

**見出し**: AI-DLC v2.6.6 リリース — 振り返り skill が「T の Issue 化」を主軸に再構築

**副見出し**: KPT を集約 Issue にまとめる運用から、Try ごとの実行 Issue 起票 + 構造改善セルフレビュー必須化へ。後方互換オプションで旧動作も維持。

**発表日**: 2026-05-18 想定

**本文**:

[背景] AI-DLC を運用してきたチームから、「振り返り（retrospective）の Issue が大量に積まれるが、Try が個別の『気をつける』チェック追加で済まされて構造改善に繋がらない」「親 retrospective Issue（例: Retrospective: v2.5.2）が low priority に沈み、その中の Try が個別実行追跡されない」といった声が上がっていた。KPT を回すこと自体が達成基準になり、本来の目的（K を継続するため / P を改善するための T を Issue にして実行に繋げる）が後景に追いやられる構造的問題が顕在化していた。

[プロダクト] AI-DLC Starter Kit v2.6.6 は `aidlc-retrospective` skill を再設計し、出力アーティファクトを「実行コミットメントとしての T Issue 群」に統一する。新規 config フラグ `rules.retrospective.aggregate_issue_enabled`（既定 `false`）で集約 retrospective Issue 起票を既定 off とし、代わりに Try 件数分の個別 Issue を起票する。各 T Issue 本文は「背景 / 主因切り分け / 構造課題昇格根拠 / 想定対策 / 関連」の 5 セクション必須で、Issue 単独で意思決定が再現できる。さらに `steps/retrospective.md` §1.2.5 に新ステップ「Try 構造性セルフレビュー」を追加し、AskUserQuestion で「Try が個別チェック追加で逃げていないか / Problem を構造課題に昇格できているか」を必須確認する（差し戻し上限 3 回、上限到達時は `selfreview-capped` ラベル付与で起票許可）。表面的振り返り防止のための 3 問固定判別ガイド（再発性 / 対象レイヤ / 再入余地）も同梱。

[顧客の声] 「振り返り Issue が散発的に作られていたのが、Try 単位で実行追跡できるようになって T が落ちなくなった」「セルフレビューで『これって個別チェック追加で逃げてない？』と問い直されるので、自然と構造改善側の Try に収束する」「`aggregate_issue_enabled = true` を設定すれば旧動作のままにできるので、既存運用への影響を一旦止めて段階的に移行できた」

[今後の展開] v2.7.0+ では `auto_issue_creation` デフォルト `false` 化、`Retrospective: {cycle}` タイトル運用の完全廃止、`retrospective_api_*` の破壊的シグネチャ整理、jsonl 自動検出（パーミッション / プライバシー設計含む）を予定。本リリースは「minor 想定 Issue の patch サブセット適用パターン」(#715) の実例として、starter kit 自身の Decision Record に手順を残す。

---

## FAQ（よくある質問）

### Q1: 既存運用が破壊されますか？

A: 既定動作は変わります（集約 retrospective Issue が既定で起票されなくなり、代わりに Try 件数分の個別 Issue が起票されます）。旧動作を維持したい場合は `config.toml` または `config.local.toml` に `[rules.retrospective] aggregate_issue_enabled = true` を明示設定すれば、v2.6.5 と同等の出力（タイトル / 本文 / ラベル / cap 判定動作）が得られます。同等性は固定 fixture (`tests/fixtures/retrospective_v265_aggregate.json`) + 5 項目差分 0 で CI 保証されます。

### Q2: なぜ patch リリースで既定動作変更を含むのですか？

A: 後方互換オプションで旧動作を完全復元できること、API 破壊変更がないこと、`predecessor_resolve_issue` の既存 5 経路が維持されること、リリースノートで 3 項目（既定変更 / opt-in 復元手順 / predecessor 解決経路）を必須告知することの 4 条件で patch 妥当性を担保しています。本リリースは #715 (minor 想定 Issue の patch サブセット適用パターン SoT 化) の実証実例として位置付けています。

### Q3: §1.2.5 セルフレビューはどう動きますか？

A: §1.2 主因切り分け後・§1.5 Issue 起票前に AskUserQuestion で 3 観点（「気をつける」逃げ / 個別→構造昇格 / 再発防止チェック逃げ）を確認します。「該当する（= 表面的）」と回答すると Try 起草に差し戻されます。差し戻し上限は 3 回で、上限到達時は T Issue に `selfreview-capped` 警告ラベルが自動付与されて起票が許可されます（強制ブロックはしません）。`selfreview-capped` ラベルは runtime で自動作成されるため、ユーザー側の事前準備は不要です。

### Q4: 一次情報三層検証 helper は何ができますか？

A: `cycles/{cycle}/inception/decisions.md` / `construction/units/*-review-summary.md` / `history/*.md` の 3 source から DR 件数・review round 数・指摘件数・defer 件数・時系列イベント等を構造化抽出する opt-in helper です。セッションログ jsonl は file path 引数渡しの opt-in のみサポート（自動検出は v2.7.0+ で予定）。既存 §1.1.5 手動 Read 経路は破壊されず、両経路で同一の事実テーブルを生成できます。

### Q5: 前サイクル（v2.6.5 以前）の振り返り Issue 参照は壊れませんか？

A: 壊れません。`predecessor_resolve_issue` の既存 5 経路（`milestone_and_label` / `label_fallback` / `spool_fallback` / `v2_5_0_compat` / `warn_continue`）は完全に維持され、bats 回帰テストで動作確認されます。v2.6.6 以降の T Issue 群を解決する新動作経路（内部サブ分岐 `t_issue_milestone_scope` / `t_issue_label_fallback`）は追加経路として動作し、既存経路の挙動には影響しません。

### Q6: 関連する GitHub Issue は？

A: 本サイクル PR で以下を記載します:

- **Closes**: #704 (Retrospective skill セルフレビュー観点不在), #652 (振り返り 3 層検証 helper skill 化 / 引数 opt-in までで Close)
- **Comment**: #710 (CLOSED / 振り返り Issue 起票方針見直し / 本サイクルが本体を patch サブセット適用で先取りした旨を記録), #715 (OPEN / minor 想定 Issue の patch サブセット適用パターン SoT 化 / 本サイクル自体が実例)
