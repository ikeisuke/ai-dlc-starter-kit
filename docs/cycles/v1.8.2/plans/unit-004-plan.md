# Unit 004 計画: AIレビュー設定強化

## 概要

`aidlc.toml` の `[rules.mcp_review]` セクションに `ai_tools` 設定を追加し、AIレビューに使用するAIサービスを設定可能にする。

## 変更対象ファイル

### 設定ファイル

- `prompts/package/aidlc.toml` - `ai_tools` 設定の追加

### プロンプトファイル

- `prompts/package/prompts/construction.md` - AIレビュー優先ルールの修正
- `prompts/package/prompts/inception.md` - AIレビュー優先ルールの修正（存在する場合）
- `prompts/package/prompts/operations.md` - AIレビュー優先ルールの修正（存在する場合）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: AIレビュー設定の構造と責務を定義
2. **論理設計**: 設定読み取りとフォールバックロジックの設計

### Phase 2: 実装

1. **aidlc.toml の修正**: `ai_tools` 設定の追加
2. **プロンプトの修正**: 各フェーズのAIレビュー優先ルールを修正
   - 設定から `ai_tools` リストを読み取る
   - リスト順にAIサービスを試行
   - すべて利用不可時のエラーメッセージ
3. **統合テスト**: 設定の読み取りとフォールバック動作の確認

## 完了条件チェックリスト

- [ ] `aidlc.toml` に `ai_tools` 設定を追加
- [ ] 各フェーズのプロンプトを修正（設定を読み取り、指定されたAIサービスを順に試行）
- [ ] エラーハンドリングの実装（すべて利用不可時のメッセージ表示）

## 技術的考慮事項

- 設定形式: `ai_tools = ["codex", "claude", "gemini"]`
- 未設定時のデフォルト: `["codex"]`（現状維持）
- 既存の `mode` 設定との互換性を維持
