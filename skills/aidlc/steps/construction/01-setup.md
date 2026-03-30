# Construction Phase プロンプト

**【次のアクション】** 今すぐ `steps/common/intro.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/common/rules.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/common/project-info.md` を読み込んで、内容を確認してください。

---

## プロジェクト情報

### 技術スタック
Inception Phaseで決定済み、または既存スタックを使用

### ディレクトリ構成（フェーズ固有の追加）
- プロジェクトルートディレクトリ: 実装コード

### 開発ルール

**共通ルールは `steps/common/rules.md` を参照**

- **プロンプト履歴管理【重要】**: 履歴は `.aidlc/cycles/{{CYCLE}}/history/` ディレクトリにUnit単位でファイル分割して管理。

  **設定確認**: `.aidlc/config.toml` の `[rules.history]` セクションを確認
  - `level = "detailed"`: ステップ完了時に記録 + 修正差分も記録
  - `level = "standard"`: ステップ完了時に記録（デフォルト）
  - `level = "minimal"`: Unit完了時にまとめて記録

  **ファイル命名規則**:
  - `construction_unit{NN}.md` （NN = 2桁ゼロパディングのUnit番号、例: `construction_unit01.md`）

  **日時取得**:
  - 日時は `write-history.sh` が内部で自動取得します

  **履歴記録フォーマット**（detailed/standard共通）:
  ```bash
  scripts/write-history.sh \
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
  2. **スコープチェック【必須】**: バックログに登録する前に、`.aidlc/cycles/{{CYCLE}}/requirements/intent.md` の「含まれるもの」セクションを確認する
     - 登録しようとしている項目が「含まれるもの」に列挙済みのIssue番号・作業項目に該当する場合: **バックログに登録せず、現サイクルの計画内で処理する**（スコープ内の作業をバックログに外出ししない）
     - 該当しない場合: 手順3へ進みバックログに登録する
  3. **バックログ項目を作成**: GitHub Issueを作成（ガイド参照: `guides/backlog-management.md`）

  4. **後続での確認**: 次のUnit開始時または次サイクルのInception Phaseでバックログを確認し、対応を検討

  **サブエージェント活用（オプション）**: バックログ追加処理は、サブエージェントに委任することで効率化できます。詳細は `guides/subagent-usage.md` を参照。

- **Workaround（その場しのぎ対応）実施時のルール【重要】**: 本質的な解決ではなく、暫定的な対応（workaround）を行う場合、以下を必ず実施する

  **必須手順**:
  1. **workaroundの実装**: 暫定的な対応を実装
  2. **バックログへの記録**: 本質的な対応をバックログに記録（ガイド参照: `guides/backlog-management.md`）
     - prefix: `chore-` または `refactor-`
     - 内容: 本質的な解決策と、なぜworkaroundを選択したかの理由
  3. **コード内TODOコメント**: workaroundを実装したコード箇所に以下形式でコメント
     ```text
     // TODO: workaround - see backlog (GitHub Issue を参照)
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

**【次のアクション】** 今すぐ `steps/common/task-management.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/common/review-flow.md` を読み込んで、内容を確認してください。

  **AIレビュー対象タイミング**: 計画ファイル承認前、設計レビュー前、コード生成後の確認前、テスト完了後の確認前

**【次のアクション】** 今すぐ `steps/common/context-reset.md` を読み込んで、内容を確認してください。

**【次のアクション】** 今すぐ `steps/common/compaction.md` を読み込んで、内容を確認してください。

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

**【次のアクション】** 今すぐ `steps/common/phase-responsibilities.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/common/progress-management.md` を読み込んで、内容を確認してください。

---

## あなたの役割

あなたはソフトウェアアーキテクト兼エンジニアです。

---

## 最初に必ず実行すること

### 1. サイクル存在確認
`.aidlc/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls -d .aidlc/cycles/{{CYCLE}}/ 2>/dev/null
```

AIが出力を確認し、パス名が表示されれば存在、エラーなら不存在と判断。

- **存在しない場合**: エラーを表示し、inception.md を案内
  ```text
  エラー: サイクル {{CYCLE}} が見つかりません。

  既存のサイクル:
  [ls .aidlc/cycles/ の結果]

  サイクルを作成するには、以下のプロンプトを読み込んでください：
  Inception Phase（`/aidlc inception` を実行）
  ```
- **存在する場合**: 処理を継続

### 2. 追加ルール確認
`.aidlc/rules.md` が存在すれば読み込む

### 3. プリフライトチェック

**【次のアクション】** 今すぐ `steps/common/preflight.md` を読み込んで、手順に従ってください。

環境チェック・設定値取得の結果がコンテキスト変数として保持されます（`gh_status`, `depth_level`, `automation_mode` 等）。以降のステップではこれらの変数を参照してください。

### 4. セッション判別設定【オプション】

`session-title` スキルが利用可能な場合に実行し、ターミナルのタブタイトルとバッジを設定する（macOS専用）。スキルが利用不可の場合はスキップして続行。

引数: `project.name`=`.aidlc/config.toml` の `[project].name`、`cycle`=`{{CYCLE}}`（不明時は空文字列）、`phase`=`Construction`

**注記**: `session-title` はスターターキット同梱ではありません。利用するには外部リポジトリからインストールが必要です。詳細は `guides/skill-usage-guide.md` を参照。

### 5. Depth Level確認

`common/rules.md` の「Depth Level仕様」セクションに従い、成果物詳細度を確認する。

プリフライトチェック（ステップ3）で取得済みのコンテキスト変数 `depth_level` を参照する。バリデーション（正規化・有効値チェック・無効値時フォールバック）は `common/rules.md` の「バリデーション仕様」に従う。

### 6. セッション状態の復元

`.aidlc/cycles/{{CYCLE}}/construction/session-state.md` の存在を確認する。

- **存在する場合**: 読み込み、以下のバリデーションを実施する:
  - `schema_version` が `1` であること
  - 必須セクション（メタ情報、基本情報、完了済みステップ、未完了タスク、次のアクション）が全て存在すること
  - バリデーション成功: 中断時点のステップから作業を再開する。下記の進捗状況確認はスキップ可能
  - バリデーション失敗: 警告を表示し、下記の進捗状況確認にフォールバック
- **存在しない場合**: 下記の進捗状況確認で復元（新規インストール環境との互換性）

### 7. 進捗状況確認【重要】

**Unit定義ファイルから進捗を確認**:

Unit定義ファイル（`.aidlc/cycles/{{CYCLE}}/story-artifacts/units/`）内の各ファイルに「実装状態」セクションが含まれています。

```bash
ls .aidlc/cycles/{{CYCLE}}/story-artifacts/units/ | sort
```

で全Unit定義ファイルを**番号順に**列挙し、各ファイルの「実装状態」セクションを確認：

**注意**: Unit定義ファイルは `{NNN}-{unit-name}.md` 形式で番号付けされています。番号順に処理することで依存関係の実行順序が保たれます。

```markdown
## 実装状態

- **状態**: 未着手 | 進行中 | 完了 | 取り下げ
- **開始日**: YYYY-MM-DD または -
- **完了日**: YYYY-MM-DD または -
- **担当**: @username または -
```

### 8. バックログ確認

対象Unitに関連するIssueとバックログを確認する。

**`gh_status` が `available` の場合**:

1. **関連Issueの詳細確認**: Unit定義ファイルの「関連Issue」セクションからIssue番号を抽出し、各Issueの詳細を確認する

   ```bash
   # Unit定義ファイルから関連Issue番号を抽出（例: #424）
   gh issue view <issue_number> --json title,body,comments --jq '.title, .body'
   ```

   - Issue本文に受け入れ基準や詳細な要件が記載されている場合、計画に反映する
   - Issueにコメントがある場合、最新の議論内容を確認する

2. **バックログIssueの確認**: 対象Unitに関連するバックログIssueがないか確認する

   ```bash
   gh issue list --label backlog --state open --json number,title --jq '.[] | "#\(.number) \(.title)"'
   ```

   - Unit定義の責務やスコープに関連するバックログIssueがあれば、計画時に考慮する

**`gh_status` が `available` 以外の場合**: 「警告: GitHub CLIが利用できないため、バックログ確認をスキップします。」と表示する。

**Unit定義ファイルに「実装時の注意」セクションがある場合**: そこに記載された関連気づきを優先的に確認する。

### 9. 対象Unit決定（Unit定義ファイルの実装状態に基づく）

ステップ7で確認した各Unit定義ファイルの「実装状態」セクションから:

- **進行中のUnitがある場合**: そのUnitを継続（優先）
- **進行中のUnitがない場合**: 以下の条件で実行可能Unitを判定
  - 状態が「未着手」
  - 依存Unitが全て「完了」または「取り下げ」（依存関係は各Unit定義ファイルの「依存する Unit」セクションを参照）

判定結果:
1. 実行可能Unitが0個（全Unitが「完了」または「取り下げ」）: 「全Unit完了」と判断
2. 実行可能Unitが1個: 自動的にそのUnitを選択
3. 実行可能Unitが複数:
   - **セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` の場合、番号順で最初のUnitを自動選択
   - `automation_mode=manual` の場合: ユーザーに選択肢を提示（各Unit定義ファイルの優先度と見積もりを参照）

**Unitの取り下げ**: ユーザーが実行可能Unitの中で実装不要と判断したUnitがある場合、選択時に「取り下げ」を指示できる。取り下げ指示があった場合はUnit定義ファイルの実装状態を「取り下げ」に更新し、再度Unit判定を実行する。

**Unit定義ファイルの読み込み**: 対象Unitが決まったら、Unit定義ファイルを読み込む
- パス: `.aidlc/cycles/{{CYCLE}}/story-artifacts/units/[unit_name].md`

### 10. セッションタイトル更新【オプション】

`session-title` スキルが利用可能な場合、Unit確定後に再度実行してUnit情報をタイトルに反映する。スキルが利用不可の場合はスキップして続行。

引数: `project.name`=`.aidlc/config.toml` の `[project].name`、`cycle`=`{{CYCLE}}`、`phase`=`Construction`、`unit`=Unit名

### 11. Issueステータス更新【Issue管理】

対象Unitが決まったら、関連IssueのステータスをUnit定義ファイルから取得し、`in-progress` に更新します（`gh_status` が `available` の場合のみ）。

```bash
# Unit定義ファイルから関連Issue番号を取得し、ステータスを更新
scripts/issue-ops.sh set-status <issue_number> in-progress
```

**出力形式**:

```text
issue:<number>:status-updated:<status>
```

例: `issue:123:status-updated:in-progress`

**ブロック発生時**:
作業がブロックされた場合は、ステータスを `blocked` に更新します。

```bash
scripts/issue-ops.sh set-status <issue_number> blocked
```

ブロック解除時は `in-progress` に戻します。

詳細は `guides/issue-management.md` を参照。

### 12. 実行前確認と完了条件の提示【重要】

選択されたUnitについて以下の手順で計画を作成し、ユーザーの承認を得る。

**手順**:

1. **計画ファイルを作成**: `.aidlc/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md`（NNN = Unit番号）
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
計画ファイル: .aidlc/cycles/{{CYCLE}}/plans/unit-{NNN}-plan.md

**完了条件チェックリスト**:
- [ ] [責務の項目1]
- [ ] [責務の項目2]
- [ ] [Issueの受け入れ基準]（該当Issueがある場合）

この計画と完了条件で進めてよろしいですか？
```

**AIレビュー**: 計画承認前に `steps/common/review-flow.md` に従ってAIレビューを実施すること。

**セミオートゲート判定**（`common/rules.md` のセミオートゲート仕様を参照）: `automation_mode=semi_auto` かつフォールバック条件に該当しない場合、自動承認し次ステップへ進む。上記以外は従来どおりユーザーに承認を求める。

**承認なしで次のステップを開始してはいけない**（`automation_mode=semi_auto` での自動承認を除く）

**【タスク作成】計画承認後、`steps/common/task-management.md` の「Construction Phase: Unit開始時タスクテンプレート」に従い、Unitのタスクリストを作成してください。** 各ステップの着手・完了時にタスクステータスを更新すること。

### 13. Unitブランチ作成【推奨】

設定が有効な場合、GitHub CLI利用可能時にUnitブランチを作成してから作業を開始する。

**設定確認**:
`.aidlc/config.toml`の`[rules.unit_branch]`セクションを確認し、`enabled`の値を取得する。
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
