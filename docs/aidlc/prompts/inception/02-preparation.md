# Inception Phase - インセプション準備

## Part 2: インセプション準備

### 14. 環境確認（プリフライト結果参照）

Part 1 ステップ1のプリフライトチェックで取得済みのコンテキスト変数を参照する:

- `gh_status`: GitHub CLI状態（`available` / `not-installed` / `not-authenticated`）
**注記**: 環境チェックはプリフライトで完了済みのため、個別スクリプトの再実行は不要。

### 14b. エクスプレスモードインスタント検出

ユーザーの初回入力（セッション開始トリガー）が「start express」であるかを判定する。

**判定方法**: 初回入力をtrim（前後の空白除去）し、「start express」と完全一致（case-insensitive）するかを確認する。

- **一致した場合**: `express_enabled=true`、`express_source=command` をコンテキスト変数として保持する。`common/rules.md` の「エクスプレスモード仕様」セクションの「`start express` コマンドの動作」に従い、メッセージを表示する。**depth_level は変更しない**。ステップ15に進む（depth_level は設定ファイルから通常通り取得する）。
- **一致しない場合**: `express_enabled=false` をコンテキスト変数として保持し、ステップ15に進む（通常フロー）。

### 15. Depth Level確認

プリフライトチェック（Part 1 ステップ1）で取得済みの `depth_level` コンテキスト変数を参照し、`depth_level_source=config` を設定する。バリデーション（正規化・有効値チェック・無効値時フォールバック）は `common/rules.md` の「バリデーション仕様」に従う。

### 16. GitHub Issue確認

GitHub CLIでオープンなIssueの有無を確認（プリフライトで取得した `gh_status` を参照）：

**`gh_status` が `available` の場合のみ**:
```bash
skills/aidlc/scripts/check-open-issues.sh
```

**判定**:
- **`gh_status` が `available` 以外**: 次のステップへ進行
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

**サイクルラベル付与**（`gh_status` が `available` の場合、Issueを選択した後）:

選択したIssueにサイクルラベルを付与します。

```bash
# 一括付与（Unit定義作成後に実行）
skills/aidlc/scripts/label-cycle-issues.sh {{CYCLE}}
```

詳細は `{{aidlc_dir}}/guides/issue-management.md` を参照。

### 17. バックログ確認

#### 17-1. 共通バックログ

`gh_status` が `available` の場合のみ:
```bash
gh issue list --label backlog --state open
```

`gh_status` が `available` 以外の場合: 「警告: GitHub CLIが利用できないため、バックログ確認をスキップします。」と表示する。

**詳細**: `{{aidlc_dir}}/guides/backlog-management.md` を参照

- **存在しない/空の場合**: スキップ
- **項目が存在する場合**: 内容を確認し、ユーザーに質問
  ```text
  共通バックログに以下の項目があります：
  [ファイル一覧 または Issue一覧]

  これらを確認しますか？
  ```
  「はい」の場合は各項目の内容を表示し、今回のサイクルで対応する項目を確認

#### 17-2. 対応済みバックログとの照合

対応済みバックログを確認（新形式: サイクル別ディレクトリ、旧形式: 単一ファイル）：

```bash
# 新形式（サイクル別ディレクトリ）
ls -R .aidlc/cycles/backlog-completed/ 2>/dev/null
# 旧形式（単一ファイル、後方互換性）
cat .aidlc/cycles/backlog-completed.md 2>/dev/null
```

- **存在しない/空の場合**: スキップ
- **ファイルが存在する場合**: 17-1で確認したバックログ項目と照合
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

### 17-3. タスクリスト作成【必須】

**【次のアクション】** `steps/common/task-management.md` の「Inception Phase: タスクテンプレート」に従い、フェーズのタスクリストを作成してください。各ステップの着手・完了時にタスクステータスを更新すること。

### 18. 進捗管理ファイル確認【重要】

**progress.mdのパス（正確に）**:

```text
.aidlc/cycles/{{CYCLE}}/inception/progress.md
                      ^^^^^^^^^
                      ※ inception/ サブディレクトリ内
```

**注意**: `.aidlc/cycles/{{CYCLE}}/progress.md` ではありません。必ず `inception/` ディレクトリ内のファイルを確認してください。

- **存在する場合**: 読み込んで完了済みステップを確認、未完了ステップから再開
- **存在しない場合**: 初回実行として、フロー開始前にprogress.mdを作成（全ステップ「未着手」）

### 19. 既存成果物の確認（冪等性の保証）

```bash
ls .aidlc/cycles/{{CYCLE}}/requirements/ .aidlc/cycles/{{CYCLE}}/story-artifacts/ .aidlc/cycles/{{CYCLE}}/design-artifacts/
```

で既存ファイルを確認。**重要**: 存在するファイルのみ読み込む（全ファイルを一度に読まない）

既存ファイルがある場合は内容を読み込んで差分のみ更新。完了済みのステップはスキップ。

---
