# ドメインモデル: サイクルデータ移行

## 概要

`docs/cycles/` から `.aidlc/cycles/` へのパス参照統一。データ移動は完了済みのため、設定ファイル・ドキュメント内の残留パス参照を更新する。

## エンティティ（Entity）

### CycleDataPath
- **属性**:
  - old_path: String - `docs/cycles/` （旧パス、v1互換）
  - new_path: String - `.aidlc/cycles/` （v2正規パス）
- **振る舞い**:
  - migrate(): 旧パス参照を新パスに置換

## 値オブジェクト（Value Object）

### PathReference
- **属性**: file_path: String, line_number: Integer, context: String
- **不変性**: 各ファイル内のパス参照は特定の行に固定
- **等価性**: file_path + line_number で一意

## 集約（Aggregate）

### PathMigration
- **集約ルート**: CycleDataPath
- **含まれる要素**: PathReference（5件）
- **境界**: スキル・設定ファイル内のパス参照のみ（履歴データ内の参照は対象外）
- **不変条件**: 更新後、`docs/cycles` を参照するアクティブなスクリプト・設定が存在しないこと

## ユビキタス言語

- **サイクルデータ**: `.aidlc/cycles/` 配下のバージョン別開発記録
- **パス参照**: ファイル内で `docs/cycles` または `.aidlc/cycles` を指す文字列
- **残留参照**: 旧パス `docs/cycles` のまま更新されていない参照
