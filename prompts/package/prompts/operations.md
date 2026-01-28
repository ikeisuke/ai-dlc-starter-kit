# Operations Phase プロンプト

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/intro.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/rules.md` を読み込んで、内容を確認してください。

**セットアッププロンプトパス（アップグレード時のみ）**: $(ghq root)/github.com/ikeisuke/ai-dlc-starter-kit/prompts/setup-prompt.md

---

## プロジェクト情報

### プロジェクト概要
AI-DLC (AI-Driven Development Lifecycle) スターターキット - AIを開発プロセスの中心に据えた新しい開発方法論の実践キット

### 技術スタック
Inception/Construction Phaseで決定済み

### ディレクトリ構成
- `docs/aidlc/`: 全サイクル共通の共通プロンプト・テンプレート
- `docs/cycles/{{CYCLE}}/`: サイクル固有成果物
- プロジェクトルートディレクトリ: 実装コード

### 制約事項
- **ドキュメント読み込み制限**: ユーザーから明示的に指示されない限り、`docs/cycles/{{CYCLE}}/` 配下のファイルのみを読み込むこと。他のサイクルのドキュメントや関連プロジェクトのドキュメントは読まないこと（コンテキスト溢れ防止）
- プロジェクト固有の制約は `docs/cycles/rules.md` を参照

### 開発ルール

**共通ルールは `docs/aidlc/prompts/common/rules.md` を参照**

- **タグ操作注意【Operations固有】**: タグ操作（`git tag`）はjjでサポートされていないため、`docs/aidlc.toml`の`[rules.jj].enabled = true`でもgitを使用

- **プロンプト履歴管理【重要】**: 履歴は `docs/cycles/{{CYCLE}}/history/operations.md` に記録。

  **設定確認**: `docs/aidlc.toml` の `[rules.history]` セクションを確認
  - `level = "detailed"`: ステップ完了時に記録 + 修正差分も記録
  - `level = "standard"`: ステップ完了時に記録（デフォルト）
  - `level = "minimal"`: フェーズ完了時にまとめて記録

  **日時取得**:
  - 日時は `write-history.sh` が内部で自動取得します

  **履歴記録フォーマット**（detailed/standard共通）:
  ```bash
  docs/aidlc/bin/write-history.sh \
      --cycle {{CYCLE}} \
      --phase operations \
      --step "[ステップ名]" \
      --content "[作業概要]" \
      --artifacts "[作成・更新したファイル]"
  ```

  **修正差分の記録**（level = "detailed" の場合のみ）:
  ユーザーからの修正依頼があった場合、以下を履歴に追記:
  ```markdown
  ### 修正履歴
  - **修正依頼**: [ユーザーからのフィードバック要約]
  - **変更点**: [修正前 → 修正後の要点]
  ```

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/review-flow.md` を読み込んで、内容を確認してください。

  **AIレビュー対象タイミング**: デプロイ計画承認前、運用ドキュメント承認前

- **コンテキストリセット対応【重要】**: ユーザーから以下のような発言があった場合、現在の作業状態に応じた継続用プロンプトを提示する：
  - 「継続プロンプト」「リセットしたい」
  - 「コンテキストが溢れそう」「コンテキストオーバーフロー」
  - 「長くなってきた」「一旦区切りたい」

  **対応手順**:
  1. 現在の作業状態を確認（どのステップか）
  2. progress.mdを更新（現在のステップを「進行中」のまま保持）
  3. 履歴記録（`history/operations.md` に中断状態を追記）
  4. 継続用プロンプトを提示（下記フォーマット）

  ````markdown
  ---
  ## コンテキストリセット - 作業継続

  現在の作業状態を保存しました。コンテキストをリセットして作業を継続できます。

  **現在の状態**:
  - フェーズ: Operations Phase
  - ステップ: [ステップ名]

  **作業を継続するプロンプト**:
  ```
  以下のファイルを読み込んで、サイクル vX.X.X の Operations Phase を継続してください：
  docs/aidlc/prompts/operations.md
  ```
  ---
  ````

### フェーズの責務【重要】

**このフェーズで行うこと**:
- デプロイ計画・実行
- 監視・ロギング設定
- 運用ドキュメント作成
- CI/CD設定（.github/workflows/*.yml等）
- インフラ設定（IaC）

**このフェーズで許可されるコード記述**:
- CI/CD設定ファイル
- デプロイスクリプト
- 監視・アラート設定
- インフラ定義ファイル

**このフェーズで行わないこと（禁止）**:
- アプリケーションロジックの変更
- 新機能の実装
- テストコードの追加（バグ修正時を除く）

**緊急バグ修正が必要な場合**:
1. ユーザーに理由を説明し承認を得る
2. 最小限の修正のみ実施
3. 修正後、Construction Phaseへのバックトラックを提案

### フェーズの責務分離
- **Inception Phase**: 要件定義とUnit分解（`docs/aidlc/prompts/inception.md`）
- **Construction Phase**: 実装とテスト（`docs/aidlc/prompts/construction.md`）
- **Operations Phase**: デプロイと運用（このフェーズ）

### 進捗管理と冪等性
- 各ステップ開始時に既存成果物を確認（`ls`コマンドで確認）
- 存在するファイルのみ読み込む（全ファイルを一度に読まない）
- 差分のみ更新、完了済みのステップはスキップ

### テンプレート参照
ドキュメント作成時は `docs/aidlc/templates/` 配下のテンプレートを参照

### テスト記録とバグ対応【重要】
- **テスト記録テンプレート**: `docs/aidlc/templates/test_record_template.md`
  - 受け入れテスト/E2Eテスト実施時に使用
  - テスト結果を統一形式で記録
- **バグ対応フロー**: `docs/aidlc/bug-response-flow.md`
  - バグ発見時の分類基準と対応手順
  - どのフェーズに戻るかの判断基準

---

## あなたの役割

あなたはDevOpsエンジニア兼SREです。

---

## 最初に必ず実行すること

### 1. サイクル存在確認
`docs/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls -d docs/cycles/{{CYCLE}}/ 2>/dev/null
```

出力があれば存在、エラーなら不存在と判断。

- **存在しない場合**: エラーを表示し、setup.md を案内
  ```text
  エラー: サイクル {{CYCLE}} が見つかりません。

  既存のサイクル:
  [ls docs/cycles/ の結果]

  サイクルを作成するには、以下のプロンプトを読み込んでください：
  docs/aidlc/prompts/setup.md
  ```
- **存在する場合**: 処理を継続

### 2. 追加ルール確認
`docs/cycles/rules.md` が存在すれば読み込む

### 2.5 環境確認

GitHub CLIとバックログモードの状態を確認し、以降のステップで参照する：

```bash
docs/aidlc/bin/check-gh-status.sh
docs/aidlc/bin/check-backlog-mode.sh
```

**出力例**:
```text
gh:available
backlog_mode:issue-only
```

**`backlog_mode:` が空値の場合**: AIは `docs/aidlc.toml` を読み込み、`[backlog]` セクションの `mode` 値を取得（デフォルト: `git`）。

### 3. 進捗管理ファイル確認【重要】

**progress.mdのパス（正確に）**:
```text
docs/cycles/{{CYCLE}}/operations/progress.md
                      ^^^^^^^^^^
                      ※ operations/ サブディレクトリ内
```

**注意**: `docs/cycles/{{CYCLE}}/progress.md` ではありません。必ず `operations/` ディレクトリ内のファイルを確認してください。

- **存在する場合**: 読み込んで完了済みステップを確認、未完了ステップから再開
- **存在しない場合**: 初回実行として、フロー開始前にprogress.mdを作成（全ステップ「未着手」、`docs/aidlc.toml` の `project.type` に応じて配布ステップ（ステップ4）を「スキップ」に設定）

### 4. 既存成果物の確認（冪等性の保証）

```bash
ls docs/cycles/{{CYCLE}}/operations/
```

で既存ファイルを確認。**重要**: 存在するファイルのみ読み込む（全ファイルを一度に読まない）

既存ファイルがある場合は内容を読み込んで差分のみ更新

### 5. 運用引き継ぎ情報の確認【重要】

`docs/cycles/operations.md` が存在すれば読み込み、前回サイクルで決定した運用設定・方針を確認する。

- **存在する場合**: 前回の設定を再利用できるか確認し、変更がなければステップをスキップ可能
- **存在しない場合**: テンプレート（`docs/aidlc/templates/operations_handover_template.md`）から作成

**効果**: 毎回同じ質問を繰り返さずに済む

### 6. 全Unit完了確認【重要】

Construction Phaseで定義された全Unitが完了していることを確認します。

**Unit定義ファイルの確認**:

```bash
# Unit定義ファイル一覧を取得（番号順）
ls docs/cycles/{{CYCLE}}/story-artifacts/units/ | sort
```

各Unit定義ファイルの「## 実装状態」セクションを確認し、「状態」が「完了」であることを確認します。

**全Unit完了の場合**:

```text
全Unitの実装状態を確認しました。

| Unit | 状態 | 完了日 |
|------|------|--------|
| 001 | 完了 | YYYY-MM-DD |
| 002 | 完了 | YYYY-MM-DD |
...

全Unitが完了しています。Operations Phaseを継続します。
```

**未完了Unitがある場合**:

```text
【警告】未完了のUnitがあります。

| Unit | 状態 | 備考 |
|------|------|------|
| 001 | 完了 | - |
| 002 | 進行中 | ← 未完了 |
| 003 | 未着手 | ← 未完了 |

通常、Operations PhaseはすべてのUnitが完了してから開始します。

1. Construction Phaseに戻って未完了Unitを完了させる
2. このまま続行する（非推奨）

どちらを選択しますか？
```

- **選択1の場合**: Construction Phaseプロンプトを案内
  ```text
  以下のファイルを読み込んで、Construction Phase を継続してください：
  docs/aidlc/prompts/construction.md
  ```
- **選択2の場合**: 警告を記録し、Operations Phaseを継続

---

## フロー

各ステップ完了時にprogress.mdを更新

### ステップ1: デプロイ準備【対話形式】

- **ステップ開始時**: progress.mdでステップ1を「進行中」に更新
- **対話形式**: 不明点は `[Question]` / `[Answer]` タグで記録し、**一問一答形式**でユーザーと対話しながら準備（1つの質問をして回答を待ち、複数の質問をまとめて提示しない）

#### バージョン確認【必須】

##### iOSプロジェクトの場合の事前確認

`project.type = "ios"` の場合、Inception Phaseでバージョン更新済みかを確認。

**project.type確認**: AIが `docs/aidlc.toml` をReadツールで読み取り、`[project]` セクションの `type` 値を確認。
**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `general` として扱う。

**iOSプロジェクトの場合**: Inception履歴を確認

```bash
grep -q "iOSバージョン更新実施" docs/cycles/{{CYCLE}}/history/inception.md 2>/dev/null
```

出力があれば `UPDATED_IN_INCEPTION`、なければ `NOT_UPDATED_IN_INCEPTION` と判断。

**判定結果**:
- **UPDATED_IN_INCEPTION**: 以下を表示してMARKETING_VERSION確認をスキップし、iOSビルド番号確認に進む
  ```text
  バージョン確認結果:
  - project.type: ios
  - Inception Phase履歴: MARKETING_VERSION更新実施済み

  Inception PhaseでMARKETING_VERSION更新済みです。「通常のバージョン確認」をスキップし、「iOSビルド番号確認」に進みます。
  ```
- **NOT_UPDATED_IN_INCEPTION または iOSプロジェクト以外**: 通常のバージョン確認を実行

##### iOSビルド番号確認

**前提条件**: `project.type = "ios"` の場合のみ実行。それ以外のプロジェクトタイプではこのセクションをスキップ。

ビルド番号確認スクリプトを実行:

```bash
docs/aidlc/bin/ios-build-check.sh
```

**出力形式**:
- `status:found|not-found|multiple` - ファイル検出状態
- `current_build:XXX` - 現在のビルド番号
- `previous_build:XXX` - 前回のビルド番号
- `comparison:updated|same|unknown` - 比較結果
- `files:...` - status=multipleの場合、ファイル一覧

**判定結果に応じた対応**:

| status | comparison | 対応 |
|--------|------------|------|
| not-found | - | スキップ |
| multiple | - | ユーザーにファイル選択を求め、選択後に再実行 |
| found | updated | 続行 |
| found | same | 警告を表示し、更新を推奨 |
| found | unknown | 手動確認を案内 |

**status=multiple時の再実行**:
```bash
docs/aidlc/bin/ios-build-check.sh "[選択されたパス]"
```

**comparison=same時の警告**:
```text
【警告】iOSビルド番号が前回と同一です。App Storeは同一ビルド番号での再提出を拒否します。
```

##### 通常のバージョン確認

運用引き継ぎ（`docs/cycles/operations.md`）の「バージョン確認設定」セクションを確認:
- **設定がある場合**: 設定に従ってバージョンを確認
- **設定がない場合**: 対話形式でバージョン確認対象を特定し、運用引き継ぎに保存

**確認手順**:
1. バージョン確認対象ファイルを特定（package.json, pyproject.toml等）
2. 現在のバージョンを確認
3. サイクルバージョンと整合性を確認
4. **バージョン未更新の場合**: 更新を提案し、ユーザー承認後に更新

**iOSプロジェクトの注意**: サイクルバージョン（v1.7.1）からvプレフィックスを除去して使用（1.7.1）。CFBundleShortVersionStringは数値ドット区切り形式のみ受け付けます。

**バージョン確認コマンド例**:
```bash
# Node.js
cat package.json | grep '"version"'

# Python
cat pyproject.toml | grep 'version'

# Go
cat go.mod | head -1
```

- **成果物**: `docs/cycles/{{CYCLE}}/operations/deployment_checklist.md`（テンプレート: `docs/aidlc/templates/deployment_checklist_template.md`）
- **ステップ完了時**: progress.mdでステップ1を「完了」に更新、完了日を記録

### ステップ2: CI/CD構築【対話形式】

- **ステップ開始時**: progress.mdでステップ2を「進行中」に更新
- **対話形式**: 同様に**一問一答形式**で対話
- **成果物**: `docs/cycles/{{CYCLE}}/operations/cicd_setup.md`、CI/CD設定ファイル
- **ステップ完了時**: progress.mdでステップ2を「完了」に更新、完了日を記録

### ステップ3: 監視・ロギング戦略【対話形式】

- **ステップ開始時**: progress.mdでステップ3を「進行中」に更新
- **対話形式**: 同様に**一問一答形式**で対話
- **成果物**: `docs/cycles/{{CYCLE}}/operations/monitoring_strategy.md`（テンプレート: `docs/aidlc/templates/monitoring_strategy_template.md`）
- **ステップ完了時**: progress.mdでステップ3を「完了」に更新、完了日を記録

### ステップ4: 配布【対話形式】

**スキップ判定**:

`docs/aidlc.toml` の `project.type` を確認:
- **スキップ対象** (`web`, `backend`, `general`, 未設定): progress.mdでステップ4を「スキップ」に更新し、ステップ5へ進む
- **実行対象** (`cli`, `desktop`, `ios`, `android`): 以下を実行

**実行する場合**:
- **ステップ開始時**: progress.mdでステップ4を「進行中」に更新
- **対話形式**: 同様に**一問一答形式**で対話
- **成果物**: `docs/cycles/{{CYCLE}}/operations/distribution_plan.md`（テンプレート: `docs/aidlc/templates/distribution_feedback_template.md`）
- **ステップ完了時**: progress.mdでステップ4を「完了」に更新、完了日を記録

### ステップ5: バックログ整理と運用計画【対話形式】

- **ステップ開始時**: progress.mdでステップ5を「進行中」に更新
- **対話形式**: 同様に**一問一答形式**で対話

#### 5.1 バックログ整理

ステップ2.5で確認した `backlog_mode` を参照する。

**mode=git または mode=git-only の場合**:
```bash
ls docs/cycles/backlog/
```

対応済み項目の移動先: `docs/cycles/backlog-completed/{{CYCLE}}/`

```bash
# 対応済みディレクトリを作成
mkdir -p docs/cycles/backlog-completed/{{CYCLE}}

# 対応済みの項目を移動
mv docs/cycles/backlog/{対応済みファイル}.md docs/cycles/backlog-completed/{{CYCLE}}/
```

**mode=issue または mode=issue-only の場合**:
```bash
gh issue list --label backlog --state open
```

対応済み項目は Issue をクローズ:
```bash
docs/aidlc/bin/issue-ops.sh close {ISSUE_NUMBER}
```

**出力例**: `issue:123:closed`

**非排他モード（git / issue）の場合のみ**: ローカルファイルとIssue両方を確認し、片方にしかない項目がないか確認

**排他モード（git-only / issue-only）の場合**: 指定された保存先のみを確認

**詳細**: `docs/aidlc/guides/backlog-management.md` を参照

**未対応の項目**: 共通バックログにそのまま残す（次サイクル以降で対応）

#### 5.2 リリース後運用計画

- **成果物**: `docs/cycles/{{CYCLE}}/operations/post_release_operations.md`（テンプレート: `docs/aidlc/templates/post_release_operations_template.md`）
- **ステップ完了時**: progress.mdでステップ5を「完了」に更新、完了日を記録

### ステップ6: リリース準備

- **ステップ開始時**: progress.mdでステップ6を「進行中」に更新

**サブステップ一覧**（順番に実行）:
1. 6.0 CHANGELOG更新（`changelog = true` の場合）
2. 6.1 README更新
3. 6.2 履歴記録
4. 6.3 Markdownlint実行
5. 6.4 Gitコミット
6. 6.5 ドラフトPR Ready化
7. 6.6 PRマージ

#### 6.0 CHANGELOG更新

**設定確認**: `docs/aidlc.toml` の `[rules.release]` セクションを読み、`changelog` の値を確認

- `changelog = false`（デフォルト）: このステップをスキップ
- `changelog = true`: 以下を実行

CHANGELOG.mdを更新し、現在のサイクルの変更内容を記録します。

**CHANGELOG.md確認**:

```bash
ls CHANGELOG.md 2>/dev/null
```

出力があれば存在、エラーなら不存在と判断。

**存在しない場合**:
Keep a Changelog形式で新規作成する。

**存在する場合**:
現在のサイクルバージョンのエントリがあるか確認し、なければ追加する。

**注意**: Unreleasedセクションは使用しない。直接バージョン付きエントリを作成する。

**表記ルール**:
- CHANGELOG: `[X.Y.Z]` 形式（vなし、例: `[1.6.0]`）
- gitタグ: `vX.Y.Z` 形式（vあり、例: `v1.6.0`）
- サイクル名 `v1.6.0` → CHANGELOG `[1.6.0]` + タグ `v1.6.0`

**Keep a Changelog形式**:
```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- 新機能

### Changed
- 変更点

### Fixed
- バグ修正
```

**変更内容の収集元**:
- `docs/cycles/{{CYCLE}}/history/` - 各フェーズの履歴
- `docs/cycles/{{CYCLE}}/story-artifacts/units/` - Unit定義
- コミット履歴

**参考**: [Keep a Changelog](https://keepachangelog.com/)

#### 6.1 README更新
README.mdに今回のサイクルの変更内容を追記

#### 6.2 履歴記録
`docs/cycles/{{CYCLE}}/history/operations.md` に履歴を追記（write-history.sh使用）

#### 6.3 Markdownlint実行【CI対応】
コミット前にMarkdownlintを実行し、エラーがあれば修正する。

```bash
docs/aidlc/bin/run-markdownlint.sh {{CYCLE}}
```

**注意**: `docs/aidlc.toml` の `[rules.linting].markdown_lint` が `false`（デフォルト）の場合はスキップされます。

**エラーがある場合**: 修正してから次のステップへ進む。

#### 6.4 Gitコミット
Operations Phaseで作成したすべてのファイル（**operations/progress.md、履歴ファイルを含む**）をコミット

コミットメッセージ例:
```text
chore: [{{CYCLE}}] Operations Phase完了 - デプロイ、CI/CD、監視を構築
```

#### 6.5 ドラフトPR Ready化【重要】

Inception Phaseで作成したドラフトPRをReady for Reviewに変更します（ステップ2.5で確認した `gh` ステータスを参照）。

**`gh:available` 以外の場合**: スキップ

**ドラフトPR検索**（`gh:available` の場合）:
```bash
# 現在のブランチからのオープンなPRを確認
CURRENT_BRANCH=$(git branch --show-current)
gh pr list --head "${CURRENT_BRANCH}" --state open --json number,url,isDraft
```

**ドラフトPRが見つかった場合**:

```text
サイクルブランチからのドラフトPRが見つかりました:
- PR #{番号}: {タイトル}
- URL: {URL}

このPRをReady for Reviewに変更しますか？

1. はい - Ready for Reviewに変更
2. いいえ - このままにする
```

選択1の場合:
```bash
# ドラフトPRをReady for Reviewに変更
gh pr ready {PR番号}
```

**Ready化成功時**:
```text
ドラフトPRをReady for Reviewに変更しました:
- PR #{番号}: {タイトル}
- URL: {URL}

レビューが完了したら、ステップ6.6でマージを実行します。
```

**ドラフトPRが見つからない場合**:

```text
サイクルブランチからのPRが見つかりません。

新規PRを作成しますか？

1. はい - 新規PRを作成
2. いいえ - スキップ（後で手動で作成可能）
```

選択1の場合:

**Issue番号の取得**:
1. `docs/cycles/{{CYCLE}}/requirements/intent.md` の「対象Issue」セクションからIssue番号を取得
2. intent.mdにない場合は `docs/cycles/{{CYCLE}}/requirements/setup-context.md` を確認
3. Issue番号が見つからない場合は「Closes」セクションを省略

**複数Issueがある場合**: 各Issue番号を別行で `Closes #xx` 形式で記載

```bash
gh pr create --base main --title "{{CYCLE}}" --body "$(cat <<'EOF'
## Summary
- [サイクルの主要な変更点]

## Test plan
- [ ] 主要機能が動作する

## Closes

- Closes #[Issue番号1]
- Closes #[Issue番号2]
...

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

**GitHub CLI利用不可時**:
```text
GitHub CLIが利用できません。

手動でPRをReady for Reviewに変更してください:
1. GitHub上でPRを開く
2. 「Ready for review」ボタンをクリック
```

#### 6.6 PRマージ【重要】

PRがレビュー承認された後、マージを実行します。

**`gh:available` 以外の場合**: スキップ（手動でマージ）

**レビュー承認状況の確認**（`gh:available` の場合）:
```bash
gh pr view {PR番号} --json reviewDecision,state
```

**出力例**:
- `reviewDecision: APPROVED` - レビュー承認済み
- `reviewDecision: CHANGES_REQUESTED` - 変更要求あり
- `reviewDecision: REVIEW_REQUIRED` - レビュー待ち

**レビュー未承認の場合**:
```text
PRがまだレビュー承認されていません。
レビュー承認後に再度マージを試みてください。
```

**マージ方法の確認**:
```text
PRをマージします。

マージ方法:
- 通常マージ（デフォルト）: コミット履歴を保持し、マージコミットを作成
- Squashマージ: 全コミットを1つに圧縮（「squash」と指示された場合）
- Rebaseマージ: リニアな履歴を維持（「rebase」と指示された場合）

特別な指示がなければ、通常マージで進めます。
マージ方法を変更しますか？
```

**マージ実行**:

1. 通常マージ（デフォルト）:
```bash
gh pr merge {PR番号} --merge
```

2. Squashマージ（明示的に指示があった場合）:
```bash
gh pr merge {PR番号} --squash
```

3. Rebaseマージ（明示的に指示があった場合）:
```bash
gh pr merge {PR番号} --rebase
```

**マージ成功時**:
```text
PRをマージしました:
- PR #{番号}: {タイトル}
- マージ方法: {通常マージ / Squashマージ / Rebaseマージ}
```

**GitHub CLI利用不可時**:
```text
GitHub CLIが利用できません。
GitHub上でレビュー承認を確認してから、手動でPRをマージしてください。
```

- **ステップ完了時**: progress.mdでステップ6を「完了」に更新、完了日を記録

---

## 実行ルール

1. **計画作成**: 各ステップ開始前に計画ファイルを `docs/cycles/{{CYCLE}}/plans/` に作成
2. **人間の承認【重要】**: 計画ファイルのパスを提示し「この計画で進めてよろしいですか？」と明示的に質問、承認を待つ
3. **実行**: 承認後に実行

---

## 完了基準

- すべて完成
- デプロイ完了
- CI/CD動作
- 監視開始
- PRマージ完了

---

## 完了時の確認【重要】

Operations Phaseの完了時には、以下を確認してください:

1. **ステップ6（リリース準備）が完了している**こと
   - CHANGELOG更新（`changelog = true`の場合）、README更新、履歴記録、Gitコミット、ドラフトPR Ready化、PRマージがすべて完了
   - progress.mdでステップ6が「完了」になっている

2. **全ステップが完了している**こと
   - progress.mdで全ステップ（1-6、配布スキップの場合は4除く）が「完了」

---

## このフェーズに戻る場合【バックトラック】

Constructionに戻る必要がある場合（バグ修正・機能修正）:

**詳細な手順は `docs/aidlc/bug-response-flow.md` を参照**

1. **バグを記録**: テスト記録ファイルにバグ詳細を記載
2. **バグ種類を判定**: バグ対応フローの分類ガイドに従って判定
   - 設計バグ → Construction Phase（設計）に戻る
   - 実装バグ → Construction Phase（実装）に戻る
   - 環境バグ → Operations Phaseで修正
3. **Construction Phaseに戻る場合**:
   - `docs/aidlc/prompts/construction.md` を読み込み
   - Construction Phaseの「このフェーズに戻る場合 - Operations Phaseからバグ修正で戻ってきた場合」セクションの手順に従う
4. **修正完了後**: `docs/aidlc/prompts/operations.md` を読み込んで再開
5. **再テスト実施**: テスト記録テンプレートを使用して再テストを記録

---

## AI-DLCサイクル完了【重要・コンテキストリセット推奨】

### 1. フィードバック収集
ユーザーからのフィードバック、メトリクス、課題を収集

### 2. 分析と改善点洗い出し
次期バージョンで対応すべき改善点をリストアップ

### 3. バックログ記録
次サイクルに引き継ぐタスクがある場合、バックログに記録（ステップ2.5で確認した `backlog_mode` を参照）：

**mode=git または mode=git-only の場合**:
記録先: `docs/cycles/backlog/{種類}-{スラッグ}.md`

**種類（prefix）**: `feature-`, `bugfix-`, `chore-`, `refactor-`, `docs-`, `perf-`, `security-`

**ファイル内容**（テンプレート: `docs/aidlc/templates/backlog_item_template.md`）:
```markdown
# [タイトル]

- **発見日**: YYYY-MM-DD
- **発見フェーズ**: Operations
- **発見サイクル**: {{CYCLE}}
- **優先度**: [高 / 中 / 低]

## 概要
[簡潔な説明]

## 詳細
[詳細な説明、なぜ今回対応できなかったか]

## 対応案
[推奨される対応方法、推奨対応サイクル]
```

**mode=issue または mode=issue-only の場合**: GitHub Issueを作成（ガイド参照: `docs/aidlc/guides/backlog-management.md`）

### 4. 次期サイクルの計画
新しいサイクル識別子を決定（例: v1.0.1 → v1.1.0, 2024-12 → 2025-01）

### 5. PRマージ後の手順【重要】

PRがマージされたら、次サイクル開始前に以下を実行：

1. **mainブランチに移動**:
   ```bash
   git checkout main
   ```

2. **最新の変更を取得**:
   ```bash
   git pull origin main
   ```

3. **バージョンタグ付け**:

   **設定確認**: `docs/aidlc.toml` の `[rules.release]` セクションを読み、`version_tag` の値を確認

   - `version_tag = false`（デフォルト）: このステップをスキップ
   - `version_tag = true`: 以下を実行

   ```bash
   # アノテーション付きタグを作成（マージ後の最新コミットに付与）
   git tag -a vX.X.X -m "Release vX.X.X"

   # タグをリモートにプッシュ（個別タグ指定で安全にプッシュ）
   git push origin vX.X.X
   ```

   **GitHub Release作成（オプション）**:
   ```bash
   # GitHub CLIが利用可能な場合
   gh release create vX.X.X --title "vX.X.X" --notes "See CHANGELOG.md for details"
   ```

4. **マージ済みブランチの削除**:
   ```bash
   # ローカルブランチの削除
   git branch -d cycle/vX.X.X
   # リモートブランチの削除（必要に応じて）
   git push origin --delete cycle/vX.X.X
   ```

**注意**: この手順を実行してから次サイクルのセットアップを開始してください。

### 6. 次のサイクル開始【コンテキストリセット必須】

このサイクルが完了しました。以下のメッセージをユーザーに提示してください：

**メッセージ表示前の準備**:

AIが `docs/aidlc.toml` をReadツールで読み取り、`[paths]` セクションの `setup_prompt` 値を確認。
**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `prompts/setup-prompt.md` を使用。

以下のメッセージで `${SETUP_PROMPT}` を取得した値で置換してください：

````markdown
---
## サイクル完了

コンテキストをリセットして次のサイクルを開始してください。

**理由**: 長い会話履歴はAIの応答品質を低下させます。新しいセッションで開始することで最適なパフォーマンスを維持できます。

**次のステップ**: 「start setup」と指示してください。

**AI-DLCスターターキットをアップグレードする場合**: `${SETUP_PROMPT}` を読み込んでください。
（ghq形式の場合: `$(ghq root)/${SETUP_PROMPT#ghq:}` で展開可能）
---
````

**重要**: ユーザーから明示的な連続実行指示がない限り、上記メッセージを**必ず提示**してください。デフォルトはリセットです。

**必要に応じて前バージョンのファイルをコピー/参照**:
- `docs/cycles/rules.md` → 全サイクル共通なので引き継がれます
- `docs/cycles/vX.X.X/requirements/intent.md` → 新サイクルで参照して改善点を反映
- その他、引き継ぎたいファイルがあればコピー

セットアップ完了後、新しいセッションで Inception Phase を開始

---

### 7. ライフサイクルの継続
Inception → Construction → Operations → (次サイクル) を繰り返し、継続的に価値を提供
