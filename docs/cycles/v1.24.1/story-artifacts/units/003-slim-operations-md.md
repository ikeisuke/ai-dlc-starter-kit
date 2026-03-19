# Unit: operations.mdのスリム化

## 概要
operations.md（運用引き継ぎ情報）から他ソースで取得可能な冗長情報を削除し、コンテキスト消費を削減する。

## 含まれるユーザーストーリー
- ストーリー 3: operations.mdのスリム化（#365）

## 関連Issue
- #365

## 責務
- `docs/cycles/operations.md` から冗長セクションを削除（178行→89行以下）
- `prompts/package/templates/operations_handover_template.md` を簡素化（60行→30行以下）
- 運用固有情報（デプロイ方針・既知の問題）は維持

## 境界
- Operations Phaseのフローロジック（operations.md, operations-release.md）は変更しない
- aidlc.tomlの構造は変更しない

## 依存関係

### 依存する Unit
- Unit 001: aidlc-setup.sh同期スキップバグ修正（依存理由: prompts/package/ の変更が確実に配布されるよう、同期バグ修正を先行させる）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- operations.mdは `docs/cycles/` 直下のため、`prompts/package/` ではなく直接編集
- テンプレートは `prompts/package/templates/` を編集（正本）
- 削減候補: プロジェクト概要、CI/CD設定、更新履歴、メタ開発手順

## 実装優先度
Medium

## 見積もり
小〜中（2ファイル同時修正＋削減後の妥当性レビュー）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-19
- **完了日**: 2026-03-19
- **担当**: -
