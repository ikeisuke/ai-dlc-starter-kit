# Unit: レビューサマリファイル生成

## 概要
AIレビュー完了時にレビューサマリファイルを生成し、指摘内容・対応をリアルタイムで蓄積する仕組みを追加する。

## 含まれるユーザーストーリー
- ストーリー 5: レビューサマリファイル生成（新規）

## 関連Issue
- なし（新規要望）

## 責務
- review-flow.md のレビュー完了ステップ（ステップ5、ステップ5.5）にサマリファイル生成手順を追加
- レビューサマリファイルのフォーマット定義
- Construction Phase: `docs/cycles/{{CYCLE}}/construction/units/{NNN}-review-summary.md` に保存
- Inception Phase: `docs/cycles/{{CYCLE}}/inception/{artifact}-review-summary.md` に保存

## 境界
- PR本文への記載はUnit 005で実施
- レビューサマリファイルのテンプレート作成は含む（docs/aidlc/templates/）

## 依存関係

### 依存する Unit
- Unit 001: 用語変更（依存理由: review-flow.md の用語が変更後の状態で作業するため）
- Unit 003: セルフレビューサブエージェント（依存理由: ステップ5.5の手順改訂後にサマリ生成手順を追加するため）

### 外部依存
- なし

## 非機能要件（NFR）
- 該当なし（プロンプト・テンプレート変更のみ）

## 技術的考慮事項
- レビューサマリはAIレビュー実施時にリアルタイム生成（後から生成すると精度低下）
- サマリ内容: レビュー種別、使用ツール、指摘内容一覧、各指摘への対応（修正済み/先送り+理由）
- AIレビュー未実施の場合はサマリファイルを生成しない
- **ファイル命名規則**:
  - Construction Phase: `{NNN}-review-summary.md`（NNN = Unit番号、例: `001-review-summary.md`）
  - Inception Phase: `{step-name}-review-summary.md`（step-name = 成果物のステップ名、例: `intent-review-summary.md`, `user-stories-review-summary.md`, `unit-definition-review-summary.md`）
- **追記タイミング**: AIレビューの各セット完了時（指摘0件到達時、または指摘対応判断フロー完了時）
- **必須項目**: レビュー種別、使用ツール、レビュー回数、指摘一覧（#/重要度/内容/対応）

## 実装優先度
High

## 見積もり
中（review-flow.md 修正 + テンプレート作成）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-27
- **完了日**: 2026-02-27
- **担当**: @ai
