# PRFAQ: AI-DLC Starter Kit v2.5.3 — 振り返り機能の信頼性向上

## Press Release（プレスリリース）

**見出し**: AI-DLC Starter Kit v2.5.3、auto mode 下での独断起票バグや履歴漏れなど振り返り機能の構造的脆弱性 4 件を統合解消

**副見出し**: AI-DLC を採用する全プロジェクトのメタプロセス品質保証の基盤として、retrospective 機能の信頼性を底上げ

**発表日**: 2026-05-08（予定）

**本文**:

[背景] AI-DLC Starter Kit を採用するプロジェクトでは、サイクル末尾の Operations Phase §1 振り返り（retrospective）が次サイクルの Inception Phase で「事前情報」として読み込まれる構造を採用しており、振り返り機能の信頼性は AI-DLC のメタプロセス品質保証そのものを支える。しかし v2.5.2 サイクルの振り返り（[#651](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/651)）で、以下 4 件の構造的脆弱性が顕在化した:

1. **auto mode 下での独断起票バグ**: jailrun v0.3.4 で AI エージェントが対話を経ずに `gh issue create` してしまう実害を確認（[#647](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/647)）
2. **履歴記録の構造的欠落**: Unit 完了時の short note 漏れ / Operations PR マージ前レビュー round 1 のエントリ漏れ（[#637](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/637)）
3. **推測値混入バグ**: 一次情報を Read してもセッション内記憶からの推測値（「約」「approximately」等）が KPT に混入する（[#634](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/634)）
4. **retrospective 系スクリプトの横依存**: `predecessor-issue.sh` が `retrospective-issue.sh` を直接 source する障害伝播リスク（[#643](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/643)）

[プロダクト] v2.5.3 は patch リリースとして 4 件の脆弱性を 4 Unit に分解し統合解消する：

- **Unit 001（#647）**: Operations §1 振り返りステップに「対話必須」明記を追加し、SKILL.md「AskUserQuestion 使用ルール」テーブルへの「振り返り内容の決定」種別追加 + fixture によるドライラン検証
- **Unit 002（#637）**: `aidlc:write-history` skill に `--mode unit-complete-short-note` / `--mode operations-round` の 2 モードを追加。Unit 完了直前の short note 記録と round 1 から開始する Operations レビューエントリ記録を構造化
- **Unit 003（#634 絞込）**: 04-completion §1 に「事実テーブル先抽出ステップ」を追加 + review-flow に「推定値検出ガード」を追加（許容例 / 非許容例併記、根拠リンク併記時の例外条件あり）
- **Unit 004（#643）**: `predecessor-issue.sh` の `retrospective-issue.sh` 横依存を解消し、`aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` の 3 つの責務別 helper に分離

すべての Unit は patch スコープに収まる小規模改修で、後方互換性を完全維持。既存の振り返りフロー / mirror Issue 起票 / `feedback_mode` 設定値の挙動は破壊しない。

[顧客の声]

> 「auto mode で開発スピードを上げたい一方で、AI が振り返り Issue を勝手に作ってしまう運用ミスが怖くて、結局 manual mode に戻していました。v2.5.3 で構造的なガードが入れば auto mode を本格運用できそうです」（Claude Code Opus 4.7 ユーザー / jailrun 開発者）

> 「次サイクルの振り返りで毎回『約 50 round』『推定 35 件』みたいな表現が混じって、あとで一次情報を Read し直す手間がありました。`v2.5.3` で推定値検出ガードが review-flow に追加されると、AI レビュー中に flag されて即時修正できるので助かります」（AI-DLC 採用プロジェクトのメンテナ）

> 「Unit 完了時の short note を書いた覚えがあるのに、振り返り時に history を見ると残っていない、という現象が v2.5.1 で起きました。`/write-history --mode unit-complete-short-note` で構造的に追記できるようになると、次サイクル振り返りで Unit 単位のリアルタイム文脈が再構成しやすくなります」

[今後の展開] v2.5.3 は patch スコープに留めるが、関連する将来サイクルの計画として以下を検討中：

- **v2.5.4 / v2.6.0**: #652（3層検証 skill 化 / jsonl 解析 helper）の取り込み — 振り返り作業の事実テーブル抽出を skill 化し、決定論的な KPT 候補を生成
- **v2.6.x**: #621（mirror Issue 自動重複統合 workflow / GitHub Models 駆動）の導入 — upstream 側でのメンテナ責任を半自動化
- **v2.6.x**: 主因切り分け（プロダクト固有 / Starter Kit 固有 / 両方）の機械判定機構の追加

## FAQ（よくある質問）

### Q1: v2.5.3 を採用すると既存サイクルの履歴ファイルや retrospective.md が壊れますか？

A: いいえ。Unit 002 で追加する `--mode unit-complete-short-note` / `--mode operations-round` は新規モードであり、既存の `--mode` 未指定パスは exit code / 出力フォーマット / 追記位置すべて完全互換です。Unit 004 の helper 分離も関数の物理配置のみが変わり、関数名・引数・戻り値・stderr メッセージは同一を維持します。

### Q2: auto mode で振り返りステップを実行した場合、対話必須ガードは何で発動しますか？

A: `04-completion.md` §1 冒頭に追加される「対話必須」明記と、§1 内の `gh issue create` / `gh api PATCH` 直前の `AskUserQuestion` 必須化記述により、対話なしで Issue 起票に到達するパスが構造的に存在しなくなります。`SKILL.md`「AskUserQuestion 使用ルール」テーブルにも「振り返り内容の決定」種別が auto mode 適用外として追記されます。

### Q3: 推定値検出ガードはどこまで厳密ですか？「約 10 件（DR-001〜DR-010）」のような根拠付き表現も flag されますか？

A: 根拠リンク（PR / Commit / Issue リンク、または対象ファイルパス参照）が同一段落内にあれば flag されません。例えば「DR-001〜DR-010（約 10 件、`requirements/decisions.md` 参照）」は許容され、「DR-001〜DR-010（**約 10 件**）」（リンクなし）は flag されます。詳細な regex は Construction Phase Unit 003 設計で確定します。

### Q4: Unit 004 の helper 分離は CLI 互換性に影響しますか？

A: 影響しません。Unit 004 は「関数の物理配置のみが変わる」refactor であり、`predecessor_resolve_issue` / `retrospective_collect_candidates` 等の公開関数の CLI 引数列・引数名・必須／任意フラグ、exit code、stderr 文言主要行（`predecessor_candidates_emitted` / `info` / `warn` プレフィックス等）はすべて同一を維持します。v2.5.2 サイクルでの `predecessor_resolve_issue v2.5.2` 呼び出しを再生して同等の NDJSON 出力（`milestone_and_label` resolution_path / 4 candidates）が得られることを回帰テストの合格基準としています。

### Q5: jailrun #70 / PR #71 の対応は v2.5.3 に含まれますか？

A: jailrun リポジトリ側の対応（`.aidlc/rules.md` へのローカルルール追加）は jailrun 側で既に実施済（PR #71）。AI-DLC Starter Kit 側では Unit 001 で同等のガードを構造的に整備することで、jailrun 以外のプロジェクトでも再発を予防します。jailrun #70 シナリオ自体は本リポ内 fixture（`.aidlc/cycles/v2.5.3/construction/fixtures/operations-mirror-autodialog.md`）でドライラン検証する形に分離し、外部リポジトリ依存は participatory（参考検証 / non-blocking）に位置付けています。

### Q6: なぜ v2.5.3 を minor（v2.6.0）でなく patch にしたのですか？

A: 4 Unit すべてが docs / steps の改訂と既存スクリプト改修のみで、新機能・破壊的変更・config.toml キー追加を含まないためです。`feedback_mode` の値追加（`mirror-strict` 等）や 3層検証 skill 化（jsonl 解析含む）は意図的に OUT_OF_SCOPE とし、別 Issue（#652 等）で minor 級として扱います。

### Q7: v2.5.2 振り返り（#651）の Try 4 件のうち、v2.5.3 で対応しないものはどれですか？

A: 以下 2 件は別サイクルへ繰り越しとなりました：
- **gh CLI フォールバック自動化**（#626 関連）: token scope 不足時の `gh api PATCH` 自動 fallback wrapper 整備 — 別サイクルで対応
- **post-merge-sync.sh autostash 警告強化**: autostash 発動時の stash list 確認ガイド明示 — 別サイクル

逆に対応する Try 2 件のうち、**review-flow 5R 化の他サイクルへの展開検証** は本サイクル自身が dogfooding として継続観察します。
