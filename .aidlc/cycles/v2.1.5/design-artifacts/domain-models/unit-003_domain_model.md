# ドメインモデル: config.toml欠落キー検出・追記候補提示

## 概要
defaults.tomlをスキーマとしてconfig.tomlの欠落キーを検出するスクリプトと、aidlc-setupフローへの統合。

## コンポーネント

### detect-missing-keys.sh（新規スクリプト）
- **責務**: defaults.tomlの全リーフキーを列挙し、config.tomlに存在しないキーを検出・出力
- **入力**: defaults.tomlパス、config.tomlパス（引数）
- **出力**: 欠落キーと対応デフォルト値をkey:value形式で標準出力
- **依存**: dasel、bootstrap.sh

### 02-generate-config.md（プロンプト修正）
- **責務**: アップグレードフローに欠落キー検出ステップを追加
- **統合ポイント**: ステップ7.4（設定マイグレーション）の後、7.5（旧形式バックログ移行）の前

## データフロー

```
defaults.toml --[dasel keys]--> 全リーフキーリスト
config.toml --[dasel get]--> 各キーの存在確認
↓
欠落キーリスト（key:default_value形式）
↓
[02-generate-config.md内のプロンプト指示]
↓
AIエージェントが欠落キーをユーザーに提示 → 確認 → daselで追記
```
