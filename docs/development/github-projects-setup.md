# GitHub Projects (ProjectsV2) セットアップ運用ガイド

> 本ガイドは AI-DLC Starter Kit v2.6.0 の Unit 006 で導入された GitHub Projects (ProjectsV2) 移行基盤の運用手順を説明する。
> 詳細仕様は `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md` 参照。

## 目的

- AI-DLC Starter Kit のバックログ管理を Issue #524（手動チェックリスト運用）から GitHub Projects (ProjectsV2) に移行
- Status / Priority / Cycle / Type の動的フィルタとビュー（Roadmap / Board / Table）で可視化を強化
- AI-DLC スキル群（特に `/aidlc i` のバックログ確認）に Project 参照を統合

## Milestone と Project の役割分担

| 軸 | GitHub Projects (新設) | Milestone (既存) | Issue #524 |
|----|----------------------|----------------|----------|
| 役割 | バックログ管理・優先度動的調整 | サイクル単位の出荷スコープ | リダイレクト用（v2.6.0〜） |
| 例 | Status: Backlog/Next/In Progress/Review/Done | v2.5.5 / v2.6.0 / v2.7.0 | Project URL のみ |
| 更新頻度 | 随時 | サイクル開始時 | ほぼ静的 |

## 前提依存

| ツール | バージョン | 用途 |
|-------|----------|------|
| `gh` | v2.x（`project` サブコマンド対応） | GitHub Projects 操作 |
| `yq` | v4.x | spec.yaml パース |
| `jq` | v1.6+ | JSON 操作 |
| `dasel` | v3.x | TOML 読み書き |
| `bats` | v1.8+ | テスト |

`yq` 未インストール時のインストール例:

```bash
# macOS
brew install yq

# Linux
sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
sudo chmod +x /usr/local/bin/yq
```

## ステップ1: gh CLI トークンスコープ拡張（**ユーザー手動作業**）

GitHub Projects の操作には以下のスコープが必須:

- `project` （Project への書き込み）
- `read:org` （`gh project list --owner @me` 要件）
- `read:project` （互換）

```bash
gh auth refresh -s project,read:org,read:project
```

事後確認:

```bash
gh auth status
# Token scopes に 'project', 'read:org', 'read:project' が含まれることを確認
```

## ステップ2: 宣言的仕様（spec.yaml）の確認

Project の desired state は `config/github-project-spec.yaml` で宣言されている。**SoT 単一系統**（手編集する場合は `bin/gh-project-cli.sh audit --check spec-conformance` で実環境との drift を確認）。

```bash
yq eval '.project.title' config/github-project-spec.yaml
yq eval '.fields[].name' config/github-project-spec.yaml
yq eval '.views[].name' config/github-project-spec.yaml
```

## ステップ3: 実環境への apply（**ユーザー承認都度**）

### 3.1 dry-run で確認

```bash
bin/setup-github-project.sh --dry-run
```

各サブコマンドが「何を作成 / 何が既存」を `<resource>:<action>:<identifier>` 形式で出力する:

- `project:would-create:AI-DLC Starter Kit Roadmap` （新規）
- `project:exists:5` （既存 / 番号付き）
- `field:would-create:Status` / `field:exists:Status`
- `view:would-create:Roadmap:graphql` / `view:exists:Roadmap`
- `item:would-add:https://...` / `item:exists:https://...`

### 3.2 apply 実行

```bash
bin/setup-github-project.sh
```

成功すると `.aidlc/config.toml` の `[github_projects]` セクションに以下が自動書き込みされる（**手編集禁止**）:

```toml
[github_projects]
owner = "@me"
project_number = 5
project_url = "https://github.com/users/ikeisuke/projects/5"
```

## ステップ4: GitHub UI で `Item closed` workflow 有効化（**ユーザー手動作業**）

GraphQL `enableProjectV2Workflow` mutation が GA 不安定のため、現在は GitHub UI 操作で有効化する:

1. Project URL を開く（例: `https://github.com/users/ikeisuke/projects/5`）
2. 右上の `...` メニュー → `Workflows`
3. `Item closed` を有効化（toggle ON）
4. Target を `Status = Done` に設定
5. Save

## ステップ5: workflow 監査（probe → audit 2 段）

`Item closed` workflow が期待通り動作しているか、sandbox Issue で probe を実施し audit で評価する。

### 5.1 probe 実行（write 副作用あり）

```bash
bin/probe-github-project.sh --probe workflow-item-closed
```

- sandbox Issue を自動作成 → Project に追加 → close → cleanup（削除）
- 結果を `.aidlc/cache/audit/probe-evidence.json` に出力

### 5.2 audit 実行（read-only 評価）

```bash
bin/audit-github-project.sh --check workflow-item-closed
```

- probe-evidence.json を入力に Status が `Done` に遷移したか評価
- 結果を `.aidlc/cache/audit/audit-summary.json` に出力

### 5.3 spec 整合監査

```bash
bin/audit-github-project.sh --check spec-conformance
```

- spec.yaml と実 Project の field 構成を比較
- drift があれば `audit-summary.json` に記録

## ステップ6: Issue #524 リダイレクト化

### 6.1 dry-run

```bash
bin/migrate-issue-524.sh --dry-run
```

- 新本文を `.aidlc/cycles/v2.6.0/operations/issue-524-new-body.dryrun.md` に出力
- 旧本文を `.aidlc/cycles/v2.6.0/operations/issue-524-backup.md` にバックアップ

### 6.2 apply

```bash
bin/migrate-issue-524.sh
```

- Issue #524 の本文を Project URL + 案内文に置換
- 旧本文はバックアップから復元可能

## モード（strict / soft）

各スクリプトは `--strict` / `--soft` モードを持つ。

| モード | デフォルト適用 | 挙動 |
|--------|--------------|------|
| `--strict` | apply 系（`setup-github-project.sh` / `gh-project-cli.sh ensure-* sync-items` apply / `migrate-issue-524.sh` apply / `probe-github-project.sh`） | スコープ不足 → exit 2（fatal） |
| `--soft` | 参照系（`audit-github-project.sh` / Inception 統合 / dry-run 単独） | スコープ不足 → exit 0 + warn のみ + `.aidlc/cache/gh-project-last-run.json` に記録 |

CI で監査を fail-fast したい場合は `bin/audit-github-project.sh --strict` を明示。

## exit code 規約

| exit | 意味 | error_type (stderr JSON) |
|------|------|-------------------------|
| 0 | 成功 | - |
| 1 | 引数不正 | `args_invalid` |
| 2 | スコープ不足（strict） | `scope_missing` |
| 3 | gh API 失敗 | `gh_api_error` |
| 4 | spec 不正 | `spec_invalid` |
| 5 | evidence / 入力前提不足 | `evidence_missing` |
| 6 | probe 副作用失敗 | `probe_side_effect_failed` |
| 7 | audit 失敗 | `audit_failed` |

## トラブルシューティング

### `gh project list` が `unknown owner type` エラー

**原因**: gh PAT に `read:org` スコープがない。

**対処**: `gh auth refresh -s project,read:org,read:project`

### `view:manual-required` が出力される

**原因**: GraphQL `createProjectV2View` が現バージョンで未実装または不安定。

**対処**: GitHub UI で Project に移動し、該当ビューを手動で作成。spec.yaml の `views[].apply_strategy` を `manual` に書き換えれば再実行で skip される。

### probe → audit で `audit:workflow-item-closed:fail`

**原因 候補**:

- GitHub UI での workflow 有効化忘れ → ステップ4 を実施
- `Status=Done` 以外のターゲット設定 → workflow 設定を確認

### `.aidlc/config.toml` の `[github_projects]` が手編集された場合

**対処**: `bin/gh-project-cli.sh audit --check spec-conformance --strict` で drift を検出。`bin/gh-project-cli.sh ensure-project` を再実行して runtime binding を再生成。

## 関連ドキュメント

- 設計: `.aidlc/cycles/v2.6.0/design-artifacts/logical-designs/unit_006_github_projects_migration_logical_design.md`
- ドメインモデル: `.aidlc/cycles/v2.6.0/design-artifacts/domain-models/unit_006_github_projects_migration_domain_model.md`
- Unit 計画: `.aidlc/cycles/v2.6.0/plans/unit-006-plan.md`
- Issue: #673 / #524（移行対象）
