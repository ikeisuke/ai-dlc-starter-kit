# ドメインモデル: スキル名前空間分離

## 概要

AI-DLCスキルを名前空間プレフィックスで論理的に分類するカタログレベルの概念モデルを定義する。ディレクトリ構造やスキルファイルの実体は変更せず、カタログ表現のみを拡張する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

**Unit 002との関係**: Unit 002で定義した SkillCatalog 集約（Owner, CatalogMetadata, PluginGroup[]）の構造は維持する。本Unitでは PluginGroup.name を名前空間プレフィックスとして活用し、名前空間マッピングを導出ビューとして追加する。

## 値オブジェクト（Value Object）

### NamespaceMapping（名前空間マッピング）

Unit 002の PluginGroup.name と SkillSlug から導出される拡張ビュー。

- **属性**:
  - namespace: string - 名前空間プレフィックス（= PluginGroup.name、例: `"aidlc"`, `"tools"`）
  - slug: SkillSlug - スキルの一意識別子（ディレクトリ名）
  - displayName: string - カタログ表示名（`namespace:slug` 形式、導出値）
  - callName: string - 実行時呼び出し名（= slug、ディレクトリ名と同一、導出値）
  - status: SkillStatus - スキルの状態
  - marketplaceListed: boolean - marketplace.json に掲載されているか
- **不変性**: 名前空間帰属は変更不可（移動時は削除+再登録）
- **等価性**: slug で判定
- **導出規則**: displayName = `${namespace}:${slug}`, callName = slug

### SkillStatus（スキル状態）

- **列挙値**:
  - `active` - 有効（通常利用可能）
  - `deprecated` - 非推奨（将来削除予定、警告表示推奨）
- **不変性**: 特定バージョンのカタログ内で不変

## 集約（Aggregate）

### SkillCatalog集約（Unit 002で定義済み、拡張なし）

- **集約ルート**: SkillCatalog
- **含まれる要素**: Unit 002の定義を維持（Owner, CatalogMetadata, PluginGroup[], SkillSlug）
- **名前空間に関する追加不変条件**:
  - PluginGroup.name が名前空間プレフィックスとして機能する
  - 同一 PluginGroup 内でスキルスラッグの重複は禁止（Unit 002の制約を継承）
  - 異なる PluginGroup 間でも同一スキルスラッグは禁止（ディレクトリ名のグローバル一意性）

## ドメインサービス

### NamespaceConflictChecker（名前空間衝突検証）

- **責務**: カタログ登録時のスキル名衝突を検証する
- **操作**:
  - checkDuplicate(catalog, newSkill) - 既存カタログ内で slug の重複がないか検証
  - checkCrossNamespace(catalog, newSkill) - 異なる PluginGroup 間での slug 重複がないか検証

### DisplayNameFormatter（カタログ表示名フォーマッタ）

- **責務**: カタログ表示名（`namespace:slug`）の構文検証と生成
- **操作**:
  - format(namespace, slug) - `namespace:slug` 形式の表示名を生成
  - validate(displayName) - 表示名の構文を検証（`{namespace}:{slug}` パターンに準拠するか）
  - parse(displayName) - 表示名から namespace と slug を分離

**注意**: 呼び出し名（callName）の解決は外部プラットフォーム（Claude Code等のAIツール）の責務であり、ドメインサービスには含まない。ドメイン側は表示名の構文ポリシーのみを担当する。

## ユビキタス言語

- **名前空間**: スキルを論理的に分類するプレフィックス。PluginGroup.name と一致する。実行時の動作には影響しない
- **カタログ表示名**: `namespace:slug` 形式の名前（例: `aidlc:reviewing-code`）。ドキュメント・カタログ上の表記用
- **呼び出し名**: ディレクトリ名と同一のスキル識別子（例: `reviewing-code`）。実行時に使用する名前。外部プラットフォームが解決を担当
- **active**: 通常利用可能なスキル状態
- **deprecated**: 非推奨で将来削除予定のスキル状態
- **marketplaceListed**: marketplace.json に掲載されているかどうか。deprecated スキルは非掲載とする
