# Operations Phase プロンプト

**【次のアクション】** 今すぐ `steps/common/intro.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/common/rules.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/common/project-info.md` を読み込んで、内容を確認してください。

**アップグレード**: `/aidlc-setup` スキルを使用してください。

---

## プロジェクト情報

### 技術スタック
Inception/Construction Phaseで決定済み

### ディレクトリ構成（フェーズ固有の追加）
- プロジェクトルートディレクトリ: 実装コード

### 開発ルール

**共通ルールは `steps/common/rules.md` を参照**

- **プロンプト履歴管理【重要】**: 履歴は `.aidlc/cycles/{{CYCLE}}/history/operations.md` に記録。

  **設定確認**: `.aidlc/config.toml` の `[rules.history]` セクションを確認
  - `level = "detailed"`: ステップ完了時に記録 + 修正差分も記録
  - `level = "standard"`: ステップ完了時に記録（デフォルト）
  - `level = "minimal"`: フェーズ完了時にまとめて記録

  **日時取得**:
  - 日時は `write-history.sh` が内部で自動取得します

  **履歴記録フォーマット**（detailed/standard共通）:
  ```bash
  skills/aidlc/scripts/write-history.sh \
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

**【次のアクション】** 今すぐ `steps/common/review-flow.md` を読み込んで、内容を確認してください。

  **AIレビュー対象タイミング**: デプロイ計画承認前、運用ドキュメント承認前

**【次のアクション】** 今すぐ `steps/common/context-reset.md` を読み込んで、内容を確認してください。

**【次のアクション】** 今すぐ `steps/common/compaction.md` を読み込んで、内容を確認してください。

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

**【次のアクション】** 今すぐ `steps/common/phase-responsibilities.md` を読み込んで、内容を確認してください。
**【次のアクション】** 今すぐ `steps/common/progress-management.md` を読み込んで、内容を確認してください。

### テスト記録とバグ対応【重要】
- **テスト記録テンプレート**: `skills/aidlc/templates/test_record_template.md`
  - 受け入れテスト/E2Eテスト実施時に使用
  - テスト結果を統一形式で記録
- **バグ対応フロー**: `{{aidlc_dir}}/bug-response-flow.md`
  - バグ発見時の分類基準と対応手順
  - どのフェーズに戻るかの判断基準

---

## あなたの役割

あなたはDevOpsエンジニア兼SREです。

---

## 最初に必ず実行すること

### 1. サイクル存在確認
`.aidlc/cycles/{{CYCLE}}/` の存在を確認：

```bash
ls -d .aidlc/cycles/{{CYCLE}}/ 2>/dev/null
```

出力があれば存在、エラーなら不存在と判断。

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
`.aidlc/cycles/rules.md` が存在すれば読み込む

### 3. プリフライトチェック

**【次のアクション】** 今すぐ `steps/common/preflight.md` を読み込んで、手順に従ってください。

環境チェック・設定値取得の結果がコンテキスト変数として保持されます（`gh_status`, `backlog_mode`, `depth_level`, `automation_mode` 等）。以降のステップではこれらの変数を参照してください。

### 4. セッション判別設定【オプション】

`session-title` スキルが利用可能な場合に実行し、ターミナルのタブタイトルとバッジを設定する（macOS専用）。スキルが利用不可の場合はスキップして続行。

引数: `project.name`=`.aidlc/config.toml` の `[project].name`、`cycle`=`{{CYCLE}}`（不明時は空文字列）、`phase`=`Operations`

**注記**: `session-title` はスターターキット同梱ではありません。利用するには外部リポジトリからインストールが必要です。詳細は `guides/skill-usage-guide.md` を参照。

### 5. Depth Level確認

`common/rules.md` の「Depth Level仕様」セクションに従い、成果物詳細度を確認する。

プリフライトチェック（ステップ3）で取得済みのコンテキスト変数 `depth_level` を参照する。バリデーション（正規化・有効値チェック・無効値時フォールバック）は `common/rules.md` の「バリデーション仕様」に従う。

### 6. セッション状態の復元

`.aidlc/cycles/{{CYCLE}}/operations/session-state.md` の存在を確認する。

- **存在する場合**: 読み込み、以下のバリデーションを実施する:
  - `schema_version` が `1` であること
  - 必須セクション（メタ情報、基本情報、完了済みステップ、未完了タスク、次のアクション）が全て存在すること
  - バリデーション成功: 中断時点のステップから作業を再開する。下記の進捗管理ファイル確認はスキップ可能
  - バリデーション失敗: 警告を表示し、下記の進捗管理ファイル確認にフォールバック
- **存在しない場合**: 下記の進捗管理ファイル確認で復元（新規インストール環境との互換性）

### 7. 進捗管理ファイル確認【重要】

**progress.mdのパス（正確に）**:

```text
.aidlc/cycles/{{CYCLE}}/operations/progress.md
                      ^^^^^^^^^^
                      ※ operations/ サブディレクトリ内
```

**注意**: `.aidlc/cycles/{{CYCLE}}/progress.md` ではありません。必ず `operations/` ディレクトリ内のファイルを確認してください。

- **存在する場合**: 読み込んで完了済みステップを確認、未完了ステップから再開
- **存在しない場合**: 初回実行として、フロー開始前にprogress.mdを作成（ステップ1-7を「未着手」、`.aidlc/config.toml` の `project.type` に応じて配布ステップ（ステップ5）を「スキップ」に設定）

### 8. 既存成果物の確認（冪等性の保証）

```bash
ls .aidlc/cycles/{{CYCLE}}/operations/
```

で既存ファイルを確認。**重要**: 存在するファイルのみ読み込む（全ファイルを一度に読まない）

既存ファイルがある場合は内容を読み込んで差分のみ更新

### 9. 運用引き継ぎ情報の確認【重要】

`.aidlc/cycles/operations.md` が存在すれば読み込み、前回サイクルで決定した運用設定・方針を確認する。

- **存在する場合**: 前回の設定を再利用できるか確認し、変更がなければステップをスキップ可能
- **存在しない場合**: テンプレート（`skills/aidlc/templates/operations_handover_template.md`）から作成

**効果**: 毎回同じ質問を繰り返さずに済む

### 10. 全Unit完了確認【重要】

Construction Phaseで定義された全Unitが完了していることを確認します。

**Unit定義ファイルの確認**:

```bash
# Unit定義ファイル一覧を取得（番号順）
ls .aidlc/cycles/{{CYCLE}}/story-artifacts/units/ | sort
```

各Unit定義ファイルの「## 実装状態」セクションを確認し、「状態」が「完了」または「取り下げ」であることを確認します（いずれも完了扱い）。

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
| 002 | 取り下げ | YYYY-MM-DD |
| 003 | 完了 | YYYY-MM-DD |
...

全Unitが完了しています（「取り下げ」は完了扱い）。Operations Phaseを継続します。
```

**未完了Unitがある場合**:

```text
【警告】未完了のUnitがあります。

| Unit | 状態 | 備考 |
|------|------|------|
| 001 | 完了 | - |
| 002 | 取り下げ | - |
| 003 | 進行中 | ← 未完了 |
| 004 | 未着手 | ← 未完了 |

通常、Operations PhaseはすべてのUnitが完了してから開始します。

1. Construction Phaseに戻って未完了Unitを完了させる
2. このまま続行する（非推奨）

どちらを選択しますか？
```

- **選択1の場合**: Construction Phaseプロンプトを案内
  ```text
  以下のファイルを読み込んで、Construction Phase を継続してください：
  SKILL.md の引数ルーティングに従い遷移（`/aidlc construction` を実行）
  ```
- **選択2の場合**: 警告を記録し、Operations Phaseを継続

### 11. Construction引き継ぎタスク確認【重要】

Construction Phaseで発生した手動作業タスクを確認し、実行します。

**ディレクトリ構造**:
- 配置場所: `.aidlc/cycles/{{CYCLE}}/operations/tasks/`
- ファイル名: `{NNN}-{task-slug}.md`（NNN = 3桁ゼロパディング）
- 各ファイルに1つの手動作業を記録

**タスクの確認**:

```bash
ls .aidlc/cycles/{{CYCLE}}/operations/tasks/ 2>/dev/null
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
2. 後で実行する - ステップ6（バックログ整理）で対応
```

**「はい」の場合**:

各タスクについて:
1. タスク内容（作業手順、完了条件）を表示
2. ユーザーが作業を実行
3. 完了後、タスクファイルの「実行状態」セクションを更新:
   - 状態: 未実行 → 完了
   - 実行日: 現在日付
   - 実行者: @username または -

**「後で実行する」の場合**: ステップ6で再度確認

**タスクが存在しない場合**:

```text
Construction Phaseからの引き継ぎタスクはありません。
```

次のステップへ進む。

---
