# Intent（開発意図）

## プロジェクト名

AI-DLC Starter Kit v2.5.2（patch リリース）

## 開発の目的

v2.5.1 サイクルのメタ振り返りで顕在化した「review-flow 規定の運用実態乖離」「CI 構造チェック不足」「横断 path resolution の producer/consumer 不整合」「Operations Phase 7.12 PR レビュー反映コミットの squash 漏れ」の 4 点を統合的に解消する。これらは v2.5.1 サイクル中に Codex レビュー round 4 / メタ振り返り検証で実証データとして確認されたもので、放置すると次サイクル以降も同型の問題が再発し、千日手・履歴汚染・テスト隔離事故・別リポ運用時の AIDLC_PROJECT_ROOT 不整合を発生させる。

このサイクルでは「v2.5.1 振り返りで確認した実態を v2.5.2 で skill / scripts / CI に反映する」ことを目的とし、振り返りプロセス自体の構造改善（#634, #637）や config.toml 整理（#640）は別サイクルへ defer する。

## ターゲットユーザー

- **メタ開発者**: AI-DLC Starter Kit 自身を開発・保守する開発者
- **AI-DLC を別リポで利用する開発者**: AIDLC_PROJECT_ROOT 横断対応で、本キットを依存として取り込んだプロジェクトでも整合的に動作する
- **AI エージェント（Claude/Codex）**: review-flow 5R 化と defer 即時 Issue 化により、現実的な round 数で完了判定でき、defer 漏れも構造的に防止される

## ビジネス価値

1. **review コスト削減と完了判定の現実化**: review round 上限を 3R→5R に拡張し「最後 2R 連続で指摘ゼロまたは defer 化」を完了条件にすることで、上限超過時の例外運用（「指摘軽減傾向のため継続実施」）が不要になる。defer 即時 Issue 化により Construction defer の Operations 流出を構造的に防止する
2. **CI 構造チェックの早期検出**: Unit 完了時 hook で skill-references / bash-substitution / test-isolation を必須実行することで、Operations Phase まで持ち越さず Construction 内で検出できる。BATS teardown の cwd 依存パターンによる致命的事故（実 v2.5.0 履歴破壊寸前）を構造的に防止
3. **横断 path resolution の整合化**: AIDLC_PROJECT_ROOT を producer/consumer 両側で共通 helper 化することで、AI-DLC を別リポで利用した際の動作整合性を担保する
4. **Operations 履歴の粒度統一**: 7.12 レビュー反映コミットを squash 統合することで、main 履歴に細粒度のレビュー反映コミット（cf5d1682, e90adfac, 84639006, 9a4394ce 等）が残らず、Construction Phase の Squash 動作と整合する

## 成功基準

- review-flow 規定が運用実態に整合し、上限 3R 超過の例外運用が解消される（受け入れ基準: `skills/aidlc/steps/common/review-flow.md` の上限が 5R / 完了条件が「最後 2R 連続で指摘ゼロまたは defer 化」/ defer 自動 Issue 化フロー追加 / Round 4 以降の新領域指摘の自動 backlog 化フロー追加）
  - **5R 化の適用対象（明示）**: `reviewing-construction-{plan,design,code,integration}` / `reviewing-operations-{deploy,premerge}` に加え、`reviewing-inception-{intent,stories,units}` も含む（review-flow.md は全 review 種別の共通ルールを規定するため）
- Construction Unit 完了時に `bin/check-skill-references.sh` / `bin/check-bash-substitution.sh` / `bin/check-test-isolation.sh`（新規）の 3 種が必須実行される（受け入れ基準: `scripts/squash-unit.sh` 経由で 3 種を必須実行 / violation 検出時に Unit 完了が exit 1 でブロック / CI ワークフロー側は既存 `.github/workflows/skill-reference-check.yml` に統合し PR 単位で同 3 種を実行）
- AIDLC_PROJECT_ROOT を設定した状態で全 BATS パスが通る（受け入れ基準: 共通 path resolution helper の実装 / producer (`__retro_spool_path` 等) と consumer (`retrospective-resend.sh` / `predecessor-issue.sh`) 両側で helper 使用 / Issue #631・#632 の close / CHANGELOG への記載）
- Operations Phase 7.12 と 7.13 の間で Squash サブステップが実行され、`merge_method=merge` 設定下でも main 履歴にレビュー反映コミットの中間状態が残らない（受け入れ基準: `steps/operations/operations-release.md` の 7.12-7.13 間に Squash サブステップ挿入（`steps/operations/02-deploy.md` 側ではなく `operations-release.md` を正とする）/ `squash_enabled=false` 時は `squash:skipped` を返して既存契約維持）

## 期限とマイルストーン

- patch リリース（v2.5.2）
- Inception → Construction → Operations の通常フロー
- 4 Unit 構成（現時点案、確定は Inception ストーリー・Unit 定義完了時。下記「Unit 実施順序の前提」と整合）

## 制約事項

- **patch スコープ厳守**: 後方互換性を破壊する変更は行わない。skill API の呼び出し名・引数仕様・config.toml の既存キーは維持する
- **メタ開発の射程**: スキル内リソースの編集は `skills/aidlc/**`（プロジェクトルート相対、META-001 例外）。スキル実行時のリソース参照は常にスキルベース相対パス
- **review_mode=required の遵守**: v2.5.1 で導入された review 必須化は本サイクルでも維持。各 Unit / Inception / Operations の review はスキップ不可
- **`$()` コマンド置換禁止**: `.aidlc/rules.md` のコーディング規約に従い、Bash コードブロック内では `$()` / バッククォートを使用しない
- **本リポ内での自己適用注意**: review-flow 5R 化は本サイクル自体の review にも適用される（自己言及の閉ループ）。CI 構造チェックも CI 強化 Unit 以降は本サイクルの後続 Unit に対して効力を持つ
- **Unit 実施順序の前提**:
  1. **Unit A**: #635 review-flow 5R 化 → 本サイクル後続 Unit の review に 5R 化を適用
  2. **Unit B**: #636 CI 構造チェック強化 → Unit B 自身の Unit 完了時から `check-test-isolation.sh` 必須実行が有効化（Unit B 完了直前に既存 BATS の cwd 依存検証を完了させる）
  3. **Unit C**: #638 AIDLC_PROJECT_ROOT 横断リファクタ
  4. **Unit D**: #639 Operations 7.12 squash 修正
  - 前提逸脱時の扱い: 上記順序を変更する場合、自己適用の閉ループが崩れる可能性があるため、Inception ストーリー・Unit 定義段階で再評価する（Construction 着手後の順序変更は不可）

### #636 CI 構造チェック強化の影響評価（既存機能への影響）

- **失敗時メッセージ仕様**: violation 検出時は exit 1 + stderr に `error\t<check_name>\t<file>:<line>\t<reason>` 形式で 1 件 1 行出力。stdout には影響しない
- **既存 PR への影響**: 本 Unit 完了時点で既存 BATS テストの cwd 依存パターンを事前修正することで CI 失敗増を抑制する。事前検証で発見した違反は Unit B のスコープ内で修正
- **暫定回避不可方針**: violation を残したまま Unit 完了するエスケープハッチは設けない（CI ワークフロー側のスキップフラグも追加しない）。`patch スコープ厳守` および `review_mode=required` の方針と整合
- **必要なテストケース**: `bin/tests/check-test-isolation/` 配下に「ガードあり / ガードなし / 致命パターン（`rm -rf $REPO_ROOT` 等）」の最小 3 ケースを BATS で用意（Unit B 受け入れ基準）

## 含まれるもの（スコープ）

- **#638**: AIDLC_PROJECT_ROOT 横断リファクタ（Epic）— producer/consumer 共通 helper 実装、`retrospective-resend.sh` / `predecessor-issue.sh` の対応、#631 + #632 の close
- **#639**: Operations Phase 7.12 PR レビュー反映コミット squash 修正（`steps/operations/operations-release.md` 7.12-7.13 間への Squash サブステップ追加）
- **#635**: review-flow 5R 化 + defer 即時 Issue 化 + Round 4 新領域指摘の自動 backlog 化（`review-flow.md` と `reviewing-construction-{plan,design,code,integration}` / `reviewing-operations-{deploy,premerge}` / `reviewing-inception-{intent,stories,units}` の各スキルへの 5R 化適用）
- **#636**: Construction Unit 完了時 CI 構造チェック強化（`bin/check-test-isolation.sh` 新規 + `scripts/squash-unit.sh` への組み込み + 既存 `.github/workflows/skill-reference-check.yml` への 3 種チェック統合）

## 含まれないもの（スコープ外）

- **#634** 振り返りプロセスの構造的改善（Epic）— 振り返り skill / steps の二段階化（事実テーブル → KPT）は次サイクルへ defer。スコープが大きく minor 級
- **#637** 履歴記録の構造改善（Unit short note + Operations round 1 エントリ）— write-history skill の改修は次サイクルへ defer
- **#640** config.toml 重複・deprecated セクション整理 — refactor 系で priority:low、本サイクルとは独立に対応可能なため defer
- **その他のバックログ Issue**: #629（PR マージ前サマリ表示）、#621（mirror Issue 自動統合 workflow）、#619（init-cycle-dir.sh のバックログ関連削除）等は別サイクル扱い

## 不明点と質問（Inception Phase中に記録）

（現時点で Question なし。スコープ確定済み）
