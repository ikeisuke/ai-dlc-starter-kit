# ドメインモデル: フェーズ内操作順序の明示化

## 概要

Git/コミット関連の操作順序ルールの構造を定義する。AIエージェントが順序違反を検知し自己修正するためのルール体系。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### 操作（Operation）

- **属性**: name: String - 操作名（例: コミット完了、PR作成）
- **不変性**: 操作名は定義後変更されない
- **等価性**: nameで判定

### 違反時アクション（ViolationAction）

- **属性**: actionType: Enum(stop_and_correct) - 停止して自己修正
- **不変性**: 違反時アクションは常に「停止→自己修正」の一貫した方針
- **等価性**: actionTypeで判定

## エンティティ（Entity）

### 操作順序ルール（OperationOrderRule）

- **属性**:
  - 先行操作（predecessor）: Operation - 先に完了すべき操作
  - 後続操作（successor）: Operation - 先行操作の後に実行すべき操作
  - 前提条件（precondition）: String - ルールが適用される条件（例: squash.enabled時）
  - 判定主体（judge）: AI - 順序を判定する主体
  - 違反時アクション（violationAction）: ViolationAction - 違反検知時の対応
- **振る舞い**:
  - 違反検知: 後続操作が先行操作より先に実行されようとした場合に検知

## 集約（Aggregate）

### 操作順序ルールセット（OperationOrderRuleSet）

- **集約ルート**: OperationOrderRuleSet
- **含まれる要素**: OperationOrderRule のリスト
- **境界**: Git/コミット操作に関連する順序制約（コミット、PR、スカッシュ、レビュー）
- **不変条件**:
  - 各ルールの先行操作と後続操作は異なる
  - ルール間で循環する順序制約がない

## ドメインサービス

### 順序違反検知サービス（OrderViolationDetector）

- **責務**: 現在の操作が順序ルールに違反していないかを判定
- **操作**: detect(currentOperation, completedOperations) - 違反したルール、または違反なしを返す

### 先行操作特定サービス（PredecessorResolver）

- **責務**: 違反検知時に実行すべき先行操作を特定する
- **操作**: resolve(violatedRule) - 実行すべき先行操作を返す

## ユビキタス言語

- **操作順序ルール**: 2つの操作間の実行順序を定義する制約
- **先行操作**: 順序上、先に完了すべき操作
- **後続操作**: 先行操作の後に実行すべき操作
- **順序違反**: 後続操作が先行操作より先に実行されること
- **自己修正**: AIが順序違反を検知した際、正しい順序にフローを戻すこと

## 不明点と質問（設計中に記録）

なし（Issue #317の要件が明確）
