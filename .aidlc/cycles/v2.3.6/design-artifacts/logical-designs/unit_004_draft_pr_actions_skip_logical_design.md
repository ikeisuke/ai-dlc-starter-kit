# 論理設計: Unit 004 - Draft PR 時の GitHub Actions スキップ

## 位置づけ（重要）

本ドキュメントは **設定変更メモ**として位置づけられる軽量な論理設計である。実装対象は `.github/workflows/` 配下の 3 本の YAML のみで、独自の関数・モジュール・データ構造を新設しない。設計対象は「どの YAML のどの行に何を追加するか」のみである。

計画ファイル `.aidlc/cycles/v2.3.6/plans/unit-004-plan.md` の Phase 1 制約に従う。

## 変更対象ファイル

| # | ファイル | 変更種別 |
|---|---------|---------|
| 1 | `.github/workflows/pr-check.yml` | `on.pull_request.types` 追加 + 3 ジョブに `if` 追加 |
| 2 | `.github/workflows/migration-tests.yml` | `on.pull_request.types` 追加 + 1 ジョブに `if` 追加 |
| 3 | `.github/workflows/skill-reference-check.yml` | `on.pull_request.types` 追加 + 1 ジョブに `if` 追加 |

変更しないもの: `on.pull_request.branches` / `paths` / `permissions` / ジョブ内ステップ / `runs-on` / 既存のジョブ名・ジョブ ID。

## 採用パターン

### 二段ガード（`types` 明示 + ジョブレベル `if`）

**選択理由（DR-004 より）**:

- 一段ガード（ジョブレベル `if` のみ）だと、GitHub デフォルトの `types` に `ready_for_review` が含まれないため、Draft → Ready 遷移で再発火しないケースが発生する → 不採用
- 二段ガード（`types` 明示 + ジョブレベル `if`）は GitHub 公式推奨パターン → 採用

**ジョブレベル `if` を選ぶ理由（ステップレベルではなく）**:

- ステップレベル `if`: runner を割り当ててからステップをスキップするため、分単位を消費する
- ジョブレベル `if`: runner を割り当てずに `skipped` で完了するため、分単位消費 0

## 具体的な YAML 差分

### 1. `.github/workflows/pr-check.yml`

**現状**:

```yaml
on:
  pull_request:
    branches: [main]
    paths:
      - '**.md'
      - '**.toml'
      - '.markdownlint.json'
      - '.github/workflows/pr-check.yml'
      - 'bin/check-bash-substitution.sh'
      - 'bin/check-defaults-sync.sh'

# ...

jobs:
  markdown-lint:
    name: Markdown Lint
    runs-on: ubuntu-latest
    steps:
      # ...

  bash-substitution-check:
    name: Bash Substitution Check
    runs-on: ubuntu-latest
    steps:
      # ...

  defaults-sync-check:
    name: Defaults TOML Sync Check
    runs-on: ubuntu-latest
    steps:
      # ...
```

**変更後**:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
    branches: [main]
    paths:
      - '**.md'
      - '**.toml'
      - '.markdownlint.json'
      - '.github/workflows/pr-check.yml'
      - 'bin/check-bash-substitution.sh'
      - 'bin/check-defaults-sync.sh'

# ...

jobs:
  markdown-lint:
    name: Markdown Lint
    if: github.event.pull_request.draft == false
    runs-on: ubuntu-latest
    steps:
      # ...

  bash-substitution-check:
    name: Bash Substitution Check
    if: github.event.pull_request.draft == false
    runs-on: ubuntu-latest
    steps:
      # ...

  defaults-sync-check:
    name: Defaults TOML Sync Check
    if: github.event.pull_request.draft == false
    runs-on: ubuntu-latest
    steps:
      # ...
```

### 2. `.github/workflows/migration-tests.yml`

**現状**:

```yaml
on:
  pull_request:
    branches: [main]
    paths:
      - 'skills/aidlc-migrate/scripts/migrate-*.sh'
      # ...

jobs:
  migration-tests:
    name: Migration Script Tests
    runs-on: ubuntu-latest
    steps:
      # ...
```

**変更後**:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
    branches: [main]
    paths:
      - 'skills/aidlc-migrate/scripts/migrate-*.sh'
      # ...

jobs:
  migration-tests:
    name: Migration Script Tests
    if: github.event.pull_request.draft == false
    runs-on: ubuntu-latest
    steps:
      # ...
```

### 3. `.github/workflows/skill-reference-check.yml`

**現状**:

```yaml
on:
  pull_request:
    branches: [main]
    paths:
      - 'skills/**'
      # ...

jobs:
  skill-reference-check:
    name: Skill Reference Check
    runs-on: ubuntu-latest
    steps:
      # ...
```

**変更後**:

```yaml
on:
  pull_request:
    types: [opened, synchronize, reopened, ready_for_review]
    branches: [main]
    paths:
      - 'skills/**'
      # ...

jobs:
  skill-reference-check:
    name: Skill Reference Check
    if: github.event.pull_request.draft == false
    runs-on: ubuntu-latest
    steps:
      # ...
```

## 配置ルール

### `on.pull_request.types` の配置位置

- `on.pull_request` ブロックの**最初のキー**として配置する（`branches` / `paths` の前）
- 値は `[opened, synchronize, reopened, ready_for_review]` で 3 本すべて統一
- 既存の `branches` / `paths` は変更しない

### ジョブレベル `if` の配置位置

- ジョブ定義内で `name:` と `runs-on:` の**間**に配置する
- 値は `github.event.pull_request.draft == false` で統一
- 3 ワークフロー中の**全てのジョブ**に付与する（pr-check.yml は 3 ジョブ、他は 1 ジョブずつ）

## エッジケース

### 既存 `paths` フィルタとの相互作用

- `on.pull_request.types` は「どのイベントで workflow run を作るか」を制御する
- `on.pull_request.paths` は「どのファイル変更で workflow run を作るか」を制御する
- 両者は AND 条件: `types` に該当 かつ `paths` にヒットしたファイル変更がある → workflow run 作成
- Draft PR でも `ready_for_review` 以外で `paths` にヒットすれば workflow run は作成される（ただしジョブレベル `if` で skip される）
- この挙動は Unit 定義 NFR「既存機能非破壊」と整合（Ready PR での挙動が従来どおり）

### Draft → Ready 遷移時の挙動

- `ready_for_review` イベントが発火し、`types` に含まれるため workflow run が新規作成される
- ジョブレベル `if` は `github.event.pull_request.draft == false` を評価 → Ready 状態なので `true` → ジョブが通常実行される
- これが「初回 runner 起動」ポイント

### Ready → Draft 戻し

- `converted_to_draft` イベントは本 Unit の `types` に含まれないため workflow run は作成されない
- 以後、synchronize / reopened が発火しても workflow run は作成されうるが、ジョブは `if` で skipped される

## 検証手段（計画 Phase 2 ステップ 7 に従う）

1. **run 単位確認**: `gh api repos/{owner}/{repo}/actions/runs?event=pull_request&head_branch=<branch>` で全 run が `conclusion=skipped`
2. **ジョブ単位確認**: 各 `run_id` に対して `gh api repos/{owner}/{repo}/actions/runs/{run_id}/jobs` で `jobs[].conclusion=skipped`
3. **Ready 遷移後**: `conclusion=success`（または paths 不一致で run 自体が作成されない）

## 境界外

- 関数・クラス・ライブラリの新設は行わない（YAML 編集のみ）
- YAML Linter の設定変更は行わない（既存ツール可用性に応じて利用するのみ）
- テスト自動化は行わない（実 PR で手動検証）

## 参考資料

- Unit ドメインモデル: `unit_004_draft_pr_actions_skip_domain_model.md`
- 計画: `plans/unit-004-plan.md`
- DR-004（`inception/decisions.md`）
