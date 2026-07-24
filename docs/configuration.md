# 設定ファイルリファレンス

AI-DLC Starter Kit（v3）の設定ファイルの構造、マージ優先順位、サポートキーの説明です。

> **schema の正本**: v3 の `config.toml` 終端キー集合（キー名 / 型 / 既定値）の唯一の正本は
> [docs/v3/data-model.md](v3/data-model.md) §11 です。本ドキュメントはその参照用リファレンスです。

## 設定ファイルの種類

| ファイル | パス | 配置元 | Git管理 | 用途 |
|---------|------|--------|---------|------|
| デフォルト設定 | `config/defaults.toml`（スキルディレクトリ内） | スキルプラグインに同梱。ユーザーが直接編集する必要はない | - | デフォルト値を定義（フォールバック） |
| ユーザー共通設定 | `~/.aidlc/config.toml` | ユーザーが手動作成 | No | ユーザー固有の共通設定（複数プロジェクト共通） |
| プロジェクト設定 | `.aidlc/config.toml` | 手動作成（README のインストール手順参照）または `/aidlc-migrate` が生成 | Yes | プロジェクト固有の設定 |
| ローカル設定 | `.aidlc/config.local.toml` | ユーザーが手動作成 | No | 個人設定（プロジェクト設定を上書き） |

> **Note**: デフォルト設定（`defaults.toml`）はスキルプラグイン内に同梱されており、プロジェクトディレクトリには配置されません。`read-config.sh` が内部的にフォールバック値として参照するため、ユーザーが意識する必要はありません。

## マージ優先順位

設定値は以下の順で解決されます（後のものが優先）:

1. `defaults.toml` — 最低優先（フォールバック値）
2. `~/.aidlc/config.toml` — ユーザー共通設定
3. `.aidlc/config.toml` — プロジェクト設定（**必須**）
4. `.aidlc/config.local.toml` — ローカル設定（最高優先）

キー単位でマージされます。上位の設定で値が定義されていれば、下位の値を上書きします。

## サポートキー（v3 終端 8 キー）

v3 がフェーズフローで参照する挙動制御キーは以下の 8 つです。すべてデフォルト値を持つため、`.aidlc/config.toml` にはデフォルトから変えたいキーのみを記述します。

| # | キー | 型 | デフォルト | 説明 |
|---|------|----|-----------|------|
| 1 | `rules.depth_level.level` | string | `"standard"` | サイクルの厳格度（`minimal` / `standard` / `comprehensive`）。work item の size との組合せで design / review の要否を決める（[data-model.md](v3/data-model.md) §8） |
| 2 | `rules.automation.mode` | string | `"manual"` | 承認ゲートの自動化（`manual`: 全承認ポイントでユーザー確認 / `semi_auto`: フォールバック条件非該当時に自動承認） |
| 3 | `rules.reviewing.mode` | string | `"recommend"` | レビュー処理パスの選択（`required` / `recommend` / `disabled`） |
| 4 | `rules.reviewing.tools` | array | `["codex"]` | レビューツールの優先順位リスト（フォールバック順序）。外部 CLI 名 / `"self"`（セルフレビュー） |
| 5 | `rules.reviewing.exclude_patterns` | array | `[]` | レビュー時の機密情報除外パターン（デフォルトの除外パターンに追加） |
| 6 | `rules.release.changelog` | bool | `false` | release での CHANGELOG 追記 opt-in |
| 7 | `rules.release.version_tag` | bool | `false` | release での version tag 作成 opt-in |
| 8 | `rules.release.required_ci_zero_fallback` | bool | `false` | required CI チェックが 0 件のときに release hard gate のフォールバック経路を解放する opt-in（発動時は別途ユーザー承認 + 記録が必須）。本キーは同梱 `defaults.toml` に未収載だが、キー不在時は release フローが安全側の `false` として扱う |

## 設定例

### 厳格度を上げる（すべての work item に design / review を要求しやすくする）

```toml
[rules.depth_level]
level = "comprehensive"
```

### 承認ゲートを半自動化する

```toml
[rules.automation]
mode = "semi_auto"
```

### レビューを必須化し、ツールの優先順位を指定する

```toml
[rules.reviewing]
mode = "required"
tools = ["codex", "self"]
```

### release で CHANGELOG 追記と tag 作成を有効化する

```toml
[rules.release]
changelog = true
version_tag = true
```

## 未知キーの扱い

v3 は上記 8 キー以外のキーを**無視します**（エラーにしません）。

- **v2 からの移行**: v2 の設定キー（`rules.git` / `rules.cycle` / `rules.construction` / `rules.github` 等）は v3 では参照されません。`/aidlc-migrate` 実行時に未サポートキーは警告として通知されます（[docs/v3/migration.md](v3/migration.md) §3.1）
- **`starter_kit_version`**（トップレベル）: v2 の config に存在し得る旧情報フィールドです。v3 では無視され、`/aidlc-migrate` の config 生成でも引き継がれません
- **共存期間の v2 共有資産キー**: v3 が一時的に委譲する共有レビュー資産が参照する v2 固有キー（例: `rules.reviewing.codex_bot_account`）は終端 schema に含まれず、不在時は各資産のデフォルト値へフォールバックします

## 欠落キーの扱い

バージョンアップで新しいキーが追加された場合も、原則としてスキル同梱の `defaults.toml` がフォールバック値を提供するため、既存の `config.toml` のままで動作します。`defaults.toml` に未収載のキーはキー不在時に各フローが安全側の既定値を適用します（例外は各キーの説明を参照）。デフォルト以外の値を使いたいキーのみ、本リファレンスを参照して手動で追記してください。
