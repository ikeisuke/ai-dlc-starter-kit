# プリフライトチェック

各フェーズ開始時に環境・ツール・設定の整合性を一括チェックし、結果をコンテキスト変数として保持する共通手順。

## 手順

### 1. 環境チェック

以下のコマンドを実行し、ツール状態を取得する:

```bash
scripts/env-info.sh
```

出力から以下を抽出し、コンテキスト変数に保持する:

| 出力キー | コンテキスト変数 | 説明 |
|---------|----------------|------|
| `gh:{status}` | `gh_status` | GitHub CLI状態（`available` / `not-installed` / `not-authenticated`） |
| `git:{status}` | - | git存在確認（blocker判定に使用） |
| `dasel:{status}` | - | dasel状態（情報保持のみ） |

**互換エイリアス**: 既存フェーズプロンプトで `gh:available` 形式で参照している箇所は `gh_status` で読み替える。

### 2. 重大度判定（環境チェック）

| チェック対象 | severity | 判定条件 | 失敗時の挙動 |
|-------------|----------|---------|-------------|
| git | blocker | `git:available` でない場合 | フェーズ中断 |

**注**: `gh_status` は手順1で常時取得されコンテキスト変数に保持される。`gh` の warn 判定と結果表示は手順5のオプションチェックで行う。

### 3. aidlc.toml確認

```bash
ls .aidlc/config.toml 2>/dev/null
```

- **存在しない場合（blocker）**: 以下を表示しフェーズ中断

  ```text
  【プリフライトチェック失敗】
  .aidlc/config.toml が見つかりません。
  AI-DLCのセットアップが必要です。`/aidlc setup` を実行してください。
  ```

- **存在する場合**: `[project].name` を確認

  ```bash
  scripts/read-config.sh project.name
  ```

  - 取得成功: 情報保持
  - 取得失敗（warn）: 「`[project].name` が未設定です。一部機能が制限される場合があります。」と警告表示して続行

### 4. 設定値取得

全設定キーを `read-config.sh` の `--keys` バッチモードで一括取得する。defaults.toml にデフォルト値が定義されているため、キー不在は発生しない。

```bash
scripts/read-config.sh --keys rules.depth_level.level rules.depth_level.history_level rules.automation.mode rules.reviewing.mode rules.reviewing.tools rules.squash.enabled rules.linting.markdown_lint rules.unit_branch.enabled rules.construction.max_retry
```

**出力形式**（`key:value` 形式、1行1キー）:

```text
rules.depth_level.level:standard
rules.automation.mode:manual
rules.reviewing.mode:recommend
...
```

各行を `key:value` でパースし、コンテキスト変数に格納する。

**コンテキスト変数への格納**:

| 設定キー | コンテキスト変数名 | デフォルト値 |
|---------|-------------------|------------|
| rules.depth_level.level | `depth_level` | standard |
| rules.depth_level.history_level | （後続の解決ロジックで処理） | ""（空文字=自動導出） |
| rules.automation.mode | `automation_mode` | manual |
| rules.reviewing.mode | `review_mode` | recommend |
| rules.reviewing.tools | `review_tools` | ['codex'] |
| rules.squash.enabled | `squash_enabled` | false |
| rules.linting.markdown_lint | `markdown_lint` | false |
| rules.unit_branch.enabled | `unit_branch_enabled` | false |
| rules.construction.max_retry | `max_retry` | 3 |

**history_level 解決ロジック**（派生コンテキスト変数）:

上記バッチ取得後、`rules.depth_level.history_level`の値を確認し、以下のフローで`history_level`コンテキスト変数を解決する:

1. 取得値が空文字でない → `history_level`に設定（明示オーバーライド）
2. 取得値が空文字 → 旧キーフォールバック:
   ```bash
   scripts/read-config.sh rules.history.level
   ```
   - exit 0かつ非空 → `history_level`に設定（旧config.tomlに明示記載あり）
   - exit 1（キー不在）→ `depth_level`から自動導出:

     | depth_level | history_level |
     |-------------|--------------|
     | minimal | minimal |
     | standard | standard |
     | comprehensive | detailed |

**エラー処理**: `read-config.sh` が exit code 2（エラー）を返した場合、以下の警告を表示しデフォルト値を使用する:

```text
【警告】{設定キー} の読み取りに失敗しました。デフォルト値 "{デフォルト値}" を使用します。
```

### 5. オプションチェック実行

以下の全項目を常時実行する。

#### gh チェック

手順1で取得済みの `gh_status` を結果提示に含める。`gh:available` でない場合は警告表示し、gh依存機能を無効化して続行（severity: warn）。

#### レビューツール確認

以下の**両方**を満たす場合のみ実行:
- `review_mode` が `disabled` でない
- `review_tools` が空配列 `[]` でない

**条件を満たさない場合**:
- `review_mode == disabled`: スキップ（情報表示なし）
- `review_tools == []`: 「外部CLIを使用しない設定です（tools = []）」と情報表示し、スキップ

**条件を満たす場合**:

`review_tools` リストの先頭ツールの存在を `which {先頭ツール名}` で確認:

```bash
which {先頭ツール名} >/dev/null 2>&1
```

（例: `review_tools = ["codex"]` なら `which codex`、`["claude"]` なら `which claude`）

- 存在する場合: `ℹ レビューツール ({先頭ツール名}): available`
- 存在しない場合: `ℹ レビューツール ({先頭ツール名}): not found（レビュー実行時にフォールバックします）`

**severity**: info（フェーズ続行に影響しない）

#### 設定バリデーション

設定値のバリデーション結果を結果提示の「オプションチェック」セクションに含める。`config/defaults.toml` の存在チェックも実施し、不在の場合は警告を表示する（severity: warn）。

### 6. 結果提示

全チェックと設定値取得が完了したら、以下のフォーマットで結果を提示する:

```text
【プリフライトチェック結果】

■ 環境チェック（blocker - 常時実行）
  ✓ git: available
  ✓ aidlc.toml: 存在

■ オプションチェック（常時実行）
  {✓ | ⚠} gh: {status}（{status が available でない場合: gh依存機能は制限されます}）
  ℹ レビューツール ({tool名}): {available | not found}
  {✓ | ⚠} defaults.toml: {存在 | 不在（デフォルト値が適用されません。config/defaults.toml を確認してください）}

■ 主要設定値（常時表示）
  depth_level: {value}
  automation_mode: {value}
  review_mode: {value}
  review_tools: {value}
  squash_enabled: {value}
  markdown_lint: {value}
  unit_branch_enabled: {value}
  history_level: {value}
  max_retry: {value}

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

1. 環境チェック（手順1-2）— blockerチェック含む、常時実行
2. aidlc.toml確認（手順3）— blockerチェック、常時実行
3. 設定値取得（手順4）
4. オプションチェック実行（手順5）— 常時実行
5. 結果提示（手順6）
6. 必要に応じて再チェック（手順7）
