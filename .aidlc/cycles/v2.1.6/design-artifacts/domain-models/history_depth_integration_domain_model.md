# ドメインモデル: history.levelとdepth_level統合

## 概要

history.levelをdepth_level配下に統合し、depth_levelからの自動導出と明示的オーバーライドの両方をサポートする。`history_level`はpreflight.mdでのみ解決される派生コンテキスト変数。

## エンティティ

### HistoryLevelConfig

- **新キー**: `rules.depth_level.history_level`（defaults.toml: 空文字=自動導出）
- **旧キー**: `rules.history.level`（defaults.tomlから削除。ユーザーconfig.tomlに残っている場合のみフォールバック）
- **解決責務**: preflight.md（派生コンテキスト変数として解決）
- **解決優先順位**: 新キー明示値 > 旧キー値（config.toml明示のみ） > depth_levelからの自動導出

## 値オブジェクト

### DepthToHistoryMapping（自動導出マッピング）

| depth_level | history_level |
|-------------|--------------|
| minimal | minimal |
| standard | standard |
| comprehensive | detailed |

## 解決フロー

1. `rules.depth_level.history_level`を取得
2. 空文字でない → その値を使用（明示オーバーライド）
3. 空文字 → `rules.history.level`を取得（旧キーフォールバック、config.toml明示のみ）
4. 旧キーも不在（exit 1） → depth_levelから自動導出
