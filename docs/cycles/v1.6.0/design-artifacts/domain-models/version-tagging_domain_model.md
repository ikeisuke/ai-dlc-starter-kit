# ドメインモデル: バージョンタグ運用

## 概要
AI-DLCサイクル完了時のバージョンタグ付けとCHANGELOG更新のワークフローを定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## エンティティ（Entity）

### VersionTag
- **ID**: タグ名（例: v1.6.0）
- **属性**:
  - name: String - タグ名（セマンティックバージョニング形式: vX.Y.Z）
  - commitHash: String - タグを付与するコミットのハッシュ
  - message: String - タグの注釈メッセージ
  - createdAt: DateTime - タグ作成日時
- **振る舞い**:
  - create: 新規タグを作成（`git tag -a`）
  - push: リモートにタグをプッシュ（`git push origin --tags`）

### Changelog
- **ID**: ファイルパス（CHANGELOG.md）
- **属性**:
  - versions: List[VersionEntry] - バージョンごとの変更履歴
- **振る舞い**:
  - addVersion: 新しいバージョンエントリを追加
  - update: 既存エントリを更新

## 値オブジェクト（Value Object）

### VersionEntry
- **属性**:
  - version: String - バージョン番号
  - releaseDate: Date - リリース日
  - changes: ChangeSet - 変更内容
- **不変性**: 各リリースの記録は変更されるべきでない
- **等価性**: バージョン番号で判定

### ChangeSet
- **属性**:
  - added: List[String] - 追加された機能
  - changed: List[String] - 変更された機能
  - fixed: List[String] - 修正されたバグ
  - removed: List[String] - 削除された機能
  - deprecated: List[String] - 非推奨になった機能
  - security: List[String] - セキュリティ関連の変更
- **不変性**: Keep a Changelog形式を維持
- **等価性**: 全属性の比較で判定

### SemanticVersion
- **属性**:
  - major: Integer - メジャーバージョン
  - minor: Integer - マイナーバージョン
  - patch: Integer - パッチバージョン
- **不変性**: バージョン番号は不変
- **等価性**: major.minor.patch の完全一致

## 集約（Aggregate）

### ReleaseAggregate
- **集約ルート**: VersionTag
- **含まれる要素**: VersionEntry, ChangeSet
- **境界**: 1つのリリースに関連するすべての情報
- **不変条件**:
  - タグ名はセマンティックバージョニング形式であること
  - CHANGELOGにタグと同じバージョンのエントリが存在すること

## ドメインサービス

### ReleaseService
- **責務**: リリースプロセス全体の調整
- **操作**:
  - prepareRelease: CHANGELOG更新、コミット作成
  - createTag: バージョンタグの作成
  - publishRelease: タグのリモートへのプッシュ

## ユビキタス言語

このドメインで使用する共通用語：

- **サイクル（Cycle）**: AI-DLCの1開発サイクル（Inception→Construction→Operations）
- **バージョンタグ**: gitリポジトリに付与するリリースマーカー
- **CHANGELOG**: バージョン間の変更履歴を記録するファイル
- **セマンティックバージョニング**: vMAJOR.MINOR.PATCH形式のバージョン管理
- **Keep a Changelog**: CHANGELOG.mdの標準形式

## 不明点と質問（設計中に記録）

現時点で不明点はありません。

---

## 設計判断

### 過去タグの状況確認

既存タグ: v0.1.0, v1.0.0 〜 v1.5.4（全バージョンにタグ付与済み）

**結論**: 過去バージョンへのタグ付けは既に完了しているため、Unit 005の「ストーリー7: バージョンタグ付け（過去分）」は実施不要。Operations Phaseへの手順追加（ストーリー8）のみを実施する。

### 手順追加箇所

1. **CHANGELOG更新**: ステップ6「リリース準備」に追加（6.0として最初に実行）
2. **バージョンタグ付け**: 「5. PRマージ後の手順」に追加
