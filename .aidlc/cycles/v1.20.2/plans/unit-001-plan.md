# Unit 001 計画: AIエージェント許可リストの刷新

## 概要

`prompts/package/guides/ai-agent-allowlist.md` から Codex CLI、Cline、Cursor、jj関連の記述を削除し、Claude Code と Kiro CLI のみの設定ガイドに刷新する。

## 変更対象ファイル

- `prompts/package/guides/ai-agent-allowlist.md`

## 実装計画

### Phase 1: 設計（ドキュメント修正のためスキップ可能 — depth_level=standard だが、本Unitはドキュメント編集のみのため設計省略）

### Phase 2: 実装

1. **セクション1「はじめに」の適用範囲修正**
   - 適用範囲リストから Codex CLI、Cline、Cursor を削除
   - Claude Code と Kiro CLI のみに変更

2. **セクション2「推奨アプローチ」の修正**
   - sandbox設定テーブルから Codex CLI 行を削除

3. **セクション3「コマンドカテゴリ一覧」の修正**
   - 全サブセクション（3.1〜3.5）から jj 関連コマンド行を削除
   - 3.2 から jj 関連の作成系コマンドを削除
   - 3.3 から jj 関連のGit操作コマンドを削除

4. **セクション4「AIエージェント別設定方法」の修正**
   - 4.1 Claude Code: jj関連の許可リストエントリを削除（設定例・ミニマルセット両方）
   - 4.2 Codex CLI セクション全体を削除
   - 4.4 Cline セクション全体を削除
   - 4.5 Cursor セクション全体を削除
   - Kiro CLI（旧4.3）のセクション番号を 4.2 に更新

5. **セクション5「セキュリティ上の注意事項」の修正**
   - 5.1: Kiro CLI の deniedCommands 参照を維持、Codex CLI/Cline/Cursor 固有記述を削除

6. **セクション7「参考リンク」の修正**
   - Codex CLI 関連リンクを削除

7. **セクション番号の整合性確認**
   - 削除後のセクション番号が連番で整合していることを確認

## 完了条件チェックリスト

- [ ] Codex CLI、Cline、Cursorのセクション・記述が0件
- [ ] jj関連コマンドの記述が0件
- [ ] Claude CodeとKiro CLIの情報のみで構成されている
- [ ] セクション番号が連番で整合している
