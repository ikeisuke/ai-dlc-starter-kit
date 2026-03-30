# 実装記録: 共通ラベル一括初期化スクリプト

## 実装日時

2026-01-17

## 作成ファイル

### ソースコード

- `prompts/package/bin/init-labels.sh` - 共通ラベル一括初期化スクリプト

### プロンプト変更

- `prompts/package/prompts/setup.md` - ラベル作成セクションをスクリプト呼び出しに変更
- `prompts/package/guides/backlog-management.md` - ラベル設定セクションをスクリプト呼び出しに変更

### 設計ドキュメント

- `docs/cycles/v1.8.0/design-artifacts/domain-models/002-init-labels_domain_model.md`
- `docs/cycles/v1.8.0/design-artifacts/logical-designs/002-init-labels_logical_design.md`

## ビルド結果

成功（シェルスクリプトのためビルド不要）

## テスト結果

成功

- `--help` オプション: ヘルプメッセージ正常表示
- `--dry-run` オプション: 11ラベルの状態確認成功
  - `backlog`: exists（既存）
  - 他10ラベル: would-create（作成予定）

```text
$ prompts/package/bin/init-labels.sh --dry-run
label:backlog:exists
label:type:feature:would-create
label:type:bugfix:would-create
label:type:chore:would-create
label:type:refactor:would-create
label:type:docs:would-create
label:type:perf:would-create
label:type:security:would-create
label:priority:high:would-create
label:priority:medium:would-create
label:priority:low:would-create
```

## コードレビュー結果

- [x] セキュリティ: OK（認証情報をスクリプト内に保持しない）
- [x] コーディング規約: OK（env-info.shと同様のスタイル）
- [x] エラーハンドリング: OK（gh未認証時のエラー出力、ラベル作成失敗時の継続処理）
- [x] テストカバレッジ: OK（手動テスト実施）
- [x] ドキュメント: OK（ヘルプメッセージ、設計ドキュメント）

## 技術的な決定事項

1. **既存ラベル一覧の一括取得**: API呼び出し回数を削減するため、`gh label list --json name` で全ラベルを一括取得し、ローカルで完全一致照合
2. **stdout/stderr分離**: 機械可読形式（stdout）と人間可読形式（stderr）を分離
3. **エラー継続処理**: `set -euo pipefail` を使用しつつ、ラベル作成失敗時は `if` 文でエラーをキャッチして継続

## 課題・改善点

- サイクルラベル（`cycle:vX.X.X`）は別スクリプト（Unit 004）で対応予定

## 状態

**完了**

## 備考

- Unit定義に記載されていた色コードと実際のスクリプトの色コードを統一
