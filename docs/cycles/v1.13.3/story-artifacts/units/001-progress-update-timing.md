# Unit: progress.md更新タイミング修正

## 概要
Construction PhaseでUnitブランチ使用時、progress.mdの更新がUnit PRマージ後になる問題を修正する。Operations Phaseで検証済みの「PR準備完了」パターンをConstruction Phaseにも適用する。

## 含まれるユーザーストーリー
- ストーリー 1: Construction Phase progress.md更新タイミング修正

## 責務
- Construction PhaseのUnit完了時の必須作業セクションにprogress.md更新ステップを追加（PR作成ステップの前に配置）
- 「PR準備完了 = 完了」の解釈をプロンプトに記載
- progress.md更新がPR作成前のコミットに含まれるよう、コミット手順の順序を明確化

## 境界
- Operations Phaseの既存実装は変更しない（参照のみ）
- Inception Phaseへの横展開は行わない
- Unitブランチを使用しない場合の既存フローは変更しない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし（プロンプトテキスト変更のみ）
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- `prompts/package/prompts/construction.md` のUnit完了時の必須作業セクションを修正
- Operations Phase operations.md ステップ6.4.5の実装パターンを参照して一貫性を確保

## 関連Issue
- #175

## 実装優先度
Medium

## 見積もり
小規模（プロンプトテキストの追加・修正のみ）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-10
- **完了日**: 2026-02-10
- **担当**: @ikeisuke
