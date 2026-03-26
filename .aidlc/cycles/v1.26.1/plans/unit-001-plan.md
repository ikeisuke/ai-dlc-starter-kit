# Unit 001 計画: Bash Substitution Check移動

## 概要
operations-release.mdから7.6 Bash Substitution Checkを削除し、rules.mdのカスタムワークフローに移動する。後続ステップ番号を繰り上げ、関連参照を更新する。

## 変更対象ファイル
1. `prompts/package/prompts/operations-release.md` - 7.6削除、ステップ番号繰り上げ
2. `docs/cycles/rules.md` - カスタムワークフローにBash Substitution Check追加、既存ワークフローのステップ番号参照更新

## 実装計画

### Step 1: operations-release.mdからの7.6削除
- 7.6 Bash Substitution Checkセクションを削除
- 後続ステップ番号を繰り上げ（7.7→7.6, 7.8→7.7, ..., 7.14→7.13）

### Step 2: rules.mdへのカスタムワークフロー追加
- カスタムワークフローセクションにBash Substitution Checkを追加
- 実行タイミング: Markdownlint後、progress.md更新前（旧7.6の位置に相当）

### Step 3: 既存参照の更新
- rules.mdの「バージョンファイル更新」「aidlc-setup同期」のステップ番号参照を更新
- rules.mdの「Codex PRレビューの再実行ルール」「PRマージ前レビューコメント確認」のステップ番号参照を更新

### Step 4: 影響範囲の網羅チェック
- `grep -r "7\.\(6\|7\|8\|9\|1[0-4]\)" prompts/package/prompts/operations-release.md` で漏れを確認

## 完了条件チェックリスト
- [ ] operations-release.mdから7.6 Bash Substitution Checkが削除されている
- [ ] 後続ステップ番号が正しく繰り上げられている（7.7→7.6, ..., 7.14→7.13）
- [ ] rules.mdのカスタムワークフローにBash Substitution Checkが追加されている
- [ ] 既存カスタムワークフローのステップ番号参照が更新されている
- [ ] ステップ番号を参照する他ドキュメントが更新されている
