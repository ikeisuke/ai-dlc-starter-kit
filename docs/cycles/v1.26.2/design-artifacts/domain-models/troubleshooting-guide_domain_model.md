# ドメインモデル: フリクション対処トラブルシューティングガイド

## 概要
AI-DLC利用時のフリクションパターンを5カテゴリに分類し、統一構成で対処法を提供するドキュメントの構造を定義する。

## エンティティ（Entity）

### FrictionCategory（フリクションカテゴリ）
- **ID**: カテゴリ番号（1-5）
- **属性**:
  - `name`: String - カテゴリ名
  - `symptoms`: List[String] - 症状一覧
  - `causes`: List[String] - 原因候補
  - `procedures`: List[Step] - 対処手順
  - `references`: List[String] - 関連参照先（既存ガイドへのリンク）

## 値オブジェクト（Value Object）

### CategoryStructure（カテゴリ統一構成）
- **属性**: symptoms, causes, procedures, references の4セクション
- **不変性**: 全カテゴリで同一構成を維持

## ユビキタス言語

- **フリクション**: AI-DLC利用時にユーザーが直面する作業阻害要因
- **5カテゴリ**: 認証失効、外部ツール制約、フェーズ逸脱、AI誤アプローチ、コンテキストリセット復帰
- **統一構成**: 症状→原因候補→対処手順→関連参照先の4セクション構成
