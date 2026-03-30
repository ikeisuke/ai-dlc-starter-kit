# Unit 004 計画: スクリプト参照の整合性確認

## 概要

ガイドドキュメント内のスクリプトパス参照が全て実在するファイルと一致していることを確認し、不一致があれば修正する。

## 変更対象ファイル

- `prompts/package/guides/backlog-management.md`（確認対象）
- `prompts/package/guides/issue-management.md`（確認対象）
- `prompts/package/guides/worktree-usage.md`（確認対象）

## 実装計画

1. 各ガイドファイル内のスクリプトパス参照を抽出
2. 正本パス（`prompts/package/bin/`）での存在確認
3. 不一致があれば修正

## 完了条件チェックリスト

- [x] backlog-management.md内のスクリプトパス参照が実在ファイルと一致
- [x] issue-management.md内のスクリプトパス参照が実在ファイルと一致
- [x] worktree-usage.md内のスクリプトパス参照が実在ファイルと一致
- [x] 不一致なし（修正不要）
