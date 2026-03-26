# 実装記録: フェーズ内操作順序の明示化

## 実装日時

2026-03-14 〜 2026-03-15

## 作成ファイル

### ソースコード

- `prompts/package/prompts/common/commit-flow.md` - 操作順序ルールセクションの追加（L108-L135）

### テスト

- N/A（プロンプトドキュメントの追記のみ。markdownlintで構文検証済み）

### 設計ドキュメント

- `docs/cycles/v1.22.0/design-artifacts/domain-models/operation_order_rules_domain_model.md`
- `docs/cycles/v1.22.0/design-artifacts/logical-designs/operation_order_rules_logical_design.md`

## ビルド結果

成功

```text
markdownlint-cli2: 79 file(s), 0 error(s)
```

## テスト結果

N/A（プロンプトドキュメントのため自動テスト対象外）

## コードレビュー結果

- [x] セキュリティ: OK
- [x] コーディング規約: OK
- [x] エラーハンドリング: OK
- [x] テストカバレッジ: N/A
- [x] ドキュメント: OK

## 技術的な決定事項

- Phase遷移の順序制約はcommit-flow.mdのスコープ外とし、各フェーズプロンプトへの参照リンクで対応
- recommendモードでのAIレビュースキップ承認も「フロー完了」として扱う
- squash:success時のUnit完了コミットスキップを順序制約に明記

## 課題・改善点

なし

## 状態

**完了**
