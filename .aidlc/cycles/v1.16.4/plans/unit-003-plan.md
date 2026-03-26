# Unit 003 計画: サイクル完了メッセージ修正

## 概要

operations.md（通常版・Lite版）のサイクル完了メッセージで「start setup」を「start inception」に修正する。

## 変更対象ファイル

| ファイル | 変更箇所（セクション） | 内容 |
|---------|---------|------|
| `prompts/package/prompts/operations.md` | 「全Unit完了の場合」セッションサマリ内 | 「start setup」→「start inception」（2箇所） |
| `prompts/package/prompts/lite/operations.md` | 「全Unit完了」メッセージ内 | 「start setup」→「start inception」（1箇所） |

**注**: `docs/aidlc/` 配下の同名ファイルはOperations Phase時のrsyncで自動同期されるため、直接編集しない（同期はOperations Phaseの責務であり、本Unitのスコープ外）。

## 実装計画

1. `prompts/package/prompts/operations.md` の「全Unit完了の場合」セクション内の2箇所を修正
2. `prompts/package/prompts/lite/operations.md` の完了メッセージ内の1箇所を修正
3. 変更後に他の「start setup」参照がないか確認（AGENTS.mdのリダイレクト定義は変更対象外）

## 完了条件チェックリスト

- [ ] operations.md（通常版）の完了メッセージ内の「start setup」が「start inception」に置換されている
- [ ] operations.md（Lite版）の完了メッセージ内の「start setup」が「start inception」に置換されている
- [ ] 後方互換性: AGENTS.mdで「start setup」がInceptionへのリダイレクトとして定義されていることを確認済み
