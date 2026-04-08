# プリフライトチェック

フェーズ開始時の環境・ツール・設定チェック。結果はコンテキスト変数に保持。

## 手順

### 1. 環境チェック

```bash
scripts/env-info.sh
```

| 出力キー | コンテキスト変数 |
|---------|----------------|
| `gh:{status}` | `gh_status` |
| `git:{status}` | - |
| `dasel:{status}` | - |
| `dasel_major_version:{version}` | `dasel_major_version` |

### 2. 重大度判定（環境チェック）

| チェック対象 | severity | 判定条件 | 失敗時の挙動 |
|-------------|----------|---------|-------------|
| git | blocker | `git:available` でない場合 | フェーズ中断 |

### 3. config.toml確認

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

`read-config.sh` のバッチモードで一括取得する:

```bash
scripts/read-config.sh --keys rules.depth_level.level rules.depth_level.history_level rules.automation.mode rules.reviewing.mode rules.reviewing.tools rules.git.squash_enabled rules.linting.enabled rules.git.unit_branch_enabled rules.construction.max_retry rules.git.merge_method
```

出力は `key:value` 形式（1行1キー）。各行をパースしコンテキスト変数に格納:

| 設定キー | コンテキスト変数名 |
|---------|-------------------|
| rules.depth_level.level | `depth_level` |
| rules.depth_level.history_level | （派生ロジックで処理） |
| rules.automation.mode | `automation_mode` |
| rules.reviewing.mode | `review_mode` |
| rules.reviewing.tools | `review_tools` |
| rules.git.squash_enabled | `squash_enabled` |
| rules.linting.enabled | （派生ロジックで処理） |
| rules.git.unit_branch_enabled | `unit_branch_enabled` |
| rules.construction.max_retry | `max_retry` |
| rules.git.merge_method | `merge_method` |

**history_level 解決ロジック**:

1. 取得値が非空 → `history_level`に設定
2. 空 → 旧キーフォールバック:
   ```bash
   scripts/read-config.sh rules.history.level
   ```
   - exit 0かつ非空 → `history_level`に設定
   - exit 1 → `depth_level`から自動導出:

     | depth_level | history_level |
     |-------------|--------------|
     | minimal | minimal |
     | standard | standard |
     | comprehensive | detailed |

**markdown_lint 解決ロジック**:

1. `rules.linting.enabled`が `true` / `false` → `markdown_lint`に設定
2. 空または取得失敗 → 旧キーフォールバック:
   ```bash
   scripts/read-config.sh rules.linting.markdown_lint
   ```
   - exit 0かつ非空 → `markdown_lint`に設定
   - exit 1 → デフォルト値 `false`

**merge_method バリデーション**:

1. `merge` / `squash` / `rebase` / `ask` → `merge_method`に設定
2. それ以外 → `⚠ merge_method の値が不正です（"{value}"）。デフォルト値 "ask" を使用します。`

**エラー処理**: exit code 2 の場合:

```text
【警告】{設定キー} の読み取りに失敗しました。デフォルト値 "{デフォルト値}" を使用します。
```

### 5. オプションチェック実行

| チェック項目 | 条件 | 動作 | 表示内容 | severity |
|-------------|------|------|---------|----------|
| gh | `gh_status` != `available` | 警告表示、gh依存機能無効化 | `⚠ gh: {status}（gh依存機能は制限されます）` | warn |
| レビューツール | `review_mode == disabled` | スキップ | （なし） | - |
| レビューツール | `review_tools == []` | 情報表示 | `ℹ 外部CLIを使用しない設定です（tools = []）` | info |
| レビューツール | 上記以外 | `command -v -- "{先頭ツール}"` で確認（ツール名は `[a-zA-Z0-9_-]+` のみ許可） | `ℹ レビューツール ({ツール名}): available / not found` | info |
| defaults.toml | `config/defaults.toml` 不在 | 警告表示 | `⚠ defaults.toml: 不在（デフォルト値が適用されません）` | warn |

### 6. 結果提示

```text
【プリフライトチェック結果】

■ 環境チェック（blocker - 常時実行）
  ✓ git: available
  ✓ aidlc.toml: 存在

■ オプションチェック（常時実行）
  {✓ | ⚠} gh: {status}（{status が available でない場合: gh依存機能は制限されます}）
  ℹ レビューツール ({tool名}): {available | not found}
  {✓ | ⚠} defaults.toml: {存在 | 不在（デフォルト値が適用されません。config/defaults.toml を確認してください）}

■ ツールバージョン
  dasel_major_version: {value}（未インストール時は「N/A」）

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
  merge_method: {value}

■ 判定: {続行可能 | 続行可能（警告N件）}
```

### 7. 再チェックフロー

```text
【プリフライトチェック失敗】

以下の問題を解決してから再実行してください:
- {失敗項目}: {対処方法}

問題を解決したら「再チェック」と入力してください。
```

再チェック: 失敗したblocker/warn項目のみ再実行。最大3回。超過時:

```text
【プリフライトチェック中断】
再チェック回数の上限（3回）に達しました。
問題を解決してからフェーズを再開してください。
```
