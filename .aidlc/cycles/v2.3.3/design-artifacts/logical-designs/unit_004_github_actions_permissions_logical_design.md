# 論理設計: GitHub Actions permissions追加

## 概要
2つのGitHub Actionsワークフローファイルにworkflow-levelのpermissionsブロックを追加する構造変更の詳細設計。

**重要**: この論理設計では**コードは書かず**、コンポーネント構成とインターフェース定義のみを行います。

## アーキテクチャパターン
既存パターンの適用拡大。`skill-reference-check.yml` で確立済みのpermissions定義パターンを `pr-check.yml` と `migration-tests.yml` に横展開する。

## コンポーネント構成

### 変更対象ファイル

```text
.github/workflows/
├── pr-check.yml               ★ permissions追加
├── migration-tests.yml        ★ permissions追加
├── skill-reference-check.yml  （参考モデル、変更なし）
└── auto-tag.yml               （変更なし）
```

### コンポーネント詳細

#### pr-check.yml（変更）
- **現状**: `on:` の後に `permissions:` ブロックなし
- **変更**: `on:` ブロックと `jobs:` ブロックの間に追加
- **追加内容**:
  ```yaml
  permissions:
    contents: read
  ```
- **根拠**: 3ジョブ全て読み取りのみ（checkout + lint/check系）

#### migration-tests.yml（変更）
- **現状**: `on:` の後に `permissions:` ブロックなし
- **変更**: `on:` ブロックと `jobs:` ブロックの間に追加
- **追加内容**: pr-check.ymlと同一（`contents: read`）
- **根拠**: migration-testsジョブは読み取りのみ（checkout + script実行）

## 処理フロー概要

### 変更の差分イメージ

```yaml
# Before (pr-check.yml / migration-tests.yml)
name: ...
on: ...

jobs:
  ...

# After
name: ...
on: ...

permissions:
  contents: read

jobs:
  ...
```

## 実装上の注意事項
- `permissions:` ブロックはYAMLのトップレベルに配置（`on:` と `jobs:` の間）
- インデントはスペース2つ（既存ファイルのインデント規約に合わせる）
- 空行で前後のブロックと視覚的に分離する
