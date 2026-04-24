# Inception Phase - インセプション準備

## ステップ2: インセプション準備

### 14. 環境確認（プリフライト結果参照）

ステップ1のプリフライトチェックで取得済みのコンテキスト変数を参照する:

- `gh_status`: GitHub CLI状態（`available` / `not-installed` / `not-authenticated`）
**注記**: 環境チェックはプリフライトで完了済みのため、個別スクリプトの再実行は不要。

### 14b. エクスプレスモードインスタント検出

ユーザーの初回入力（セッション開始トリガー）が「start express」であるかを判定する。

**判定方法**: 初回入力をtrim（前後の空白除去）し、「start express」と完全一致（case-insensitive）するかを確認する。

- **一致した場合**: `express_enabled=true`、`express_source=command` をコンテキスト変数として保持する。`common/rules-automation.md` の「エクスプレスモード仕様」セクションの「`start express` コマンドの動作」に従い、メッセージを表示する。**depth_level は変更しない**。ステップ15に進む（depth_level は設定ファイルから通常通り取得する）。
- **一致しない場合**: `express_enabled=false` をコンテキスト変数として保持し、ステップ15に進む（通常フロー）。

### 15. Depth Level確認

プリフライトチェック（ステップ1）で取得済みの `depth_level` コンテキスト変数を参照し、`depth_level_source=config` を設定する。バリデーション（正規化・有効値チェック・無効値時フォールバック）は `common/rules-reference.md` の「Depth Level仕様」に従う。

### 16. GitHub Issue確認

GitHub CLIでオープンなIssueの有無を確認（プリフライトで取得した `gh_status` を参照）：

**`gh_status` が `available` の場合のみ**:
```bash
scripts/check-open-issues.sh
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

**Milestone 機能 opt-in ガード（v2.4.0 以降、Unit 008 / #597 Unit G）**:

`MILESTONE_ENABLED` を判定する:

```bash
scripts/read-config.sh rules.github.milestone_enabled
```

実行結果（exit 0 で stdout が `true`、それ以外はキー不在 / 致命エラー）を `MILESTONE_ENABLED` として扱う。stdout が `true` 以外、または exit コードが 0 でない場合は `false` 相当として扱う。

- `MILESTONE_ENABLED` が `true` 以外（既定）の場合: メッセージ `milestone:disabled:skip:step=02-preparation-step16:reason=opt-out` を出力し、**本ステップの Milestone 紐付け処理をすべてスキップ**して次のステップへ進む。後続の `gh_status` 判定および Milestone 紐付け bash 群は **一切実行しない**
- `MILESTONE_ENABLED` が `true` の場合: 以下の `gh_status` 判定および Milestone 紐付け処理を実行する

**Milestone 紐付け**（`gh_status` が `available` の場合、Issueを選択した後）:

選択したIssueを今回サイクルの Milestone に紐付けます。Milestone は `inception.05-completion` ステップ1で正式に作成・紐付けされます。本ステップでは **既存 Milestone がある場合のみ先行紐付け** を行うオプショナル動作とし、Milestone 作成・フォールバック PATCH の正式な手順は 05-completion ステップ1 に集約します。

`scripts/milestone-ops.sh early-link` がスクリプト内部で 5 ケース判定を行い、`open=1 && closed=0` のときのみ各 Issue を `gh issue edit --milestone {{CYCLE}}` で先行紐付けします。それ以外のケース（open≥2 / closed≥1 / 不在 / 混在）は必ず **先行紐付けをスキップ** し、05-completion ステップ1 の 5 ケース判定 + 作成 + フォールバック PATCH に委譲します。

`<SELECTED_ISSUES>` は本ステップ「Issue 確認」サブセクションで選択した Issue 番号の改行区切りリストを、`--issues` に文字列として渡します（複数 Issue 対応）。`<MILESTONE_NUMBER>` は 05-completion で確定するため本ステップでは未確定でも構わず、空でも先行紐付け自体は試行可能（PATCH フォールバックを行わないため）。

```bash
scripts/milestone-ops.sh early-link {{CYCLE}} \
  --milestone-number 0 \
  --issues "<SELECTED_ISSUES>"
```

stdout 出力（1 行 / Issue 、または 1 行のスキップ理由）:

- `issue:<N>:linked-early:milestone={{CYCLE}}`（先行紐付け成功）
- `issue:<N>:link-failed-early:will-retry-in-05-completion`（gh issue edit 失敗、05-completion ステップ1 で再試行されるため本ステップは exit 0 を維持）
- `early-link:skip:open=<N>:closed=<N>:reason=defer-to-05-completion`（5 ケース判定でスキップ条件に該当）
- `early-link:no-issues-provided`（`SELECTED_ISSUES` が空）

**注**: 本ステップでの先行紐付けは `gh issue edit --milestone` のみを使用し、PATCH フォールバックは 05-completion ステップ1 に集約します（責任分離のため）。`gh issue edit --milestone` が権限または環境差分で失敗する場合は本ステップではエラーログのみ残し、05-completion ステップ1 のフォールバック手順で再試行されます。

詳細は `guides/issue-management.md` を参照。

### 17. バックログ確認

#### 17-1. 共通バックログ

`gh_status` が `available` の場合のみ:
```bash
gh issue list --label backlog --state open
```

`gh_status` が `available` 以外の場合: 「警告: GitHub CLIが利用できないため、バックログ確認をスキップします。」と表示する。

**詳細**: `guides/backlog-management.md` を参照

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

### 18. 既存成果物の確認（冪等性の保証）

```bash
ls .aidlc/cycles/{{CYCLE}}/requirements/ .aidlc/cycles/{{CYCLE}}/story-artifacts/ .aidlc/cycles/{{CYCLE}}/design-artifacts/
```

で既存ファイルを確認。**重要**: 存在するファイルのみ読み込む（全ファイルを一度に読まない）

既存ファイルがある場合は内容を読み込んで差分のみ更新。完了済みのステップはスキップ。

---
