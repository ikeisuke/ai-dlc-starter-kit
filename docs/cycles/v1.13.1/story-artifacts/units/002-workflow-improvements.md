# Unit: ワークフロー改善（operations/construction）

## 概要
Operations PhaseとConstruction Phaseのワークフローを改善し、PRマージ後のcheckout失敗とUnit完了時のコミット忘れを防止する。

## 含まれるユーザーストーリー
- ストーリー2: PRマージ後のcheckout失敗防止
- ストーリー3: Unit完了時のコミット確認

## 責務
- operations.mdのリリース準備セクションの手順改善
- construction.mdのUnit完了時チェックリスト追加

## 境界
- setup-prompt.mdへの変更は別Unit（Unit 003）で対応
- inception.mdへの変更は別Unit（Unit 003）で対応
- Lite版プロンプト（`prompts/package/prompts/lite/`）は対象外（別サイクルで対応）

## ソースファイル管理
- **修正対象**: `prompts/package/prompts/operations.md`、`prompts/package/prompts/construction.md`（ソース）
- **同期先**: `docs/aidlc/prompts/` 配下はrsync同期で自動更新（Operations Phaseで実施）
- このリポジトリはメタ開発のため、`prompts/package/`がソースオブトゥルース

## 依存関係

### 依存するUnit
なし

### 外部依存
なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- ドキュメントの手順変更のみ
- 既存の手順との整合性を保つ

## 実装優先度
High（Must-have + Should-have）

## 見積もり
小規模（ドキュメント2ファイルの修正）

## 関連Issue
- #167
- #166

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-02-05
- **完了日**: 2026-02-05
- **担当**: Claude
