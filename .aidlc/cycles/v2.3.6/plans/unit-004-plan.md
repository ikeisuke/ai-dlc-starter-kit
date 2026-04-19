# Unit 004 実装計画 - Draft PR 時の GitHub Actions スキップ

## Unit 概要

`pull_request` トリガーで動作する 3 本のワークフロー（`pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml`）に対して、以下の二段ガードを導入し Draft PR 期間中の runner 分単位消費を 0 にする:

1. `on.pull_request.types` を `[opened, synchronize, reopened, ready_for_review]` に明示
2. 各ジョブに `if: github.event.pull_request.draft == false` を付与

workflow run 自体は作成されうるが、ジョブレベル `if` が `false` と評価された時点で `skipped` 状態になり runner は割り当てられない。Draft → Ready 遷移で `ready_for_review` イベントが発火し、初回の runner 実行が行われる運用に寄せる（DR-004）。

## 完了条件チェックリスト

**Unit 定義「責務」由来**:

- [ ] `.github/workflows/pr-check.yml` の `on.pull_request.types` が `[opened, synchronize, reopened, ready_for_review]` に明示されている。
- [ ] `.github/workflows/pr-check.yml` の全ジョブ（`markdown-lint` / `bash-substitution-check` / `defaults-sync-check`）に `if: github.event.pull_request.draft == false` が付与されている。
- [ ] `.github/workflows/migration-tests.yml` の `on.pull_request.types` が同様に明示されている。
- [ ] `.github/workflows/migration-tests.yml` の `migration-tests` ジョブに `if: github.event.pull_request.draft == false` が付与されている。
- [ ] `.github/workflows/skill-reference-check.yml` の `on.pull_request.types` が同様に明示されている。
- [ ] `.github/workflows/skill-reference-check.yml` の `skill-reference-check` ジョブに `if: github.event.pull_request.draft == false` が付与されている。
- [ ] 既存の `paths` フィルタ / `branches: [main]` / `permissions` / ジョブ内ステップは変更されていない（Ready PR での挙動が従来どおり維持される）。
- [ ] Unit 004 完了コミット後、**専用のテスト Draft PR**（Unit 004 専用のブランチから作成、既定はこちら）で検証手順を実行し結果を記録する。サイクル PR を Draft に戻す方式は副作用（Required status checks / レビュー要求 / CODEOWNERS 通知）が大きいため代替手段とし、使用する場合はその旨と理由を記録する。検証は以下の 2 段で実施する:
  1. **run 単位確認**: `gh api repos/{owner}/{repo}/actions/runs?event=pull_request&head_branch=<branch>` で workflow run 一覧を取得し、Draft 状態時は全 run の `conclusion` が `skipped`（または `status=completed` + `conclusion=skipped`）になっていることを確認する。
  2. **ジョブ単位確認**: 各 `run_id` に対して `gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs` を実行し、`jobs[].conclusion` が `skipped` であることを確認する（Unit 定義 L17 のジョブ粒度要件の直接検証）。
  3. **Ready 遷移後の確認**: Draft → Ready に遷移後、再度同手順で初回 run が `in_progress` → `completed` となり、ジョブの `conclusion` が `success`（または該当 paths にヒットしない場合は run が作成されない）であることを確認する。

**NFR 由来**:

- [ ] リソース効率: Draft PR 期間中の runner 分単位消費が 0（jobs skipped のため）。
- [ ] 可観測性: Draft → Ready 遷移で runner が初回起動し観測可能。
- [ ] 既存機能非破壊: Ready PR での `synchronize` / `reopened` / `paths` フィルタの挙動が従来どおり。

## 実装方針

### Phase 1（設計）の扱い

`depth_level=standard` のため、軽量な設計成果物を作成する。本 Unit は GitHub Actions YAML の起動条件を変更するだけの単純な変更であり、**実装対象は workflow YAML 3 本のみ**で独自ドメインロジックを持たない。従って Phase 1 の成果物は以下を厳守する:

- **抽象化の制約**: ドメインモデルで扱う概念（`PullRequestEvent` / `DraftState` / `JobGuardDecision`）は、GitHub Actions の既存仕様を説明するための**説明補助**として位置づけ、新たな設計責務を増やさない。設計成果物が Unit 定義の責務境界（YAML 起動条件の変更）を越えた抽象レイヤーを持ち込まないよう注意する。
- **ドメインモデル**: `.aidlc/cycles/v2.3.6/design-artifacts/domain-models/unit_004_draft_pr_actions_skip_domain_model.md`
  - 目的: GitHub Actions の `pull_request` イベントと Draft/Ready 状態に基づくジョブ実行判定ルールを**既存仕様の要約として**明文化（新規ドメインの設計ではない）
  - 記述は 1 ページ程度に収め、概念モデルは説明補助であることを冒頭で明示する
- **論理設計**: `.aidlc/cycles/v2.3.6/design-artifacts/logical-designs/unit_004_draft_pr_actions_skip_logical_design.md`
  - 3 ワークフローの `on.pull_request.types` 明示と、各ジョブの `if` ガード配置の具体的な YAML 差分を示す（設定変更メモに近い軽量成果物）
  - `types` 明示 + ジョブレベル `if` の二段ガードを採用する理由（GitHub デフォルト types の罠、ステップレベル `if` だと runner が起動してしまう点）を記述
- **設計レビュー**: `reviewing-construction-design` スキル（優先 codex）で実施（`review_mode=required`）。
- **設計承認**: ゲート承認（`automation_mode=semi_auto` → フォールバック条件非該当なら `auto_approved`）。

### Phase 2（実装）の作業内容

1. **`pr-check.yml` 編集**:
   - `on.pull_request` に `types: [opened, synchronize, reopened, ready_for_review]` を追加
   - `markdown-lint` / `bash-substitution-check` / `defaults-sync-check` 各ジョブの `runs-on` 行の前に `if: github.event.pull_request.draft == false` を追加
2. **`migration-tests.yml` 編集**:
   - 同様に `on.pull_request.types` 追加 + `migration-tests` ジョブに `if` 追加
3. **`skill-reference-check.yml` 編集**:
   - 同様に `on.pull_request.types` 追加 + `skill-reference-check` ジョブに `if` 追加
4. **YAML 構文検証**:
   - 可能なら `actionlint` / `yq` / `yamllint` 等で構文チェックを実行。ツールが無い場合は `python -c 'import yaml; yaml.safe_load(open("..."))'` で代替。
5. **コードレビュー**: `reviewing-construction-code` スキル（優先 codex）で実施。
6. **統合レビュー**: 構文検証完了後に `reviewing-construction-integration` スキルで実施。
7. **実 PR 検証（完了条件に含む）**:
   - **既定**: Unit 004 専用のテスト Draft PR を作成（`cycle/v2.3.6` から派生した検証用ブランチを `main` 向けに Draft PR として push）し、そこで検証を実施する。サイクル PR への副作用（Required status checks / レビュー要求 / CODEOWNERS 通知）を避ける
   - **代替（必要時のみ）**: テスト PR 作成が困難な場合はサイクル PR を一時的に Draft に戻して検証。この場合は理由と影響を完了履歴に記録する
   - 検証手順（完了条件 L23 の 2 段検証に従う）:
     1. run 単位確認: `gh api repos/{owner}/{repo}/actions/runs?event=pull_request&head_branch=<branch>` で `conclusion=skipped` を確認
     2. ジョブ単位確認: `gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs` で `jobs[].conclusion=skipped` を確認
     3. Ready 遷移後確認: Draft → Ready に遷移し、初回 run が `in_progress` → `completed`、ジョブの `conclusion=success`（または paths 不一致で run 自体が作成されない）となることを確認
   - 検証結果（各ステップの実コマンド出力サマリ）を Unit 004 完了履歴に記録

### 境界外（本 Unit では扱わない）

- `.github/workflows/auto-tag.yml`（`push` トリガーのため Draft 概念なし）。
- 他のトリガー（`schedule` / `workflow_dispatch`）の追加・変更。
- ワークフロー内のジョブステップ内容・ビルドスクリプトの変更。
- 新規ワークフローの追加。
- CHANGELOG 更新（Unit 003 で集約、DR-002）。

## 影響範囲

- 変更ファイル:
  - `.github/workflows/pr-check.yml`
  - `.github/workflows/migration-tests.yml`
  - `.github/workflows/skill-reference-check.yml`
- 既存ステップ・`paths` フィルタ・`permissions` は変更しない。
- 下流影響:
  - Draft PR 期間中は全ジョブが `skipped` で runner 消費が 0 になる。
  - `ready_for_review` 遷移で初回 runner 実行が発火し、以降は `synchronize` で通常どおり実行される。
  - 既存の Ready PR ワークフローには一切の挙動変化なし。

## 見積もり

0.25 日（Unit 定義と同じ）

## 依存関係

- 依存する Unit: なし（Unit 001 / 002 / 003 とは独立、編集対象ファイルも非重複）。
- CHANGELOG 集約は Unit 003 が担当するため、Unit 004 単体では CHANGELOG 更新を行わない。
- 外部依存: GitHub Actions ランタイムの挙動（`ready_for_review` イベントのトリガ仕様、`github.event.pull_request.draft` コンテキスト）。

## 参考資料

- Unit 定義: `story-artifacts/units/004-draft-pr-actions-skip.md`
- DR-004（`inception/decisions.md`）
- GitHub Actions: [`pull_request` の types](https://docs.github.com/en/actions/reference/events-that-trigger-workflows#pull_request)
- GitHub Actions: [ジョブレベル `if`](https://docs.github.com/en/actions/reference/workflow-syntax-for-github-actions#jobsjob_idif)
