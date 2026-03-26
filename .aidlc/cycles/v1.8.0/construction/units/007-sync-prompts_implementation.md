# 実装記録: rsync同期スクリプト

## 実装日時

2026-01-17 22:10 〜 2026-01-17 22:16

## 作成ファイル

### ソースコード

- `prompts/package/bin/sync-prompts.sh` - prompts/package配下の4ディレクトリをdocs/aidlc/に一括同期するスクリプト

### テスト

手動テストを実施（自動テストなし）

### 設計ドキュメント

- `docs/cycles/v1.8.0/design-artifacts/domain-models/sync-prompts_domain_model.md`
- `docs/cycles/v1.8.0/design-artifacts/logical-designs/sync-prompts_logical_design.md`

## ビルド結果

成功（シェルスクリプトのためビルド不要）

## テスト結果

成功

- 実行テスト数: 5
- 成功: 5
- 失敗: 0

```text
テスト1: --help オプション → 正常にヘルプ表示
テスト2: --dry-run オプション → 4ターゲット全てwould-sync出力
テスト3: --only prompts,guides → 2ターゲットのみ処理
テスト4: --dest /tmp/sync-test/ → 指定先に同期
テスト5: 実際の同期 → 4ディレクトリ全て正常同期
```

## コードレビュー結果

- [x] セキュリティ: OK（ローカルファイル操作のみ）
- [x] コーディング規約: OK（既存スクリプトと一貫したスタイル）
- [x] エラーハンドリング: OK（rsync未インストール時のエラー、同期失敗時のエラー出力）
- [x] テストカバレッジ: OK（主要機能の手動テスト完了）
- [x] ドキュメント: OK（--helpでの使用方法表示）

## 技術的な決定事項

1. **rsyncオプション**: `-a --delete -v` を採用
   - `-a`: アーカイブモード（パーミッション・タイムスタンプ保持）
   - `--delete`: 同期元にないファイルは削除
   - `-v`: 詳細出力
   - `-n`: dry-runモード時に追加
2. **出力形式**: 既存スクリプト（init-labels.sh等）と一貫した `sync:<target>:<status>` 形式
3. **末尾スラッシュ処理**: --dest で末尾スラッシュがない場合は自動付与
4. **--onlyバリデーション**: 無効なターゲット名を検出してエラー終了

## AIレビュー指摘と修正

| 指摘 | 対応 |
|------|------|
| 終了コードが2（設計は1） | exit 1 に修正 |
| dry-runがrsync -nを実行しない | rsync -nを実行するよう修正 |
| --onlyで無効ターゲットを受け入れる | validate_only_targets関数を追加 |
| dry-run時のrsync失敗が成功扱い | エラー処理を追加 |
| parse_args()関数が存在しない | parse_args()関数を切り出し |
| dry-runで同期先ディレクトリ未作成 | dry-run前にmkdir -pを実行 |

## 課題・改善点

なし

## 状態

**完了**

## 備考

- このスクリプトは `prompts/setup-prompt.md` から呼び出されることを想定
- Unit定義で言及されていた「プロンプト内のrsyncをスクリプト呼び出しに置換」は別途対応が必要（スコープ外）
