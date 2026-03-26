# ドメインモデル: unit_branch.enabledデフォルト値変更

## 概要

Unitブランチ作成の設定判定ロジックにおけるデフォルト値を変更する。プロンプトテキストの変更のみで、実装コードは含まない。

## エンティティ（Entity）

### UnitBranchSetting（概念モデル）

- **属性**:
  - enabled: boolean | undefined - Unitブランチ作成を提案するかどうか
- **振る舞い**:
  - isEnabled(): `enabled = true` の場合のみ `true` を返す。`false`、未設定、空文字、型不一致等はすべて `false` を返す

## 値オブジェクト（Value Object）

該当なし

## 集約（Aggregate）

該当なし

## ドメインサービス

該当なし

## ユビキタス言語

- **unit_branch.enabled**: Unitブランチ作成の有効/無効を制御する設定値
- **デフォルト値**: 設定が明示的に指定されていない場合に適用される値（変更前: true → 変更後: false）

## 不明点と質問（設計中に記録）

なし（要件が明確）
