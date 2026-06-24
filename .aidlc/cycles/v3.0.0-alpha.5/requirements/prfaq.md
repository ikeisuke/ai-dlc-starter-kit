# PRFAQ: AI-DLC v3 — develop normal/risky 分岐（v3.0.0-alpha.5 / Phase 4）

## Press Release（プレスリリース）

**見出し**: AI-DLC v3 の `develop` が tiny を超えて、通常・高リスクの作業を「ちょうどいい厚み」で完走できるようになりました

**副見出し**: work item の `size`（tiny / normal / risky）と cycle の `depth_level` に応じて、設計・レビュー・テストプラン・rollback note の厚みを自動で調整する develop フロー

**発表日**: v3.0.0-alpha.5（2026-06）

**本文**:

[背景] v3 の `develop` はこれまで `size: tiny` のみ対応し、`normal` / `risky` の work item は「未サポート」として停止していました。実際の開発には小さな修正だけでなく、設計やレビューを要する通常変更や、state model 変更のような高リスク変更が含まれます。全てに同じ儀式を強制すれば重すぎ、何も課さなければ高リスク変更を見落とします。

[プロダクト] Phase 4 では `develop` に size × depth_level 分岐を実装しました。`normal` は簡易 design + code review、`risky` は design + リスク分析 + テストプラン + 複数 review + rollback note と、変更の性質に応じて厚みが変わります。`depth_level`（minimal / standard / comprehensive）と組み合わせ、`data-model.md` §8 マトリクスが唯一の正本として成果物要否を決めます。レビューは既存の `reviewing-construction-*` スキルへルーティングされます。

[顧客の声] 「tiny で軽く回せる手軽さはそのままに、ようやく実機能の追加も v3 で完走できる。高リスク変更だけが自動で重く扱われるので、レビュー漏れの不安が減った」（AI-DLC を使う開発者）

[今後の展開] 次の Phase 5（release）で「全 work item 完了検出 → PR ready → merge → cleanup」を実装し、v3 単独でのフルサイクル（define → develop → release → reflect）完走（Phase 6）と、`/aidlc` = v3 への本流化（Phase 7）へ進みます。

## FAQ（よくある質問）

### Q1: tiny の使い勝手は変わりますか？
A: `tiny + {minimal, standard}` の動作は変わりません（非回帰）。`tiny + comprehensive` のときだけ §8 に従い「短い理由記録」が 1 行追加されますが、design / review は引き続きスキップされます。

### Q2: normal と risky で何が違いますか？
A: `normal` は code review 中心（depth_level により簡易 design を伴う）。`risky` は design + rollback note が必須で、`risky + comprehensive` ではさらにリスク分析 + テストプラン + 複数 review（code + design）が加わります。`risky` は `minimal` を選べません（エラー停止）。

### Q3: レビューは新しい統合スキル（aidlc-review）を使いますか？
A: 本サイクルでは使いません。既存の `reviewing-construction-plan / design / code` へ暫定ルーティングします。9 個のレビュースキルを 1 つに統合する `aidlc-review`（RFC DG-4）は別サイクルで扱います。

### Q4: rollback note やテストプランはどこに保存されますか？
A: 別ファイルは作りません。`designs/<id>-<slug>.md` 内の必須セクション `## Rollback Note` / `## Test Plan` として保持します（v3 の成果物数を増やさない方針）。

### Q5: 設計仕様に矛盾はありませんか？
A: `workflow.md` §3.2（risky 一般の記述）と §6.1（plan/design/code の列挙）は、唯一の正本である `data-model.md` §8 / §6.2 と一部文言が割れています。本サイクルは §8 / §6.2 を正本として実装し、§3.2 / §6.1 の文言整合は該当 Unit の設計で補正します。

### Q6: #733 の振り返り（共有 parser 集約 T1）はこのサイクルですか？
A: いいえ。T1 / T2' / T4 は alpha.4 で完了済みです（Epic #736 番外項目）。本サイクルに残作業はありません。
