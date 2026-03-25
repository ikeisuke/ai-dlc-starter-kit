# ドメインモデル: アーキテクチャスタイル宣言と違反検出

## 概要
プロジェクトのアーキテクチャスタイルをTOML設定で宣言し、reviewing-architectureスキルがスタイル固有の観点でレビューできるようにするための設定スキーマ設計。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### ArchitectureStyle
- **属性**: style: string - アーキテクチャスタイルの識別子
- **有効値**: `"layered"`, `"hexagonal"`, `"clean"`, `"event-driven"`, `"modular"`, `"none"`
- **不変性**: 設定ファイルから読み取った後は変更不可
- **等価性**: 文字列値の完全一致
- **デフォルト値**: `"none"`（未設定時、スタイル固有の検証を行わない）

### LayerDefinition
- **属性**: layers: string[] - レイヤー名の順序付き配列（外側/上位から内側/下位の順）
- **不変性**: 設定ファイルから読み取った後は変更不可
- **等価性**: 配列の内容と順序の完全一致
- **デフォルト値**: `[]`（空配列、レイヤー検証を行わない）
- **制約**: `style` が `"layered"`, `"clean"`, `"hexagonal"` の場合に意味を持つ。`"event-driven"`, `"modular"` の場合は `layers` を無視する（設定されていても参照しない）
- **順序の意味**: `dependency_direction` に応じて解釈が変わる
  - `"top-down"`: 配列先頭が上位層、末尾が下位層。上位→下位への依存のみ許可
  - `"inward"`: 配列先頭が外部層、末尾が内部層。外部→内部への依存のみ許可

### DependencyDirection
- **属性**: dependency_direction: string - 依存方向の制約
- **有効値**: `"top-down"`（上位→下位）, `"inward"`（外部→内部）, `"none"`
- **不変性**: 設定ファイルから読み取った後は変更不可
- **等価性**: 文字列値の完全一致
- **デフォルト値**: `"none"`（依存方向の検証を行わない）

## ドメインサービス

### ArchitectureConfigReader
- **責務**: `[rules.architecture]` セクションから設定値を読み取り、バリデーション後に返す
- **操作**:
  - readStyle() - `rules.architecture.style` を読み取り、有効値チェック
  - readLayers() - `rules.architecture.layers` を配列として読み取り
  - readDependencyDirection() - `rules.architecture.dependency_direction` を読み取り
- **グレースフルデグラデーション**: 未知のstyle値に対して警告を出力し、`"none"` として扱う（汎用レビューで続行）

### StyleAwareReviewer
- **責務**: 宣言されたスタイルに基づいてレビュー観点を調整する
- **操作**:
  - getReviewPerspectives(style) - スタイルに応じた追加レビュー観点を返す
  - validateLayerDependency(layers, direction) - レイヤー間依存の方向性をチェック

## スタイル別レビュー観点マッピング

| style | 追加レビュー観点 |
|-------|----------------|
| `layered` | レイヤースキップ（例: presentation→domain直接参照）の検出、依存方向が上→下であるか |
| `hexagonal` | ポート/アダプタ分離の確認、ドメインが外部依存を持っていないか |
| `clean` | ユースケース層の責務、依存性逆転の原則遵守 |
| `event-driven` | イベント駆動パターンの一貫性、イベントハンドラの責務分離 |
| `modular` | モジュール間の結合度、公開インターフェースの最小化 |
| `none` | 追加観点なし（既存の汎用レビューのみ） |

## 設定スキーマ（TOML）

```toml
[rules.architecture]
style = "none"                  # アーキテクチャスタイル
layers = []                     # レイヤー定義（上位から下位の順）
dependency_direction = "none"   # 依存方向制約
```

### 設定例

#### Layered Architecture
```toml
[rules.architecture]
style = "layered"
layers = ["presentation", "application", "domain", "infrastructure"]
dependency_direction = "top-down"
```

#### Hexagonal Architecture
```toml
[rules.architecture]
style = "hexagonal"
layers = ["adapters", "ports", "application", "domain"]
dependency_direction = "inward"
```

#### Clean Architecture
```toml
[rules.architecture]
style = "clean"
layers = ["frameworks", "interface-adapters", "use-cases", "entities"]
dependency_direction = "inward"
```

## バリデーション仕様

| 設定キー | バリデーション | 失敗時の動作 |
|---------|-------------|------------|
| `style` | 有効値リストに含まれるか | 警告表示 + `"none"` にフォールバック |
| `layers` | 配列であるか | 警告表示 + `[]` にフォールバック |
| `dependency_direction` | 有効値リストに含まれるか | 警告表示 + `"none"` にフォールバック |

**バリデーション警告フォーマット**:
```text
【警告】rules.architecture.{key} に無効な値 "{入力値}" が設定されています。"{デフォルト値}" にフォールバックします。有効値: {有効値リスト}
```

## ユビキタス言語

- **アーキテクチャスタイル**: プロジェクトが採用するソフトウェアアーキテクチャのパターン（layered, hexagonal等）
- **レイヤー**: アーキテクチャ上の論理的な分離層
- **依存方向**: レイヤー間の依存が許可される方向（top-down: 上→下、inward: 外→内）
- **グレースフルデグラデーション**: 未知の設定値に対して警告を出しつつ、汎用的な動作で処理を続行すること

## 不明点と質問（設計中に記録）

なし（Unit定義から要件が明確）
