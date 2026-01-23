# ドメインモデル: deprecation準備

## 概要

後方互換性のために残されたコードを計画的に整理するため、deprecation（非推奨化）対象を管理する概念モデルを定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### DeprecationItem

非推奨対象を表すエンティティ。

- **ID**: String（識別子: `{feature-name}-{version}`形式）
- **属性（すべて必須）**:
  - name: String - 機能名
  - description: String - 機能の説明と具体的な対象
  - deprecatedVersion: SemVer - 非推奨化されたバージョン
  - removalVersion: SemVer - 削除予定バージョン
  - affectedFiles: List[FilePath] - 影響を受けるファイル一覧（1件以上必須）
  - migrationGuide: String - 移行ガイド（代替手段の説明）
- **振る舞い**:
  - isExpired(currentVersion): Boolean - 削除予定バージョンを超過しているか

## 値オブジェクト（Value Object）

### SemVer

セマンティックバージョニング値。

- **属性**: major: Integer, minor: Integer, patch: Integer
- **不変性**: バージョン番号は変更不可
- **等価性**: major, minor, patch がすべて一致

### FilePath

ファイルパス値。

- **属性**: path: String - ファイルパス
- **不変性**: パスは変更不可
- **等価性**: path が一致

## 集約（Aggregate）

### DeprecationRegistry

deprecation対象の集約。

- **集約ルート**: DeprecationRegistry（シングルトン）
- **含まれる要素**: List[DeprecationItem]
- **境界**: すべてのdeprecation対象の一元管理
- **不変条件**:
  - 同一IDの項目は存在しない
  - removalVersionはdeprecatedVersion以上

## ドキュメントとしての表現

このドメインモデルは `prompts/package/deprecation.md` ファイルとして以下の形式で永続化される：

```markdown
# Deprecation一覧

## [機能名]

- **非推奨バージョン**: vX.Y.Z
- **削除予定バージョン**: vX.Y.Z
- **影響ファイル**: [ファイルパス一覧]
- **移行ガイド**: [代替手段の説明]
```

## ユビキタス言語

- **Deprecation（非推奨化）**: 将来削除予定であることを宣言する状態
- **Removal（削除）**: 実際にコードを削除する行為
- **Migration（移行）**: 非推奨機能から推奨される代替手段への切り替え
- **Backward Compatibility（後方互換性）**: 古い形式を引き続きサポートする状態

## 不明点と質問

現時点で不明点はありません。Issue #80の内容に基づいて設計しました。
