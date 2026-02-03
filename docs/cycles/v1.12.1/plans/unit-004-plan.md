# Unit 004 計画: Construction Phase確認の自動化

## 概要

Construction PhaseのUnit完了時確認（AIレビュー実施確認、Operations引き継ぎ確認）をユーザーへの質問形式からAI自身による自動確認に変更する。

## 関連Issue

- #156

## 変更対象ファイル

- `prompts/package/prompts/construction.md` - Construction Phaseプロンプト

**注意**: メタ開発ルールに従い、`docs/aidlc/prompts/construction.md`ではなく`prompts/package/prompts/construction.md`を編集する。

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: 自動確認ロジックの設計
   - AIレビュー実施確認: 履歴ファイルからの検出パターン
   - 引き継ぎ確認: ディレクトリ存在チェックの仕様

2. **論理設計**: プロンプト変更の詳細設計
   - 0.6セクションの変更内容
   - 0.7セクションの変更内容

### Phase 2: 実装

3. **コード生成**: construction.mdの修正
4. **テスト**: 動作確認

## 完了条件チェックリスト

- [ ] AIレビュー実施確認: 履歴ファイルを読んで自動判断するように変更
- [ ] 引き継ぎ確認: operations/tasks/ディレクトリを確認して自動判断するように変更
- [ ] ユーザーへの不要な質問が削除される
