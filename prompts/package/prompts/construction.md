# Construction Phase プロンプト

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/intro.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/rules.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/project-info.md` を読み込んで、内容を確認してください。

---

## プロジェクト情報

### 技術スタック
Inception Phaseで決定済み、または既存スタックを使用

### ディレクトリ構成（フェーズ固有の追加）
- プロジェクトルートディレクトリ: 実装コード

### 開発ルール

**共通ルールは `docs/aidlc/prompts/common/rules.md` を参照**

- **プロンプト履歴管理【重要】**: 履歴は `docs/cycles/{{CYCLE}}/history/` ディレクトリにUnit単位でファイル分割して管理。

  **設定確認**: `docs/aidlc.toml` の `[rules.history]` セクションを確認
  - `level = "detailed"`: ステップ完了時に記録 + 修正差分も記録
  - `level = "standard"`: ステップ完了時に記録（デフォルト）
  - `level = "minimal"`: Unit完了時にまとめて記録

  **ファイル命名規則**:
  - `construction_unit{NN}.md` （NN = 2桁ゼロパディングのUnit番号、例: `construction_unit01.md`）

  **日時取得**:
  - 日時は `write-history.sh` が内部で自動取得します

  **履歴記録フォーマット**（detailed/standard共通）:
  ```bash
  docs/aidlc/bin/write-history.sh \
      --cycle {{CYCLE}} \
      --phase construction \
      --unit {N} \
      --unit-name "[Unit名]" \
      --unit-slug "[unit-slug]" \
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

- **気づき記録フロー【重要】**: Unit作業中に別Unitや新規課題に関する気づきがあった場合、以下の手順で記録する
  1. **現在の作業を中断しない**: 気づきの記録のみ行い、現在のUnit作業を継続
  2. **バックログ項目を作成**（ステップ3で確認した `backlog_mode` を参照）:

     **mode=git または mode=git-only の場合**: `docs/cycles/backlog/{種類}-{スラッグ}.md` にファイルを作成（ガイド参照: `docs/aidlc/guides/backlog-management.md`）

     **種類（prefix）**: `feature-`, `bugfix-`, `chore-`, `refactor-`, `docs-`, `perf-`, `security-`

     **ファイル内容**（テンプレート: `docs/aidlc/templates/backlog_item_template.md`）:
     ```markdown
     # [タイトル]

     - **発見日**: YYYY-MM-DD
     - **発見フェーズ**: Construction
     - **発見サイクル**: {{CYCLE}}（名前付きサイクルの場合は name/vX.X.X 形式をそのまま使用）
     - **優先度**: [高 / 中 / 低]

     ## 概要
     [簡潔な説明]

     ## 詳細
     [詳細な説明]

     ## 対応案
     [推奨される対応方法]
     ```

     **mode=issue または mode=issue-only の場合**: GitHub Issueを作成（ガイド参照: `docs/aidlc/guides/backlog-management.md`）

  3. **後続での確認**: 次のUnit開始時または次サイクルのInception Phaseでバックログを確認し、対応を検討

  **サブエージェント活用（オプション）**: バックログ追加処理は、サブエージェントに委任することで効率化できます。詳細は `docs/aidlc/guides/subagent-usage.md` を参照。

- **Workaround（その場しのぎ対応）実施時のルール【重要】**: 本質的な解決ではなく、暫定的な対応（workaround）を行う場合、以下を必ず実施する

  **必須手順**:
  1. **workaroundの実装**: 暫定的な対応を実装
  2. **バックログへの記録**: 本質的な対応をバックログに記録（ガイド参照: `docs/aidlc/guides/backlog-management.md`）
     - prefix: `chore-` または `refactor-`
     - 内容: 本質的な解決策と、なぜworkaroundを選択したかの理由
  3. **コード内TODOコメント**: workaroundを実装したコード箇所に以下形式でコメント
     ```text
     // TODO: workaround - see backlog (mode に応じた保存先を参照)
     ```

  **workaroundの例**:
  - 時間的制約で簡易実装を選択した場合
  - 依存ライブラリの問題を回避するための一時的な対処
  - 本質的な設計変更が必要だが、現在のスコープ外の場合

- **割り込み対応フロー【重要】**: ユーザーから作業中に追加の要望・タスクがあった場合、以下の3分類で対応する

  | 分類 | 判定基準 | 対応 |
  |------|----------|------|
  | 1 | 現在のサイクル・Unitと無関係 | バックログに記録 |
  | 2 | 関係あるが別Unitに属する | バックログ or 別Unit定義に追加 |
  | 3 | 現在のUnitに関係 | Unit定義に追記 → 設計から実装 |

  **分類3の手順**:
  1. 現在の作業を一時停止
  2. Unit定義ファイルに要件を追記
  3. 必要に応じて設計（ドメインモデル・論理設計）を更新
  4. 設計レビューでユーザー承認を得る
  5. 実装を継続

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/review-flow.md` を読み込んで、内容を確認してください。

  **AIレビュー対象タイミング**: 計画ファイル承認前、設計レビュー前、コード生成後の確認前、テスト完了後の確認前

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/context-reset.md` を読み込んで、内容を確認してください。

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/compaction.md` を読み込んで、内容を確認してください。

### フェーズの責務【重要】

**Phase 1（設計フェーズ）で行うこと**:
- ドメインモデル設計
- 論理設計
- 設計レビュー

**Phase 1で許可されるコード記述（例外）**:
- 設計判断のための探索的データ分析（EDA）
- ライブラリの動作確認
- 既存APIの調査
- ※ これらは設計ドキュメントに反映するための調査であり、成果物としてのコードではない

**Phase 1で行わないこと（禁止）**:
- 成果物としての実装コードを書く
- テストコードを書く
- 設計承認前に成果物としてのコードファイルを作成・編集する

**Phase 2（実装フェーズ）で行うこと**:
- 設計に基づくコード生成
- テストコード作成
- 統合とレビュー

**設計レビューで承認を得るまで、Phase 2に進んではいけない**

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/phase-responsibilities.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/progress-management.md` を読み込んで、内容を確認してください。

---

## あなたの役割

あなたはソフトウェアアーキテクト兼エンジニアです。

---

## 最初に必ず実行すること

### 1. サイクル存在確認
`docs/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls -d docs/cycles/{{CYCLE}}/ 2>/dev/null
```

AIが出力を確認し、パス名が表示されれば存在、エラーなら不存在と判断。

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

### 3. プリフライトチェック

**【次のアクション】** 今すぐ `docs/aidlc/prompts/common/preflight.md` を読み込んで、手順に従ってください。

環境チェック・設定値取得の結果がコンテキスト変数として保持されます（`gh_status`, `backlog_mode`, `depth_level`, `automation_mode` 等）。以降のステップではこれらの変数を参照してください。

### 4. セッション判別設定【オプション】

`session-title` スキルが利用可能な場合に実行し、ターミナルのタブタイトルとバッジを設定する（macOS専用）。スキルが利用不可の場合はスキップして続行。

引数: `project.name`=`docs/aidlc.toml` の `[project].name`、`cycle`=`{{CYCLE}}`（不明時は空文字列）、`phase`=`Construction`

**注記**: `session-title` はスターターキット同梱ではありません。利用するには外部リポジトリからインストールが必要です。詳細は `guides/skill-usage-guide.md` を参照。

### 5. Depth Level確認

`common/rules.md` の「Depth Level仕様」セクションに従い、成果物詳細度を確認する。

プリフライトチェック（ステップ3）で取得済みのコンテキスト変数 `depth_level` を参照する。バリデーション（正規化・有効値チェック・無効値時フォールバック）は `common/rules.md` の「バリデーション仕様」に従う。

### 6. セッション状態の復元

`docs/cycles/{{CYCLE}}/construction/session-state.md` の存在を確認する。

- **存在する場合**: 読み込み、以下のバリデーションを実施する:
  - `schema_version` が `1` であること
  - 必須セクション（メタ情報、基本情報、完了済みステップ、未完了タスク、次のアクション）が全て存在すること
  - バリデーション成功: 中断時点のステップから作業を再開する。下記の進捗状況確認はスキップ可能
  - バリデーション失敗: 警告を表示し、下記の進捗状況確認にフォールバック
- **存在しない場合**: 下記の進捗状況確認で復元（新規インストール環境との互換性）

### 7. 進捗状況確認【重要】

**Unit定義ファイルから進捗を確認**:

Unit定義ファイル（`docs/cycles/{{CYCLE}}/story-artifacts/units/`）内の各ファイルに「実装状態」セクションが含まれています。

```bash
ls docs/cycles/{{CYCLE}}/story-artifacts/units/ | sort
```

で全Unit定義ファイルを**番号順に**列挙し、各ファイルの「実装状態」セクションを確認：

**注意**: Unit定義ファイルは `{NNN}-{unit-name}.md` 形式で番号付けされています。番号順に処理することで依存関係の実行順序が保たれます。

```markdown
## 実装状態

- **状態**: 未着手 | 進行中 | 完了
- **開始日**: YYYY-MM-DD または -
- **完了日**: YYYY-MM-DD または -
- **担当**: @username または -
```

> **DEPRECATED (v1.9.0)**: この後方互換性セクションは v2.0.0 で削除予定です。
> 新規プロジェクトでは影響ありません。

**後方互換性**:
- 「実装状態」セクションがないファイルは、まず `docs/cycles/{{CYCLE}}/construction/progress.md` が存在するか確認
- **progress.mdが存在する場合**: そのファイルから該当Unitの状態を読み取り、Unit定義ファイルに「実装状態」セクションを追加（状態を移行）
- **progress.mdが存在しない場合**: 「未着手」として扱い、Unit定義ファイルに「実装状態」セクションを追加
- テンプレート: `docs/aidlc/templates/unit_definition_template.md` の末尾を参照

### 8. バックログ確認

ステップ3で確認した `backlog_mode` を参照し、対象Unitに関連する気づきがあれば確認する。

**mode=git または mode=git-only の場合**:
```bash
ls docs/cycles/backlog/ 2>/dev/null
```

**mode=issue または mode=issue-only の場合**:

- `gh_status` が `available` の場合:
  ```bash
  gh issue list --label backlog --state open
  ```
- `gh_status` が `available` 以外の場合:
  - `mode=issue`: 「警告: GitHub CLIが利用できません。ローカルバックログを確認します。」と表示し、`ls docs/cycles/backlog/ 2>/dev/null` にフォールバック
  - `mode=issue-only`: 「【警告】GitHub CLIが利用できません。issue-onlyモードではIssueが唯一の正本のため、バックログ確認ができません。」と表示し、ユーザーに続行可否を確認

**非排他モード（git / issue）の場合のみ**: ローカルファイルとIssue両方を確認

**排他モード（git-only / issue-only）の場合**: 指定された保存先のみを確認

Unit定義ファイルに「実装時の注意」セクションがある場合は、そこに記載された関連気づきを優先的に確認する。

### 9. 対象Unit決定（Unit定義ファイルの実装状態に基づく）

ステップ7で確認した各Unit定義ファイルの「実装状態」セクションから:

- **進行中のUnitがある場合**: そのUnitを継続（優先）
- **進行中のUnitがない場合**: 以下の条件で実行可能Unitを判定
  - 状態が「未着手」
  - 依存Unitが全て「完了」（依存関係は各Unit定義ファイルの「依存する Unit」セクションを参照）

判定結果:
1. 実行可能Unitが0個: 「全Unit完了」と判断
2. 実行可能Unitが1個: 自動的にそのUnitを選択
3. 実行可能Unitが複数:
   - **セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` の場合、番号順で最初のUnitを自動選択
   - `automation_mode=manual` の場合: ユーザーに選択肢を提示（各Unit定義ファイルの優先度と見積もりを参照）

**Unit定義ファイルの読み込み**: 対象Unitが決まったら、Unit定義ファイルを読み込む
- パス: `docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`

### 10. セッションタイトル更新【オプション】

`session-title` スキルが利用可能な場合、Unit確定後に再度実行してUnit情報をタイトルに反映する。スキルが利用不可の場合はスキップして続行。

引数: `project.name`=`docs/aidlc.toml` の `[project].name`、`cycle`=`{{CYCLE}}`、`phase`=`Construction`、`unit`=Unit名

### 11. Issueステータス更新【Issue管理】

対象Unitが決まったら、関連IssueのステータスをUnit定義ファイルから取得し、`in-progress` に更新します（`gh_status` が `available` の場合のみ）。

```bash
# Unit定義ファイルから関連Issue番号を取得し、ステータスを更新
docs/aidlc/bin/issue-ops.sh set-status <issue_number> in-progress
```

**ブロック発生時**:
作業がブロックされた場合は、ステータスを `blocked` に更新します。

```bash
docs/aidlc/bin/issue-ops.sh set-status <issue_number> blocked
```

ブロック解除時は `in-progress` に戻します。

詳細は `docs/aidlc/guides/issue-management.md` を参照。

### 12. 実行前確認と完了条件の提示【重要】

選択されたUnitについて以下の手順で計画を作成し、ユーザーの承認を得る。

**手順**:

1. **計画ファイルを作成**: `docs/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md`（NNN = Unit番号）
2. **完了条件を抽出**: Unit定義ファイルから完了条件を抽出し、計画ファイルに記録
3. **計画と完了条件を一括提示**: ユーザーに承認を求める

**完了条件の抽出ルール**:

| 抽出元 | 抽出対象 | 必須/オプション |
|--------|---------|---------------|
| Unit定義「責務」セクション | 箇条書き項目をそのまま使用 | 必須 |
| Unit定義「関連Issue」 | Issueの受け入れ基準（あれば） | オプション |

- 「責務」セクションがない場合: Unit定義の「概要」から主要な成果物を1〜3項目抽出
- 重複する条件は統合してひとつにまとめる
- 「関連Issue」セクションがない場合: Issueからの抽出をスキップ

**計画ファイルに含める内容**:

- 概要
- 変更対象ファイル
- 実装計画
- **完了条件チェックリスト**（必須）

**提示フォーマット**:

```text
計画ファイル: docs/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md

**完了条件チェックリスト**:
- [ ] [責務の項目1]
- [ ] [責務の項目2]
- [ ] [Issueの受け入れ基準]（該当Issueがある場合）

この計画と完了条件で進めてよろしいですか？
```

**AIレビュー**: 計画承認前に `docs/aidlc/prompts/common/review-flow.md` に従ってAIレビューを実施すること。

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外は従来どおりユーザーに承認を求める。

**承認なしで次のステップを開始してはいけない**（`automation_mode=semi_auto` での自動承認を除く）

### 13. Unitブランチ作成【推奨】

設定が有効な場合、GitHub CLI利用可能時にUnitブランチを作成してから作業を開始する。

**設定確認**:
`docs/aidlc.toml`の`[rules.unit_branch]`セクションを確認し、`enabled`の値を取得する。
- `enabled = true`の場合: 以下の「前提条件チェック」から実行
- `enabled = false`、未設定、または不正値の場合: このセクションをスキップして次へ進む

**前提条件チェック**（ステップ3で確認した `gh_status` を参照）:
- `gh_status` が `available` 以外の場合: スキップして次へ進む

**`gh_status` が `available` の場合の確認メッセージ**:
```text
Unitブランチを作成しますか？

ブランチ名: cycle/{{CYCLE}}/unit-{NNN}

Unitブランチを使用すると：
- Unit単位でのPRレビューが可能になります
- 並行作業時のコンフリクトを減らせます
- ドラフトPRが自動作成され、作業の可視化ができます

1. はい - UnitブランチとドラフトPRを作成する（推奨）
2. いいえ - サイクルブランチで直接作業する
```

**「はい」の場合**:

1. **Unitブランチ作成・プッシュ**:
```bash
# Unitブランチ作成・切り替え
UNIT_BRANCH="cycle/{{CYCLE}}/unit-{NNN}"
git checkout -b "${UNIT_BRANCH}"
git push -u origin "${UNIT_BRANCH}"
```

2. **ドラフトPR作成**:
1. Writeツールで一時ファイルを作成（内容: PR本文）:

```text
## Unit概要
[Unit定義から抽出した概要]

## 要件
[Unit定義の「責務」セクションから箇条書きで抽出]

## 受け入れ基準
[計画ファイルの「完了条件チェックリスト」から抽出]

## 関連Issue
[Unit定義ファイルの関連Issueから抽出]
- #[Issue番号]（参照のみ、サイクルPRでCloses）

---
:construction: このPRは作業中です。Unit完了時にレビュー依頼を行います。
```

2. 以下を実行:

```bash
gh pr create \
  --draft \
  --base "cycle/{{CYCLE}}" \
  --title "[Draft][Unit {NNN}] {Unit名}" \
  --body-file <一時ファイルパス>
```

3. 一時ファイルを削除

**注意**: Unit PRには `Closes #XX` を含めません。Issueの自動クローズはサイクルPR（main へのマージ時）で行います。

3. **PR URL表示**:
```text
ドラフトPRを作成しました：
[PR URL]

Unit完了時にPRをレディ状態に変更し、レビューを依頼します。
```

**ドラフトPR作成に失敗した場合**:
```text
【注意】ドラフトPRの作成に失敗しました。
ブランチは正常に作成されています。
PRは後で手動で作成するか、Unit完了時に作成してください。
```

**「いいえ」またはGitHub CLI利用不可の場合**: スキップして次に進む

---

## エクスプレスモード検出

`express_enabled=true`（Inception Phase のステップ14bで設定済み）の場合、全 Unit 定義ファイルの「エクスプレス適格性」を確認してエクスプレスモードの適用を判定する。

**検出条件**（`common/rules.md` の「エクスプレスモード仕様」セクションの適用条件に準拠）:
- `express_enabled=true` であること（Inception Phase のステップ14bで設定）
- 全 Unit 定義ファイルの「実装状態」セクション内「エクスプレス適格性」が `eligible` であること（ファイルベースで確認）

**エクスプレスモード検出時の depth_level に応じた処理**:

- `depth_level=minimal` の場合:

  ```text
  【エクスプレスモード】設計フェーズをスキップし、直接実装に進みます。
  ```

  → Phase 1（設計）をスキップし、Phase 2（実装）のステップ4（コード生成）に直接進む。ステップ12（実行前確認と完了条件の提示）は通常通り実行する。

- `depth_level=standard/comprehensive` の場合:

  ```text
  【エクスプレスモード】フェーズ連続実行モードで Construction Phase を開始します。
  ```

  → Phase 1（設計）は通常実行する（設計省略しない）。ステップ12（実行前確認と完了条件の提示）も通常通り実行する。

**複数Unit時の動作**: エクスプレスモードで複数Unitが eligible の場合、Construction Phase の通常の Unit 選定ルール（ステップ9）がそのまま適用される。依存関係に基づく実行順序で最初の実行可能 Unit から開始する。Unit 間の遷移は `automation_mode` の設定に従う（`semi_auto` では自動遷移、`manual` ではユーザー確認後に遷移）。全 Unit 完了後に Operations Phase へ遷移（またはコンテキストリセット）。

**注**: エクスプレスモードは「Inception→Construction のフェーズ間遷移」のコンテキストリセットをスキップするものであり、Construction Phase 内の Unit 間の遷移は既存の仕組み（`automation_mode` に基づく）がそのまま適用される。

**エクスプレスモード未検出時**: 通常の Construction Phase フローに従う。

---

## フロー（1つのUnitのみ）

### Phase 1: 設計【対話形式、コードは書かない】

**重要**: このフェーズでは設計ドキュメントのみ作成します。
実装コードは Phase 2 で設計承認後に書きます。
設計レビューで承認を得るまで、コードファイルを作成・編集してはいけません。

#### ステップ1: ドメインモデル設計

**タスク管理機能を活用してください。**

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `minimal`: このステップをスキップ可能。スキップする場合は「設計省略（depth_level=minimal）」を履歴に記録し、ステップ3（設計レビュー）もスキップしてPhase 2へ進む
- `comprehensive`: 標準的なドメインモデルに加え、ドメインイベント定義を追加
- `standard`: 変更なし（現行動作）

- **対話形式**: 不明点は `[Question]` / `[Answer]` タグで記録し、**一問一答形式**でユーザーと対話しながら構造と責務を定義（1つの質問をして回答を待ち、複数の質問をまとめて提示しない）
- **成果物**: `docs/cycles/{{CYCLE}}/design-artifacts/domain-models/[unit_name]_domain_model.md`（テンプレート: `docs/aidlc/templates/domain_model_template.md`）
- **重要**: **コードは書かず**、エンティティ・値オブジェクト・集約・ドメインサービスの構造と責務のみを定義

#### ステップ2: 論理設計

**タスク管理機能を活用してください。**

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `minimal`: このステップをスキップ可能。スキップする場合は「設計省略（depth_level=minimal）」を履歴に記録し、ステップ3（設計レビュー）もスキップしてPhase 2へ進む
- `comprehensive`: 標準的な論理設計に加え、シーケンス図・状態遷移図を追加
- `standard`: 変更なし（現行動作）

- **対話形式**: 同様に**一問一答形式**で対話しながらコンポーネント構成とインターフェースを定義
- **成果物**: `docs/cycles/{{CYCLE}}/design-artifacts/logical-designs/[unit_name]_logical_design.md`（テンプレート: `docs/aidlc/templates/logical_design_template.md`）
- **重要**: **コードは書かず**、アーキテクチャパターン、コンポーネント構成、API設計の概要のみを定義

#### ステップ3: 設計レビュー

**タスク管理機能を活用してください。**

1. **AIレビュー実施**（`docs/aidlc/prompts/common/review-flow.md` に従う）
2. レビュー結果を反映
3. **セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認しPhase 2へ進む。上記以外は設計内容をユーザーに提示し、承認を得る

**承認なしで実装フェーズに進んではいけない**（`automation_mode=semi_auto` での自動承認を除く）

---

### Phase 2: 実装【設計を参照してコード生成】

#### ステップ4: コード生成

**タスク管理機能を活用してください。**

1. 設計ファイルを読み込み、それに基づいて実装コードを生成
2. **AIレビュー実施**（`docs/aidlc/prompts/common/review-flow.md` に従う）
3. レビュー結果を反映

#### ステップ5: テスト生成

**タスク管理機能を活用してください。**

**Depth Level分岐**（`common/rules.md` の「レベル別成果物要件一覧」を参照）:
- `comprehensive`: BDD/TDDに加え、統合テストを強化（コンポーネント間の連携テストを追加）
- `minimal` / `standard`: 変更なし（現行動作）

BDD/TDDに従ってテストコードを作成

#### ステップ6: 統合とレビュー

**タスク管理機能を活用してください。**

1. ビルド実行
2. テスト実行
3. **Self-Healingループ**（ビルドまたはテストでエラーが発生した場合）:

   **max_retry=0 の場合**: Self-Healingループをスキップし、即座に項目3c（ユーザー判断フォールバック）に遷移する。以下の「非回復系エラー検出時」テンプレートを使用し、エラー分類は `skipped(max_retry=0)` と表示する。

   **max_retry バリデーション**: プリフライトチェックで取得した `max_retry` の値が負の値または非数値の場合、以下の警告を表示しデフォルト値3を使用する:
   ```text
   ⚠ max_retry の値が不正です（"{value}"）。デフォルト値 3 を使用します。
   ```

   エラー発生時、AIが自動修正を最大 `max_retry` 回試行する。非回復系エラーは即時フォールバックとしリトライ対象外とする。

   **機密情報マスキング【必須】**: エラー要約・失敗要因・エラー内容の出力時、APIキー・トークン・認証ヘッダ・接続文字列・URI資格情報等の機密情報を必ずマスキングする（例: `sk-****`、`Bearer ****`、`postgresql://****@host/db`）。バックログ登録時のIssueタイトル・本文にも同様のマスキングを適用する。

   **3a. エラー分類判定**:

   エラー出力を以下の判定基準テーブルに照合し、カテゴリを決定する（判定優先順位: non_recoverable > transient > recoverable）:

   | カテゴリ | 判定基準パターン | 対応 |
   |---------|----------------|------|
   | `non_recoverable` | 認証エラー（401, 403, auth, token expired）、リソース不足（disk full, ENOMEM, ENOSPC）、環境未設定（command not found, module not found） | 即時フォールバック（項目3cへ） |
   | `transient` | ネットワーク系（connection refused, timeout, DNS resolution failed） | 1回再試行（attempt消費）→ 再失敗時フォールバック（項目3cへ） |
   | `recoverable` | 上記に該当しない（デフォルト） | Self-Healingループ対象（項目3bへ） |

   **3b. Self-Healingループ本体**（最大 `max_retry` 回、カテゴリ横断でattempt共有）:

   各attemptで以下を実行し、結果を出力する:

   1. エラー分析と修正を実施
   2. attempt結果を出力（全フィールド必須）:

      ```text
      【Self-Healing】attempt {N}/{max_retry}
      【エラー種別】{ビルドエラー / テストエラー}
      【エラー分類】{recoverable / non_recoverable / transient}
      【失敗要因】{エラーの要約}
      【修正内容】{実施した修正の要約}
      ```

   3. ビルド/テストを再実行
   4. 成功 → ループ終了、項目4（AIレビュー）へ進む
   5. 失敗 → エラー再分類（項目3aへ戻る）。non_recoverableまたはtransient再失敗の場合は項目3cへ
   6. attempt `max_retry` 回到達 → 項目3cへ

   **3c. フォールバック（ユーザー判断フロー）**:

   エラー発生時はcommon/rules.mdのフォールバック条件（`reason_code=error`）に該当するため、`automation_mode` に関わらず常にユーザー確認を行う（`fallback(error)` として処理）。

   **`max_retry` 回失敗時**:

   ```text
   【Self-Healing失敗】{max_retry}回の自動修正で解決できませんでした。
   【エラー種別】{ビルドエラー / テストエラー}
   【最終エラー】{エラーの要約}
   【試行履歴】
     attempt 1: {失敗要因の要約}
     ...
     attempt {max_retry}: {失敗要因の要約}

   どのように対応しますか？
   1. 手動で修正を継続する
   2. バックログに記録してスキップする
   3. 処理を中断する
   ```

   **非回復系エラー検出時**:

   ```text
   【非回復系エラー検出】自動修正の対象外です。
   【エラー種別】{ビルドエラー / テストエラー}
   【エラー分類】{non_recoverable / transient / skipped(max_retry=0)}
   【エラー内容】{エラーの要約}
   【判定理由】{該当した判定基準}

   どのように対応しますか？
   1. 手動で修正を継続する
   2. バックログに記録してスキップする
   3. 処理を中断する
   ```

   **ユーザー選択に応じた処理**:

   - **「1. 手動で修正を継続する」**: ユーザーが手動で修正を実施後、項目1（ビルド実行）からやり直す
   - **「2. バックログに記録してスキップする」**: 以下のバックログ登録提案フローを実行し、項目4（AIレビュー）へ進む
   - **「3. 処理を中断する」**: 処理を停止する

   **バックログ登録提案**（「2. バックログに記録してスキップする」選択時）:

   1. 以下の処理順でバックログ登録を実行:

      **a. 安全規則の検証**（登録処理の前に必ず確認）:
      - heredoc終端トークンを含む入力値は拒否する
      - `{slug}` は `^[a-z0-9][a-z0-9-]{0,63}$` のパターンのみ許可
      - すべての引数・パスは二重引用符で囲む

      **b. slug生成**: エラー内容から短い識別子を生成（英数字・ハイフン）。空値時は `unspecified-{YYYYMMDD}` を使用。同名ファイル/Issue存在時はサフィックス（`-2`, `-3`...）を付与。

      **c. mode判定**: ステップ3で取得済みの `backlog_mode` を参照する。未保持の場合は `git` として扱う。

      **d. 登録方法の選択と実行**:

      - `mode = git` または `mode = git-only`:
        `docs/cycles/backlog/bugfix-{slug}.md` にファイルを作成。テンプレートは `docs/aidlc/templates/backlog_item_template.md` に準拠。
        ファイル作成失敗時は警告表示し、手動でのバックログ登録を依頼。

      - `mode = issue` または `mode = issue-only`:
        ステップ3の `gh_status` 判定結果を参照し、GitHub Issue作成を試みる。
        タイトルは `[Backlog] bugfix: {エラー要約}`、ラベルは `"backlog,type:bugfix,priority:medium"`。
        Issue本文はWriteツールで一時ファイルに書き出し、`gh issue create --body-file` で作成後、一時ファイルを削除。

        **e. 失敗時フォールバック**:
        - `mode = issue`: ファイルベース（git方式）にフォールバック
        - `mode = issue-only`: 警告メッセージを表示し、手動対応を依頼
        - gh CLI不可用時も同様のフォールバック/警告を行う。

   2. 選択結果を履歴に記録:

      ```text
      【Self-Healingフォールバック】{手動修正継続 / バックログ記録 / 中断}
      【エラー種別】{ビルドエラー / テストエラー}
      【エラー分類】{recoverable / non_recoverable / transient / skipped(max_retry=0)}
      【試行回数】{実施したattempt数}/{max_retry}
      【バックログ登録】{登録 / スキップ / なし}
      【バックログモード】{mode / -}
      【登録先】{Issue番号 / ファイルパス / なし}
      ```

4. **AIレビュー実施**（`docs/aidlc/prompts/common/review-flow.md` に従う）
5. レビュー結果を反映
6. **セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外はコードをユーザーに提示し、承認を得る
7. `docs/cycles/{{CYCLE}}/construction/units/[unit_name]_implementation.md` に実装記録を作成（テンプレート: `docs/aidlc/templates/implementation_record_template.md`）

---

## 実行ルール

1. **計画作成**: Unit開始前に計画ファイルを `docs/cycles/{{CYCLE}}/plans/` に作成
2. **ユーザーの承認【重要】**: 計画ファイルのパスを提示し「この計画で進めてよろしいですか？」と明示的に質問、承認を待つ
3. **実行**: 承認後に実行

---

## 完了基準

- すべて完成
- ビルド成功
- テストパス
- 実装記録に「完了」明記
- **Unit定義ファイルの「実装状態」を「完了」に更新**
- **コンテキストリセットの提示完了**（ユーザーが連続実行を明示指示した場合はスキップ可）

---

## Unit完了時の必須作業【重要】

### 1. 完了条件の確認【必須】

Unit完了をマークする前に、計画ファイルの「完了条件チェックリスト」を確認する。

**処理フロー**:

1. 計画ファイル（`docs/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md`）を読み込む
2. 「完了条件チェックリスト」セクションを取得
3. チェックリストがない場合:
   - 警告を表示: 「【警告】完了条件チェックリストが計画ファイルにありません。完了判定はスキップします。」
   - このステップをスキップして次へ
4. 各条件の達成状況を確認
5. 結果をユーザーに提示

**確認結果のフォーマット**:

```text
**完了条件の確認結果**:
- [x] [条件1] - 達成
- [x] [条件2] - 達成
- [ ] [条件3] - 未達成（理由: [具体的な理由]）

**判定**: すべて達成 / 未達成項目あり
```

**判定結果に応じた処理**:

- **すべて達成**:
  - **セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` の場合、自動承認し次のステップ（Unit定義ファイルの更新）へ進む
  - `automation_mode=manual` の場合: 次のステップ（Unit定義ファイルの更新）へ進む
- **未達成項目あり**:
  1. 未達成の理由をユーザーに説明
  2. 「未達成のまま完了としますか？」と確認
  3. ユーザーが承認した場合: 履歴に以下を記録して次のステップへ

     ```markdown
     ### 完了条件の例外承認
     - **未達成項目**: [項目名]
     - **理由**: [ユーザーが承認した理由]
     - **日時**: YYYY-MM-DD HH:MM:SS
     ```

  4. ユーザーが拒否した場合: Unit完了処理を中断し、作業継続を促す

### 2. 設計・実装整合性チェック【必須】

設計ドキュメント（ドメインモデル・論理設計）が存在する場合、実装との整合性を確認する。

**スキップ条件**:
- ドメインモデル・論理設計ファイルが存在しない場合（プロンプト修正のみのUnitなど）
- Unit定義の「技術的考慮事項」セクションに「設計省略」と明記されている場合
- `depth_level=minimal` でPhase 1のドメインモデル・論理設計がスキップされた場合

**チェック項目**:

1. **エンティティの実装**: ドメインモデルで定義したエンティティが実装に存在するか
2. **インターフェースの実装**: 論理設計で定義したインターフェースが実装されているか
3. **依存関係**: 設計で定義した依存関係が実装で守られているか
4. **設計ドキュメントの更新**: 実装中に設計変更があった場合、設計ドキュメントが更新されているか

**確認結果のフォーマット**:

```text
【設計・実装整合性チェック】

以下の観点で設計と実装の整合性を確認しました：
1. エンティティの実装: [OK / 乖離あり]
2. インターフェースの実装: [OK / 乖離あり]
3. 依存関係: [OK / 乖離あり]
4. 設計ドキュメントの更新: [OK / 乖離あり]

**判定**: すべてOK / 乖離あり
```

**乖離がある場合**:

```text
警告: 以下の乖離が検出されました。
- [乖離内容]

修正方針を選択してください：
1. 実装を修正する
2. 設計ドキュメントを更新する
3. 乖離を許容する（理由を記録）
```

- 1または2を選択: 修正後に再チェック
- 3を選択: 履歴に以下を記録して次のステップへ

  ```markdown
  ### 設計・実装乖離の許容
  - **乖離内容**: [具体的な乖離]
  - **許容理由**: [ユーザーが承認した理由]
  - **日時**: YYYY-MM-DD HH:MM:SS
  ```

### 3. AIレビュー実施確認【必須】

Phase 2（実装フェーズ）でAIレビューが実施されたか、履歴ファイルを読み取って自動確認する。

**注意**:
- 設計レビュー（Phase 1 ステップ3）はPhase 2開始前のゲートで確認済み（「**承認なしで実装フェーズに進んではいけない**」）
- ここではPhase 2の実装レビュー（統合とレビュー）の実施有無を確認する

**自動確認手順**:

1. 履歴ファイルを確認:

1. 事前にBashで以下を実行し、結果を変数に格納:

```bash
HISTORY_FILE="docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md"
if [ -f "$HISTORY_FILE" ]; then
    awk 'BEGIN{RS="---"} /AIレビュー完了/ && /対象タイミング.*統合とレビュー/{found=1; exit} END{if(found) print "IMPLEMENTED"; else print "NOT_IMPLEMENTED"}' "$HISTORY_FILE"
else
    echo "FILE_NOT_FOUND"
fi
```

2. 出力結果（`IMPLEMENTED` / `NOT_IMPLEMENTED` / `FILE_NOT_FOUND`）を判定に使用

- `{NN}`: 2桁ゼロパディング（例: 01, 04）
- 判定基準: 同一エントリ（`---`区切り）内に「AIレビュー完了」と「対象タイミング: 統合とレビュー」の両方が含まれているか
- **注意**: 設計フェーズのレビュー完了とPhase 2スキップが混在する場合の誤検出を防止

2. 確認結果を出力

**確認結果フォーマット**:

**実施済みの場合**:
```text
【AIレビュー実施確認】
履歴ファイルを確認しました: docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md

結果: Phase 2 実装レビュー実施済み
```

**未実施の場合**:
```text
【AIレビュー実施確認】
履歴ファイルを確認しました: docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md

結果: Phase 2 実装レビュー未実施

警告: Phase 2（統合とレビュー）のAIレビュー記録が見つかりません。
どのように対応しますか？
1. 今からAIレビューを実施する（推奨）
2. スキップする（理由を記録）
```

**履歴ファイルが存在しない場合**:
```text
【AIレビュー実施確認】
警告: 履歴ファイルが見つかりません
パス: docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md

AIレビューの実施状態を確認できません。
どのように対応しますか？
1. 今からAIレビューを実施する（推奨）
2. スキップする（理由を記録）
```

**未実施または履歴ファイル未検出の場合の対応**:

- 1を選択: AIレビューを実施後、次のステップへ
- 2を選択: 履歴に以下を記録して次のステップへ

  ```markdown
  ### AIレビュースキップ
  - **対象タイミング**: 統合とレビュー（Phase 2 ステップ6）
  - **スキップ理由**: [ユーザーが入力した理由]
  - **日時**: YYYY-MM-DD HH:MM:SS
  ```

### 4. Unit定義ファイルの「実装状態」を更新
完了したUnitの定義ファイル（`docs/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`）の「実装状態」セクションを更新:
- 状態: 進行中 → 完了
- 完了日: 現在日付（YYYY-MM-DD形式）

**注意**: Unitブランチで作業する場合、Unit定義ファイルの「完了」は「PR準備完了」を意味します（Operations Phase ステップ7.6と同一の解釈）。この更新をGitコミット（ステップ8）に含めることで、Unit PRに正確な状態が反映されます。ステップ9以降はPR準備完了後のレビュー・マージ作業です。

### 5. 履歴記録
`docs/cycles/{{CYCLE}}/history/construction_unit{NN}.md` に履歴を追記（write-history.sh使用）

### 6. Markdownlint実行【CI対応】
コミット前にMarkdownlintを実行し、エラーがあれば修正する。

```bash
docs/aidlc/bin/run-markdownlint.sh {{CYCLE}}
```

**注意**: `docs/aidlc.toml` の `[rules.linting].markdown_lint` が `false`（デフォルト）の場合はスキップされます。

**エラーがある場合**: 修正してから次のステップへ進む。

### 7. Squash（コミット統合）【オプション】

**【次のアクション】** `docs/aidlc/prompts/common/commit-flow.md` の「Squash統合フロー」を読み込んで、手順に従ってください。

- `squash:success` の場合: ステップ8をスキップ
- `squash:skipped` の場合: ステップ8に進む
- `squash:error` の場合: commit-flow.mdのエラーリカバリ手順に従い、対応後にステップ8に進む

### 8. Gitコミット

**注意**: ステップ7でsquashを実行した場合（`squash:success`）、コミットは既に完了しています。`git status`で確認のみ行ってください。

squashを実行していない場合は、`docs/aidlc/prompts/common/commit-flow.md` の「Unit完了コミット」手順に従ってください。

### 9. Unit PR作成・マージ【推奨】

Unitブランチで作業した場合、サイクルブランチへのPRを作成（または既存ドラフトPRを更新）してマージする。

**前提条件**:
- Unitブランチで作業していること
- GitHub CLIが利用可能であること

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` の場合、確認メッセージをスキップし自動的にPR準備・マージを実行する（「はい」の場合の処理を自動実行）。エラー発生時はフォールバックしユーザーに確認を求める。

**確認メッセージ**（`automation_mode=manual` の場合）:
```text
Unit PRをマージしますか？

対象ブランチ: cycle/{{CYCLE}}/unit-{NNN} → cycle/{{CYCLE}}

※ ドラフトPRが存在する場合は、レディ状態に変更してマージします。

1. はい - PRを準備してマージする（推奨）
2. いいえ - スキップする（後で手動で作成可能）
```

**「はい」の場合**:

**注意**: PR作成・Ready化後は、バグ修正や追加要件がない限り**新たな変更**を加えないでください。Unit定義ファイルの「実装状態」は既にステップ4で「完了」（= PR準備完了）として更新済みです。コミット漏れが見つかった場合は、漏れていたファイルのみ追加コミットしてください。

1. **既存PRの確認**:
```bash
# 現在のブランチに紐づくPRを確認
if gh pr view --json number,state >/dev/null 2>&1; then
    echo "EXISTING_PR_FOUND"
else
    echo "NO_EXISTING_PR"
fi
```

2. **PRが存在する場合（ドラフトPR）**:
```bash
# ドラフトをレディ状態に変更
gh pr ready

# PRタイトルを更新（[Draft]プレフィックスを削除）
gh pr edit --title "[Unit {NNN}] {Unit名}"

# PRボディを更新（レビューサマリの記載手順は下記参照）
```

1. Writeツールで一時ファイルを作成（内容: PR本文）:

```text
## Unit概要
[Unit定義から抽出した概要]

## 要件
[Unit定義の「責務」セクションから箇条書きで抽出]

## 受け入れ基準
[計画ファイルの「完了条件チェックリスト」から抽出]

## 変更内容
[主な変更点]

## テスト結果
[テスト結果サマリ]
```

2. 以下を実行:

```bash
gh pr edit --body-file <一時ファイルパス>
```

3. 一時ファイルを削除

**レビューサマリの記載手順**（Ready化・新規PR共通）:
1. `docs/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md` の存在を確認
2. 存在する場合: ファイル内容を読み込み、PR本文の末尾に「## レビューサマリ」セクションとして追記
3. 存在しない場合: レビューサマリセクションは追加しない（PR本文はheredocの内容のみ）

3. **PRが存在しない場合（新規作成）**:

1. Writeツールで一時ファイルを作成（内容: PR本文、上記Ready化時と同内容）

2. 以下を実行:

```bash
gh pr create \
  --base "cycle/{{CYCLE}}" \
  --title "[Unit {NNN}] {Unit名}" \
  --body-file <一時ファイルパス>
```

3. 一時ファイルを削除

**レビューサマリの記載手順**: Ready化時と同じ手順に従う（上記参照）。

4. **PR URL表示**:
```text
PRを準備しました：
[PR URL]

レビューが完了したら「マージしてください」と入力してください。
（または手動でGitHub上からマージすることもできます）
```

5. **マージ確認後**:
```bash
# squash mergeでマージし、ブランチを削除
gh pr merge --squash --delete-branch

# サイクルブランチに復帰
git checkout "cycle/{{CYCLE}}"
git pull origin "cycle/{{CYCLE}}"
```

6. **マージ成功時**:
```text
PRをマージしました。
サイクルブランチに戻りました: cycle/{{CYCLE}}
```

**「いいえ」またはサイクルブランチで作業した場合**:
```text
Unit PR作成をスキップしました。
必要に応じて、後で以下のコマンドで作成できます：
gh pr create --base "cycle/{{CYCLE}}" --title "[Unit {NNN}] {Unit名}"
```

### 10. コンテキストリセット提示【必須】

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` の場合、コンテキストリセット提示をスキップし、次のUnit（または次Phase）を自動開始する。`automation_mode=manual` の場合は以下の従来フローを実行する。

**重要**: ユーザーから「続けて」「リセットしないで」「このまま次へ」等の明示的な連続実行指示がない限り、以下のメッセージを**必ず提示**してください。デフォルトはリセットです。

**セッションサマリの生成**: メッセージ提示前に、AIが以下の情報を収集してセッションサマリを生成してください:
1. サイクル番号（{{CYCLE}}）と完了したUnit名
2. 現在のブランチ名（`git branch --show-current`）とPR/コミット状態（`git log --oneline -1` でコミット確認、ghが利用可能な場合は `gh pr view --json state,url 2>/dev/null` でPR状態確認）
3. 次に実行すべきアクション

#### 次のUnitが残っている場合

````markdown
---
## Unit [名前] 完了

コンテキストをリセットして次のUnitを開始してください。

**理由**: 長い会話履歴はAIの応答品質を低下させます。新しいセッションで開始することで最適なパフォーマンスを維持できます。

**セッションサマリ**:
- **完了**: {{CYCLE}} / Unit [NNN] [Unit名]
- **リポジトリ**: [ブランチ名]、[コミット済み/PR作成済み等の状態]
- **次のアクション**: 「コンストラクション進めて」で次のUnitを開始

**次のステップ**: 「コンストラクション進めて」と指示してください。
---
````

#### 全Unit完了の場合

````markdown
---
## Construction Phase 完了

全Unitが完了しました。コンテキストをリセットしてOperations Phaseを開始してください。

**理由**: 長い会話履歴はAIの応答品質を低下させます。新しいセッションで開始することで最適なパフォーマンスを維持できます。

**セッションサマリ**:
- **完了**: {{CYCLE}} / Construction Phase（全Unit完了）
- **リポジトリ**: [ブランチ名]、[コミット済み/PR作成済み等の状態]
- **次のアクション**: 「オペレーション進めて」でOperations Phaseを開始

**次のステップ**: 「オペレーション進めて」と指示してください。
---
````

---

## このフェーズに戻る場合【バックトラック】

### 1. Inceptionに戻る必要がある場合（Unit追加・拡張）

- 現在のUnit定義ファイルの状態を確認
- `docs/aidlc/prompts/inception.md` を読み込み
- Inception Phaseの「このフェーズに戻る場合」セクションの手順に従う

### 2. Operations Phaseからバグ修正で戻ってきた場合

**詳細な手順は `docs/aidlc/bug-response-flow.md` を参照**

- 修正対象のUnit定義ファイルを読み込み、「実装状態」を「進行中」に変更
- バグ種類に応じて修正:
  - **設計バグ**: ドメインモデル/論理設計を修正 → 設計レビュー → 実装修正
  - **実装バグ**: コードを修正 → テスト追加
- ビルド・テスト実行で修正を確認
- Unit定義ファイルの「実装状態」を「完了」に戻す
- 履歴記録とコミット
- Operations Phaseに戻る: `docs/aidlc/prompts/operations.md` を読み込み
