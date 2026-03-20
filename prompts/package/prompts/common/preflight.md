# プリフライトチェック

各フェーズ開始時に環境・ツール・設定の整合性を一括チェックし、結果をコンテキスト変数として保持する共通手順。

## 手順

### 1. 環境チェック

以下のコマンドを実行し、ツール状態を取得する:

```bash
docs/aidlc/bin/env-info.sh
```

出力から以下を抽出し、コンテキスト変数に保持する:

| 出力キー | コンテキスト変数 | 説明 |
|---------|----------------|------|
| `gh:{status}` | `gh_status` | GitHub CLI状態（`available` / `not-installed` / `not-authenticated`） |
| `git:{status}` | - | git存在確認（blocker判定に使用） |
| `dasel:{status}` | - | dasel状態（情報保持のみ） |

**互換エイリアス**: 既存フェーズプロンプトで `gh:available` 形式で参照している箇所は `gh_status` で読み替える。

```bash
docs/aidlc/bin/check-backlog-mode.sh
```

出力: `backlog_mode:{mode}` → `backlog_mode` コンテキスト変数

### 2. 重大度判定（環境チェック）

| チェック対象 | severity | 判定条件 | 失敗時の挙動 |
|-------------|----------|---------|-------------|
| git | blocker | `git:available` でない場合 | フェーズ中断 |
| gh | warn | `gh:available` でない場合 | 警告表示、gh依存機能を無効化して続行 |

### 3. aidlc.toml確認

```bash
ls docs/aidlc.toml 2>/dev/null
```

- **存在しない場合（blocker）**: 以下を表示しフェーズ中断

  ```text
  【プリフライトチェック失敗】
  docs/aidlc.toml が見つかりません。
  AI-DLCのセットアップが必要です。prompts/setup-prompt.md を参照してください。
  ```

- **存在する場合**: `[project].name` を確認

  ```bash
  docs/aidlc/bin/read-config.sh project.name
  ```

  - 取得成功: 情報保持
  - 取得失敗（warn）: 「`[project].name` が未設定です。一部機能が制限される場合があります。」と警告表示して続行

### 4. レビューツール確認（条件付き）

**前提**: 手順5で `review_mode` を取得した後に実行する。ただし、チェック実行タイミングは手順5の後とする。

以下の**両方**を満たす場合のみ実行:
- `review_mode` が `disabled` でない
- `review_tools` が空配列 `[]` でない

**条件を満たさない場合**:
- `review_mode == disabled`: スキップ（情報表示なし）
- `review_tools == []`: 「外部CLIを使用しない設定です（tools = []）」と情報表示し、スキップ

**条件を満たす場合**:

`review_tools` リストの先頭ツールの存在を確認:

```bash
which codex >/dev/null 2>&1
```

- 存在する場合: `ℹ レビューツール ({tool名}): available`
- 存在しない場合: `ℹ レビューツール ({tool名}): not found（レビュー実行時にフォールバックします）`

**severity**: info（フェーズ続行に影響しない）

### 5. 設定値取得

各設定キーを `read-config.sh` の単一キーモード + `--default` で個別に取得する。`--default` によりキー不在時もデフォルト値が確実に返される。

```bash
docs/aidlc/bin/read-config.sh rules.depth_level.level --default "standard"
docs/aidlc/bin/read-config.sh rules.automation.mode --default "manual"
docs/aidlc/bin/read-config.sh rules.reviewing.mode --default "recommend"
docs/aidlc/bin/read-config.sh rules.reviewing.tools --default "['codex']"
docs/aidlc/bin/read-config.sh rules.squash.enabled --default "false"
docs/aidlc/bin/read-config.sh rules.linting.markdown_lint --default "false"
docs/aidlc/bin/read-config.sh rules.unit_branch.enabled --default "false"
docs/aidlc/bin/read-config.sh rules.history.level --default "standard"
```

**コンテキスト変数への格納**:

| 設定キー | コンテキスト変数名 | デフォルト値 |
|---------|-------------------|------------|
| rules.depth_level.level | `depth_level` | standard |
| rules.automation.mode | `automation_mode` | manual |
| rules.reviewing.mode | `review_mode` | recommend |
| rules.reviewing.tools | `review_tools` | ['codex'] |
| rules.squash.enabled | `squash_enabled` | false |
| rules.linting.markdown_lint | `markdown_lint` | false |
| rules.unit_branch.enabled | `unit_branch_enabled` | false |
| rules.history.level | `history_level` | standard |

**エラー処理**: `read-config.sh` が exit code 2（エラー）を返した場合、以下の警告を表示しデフォルト値を使用する:

```text
【警告】{設定キー} の読み取りに失敗しました。デフォルト値 "{デフォルト値}" を使用します。
```

**注記**: 手順5完了後に手順4（レビューツール確認）を実行する（`review_mode` と `review_tools` が必要なため）。

### 6. 結果提示

全チェックと設定値取得が完了したら、以下のフォーマットで結果を提示する:

```text
【プリフライトチェック結果】

■ 環境チェック
  ✓ git: available
  ✓ aidlc.toml: 存在
  {✓ | ⚠} gh: {status}（{status が available でない場合: gh依存機能は制限されます}）
  ℹ レビューツール ({tool名}): {available | not found}

■ 主要設定値
  depth_level: {value}
  automation_mode: {value}
  review_mode: {value}
  review_tools: {value}
  squash_enabled: {value}
  markdown_lint: {value}
  unit_branch_enabled: {value}
  history_level: {value}
  backlog_mode: {value}

■ 判定: {続行可能 | 続行可能（警告N件）}
```

### 7. 再チェックフロー

blocker項目が失敗した場合、ユーザーに対処を依頼する:

```text
【プリフライトチェック失敗】

以下の問題を解決してから再実行してください:
- {失敗項目}: {対処方法}

問題を解決したら「再チェック」と入力してください。
```

**再チェック**: ユーザーが「再チェック」「retry」等を入力した場合、失敗したblocker/warn項目のみを再チェックする。

**最大回数**: 3回。超過時は以下を表示しフェーズ中断:

```text
【プリフライトチェック中断】
再チェック回数の上限（3回）に達しました。
問題を解決してからフェーズを再開してください。
```

## 実行順序まとめ

1. 環境チェック（手順1-2）
2. aidlc.toml確認（手順3）
3. 設定値取得（手順5）
4. レビューツール確認（手順4 - `review_mode` と `review_tools` に依存するため手順5の後に実行）
5. 結果提示（手順6）
6. 必要に応じて再チェック（手順7）
