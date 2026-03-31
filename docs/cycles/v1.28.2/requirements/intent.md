# Intent（開発意図）

## プロジェクト名
ai-dlc-starter-kit

## 開発の目的
`migrate-config.sh --dry-run` の cleanup trap で `_cleanup_files[@]: unbound variable` エラーが発生し、`exit 1` で終了するバグを修正する。dry-run 実行時に一時ファイルが作成されない経路では `_cleanup_files` 配列が空のまま trap に到達するが、`set -u` (nounset) 下で空配列の展開がエラーとなる。

## ターゲットユーザー
AI-DLC Starter Kit を導入した利用プロジェクトの開発者

## ビジネス価値
利用プロジェクト側の AIDLC アップグレード実行時に `error:migrate-failed` が発生しなくなり、アップグレード体験が改善される。

## スコープ

**含まれるもの**:
- `prompts/package/bin/migrate-config.sh` の `_cleanup` 関数の修正
- 一時ファイル生成あり／なしの両経路での cleanup 正常終了の確認

**除外されるもの**:
- 自動テストの追加（既存のテストフレームワークがないため）
- ドキュメント更新（CHANGELOG は Operations Phase で対応）

## 成功基準
- `migrate-config.sh --dry-run` が cleanup 処理も含めて `exit 0` で正常終了する（一時ファイル未生成経路）
- `_cleanup_files` 配列が空の場合でも `set -u` 下でエラーが発生しない
- 一時ファイルが存在する場合の cleanup 動作に影響がない（一時ファイル生成経路での回帰なし）

## 期限とマイルストーン
パッチリリース（v1.28.2）

## 制約事項
- `prompts/package/bin/migrate-config.sh` のみ修正対象（メタ開発ルールに従う）
- `set -euo pipefail` は維持する
- 既存の cleanup ロジック（一時ファイル削除）の動作を変更しない

## 不明点と質問（Inception Phase中に記録）

なし（Issue #463 に十分な情報が記載されている）
