# PRFAQ: v3 release フロー（Phase 5）

## Press Release（プレスリリース）

**見出し**: AI-DLC v3 が `define → develop → release` を通しで提供 — main への安全な取り込みまで v3 単独で完結

**副見出し**: release フェーズの実装により、work item 完了後の PR 整備・レビュー・merge・後始末を v3 の一貫した手順で扱えるようになります。

**発表日**: v3.0.0-alpha.6（Phase 5 サイクル）

**本文**:

[背景] v3 リニューアル（`skills/aidlc-v3`）は Phase 4（develop normal/risky 分岐）までで「要件定義から実装まで」を v3 単独で回せるようになりました。しかし release フローが未実装で、work item 完了後の「main に安全に取り込む」工程（PR 整備・レビュー・merge・cleanup）を v3 の手順で扱えませんでした。この最後の歯抜けが、v3 をスキルとして通しで使える状態（Phase 6 完了）への障壁でした。

[プロダクト] Phase 5 では `skills/aidlc-v3/steps/release.md` と `templates/release.md` を新規実装し、release フェーズの Step 1–4（リリース準備 / PR 整備 / Merge 承認・実行 / Post-merge）を提供します。全 work item の完了を検出するゲート、PR の作成・ready 化と state.json への状態記録、観点別レビュー（premerge 常時 / integration 複数時 / deploy risky 時）のルーティング、merge 前の承認記録、merge 後の cleanup を、既存の state スクリプトと reviewing スキルを再利用して構成します。v2 Operations Phase の多数の step / script / 固定スロットに対し、release を約 150–200 行の手順 + テンプレート + 既存資産の再利用で実現し、v3 の設計目標「読み込み量・成果物数の削減」を release フェーズでも実証します。

[顧客の声] 「work item を develop し終えたら `release` を実行するだけで、PR 整備からレビュー、merge、ブランチの後始末までが一貫した手順で進む。merge 承認が state.json に残るので、後から『誰が承認したか』も追える」（AI-DLC を使う開発者）。

[今後の展開] Phase 6（reflect + doctor）で v3 単独フルサイクル完走が可能になり、Phase 7（dogfooding + 本流化）で `/aidlc` = v3 に置き換わります。

## FAQ（よくある質問）

### Q1: このサイクルで v3 の release フローを使って alpha.6 自身をリリースするのですか？
A: いいえ。Phase 5 は release フローの「実装」が責務です。alpha.6 自身のリリースは引き続き v2（`/aidlc operations`）で行います。v3 を使った自己リリース（dogfooding）は Phase 7 です。

### Q2: state.json の schema は変わりますか？
A: 変わりません。release で使う 3 フィールド（`release.pr_number` / `release.ready` / `release.merge_approved`）は `docs/v3/data-model.md §3` で確定済みです。Phase 5 はこれらへの書き込み手順を実装するだけで、schema は変更しません。

### Q3: なぜ `release.merge_approved` を merge の前に記録するのですか？
A: merge 後は feature ブランチが消えるため、承認記録もろとも失われます。merge 前の最終コミットで記録することで、merge 後にも「merge を承認した」証拠が state.json に残ります。complete 判定は、この承認記録と PR の実態（実際に merged か）の両方が揃ったときに成立します（`data-model.md §5.1`）。

### Q4: レビューは v3 独自の新しい仕組みになるのですか？
A: いいえ。9 個の reviewing スキルを 1 つに統合する（`aidlc-review`）のは後続 Phase の作業です。Phase 5 では既存の reviewing スキル（premerge / integration / deploy）へ `review-routing` 経由で委譲します。develop の code/design レビューと同じ方式です。

### Q5: tag や changelog は必ず作られますか？
A: いいえ。tag（`version_tag`）と changelog（`changelog`）は設定による opt-in です。既定では作られず、opt-out でも release フローは正常に完了します（core ワークフロー成立に不要）。GitHub Milestone close / Release 自動作成 / Projects 登録なども v3 では core から外します。

### Q6: Unit はどう分割されていますか？
A: 線形依存の 4 Unit です。001（release 骨格 + リリース準備ゲート）→ 002（PR 整備 + release.md テンプレート + review ルーティング）→ 003（merge 承認・実行 + post-merge）→ 004（SKILL.md 統合 + express 整合 + テスト・回帰）。`release` コマンドの利用者向け有効化は、Step 1–4 とテストが揃う Unit 004 で行います。
