# Unit 003 計画: ai_tools設定による複数AIサービス対応

## 概要

aidlc.tomlの`ai_tools`設定を読み取り、AIレビューに使用するサービスの優先順位に従ってツールを選択するロジックをreview-flow.mdに追加する。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/common/review-flow.md` | ai_tools設定の読み取りと優先順位判定ロジックを追加 |

## 現状分析

**現在のreview-flow.md**:
- `codex`スキルを固定で使用
- MCPフォールバックとして`mcp__codex__codex`を使用
- 他のAIサービス（claude, gemini等）には非対応

**現在のaidlc.toml**:
- `[rules.mcp_review]`セクションに`ai_tools = ["codex"]`が既に存在
- コメントで複数サービス対応の説明あり

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: ai_tools設定の構造と判定ロジックを定義
2. **論理設計**: review-flow.mdへの変更箇所を特定

### Phase 2: 実装

1. review-flow.mdに「ai_tools設定の読み取り」セクションを追加
2. 「AIレビューツール利用可否の確認」セクションを拡張
3. 後方互換性（ai_tools未設定時のデフォルト動作）を維持

## 技術的考慮事項

- 対応ツール名: codex, claude, gemini
- エラーハンドリング: 空配列、未対応ツール名、不正な型
- 後方互換性: ai_tools未設定時は`["codex"]`をデフォルトとして使用

## 完了条件チェックリスト

- [ ] review-flow.mdにai_tools設定セクションを追加
- [ ] 利用可否判定ロジックの明文化
- [ ] 後方互換性の維持（ai_tools未設定時にcodexがデフォルトで使用される）
