# Unit: Reverse Engineering強化

## 概要
Inception Phaseのステップ2（既存コード分析）をReverse Engineeringステージとして拡張し、体系的な解析手順を組み込む。

## 含まれるユーザーストーリー
- ストーリー 3: 既存コードベースの体系的解析

## 責務
- `prompts/package/prompts/inception.md` のステップ2を「Reverse Engineering」として拡張
- 4つの解析手順を追加: ディレクトリ構造解析、パターン・アーキテクチャ検出、技術スタック推定、依存関係マッピング
- 解析結果の `existing_analysis.md` への構造化出力フォーマットを定義
- 解析エラー時のフォールバック動作（取得済み結果記録+継続可否確認）を記載
- greenfieldスキップのConditional分岐を維持

## 境界
- `existing_analysis.md` のテンプレート化は対象外（プロンプト内の出力指示で制御）
- Construction Phase以降への影響はなし

## 依存関係

### 依存する Unit
- なし

### 外部依存
- Amazon AIDLC の reverse-engineering.md（MIT-0ライセンス、参照元として活用）

## 非機能要件（NFR）
- **パフォーマンス**: N/A（プロンプト変更のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: 大規模コードベースではサブエージェントによる並行解析を推奨する旨を記載
- **可用性**: N/A

## 技術的考慮事項
- 既存のステップ2の基盤を活用し、手順を具体化する拡張（既存動作を壊さない）
- brownfield/greenfield判定は既存のConditional分岐をそのまま利用

## 実装優先度
Medium

## 見積もり
小規模（inception.md 1ファイルのステップ2拡張のみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-07
- **完了日**: 2026-03-07
- **担当**: Claude
