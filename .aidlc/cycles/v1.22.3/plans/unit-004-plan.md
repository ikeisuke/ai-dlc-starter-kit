# Unit 004 計画: Kiro agent設定のアップデート

## 概要

`.kiro/agents/aidlc-poc.json` をツール権限・リソース参照を含む詳細な設定にアップデートする。

## 変更対象ファイル

- `.kiro/agents/aidlc-poc.json` — JSON設定の更新

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: JSON設定の各フィールド定義
2. **論理設計**: ツール権限・コマンド許可リスト設計
3. **設計レビュー**: AIレビュー実施

### Phase 2: 実装

4. **コード生成**: JSON設定の更新
5. **テスト生成**: JSONバリデーション
6. **統合とレビュー**: AIレビュー実施

## 完了条件チェックリスト

- [ ] `.kiro/agents/aidlc-poc.json` がIssue #344で指定されたJSON設定に更新されている
- [ ] name、description、tools、allowedTools、toolsSettings、resourcesの全フィールドが設定されている
- [ ] `allowedCommands` でコマンド実行範囲が制限されている
- [ ] JSONとして有効である
