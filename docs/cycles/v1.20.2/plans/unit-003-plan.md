# Unit 003 計画: スキル利用ガイドのツール記述整理

## 概要

`prompts/package/guides/skill-usage-guide.md` から Codex CLI、Gemini CLI の記述を削除し、Claude Code と Kiro CLI のみに整理する。

## 変更対象ファイル

- `prompts/package/guides/skill-usage-guide.md`

## 実装計画

1. セクション「Codex CLI」（85-125行）を丸ごと削除
2. セクション「Gemini CLI」（128-145行）を丸ごと削除
3. トラブルシューティングからcodex/gemini参照を削除（239-243行）
4. 関連リンクからCodex CLI、Gemini CLI行を削除（249-250行）
5. 残存するCodex/Gemini記述の最終確認

## 完了条件チェックリスト

- [ ] Codex CLI、Gemini CLIの使用方法記述が0件
- [ ] Claude CodeとKiro CLIの情報のみで構成されている
- [ ] 削除後の内容が整合している
