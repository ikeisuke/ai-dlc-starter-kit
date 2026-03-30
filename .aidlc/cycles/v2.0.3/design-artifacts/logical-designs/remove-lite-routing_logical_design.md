# 論理設計: Lite版ルーティング廃止

## 変更パターン

本Unitの変更は3つのパターンに分類される。

### パターン1: テーブル行・セクション削除（編集）

対象ファイルからLite関連のテーブル行またはセクション全体を削除する。

| ファイル | 削除対象 |
|---------|---------|
| skills/aidlc/SKILL.md | ルーティングテーブルのlite行3行、argument-hintのlite部分、Lite条件分岐の説明行 |
| skills/aidlc/CLAUDE.md | 「Lite版を使用する場合」セクション全体 |
| skills/aidlc/AGENTS.md | 「Lite版を使用する場合」セクション全体 |
| prompts/package/prompts/CLAUDE.md | 「Lite版を使用する場合」セクション全体 |
| prompts/package/prompts/AGENTS.md | 「Lite版を使用する場合」セクション全体 |
| docs/aidlc/prompts/CLAUDE.md | sync-package.shで自動反映（直接編集禁止） |
| docs/aidlc/prompts/AGENTS.md | sync-package.shで自動反映（直接編集禁止） |

### パターン2: ファイル・ディレクトリ削除

| 対象 | アクション |
|------|----------|
| prompts/package/prompts/lite/ | ディレクトリごと削除（inception.md, construction.md, operations.md） |
| docs/aidlc/prompts/lite/ | sync-package.shで自動反映（直接編集禁止） |

### パターン3: 例示参照の更新

| ファイル | 変更内容 |
|---------|---------|
| skills/aidlc/steps/setup/02-generate-config.md | Lite例示を削除 |
| prompts/setup-prompt.md | Lite例示を削除 |

## 実行順序

1. パターン1（テーブル行・セクション削除）: skills/aidlc/ → prompts/package/（正本のみ編集）
2. パターン2（ファイル削除）: prompts/package/prompts/lite/ ディレクトリごと削除
3. パターン3（例示更新）
4. sync-package.sh で docs/aidlc/ に同期（直接編集しない）
5. 検証

## 設計判断

- **廃止メッセージ不要**: ユーザー指示により、旧Liteコマンド入力時の廃止メッセージは実装しない（完全撤去）。ルーティングテーブルからエントリを削除するため、AIは未知のコマンドとして扱う
- **docs/aidlc/ 直接編集禁止**: メタ開発ルールに従い、docs/aidlc/ は sync-package.sh による同期で更新する

## 検証方法

削除完了後、以下のコマンドで残存チェック:
```
rg -n 'lite inception|lite construction|lite operations|start lite' skills/aidlc/ prompts/package/ docs/aidlc/
ls prompts/package/prompts/lite/ docs/aidlc/prompts/lite/ 2>/dev/null
```

同期確認:
```
diff -rq prompts/package/prompts/ docs/aidlc/prompts/ --exclude='*.local*'
```
