# Unit: エクスプレスモード仕様定義

## 概要
rules.mdにエクスプレスモードの仕様（適用条件、成果物要件、フォールバック条件）を追加する。

## 含まれるユーザーストーリー
- ストーリー 1a: エクスプレスモード判定とフォールバック（#359）

## 責務
- rules.mdのDepth Levelテーブルにエクスプレスモード（minimal拡張）の成果物要件を追加
- エクスプレスモード適用条件の定義（Unit数1以下、depth_level=minimal）
- フォールバック条件と通知メッセージの定義（文言の正本はrules.md内に定義）
- 既存モード（standard/comprehensive）への非影響を保証する仕様記述

## 境界
- inception.md/construction.mdのフロー実装はUnit 003で行う
- Operations Phase統合は対象外

## 依存関係

### 依存する Unit
- なし（rules.mdの仕様追加はinception.mdのステップ番号に依存しない。Unit 001との実装順序は推奨だがハード依存ではない）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 対象ファイル: `prompts/package/prompts/common/rules.md`
- Depth Level仕様セクションの拡張（Single Source of Truth原則を維持）
- semi_autoモードのゲート判定との整合性を記述

## 実装優先度
High

## 見積もり
小規模（rules.md 1ファイルの仕様追加）

## 関連Issue
- #359

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
