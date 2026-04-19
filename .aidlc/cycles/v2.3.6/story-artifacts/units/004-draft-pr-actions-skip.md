# Unit: Draft PR 時の GitHub Actions スキップ

## 概要

`pull_request` トリガーで動作する 3 本のワークフロー（`pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml`）が Draft PR でも毎コミット走って runner 分単位を無駄消費している。本 Unit で `types` 明示 + ジョブレベル `if` の二段ガードを導入し、Draft PR ではジョブが `skipped` 状態で runner を消費せず、`ready_for_review` 遷移時に runner 起動 → 初回実行される運用に寄せる。workflow run 自体は `types` 該当イベントで作成されうるが、ジョブレベル `if` で skip されるため runner リソース消費は 0。

## 含まれるユーザーストーリー

- ストーリー 3.1: Draft PR で GitHub Actions の不要な起動を抑止する（DR-004, Unit 004）

## 責務

- `.github/workflows/pr-check.yml` / `migration-tests.yml` / `skill-reference-check.yml` の 3 本で以下を実施する:
  - `on.pull_request.types` を `[opened, synchronize, reopened, ready_for_review]` に明示。
  - `jobs.*` 各ジョブに `if: github.event.pull_request.draft == false` を付与。
- 既存の `paths` フィルタ / `branches: [main]` 等の発火条件は変更しない。
- Unit 004 PR 本文に検証手順（`gh api repos/{owner}/{repo}/actions/runs?event=pull_request&head_branch=<branch>` で Draft 状態時は全 run のジョブが `skipped` または `conclusion=skipped`、Ready 遷移後に初回 `in_progress` → `completed`）を記録する。

## 境界

- `.github/workflows/auto-tag.yml`（`push` トリガー）は対象外（Draft 概念なし）。
- 他のトリガー（`schedule`, `workflow_dispatch`）の追加・変更は扱わない。
- ワークフロー内のジョブステップ内容・ビルドスクリプトの変更は扱わない（あくまで起動条件のみ）。
- 新規ワークフローの追加は扱わない。

## 依存関係

### 依存する Unit

- なし（Unit 001 / 002 / 003 とは独立。編集対象ファイルが重複しないためコード上の依存もなし）

> 注: CHANGELOG 集約は Unit 003 が担当するため、Unit 004 の変更内容も Unit 003 の CHANGELOG 追記に含める（DR-002 の集約方針に従う）。Unit 004 単体では CHANGELOG 更新を行わない。

### 外部依存

- GitHub Actions ランタイムの挙動（`ready_for_review` イベントのトリガ仕様、`github.event.pull_request.draft` コンテキスト）

## 非機能要件（NFR）

- **リソース効率**: Draft PR 期間中の runner 分単位消費を 0 にする（workflow run は作成されてもジョブが `skipped` で完了するため runner 未割当）。
- **可観測性**: Draft → Ready 遷移で初回の runner 実行が観測できる（actions タブで `in_progress` → `completed`、または `gh api` の `status=in_progress` から `status=completed`）。
- **既存機能非破壊**: Ready PR での挙動は従来どおり（synchronize / reopened で発火、paths フィルタ尊重）。

## 技術的考慮事項

- `types` を明示する理由: GitHub のデフォルトは `[opened, synchronize, reopened]` で `ready_for_review` が含まれない。Draft → Ready 遷移で再発火させるため `ready_for_review` を明示的に追加する。
- `if` をジョブレベルに置く理由: ジョブレベル `if` が `false` と評価されるとジョブは `skipped` ステータスとなり runner を割り当てずに完了するため、分単位を消費しない。ステップレベル `if` だと runner が起動してからステップがスキップされるため runner 分単位を消費してしまう。
- `closed` や `labeled` などのイベントは本 Unit のスコープ外。
- テスト: 実 PR（v2.3.6 の cycle/v2.3.6 ブランチ）で Draft 維持中は全ジョブが `skipped` であること、Ready 化すると runner が起動し初回 `in_progress` → `completed` となることを検証する。

## 関連Issue

- なし（サイクル追加要件、ユーザーからの直接要望で Intent 拡張）

## 実装優先度

Medium

## 見積もり

0.25 日（ワークフロー 3 本の YAML 編集のみ）

---
## 実装状態

有効値: 未着手 | 進行中 | 完了 | 取り下げ

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
