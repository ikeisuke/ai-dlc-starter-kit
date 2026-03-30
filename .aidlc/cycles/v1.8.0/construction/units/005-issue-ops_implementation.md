# 実装記録: Issue操作スクリプト

## 実装日時

2026-01-17

## 作成ファイル

### ソースコード

- `prompts/package/bin/issue-ops.sh` - Issue操作スクリプト（label, closeサブコマンド）

### 更新ファイル

- `prompts/package/prompts/inception.md` - ラベル付与をスクリプト呼び出しに変更
- `prompts/package/prompts/operations.md` - Issue Closeをスクリプト呼び出しに変更

### 設計ドキュメント

- `docs/cycles/v1.8.0/design-artifacts/domain-models/005-issue-ops_domain_model.md`
- `docs/cycles/v1.8.0/design-artifacts/logical-designs/005-issue-ops_logical_design.md`

## ビルド結果

成功（Bashスクリプトのため特別なビルドは不要）

## テスト結果

成功

- 実行テスト数: 10
- 成功: 10
- 失敗: 0

| テスト | 結果 |
|--------|------|
| `--help` | ヘルプ表示 |
| 引数なし | `error:missing-subcommand` |
| 未知サブコマンド | `error:unknown-subcommand:foo` |
| label引数不足 | `error:missing-issue-number` |
| labelラベル名不足 | `error:missing-label-name` |
| close引数不足 | `error:missing-issue-number` |
| label成功 | `issue:73:labeled:documentation` |
| close成功 | `issue:73:closed` |
| close --not-planned成功 | `issue:73:closed:not-planned` |
| 存在しないIssue | `issue:99999:error:not-found` |

## コードレビュー結果

- [x] セキュリティ: OK（外部コマンド実行は引数を適切にクオート）
- [x] コーディング規約: OK（既存スクリプトとパターン統一）
- [x] エラーハンドリング: OK（全エラーケースで適切な出力）
- [x] テストカバレッジ: OK（主要ケースをカバー）
- [x] ドキュメント: OK（ヘルプ、設計ドキュメント完備）

## 技術的な決定事項

1. **出力形式統一**: すべての出力をstdoutに統一（パイプ処理しやすい）
2. **エラー理由形式**: ハイフン区切り（`not-found`など）で機械処理しやすく
3. **既存スクリプトとの差異**: cycle-label.shはstderrにエラーを出力するが、本スクリプトはstdoutに統一
4. **エラー解析**: ghのエラーメッセージから`not found`/`could not resolve`を検出
5. **exit status取得**: `if ! func`パターンではなく`func; status=$?`パターンを使用（`!`でステータスが反転するため）
6. **引数保護**: Issue番号が`-`で始まる場合のオプション誤認識を防ぐため`gh issue edit --add-label "..." -- "$issue_number"`形式を使用

## 課題・改善点

1. **存在しないラベルへの対応**: ghは存在しないラベルを自動作成せずエラーを返す。設計では「ghの標準動作に委ねる（自動作成される）」としていたが、実際は異なる動作。
2. **パフォーマンス計測**: NFR「5秒以内」の明示的な計測は未実施（手動テストで問題なし）

## 状態

**完了**

## 備考

- テストに使用したIssue #73（AIレビュー設定の改善）はreopenして残存
