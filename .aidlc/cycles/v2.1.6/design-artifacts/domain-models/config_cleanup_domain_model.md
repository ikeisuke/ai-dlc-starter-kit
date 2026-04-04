# ドメインモデル: 設定キー整理

## 概要

AI-DLCの設定管理ドメインにおいて、不要・重複・スコープ違いの設定キーを整理し、設定構造を簡素化する。本Unitは設定ファイル（TOML）とプロンプトファイル（Markdown）の修正が中心であり、アプリケーションコードのエンティティ/集約モデルではなく、設定ドメインの構造と責務を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## エンティティ（設定ドメインの構成要素）

### ConfigKey（設定キー）

- **ID**: TOML形式のドットノーテーション（例: `rules.preflight.enabled`）
- **属性**:
  - `key_path`: String - TOMLキーパス（例: `rules.preflight.enabled`）
  - `value_type`: String - 値の型（boolean / string / integer / array）
  - `default_value`: Any - デフォルト値（defaults.tomlで定義）
  - `scope`: Enum - 配置スコープ（`universal` / `project_specific`）
  - `lifecycle`: Enum - ライフサイクル状態（`active` / `deprecated` / `deleted`）
- **振る舞い**:
  - `resolve()`: マージ順 defaults.toml → config.toml → config.local.toml で値を重ね合わせ、最終優先順位 local > config > defaults（後勝ち）で解決
  - `is_present()`: キーが定義されているか判定（read-config.sh exit code 0/1）

### ConfigSection（設定セクション）

- **ID**: TOMLセクションヘッダ（例: `[rules.preflight]`）
- **属性**:
  - `section_path`: String - セクションパス
  - `keys`: ConfigKey[] - セクション内のキー一覧
  - `lifecycle`: Enum - セクションのライフサイクル状態

## 値オブジェクト

### CompatibilityPolicy（互換ポリシー）

- **属性**:
  - `classification`: Enum - `deleted`（削除・無視） / `renamed`（改名・フォールバック） / `doc_only`（文書更新のみ）
  - `old_key`: String - 旧キーパス
  - `new_key`: String? - 新キーパス（deletedの場合はnull）
  - `fallback_required`: Boolean - 旧キーからのフォールバック読み取りが必要か
- **不変性**: 互換ポリシーはUnit定義時に決定され、実装中に変更しない
- **等価性**: `old_key` で一意

### ConfigScope（配置スコープ）

- **属性**:
  - `scope_type`: Enum - `universal`（全ユーザー共通、defaults.tomlに定義） / `project_specific`（プロジェクト固有、config.tomlに直接記載）
- **不変性**: 各キーのスコープはUnit定義で決定済み

## 集約

### ConfigSchema（設定スキーマ）

- **集約ルート**: defaults.toml（デフォルト値の正本）
- **含まれる要素**: ConfigSection[], ConfigKey[]
- **境界**: defaults.tomlが定義する設定スキーマの範囲。project_specificなキーはスキーマ外
- **不変条件**:
  - defaults.tomlに定義されたキーは全ユーザーに適用される
  - キー不在時はread-config.shがexit 1を返す（無効扱いの契約）

### PreflightExecutionPolicy（プリフライト実行ポリシー）

- **責務**: preflight.mdにおけるチェック実行の構成ルール
- **整理後のポリシー**: 環境チェック（blocker）とオプションチェック（gh/review-tools/config-validation）を常時固定実行。設定による分岐は廃止

## ドメインサービス

### ConfigMigrationService（設定マイグレーション）

- **責務**: setupスキルのmigrate-config.shが担う。アップグレード時に新セクションを追加
- **操作**: 削除対象のpreflight追加ロジックを除去

### ConfigReader（設定読み取り）

- **責務**: read-config.shが担う。設定値の解決とフォールバック
- **操作**:
  - `read(key)`: マージ順 defaults.toml → config.toml → config.local.toml（後勝ち、最終優先順位 local > config > defaults）
  - キー不在時: exit 1（無効扱い）
  - エラー時: exit 2

## ユビキタス言語

- **defaults.toml**: 全ユーザー共通のデフォルト値を定義するファイル。設定スキーマの正本
- **config.toml**: プロジェクト固有の設定上書きファイル
- **キー不在**: defaults.tomlにキーが存在しない状態。read-config.shはexit 1を返す
- **削除**: キーをdefaults.tomlから除去し、旧config.tomlに残っていても無視する互換ポリシー
- **スコープ変更**: キーの配置場所をuniversal（defaults.toml）からproject_specific（config.toml直接）に変更すること
- **detect-missing-keys.sh**: defaults.tomlをスキーマとしてconfig.tomlの欠落キーを検出するスクリプト。defaults.tomlからキーを削除すると、そのキーは検出対象外になる

## 不明点と質問（設計中に記録）

なし（Unit定義とIntent要件から構造が明確）
