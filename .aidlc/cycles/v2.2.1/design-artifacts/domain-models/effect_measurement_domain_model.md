# ドメインモデル: 効果計測・検証

## 概要
Wave 2全施策の実装完了後にファイルバイト数の再計測を行い、ベースラインとの差分から成功基準（12.5KB以上削減）の達成を判定する。コード変更は行わない計測・記録専用のUnit。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### FileMeasurement
- **属性**: path: string - 対象ファイルのスキルベースディレクトリ相対パス、bytes: integer - `wc -c` 計測値
- **不変性**: 計測時点のスナップショットとして不変
- **等価性**: path が同一であれば同一ファイルの計測値

### PhaseMeasurement
- **属性**: phase: string - フェーズ名（Inception/Construction/Operations）、common_total: integer - 共通ファイル合計、step_total: integer - ステップファイル合計、load_total: integer - 初回ロード合計
- **不変性**: フェーズ単位の集計結果として不変
- **等価性**: phase が同一であれば同一フェーズの計測値

### DeltaResult
- **属性**: phase: string - フェーズ名、baseline_bytes: integer - ベースライン値、current_bytes: integer - 事後計測値、delta_bytes: integer - 差分（正=削減）
- **不変性**: 比較結果として不変
- **等価性**: phase が同一であれば同一比較

## ドメインサービス

### MeasurementService
- **責務**: 対象ファイルリストのバイト数を取得し、FileMeasurement のリストを生成する
- **操作**: measure(file_list) - ファイルリストの各バイト数を計測
- **注**: 計測手段（`wc -c`）はインフラ詳細だが、Unit 001との比較可能性を担保するため同一手段を要件として固定。計測・記録専用Unitのためポート抽象化は過剰設計と判断

### ComparisonService
- **責務**: ベースラインと事後計測の PhaseMeasurement を比較し、DeltaResult を生成する
- **操作**: compare(baseline, current) - フェーズ別の差分を算出

### JudgmentService
- **責務**: DeltaResult のリストから成功基準の達成を判定する
- **操作**: judge(delta_results) - フェーズ別の削減量を評価し、全フェーズで12,500B以上の削減が達成されているかを判定（フェーズ別判定）
- **判定ロジック**: 全フェーズの delta_bytes >= 12,500 なら「達成」、一部のみなら「一部達成」、全フェーズ未達なら「未達成」

## ユビキタス言語

- **ベースライン**: Unit 001で計測したWave 1実施後のバイト数（不変の参照入力）
- **事後計測**: Wave 2全施策実施後の再計測値
- **成功基準**: 各フェーズのベースラインからの削減量が12.5KB（12,500B）以上（フェーズ別判定）
- **初回ロード合計**: 共通ファイル合計 + ステップファイル合計（フェーズ別）
