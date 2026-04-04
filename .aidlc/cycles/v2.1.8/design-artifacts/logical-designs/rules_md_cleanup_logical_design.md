# 論理設計: rules.mdの設定項目整理

## 概要

`.aidlc/rules.md` の埋め込み定数（Codexボットアカウント名）を `rules.reviewing.codex_bot_account` として既存の設定体系に統合する。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン

既存の設定読み取りパターン（defaults.toml → config.toml → config.local.toml のレイヤードマージ）を踏襲。新規パターンの導入なし。

## コンポーネント構成

### 変更対象ファイル構成

```text
skills/aidlc/config/
└── defaults.toml                    # [変更] codex_bot_account追加（正本）
skills/aidlc-setup/config/
└── defaults.toml                    # [変更] codex_bot_account追加（配布コピー、正本と同期）
.aidlc/
├── config.toml                      # [変更] codex_bot_account追加
└── rules.md                         # [変更] 定義箇所をconfig.toml参照導線に置き換え
```

### コンポーネント詳細

#### defaults.toml（正本: `skills/aidlc/config/defaults.toml`）

- **責務**: 全設定キーのデフォルト値を定義
- **変更内容**: `[rules.reviewing]` セクションに `codex_bot_account = "chatgpt-codex-connector[bot]"` を追加
- **公開インターフェース**: `read-config.sh` によるキー読み取り

#### defaults.toml（配布コピー: `skills/aidlc-setup/config/defaults.toml`）

- **責務**: セットアップ時に使用するデフォルト値の配布用コピー
- **変更内容**: 正本（`skills/aidlc/config/defaults.toml`）と同一の `codex_bot_account` を追加
- **依存**: 正本defaults.tomlとの同期

#### config.toml（`.aidlc/config.toml`）

- **責務**: プロジェクト固有の設定値を保持
- **変更内容**: `[rules.reviewing]` セクションに `codex_bot_account` を追加（コメント付き）
- **依存**: defaults.toml（デフォルト値のフォールバック元）

#### rules.md（`.aidlc/rules.md`）

- **責務**: プロジェクト固有のガイドラインと手順を保持
- **変更内容**: Codex PRレビューセクション内の定数定義箇所（L261）をconfig.toml参照の導線に置き換え。コマンド例・判定条件内の参照箇所（L324, L332, L347, L363）はリテラルのまま残留

### rules.md内の `chatgpt-codex-connector[bot]` 出現箇所の分類

| 行 | 出現種別 | コンテキスト | 対応 |
|----|---------|-------------|------|
| L261 | 定義 | `**Codexボットアカウント**: \`chatgpt-codex-connector[bot]\`` | **導線化**: config.toml参照に置き換え |
| L324 | 参照 | `user.login == \`chatgpt-codex-connector[bot]\``（フィルタ条件説明） | **残留**: 手順内の判定条件として不可分 |
| L332 | 参照 | `--jq` 内の `select(.user.login == "...")` | **残留**: コマンド例として不可分 |
| L347 | 参照 | `--jq` 内の `select(.user.login == "...")` | **残留**: コマンド例として不可分 |
| L363 | 参照 | `user.login == \`chatgpt-codex-connector[bot]\``（フィルタ条件説明） | **残留**: 手順内の判定条件として不可分 |

**方針**: L261の定義箇所のみ導線化する。参照箇所（L324, L332, L347, L363）はコマンド例・判定条件として手順と不可分であり、リテラル値をそのまま残す。実行時にAIエージェントがconfig.tomlから読み取った値を使用する（rules.mdの手順説明はデフォルト値の例示として機能する）。

## インターフェース設計

### read-config.sh（既存、変更なし）

既存の `read-config.sh` で新キーを読み取れることを確認するのみ。スクリプト自体の変更は不要（dasel経由のTOMLキー読み取りは汎用的に動作するため）。

```bash
# 使用方法（既存インターフェースのまま）
scripts/read-config.sh rules.reviewing.codex_bot_account
# 期待出力: chatgpt-codex-connector[bot]
# 終了コード: 0
```

## ファイル形式

### defaults.toml追加エントリ（正本: `skills/aidlc/config/defaults.toml`）

```toml
[rules.reviewing]
# 既存のmode, tools, exclude_patternsに加えて:
codex_bot_account = "chatgpt-codex-connector[bot]"
```

### config.toml追加エントリ

```toml
[rules.reviewing]
# 既存の設定に加えて:
# codex_bot_account: Codex GitHub AppのBotアカウント名
# - Codex PRレビュー状態判定で使用
# - デフォルト: "chatgpt-codex-connector[bot]"
codex_bot_account = "chatgpt-codex-connector[bot]"
```

### rules.md変更箇所（L261のみ）

変更前:
```markdown
**Codexボットアカウント**: `chatgpt-codex-connector[bot]`（変更可能な定数。Codex GitHub AppのBot名が変更された場合はこの値を更新する）
```

変更後:
```markdown
**Codexボットアカウント**: `.aidlc/config.toml` の `rules.reviewing.codex_bot_account` で設定（デフォルト: `chatgpt-codex-connector[bot]`）。Codex GitHub AppのBot名が変更された場合はconfig.tomlの値を更新する。
```

## 処理フロー概要

### 設定移行の処理フロー

1. `skills/aidlc/config/defaults.toml`（正本）に `codex_bot_account` を追加
2. `skills/aidlc-setup/config/defaults.toml`（配布コピー）に同一エントリを追加（正本との同期）
3. `.aidlc/config.toml` の `[rules.reviewing]` に `codex_bot_account` を追加
4. `.aidlc/rules.md` L261のCodexボットアカウント定義箇所を導線に置き換え
5. `read-config.sh` で読み取り確認

**関与するコンポーネント**: defaults.toml（正本/配布）、config.toml、rules.md、read-config.sh

## 非機能要件（NFR）への対応

該当なし（Unit定義のNFRがすべて「該当なし」のため）

## 技術選定

- **言語**: TOML（設定ファイル）、Markdown（ドキュメント）
- **ツール**: dasel（TOML読み取り、既存）

## 実装上の注意事項

- defaults.toml正本（`skills/aidlc/config/defaults.toml`）とaidlc-setup配布コピーの同期を忘れないこと
- config.tomlへの追加はコメント付きで、既存の `[rules.reviewing]` セクション末尾に配置
- ステップファイル内にCodexボットアカウント名の参照は0件（検索済み）。ステップファイルの更新は不要
- rules.md内の参照箇所（L324, L332, L347, L363）はリテラル残留。定義箇所（L261）のみ導線化
