# ドメインモデル: マーケットプレイス対応

## 概要

AI-DLCスキルのマーケットプレイス方式によるカタログ定義と配布の構造を定義する。`.claude-plugin/marketplace.json` のスキーマとスキル管理の2方式（マーケットプレイス／埋め込み）の責務境界を明確化する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### SkillCatalog（スキルカタログ）

- **ID**: `name`（リポジトリ識別名、例: `"ai-dlc-starter-kit"`）
- **属性**:
  - name: string - カタログの識別名
  - owner: Owner - カタログ所有者情報
  - metadata: CatalogMetadata - カタログのメタ情報
  - plugins: PluginGroup[] - プラグイングループの一覧
- **振る舞い**:
  - findSkillBySlug(slug): 指定スラッグに一致するスキルパスを返す
  - listAllSkills(): 全スキルの一覧を返す

### PluginGroup（プラグイングループ）

- **ID**: `name`（グループ名、例: `"aidlc"`, `"tools"`）
- **属性**:
  - name: string - グループの識別名
  - description: string - グループの説明
  - source: string - ソースディレクトリの相対パス
  - strict: boolean - 厳格モード（デフォルト: false）
  - skills: string[] - スキルパスの一覧（相対パス）
- **振る舞い**:
  - containsSkill(slug): グループ内に指定スラッグのスキルが含まれるか判定

## 値オブジェクト（Value Object）

### Owner（所有者）

- **属性**:
  - name: string - 所有者名
  - email: string - 連絡先メール
- **不変性**: カタログの所有者情報は変更頻度が低く、不変として扱う
- **等価性**: name + email の組み合わせで判定

### CatalogMetadata（カタログメタデータ）

- **属性**:
  - description: string - カタログの説明文
  - version: string - カタログバージョン（semver形式）
- **不変性**: 特定バージョンのメタデータは不変
- **等価性**: version で判定

### SkillSlug（スキルスラッグ）

- **属性**:
  - value: string - スキルの識別子（ディレクトリ名と一致）
- **不変性**: スキル名は変更不可（リネーム時は新規スキルとして扱う）
- **等価性**: 正規化後の完全一致（小文字化済みのため大文字小文字の区別なし）
- **制約**: `^[a-z0-9][a-z0-9-]*$` パターンのみ許可
- **正規化**: 生成時に小文字化を必須とする。制約に合致しない値は拒否する

## 集約（Aggregate）

### SkillCatalog集約

- **集約ルート**: SkillCatalog
- **含まれる要素**: Owner, CatalogMetadata, PluginGroup[], SkillSlug
- **境界**: marketplace.json ファイル1つが1つの集約に対応
- **不変条件（論理整合性のみ）**:
  - 全スキルスラッグはカタログ内で一意であること
  - 各スキルパスが有効な相対パス形式であること（ファイルシステム実在確認はインフラ層の責務）
  - metadata.version が semver 形式であること

## ドメインサービス

### SkillCatalogResolver（スキルカタログ解決）

- **責務**: カタログ内のスキルスラッグ解決（ドメインロジックのみ）
- **操作**:
  - resolveSkill(slug) - カタログからスキルパスを解決。スラッグの正規化・一意性検証を行う

**注意**: 実際のインストール処理（ファイルシステム操作）は Claude Code プラットフォーム側の責務であり、ドメイン層には含まない。

### SkillDistributionCoordinator（スキル配布調整）

- **責務**: マーケットプレイス方式と埋め込み方式の共存管理
- **操作**:
  - determineSource(slug) - 指定スキルの配布元を決定

**2方式の優先規則**: マーケットプレイス方式と埋め込み方式は独立したフローであり、通常は競合しない。両方式が同一スキルを提供した場合、埋め込み方式（setup-ai-tools.sh のシンボリックリンク）が `.claude/skills/` を上書きするため、結果的に埋め込み方式が優先される。詳細は論理設計を参照。

## ユビキタス言語

- **マーケットプレイス方式**: `/plugin marketplace add` + `/plugin install` による選択的スキルインストール
- **埋め込み方式**: sync-package.sh → setup-ai-tools.sh によるスターターキット同梱スキルの一括配布
- **スキルスラッグ**: スキルの一意識別子。ディレクトリ名と一致する小文字英数字・ハイフン文字列（例: `reviewing-code`）
- **カタログ**: marketplace.json に定義されたスキルの一覧情報
- **プラグイングループ**: 関連スキルの論理的グルーピング（例: `aidlc` グループ、`tools` グループ）
