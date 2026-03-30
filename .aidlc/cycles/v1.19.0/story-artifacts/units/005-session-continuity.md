# Unit: Session Continuity

## 概要
セッション中断時の作業状態自動保存と再開時の状態復元を正式にサポートし、コンテキスト喪失によるやり直しを防止する。

## 含まれるユーザーストーリー
- ストーリー 4: セッション中断・再開の正式サポート

## 責務
- `prompts/package/prompts/common/compaction.md` にsession-state.md生成ステップを追加
- `prompts/package/prompts/common/context-reset.md` にsession-state.md生成・復元手順を追加
- 各フェーズプロンプト（inception.md, construction.md, operations.md）のコンテキストリセット提示箇所にsession-state.md生成を追加
- session-state.mdの必須記録項目を定義: サイクル番号、フェーズ、現在のステップ、完了済みステップ一覧、未完了タスク、次のアクション
- フォールバック動作の定義: session-state.md不在時はprogress.mdから復元

## 境界
- session-state.mdのテンプレート化は対象外（プロンプト内の出力指示で制御）
- progress.mdの構造・フォーマットは変更しない
- Lite版プロンプト（`prompts/package/prompts/lite/*.md`）は本Unitの対象外。Lite版へのSession Continuity適用は将来サイクルで検討

## 依存関係

### 依存する Unit
- なし

### 外部依存
- Amazon AIDLC の session-continuity.md（MIT-0ライセンス、参照元として活用）

## 非機能要件（NFR）
- **パフォーマンス**: N/A（プロンプト変更のみ）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: session-state.md生成失敗時でも既存のprogress.md・履歴ファイルによる復元が可能

## 技術的考慮事項
- 既存のcompaction.md、context-reset.mdを発展させる形で実装
- progress.mdとの二重管理にならないよう、session-state.mdはprogress.mdの情報を包含する上位セットとする
- 複数フェーズプロンプトへの一貫した変更が必要（既存のコンテキストリセット提示箇所を特定して追加）

## 実装優先度
High

## 見積もり
中規模（compaction.md + context-reset.md + 3フェーズプロンプトの修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-03-07
- **完了日**: 2026-03-07
- **担当**: AI
