# 実装記録: サブエージェント活用ガイド

## 実装日時

2026-01-14

## 作成ファイル

### ソースコード

該当なし（ドキュメントのみ）

### テスト

該当なし（ドキュメントのみ）

### ドキュメント

- `prompts/package/guides/subagent-usage.md` - サブエージェント活用ガイド（新規作成）
- `prompts/package/prompts/construction.md` - 気づき記録フローにガイド参照追加

### 設計ドキュメント

- `docs/cycles/v1.7.4/design-artifacts/domain-models/003-subagent-guide_domain_model.md`
- `docs/cycles/v1.7.4/design-artifacts/logical-designs/003-subagent-guide_logical_design.md`

## ビルド結果

成功

```text
Markdownlint: 0 error(s)
```

## テスト結果

該当なし（ドキュメントのみ）

## コードレビュー結果

- [x] セキュリティ: OK（該当なし）
- [x] コーディング規約: OK
- [x] エラーハンドリング: OK（該当なし）
- [x] テストカバレッジ: OK（該当なし）
- [x] ドキュメント: OK

## 技術的な決定事項

- Claude Code専用のガイドとして作成（他ツール非対応を明記）
- 委任可否判断チェックリスト（4項目）を導入
- 並列実行の禁止条件を明確化

## 課題・改善点

- `docs/aidlc/guides/subagent-usage.md` はOperations Phaseのrsyncで反映予定
- 実運用フィードバックに基づく指示テンプレートの拡充

## 状態

**完了**

## 備考

- 関連Issue: #64, #62
