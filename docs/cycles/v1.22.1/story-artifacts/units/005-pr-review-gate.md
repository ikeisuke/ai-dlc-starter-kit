# Unit: PRマージ前レビューゲート強化

## 概要
Operations PhaseのPRマージ前に/reviewとcodex review --base mainの実行を必須化し、Codex PRレビュー完了を待つゲートをoperations-release.mdに定義する。

## 含まれるユーザーストーリー
- ストーリー 5: PRマージ前ローカルレビューとCodexレビューゲート

## 責務
- operations-release.md Step 6.6.7〜6.7間にローカルレビューステップを追加
- /reviewとcodex review --base mainの必須化定義
- Codex PRレビュー完了待機ゲートの定義
- CHANGES_REQUESTED時の修正→再レビューフロー定義
- rules.mdの既存ゲートのoperations-release.mdへの統合

## 境界
- /reviewコマンドやcodex CLIの実装変更は含まない
- CI/CDパイプラインの変更は含まない（プロンプトベースのフロー制御のみ）

## 依存関係

### 依存する Unit
- なし

### 外部依存
- Claude Code /reviewコマンド（組み込み機能）
- Codex CLI（codex review）
- GitHub CLI（gh）

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- 正本はoperations-release.md。rules.mdの既存ゲート（L154-202）は参照リンクに変更
- 判定ロジック優先順: (1) /reviewは常に必須 (2) codex CLIインストール済み→codex review --base main必須 (3) gh CLIインストール済み→Codex PRレビューゲート必須 (4) 各CLI未インストール時→該当ステップをスキップし次へ
- 既存フロー: 6.6.7（main差分チェック）→ [新ステップ] → 6.7（マージ）

## 関連Issue
- #332, #325

## 実装優先度
High

## 見積もり
中（複数ファイルのプロンプト変更と既存ルール統合）

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
