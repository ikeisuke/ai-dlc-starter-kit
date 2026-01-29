# Unit: Construction → Operations引き継ぎの仕組み

## 概要

Construction Phaseで発生した手動作業をOperations Phaseに明確に引き継ぐ仕組みを構築する。

## 含まれるユーザーストーリー

- A-1: Construction → Operations引き継ぎ (#140)

## 責務

- 引き継ぎタスクファイルのテンプレート作成
- Construction Phase完了時の引き継ぎファイル作成手順をconstruction.mdに追加
- Operations Phase開始時の引き継ぎファイル確認手順をoperations.mdに追加
- 1作業1ファイル形式のディレクトリ構造定義

## 境界

- 既存のphase間引き継ぎ（Inception → Construction）は変更しない
- Unit定義ファイルの構造は変更しない

## 依存関係

### 依存する Unit

- なし

### 外部依存

- なし

## 非機能要件（NFR）

- **パフォーマンス**: N/A（ドキュメント・テンプレートの変更のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: 複数人での並行作業が可能な形式
- **可用性**: N/A

## 技術的考慮事項

- `docs/cycles/vX.X.X/operations/tasks/` ディレクトリを使用
- テンプレートは `prompts/package/templates/` に配置
- 既存のUnit定義ファイル形式を参考にする

## 実装優先度

High

## 見積もり

中（テンプレート作成 + プロンプト2ファイル修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-01-29
- **完了日**: 2026-01-29
- **担当**: -
