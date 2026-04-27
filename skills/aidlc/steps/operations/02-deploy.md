# Operations Phase デプロイ実作業（`operations.02-deploy`）

> 「変更なし」スキップ・`project.type` 依存スキップ・`automation_mode` ゲート判定・AI レビュー分岐は `steps/operations/index.md`（フェーズインデックス）§2 に集約されている。本ファイルはステップ1〜7 の詳細手順本体のみを含む。

## フロー

各ステップ完了時にprogress.mdを更新

**状態ラベル一覧**: progress.md 内のステップ状態に使用するラベルは以下の 5 値:

| 状態ラベル | 説明 |
|----------|------|
| `未着手` | ステップ未開始 |
| `進行中` | ステップ実行中 |
| `完了` | ステップ正常完了 |
| `スキップ` | ステップ条件によりスキップ（変更なし / プロジェクト種別不該当 等） |
| `PR準備完了` | §7.6 で progress.md 更新完了状態（§7.7 コミット前後を含む段階表現、`PR準備完了` の遷移は §7 サブステップ §7.6 で発生） |

### ステップ1: 変更確認

**タスク管理機能を活用してください。**

ステップ2-5の確認をスキップするかどうかを確認します。**セミオートゲート判定**: `steps/operations/index.md` の「§2.6 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。`automation_mode=semi_auto` での自動処理は index.md §2.3 も参照。

**確認メッセージ**（`automation_mode=manual` の場合）:
```text
以下の項目で変更したい箇所はありますか？

- ステップ2: デプロイ準備
- ステップ3: CI/CD構築
- ステップ4: 監視・ロギング戦略
- ステップ5: 配布

1. はい - 変更したい項目がある
2. いいえ - 変更なし（ステップ2-5をスキップしてステップ6へ）
```

**選択に応じた処理**:
- **「はい」選択時**: progress.mdでステップ1を「完了」に更新し、ステップ2から順に確認フローを実行（ステップ2-5 → ステップ6 → ステップ7）
- **「いいえ」選択時**: 以下を実行
  1. progress.mdでステップ1を「完了」、ステップ2-5を「スキップ」に更新
  2. 履歴に「ステップ2-5をスキップ（変更なしを選択）」と記録
  3. ステップ6（バックログ整理と運用計画）に進む

**注意**: `.aidlc/rules.md`にカスタムワークフロー（例: アップグレード処理）が定義されている場合、それはスキップ対象外です。rules.mdの指示に従って実行してください。

### ステップ2: デプロイ準備【対話形式】

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ2を「進行中」に更新。**セミオートゲート判定**: `steps/operations/index.md` の「§2.6 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。
- **対話形式**: 不明点は `[Question]` / `[Answer]` タグで記録し、**一問一答形式**でユーザーと対話しながら準備（1つの質問をして回答を待ち、複数の質問をまとめて提示しない）

- **成果物**: `.aidlc/cycles/{{CYCLE}}/operations/deployment_checklist.md`（テンプレート: `templates/deployment_checklist_template.md`）
- **ステップ完了時**: progress.mdでステップ2を「完了」に更新、完了日を記録

### ステップ3: CI/CD構築【対話形式】

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ3を「進行中」に更新。**セミオートゲート判定**: `steps/operations/index.md` の「§2.6 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。
- **対話形式**: 同様に**一問一答形式**で対話
- **成果物**: `.aidlc/cycles/{{CYCLE}}/operations/cicd_setup.md`、CI/CD設定ファイル
- **ステップ完了時**: progress.mdでステップ3を「完了」に更新、完了日を記録

### ステップ4: 監視・ロギング戦略【対話形式】

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ4を「進行中」に更新。**セミオートゲート判定**: `steps/operations/index.md` の「§2.6 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。
- **対話形式**: 同様に**一問一答形式**で対話
- **成果物**: `.aidlc/cycles/{{CYCLE}}/operations/monitoring_strategy.md`（テンプレート: `templates/monitoring_strategy_template.md`）
- **ステップ完了時**: progress.mdでステップ4を「完了」に更新、完了日を記録

### ステップ5: 配布【対話形式】

**タスク管理機能を活用してください。**

**スキップ判定**:

`.aidlc/config.toml` の `project.type` を確認:
- **スキップ対象** (`web`, `backend`, `general`, 未設定): progress.mdでステップ5を「スキップ」に更新し、ステップ6へ進む
- **実行対象** (`cli`, `desktop`, `ios`, `android`): 以下を実行

**実行する場合**:
- **ステップ開始時**: progress.mdでステップ5を「進行中」に更新。**セミオートゲート判定**: `steps/operations/index.md` の「§2.6 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。
- **対話形式**: 同様に**一問一答形式**で対話
- **成果物**: `.aidlc/cycles/{{CYCLE}}/operations/distribution_feedback.md`（テンプレート: `templates/distribution_feedback_template.md`）
- **ステップ完了時**: progress.mdでステップ5を「完了」に更新、完了日を記録

### ステップ6: バックログ整理と運用計画【対話形式】

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ6を「進行中」に更新。**セミオートゲート判定**: `steps/operations/index.md` の「§2.6 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。
- **対話形式**: 同様に**一問一答形式**で対話

#### 6.1 Construction引き継ぎタスク再確認

ステップ11で「後で実行する」を選択した引き継ぎタスクがある場合、ここで再確認・実行する。

```bash
ls .aidlc/cycles/{{CYCLE}}/operations/tasks/ 2>/dev/null
```

**未実行タスクがある場合**: 各タスクの実行状態を確認し、未実行のものを実行する。

#### 6.2 バックログ整理

```bash
gh issue list --label backlog --state open
```

**自動クローズ判定**:

PRの`Closes`セクションに記載されたIssueはマージ時に自動クローズされるため、手動クローズをスキップする。

1. **PR番号の取得**（draft/ready両方を検索）:

事前にBashで `git branch --show-current` を実行し、現在のブランチ名を取得。取得したブランチ名を使って以下を実行:

```bash
gh pr list --head "<取得したブランチ名>" --state open --json number --jq '.[0].number'
```

- PR番号が取得できた場合: 次のステップへ
- PR番号が取得できない場合（PRなし、gh利用不可等）: 従来どおり全Issueについて手動クローズ確認

2. **Closesセクションの解析**:

```bash
# PR本文を取得
gh pr view {PR番号} --json body --jq '.body'
```

取得したPR本文から `Closes #数字` パターン（大文字小文字不問）を抽出してIssue番号のリストを作成する。Closesパターンが0件の場合も正常系として扱い、全Issueを手動クローズ確認対象とする。

3. **クローズ判定**:

- **Closesに含まれるIssue**: 「PRマージ時に自動クローズされます」と表示し、手動クローズをスキップ
- **Closesに含まれないIssue**: 対応済みか確認し、手動でクローズ

**注意**: この判定は暫定であり、最終確定はステップ7.13（PRマージ）直前のCloses確認結果に従う。PRマージまでにClosesセクションが変更された場合は再判定が必要。

対応済み項目の手動クローズ（自動クローズ対象外のみ）:
```bash
scripts/issue-ops.sh close {ISSUE_NUMBER}
```

**出力例**: `issue:123:closed`

**全Issueが自動クローズ対象の場合**:
```text
全対応済みIssueはPRマージ時に自動クローズされます。手動クローズは不要です。
```

**詳細**: `guides/backlog-management.md` を参照

**未対応の項目**: 共通バックログにそのまま残す（次サイクル以降で対応）

#### 6.3 リリース後運用計画

- **成果物**: `.aidlc/cycles/{{CYCLE}}/operations/post_release_operations.md`（テンプレート: `templates/post_release_operations_template.md`）
- **ステップ完了時**: progress.mdでステップ6を「完了」に更新、完了日を記録

### ステップ7: リリース準備

> **順序制約**: リリース準備のコミット・PR操作は `steps/common/commit-flow.md` の「操作順序ルール」に従うこと。コミットが存在しない状態でPR Ready化やPRマージに進んではいけない。

**タスク管理機能を活用してください。**

**Depth Level分岐**（`common/rules-reference.md` の「レベル別成果物要件」を参照）:
- `comprehensive`: 通常のリリース準備に加え、ロールバック手順を詳細化（手順書作成、ロールバック判定基準の明記）
- `minimal` / `standard`: 変更なし（現行動作）

- **ステップ開始時**: progress.mdでステップ7を「進行中」に更新。**セミオートゲート判定**: `steps/operations/index.md` の「§2.6 automation_mode 分岐」に従う（詳細: `common/rules-automation.md`）。

**サブステップ一覧**（順番に実行、各サブステップの詳細手順は `steps/operations/operations-release.md` および `scripts/operations-release.sh` を参照して従うこと）:
1. 7.1 バージョン確認
2. 7.2 CHANGELOG更新（`changelog = true` の場合）
3. 7.3 README更新
4. 7.4 履歴記録
5. 7.5 Markdownlint実行
6. 7.6 progress.md更新 ← **PR準備完了**
7. 7.7 Gitコミット

**注**: 7.6でprogress.mdを「PR準備完了」状態に更新し、7.7でコミットしてPRに反映します。以下はレビュー・マージ作業です。

> **[必読] `operations-release.md §7.7`**: §7.7 Git コミットのコミット対象ファイル / 行区切り規約 / 設定依存判定の詳細は `steps/operations/operations-release.md §7.7` を参照する。本ファイル（02-deploy.md）にはサブステップ番号の列挙のみを残し、詳細手順は集約先で管理する。

8. 7.8 ドラフトPR Ready化
9. 7.9 コミット漏れ確認
10. 7.10 リモート同期確認
11. 7.11 mainブランチとの差分チェック
12. 7.12 PRマージ前レビュー
13. 7.13 PRマージ【ユーザー選択: automation_mode に関わらずユーザー確認必須】

- **ステップ完了時**: progress.mdでステップ7を「完了」に更新、完了日を記録

---
