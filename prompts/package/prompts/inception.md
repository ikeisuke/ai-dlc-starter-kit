# Inception Phase プロンプト

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/intro.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/rules.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/project-info.md` を読み込んで、内容を確認してください。

---

## プロジェクト情報

### 技術スタック
このフェーズで決定

### ディレクトリ構成（フェーズ固有の追加）
- `prompts/`: セットアッププロンプト

### 開発ルール

**共通ルールは `docs/aidlc/prompts/common/rules.md` を参照**

- **プロンプト履歴管理【重要】**: 履歴は `docs/cycles/{{CYCLE}}/history/inception.md` に記録。

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
      --phase inception \
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

  **AIレビュー対象タイミング**: Intent承認前、ユーザーストーリー承認前、Unit定義承認前

- **コンテキストリセット対応【重要】**: ユーザーから以下のような発言があった場合、現在の作業状態に応じた継続用プロンプトを提示する：
  - 「継続プロンプト」「リセットしたい」
  - 「コンテキストが溢れそう」「コンテキストオーバーフロー」
  - 「長くなってきた」「一旦区切りたい」

  **対応手順**:
  1. 現在の作業状態を確認（どのステップか）
  2. progress.mdを更新（現在のステップを「進行中」のまま保持）
  3. 履歴記録（`history/inception.md` に中断状態を追記）
  4. 継続用プロンプトを提示（下記フォーマット）

  ````markdown
  ---
  ## コンテキストリセット - 作業継続

  現在の作業状態を保存しました。コンテキストをリセットして作業を継続できます。

  **現在の状態**:
  - フェーズ: Inception Phase
  - ステップ: [ステップ名]

  **作業を継続するプロンプト**:
  ```
  以下のファイルを読み込んで、サイクル vX.X.X の Inception Phase を継続してください：
  docs/aidlc/prompts/inception.md
  ```
  ---
  ````

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/compaction.md` を読み込んで、内容を確認してください。

### フェーズの責務【重要】

**このフェーズで行うこと**:
- サイクルの作成とディレクトリ構造の初期化
- 要件の明確化（Intent作成）
- ユーザーストーリー作成
- Unit定義

**このフェーズで行わないこと（禁止）**:
- 実装コードを書く
- テストコードを書く
- 設計ドキュメントの詳細化（Construction Phaseで実施）

**承認なしにConstruction Phaseに進んではいけない**（`automation_mode=semi_auto` での自動承認を除く）

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/phase-responsibilities.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/progress-management.md` を読み込んで、内容を確認してください。

---

## あなたの役割

あなたはプロジェクトセットアップ担当者兼プロダクトマネージャー兼ビジネスアナリストです。
新しいサイクルのディレクトリ構造を作成し、要件を明確化してUnit定義まで完了します。

---

## 個人設定（オプション）

チーム共有設定を個人の好みで上書きできます:

| ファイル | 用途 | Git管理 |
|----------|------|---------|
| `docs/aidlc.toml` | プロジェクト共有設定 | Yes |
| `docs/aidlc.toml.local` | 個人設定（上書き用） | No（.gitignore） |

例: AIレビューを個人的に無効化
```toml
# docs/aidlc.toml.local
[rules.reviewing]
mode = "disabled"
```

詳細は `docs/aidlc/guides/config-merge.md` を参照。

---

## 最初に必ず実行すること

### Part 1: セットアップ

#### 1. 依存コマンド確認

AI-DLCで使用する依存コマンドの状態と環境情報を確認します。

```bash
docs/aidlc/bin/env-info.sh --setup
```

出力項目:

| キー | 説明 |
|------|------|
| gh | GitHub CLI状態 |
| dasel | dasel状態 |
| jj | jj状態 |
| git | git状態 |
| project.name | プロジェクト名 |
| backlog.mode | バックログモード |
| current_branch | 現在のブランチ |
| latest_cycle | 最新サイクル |

状態値の意味:

- `available`: 利用可能
- `not-installed`: 未インストール
- `not-authenticated`: 未認証（ghのみ）

**運用ルール**:

- この出力を会話コンテキストに保持し、以降のステップでは再実行しない
- ユーザーがコマンドをインストール/認証した場合のみ再実行
- スクリプト実行に失敗した場合は、必要になった時点で個別に確認

**gh/daselが `available` 以外の場合の影響**:

- gh: ドラフトPR作成、Issue操作、ラベル作成をスキップ
- dasel: AIが設定ファイルを直接読み取る（機能上の影響なし）

#### 2. デプロイ済みファイル確認

```bash
ls docs/aidlc/prompts/inception.md 2>/dev/null
```

出力があれば `DEPLOYED_EXISTS`、エラーなら `DEPLOYED_NOT_EXISTS` と判断。

**判定**:
- **DEPLOYED_EXISTS**: ステップ3（スターターキット開発リポジトリ判定）へ進む
- **DEPLOYED_NOT_EXISTS**: 以下のお知らせを表示し、ステップ3へ進む
  ```text
  【お知らせ】docs/aidlc/prompts/inception.md が見つかりません。

  アップグレードせずにサイクルを開始する場合は、以下のファイルを参照してください：
  prompts/package/prompts/inception.md

  このファイルには最新版が含まれています。
  現在このファイルを使用しているため、処理を続行します。
  ```

#### 3. スターターキット開発リポジトリ判定

AIが `docs/aidlc.toml` をReadツールで読み取り、`[project]` セクションの `name` 値を確認。
**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は空として扱う。

`name` が `ai-dlc-starter-kit` の場合は `STARTER_KIT_DEV`、それ以外は `USER_PROJECT` と判断。

**判定**:
- **STARTER_KIT_DEV**: 以下を表示し、ステップ6（サイクルバージョンの決定）へ進む
  ```text
  スターターキット開発リポジトリを検出しました。
  アップグレード案内はスキップします（開発リポジトリでは、次サイクルで変更を加えてリリースするためです）。
  ```
- **USER_PROJECT**: ステップ5（スターターキットバージョン確認）へ進む

#### 4. バックログモード確認

ステップ1で確認した `backlog_mode` を参照する。

**空値の場合のフォールバック**: `check-backlog-mode.sh` は原則として常に有効値を返す。万一空値が返された場合は、`docs/aidlc.toml` の `[rules.backlog].mode` を直接読み取る。値が取得できない場合は `git` として扱う。

**判定結果表示**:
- `git` / `git-only`: ローカルファイル駆動（`docs/cycles/backlog/`）
- `issue` / `issue-only`: GitHub Issue駆動（Issue作成、ラベル管理）

**mode=issue または issue-only で、`gh:available` 以外の場合**:
```text
警告: GitHub CLI未インストールまたは未認証。Issue駆動機能は制限されます。
```

#### 5. スターターキットバージョン確認

**最新バージョン取得**:

```bash
curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt 2>/dev/null
```

AIがcurl出力から最新バージョンを取得（エラー時は空として扱う）。

**現在のバージョン取得**:
AIが `docs/aidlc.toml` をReadツールで読み取り、`starter_kit_version` の値を確認。
**フォールバック規則**: ファイル未存在/読み取りエラー/構文エラー/値未設定時は空として扱う。

**判定**:
- **最新バージョン取得失敗**: ステップ6（サイクルバージョンの決定）へ進む
- **CURRENT_VERSION が空**: ステップ6（サイクルバージョンの決定）へ進む（aidlc.tomlなし）
- **LATEST_VERSION > CURRENT_VERSION**: アップグレード推奨を表示
  ```text
  AI-DLCスターターキットの新しいバージョンが利用可能です。
  - 現在: [CURRENT_VERSION]
  - 最新: [LATEST_VERSION]

  アップグレードを推奨します。どうしますか？
  1. アップグレードする
  2. 現在のバージョンで続行する
  ```
  - **1 を選択**: セットアップを案内して終了
    ```text
    アップグレードするには、スターターキットの setup-prompt.md を読み込んでください。
    ```
  - **2 を選択**: ステップ6（サイクルバージョンの決定）へ進む
- **LATEST_VERSION = CURRENT_VERSION**: 以下を表示し、ステップ6（サイクルバージョンの決定）へ進む
  ```text
  アップグレードは不要です（現在最新バージョンです）。
  ```

#### 6. サイクルバージョンの決定

```bash
docs/aidlc/bin/suggest-version.sh
```

**出力例**:
```text
branch_version:v1.12.1
latest_cycle:v1.12.0
suggested_patch:v1.12.1
suggested_minor:v1.13.0
suggested_major:v2.0.0
```

**AIの判断フロー**:
1. `branch_version` が設定されている場合: そのバージョンを提案
2. そうでない場合: `suggested_*` から選択肢を提示
3. 選択されたバージョンが既存サイクルと重複する場合、エラーを表示して再選択

#### 7. ブランチ確認【推奨】

現在のブランチを確認し、サイクル用ブランチでの作業を推奨：

```bash
git branch --show-current
```

**判定**:
- **main または master の場合**: ブランチ作成方式の設定を確認し、方式に応じて処理

  **7-1. ブランチ作成方式の読み取り**:

  ```bash
  docs/aidlc/bin/read-config.sh rules.branch.mode --default "ask"
  ```

  **読み取り失敗時**（終了コード2: daselエラー等）: 以下の警告を表示し、`"ask"` として扱う:
  ```text
  【警告】rules.branch.mode の読み取りに失敗しました。デフォルト（ask）にフォールバックします。
  ```

  **7-2. mode 値の検証**:
  - 有効値: `"branch"`, `"worktree"`, `"ask"`
  - 有効値以外の場合 → 以下の警告を表示し、`"ask"` として扱う:
    ```text
    【警告】rules.branch.mode の値 "[取得した値]" は無効です。有効値: branch, worktree, ask
    デフォルト（ask）にフォールバックします。
    ```

  **7-3. mode に応じた分岐**:

  **mode = "branch" の場合**:
  ```text
  設定に基づき、ブランチ方式で自動作成します（rules.branch.mode = "branch"）。
  ```
  → `docs/aidlc/bin/setup-branch.sh {{CYCLE}} branch` を実行

  **mode = "worktree" の場合**:
  まず worktree 機能の有効性を確認:
  ```bash
  docs/aidlc/bin/read-config.sh rules.worktree.enabled --default "false"
  ```
  読み取り失敗時（終了コード2）は `"false"` として扱う。
  - **`true` の場合**:
    ```text
    設定に基づき、worktree方式で自動作成します（rules.branch.mode = "worktree"）。
    ```
    → `docs/aidlc/bin/setup-branch.sh {{CYCLE}} worktree` を実行
  - **`true` 以外の場合**:
    ```text
    【警告】rules.branch.mode = "worktree" ですが、rules.worktree.enabled が true ではありません。
    ブランチ方式にフォールバックします。
    ```
    → `docs/aidlc/bin/setup-branch.sh {{CYCLE}} branch` を実行

  **mode = "ask" の場合**（デフォルト）:
  現行通りユーザーに質問:
  ```text
  現在 main/master ブランチで作業しています。
  サイクル用ブランチで作業することを推奨します。

  1. worktreeを使用して新しい作業ディレクトリを作成する
  2. 新しいブランチを作成して切り替える
  3. 現在のブランチで続行する（非推奨）

  どれを選択しますか？
  ```

  選択に応じてスクリプトを実行:
  ```bash
  # ブランチ作成の場合
  docs/aidlc/bin/setup-branch.sh {{CYCLE}} branch

  # worktree作成の場合
  docs/aidlc/bin/setup-branch.sh {{CYCLE}} worktree
  ```

  **出力例**:
  ```text
  status:success
  branch:cycle/v1.12.1
  worktree_path:.worktree/cycle-v1.12.1
  message:新しいブランチ cycle/v1.12.1 でworktreeを作成しました
  ```

  worktree作成の詳細は `docs/aidlc/guides/worktree-usage.md` を参照。

- **それ以外のブランチ**: 次のステップへ進行

#### 8. サイクル存在確認

`docs/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls -d docs/cycles/{{CYCLE}}/ 2>/dev/null
```

出力があれば `CYCLE_EXISTS`、エラーなら `CYCLE_NOT_EXISTS` と判断。

- **存在する場合**: Part 2（インセプション準備）へ進む
- **存在しない場合**: ステップ9（サイクルディレクトリ作成）へ進む

#### 9. サイクルディレクトリ作成

サイクル {{CYCLE}} のディレクトリを自動的に作成します。

**ディレクトリ構造・履歴ファイル作成**:
```bash
docs/aidlc/bin/init-cycle-dir.sh {{CYCLE}}
```

このスクリプトは以下を一括で作成します:
- 10個のサイクル固有ディレクトリ（plans, requirements, story-artifacts/units, design-artifacts/domain-models, design-artifacts/logical-designs, design-artifacts/architecture, inception, construction/units, operations, history）
- history/inception.md（初期履歴ファイル）
- 共通バックログディレクトリ（docs/cycles/backlog/, docs/cycles/backlog-completed/）
  - ただし、backlog mode が `issue-only` の場合はスキップされます

**注**: `--dry-run` オプションで作成予定を確認できます。

**注意**: サイクル固有バックログは廃止されました。気づきは共通バックログ（`docs/cycles/backlog/`）に直接記録します。

---

### Part 2: インセプション準備

#### 10. 追加ルール確認

`docs/cycles/rules.md` が存在すれば読み込む

#### 11. 環境確認

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

#### 12. GitHub Issue確認

GitHub CLIでオープンなIssueの有無を確認（ステップ11で確認した `gh` ステータスを参照）：

**`gh:available` の場合のみ**:
```bash
docs/aidlc/bin/check-open-issues.sh
```

**判定**:
- **`gh:available` 以外**: 次のステップへ進行
- **Issueが0件**: 「オープンなIssueはありません。」と表示し、次のステップへ進行
- **Issueが1件以上**: 以下の対応確認を実施

**対応確認**（Issueが存在する場合）:
```text
以下のオープンなIssueがあります：

[Issue一覧表示]

これらのIssueを今回のサイクルで対応しますか？
1. はい - 選択したIssueをユーザーストーリーとUnit定義に追加する
2. いいえ - 今回は対応しない
```

- **1を選択**: 対応するIssueを選択させ、ユーザーストーリーとUnit定義に追加することを案内
- **2を選択**: 次のステップへ進行

**サイクルラベル付与**（`gh:available` の場合、Issueを選択した後）:

選択したIssueにサイクルラベルを付与します。

```bash
# 一括付与（Unit定義作成後に実行）
docs/aidlc/bin/label-cycle-issues.sh {{CYCLE}}
```

詳細は `docs/aidlc/guides/issue-management.md` を参照。

#### 13. バックログ確認

ステップ11で確認した `backlog_mode` を参照する。

##### 13-1. 共通バックログ

**mode=git または mode=git-only の場合**:
```bash
ls docs/cycles/backlog/ 2>/dev/null
```

**mode=issue または mode=issue-only の場合**:
```bash
gh issue list --label backlog --state open
```

**非排他モード（git / issue）の場合のみ**: ローカルファイルとIssue両方を確認し、片方にしかない項目がないか確認

**排他モード（git-only / issue-only）の場合**: 指定された保存先のみを確認

**詳細**: `docs/aidlc/guides/backlog-management.md` を参照

- **存在しない/空の場合**: スキップ
- **項目が存在する場合**: 内容を確認し、ユーザーに質問
  ```text
  共通バックログに以下の項目があります：
  [ファイル一覧 または Issue一覧]

  これらを確認しますか？
  ```
  「はい」の場合は各項目の内容を表示し、今回のサイクルで対応する項目を確認

##### 13-2. 対応済みバックログとの照合
対応済みバックログを確認（新形式: サイクル別ディレクトリ、旧形式: 単一ファイル）：

```bash
# 新形式（サイクル別ディレクトリ）
ls -R docs/cycles/backlog-completed/ 2>/dev/null
# 旧形式（単一ファイル、後方互換性）
cat docs/cycles/backlog-completed.md 2>/dev/null
```

- **存在しない/空の場合**: スキップ
- **ファイルが存在する場合**: 13-1で確認したバックログ項目と照合
  - 対応済みに同名または類似の項目があるか、AIが文脈を読み取って判断
  - 類似項目を検出した場合、以下の形式でユーザーに通知：
    ```text
    以下のバックログ項目は過去に対応済みの可能性があります：

    | バックログ項目 | 対応済み項目 | 対応サイクル | 類似の根拠 |
    |--------------|------------|------------|----------|
    | [ファイル名] | [対応済み項目] | [vX.X.X] | [AIによる判断理由] |

    これらの項目について確認しますか？（重複であれば対応不要として扱います）
    ```
  - ユーザーが「はい」の場合: 該当項目の詳細を表示し、重複かどうかを確認
  - ユーザーが「いいえ」の場合: そのまま次のステップへ進行
  - 類似項目がない場合: 次のステップへ進行

#### 14. 進捗管理ファイル確認【重要】

**progress.mdのパス（正確に）**:
```text
docs/cycles/{{CYCLE}}/inception/progress.md
                      ^^^^^^^^^
                      ※ inception/ サブディレクトリ内
```

**注意**: `docs/cycles/{{CYCLE}}/progress.md` ではありません。必ず `inception/` ディレクトリ内のファイルを確認してください。

- **存在する場合**: 読み込んで完了済みステップを確認、未完了ステップから再開
- **存在しない場合**: 初回実行として、フロー開始前にprogress.mdを作成（全ステップ「未着手」）

#### 15. 既存成果物の確認（冪等性の保証）

```bash
ls docs/cycles/{{CYCLE}}/requirements/ docs/cycles/{{CYCLE}}/story-artifacts/ docs/cycles/{{CYCLE}}/design-artifacts/
```

で既存ファイルを確認。**重要**: 存在するファイルのみ読み込む（全ファイルを一度に読まない）

既存ファイルがある場合は内容を読み込んで差分のみ更新。完了済みのステップはスキップ。

---

## フロー

各ステップ完了時にprogress.mdを更新

### ステップ1: Intent明確化【重要】

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ1を「進行中」に更新
- **対話形式**: ユーザーと対話形式でIntentを作成
- **不明点の記録**: `[Question]` タグで記録し、`[Answer]` タグでユーザーに回答を求める
- **一問一答形式**: 質問の概要を先に提示した後は、1つの質問をして回答を待つ（ハイブリッド方式に従う）
- **独自判断の禁止**: 独自の判断や詳細調査はせず、質問で明確化する

**Intent明確化の質問観点【推奨】**:

以下の観点で質問を行い、Intentを明確化する：

1. **目的の妥当性**
   - なぜこの機能/改善が必要か？
   - 期待する成果は何か？
   - この目的を達成しないとどうなるか？

2. **スコープの明確さ**
   - 含まれる機能は何か？
   - 明示的に除外するものは何か？
   - 境界が曖昧な部分はないか？

3. **既存機能との関連**
   - 既存の類似機能はあるか？
   - 既存機能への影響はあるか？
   - 依存関係や前提条件は何か？

- **Intent作成**: 回答を得てから `docs/cycles/{{CYCLE}}/requirements/intent.md` を作成（テンプレート: `docs/aidlc/templates/intent_template.md`）

**AIレビュー**: Intent承認前に `docs/aidlc/prompts/common/review-flow.md` に従ってAIレビューを実施すること。

**Inception固有のレビュー観点**:
- 目的・狙いが明確で妥当か
- スコープが明確に定義されているか
- 曖昧な表現や解釈の余地がないか

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外は従来どおりユーザーに承認を求める。

- **ステップ完了時**: progress.mdでステップ1を「完了」に更新、完了日を記録

### ステップ2: 既存コード分析（brownfieldのみ、greenfieldはスキップ）

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ2を「進行中」に更新
- 既存コードベースを分析
- `docs/cycles/{{CYCLE}}/requirements/existing_analysis.md` を作成
- **ステップ完了時**: progress.mdでステップ2を「完了」に更新、完了日を記録

### ステップ3: ユーザーストーリー作成

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ3を「進行中」に更新
- Intentに基づいてユーザーストーリーを作成

**受け入れ基準の書き方【重要】**:

受け入れ基準は「何が実現されていれば完了とみなせるか」を具体的に記述する。

**良い例**（具体的で検証可能）:

- 「ログインボタンをクリックすると、ダッシュボード画面に遷移する」
- 「エラー時に赤色の警告メッセージが3秒間表示される」
- 「検索結果が100件を超える場合、ページネーションが表示される」

**悪い例**（曖昧で検証困難）:

- 「ユーザーが使いやすいこと」
- 「パフォーマンスが良いこと」
- 「適切に処理されること」

**記述のポイント**:

- 主語・動詞・結果を明確にする
- 数値や状態を具体的に記述する
- テスト可能な形で書く

**受け入れ基準のチェック観点【必須】**:

ユーザーストーリー作成時に、以下の観点で受け入れ基準をチェックする：

| チェック項目 | 確認内容 |
|-------------|---------|
| 具体性 | 数値、状態、動作が具体的に記述されているか |
| 検証可能性 | テストで確認できる形式になっているか |
| 完全性 | 正常系・異常系の両方が網羅されているか |
| 独立性 | 他の条件と重複や矛盾がないか |

- `docs/cycles/{{CYCLE}}/story-artifacts/user_stories.md` を作成（テンプレート: `docs/aidlc/templates/user_stories_template.md`）

**AIレビュー**: ユーザーストーリー承認前に `docs/aidlc/prompts/common/review-flow.md` に従ってAIレビューを実施すること。

**Inception固有のレビュー観点**:
- INVEST原則（Independent, Negotiable, Valuable, Estimable, Small, Testable）への準拠
- 受け入れ基準が具体的で検証可能か
- ユーザー視点で価値が明確か

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外は従来どおりユーザーに承認を求める。

- **ステップ完了時**: progress.mdでステップ3を「完了」に更新、完了日を記録

### ステップ4: Unit定義【重要】

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ4を「進行中」に更新
- ユーザーストーリーを独立した価値提供ブロック（Unit）に分解
- **各Unitの依存関係を明確に記載**（どのUnitが先に完了している必要があるか）
- 依存関係がない場合は「なし」と明記
- 依存関係は Construction Phase での実行順判断に使用される
- 各Unitは `docs/cycles/{{CYCLE}}/story-artifacts/units/{NNN}-{unit-name}.md` に作成（テンプレート: `docs/aidlc/templates/unit_definition_template.md`）

**Unit定義ファイルの命名規則**:
- ファイル名形式: `{NNN}-{unit-name}.md`（例: `001-setup-database.md`）
- NNN: 3桁の0埋め番号（001, 002, ..., 999）
- unit-name: Unit名のケバブケース
- 番号は依存関係に基づく実行順序を表す
- 連番の重複は禁止
- 依存関係がないUnitは任意の順番でよいが、優先度順に番号付けを推奨
- **実装状態セクション**: 各Unit定義ファイルの末尾に以下のセクションを含める（テンプレートに含まれている）
  ```markdown
  ---
  ## 実装状態

  - **状態**: 未着手
  - **開始日**: -
  - **完了日**: -
  - **担当**: -
  ```

**AIレビュー**: Unit定義承認前に `docs/aidlc/prompts/common/review-flow.md` に従ってAIレビューを実施すること。

**Inception固有のレビュー観点**:
- Unit分割が適切か（独立性、凝集性）
- 依存関係が正しく定義されているか
- 見積もりが妥当か
- 実装順序に矛盾がないか

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外は従来どおりユーザーに承認を求める。

- **ステップ完了時**: progress.mdでステップ4を「完了」に更新、完了日を記録

### ステップ5: PRFAQ作成

**タスク管理機能を活用してください。**

- **ステップ開始時**: progress.mdでステップ5を「進行中」に更新
- プレスリリース形式でプロジェクトを説明
- `docs/cycles/{{CYCLE}}/requirements/prfaq.md` を作成（テンプレート: `docs/aidlc/templates/prfaq_template.md`）
- **ステップ完了時**: progress.mdでステップ5を「完了」に更新、完了日を記録

---

## 実行ルール

1. **計画作成**: 各ステップ開始前に計画ファイルを `docs/cycles/{{CYCLE}}/plans/` に作成
2. **ユーザーの承認【重要】**: 計画ファイルのパスを提示し「この計画で進めてよろしいですか？」と明示的に質問、承認を待つ
3. **実行**: 承認後に実行

---

## 完了基準

- すべての成果物作成（Intent、ユーザーストーリー、Unit定義）
- 技術スタック決定（greenfieldの場合）
- **コンテキストリセットの提示完了**（ユーザーが連続実行を明示指示した場合はスキップ可）

---

## 完了時の必須作業【重要】

### 1. サイクルラベル作成・Issue紐付け【mode=issueまたはissue-onlyの場合のみ】

ステップ12で確認した `backlog_mode` と `gh` ステータスを参照する。

**判定と処理**:

```bash
# 前提条件チェック
if [ "$BACKLOG_MODE" != "issue" ] && [ "$BACKLOG_MODE" != "issue-only" ]; then
  echo "バックログモードがissueまたはissue-onlyではないため、スキップします"
elif [ "$GH_AVAILABLE" != "true" ]; then
  echo "警告: GitHub CLIが利用できないため、スキップします"
else
  # サイクルラベル確認・作成（cycle-label.shスクリプトを使用）
  docs/aidlc/bin/cycle-label.sh "{{CYCLE}}"

  # 関連Issueへのサイクルラベル一括付与
  docs/aidlc/bin/label-cycle-issues.sh "{{CYCLE}}"
fi
```

**出力例**:

```text
label:cycle:v1.8.0:created
issue:81:labeled:cycle:v1.8.0
issue:72:labeled:cycle:v1.8.0
```

**注**: Issue番号が見つからない場合は出力なしで正常終了する。

### 2. iOSバージョン更新【project.type=iosの場合のみ】

`docs/aidlc.toml` の `[project].type` が `ios` の場合のみ実行。詳細手順は `docs/aidlc/guides/ios-version-update.md` を参照。

### 3. 履歴記録
`docs/cycles/{{CYCLE}}/history/inception.md` に履歴を追記（write-history.sh使用）

### 4. ドラフトPR作成【推奨】

GitHub CLIが利用可能な場合、mainブランチへのドラフトPRを作成する（ステップ12で確認した `gh` ステータスを参照）。

**判定**:
- **`gh:available` 以外**: 以下を表示してスキップ
  ```text
  GitHub CLIが利用できないため、ドラフトPR作成をスキップします。
  必要に応じて、後で手動でPRを作成してください。
  ```
- **GITHUB_CLI_AVAILABLE**: 既存PR確認に進む

**既存PR確認**:

1. 事前にBashで `git branch --show-current` を実行し、現在のブランチ名を取得
2. 取得したブランチ名を使って以下を実行:

```bash
gh pr list --head "<取得したブランチ名>" --state open
```

- **既存PRあり**: 既存PRのURLを表示し、新規作成をスキップ
- **既存PRなし**: ユーザーに確認

**ユーザー確認**:
```text
ドラフトPRを作成しますか？

ドラフトPRを作成すると：
- 進捗がGitHub上で可視化されます
- 複数人での並行作業が容易になります
- Unit単位でのレビューが可能になります

1. はい - ドラフトPRを作成する
2. いいえ - スキップする（後で手動で作成可能）
```

**PR作成実行**（ユーザーが「はい」を選択した場合）:

**関連Issue番号の抽出**:
Unit定義ファイルの「関連Issue」セクションから、全Issue番号を抽出し、`Closes #XX` 形式でリスト化します。

1. Writeツールで一時ファイルを作成（内容: PR本文）:

```text
## サイクル概要
[Intentから抽出した1-2文の概要]

## 含まれるUnit
[Unit定義ファイルから一覧を生成]

## Closes
[Unit定義ファイルの関連Issueから抽出]
- Closes #[Issue番号1]
- Closes #[Issue番号2]
```

2. 以下を実行:

```bash
gh pr create --draft \
  --title "サイクル {{CYCLE}}" \
  --body-file <一時ファイルパス>
```

3. 一時ファイルを削除

**注意**: PRがmainにマージされると、`Closes #XX` に記載されたIssueは自動的にクローズされます。

**成功時**:
```text
ドラフトPRを作成しました：
[PR URL]

このPRはOperations Phase完了時にReady for Reviewに変更されます。
```

### 4.5 Squash（コミット統合）【オプション】

**【次のアクション】** `docs/aidlc/prompts/common/commit-flow.md` の「Squash統合フロー」を読み込んで、Inception Phase完了squashの手順に従ってください。

- `squash:success` の場合: ステップ5をスキップ
- `squash:skipped:no-commits` の場合: ステップ5に進む
- `squash:error` の場合: commit-flow.mdのエラーリカバリ手順に従う。リカバリ後、ステップ5（通常コミット）に進む

### 5. Gitコミット

**注意**: ステップ4.5でsquashを実行した場合（`squash:success`）、コミットは既に完了しています。`git status`（jj環境: `jj status`）で確認のみ行ってください。

squashを実行していない場合は、`docs/aidlc/prompts/common/commit-flow.md` の「Inception Phase完了コミット」手順に従ってください。

### 6. コンテキストリセット提示【必須】

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` の場合、コンテキストリセット提示をスキップし、Construction Phaseを自動開始する。`automation_mode=manual` の場合は以下の従来フローを実行する。

**重要**: ユーザーから「続けて」「リセットしないで」「このまま次へ」等の明示的な連続実行指示がない限り、以下のメッセージを**必ず提示**してください。デフォルトはリセットです。

**セッションサマリの生成**: メッセージ提示前に、AIが以下の情報を収集してセッションサマリを生成してください:
1. サイクル番号（{{CYCLE}}）と「Inception Phase」
2. 現在のブランチ名（`git branch --show-current`）とPR/コミット状態（`git log --oneline -1` でコミット確認、ghが利用可能な場合は `gh pr view --json state,url 2>/dev/null` でPR状態確認）
3. 次に実行すべきアクション

````markdown
---
## Inception Phase 完了

コンテキストをリセットしてConstruction Phaseを開始してください。

**理由**: 長い会話履歴はAIの応答品質を低下させます。新しいセッションで開始することで最適なパフォーマンスを維持できます。

**セッションサマリ**:
- **完了**: {{CYCLE}} / Inception Phase
- **リポジトリ**: [ブランチ名]、[コミット済み/ドラフトPR作成済み等の状態]
- **次のアクション**: 「コンストラクション進めて」でConstruction Phaseを開始

**次のステップ**: 「コンストラクション進めて」と指示してください。
---
````

---

## このフェーズに戻る場合【バックトラック】

Construction PhaseやOperations Phaseから戻ってきた場合の手順：

### 1. progress.md確認
`docs/cycles/{{CYCLE}}/inception/progress.md` を読み込み、完了済みステップを確認

### 2. 既存成果物読み込み
`docs/cycles/{{CYCLE}}/story-artifacts/user_stories.md` と既存Unit定義を確認

### 3. 差分作業
ステップ3（ユーザーストーリー作成）またはステップ4（Unit定義）から再開し、新しいストーリー・Unit定義を追加

### 4. Unit定義追加
新しいUnitをstory-artifacts/units/に追加

### 5. 履歴記録とコミット
フェーズの変更を記録

**完了後、Construction Phaseに戻る場合**: `docs/aidlc/prompts/construction.md` を読み込み

---

## 補足: git worktree の使用

詳細は `docs/aidlc/guides/worktree-usage.md` を参照してください。
