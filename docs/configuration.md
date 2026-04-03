# 設定ファイルリファレンス

AI-DLC Starter Kit の設定ファイルの構造、マージ優先順位、全キーの説明です。

## 設定ファイルの種類

| ファイル | パス | Git管理 | 用途 |
|---------|------|---------|------|
| デフォルト設定 | `skills/aidlc/config/defaults.toml` | Yes（スキル内） | 全キーのデフォルト値を定義 |
| ユーザー共通設定 | `~/.aidlc/config.toml` | No | ユーザー固有の共通設定（複数プロジェクト共通） |
| プロジェクト設定 | `.aidlc/config.toml` | Yes | プロジェクト固有の設定 |
| ローカル設定 | `.aidlc/config.local.toml` | No | 個人設定（プロジェクト設定を上書き） |

## マージ優先順位

設定値は以下の順で解決されます（後のものが優先）:

1. `defaults.toml` — 最低優先（フォールバック値）
2. `~/.aidlc/config.toml` — ユーザー共通設定
3. `.aidlc/config.toml` — プロジェクト設定（**必須**）
4. `.aidlc/config.local.toml` — ローカル設定（最高優先）

キー単位でマージされます。上位の設定で値が定義されていれば、下位の値を上書きします。

## プロジェクト固有設定

### `[project]` セクション

| キー | 型 | 説明 |
|------|-----|------|
| `name` | string | プロジェクト名 |
| `type` | string | プロジェクト種別（`general` / `ios` 等） |
| `description` | string | プロジェクトの説明 |

### `[project.tech_stack]` セクション

| キー | 型 | 説明 |
|------|-----|------|
| `languages` | array | 使用言語 |
| `frameworks` | array | 使用フレームワーク |
| `tools` | array | 使用ツール |

### トップレベル

| キー | 型 | 説明 |
|------|-----|------|
| `starter_kit_version` | string | インストール済みスターターキットのバージョン |

## ルール設定（`[rules.*]`）

### `[rules.automation]` — 自動化モード

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `mode` | string | `"manual"` | `manual`: 全承認ポイントでユーザー確認。`semi_auto`: フォールバック条件非該当時に自動承認 |

### `[rules.reviewing]` — レビュー設定

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `mode` | string | `"recommend"` | `required`: AIレビュー必須。`recommend`: 推奨（スキップ可）。`disabled`: 無効 |
| `tools` | array | `["codex"]` | 使用するレビューツールの優先順位リスト（`codex` / `claude` / `gemini`） |
| `exclude_patterns` | array | `[]` | レビュー対象から除外するファイルパターン |

### `[rules.depth_level]` — 成果物詳細度

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `level` | string | `"standard"` | `minimal`: 簡略化。`standard`: 通常。`comprehensive`: 詳細（リスク分析等追加） |

### `[rules.squash]` — コミット統合

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `enabled` | boolean | `false` | Unit/Phase完了時に中間コミットをスカッシュするか |

### `[rules.commit]` — コミット設定

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `ai_author_auto_detect` | boolean | `true` | AIツールを自動検出してCo-Authored-Byを付与するか |
| `ai_author` | string | `""` | 手動指定時のAI著者名（空なら自動検出） |

### `[rules.git]` — Git設定

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `commit_on_unit_complete` | boolean | `true` | Unit完了時に自動コミットするか |
| `commit_on_phase_complete` | boolean | `true` | Phase完了時に自動コミットするか |

### `[rules.branch]` — ブランチ設定

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `mode` | string | `"ask"` | `branch`: 自動ブランチ作成。`worktree`: worktree作成。`ask`: ユーザーに選択 |

### `[rules.unit_branch]` — Unitブランチ

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `enabled` | boolean | `false` | Unit単位でブランチを作成するか |

### `[rules.cycle]` — サイクル設定

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `mode` | string | `"default"` | `default`: バージョン番号のみ。`named`: 名前付きサイクル。`ask`: 選択 |
| `named_enabled` | boolean | `false` | 名前付きサイクル機能を有効にするか |

### `[rules.construction]` — Construction Phase

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `max_retry` | integer | `3` | Self-Healingループの最大リトライ回数 |

### `[rules.preflight]` — プリフライトチェック

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `enabled` | boolean | `true` | オプションチェックを実行するか |
| `checks` | array | `["gh", "review-tools", "config-validation"]` | 実行するチェック項目 |

### `[rules.linting]` — Lint設定

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `markdown_lint` | boolean | `false` | Markdownlintを実行するか |

### `[rules.size_check]` — ファイルサイズチェック

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `enabled` | boolean | `true` | ファイルサイズチェックを有効にするか |
| `max_bytes` | integer | `150000` | 最大バイト数 |
| `max_lines` | integer | `1000` | 最大行数 |
| `max_tokens` | integer | `40000` | 最大トークン数 |
| `target_pattern` | string | `"*.md"` | チェック対象のファイルパターン |

### `[rules.history]` — 履歴記録

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `level` | string | `"standard"` | `detailed`: ステップ完了時+修正差分。`standard`: ステップ完了時。`minimal`: フェーズ/Unit完了時 |

### `[rules.release]` — リリース設定

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `changelog` | boolean | `false` | CHANGELOG.mdを生成するか |
| `version_tag` | boolean | `false` | Gitタグを作成するか |

### `[rules.worktree]` — Worktree設定

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `enabled` | boolean | `false` | worktree方式を有効にするか（branch.mode=worktreeの前提） |

### `[rules.feedback]` — フィードバック

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `enabled` | boolean | `true` | フィードバック機能を有効にするか |

### `[rules.version_check]` — バージョンチェック

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `enabled` | boolean | `true` | セッション開始時のバージョンチェックを有効にするか |

### `[rules.documentation]` — ドキュメント

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `language` | string | `"日本語"` | ドキュメントの言語 |

## カスタマイズ例

### レビューを必須にする

```toml
[rules.reviewing]
mode = "required"
tools = ["codex"]
```

### セミオートモードを有効にする

```toml
[rules.automation]
mode = "semi_auto"
```

### Markdownlintとスカッシュを有効にする

```toml
[rules.linting]
markdown_lint = true

[rules.squash]
enabled = true
```

## 欠落キーの自動検出

バージョンアップで新しいキーが追加された場合、`/aidlc setup` のアップグレードフロー実行時に自動的に検出されます。欠落キーは追記候補として提示され、ユーザーの確認後にconfig.tomlに追記されます。
