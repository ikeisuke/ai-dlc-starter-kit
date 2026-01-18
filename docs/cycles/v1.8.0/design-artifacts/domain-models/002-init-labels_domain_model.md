# ドメインモデル: 共通ラベル一括初期化スクリプト

## 概要

GitHub Issueで使用するバックログ管理用の共通ラベルを一括作成するスクリプトの構造と責務を定義する。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。実装はImplementation Phase（コード生成ステップ）で行います。

## 値オブジェクト（Value Object）

### Label（ラベル）

GitHub Issueに付与するラベルを表す値オブジェクト。

- **属性**:
  - name: String - ラベル名（例: "backlog", "type:feature"）
  - color: String - 16進数カラーコード（#なし、例: "0052CC"）
  - description: String - ラベルの説明
- **不変性**: ラベル定義は変更されない（変更する場合は再作成）
- **等価性**: name が同一であれば同一ラベルとみなす

### LabelCategory（ラベルカテゴリ）

ラベルを分類するカテゴリを表す値オブジェクト。

- **属性**:
  - prefix: String - カテゴリプレフィックス（例: "type:", "priority:"）
  - purpose: String - カテゴリの目的
- **等価性**: prefix が同一であれば同一カテゴリ

**注**: このモデルはラベルの概念的な分類を表現するためのものであり、実装では直接使用しない（ラベル定義テーブルで暗黙的に表現される）。

## ドメインサービス

### LabelInitializationService

共通ラベルの一括初期化を担うサービス。

- **責務**: 定義済みの共通ラベルをGitHub リポジトリに作成する
- **操作**:
  - initializeAllLabels() - 全共通ラベルを初期化
  - checkLabelExists(name) - ラベルの存在確認
  - createLabel(label) - 単一ラベルの作成

### 処理フロー

```text
1. gh CLI の利用可否確認
   ├─ 利用不可 → エラーメッセージ出力、終了
   └─ 利用可能 → 続行

2. 各ラベルについて:
   ├─ ラベル存在確認 (gh label list)
   │   ├─ 存在する → スキップ、"label:exists" 出力
   │   └─ 存在しない → ラベル作成 (gh label create)
   │       ├─ 成功 → "label:created" 出力
   │       └─ 失敗 → "label:error" 出力

3. 処理結果サマリ出力
```

## 共通ラベル定義

### カテゴリ1: バックログ識別

| ラベル名 | 色 | 説明 |
|---------|------|------|
| backlog | 0052CC | バックログアイテム |

### カテゴリ2: タイプ（type:）

| ラベル名 | 色 | 説明 |
|---------|------|------|
| type:feature | A2EEEF | 新機能 |
| type:bugfix | D73A4A | バグ修正 |
| type:chore | FEF2C0 | 雑務 |
| type:refactor | C5DEF5 | リファクタリング |
| type:docs | 0075CA | ドキュメント |
| type:perf | F9D0C4 | パフォーマンス |
| type:security | D93F0B | セキュリティ |

### カテゴリ3: 優先度（priority:）

| ラベル名 | 色 | 説明 |
|---------|------|------|
| priority:high | B60205 | 優先度: 高 |
| priority:medium | FBCA04 | 優先度: 中 |
| priority:low | 0E8A16 | 優先度: 低 |

## ユビキタス言語

このドメインで使用する共通用語：

- **共通ラベル**: 全サイクルで共通して使用するGitHub Issueラベル
- **サイクルラベル**: 特定のサイクル（vX.X.X）に紐づくラベル（別Unit 004で対応）
- **ラベル初期化**: ラベルが存在しない場合に作成する処理

## 不明点と質問（設計中に記録）

なし（Unit定義で要件が明確）
