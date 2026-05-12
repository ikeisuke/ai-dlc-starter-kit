# Construction Phase 履歴: Unit 05

## 2026-05-12T09:39:29+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-gh-project-side-effect-bats（gh-project 副作用 bats テスト整備（gh API モックフレームワーク））
- **ステップ**: AIレビュー完了
- **実行内容**: 計画承認前 AI レビュー (reviewing-construction-plan / focus=architecture / codex) を 2 round 実施し、ReviewSession.is_completed() = completed で確定。

Round 1 (session-id: 877479): 4 件指摘
- 高 #1: 完了条件チェックリストが全項目 [x] になっており、承認ゲートとして機能しない（[ ] が妥当）
- 中 #2: probe-github-project.bats ケース 2 で gh project item-delete 検証を要求しているが、実装は gh_project_repo_delete_issue 経由で gh issue delete を呼ぶ。アサート対象が誤り。モック対象 API 一覧 / dispatcher にも issue delete が欠落
- 中 #3: gh_project_inject_failure は MOCK_<API>_FAIL を立てるが、gh wrapper の dispatcher は MOCK_GH_FAIL しか参照していない（API 単位失敗注入が機能しない）
- 低 #4: fixture ディレクトリ規約が文書内で不一致（setup_env で bin/tests/gh-project/fixtures をリポジトリ commit 対象として mkdir / gh mock 説明では BATS_TEST_TMPDIR/fixtures をデフォルトと記載）

Round 1 修正内容（unit-005-plan.md 反映）:
- 完了条件チェックリスト全項目を [ ] に変更（実施前提を回復）
- probe bats ケース 2 のアサート対象を gh issue delete に修正、sandbox 操作の流れを issue create → item-add → issue edit close → cleanup に明示
- Issue #683 受け入れ基準のモック対象 API 一覧に issue delete を追加
- dispatcher の case 文に issue create / issue edit / issue delete / issue view / api graphql を追加、各分岐内で MOCK_<API>_FAIL を参照する形に修正
- gh_project_inject_failure ヘルパー仕様を更新（"project list" → MOCK_PROJECT_LIST_FAIL の変数名生成、グローバルは MOCK_GH_FAIL を直接 export）
- fixture ディレクトリ規約を一本化（リポジトリ commit 対象: bin/tests/gh-project/fixtures/ / ランタイム展開先: GH_PROJECT_FIXTURE_DIR デフォルト BATS_TEST_TMPDIR/fixtures、コピー経路を明文化）

Round 2 (session-id: 6ef05854-87a5-4425-83c7-dbda297ffa11): 指摘 0 件、4 観点とも反映確認

シグナル:
- review_detected = true (R1)
- resolved_count = 4
- unresolved_count = 0
- deferred_count = 0
- rounds = 2 (last_round_clean = true → completed)

セミオートゲート判定: auto_approved (automation_mode=semi_auto / unresolved_count=0 / フォールバック非該当)

備考: 計画承認前レビューのためレビューサマリは生成しない (review-flow.md 規定)。
副次成果: codex stdin 待ちハング問題を本フロー中に発見し、運用知見として Issue #703 (priority:medium / type:docs) を起票。回避策（codex exec ... </dev/null 必須）は別セッションで ~/.claude/CLAUDE.md に追記済み。

関連 Issue:
- #683 (本 Unit 起点 / type:defer-from-review)
- #703 (副次起票 / codex stdin 待ち運用ルール)
- **成果物**:
  - `.aidlc/cycles/v2.6.2/plans/unit-005-plan.md`

---
## 2026-05-12T09:52:50+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-gh-project-side-effect-bats（gh-project 副作用 bats テスト整備（gh API モックフレームワーク））
- **ステップ**: AIレビュー完了
- **実行内容**: 設計 AI レビュー (reviewing-construction-design / focus=architecture / codex) を 3 round 実施し、ReviewSession.is_completed() = completed で確定。

Round 1 (session-id: cdr-20260512-001): 4 件指摘
- 高 #1: ApiSelector dispatch 表が不完全（gh project view-list / view-create / field-create / edit / gh issue close / issue list が欠落）
- 中 #2: fixture キー命名が文書間で不整合（issue-view-body.json vs issue-view.json）
- 中 #3: audit bats ケース表に --check all の集約検証ケース欠落
- 中 #4: migrate --dry-run ケース期待が実装と不一致（dry-run でも gh issue view 524 は呼ばれる）

Round 2 (session-id: 20260512-verify-unit005-r1-followup): 残存 2 件
- 中 #2 残存: L97 migrate-issue-524.bats 依存に issue-view-body.json が残存
- 中 #5: L104 probe-github-project.bats 依存に item-add.json が残存

Round 3 (session-id: c2f57a): 指摘 0 件

修正内容:
- domain_model.md dispatch 表に 6 API を追加（project view-list / view-create / field-create / edit / issue close / issue list）、各 fixture key + per-api FailureFlag を 1 対 1 で明記
- 命名規約セクションを SoT として明示（fixture キー = ApiSelector 値の半角スペース・ハイフン → '-' 正規化）
- logical_design.md の fixtures 一覧（19 ファイル）/ fixture スキーマ表 / bats 依存記述を新命名で統一
- audit ケース表に ケース 6（--check all 集約）を追加、Phase 2 合計 18 ケース相当
- migrate ケース 1 を実装挙動と整合（gh issue edit 0 回 + gh issue view 1 回）
- gh wrapper の --jq 引数扱いを Phase 2 実装時の境界として明示

シグナル:
- review_detected = true
- resolved_count = 5
- unresolved_count = 0
- deferred_count = 0
- rounds = 3 (last_round_clean = true → completed)

セミオートゲート判定: auto_approved (automation_mode=semi_auto / unresolved_count=0 / フォールバック非該当)

関連 Issue: #683
- **成果物**:
  - `.aidlc/cycles/v2.6.2/design-artifacts/domain-models/unit_005_gh_project_side_effect_bats_domain_model.md`
  - `.aidlc/cycles/v2.6.2/design-artifacts/logical-designs/unit_005_gh_project_side_effect_bats_logical_design.md`
  - `.aidlc/cycles/v2.6.2/construction/units/005-review-summary.md`

---
## 2026-05-12T10:03:04+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-gh-project-side-effect-bats（gh-project 副作用 bats テスト整備（gh API モックフレームワーク））
- **ステップ**: Phase 1 実装完了
- **実行内容**: Phase 1（モック基盤整備）の実装が完了。Phase 2（4 bats 追加 + Unit 004 既存 bats モック経由化）は別セッションまたは継続セッションで実施する。

実装成果物:
- bin/tests/gh-project/_helpers.bash 新設（gh API モックフレームワーク本体）
  - gh_project_setup_env: 環境セットアップ
  - gh_project_mock_gh: gh wrapper factory（17 ApiSelector dispatch + per-api 失敗注入 + 未モック検出 exit 99 + fixture 不在 exit 98）
  - gh_project_mock_dasel / gh_project_mock_yq: 補助 wrapper
  - gh_project_set_fixture: fixture コピー
  - gh_project_inject_failure: per-api 失敗注入（"project list" → MOCK_PROJECT_LIST_FAIL）
  - gh_project_assert_gh_call_count / gh_project_assert_gh_call_contains: 呼出アサート
- bin/tests/gh-project/fixtures/ 新設（最小 7 ファイル: project-list / project-create / project-edit / project-field-list / project-view-list / project-item-list / issue-list）
- bin/tests/gh-project/_helpers_self_test.bats 新設（11 ケース / Phase 1 完了マーカー）
  - gh_project_setup_env の環境変数 export 確認
  - gh auth status 固定応答
  - fixture dispatch 動作確認
  - 未モック API exit 99 検出
  - fixture 不在 exit 98 検出
  - per-api 失敗注入 + 他 API 非波及
  - グローバル MOCK_GH_FAIL の全 API 波及
  - 呼出ログアサート（成功 / 不一致時 non-zero）
  - gh_project_set_fixture src 不在時の non-zero return

検証:
- bats bin/tests/gh-project/ で 53 件全件 pass（既存 42 件 + Unit 005 Phase 1 新規 11 件）
- shellcheck _helpers.bash: clean
- shellharden: 未インストール環境のため lint スキップ（既存スクリプトと同条件）

Phase 1 完了マーカーの設計書からの調整:
- 設計書では「setup-github-project.bats の最小 1 ケース」を Phase 1 完了マーカーとしていたが、subject (setup-github-project.sh) が 5 subcommand orchestrator のため、最小 1 ケースでも fixture 全 spec subcommand 分が必要になる
- Phase 1 完了マーカーは「helpers の自己テスト」(`_helpers_self_test.bats` / 11 件) で代替し、subject に対する最小動作確認は Phase 2 で全 4 bats 実装と一体化する
- 本調整は Phase 2 完了マーカー（4 bats 全件 pass）には影響しない

シグナル:
- 実装規模: _helpers.bash 約 230 行 + fixtures 7 ファイル + bats 11 ケース
- 試行: Self-Healing 0 回（実装初回で全件 pass）

次セッションでの Phase 2 残作業:
1. setup-github-project.bats 新設（4 ケース / 全 spec subcommand 分の fixture 追加）
2. migrate-issue-524.bats 新設（4 ケース / issue-view.json / issue-edit.json fixture 追加）
3. probe-github-project.bats 新設（4 ケース / issue-create.json / project-item-add.json / issue-close.json / issue-delete.json fixture 追加）
4. audit-github-project.bats 新設（6 ケース / probe-evidence-*.json + project-field-list-with-cycle.json fixture 追加 / --check all 集約検証含む）
5. Unit 004 既存 ensure_fields_options_sync.bats を _helpers 経由に置換（assert 本体は変更しない）
6. コード AI レビュー / 統合 AI レビュー / 完了処理
- **成果物**:
  - `bin/tests/gh-project/_helpers.bash`
  - `bin/tests/gh-project/_helpers_self_test.bats`
  - `bin/tests/gh-project/fixtures/`

---
## 2026-05-12T11:00:40+09:00

- **フェーズ**: Construction Phase
- **Unit**: 05-gh-project-side-effect-bats（gh-project 副作用 bats テスト整備（gh API モックフレームワーク））
- **ステップ**: Phase 2 実装 + コードレビュー + 統合レビュー + 完了処理
- **実行内容**: - **フェーズ**: Construction Phase
- **Unit**: 05-gh-project-side-effect-bats（gh-project 副作用 bats テスト整備（gh API モックフレームワーク））
- **ステップ**: Phase 2 実装 + コードレビュー + 統合レビュー + 完了処理
- **実行内容**: Unit 005 Phase 2 を完了。設計書の Phase 2 ケース表 18 ケース (setup-github-project 4 / migrate-issue-524 4 / probe-github-project 4 / audit-github-project 6) をすべて bats 化し、Unit 004 既存 14 ケースを _helpers 経由に移行、Phase 1 完了マーカー bats に assert helper 契約検証 2 ケースを追加。プロジェクト全 bats 139 件 green / shellcheck _helpers.bash + setup-github-project.sh clean / markdownlint N/A (md 変更なし)。

実装成果物:
- bin/tests/gh-project/setup-github-project.bats（新規 4 ケース）
  - dry-run で 5 subcommand 順次実行 + completed 行
  - --strict 透過 (view-create 1 回)
  - ensure-fields 失敗注入で fail-fast
  - audit ステップ --dry-run 除去 (audit:spec-conformance: + audit-summary: 直接アサート)
- bin/tests/gh-project/migrate-issue-524.bats（新規 4 ケース）
  - --dry-run で gh issue view 1 / gh issue edit 0 + backup-saved
  - バックアップが .aidlc/cycles/v2.6.0/operations/issue-524-backup.md に作成
  - --strict scope 不足 → exit 2 + scope_missing
  - unknown option → exit 1 + args_invalid
- bin/tests/gh-project/probe-github-project.bats（新規 4 ケース）
  - --dry-run structure-only evidence (cleanup_status: null)
  - apply 経路で sandbox 作成 + cleanup (gh issue delete 1 回 + cleanup_status: succeeded)
  - --probe 値欠落 → exit 1 + missing_value_for_option
  - --strict scope 不足 → exit 2
- bin/tests/gh-project/audit-github-project.bats（新規 6 ケース）
  - within_sla / sla_exceeded(strict)/ unknown(soft) / evidence_missing(strict) / spec-conformance drift / --check all 集約
- bin/tests/gh-project/_helpers.bash（リファクタ）
  - _dispatch_api に集約 (case 1 行で API 拡張可能 / 17 ApiSelector 対応)
  - per-API MOCK_<API>_FAIL_ON_NTH 追加 (awk index() で行頭境界厳密判定)
  - --jq 引数の fixture への適用 (valid JSON 必須 / parse 失敗で exit 97)
  - gh_project_assert_gh_call_count_fixed 新規追加 (grep -Fx で行全体一致 / ERE と用途分離)
- bin/tests/gh-project/ensure_fields_options_sync.bats（Unit 004 既存 14 ケース移行）
  - インラインモック 約 80 行を _helpers 経由に置換
  - assert 本体の意味維持 (graphql 呼出回数 / option 引数 / nth-call failure)
- bin/tests/gh-project/_helpers_self_test.bats（Phase 1 完了マーカー + R4 反映 2 ケース追加）
  - 行全体一致で count=1
  - 部分一致では false-negative
- bin/tests/gh-project/fixtures/（新規 14 個 / Phase 1 既存 7 個 = 計 21 個）
  - api-graphql / issue-{close,create,delete,edit,view} / probe-evidence-{within,exceeded,unknown} / project-field-{create,list-with-cycle} / project-item-{add,edit} / project-view-create
- bin/setup-github-project.sh（subject bug 即時 fix / 5 行 + コメント）
  - `${_OPTS[@]/--dry-run/}` パラメータ展開が空文字列要素を残し、下位 CLI が unknown_option: で exit 1 する bug を配列フィルタに置換
  - DR-010 で意思決定記録 (CLAUDE.md「即時実装優先ルール」適用)
- .aidlc/cycles/v2.6.2/construction/units/005-review-summary.md（Set 2 + Set 3 追記）
- .aidlc/cycles/v2.6.2/inception/decisions.md（DR-010 追加）
- .aidlc/cycles/v2.6.2/story-artifacts/units/005-gh-project-side-effect-bats.md（実装状態=完了 / 完了日 2026-05-12）

検証:
- bats bin/tests/ -r で 139 件全件 pass (Unit 005 関連 73 件 + 他 66 件 / 既存 53 件と完全並存)
- shellcheck _helpers.bash + bin/setup-github-project.sh: clean
- markdownlint: N/A (md 変更なし)

レビュー履歴:
- コードレビュー (reviewing-construction-code / codex): R1 3 件 (中:2 低:1) → R2 1 件 (低 / nth-call 行頭境界) → R3 0 件 → completed / auto_approved
- 統合レビュー (reviewing-construction-integration / codex): R1 2 件 → R2 2 件 → R3 2 件 → R4 2 件 → R5 0 件 → completed / auto_approved / deferred 1 件 (R4 #2 README 明文化 / PENDING_MANUAL / inline doc が canonical との判断)

セミオートゲート判定:
- 計画承認: auto_approved (前セッション)
- 設計承認: auto_approved (前セッション)
- 実装 (コードレビュー): auto_approved (本セッション)
- 統合とレビュー: auto_approved (本セッション)

関連 Issue: #683 (本 Unit 起点 / type:defer-from-review)
- **成果物**:
  - `bin/tests/gh-project/setup-github-project.bats`
  - `bin/tests/gh-project/migrate-issue-524.bats`
  - `bin/tests/gh-project/probe-github-project.bats`
  - `bin/tests/gh-project/audit-github-project.bats`
  - `bin/tests/gh-project/_helpers.bash`
  - `bin/tests/gh-project/ensure_fields_options_sync.bats`
  - `bin/tests/gh-project/_helpers_self_test.bats`
  - `bin/tests/gh-project/fixtures/*.json` (21 個)
  - `bin/setup-github-project.sh`
  - `.aidlc/cycles/v2.6.2/construction/units/005-review-summary.md`
  - `.aidlc/cycles/v2.6.2/inception/decisions.md`
  - `.aidlc/cycles/v2.6.2/story-artifacts/units/005-gh-project-side-effect-bats.md`

---
