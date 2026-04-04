# ドメインモデル: rules.mdの設定項目整理

## 概要

`.aidlc/rules.md` からconfig.tomlに移行可能な設定的項目を特定し、既存の設定体系に統合する。対象は `rules.reviewing.codex_bot_account` の1件のみ。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（Entity）

### ConfigSetting（設定項目）

- **ID**: 設定キーパス（例: `rules.reviewing.codex_bot_account`）
- **属性**:
  - key: string - TOML形式のドット区切りキーパス
  - value: string - 設定値
  - default_value: string - defaults.tomlで定義されるデフォルト値
  - description: string - 設定の説明（config.tomlコメント）
- **振る舞い**: なし（値の解決はインフラ層の責務）

### RulesSection（rules.mdセクション）

- **ID**: セクション番号（1〜15）
- **属性**:
  - name: string - セクション名
  - classification: enum(narrative, template_placeholder) - 分類
  - migration_decision: enum(retain, partial_migrate) - 移行判定
  - embedded_constants: list[EmbeddedConstant] - 埋め込まれた定数値のリスト

## 値オブジェクト（Value Object）

### EmbeddedConstant（埋め込み定数）

- **属性**:
  - value: string - 定数値（例: `chatgpt-codex-connector[bot]`）
  - location: string - rules.md内の記載箇所（行番号）
  - occurrence_type: enum(definition, reference) - 出現種別（定義 or 参照）
  - migration_eligible: boolean - 移行候補か否か
  - eligibility_reason: string - 判断理由
- **不変性**: 棚卸し時点の分析結果であり、変更は再棚卸しが必要
- **等価性**: value + location の組み合わせで判定

### MigrationCriteria（移行判断基準）

- **属性**:
  - is_external_identifier: boolean - 外部システム変更に追従させたい識別子か
  - is_user_overridable: boolean - 利用者が上書きしうる値か
  - is_protocol_string: boolean - 手順と不可分なプロトコル文字列か（除外条件）
- **不変性**: 判断基準はUnit定義で確定済み
- **等価性**: 3属性の組み合わせで判定

## 集約（Aggregate）

### SettingMigration（設定移行）

- **集約ルート**: ConfigSetting
- **含まれる要素**: EmbeddedConstant（移行元）、ConfigSetting（移行先）
- **境界**: 1つの埋め込み定数から1つの設定項目への移行
- **不変条件**:
  - 移行先キーは既存の設定セクション配下に配置（`rules.reviewing.*`）
  - 移行元のrules.mdには定義箇所のみ導線化、参照箇所（コマンド例・判定条件）はリテラル残留

## ドメインサービス

### ConfigMigrationService

- **責務**: rules.mdの埋め込み定数をconfig.toml設定項目に移行する概念的プロセス
- **操作**:
  - analyze(section): セクション内の埋め込み定数を特定し、MigrationCriteriaで評価
  - classifyOccurrences(constant): 定数の全出現箇所を定義/参照に分類
  - migrate(constant, target_key): 定数定義をconfig.toml設定に移行し、rules.mdの定義箇所を導線に更新

## リポジトリインターフェース

### ConfigRepository

- **対象集約**: SettingMigration
- **操作**:
  - load(key) - 設定値を読み取り
  - save(setting) - 設定値を永続化

### RulesRepository

- **対象集約**: RulesSection
- **操作**:
  - load(sectionName) - rules.mdのセクション読み取り
  - save(section) - rules.mdのセクション更新

## ユビキタス言語

- **棚卸し**: rules.mdの全セクションを分類し、移行候補を特定するプロセス
- **ナラティブ**: 手順説明、ガイドライン等の自由記述。config.toml移行対象外
- **設定的項目**: true/false/文字列で表現できる値。移行判断基準で評価
- **導線**: 移行済み項目の代わりにrules.mdに残す、config.toml参照への誘導テキスト
- **プロトコル文字列**: 手順と不可分な定数（`@codex review` 等）。移行対象外
- **定義箇所**: 定数の初出定義（導線化対象）
- **参照箇所**: コマンド例・判定条件内の定数使用（リテラル残留、定義箇所の導線を参照）
