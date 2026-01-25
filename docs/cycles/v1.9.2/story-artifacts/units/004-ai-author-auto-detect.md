# Unit: AI著者情報の自動検出

## 概要

使用中のAIツールに応じてCo-Authored-Byを自動設定する機能を実装する。

## 含まれるユーザーストーリー

- ストーリー4: AI著者情報の自動検出

## 責務

- AIツール自己認識による検出ロジック
- 環境変数からの補助検出
- 検出失敗時のユーザー確認フロー
- rules.mdへの検出ロジック記載

## 対象ファイル

- `prompts/package/prompts/common/rules.md`（編集対象）
- `docs/aidlc/prompts/common/rules.md`（Operations Phaseでrsync同期）

## 境界

- 固定デフォルト値は使用しない
- 新規AIツールの追加は対象外（マッピングテーブルのみ）

## 依存関係

### 依存する Unit

なし（依存する他のUnitがない）

### 外部依存

なし

## 非機能要件（NFR）

- **パフォーマンス**: 該当なし
- **セキュリティ**: 該当なし
- **スケーラビリティ**: 新規ツール追加に対応可能な設計
- **可用性**: 該当なし

## 技術的考慮事項

- AIツール自己認識: Claude Code, Cursor, Cline, Windsurf, Codex CLI, KiroCLI
- 優先順位: aidlc.toml設定 > 自己認識 > 環境変数 > ユーザー確認
- 検出失敗時は固定値を使わずユーザーに確認

**無効化オプション**:
- `ai_author_auto_detect = false` 設定時は自動検出をスキップ

**「未設定」の定義**:
- キーが存在しない
- `ai_author = ""`（空文字）
- `ai_author = "   "`（空白のみ）
- 上記はすべて「未設定」として扱い、自動検出を試みる

**環境変数（補助検出用）**:
- `CLAUDE_CODE` - Claude Code実行時
- `CURSOR_EDITOR` - Cursor実行時
- その他AIツール固有の環境変数

**成果物形式**:
- rules.mdに検出ロジックのフローチャートまたは疑似コードを記載

**AIツールとai_author値のマッピング**:

| AIツール | ai_author値 |
|---------|-------------|
| Claude Code | `Claude <noreply@anthropic.com>` |
| Cursor | `Cursor <noreply@cursor.com>` |
| Cline | `Cline <noreply@cline.bot>` |
| Windsurf | `Windsurf <noreply@codeium.com>` |
| Codex CLI | `Codex <noreply@openai.com>` |
| KiroCLI | `Kiro <noreply@aws.com>` |

## 実装優先度

High

## 見積もり

中規模な変更

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
