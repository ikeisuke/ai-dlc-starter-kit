# ドメインモデル: 確認系処理のスクリプト化

## 概要

setup-prompt.md 内の確認系処理（バージョン比較、セットアップ種類判定）をスクリプト化し、プロンプトを簡素化する。シェルスクリプトによる処理自動化のドメインを定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## 値オブジェクト（Value Object）

### Version

- **属性**: value: String - セマンティックバージョン（例: "1.9.0"）
- **不変性**: 一度取得したバージョン値は変更されない
- **等価性**: セマンティックバージョンとして比較（major.minor.patch の各数値を比較）
- **正規化**: 比較前に正規化を行う（例: `1.9` → `1.9.0`）
- **取得元**:
  - プロジェクト: `docs/aidlc.toml` の `starter_kit_version`
  - スターターキット: `version.txt`（リポジトリルート直下）
    - スクリプトからのパス: `$SCRIPT_DIR/../../../version.txt`

### VersionStatus

バージョン比較結果を表す値オブジェクト。

- **属性**: status: Enum, project_version: String?, kit_version: String?
- **状態値**:
  | 値 | 意味 |
  |----|------|
  | `current` | 同じバージョン |
  | `upgrade_available` | アップグレード可能（プロジェクト < スターターキット） |
  | `project_newer` | プロジェクトが新しい（プロジェクト > スターターキット） |
  | `not_found` | バージョン情報が取得できない |
  | `unknown` | dasel未インストールで判定不可（AIに委ねる） |
- **出力形式の補足**: `unknown` はスクリプト出力で `version_status:` （空値）として表現される

### SetupType

セットアップ種類を表す値オブジェクト。

- **属性**:
  - type: Enum - セットアップ種類
  - project_version: String? - プロジェクトのバージョン（upgrade/warning_newer時のみ）
  - kit_version: String? - スターターキットのバージョン（upgrade/warning_newer時のみ）
- **種類値**:
  | 値 | 条件 | 意味 |
  |----|------|------|
  | `initial` | 設定ファイルなし | 初回セットアップ |
  | `cycle_start` | aidlc.toml存在 & バージョン同じ | サイクル開始 |
  | `upgrade` | aidlc.toml存在 & プロジェクト < キット | アップグレード可能 |
  | `warning_newer` | aidlc.toml存在 & プロジェクト > キット | 警告（プロジェクトが新しい） |
  | `migration` | project.toml存在（旧形式） | 移行が必要 |
  | `unknown` | dasel未インストール | 判定不可（AIに委ねる）

### ConfigFileState

設定ファイルの存在状態を表す値オブジェクト。

- **属性**: state: Enum
- **状態値**:
  | 値 | 意味 |
  |----|------|
  | `aidlc_toml_exists` | 新形式（`docs/aidlc.toml`）が存在 |
  | `project_toml_exists` | 旧形式（`docs/aidlc/project.toml`）が存在 |
  | `not_exists` | 設定ファイルなし |
- **優先順位**: `docs/aidlc.toml` が存在すれば `docs/aidlc/project.toml` の存在は無視する（新形式優先）

## ドメインサービス

### VersionComparator

- **責務**: 2つのバージョン文字列を比較し、VersionStatus を返す
- **操作**:
  - compare(project_version, kit_version) → VersionStatus
- **入力前提**:
  - 空文字または未設定のバージョンは `not_found` として扱う
  - どちらか一方でも空文字の場合、比較を行わず `not_found` を返す
- **比較ロジック**: セマンティックバージョニングに基づく大小比較

### SetupTypeResolver

- **責務**: 設定ファイル状態とバージョン情報から SetupType を判定
- **前提**: daselの有無は上位（スクリプト）で判定し、未インストール時は `unknown` を返す
- **操作**:
  - resolve(config_state, version_status) → SetupType
- **判定ロジック**:
  1. dasel未インストール → `unknown`（AIに委ねる）
  2. 設定ファイルなし → `initial`
  3. 旧形式のみ存在（project.toml）→ `migration`
  4. 新形式 & バージョン情報取得不可（`not_found`）→ `initial`（初回扱い）
  5. 新形式 & バージョン同じ → `cycle_start`
  6. 新形式 & プロジェクト < キット → `upgrade`（project_version, kit_version を保持）
  7. 新形式 & プロジェクト > キット → `warning_newer`（project_version, kit_version を保持）

## 出力形式

既存スクリプトと同様の `key:value` 形式を使用:

### check-version.sh 出力

```text
version_status:{状態}
```

- `version_status:current` - バージョンが同じ（VersionStatus: `current`）
- `version_status:upgrade_available:{project}:{kit}` - アップグレード可能（VersionStatus: `upgrade_available`）
- `version_status:project_newer:{project}:{kit}` - プロジェクトが新しい（VersionStatus: `project_newer`）
- `version_status:not_found` - バージョン情報なし（VersionStatus: `not_found`）
- `version_status:` - dasel未インストール（VersionStatus: `unknown` に対応、空値として出力）

### check-setup-type.sh 出力

```text
setup_type:{種類}
```

- `setup_type:initial` - 初回セットアップ
- `setup_type:cycle_start` - サイクル開始
- `setup_type:upgrade:{project}:{kit}` - アップグレード可能（バージョン情報付き）
- `setup_type:warning_newer:{project}:{kit}` - プロジェクトが新しい（バージョン情報付き）
- `setup_type:migration` - 移行が必要
- `setup_type:` - dasel未インストール / unknown（AIに委ねる）

## ユビキタス言語

- **スターターキット**: AI-DLC のテンプレート・プロンプト群を含むリポジトリ
- **プロジェクト**: AI-DLC を利用する対象プロジェクト
- **バージョン**: セマンティックバージョニング形式のバージョン文字列
- **移行**: 旧形式（project.toml）から新形式（aidlc.toml）への変換
- **アップグレード**: スターターキットの新バージョンへの更新

## 不明点と質問

（なし - 既存スクリプトとsetup-prompt.mdから要件が明確）
