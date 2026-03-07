# Operations Phase プロンプト

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/intro.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/rules.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/project-info.md` を読み込んで、内容を確認してください。

**アップグレード**: `/upgrading-aidlc` スキルを使用してください。

---

## プロジェクト情報

### 技術スタック
Inception/Construction Phaseで決定済み

### ディレクトリ構成（フェーズ固有の追加）
- プロジェクトルートディレクトリ: 実装コード

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

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/context-reset.md` を読み込んで、内容を確認してください。

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/compaction.md` を読み込んで、内容を確認してください。

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

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/phase-responsibilities.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/progress-management.md` を読み込んで、内容を確認してください。

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

- **存在しない場合**: エラーを表示し、inception.md を案内
  ```text
  エラー: サイクル {{CYCLE}} が見つかりません。

  既存のサイクル:
  [ls docs/cycles/ の結果]

  サイクルを作成するには、以下のプロンプトを読み込んでください：
  docs/aidlc/prompts/inception.md
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

**`backlog_mode:` が空値の場合**（原則発生しない）: AIは `docs/aidlc.toml` を読み込み、`[rules.backlog]` セクションの `mode` 値を取得（デフォルト: `git`）。

### 2.6 セッション判別設定

`session-title` スキルを実行し、ターミナルのタブタイトルとバッジを設定する（macOS専用、非macOS環境では自動スキップ。エラー時もスキップして続行）。

引数: `project.name`=`docs/aidlc.toml` の `[project].name`、`phase`=`Operations`、`cycle`=`{{CYCLE}}`（不明時は `unknown`）

### 2.7 Depth Level確認

`common/rules.md` の「Depth Level仕様」セクションに従い、成果物詳細度を確認する。

```bash
docs/aidlc/bin/read-config.sh rules.depth_level.level --default "standard"
```

取得した値をコンテキスト変数 `depth_level` として保持する。バリデーション（正規化・有効値チェック・無効値時フォールバック）は `common/rules.md` の「バリデーション仕様」に従う。

### 3. 進捗管理ファイル確認【重要】

**progress.mdのパス（正確に）**:
```text
docs/cycles/{{CYCLE}}/operations/progress.md
                      ^^^^^^^^^^
                      ※ operations/ サブディレクトリ内
```

**注意**: `docs/cycles/{{CYCLE}}/progress.md` ではありません。必ず `operations/` ディレクトリ内のファイルを確認してください。

- **存在する場合**: 読み込んで完了済みステップを確認、未完了ステップから再開
- **存在しない場合**: 初回実行として、フロー開始前にprogress.mdを作成（ステップ0-6を「未着手」、`docs/aidlc.toml` の `project.type` に応じて配布ステップ（ステップ4）を「スキップ」に設定）

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

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）:

承認ポイントID: `operations.startup.unit_verification`

- `automation_mode=semi_auto` かつ全Unit完了の場合: `auto_approved` として自動遷移（ユーザー確認なしで「全Unit完了の場合」の出力を表示し、次ステップへ進む）。履歴記録
- `automation_mode=semi_auto` かつ未完了Unitがある場合: `fallback`（reason_code: `incomplete_conditions`）として従来フロー（ユーザー確認）へ。履歴記録
- `automation_mode=semi_auto` かつUnit状態の判定に失敗した場合: `fallback`（reason_code: `error`）として従来フロー（ユーザー確認）へ。履歴記録
- `automation_mode=manual`: ゲート判定スキップ、従来フローを実行

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

### 7. Construction引き継ぎタスク確認【重要】

Construction Phaseで発生した手動作業タスクを確認し、実行します。

**ディレクトリ構造**:
- 配置場所: `docs/cycles/{{CYCLE}}/operations/tasks/`
- ファイル名: `{NNN}-{task-slug}.md`（NNN = 3桁ゼロパディング）
- 各ファイルに1つの手動作業を記録

**タスクの確認**:

```bash
ls docs/cycles/{{CYCLE}}/operations/tasks/ 2>/dev/null
```

**タスクが存在する場合**:

1. 各タスクファイルを読み込み、内容を確認
2. タスク一覧をユーザーに提示:

```text
【Construction引き継ぎタスク一覧】

以下の手動作業タスクがConstruction Phaseから引き継がれています:

| # | タスク名 | 発生Unit | 緊急度 | 状態 |
|---|----------|----------|--------|------|
| 001 | [タスク名] | Unit NNN | 高/中/低 | 未実行 |
| 002 | [タスク名] | Unit NNN | 高/中/低 | 未実行 |

これらのタスクを確認・実行しますか？

1. はい - タスクを順番に確認・実行する
2. 後で実行する - ステップ5（バックログ整理）で対応
```

**「はい」の場合**:

各タスクについて:
1. タスク内容（作業手順、完了条件）を表示
2. ユーザーが作業を実行
3. 完了後、タスクファイルの「実行状態」セクションを更新:
   - 状態: 未実行 → 完了
   - 実行日: 現在日付
   - 実行者: @username または -

**「後で実行する」の場合**: ステップ5で再度確認

**タスクが存在しない場合**:

```text
Construction Phaseからの引き継ぎタスクはありません。
```

次のステップへ進む。

---

## フロー

各ステップ完了時にprogress.mdを更新

### ステップ0: 変更確認

**タスク管理機能を活用してください。**

ステップ1-4の確認をスキップするかどうかを確認します。

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` の場合、「いいえ」（変更なし）を自動選択し、ステップ1-4をスキップする。`automation_mode=manual` の場合は従来どおりユーザーに確認する。

**確認メッセージ**（`automation_mode=manual` の場合）:
```text
以下の項目で変更したい箇所はありますか？

- ステップ1: デプロイ準備
- ステップ2: CI/CD構築
- ステップ3: 監視・ロギング戦略
- ステップ4: 配布

1. はい - 変更したい項目がある
2. いいえ - 変更なし（ステップ1-4をスキップしてステップ5へ）
```

**選択に応じた処理**:
- **「はい」選択時**: progress.mdでステップ0を「完了」に更新し、ステップ1から順に確認フローを実行（ステップ1-4 → ステップ5 → ステップ6）
- **「いいえ」選択時**: 以下を実行
  1. progress.mdでステップ0を「完了」、ステップ1-4を「スキップ」に更新
  2. 履歴に「ステップ1-4をスキップ（変更なしを選択）」と記録
  3. ステップ5（バックログ整理と運用計画）に進む

**注意**: `docs/cycles/rules.md`にカスタムワークフロー（例: アップグレード処理）が定義されている場合、それはスキップ対象外です。rules.mdの指示に従って実行してください。

### ステップ1: デプロイ準備【対話形式】

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ1を「進行中」に更新
- **対話形式**: 不明点は `[Question]` / `[Answer]` タグで記録し、**一問一答形式**でユーザーと対話しながら準備（1つの質問をして回答を待ち、複数の質問をまとめて提示しない）

- **成果物**: `docs/cycles/{{CYCLE}}/operations/deployment_checklist.md`（テンプレート: `docs/aidlc/templates/deployment_checklist_template.md`）
- **ステップ完了時**: progress.mdでステップ1を「完了」に更新、完了日を記録

### ステップ2: CI/CD構築【対話形式】

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ2を「進行中」に更新
- **対話形式**: 同様に**一問一答形式**で対話
- **成果物**: `docs/cycles/{{CYCLE}}/operations/cicd_setup.md`、CI/CD設定ファイル
- **ステップ完了時**: progress.mdでステップ2を「完了」に更新、完了日を記録

### ステップ3: 監視・ロギング戦略【対話形式】

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ3を「進行中」に更新
- **対話形式**: 同様に**一問一答形式**で対話
- **成果物**: `docs/cycles/{{CYCLE}}/operations/monitoring_strategy.md`（テンプレート: `docs/aidlc/templates/monitoring_strategy_template.md`）
- **ステップ完了時**: progress.mdでステップ3を「完了」に更新、完了日を記録

### ステップ4: 配布【対話形式】

**タスク管理機能を活用してください。**

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

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ5を「進行中」に更新
- **対話形式**: 同様に**一問一答形式**で対話

#### 5.0 Construction引き継ぎタスク再確認

ステップ7で「後で実行する」を選択した引き継ぎタスクがある場合、ここで再確認・実行する。

```bash
ls docs/cycles/{{CYCLE}}/operations/tasks/ 2>/dev/null
```

**未実行タスクがある場合**: 各タスクの実行状態を確認し、未実行のものを実行する。

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

**注意**: この判定は暫定であり、最終確定はステップ6.7（PRマージ）直前のCloses確認結果に従う。PRマージまでにClosesセクションが変更された場合は再判定が必要。

対応済み項目の手動クローズ（自動クローズ対象外のみ）:
```bash
docs/aidlc/bin/issue-ops.sh close {ISSUE_NUMBER}
```

**出力例**: `issue:123:closed`

**全Issueが自動クローズ対象の場合**:
```text
全対応済みIssueはPRマージ時に自動クローズされます。手動クローズは不要です。
```

**非排他モード（git / issue）の場合のみ**: ローカルファイルとIssue両方を確認し、片方にしかない項目がないか確認

**排他モード（git-only / issue-only）の場合**: 指定された保存先のみを確認

**詳細**: `docs/aidlc/guides/backlog-management.md` を参照

**未対応の項目**: 共通バックログにそのまま残す（次サイクル以降で対応）

#### 5.2 リリース後運用計画

- **成果物**: `docs/cycles/{{CYCLE}}/operations/post_release_operations.md`（テンプレート: `docs/aidlc/templates/post_release_operations_template.md`）
- **ステップ完了時**: progress.mdでステップ5を「完了」に更新、完了日を記録

### ステップ6: リリース準備

**タスク管理機能を活用してください。**

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `comprehensive`: 通常のリリース準備に加え、ロールバック手順を詳細化（手順書作成、ロールバック判定基準の明記）
- `minimal` / `standard`: 変更なし（現行動作）

- **ステップ開始時**: progress.mdでステップ6を「進行中」に更新

**サブステップ一覧**（順番に実行、詳細は operations-release.md が正本）:
1. 6.0 バージョン確認
2. 6.1 CHANGELOG更新（`changelog = true` の場合）
3. 6.2 README更新
4. 6.3 履歴記録
5. 6.4 Markdownlint実行
6. 6.4.5 progress.md更新 ← **PR準備完了**
7. 6.5 Gitコミット

**注**: 6.4.5でprogress.mdを「PR準備完了」状態に更新し、6.5でコミットしてPRに反映します。以下はレビュー・マージ作業です。

8. 6.6 ドラフトPR Ready化
9. 6.6.5 コミット漏れ確認
10. 6.6.6 リモート同期確認
11. 6.7 PRマージ

**【次のアクション】** 今すぐ `docs/aidlc/prompts/operations-release.md` を読み込んで、各サブステップの詳細手順に従ってください。

- **ステップ完了時**: progress.mdでステップ6を「完了」に更新、完了日を記録

---

## 実行ルール

1. **計画作成**: 各ステップ開始前に計画ファイルを `docs/cycles/{{CYCLE}}/plans/` に作成
2. **ユーザーの承認【重要】**: 計画ファイルのパスを提示し「この計画で進めてよろしいですか？」と明示的に質問、承認を待つ
   - **セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外は従来どおりユーザーに承認を求める
3. **実行**: 承認後に実行

---

## 完了基準

- すべて完成
- デプロイ完了
- CI/CD動作
- 監視開始
- PRマージ完了
- **コンテキストリセットの提示完了**（ユーザーが連続実行を明示指示した場合はスキップ可）

---

## 完了時の確認【重要】

Operations Phaseの完了時には、以下を確認してください:

1. **ステップ6（リリース準備）がPR準備完了している**こと
   - バージョン確認、バージョンファイル更新（AI-DLCスターターキットのみ）、CHANGELOG更新（`changelog = true`の場合）、README更新、履歴記録、Markdownlint実行、progress.md更新、Gitコミットが完了
   - progress.mdでステップ6が「完了」（= PR準備完了）になっている
   - **注**: 6.6-6.7はPR準備完了後のレビュー・マージ作業

2. **全ステップが完了している**こと
   - progress.mdで全ステップ（0-6、配布スキップの場合は4除く、変更なし選択時は1-4も「スキップ」）が「完了」または「スキップ」

3. **コンテキストリセットの提示が完了している**こと（ユーザーが連続実行を明示指示した場合はスキップ可）
   - 「AI-DLCサイクル完了」セクションのStep 6でリセットメッセージをユーザーに提示済み

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

## AI-DLCサイクル完了【重要・コンテキストリセット必須】

### 1. フィードバック収集
ユーザーからのフィードバック、メトリクス、課題を収集

### 2. 分析と改善点洗い出し
次期バージョンで対応すべき改善点をリストアップ

### 3. バックログ記録
次サイクルに引き継ぐタスクがある場合、バックログに記録（ステップ2.5で確認した `backlog_mode` を参照）：

**mode=git または mode=git-only の場合**:
記録先: `docs/cycles/backlog/{種類}-{スラッグ}.md`

**種類（prefix）**: `feature-`, `bugfix-`, `chore-`, `refactor-`, `docs-`, `perf-`, `security-`

**ファイル内容**: テンプレート `docs/aidlc/templates/backlog_item_template.md` を参照

**mode=issue または mode=issue-only の場合**: GitHub Issueを作成（ガイド: `docs/aidlc/guides/backlog-management.md`）

### 4. 次期サイクルの計画
新しいサイクル識別子を決定（例: v1.0.1 → v1.1.0, 2024-12 → 2025-01）

### 5. PRマージ後の手順【重要】

PRがマージされたら、次サイクル開始前に以下を実行：

0. **未コミット変更の確認**:

   ```bash
   git status --porcelain
   ```

   **空でない場合**:

   ```text
   【注意】未コミットの変更があります。
   通常、この時点で未コミット変更は存在しないはずです（6.6.5で確認済み）。

   変更されているファイル:
   {git status --porcelain の実行結果をここに貼り付け}

   対応方法を選択してください：
   1. コミットする（推奨）- 変更を履歴として残す
   2. stashする - 一時的に退避してcheckout後に復元
   3. 破棄する - 誤生成/一時ファイルのみ（progress.md, history, Unit定義は破棄NG）
   ```

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

### 6. 次のサイクル開始【必須】

**重要**: ユーザーから「続けて」「リセットしないで」「このまま次へ」等の明示的な連続実行指示がない限り、以下のメッセージを**必ず提示**してください。デフォルトはリセットです。

**メッセージ表示前の準備**:

1. AIが `docs/aidlc.toml` をReadツールで読み取り、`[paths]` セクションの `setup_prompt` 値を確認。
   **フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は `prompts/setup-prompt.md` を使用。

2. **セッションサマリの生成**: AIが以下の情報を収集してセッションサマリを生成してください:
   - サイクル番号（{{CYCLE}}）
   - 現在のブランチ名（`git branch --show-current`）とPR/コミット状態（`git log --oneline -1` でコミット確認、ghが利用可能な場合は `gh pr view --json state,url 2>/dev/null` でPR状態確認）
   - 次に実行すべきアクション

以下のメッセージで `${SETUP_PROMPT}` を取得した値で置換してください：

````markdown
---
## サイクル完了

コンテキストをリセットして次のサイクルを開始してください。

**理由**: 長い会話履歴はAIの応答品質を低下させます。新しいセッションで開始することで最適なパフォーマンスを維持できます。

**セッションサマリ**:
- **完了**: サイクル {{CYCLE}}
- **リポジトリ**: [ブランチ名]、[PRマージ済み/タグ作成済み等の状態]
- **次のアクション**: 「start inception」で次のサイクルを開始

**次のステップ**: 「start inception」と指示してください。

**AI-DLCスターターキットをアップグレードする場合**: `/upgrading-aidlc` スキルを実行してください。
---
````

**必要に応じて前バージョンのファイルをコピー/参照**:
- `docs/cycles/rules.md` → 全サイクル共通なので引き継がれます
- `docs/cycles/vX.X.X/requirements/intent.md` → 新サイクルで参照して改善点を反映
- その他、引き継ぎたいファイルがあればコピー

セットアップ完了後、新しいセッションで Inception Phase を開始

---

### 7. ライフサイクルの継続
Inception → Construction → Operations → (次サイクル) を繰り返し、継続的に価値を提供
