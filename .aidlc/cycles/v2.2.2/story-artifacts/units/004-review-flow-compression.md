# Unit: review-flow追加圧縮

## 概要

review-flow-reference.mdの冗長な記述を圧縮し、review-flow関連ファイルの合計サイズを20%以上削減する。

## 含まれるユーザーストーリー

- ストーリー 1: review-flow追加圧縮（#519 S10残り）

## 責務

- review-flow-reference.mdのツール別制約の重複統合・簡略化
- review-flow-reference.md内の冗長な説明文の圧縮
- review-flow.mdはreview-flow-reference.md統合に伴う参照リンク調整のみ

## 境界

- review-flow.mdの指摘対応判断フロー（品質劣化リスクマトリクス記載セクション）
- AIレビュー指摘の却下禁止ルール
- review-flow.mdの処理パス分岐ロジック自体の変更

## 依存関係

### 依存する Unit

なし

### 外部依存

なし

## 非機能要件（NFR）

該当なし

## 技術的考慮事項

- 現行サイズ: review-flow.md約215行 + review-flow-reference.md約100行
- 圧縮対象: ツール別制約の重複（Codex/Claude/Gemini共通部分）、エラーメッセージの冗長な記述
- 測定: `wc -c` でUTF-8バイト数を比較

## 関連Issue

- #519

## 実装優先度

Medium

## 見積もり

中（2ファイル修正、慎重な内容精査が必要）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
- **エクスプレス適格性**: -
- **適格性理由**: -
