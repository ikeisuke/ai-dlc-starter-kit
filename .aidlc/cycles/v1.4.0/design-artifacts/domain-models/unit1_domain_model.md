# ドメインモデル: サイクルバージョン提案改善

## 概要

既存サイクルから次バージョンを推測し、ユーザーに提案する機能のドメインモデル。プロンプト編集のみのため、軽量版として概念整理を行う。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### SemanticVersion
- **属性**:
  - major: Integer - メジャーバージョン（破壊的変更）
  - minor: Integer - マイナーバージョン（新機能追加）
  - patch: Integer - パッチバージョン（バグ修正）
- **不変性**: バージョン番号は一度決まると変更されない
- **等価性**: major, minor, patch の3値が全て一致する場合に等価
- **文字列表現**: `v{major}.{minor}.{patch}` 形式

### VersionIncrementType
- **属性**: type: Enum (PATCH | MINOR | MAJOR)
- **意味**:
  - PATCH: バグ修正・小さな変更
  - MINOR: 新機能追加（後方互換あり）
  - MAJOR: 破壊的変更

## ドメインサービス

### VersionProposer
- **責務**: 既存バージョン群から次バージョン候補を生成
- **操作**:
  - detectLatestVersion(existingVersions): 既存バージョンから最新を特定
  - proposeNextVersions(latestVersion): 次バージョン候補（PATCH/MINOR/MAJOR）を生成

### VersionParser
- **責務**: バージョン文字列の解析と検証
- **操作**:
  - parse(versionString): 文字列 → SemanticVersion 変換
  - format(version): SemanticVersion → 文字列変換
  - isValid(versionString): 形式の妥当性検証

## ビジネスルール

1. **デフォルト提案**: パッチインクリメントをデフォルト推奨とする
2. **重複禁止**: 既存サイクルと同じバージョンは選択不可
3. **フォールバック**: 既存サイクルがない場合は v1.0.0 を提案
4. **形式制約**: `v{major}.{minor}.{patch}` 形式のみ対応

## ユビキタス言語

- **サイクル（Cycle）**: AI-DLCの開発単位。1つのバージョンに対応
- **セマンティックバージョン**: major.minor.patch 形式のバージョン体系
- **パッチインクリメント**: パッチ番号を+1する操作（例: v1.3.2 → v1.3.3）
- **マイナーインクリメント**: マイナー番号を+1、パッチを0にリセット（例: v1.3.2 → v1.4.0）
- **メジャーインクリメント**: メジャー番号を+1、マイナー・パッチを0にリセット（例: v1.3.2 → v2.0.0）

## 不明点と質問

（なし - 要件は明確）
