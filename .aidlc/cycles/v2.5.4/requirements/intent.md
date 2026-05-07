# Intent（開発意図）

## プロジェクト名

ai-dlc-starter-kit v2.5.4 — Operations / worktree / レビュー運用の構造的健全化

## 開発の目的

v2.5.3 リリース直後の振り返りと運用再開で顕在化した **5 件の構造的脆弱性 / 運用ノイズ** を統合解消する patch リリース（v2.5.4 Construction Phase 着手後に Unit 005 を追加した hotfix 拡張）。

1. **Operations §7 ステップ7「完了」更新タイミングの曖昧さ**（[#656](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/656)）— v2.5.3 Operations Phase で AI が PR マージ後に `progress.md` を更新してマージ前完結契約違反を起こした。`02-deploy.md` §7 と `04-completion.md` の記述が「マージ前 / マージ後」どちらに「完了」更新を確定させるか曖昧で、AI が解釈を誤った構造的問題を解消する
2. **worktree 環境立ち上げ時のメインリポ health check 不在**（[#657](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/657)）— v2.5.3 Operations Phase で `post-merge-cleanup.sh` がメインリポジトリの `git checkout main` で失敗。原因は過去の `git stash pop` 残骸（コンフリクトマーカー未解決）の放置だった。Operations Phase の終盤ではなく開始時に検出する health check を追加する
3. **設計レビュー 5R 到達時の千日手・議論密度ガード弱化**（[#658](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/658)）— v2.5.3 Unit 004 で設計レビューが 5R（最大）に到達。現状の千日手検出（過去 5R 中 3R 連続同種）は設計レビュー特有の議論密度・後半での仮説追加・個別点漸進パターンを早期検出できない。設計レビュー特化の早期 defer 判断ガイドを追加する
4. **`predecessor-issue.sh` の zsh source 互換性問題**（v2.5.3 リリース直後に判明、Issue 未起票）— `predecessor_resolve_issue` 関数を zsh interactive shell で `source && 関数呼び出し` した場合に `BASH_SOURCE` 解決が失敗。bash で実行すれば動くが、AI エージェントが手順記述に従って zsh シェルから直接 source する経路が壊れている。AI-DLC で AI エージェントが手順記述通りに source 呼び出しする全 helper の zsh 互換性を網羅的に確認・修正する
5. **AI レビュー完了条件 `last_two_rounds_clean` の冗長性**（v2.5.4 Unit 002 計画レビュー時にユーザー指摘、Issue 未起票 / 内部 hotfix）— v2.5.2 で導入された 5R 化の完了条件「最後 2 round 連続 clean」は、Round 1 で指摘 → Round 2 で全 resolve しても完了せず Round 3 を強制する冗長な仕様。`last_round_clean`（直近 round が clean）で完了する形に緩和し、本サイクル後続 Unit（002〜004）のレビュー所要時間を即時短縮する

## ターゲットユーザー

- AI-DLC Starter Kit を採用しているプロジェクト開発者（特にメタ開発・worktree 環境利用者）
- v2.5.3 リリースで初めて顕在化した運用エッジケースに遭遇したユーザー
- AI エージェントが auto mode で Operations Phase を完走する場面（マージ前完結契約遵守が AI 規律に依存している）

## ビジネス価値

- **マージ前完結契約違反の構造的予防** — Operations §7 の状態遷移タイミングを明示的にすることで、AI agent が解釈を誤って契約違反を起こすリスクをドキュメントレベルで構造的に消す
- **worktree 環境の運用診断強化** — Operations 終盤の post-merge-cleanup 失敗ではなく開始時に環境異常を検出することで、サイクル所要時間を短縮し、ユーザーの手動復旧手順への到達を早める
- **設計レビュー千日手の早期検出** — v2.5.3 Unit 004 のような設計レビュー 5R 到達ケースで、Round 3 終了時点で defer 判断のアラートを出すことで、Construction Phase の停滞リスクを抑制する（本サイクルでの担当は Unit 003）
- **AI エージェント呼び出し経路の互換性保証** — zsh / bash どちらの shell で source されても helper が動作するよう保証することで、複数の AI エージェント実装（Claude Code / 他）からの利用可能性を担保
- **AI レビュー所要時間の構造的短縮** — `last_round_clean` 化により Round 1 指摘→ Round 2 全 resolve で 2R 完了が可能となり、Construction Phase の AI レビュー所要時間を 1〜2 round 分削減する（本サイクル後続 Unit に即時適用）

## 含まれるもの（Unit 想定 5 件、Unit 005 は Construction Phase 着手後の hotfix 追加）

| Unit 候補 | 対象 Issue | 概要 |
|----------|-----------|------|
| Unit 001 | [#656](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/656) | Operations §7 ステップ7「完了」更新タイミングをマージ前に統一 — `steps/operations/02-deploy.md` §7 内の状態遷移記述を §7.7 Git コミット時に確定する形へ書き換え、`steps/operations/04-completion.md` のマージ前完結ルールと整合 |
| Unit 002 | [#657](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/657) | worktree 環境立ち上げ時のメインリポジトリ health check を追加 — Operations Phase **開始時（`01-setup.md` から必須呼び出し）** に、メインリポの `git status --porcelain` / `MERGE_HEAD` 有無 / コンフリクトマーカー scan を実施する health check helper を新設 |
| Unit 003 | [#658](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/658) | 設計レビュー 5R 到達時の千日手・議論密度ガード強化 — `steps/common/review-flow.md` に設計レビュー特化の早期 defer ガイド（Round 3 終了時 OUT_OF_SCOPE 推奨アラート / Round 4 以降の新規仮説追加検出 / 議論密度警告）を追加 |
| Unit 004 | [#659](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/659) | `predecessor-issue.sh` 等 helper の zsh source 互換性 **必須対象 1 ファイル修正 + 全 helper の zsh source テスト追加** — 必須修正対象は `predecessor-issue.sh`（v2.5.3 で実害発生済み）。テスト追加対象は全 helper 6 ファイル（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `predecessor-issue.sh` / `retrospective-issue.sh`）の zsh source 動作確認 |
| Unit 005 | （内部 hotfix / Issue 起票なし） | AI レビュー完了条件を `last_round_clean` に緩和 — `skills/aidlc/steps/common/review-flow.md` の「完了条件の判定単一仕様」と `skills/aidlc/templates/review_summary_template.md` を更新し、Round 1 指摘→ Round 2 全 resolve で完了できるようにする。**Unit 002 / 003 / 004 のレビュー前に最優先で実装**することで本サイクル内に新ルールを即時適用する |

## 除外するもの（OUT_OF_SCOPE）

- **[#652](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/652)** 振り返り 3層検証手順の skill 化（jsonl 解析 helper 含む）— 規模大、本サイクル patch スコープ外。次サイクル以降で対応
- **[#648](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/648)** suggest-permissions の acknowledgedFindings 機構 — 規模中、本サイクル patch スコープ外
- **[#643](https://github.com/ikeisuke/ai-dlc-starter-kit/issues/643)** の追加リファクタ — Unit 004 で `predecessor-issue.sh` の zsh 互換性のみ対応し、責務分離の追加リファクタ（aidlc-paths.sh の更なる集約等）は OUT_OF_SCOPE

## 成功基準

| Unit | 検証方法 | 合格条件（定量） |
|------|---------|----------------|
| Unit 001 | (a) `grep -E "ステップ7.*完了" steps/operations/02-deploy.md` で「§7.7 Git コミット時」または「§7.X 完了時」の明示が **1 箇所以上**<br>(b) `02-deploy.md` §7 のステップ7「完了」更新記述行 と `04-completion.md` のマージ前完結ルール記述行 を grep で抽出し、両者が指すサブステップ番号（§7.7 等）が一致することを目視確認（**矛盾サブステップ番号 0 件**）<br>(c) ドライラン: v2.5.4 自身の Operations Phase で AI が `progress.md` ステップ7 を §7.7 Git コミット時に「完了」更新し、§7.13 マージ後に追加編集をしないことを確認（**マージ後の `progress.md` 編集 0 回**） | (a)(b)(c) すべて合格 |
| Unit 002 | (a) `scripts/main-repo-health-check.sh`（または同等の helper）が新設されており、main repo の `unmerged paths` / `MERGE_HEAD` / コンフリクトマーカー scan の **3 項目すべて**を実施し、終了コードは `skills/aidlc/guides/exit-code-convention.md` 規約準拠（**`0`**: 健全+警告検出 / **`1`**: バリデーションエラー（本 helper では通常非発生） / **`2`**: システムエラー）。警告は stdout の `status:warning` および `health-check:<項目>:warning:<detail>` で通知<br>(b) **`steps/operations/01-setup.md` から health check 呼び出しが必須追加**（`04-completion.md` のみへの追加では不合格）。呼び出し側は stdout の `status:warning` を判定（exit code は使わない）<br>(c) ドライラン: v2.5.3 で発生した stash pop 残骸シナリオ（review-flow.md にコンフリクトマーカー 6 件が残る状態）を fixture で再現し、health check が **exit 0 + stdout `status:warning` + `health-check:conflict-marker:warning:<detail>` 1 件以上**で検出 | (a)(b)(c) すべて合格 |
| Unit 003 | (a) `grep -E "Round 3.*defer\|議論密度" steps/common/review-flow.md` で設計レビュー特化の defer ガイド記述が **1 箇所以上**<br>(b) Round 別指摘件数の閾値（例: Round 3 で指摘 ≥ 5 件警告）が **明示的に数値で記載**<br>(c) Round 4 以降の新規仮説追加検出ロジックが文書化 | (a)(b)(c) すべて合格 |
| Unit 004 | (a) **必須修正対象 1 ファイル**: `bash` / `zsh -c` 両方で `source skills/aidlc/scripts/lib/predecessor-issue.sh && predecessor_resolve_issue v2.5.3` が exit 0 で動作（v2.5.3 で実害発生済み）<br>(b) `__PRED_SCRIPT_DIR` の SCRIPT_DIR 解決が `BASH_SOURCE` だけに依存しない代替経路を持つ（zsh での挙動を含めて確認）<br>(c) **テスト追加対象 6 ファイル**: helper 群（`aidlc-paths.sh` / `aidlc-validate.sh` / `aidlc-gh.sh` / `aidlc-spool.sh` / `predecessor-issue.sh` / `retrospective-issue.sh`）すべてで zsh source 動作確認のテストが追加（**追加テスト 6 件以上**） | (a)(b)(c) すべて合格。**修正対象は (a) の 1 ファイルに限定し、他の 5 ファイルはテスト追加のみで構造変更しない**（patch スコープ保護） |
| Unit 005 | (a) `skills/aidlc/steps/common/review-flow.md` の「完了条件の判定単一仕様」セクションが `last_round_clean` ベース（直近 round が clean なら完了）に書き換えられている。`last_two_rounds_clean` の記述が **0 件**（grep で確認）<br>(b) `1R clean 特例` は `last_round_clean` の自然な帰結として吸収されているか、または独立記述として残しても矛盾しない（規則の重複・矛盾なし）<br>(c) `5R 上限・defer 自動 Issue 起票・千日手検出・Round 4+ 新領域 backlog 化` は維持（`grep -E "5 ?R\|5\\s*round\|千日手\|new-area-from-round4plus" skills/aidlc/steps/common/review-flow.md` で **既存記述が残ること**）<br>(d) `skills/aidlc/templates/review_summary_template.md` の反復回数表記補注が新ルールと整合<br>(e) **本サイクル後続 Unit（002〜004）のレビューで新ルールが即時適用される**（実装順序として Unit 005 を Unit 002 より前に完了させる） | (a)(b)(c)(d)(e) すべて合格 |

## 期限とマイルストーン

- patch リリース v2.5.4 として 1 サイクル内で完了
- 全 Unit を Inception → Construction → Operations 一気通貫で実施

## 制約事項

- **後方互換**: 既存の Operations Phase progress.md / history / Operations release scripts の挙動を破壊しない（記述変更のみで構造変更なし）
- **patch スコープ**: 破壊的変更なし。設定ファイル（config.toml）のキー追加・名称変更は行わない
- **review-flow 5R 化**: v2.5.2 で導入された 5R 上限 / defer 自動 Issue 起票 / 千日手検出 / Round 4+ 新領域 backlog 化は本サイクルでも継続適用。**Unit 005 は完了条件のみを `last_two_rounds_clean` → `last_round_clean` に緩和し、5R 化の他要素は維持する**
- **メタ開発前提**: スキルファイル変更は `skills/aidlc/SKILL.md` の本文 500 行制限を遵守
- **Unit 005 実装順序**: Unit 005（review-flow 完了条件緩和）は **Unit 002 より前に実装**する。これにより Unit 002〜004 のレビューに新ルールが即時適用される
