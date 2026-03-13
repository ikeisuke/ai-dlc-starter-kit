# ドメインモデル: jjスキル移行準備

## 概要

jjスキルの外部化に伴う移行ガイド・検出ロジック・Issue管理のドメイン概念を定義する。新たなエンティティや集約は導入せず、既存の設定マイグレーションドメインに廃止設定検出の概念を追加する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

本Unitでは新規エンティティの導入はなし。

## 値オブジェクト（Value Object）

### DeprecatedConfigEntry

- **属性**:
  - sectionKey: String - 廃止されたTOMLセクションキー（例: `rules.jj`）
  - deprecatedSince: String - 廃止バージョン（例: `v1.21.0`）
  - migrationGuideRef: String - 移行ガイドのユーザー向けパス
- **不変性**: 廃止設定の定義は変更されない（バージョン間で固定）
- **等価性**: sectionKey が同一であれば同一の廃止設定を指す（キー単位で最新定義を上書きする意図。同一キーで複数バージョンの廃止履歴は管理しない）

## 集約（Aggregate）

本Unitでは新規集約の導入はなし。既存のConfigMigration処理にDeprecatedConfigEntryの検出を追加する。

## ドメインサービス

### DeprecatedConfigDetector

- **責務**: ユーザーの `aidlc.toml` に廃止されたセクションが残存していないかを検出し、検出結果（DeprecatedConfigEntry）を返却する
- **操作**:
  - detect(configPath) → DeprecatedConfigEntry | null - 対象の設定ファイルを走査し、廃止セクションの存在を判定。検出結果を返却する
- **I/O責務の分離**: 検出結果の出力整形（`warn:deprecated-config:{key}` 等のメッセージフォーマット）はスクリプト層（migrate-config.sh）が担う。本サービスは検出ロジックのみ

## リポジトリインターフェース

本Unitでは不要（永続化対象なしのため専用リポジトリ不要。検出対象ファイルへのアクセスはインフラ層で処理）。

## ユビキタス言語

- **廃止設定（Deprecated Config）**: スターターキットから削除されたが、ユーザーの `aidlc.toml` に残存している可能性がある設定セクション
- **移行ガイド（Migration Guide）**: 廃止設定の移行手順を記載したドキュメント
- **SoT（Source of Truth）**: `prompts/package/` 配下の正本ファイル。`docs/aidlc/` はrsync同期によるミラー
- **skillsリポジトリ**: jjスキルの公開先となる独立リポジトリ（未作成、Issue管理対象）

## 不明点と質問（設計中に記録）

なし（Unit定義と計画から十分な情報が得られている）
