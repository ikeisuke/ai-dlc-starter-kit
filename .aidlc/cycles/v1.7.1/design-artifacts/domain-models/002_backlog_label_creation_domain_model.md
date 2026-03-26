# ドメインモデル: backlogラベル自動作成

## 概要

Issue駆動バックログモード使用時に、GitHub Issueのラベルを自動作成・管理する機能のドメインモデル。ラベルはバックログ項目の分類と追跡に使用される。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### GitHubLabel

- **属性**:
  - name: String - ラベル名（例: "backlog", "type:feature"）
  - description: String - ラベルの説明
  - color: String - 6桁のHexカラーコード（#なし）
- **不変性**: ラベルは定義時に確定し、実行時に変更しない
- **等価性**: nameで等価性を判定

### LabelCategory

ラベルのカテゴリ分類:

| カテゴリ | プレフィックス | 用途 |
|---------|---------------|------|
| Backlog | なし | バックログ項目識別 |
| Type | `type:` | 項目種類の分類 |
| Priority | `priority:` | 優先度の分類 |
| Cycle | `cycle:` | サイクル紐付け |

## 定義済みラベル

### 基本ラベル（setup.mdで作成）

| name | description | color |
|------|-------------|-------|
| `backlog` | バックログ項目 | FBCA04 |
| `type:feature` | 新機能 | 1D76DB |
| `type:bugfix` | バグ修正 | D93F0B |
| `type:chore` | 雑務・メンテナンス | 0E8A16 |
| `type:refactor` | リファクタリング | 5319E7 |
| `type:docs` | ドキュメント | 0075CA |
| `type:perf` | パフォーマンス | FBCA04 |
| `type:security` | セキュリティ | B60205 |
| `priority:high` | 高優先度 | D93F0B |
| `priority:medium` | 中優先度 | FBCA04 |
| `priority:low` | 低優先度 | 0E8A16 |

### サイクルラベル（inception.mdで作成）

| name | description | color |
|------|-------------|-------|
| `cycle:vX.X.X` | サイクル vX.X.X | C5DEF5 |

## ドメインサービス

### LabelManager（概念）

- **責務**: GitHubラベルの存在確認と自動作成
- **操作**:
  - `checkAndCreateLabels()` - 必要なラベルが存在しない場合に作成
  - `createCycleLabel(version)` - サイクルラベルを作成

## 処理フロー

### setup.mdでの処理

1. backlog.mode = "issue" を確認
2. GitHub CLIが利用可能か確認
3. 各基本ラベルについて:
   - `gh label list --search "ラベル名"` で存在確認
   - 存在しない場合 `gh label create` で作成

### inception.mdでの処理

1. backlog.mode = "issue" を確認
2. サイクルラベル `cycle:vX.X.X` の存在確認
3. 存在しない場合に作成
4. 関連Issueにサイクルラベルを付与（Unit定義の「関連Issue」参照）

## ユビキタス言語

- **backlogラベル**: Issue駆動バックログの項目を識別するためのGitHubラベル
- **typeラベル**: バックログ項目の種類を分類するラベル（feature, bugfix等）
- **priorityラベル**: バックログ項目の優先度を示すラベル
- **cycleラベル**: バックログ項目を特定のサイクルに紐付けるラベル

## 不明点と質問

なし（Unit 002定義で十分明確）
