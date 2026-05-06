# ユーザーストーリー

## Epic: v2.5.1 振り返り反映 + 優先度高い構造的バグ修正

### ストーリー 1A: review-flow round 上限 5R 化と完了条件改定（#635 の一部）

**優先順位**: Must-have

As a AI-DLC を使う AI エージェント（Claude/Codex）  
I want to review round 上限が 5 に拡張され、完了条件が「最後 2 round 連続で指摘ゼロまたは defer 化」に改定される  
So that 上限 3R 超過時の例外運用（「指摘軽減傾向のため継続実施」）が解消され、現実的な round 数で完了判定できるようになる

**受け入れ基準**:

- [ ] `skills/aidlc/steps/common/review-flow.md` の review round 上限が `5` と明記されている
- [ ] 完了条件が「最後 2 round 連続で指摘ゼロまたは defer 化」と明記されている
- [ ] `skills/aidlc/steps/common/review-flow-reference.md` などのリファレンス文書で round 上限 / 完了条件の記述が同期されている
- [ ] 既存テスト（`bin/tests/` 配下）でレビューフロー記述に依存するものがあれば 5R / 完了条件に追従している
- [ ] 5R 化が `reviewing-construction-{plan,design,code,integration}` / `reviewing-operations-{deploy,premerge}` / `reviewing-inception-{intent,stories,units}` の各スキル文書とリファレンスに反映されている
- [ ] `bin/check-skill-references.sh` が pass する

**技術的考慮事項**:

- 本サブストーリーの改修は本サイクルの後続 Unit（B/C/D）の review に対しても効力を持つ（自己適用の閉ループ）
- ストーリー 1B / 1C と独立: 5R 化単独でもリリース可能（ただし本サイクルでは同一 Unit A 内で完結させる）

---

### ストーリー 1B: review-flow defer 判定時の自動 Issue 起票フロー（#635 の一部）

**優先順位**: Must-have

As a AI-DLC を使う AI エージェント（Claude/Codex）  
I want to review 中の defer 判定時に AI agent 側が即時 `gh issue create` で Issue を起票し、起票結果を review-summary に記録する  
So that v2.5.1 で発生した「Construction defer 指摘がユーザー判断保留により Operations へ流出する」問題が構造的に防止される

**受け入れ基準**:

- [ ] `skills/aidlc/steps/common/review-flow.md` に「defer 判定時に AI agent が `gh issue create` で即時 Issue を起票する」フローが追加されている
- [ ] **起票時のラベル仕様（確定）**:
  - **必須ラベル**: `backlog`, `type:defer-from-review`
  - **任意ラベル**: 該当 Unit 番号ラベル（例: `unit:001`）、`priority:medium` 等の優先度ラベル
  - 必須ラベルが付与されていない Issue は本フロー由来として扱わない（運用上の識別キー）
- [ ] **起票後のラベル検証（必須）**: 起票成功後に `gh issue view <N> --json labels --jq '[.labels[].name]'` で実際に付与されたラベル集合を取得し、必須ラベル `backlog` と `type:defer-from-review` の両方が含まれることを検証する。両方含まれる場合のみ起票成功扱い、いずれかが欠落している場合（ラベル未存在等で `gh issue create --label` が無視された場合を含む）は `PENDING_MANUAL` 扱い（warn 継続 + review-summary に `PENDING_MANUAL` を記録）に統一する
- [ ] 起票成功時（必須ラベル両方付与確認後）は review-summary の「バックログ」列に Issue 番号を記録するルールが明記されている
- [ ] 起票失敗時の異常系扱いが明記されている: `gh issue create` 失敗（`gh_status != available` / 権限不足 / ネットワーク断 / API エラー）の場合は warn 表示のみで review を継続し、review-summary の「バックログ」列に `PENDING_MANUAL` を記録する。review 自体は中断しない
- [ ] 「ユーザー判断に委ねる」「Issue 化保留」等の文言が review-flow.md / 関連 skill から削除されている
- [ ] 既存 v2.5.1 review-summary 記述様式との後方互換性が確認されている（既存記述は読み取り可能、新規記述は新ルール準拠）

**技術的考慮事項**:

- ラベル未存在時の `gh issue create` は実装によりラベル無しで起票成功するか失敗するかが分かれる。受け入れ基準上は「失敗時 warn 継続」で統一する
- Issue 番号取得は `gh issue create` の stdout から `https://github.com/.../issues/<N>` を正規表現でパースする想定

---

### ストーリー 1C: Round 4 以降の新領域指摘の自動 backlog 化（#635 の一部）

**優先順位**: Must-have

As a AI-DLC を使う AI エージェント（Claude/Codex）  
I want to Round 4 以降に発生した新領域の指摘を AI agent が自動で backlog Issue として起票し、同 round 内で対応せず次サイクルへ defer する  
So that v2.5.1 で発生した「Round 4 で新領域に飛び火 → 千日手」の問題が構造的に防止される

**受け入れ基準**:

- [ ] `skills/aidlc/steps/common/review-flow.md` に「Round 4 以降の新領域指摘は同 round 内で対応せず自動 backlog 化（次サイクルへ defer）」フローが追加されている
- [ ] **新領域の判定ルール（正準: 領域キー差分による一次判定）**:
  - **一次判定（正準）**: Round 1〜3 の指摘パスを下記「境界条件」で正規化した領域キー集合 `K_old` と、Round 4 以降の指摘パスを正規化した領域キー集合 `K_new` の差分 `K_new - K_old` に該当する指摘を「新領域指摘」とする
  - **二次判定（補助根拠）**: 一次判定で「新領域指摘」と判定された各指摘について、根拠として原パス（Round 4+ で指摘された具体的ファイルパス）と Round 1-3 で同じ領域キーが指摘されていなかったことの確認ログを review-summary に記録する
  - **判定手順（再現可能、固定）**:
    0. **`内容` 列のパス記法（規約）**: review-summary の「内容」列に記載するパスは、必ず repo-relative の path を backtick で囲む（例: `` `skills/aidlc/scripts/lib/aidlc-paths.sh` ``）。複数パスを 1 件の指摘で記載する場合は、各パスを backtick で囲み `, ` で区切る（例: `` `a.sh`, `b.sh` ``）。コードブロック内のパスは抽出対象外。絶対パスは記載しない（規約違反、起票時に reject 対象）
    1. Round 1〜3 の review-summary 各行から指摘対象パスを抽出（`内容` 列に backtick で囲まれた repo-relative path を正規表現 `` `([^`]+)` `` でマッチさせ、区切りは `, ` を期待。マッチしない場合は warn 表示 + 当該指摘を除外）
    2. 同じく Round 4 以降の review-summary 各行から指摘対象パスを抽出（手順 0 の規約と手順 1 の正規表現を適用、抽出不能時は warn + 除外）
    3. 各パスを上記「境界条件」テーブルで領域キーに正規化
    4. 重複除去 + 文字列昇順ソート → `K_old`（Round 1-3） / `K_new`（Round 4+） を確定
    5. 差分 `K_new - K_old` を計算 → 「新領域キー集合」を確定
    6. review-summary 末尾の追加セクション `## Round 4 新領域判定` に `K_old`, `K_new`, `K_new - K_old` を JSON 配列形式（例: `"K_old": ["scripts/lib", "steps/common"]`）で記録
    7. 各 Round 4+ 指摘について、その指摘パスを領域キーに正規化した結果が「新領域キー集合」に含まれる場合、当該指摘を「新領域指摘」と判定（true/false 二値）
  - 判定は AI agent が上記手順 1〜7 を機械的に実施し、`K_old` / `K_new` / `K_new - K_old` と該当指摘のパス集合を review-summary に記録する
- [ ] 新領域指摘は `gh issue create --label backlog --label type:new-area-from-round4plus` で起票され、本サイクルでは対応しない（同 round の既存領域指摘は通常通り対応）
- [ ] **起票後のラベル検証（必須、ストーリー 1B と同等）**: 起票成功後に `gh issue view <N> --json labels --jq '[.labels[].name]'` で実際に付与されたラベル集合を取得し、必須ラベル `backlog` と `type:new-area-from-round4plus` の両方が含まれることを検証する。両方含まれる場合のみ起票成功扱い、いずれかが欠落している場合（ラベル未存在で `gh issue create --label` が無視された場合を含む）は `PENDING_MANUAL` 扱い（warn 継続 + review-summary に `PENDING_MANUAL` を記録）に統一する
- [ ] **新領域判定の境界条件（完全列挙＋フォールバック）**: パス比較は文字列完全一致ではなく、以下のキー集合に正規化した値同士で同一性を判定する。
  - **完全列挙する領域キー**:
    - `skills/aidlc/scripts/lib/*` → `scripts/lib`
    - `skills/aidlc/scripts/*`（lib 以下を除く） → `scripts`
    - `skills/aidlc/steps/common/*` → `steps/common`
    - `skills/aidlc/steps/inception/*` → `steps/inception`
    - `skills/aidlc/steps/construction/*` → `steps/construction`
    - `skills/aidlc/steps/operations/*` → `steps/operations`
    - `skills/aidlc/templates/*` → `templates`
    - `skills/aidlc/config/*` → `config`
    - `skills/aidlc/agents/*` → `agents`
    - `skills/aidlc/guides/*` / `skills/aidlc/references/*` → `docs/skill`
    - `skills/reviewing-*/**` → `skills/reviewing`
    - `bin/*`（tests を除く） → `bin`
    - `bin/tests/**` → `bin/tests`
    - `tests/**` → `tests`
    - `.github/workflows/*` → `ci`
    - `docs/**` → `docs/repo`
    - `.aidlc/cycles/<cycle>/**` → `cycle-artifacts`
  - **フォールバック規則**: 上記に該当しないパスは、リポジトリルートからの第一階層ディレクトリ名を領域キーとする（例: `Makefile` → `root`、`foo/bar.txt` → `foo`）。リポジトリルート直下のファイルは `root` キーに集約する
- [ ] 起票失敗時の異常系扱いが明記されている: ストーリー 1B と同様（warn 継続 + `PENDING_MANUAL` 記録）

**技術的考慮事項**:

- 新領域判定は上記「判定手順 1〜7」に基づく**準機械判定（AI agent が機械的手順を実施）**とする。Bash スクリプトでの自動化までは本サイクルではスコープ外（次サイクル候補）
- ストーリー 1B と独立: 1B が動作していない場合でも 1C は新領域指摘の発生時のみトリガーされる

---

### ストーリー 2: Construction Unit 完了時 CI 構造チェック強化（#636）

**優先順位**: Must-have

As a AI-DLC スターターキットの保守者  
I want to Unit 完了時に `check-skill-references.sh` / `check-bash-substitution.sh` / `check-test-isolation.sh`（新規）の 3 種のチェックが必須実行され、`squash-unit.sh` 経由で violation 検出時に Unit 完了が exit 1 でブロックされる  
So that スキル参照ずれ・コマンド置換違反・BATS テストの cwd 依存パターン（実 v2.5.0 履歴破壊寸前と同型の致命バグ）が Construction Phase 内で検出され、Operations Phase まで持ち越されない

**受け入れ基準**:

- [ ] **検査対象関数（確定）**: `bin/check-test-isolation.sh` が新規作成され、`tests/**/*.bats` を走査して BATS 関数（`teardown` / `teardown_file` / `setup` / `setup_file` / `@test`）内の `rm -rf` 呼び出しを検出する
- [ ] **ガード判定の厳密ルール（静的解析可能）**: 上記 BATS 関数内において、`rm -rf` の呼び出し前に同一関数内で `cd "$BATS_TMPDIR"` / `cd "$BATS_TEST_TMPDIR"` / `cd "$BATS_FILE_TMPDIR"` / `cd "$TMP"` / `cd "$(mktemp -d ...)"` のいずれかが先行していない場合は violation。判定は 1 関数（`{` 〜 `}` または `function ... {` 〜 `}` または BATS 標準の `teardown() { ... }`）単位で行う
- [ ] **致命パターン**: `rm -rf "$REPO_ROOT"` / `rm -rf .aidlc/...` / `rm -rf "$(pwd)"` / `rm -rf $HOME/...` のような cwd 依存または絶対パス危険パターンを致命として検出（exit 1 + `severity:fatal` を stderr に追加）
- [ ] violation 検出時は exit 1 + stderr に `error\t<check_name>\t<file>:<line>\t<reason>` 形式で 1 件 1 行出力する
- [ ] `scripts/squash-unit.sh` が check-skill-references / check-bash-substitution / check-test-isolation の 3 種を必須実行し、いずれかが exit 1 を返す場合 Unit 完了をブロックする
- [ ] `.github/workflows/skill-reference-check.yml` に check-bash-substitution / check-test-isolation が統合され、PR 単位で同 3 種が実行される
- [ ] `bin/tests/check-test-isolation/` 配下に「ガードあり / ガードなし / 致命パターン（`rm -rf $REPO_ROOT` 等）」の最小 3 ケースが BATS で用意されている
- [ ] 既存の `tests/**/*.bats` で違反がない（事前検証で発見した違反は本 Unit で修正）
- [ ] 暫定回避フラグ（CI スキップ等）を追加していない

**技術的考慮事項**:

- 関数スコープ判定は `awk` で `function foo() {` から対応する `}` までを 1 関数として識別する実装を想定（多階層 `{}` のネストはマッチング深度カウンタで管理）
- 本 Unit の Unit 完了時点から自身の violation 検出が有効化されるため、Unit 完了直前に既存 BATS の cwd 依存検証を必ず完了させる
- 既存 PR への影響: 違反がない状態を本 Unit 内で確保することで CI 失敗増を抑制する

---

### ストーリー 3: AIDLC_PROJECT_ROOT 横断 path resolution リファクタ（#638、Epic for #631+#632）

**優先順位**: Must-have

As a AI-DLC を別リポジトリで利用する開発者  
I want to retrospective spool / predecessor 互換 path 解決が producer/consumer 両側で `AIDLC_PROJECT_ROOT` を尊重する共通 helper 経由に統一され、`AIDLC_PROJECT_ROOT` を設定した状態で全 BATS テストが pass する  
So that 別リポで AI-DLC を利用した際に producer/consumer 間で path が分岐する問題が解消され、千日手の原因となった Codex 横断レビューでの新領域指摘の発生源が無くなる

**受け入れ基準**:

- [ ] `skills/aidlc/scripts/lib/` 配下に共通 path resolution helper（`aidlc-paths.sh`）が新規作成されている
- [ ] helper は `aidlc_cycle_path <cycle> <subpath>` 関数を提供し、`AIDLC_PROJECT_ROOT` 設定時は `<AIDLC_PROJECT_ROOT>/.aidlc/cycles/<cycle>/<subpath>`（AIDLC_PROJECT_ROOT の値そのものを基準とする。絶対パスとは限らない）、未設定時は cwd 相対の `.aidlc/cycles/<cycle>/<subpath>` を返す
- [ ] **AIDLC_PROJECT_ROOT 異常値時の挙動（明示）**:
  - 空文字 / 未設定: 未設定扱い（cwd 相対にフォールバック）
  - 相対パス: `<AIDLC_PROJECT_ROOT>/.aidlc/cycles/<cycle>/<subpath>` として連結（絶対化はしない。値そのものを基準とする）
  - 末尾に空白を含む文字列: そのまま連結（trim しない。明示的な値の場合は呼び出し側責務）
  - 存在しないパス: helper 自体は存在チェックを行わない（呼び出し側が `[[ -d ]]` / `[[ -f ]]` で判定する責務）
  - 上記方針の理由: helper は単純な path 連結関数であり、絶対パス化や validation は呼び出し側責務とする（既存 `__retro_spool_path` の動作と整合）。返却値の絶対パス保証は本ストーリーのスコープ外
- [ ] `scripts/retrospective-resend.sh` の `SPOOL_PATH` 算出が helper 経由に変更されている
- [ ] `scripts/lib/predecessor-issue.sh` の `compat_path` / `spool_path` 算出が helper 経由に変更されている
- [ ] producer 側 `scripts/lib/retrospective-issue.sh` の `__retro_spool_path` も helper 経由に統一されている（producer/consumer 整合）
- [ ] `AIDLC_PROJECT_ROOT` を設定した状態で `bin/tests/` 配下の全 BATS テストが pass する
- [ ] 設定なしでも全 BATS テストが pass する（後方互換性）
- [ ] **Issue #631 / #632 の close に必要な技術条件が満たされている**: (1) helper 経由の path 解決が producer/consumer 両側で実装済み、(2) `AIDLC_PROJECT_ROOT` 設定時の BATS 再現テストが pass、(3) 修正範囲を裏付ける git diff（`scripts/retrospective-resend.sh` / `scripts/lib/predecessor-issue.sh` / `scripts/lib/retrospective-issue.sh` / `scripts/lib/aidlc-paths.sh`）が確認可能 — の 3 点。**Issue の実際の close 操作は本ストーリーの DoD ではなく、Operations Phase 6.x（バックログクリーンアップ）と運用チェックリストへ分離する**
- [ ] CHANGELOG に AIDLC_PROJECT_ROOT 横断対応を記載する
- [ ] `bin/check-bash-substitution.sh` / `bin/check-skill-references.sh` が pass する

**技術的考慮事項**:

- helper は多重 source ガード `__AIDLC_PATHS_SH_LOADED` を採用する（既存パターンに合わせる）
- `predecessor-issue.sh` を zsh から `source` した際の `BASH_SOURCE` 解決失敗（本サイクル開始時に検証済）は本ストーリーのスコープ外（zsh 互換性は別 Issue）

---

### ストーリー 4: Operations Phase 7.12 PR レビュー反映コミットの squash 統合（#639）

**優先順位**: Must-have

As a AI-DLC スターターキットを利用する開発者  
I want to Operations Phase の 7.12（PR マージ前レビュー）と 7.13（PR マージ）の間に Squash サブステップが実行され、`squash_enabled=true` 設定下では 7.12 で発生した複数 round のレビュー反映コミットが 1 コミットに squash 統合される  
So that `merge_method=merge` 設定下でも main 履歴に細粒度のレビュー反映コミット（v2.5.1 の cf5d1682, e90adfac, 84639006, 9a4394ce 等）が残らず、Construction Phase の Squash 動作と整合した粒度で履歴が記録される

**受け入れ基準**:

- [ ] `skills/aidlc/steps/operations/operations-release.md` の 7.12 と 7.13 の間に Squash サブステップが追加されている
- [ ] Squash サブステップは Construction Phase の `commit-flow.md` Squash 統合フローを再利用する形で実装されている
- [ ] **Squash 対象範囲のソース（確定）**: `.aidlc/cycles/<cycle>/operations/progress.md` 内に 7.7 完了時の commit hash を新規スロット `release_prep_commit` として記録する（progress.md 採用、環境変数は不採用）。Squash サブステップはこの slot から起点 hash を取得し、`HEAD` までの追加コミット群を対象として squash する
- [ ] `release_prep_commit` slot は v2.5.2 サイクルから新規追加。既存サイクル（v2.5.1 以前）の progress.md には存在しないため、未存在時は `squash:skipped:reason=release_prep_commit_missing` を返してスキップする（後方互換性 + 既存サイクル再開時の安全性）
- [ ] `squash_enabled=true` の場合、上記範囲の追加コミット群が 1 コミットに squash される
- [ ] `squash_enabled=false` の場合、`squash:skipped:reason=disabled` を返して既存契約を維持する（後方互換性）
- [ ] **Squash 実行失敗時の契約（追加異常系）**:
  - **対象コミット 0 件**（`release_prep_commit` から HEAD まで追加コミットなし）: `squash:skipped:reason=no_commits` を返して継続（block しない。7.13 への進行を妨げない）
  - **`git rebase` / `git commit` 失敗**: `squash:failed:reason=git_op_failed:<exit_code>` を返して Operations Phase を block（exit 1）。失敗時は git の状態を `git rebase --abort` 等でクリーンアップし、失敗前の状態に戻す（rollback）。ユーザーに手動対応を案内するメッセージを表示する
  - **コンフリクト発生**: `squash:failed:reason=conflict` を返して Operations Phase を block（exit 1）。`git rebase --abort` で rollback し、ユーザーに手動 squash を案内する
  - **異常終了時の状態**: 失敗時は必ず `git rebase --abort` などで作業ツリーが Squash 開始前の状態に戻ること（rollback 保証）。残骸（中間 .git/rebase-merge ディレクトリ等）を残さない
- [ ] Squash 後に 7.13 の pre-flight check（`validate-git.sh uncommitted` / `merge-pr` の `pre-merge-uncommitted-detected`）が引き続き正しく動作する
- [ ] 検証手順の再現性: `release_prep_commit` slot の記録 → 7.12 で複数コミット追加 → Squash サブステップ実行 → `git log <release_prep_commit>..HEAD --oneline` が 1 行（squash 後コミット）になることを確認できる
- [ ] CHANGELOG に Operations Phase の squash 対応追加と `release_prep_commit` slot 追加を記載する
- [ ] `bin/check-skill-references.sh` が pass する

**技術的考慮事項**:

- `merge_method=merge` を維持しつつ、その内部の中間コミット群のみ事前 squash する設計（`merge_method=squash` への変更ではない）
- 7.12 で `pre-merge-uncommitted-detected` ガードが既に存在するため、Squash サブステップの前後で git の状態整合（`uncommitted=ok`）を保つ
- 7.7 で `release_prep_commit` slot を progress.md に記録する処理は本ストーリーで追加実装する（7.7 を最小限改修）

---

## サマリ

| # | ストーリー | 優先順位 | 関連 Issue | 担当 Unit |
|---|----------|---------|-----------|----------|
| 1A | review-flow round 上限 5R 化と完了条件改定 | Must-have | #635 | Unit A |
| 1B | review-flow defer 判定時の自動 Issue 起票フロー | Must-have | #635 | Unit A |
| 1C | Round 4 以降の新領域指摘の自動 backlog 化 | Must-have | #635 | Unit A |
| 2 | Construction Unit 完了時 CI 構造チェック強化 | Must-have | #636 | Unit B |
| 3 | AIDLC_PROJECT_ROOT 横断 path resolution リファクタ | Must-have | #638（Epic for #631, #632） | Unit C |
| 4 | Operations Phase 7.12 PR レビュー反映コミットの squash 統合 | Must-have | #639 | Unit D |

全ストーリーが Must-have（patch リリースのスコープ厳守）。優先順位による sequence は Intent 制約事項「Unit 実施順序の前提」に従う（Unit A → B → C → D）。Unit A 内の 1A/1B/1C は独立した受け入れ基準を持ち、INVEST の Independent/Small を確保する。
