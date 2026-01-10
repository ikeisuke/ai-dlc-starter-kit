# Unit: AIエージェント許可リストガイド

## 概要
各種AIエージェント（Claude Code、Codex、Kiro-CLI等）向けに、AI-DLCで使用する安全なコマンドの許可リストをドキュメント化する。

## 含まれるユーザーストーリー
- ストーリー 1-1: AIエージェント許可リストガイドの提供

## 責務
- `prompts/package/guides/ai-agent-allowlist.md` の作成
- コマンドのカテゴリ分類（読み取り専用、作成系、Git操作、除外対象）
- 各AIエージェントの設定ファイルパスと設定方法の記載
- スターターキットセットアップ完了時の案内メッセージ追加

## 境界
- 各AIエージェントの設定ファイルパスと設定方法の概要は記載する（責務に含む）
- 各AIエージェントの設定ファイルテンプレート（コピペ可能な設定例）の作成は対象外
- AIエージェント固有のトラブルシューティングや詳細な設定手順は対象外

## 依存関係

### 依存する Unit
- なし

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: 破壊的コマンドを明確に除外リストに記載
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項
- 各AIエージェントの設定ファイル形式は異なるため、汎用的な説明を提供
- `prompts/package/guides/` ディレクトリを新規作成
- 各フェーズで使用されるコマンドを網羅的に抽出

## 参考ファイル
- `prompts/setup-prompt.md`（スターターキットセットアップ - 案内追加対象、コマンド使用例）
- `prompts/package/prompts/setup.md`（サイクルセットアップ - コマンド使用例）
- `prompts/package/prompts/inception.md`（Inception Phase - コマンド使用例）
- `prompts/package/prompts/construction.md`（Construction Phase - コマンド使用例）
- `prompts/package/prompts/operations.md`（Operations Phase - コマンド使用例）
- `docs/cycles/backlog/feature-ai-agent-allowlist-recommendations.md`（バックログ）

## 実装優先度
Medium

## 見積もり
中（ガイドドキュメント作成 + セットアッププロンプト修正）

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-01-10
- **完了日**: -
- **担当**: AI
