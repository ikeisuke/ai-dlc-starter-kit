# Unit 002 計画: サンドボックス環境ガイドのツール記述整理

## 概要

`prompts/package/guides/sandbox-environment.md` から Codex CLI、Cline、Cursor、Gemini CLI の記述を削除し、Claude Code と Kiro CLI のみに整理する。

## 変更対象ファイル

- `prompts/package/guides/sandbox-environment.md`

## 実装計画

1. 検証情報テーブルからCodex CLI行を削除
2. 認証方式テーブルからCodex CLI行を削除
3. サンドボックス種類テーブルからCodex参照を削除
4. ユースケース別推奨設定テーブルからCodex参照を削除
5. セクション4 (Codex CLI) と 4.5 (Codex CLI OAuth) を丸ごと削除
6. セクション5 (KiroCLI) → 4 に、5.5 → 4.5 にリナンバ
7. セクション6 (Docker) → 5 にリナンバ
8. セクション7 (セキュリティ) → 6 にリナンバ
9. 参考リンクからCodex CLI行を削除
10. 残存するCodex/Cline/Cursor/Gemini記述の最終確認

## 完了条件チェックリスト

- [ ] Codex CLI、Cline、Cursor、Gemini CLIの記述が0件
- [ ] Claude CodeとKiro CLIの情報のみで構成されている
- [ ] 参考リンクから削除対象ツールのリンクが除去されている
