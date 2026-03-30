# Unit 001: Lite版ルーティング廃止 - 計画

## 概要

SKILL.md/CLAUDE.md/AGENTS.mdからLite版ルーティングエントリを完全削除し、Liteプロンプトファイルを削除する。ユーザー指示により廃止メッセージの実装は不要（完全撤去）。

## 同期方針

- **正本**: `skills/aidlc/`（スキルファイル）と `prompts/package/`（パッケージプロンプト）
- **生成先**: `docs/aidlc/` は `prompts/package/` からの rsync コピー（直接編集禁止）。sync-package.sh で同期
- **同期順**: skills/aidlc/ → prompts/package/ → docs/aidlc/

## 変更対象ファイル

### スキルファイル（skills/aidlc/ - 正本）
1. `skills/aidlc/SKILL.md` - Liteルーティングテーブル行削除、Lite条件分岐削除、argument-hintからLite除去
2. `skills/aidlc/CLAUDE.md` - Lite版テーブルセクション削除
3. `skills/aidlc/AGENTS.md` - Lite版テーブルセクション削除

### パッケージプロンプト（prompts/package/ - 正本）
4. `prompts/package/prompts/CLAUDE.md` - Lite版テーブルセクション削除
5. `prompts/package/prompts/AGENTS.md` - Lite版テーブルセクション削除
6. `prompts/package/prompts/lite/inception.md` - ファイル削除
7. `prompts/package/prompts/lite/construction.md` - ファイル削除
8. `prompts/package/prompts/lite/operations.md` - ファイル削除

### ドキュメント（docs/aidlc/ - sync-package.shで自動同期、直接編集禁止）
9-13. sync-package.sh で prompts/package/ から自動反映

### セットアップ系ドキュメント（Lite参照例示の削除）
14. `skills/aidlc/steps/setup/02-generate-config.md` - Lite例示の削除
15. `prompts/setup-prompt.md` - Lite例示の削除

## 実装計画

1. skills/aidlc/SKILL.md のLite関連エントリを削除
2. skills/aidlc/CLAUDE.md、AGENTS.md のLiteテーブルセクション削除
3. prompts/package/prompts/CLAUDE.md、AGENTS.md のLiteテーブルセクション削除
4. Liteプロンプトファイル削除（prompts/package/prompts/lite/ ディレクトリごと削除）
5. セットアップ系ドキュメントのLite例示を削除
6. sync-package.sh で docs/aidlc/ に同期（直接編集しない）
7. 同期結果を検証

## 完了条件チェックリスト

- [ ] SKILL.md/CLAUDE.md/AGENTS.mdからLite版ルーティングテーブル行が削除されていること
- [ ] SKILL.mdのLite条件分岐・argument-hintからLite除去されていること
- [ ] Liteプロンプトファイル（lite/inception.md, lite/construction.md, lite/operations.md）が存在しないこと
- [ ] prompts/package/配下の対応ファイルも同様に更新されていること
- [ ] docs/aidlc/配下がsync-package.shで正しく同期されていること
- [ ] セットアップ系ドキュメントのLite例示が削除されていること
