# ドメインモデル: PRマージ方法設定化

## 概要

PRマージ方法をconfig.tomlで事前設定可能にし、Operations Phaseでの手動選択を省略可能にする。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### MergeMethod

PRマージ方法を表す列挙型。

- **有効値**: `"merge"` | `"squash"` | `"rebase"` | `"ask"`
- **デフォルト**: `"ask"`（従来動作維持）
- **不変条件**: 無効値は `"ask"` にフォールバックし警告を出力する

## ドメインサービス

### MergeMethodResolver

マージ実行時にMergeMethodの値に基づいて動作を決定する。

- **責務**: merge_methodの値に応じたマージ実行方法の決定
- **操作**:
  - resolve(merge_method) → 自動実行 or ユーザー選択
  - fallback_on_error() → マージ失敗時にユーザーに方法選択を求める

## 影響範囲

| レイヤー | 責務 |
|---------|------|
| config/defaults.toml | MergeMethodのデフォルト値定義 |
| preflight.md | MergeMethodの読み込みとバリデーション |
| operations-release.md | MergeMethodResolverによるマージ実行分岐 |
