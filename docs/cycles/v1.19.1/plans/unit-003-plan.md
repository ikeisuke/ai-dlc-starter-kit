# Unit 003 計画: session-title表示順変更

## 概要

session-titleスキルのタイトル表示順を「プロジェクト / バージョン / フェーズ / ユニット」に変更し、ユニット引数を追加する。

## 変更対象ファイル

1. `prompts/package/skills/session-title/bin/aidlc-session-title.sh` - 引数順・表示フォーマット変更
2. `prompts/package/skills/session-title/SKILL.md` - 引数説明・呼び出し例更新
3. `prompts/package/prompts/inception.md` - 呼び出し箇所の引数順更新
4. `prompts/package/prompts/construction.md` - 呼び出し箇所の引数順更新 + unit引数追加
5. `prompts/package/prompts/operations.md` - 呼び出し箇所の引数順更新

## 実装計画

### Phase 1: 設計

- ドメインモデル: 引数の変更（順序変更 + unit追加）と表示フォーマット定義
- 論理設計: 各ファイルの具体的な変更内容

### Phase 2: 実装

1. `aidlc-session-title.sh` の変更:
   - 引数順: `<project_name> <phase> <cycle>` → `<project_name> <cycle> <phase> [unit]`
   - 表示フォーマット: `PROJECT / CYCLE / PHASE[ / UNIT]`
   - cycle が空/unknown の場合はスキップ
   - unit はオプショナル（Construction Phase でのみ指定）

2. `SKILL.md` の更新:
   - argument-hint の変更
   - 実行方法セクションの引数説明更新
   - スクリプト呼び出し例の更新

3. 各フェーズプロンプトの呼び出し箇所更新:
   - inception.md: 引数順変更
   - construction.md: 引数順変更 + unit引数追加
   - operations.md: 引数順変更

## 完了条件チェックリスト

- [ ] `aidlc-session-title.sh` の引数順と表示フォーマットを変更
- [ ] ユニット引数（オプショナル）を追加
- [ ] SKILL.mdの引数説明・呼び出し例を更新
- [ ] 各フェーズプロンプトの呼び出し箇所の引数順を更新
