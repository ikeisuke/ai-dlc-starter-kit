# 設定ファイルリファレンス

AI-DLC Starter Kit の設定ファイルの構造、マージ優先順位、全キーの説明です。

## 設定ファイルの種類

| ファイル | パス | 配置元 | Git管理 | 用途 |
|---------|------|--------|---------|------|
| デフォルト設定 | `config/defaults.toml`（スキルディレクトリ内） | スキルプラグインに同梱。ユーザーが直接編集する必要はない | - | 全キーのデフォルト値を定義（フォールバック） |
| ユーザー共通設定 | `~/.aidlc/config.toml` | ユーザーが手動作成 | No | ユーザー固有の共通設定（複数プロジェクト共通） |
| プロジェクト設定 | `.aidlc/config.toml` | `/aidlc setup` で生成 | Yes | プロジェクト固有の設定 |
| ローカル設定 | `.aidlc/config.local.toml` | ユーザーが手動作成 | No | 個人設定（プロジェクト設定を上書き） |

> **Note**: デフォルト設定（`defaults.toml`）はスキルプラグイン内に同梱されており、プロジェクトディレクトリには配置されません。`read-config.sh` が内部的にフォールバック値として参照するため、ユーザーが意識する必要はありません。

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
| `starter_kit_version` | string | 最後に実行した `aidlc-setup` / `aidlc-migrate` のバージョン（v2.4.0 以降、`bin/update-version.sh` による上書き対象外） |

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

### `[rules.git]` — Git設定（v2.1.8で統合）

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `commit_on_unit_complete` | boolean | `true` | Unit完了時に自動コミットするか |
| `commit_on_phase_complete` | boolean | `true` | Phase完了時に自動コミットするか |
| `branch_mode` | string | `"ask"` | `branch`: 自動ブランチ作成。`worktree`: worktree作成。`ask`: ユーザーに選択 |
| `unit_branch_enabled` | boolean | `false` | Unit単位でブランチを作成するか |
| `squash_enabled` | boolean | `false` | Unit/Phase完了時に中間コミットをスカッシュするか |
| `ai_author` | string | `""` | 手動指定時のAI著者名（空なら自動検出） |
| `ai_author_auto_detect` | boolean | `true` | AIツールを自動検出してCo-Authored-Byを付与するか |

> **互換用エイリアス**: 旧キー（`rules.branch.mode`, `rules.unit_branch.enabled`, `rules.squash.enabled`, `rules.commit.ai_author`, `rules.commit.ai_author_auto_detect`）も引き続き読み取れます。新規設定では `[rules.git]` を使用してください。

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

### ~~`[rules.worktree]`~~ — 廃止（v2.1.8）

`worktree_enabled` は廃止されました。`rules.git.branch_mode = "worktree"` で代替してください。

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

### `[rules.github]` — GitHub 連携（v2.4.0 で追加）

| キー | 型 | デフォルト | 説明 |
|------|-----|----------|------|
| `milestone_enabled` | boolean | `false` | GitHub Milestone 自動作成 / 紐付け / close 機能を有効にするか。`true` 時は Inception Phase で Milestone 自動作成、Operations Phase で自動 close。`false`（既定）では Milestone 関連ステップが全てスキップされる |

> **後方互換性**: v2.3.6 以前から v2.4.0 にアップグレードする利用者は本キーが未設定のため、Milestone 機能は動作しません。Milestone 運用を有効化したい場合は `.aidlc/config.toml` に `[rules.github]` セクションと `milestone_enabled = true` を追記してください。Milestone OFF の場合でも、Issue/PR 連携（ドラフト PR 作成、PR Ready 化、PR マージ、`Closes #XX` による Issue auto-close）は通常通り動作します。失われるのは Milestone によるサイクル単位の集約可視化のみです。

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

[rules.git]
squash_enabled = true
```

### Milestone 運用を有効化する

```toml
[rules.github]
milestone_enabled = true
```

## 欠落キーの自動検出

バージョンアップで新しいキーが追加された場合、`/aidlc setup` のアップグレードフロー実行時に自動的に検出されます。欠落キーは追記候補として提示され、ユーザーの確認後にconfig.tomlに追記されます。
