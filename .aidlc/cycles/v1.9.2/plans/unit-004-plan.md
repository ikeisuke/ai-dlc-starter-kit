# Unit 004 計画: AI著者情報の自動検出

## 概要

使用中のAIツールに応じてCo-Authored-Byを自動設定する機能を実装する。

## 変更対象ファイル

- `prompts/package/prompts/common/rules.md`（編集対象）
- `docs/aidlc/prompts/common/rules.md`（Operations Phaseでrsync同期）

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: AI著者情報検出の概念モデルを定義
2. **論理設計**: 検出フローと優先順位を設計
3. **設計レビュー**: ユーザー承認を得る

### Phase 2: 実装

4. **コード生成**: rules.mdに検出ロジックを追加
5. **テスト生成**: 該当なし（ドキュメント変更のみ）
6. **統合とレビュー**: 最終確認

## 完了条件チェックリスト

- [ ] AIツール自己認識による検出ロジックが定義されている
- [ ] 環境変数からの補助検出が定義されている
- [ ] 検出失敗時のユーザー確認フローが定義されている
- [ ] rules.mdに検出ロジックが記載されている

## 技術的考慮事項

### AIツールとai_author値のマッピング

| AIツール | ai_author値 |
|---------|-------------|
| Claude Code | `Claude <noreply@anthropic.com>` |
| Cursor | `Cursor <noreply@cursor.com>` |
| Cline | `Cline <noreply@cline.bot>` |
| Windsurf | `Windsurf <noreply@codeium.com>` |
| Codex CLI | `Codex <noreply@openai.com>` |
| KiroCLI | `Kiro <noreply@aws.com>` |

### 優先順位

1. aidlc.toml設定（`ai_author`が設定されている場合）
2. 自己認識（AIツールの自己申告）
3. 環境変数（`CLAUDE_CODE`, `CURSOR_EDITOR`等）
4. ユーザー確認（上記すべて失敗時）

### 無効化オプション

- `ai_author_auto_detect = false` 設定時は自動検出をスキップ

### 「未設定」の定義

以下はすべて「未設定」として扱い、自動検出を試みる:
- キーが存在しない
- `ai_author = ""`（空文字）
- `ai_author = "   "`（空白のみ）
