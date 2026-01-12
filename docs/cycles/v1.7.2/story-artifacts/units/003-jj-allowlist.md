# Unit: jjサポート - 許可リスト

## 概要
AIエージェント許可リストにjjコマンドを追加する。

## 含まれるユーザーストーリー
- ストーリー 2-2: 許可リストへのjjコマンド追加 (#42)

## 責務
- ai-agent-allowlist.md にjj読み取り系コマンドを追加
- ai-agent-allowlist.md にjj作成系コマンドを追加
- ai-agent-allowlist.md にjj操作系コマンドを追加
- Claude Code設定例にjjコマンドを追加

## 境界
- jjの設定やドキュメントは別Unit（002）

## 依存関係

### 依存する Unit
- なし（Unit 002と並行して実装可能）

### 外部依存
- なし

## 非機能要件（NFR）
- **パフォーマンス**: 該当なし
- **セキュリティ**: 書き込み系コマンド（`jj git push`, `jj describe`, `jj new`等）を許可リストに追加するため、既存のGit許可リストと同等のリスク管理を適用。sandbox環境での実行を推奨する旨を注記。
- **スケーラビリティ**: 該当なし
- **可用性**: 該当なし

## 技術的考慮事項
- prompts/package/guides/ai-agent-allowlist.md を修正
- 追加するjjコマンド:
  - 読み取り系: jj status, jj log, jj diff, jj bookmark list
  - 作成系: jj git init --colocate, jj bookmark create, jj new
  - 操作系: jj describe -m, jj git push, jj bookmark set
- Claude Code設定例のJSON形式に合わせて追加

## 実装優先度
Medium

## 見積もり
AI-DLCでは見積もりを行わない

---
## 実装状態

- **状態**: 進行中
- **開始日**: 2026-01-13
- **完了日**: -
- **担当**: @AI
