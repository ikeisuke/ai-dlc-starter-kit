# ドメインモデル: ユーザー共通設定

## 概要

`~/.aidlc/config.toml`によるユーザー共通設定機能のドメインモデル。3階層（ホーム < プロジェクト < .local）のマージを実現する。

## エンティティ・値オブジェクト

### ConfigSource（値オブジェクト）

設定ファイルの種類を表す。

| 値 | ファイルパス | 優先度 | 必須 |
|----|-------------|--------|------|
| HOME | `$HOME/.aidlc/config.toml` | 低 | No |
| PROJECT | `docs/aidlc.toml` | 中 | Yes |
| LOCAL | `docs/aidlc.toml.local` | 高 | No |

### ConfigKey（値オブジェクト）

ドット区切りの設定キー。

- 形式: `section.subsection.key`（例: `rules.mcp_review.mode`）
- 制約: 空文字不可

### ConfigValue（値オブジェクト）

取得した設定値。

| 属性 | 型 | 説明 |
|------|----|------|
| exists | boolean | 値が存在するか |
| value | string | 設定値（存在する場合） |
| source | ConfigSource | 値の出所 |

## マージルール

### 優先順位（低→高）

1. HOME (`~/.aidlc/config.toml`)
2. PROJECT (`docs/aidlc.toml`)
3. LOCAL (`docs/aidlc.toml.local`)

### マージ動作

- **キー単位優先**: 後から読み込んだ値が前の値を上書き
- **配列置換**: 配列は完全置換（マージしない）
- **ネスト再帰マージ**: テーブルはキーごとに再帰的にマージ
- **型不一致時**: 後から読み込んだ値が勝つ

## 不変条件

1. PROJECT設定ファイルは必須（不在時はエラー）
2. HOME/LOCAL設定ファイルはオプション（不在時はスキップ）
3. `$HOME`環境変数が未設定の場合、HOME設定はスキップ
4. 最終的な値は常に1つ（マージ後）

## 制約事項

- **Windows非対応**: `$HOME`環境変数とUnixパス形式（`~/.aidlc/`）を前提。Windows環境での動作は保証しない
