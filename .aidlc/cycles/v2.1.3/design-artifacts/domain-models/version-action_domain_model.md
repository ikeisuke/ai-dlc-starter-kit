# ドメインモデル: /aidlc version アクションの追加

## 概要

`/aidlc version` アクションの概念構造を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### VersionInfo

- **属性**: version: string（セマンティックバージョニング形式）
- **取得元**: スキルベースディレクトリの `version.txt`
- **不変性**: 読み取り専用（スキルリリース時にのみ更新）

## ユビキタス言語

- **スキルバージョン**: `skills/aidlc/version.txt` に記録されたスキル自体のバージョン
- **starter_kit_version**: `.aidlc/config.toml` に記録されたプロジェクト導入済みバージョン（本アクションでは使用しない）
