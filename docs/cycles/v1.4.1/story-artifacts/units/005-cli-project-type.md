# Unit: CLIプロジェクトタイプ追加

## 概要
コマンドラインツールをプロジェクトタイプとして選択できるようにする。

## 含まれるユーザーストーリー
- ストーリー1: コマンドラインツールのプロジェクトタイプ追加

## 責務
- operations_progress_template.md に cli プロジェクトタイプを追加
- operations.md で cli の配布ステップ処理を定義
- cli はデスクトップアプリに準じた扱い（配布ステップ実施）

## 境界
- setup-init.md でのプロジェクトタイプ選択肢追加は含まない（必要に応じて後続で対応）

## 依存関係

### 依存する Unit
- なし（他の Unit に依存しない、operations.md 系は独立）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 変更対象ファイル:
  - `prompts/package/prompts/operations.md`
  - `prompts/package/templates/operations_progress_template.md`
- 既存のプロジェクトタイプ: ios, android, web, backend, general
- cli はデスクトップ（desktop）に準じる扱い

## 実装優先度
Medium

## 見積もり
小（テンプレートとプロンプトの修正）

---
## 実装状態

- **状態**: 完了
- **開始日**: 2025-12-19
- **完了日**: 2025-12-19
- **担当**: AI
