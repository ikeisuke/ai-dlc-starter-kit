# PRFAQ: AI-DLC Starter Kit v2.5.2

## Press Release（プレスリリース）

**見出し**: AI-DLC Starter Kit v2.5.2 — review-flow を運用実態に整合化、CI 構造チェックと横断 path resolution を強化

**副見出し**: 5R 化された review-flow、Construction Unit 完了時の 3 種 CI 構造チェック、AIDLC_PROJECT_ROOT 横断対応、Operations 7.12 squash 統合により、千日手・履歴汚染・テスト隔離事故・別リポ運用時の path 不整合を構造的に解消

**発表日**: 2026 年 5 月（patch リリース）

**本文**:

### 背景

v2.5.1 サイクルのメタ振り返りで、review-flow 規定（round 上限 3R）と運用実態（多くの review が 5-6 round に達する）の慢性的な乖離、Construction defer の Operations 流出、Round 4 で発生する千日手、BATS テスト teardown の cwd 依存パターンによる致命バグ（実 v2.5.0 履歴破壊寸前）、AIDLC_PROJECT_ROOT producer/consumer 不整合、Operations Phase 7.12 PR レビュー反映コミットが squash されずに main 履歴に残る問題、の 4 つの構造的課題が実証データとして確認された。これらを放置すると次サイクル以降も同型の問題が再発し、AI-DLC を別リポで利用する開発者にも不整合が伝播する。

### プロダクト（変更内容）

v2.5.2 では以下の 4 Unit を実装する:

- **Unit 001 (#635)**: review-flow round 上限 3R→5R 拡張、完了条件を「最後 2 round 連続で指摘ゼロまたは defer 化」に改定。defer 判定時の AI agent による即時 Issue 起票（必須ラベル: `backlog`, `type:defer-from-review`）、Round 4 以降の新領域指摘の自動 backlog 化（領域キー差分による準機械判定）を追加
- **Unit 002 (#636)**: `bin/check-test-isolation.sh` を新規作成、`scripts/squash-unit.sh` 経由で check-skill-references / check-bash-substitution / check-test-isolation の 3 種を Construction Unit 完了時に必須実行。既存違反は出口条件付き allowlist で一時隔離
- **Unit 003 (#638)**: `skills/aidlc/scripts/lib/aidlc-paths.sh` の新規 helper で AIDLC_PROJECT_ROOT を producer/consumer 両側で統一。`AIDLC_PROJECT_ROOT` 設定下でも全 BATS テスト pass を保証
- **Unit 004 (#639)**: Operations Phase 7.12-7.13 間に Squash サブステップを追加（`git reset --soft + git commit` 非対話方式）、`progress.md` の `release_prep_commit` slot で Squash 起点を確定

### 顧客の声

- **メタ開発者**: 「review が 3R で打ち切れず、上限超過で例外運用していた問題が消える。defer 漏れも構造的に防止される」
- **AI-DLC を別リポで利用する開発者**: 「AIDLC_PROJECT_ROOT 設定下で全 BATS が pass し、producer/consumer が分岐していた path 不整合が解消される」
- **AI エージェント（Claude/Codex）**: 「現実的な 5R 上限と『最後 2 round 連続ゼロ』完了条件で、収束判定が安定する」

### 今後の展開

- **次サイクル候補**: #634 振り返りプロセスの構造的改善（事実テーブル → KPT の二段階化）、#637 履歴記録の構造改善、#640 config.toml 整理
- **将来候補**: 新領域判定の Bash スクリプト自動化、check-test-isolation.allowlist の段階解消（既存違反の正規修正）

## FAQ（よくある質問）

### Q1: なぜ patch リリース（v2.5.2）か？

A: 後方互換性を破壊する変更を含まないため。skill API の呼び出し名・引数仕様、config.toml の既存キー、Operations Phase の `merge_method=merge` などはすべて維持される。新規追加機能（5R 化、3 種 CI チェック、AIDLC_PROJECT_ROOT 横断、release_prep_commit slot）はすべて既存運用を妨げず、未設定時は v2.5.1 と同一動作にフォールバックする。

### Q2: 5R 化は本サイクル自身の review にも適用されるか？

A: はい（自己適用の閉ループ）。Unit 001 完了直後から、本サイクル後続 Unit（B/C/D）の review に 5R 化と「最後 2 round 連続ゼロ」完了条件が適用される。実際、本 Inception の User Stories レビューは 9 round、Unit 定義レビューは 7 round で収束しており、3R 上限を超過しても 5R 完了条件で正常収束することを実証している。

### Q3: AIDLC_PROJECT_ROOT を未設定のまま使い続ける場合、影響はあるか？

A: 影響なし。Unit 003 の helper は `AIDLC_PROJECT_ROOT` 未設定時に v2.5.1 と同一の cwd 相対 path を返すため、本リポ（メタ開発）での動作は変わらない。AIDLC を別リポで利用する場合のみ恩恵を受ける。

### Q4: check-test-isolation で既存違反が大量に検出された場合、リリースは可能か？

A: 可能。Unit 002 では既存違反を出口条件付き allowlist（`file_path<TAB>function_name<TAB>reason<TAB>added_date<TAB>tracking_issue<TAB>expiry_date`）で一時隔離するため、既存違反のままリリース可能。allowlist 内 entry の段階解消は別 Issue として切り出し、後続サイクルで対応する。新規違反（allowlist 外）は exit 1 でブロックされるため、本サイクル以降の新規追加コードは清浄性が保証される。

### Q5: Operations 7.12 Squash 採用時、`merge_method=squash` への変更が必要か？

A: 不要。本実装は `merge_method=merge` 維持下で「PR マージ自体は merge commit を作るが、その内部の中間コミット群は事前 squash する」設計。`merge_method=squash` への変更は別途検討マターとし、本サイクルではスコープ外。

### Q6: `release_prep_commit` slot がない既存サイクル（v2.5.1 以前）で再開した場合の挙動は？

A: `release_prep_commit` slot 未存在時は `squash:skipped:reason=release_prep_commit_missing` を返してスキップする。後方互換性が保たれるため、既存サイクル進行中の Operations Phase 再開で本機能がエラーを発生させることはない。
