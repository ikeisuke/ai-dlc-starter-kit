# Unit 001 計画: トークン数ベースサイズチェック

## 概要
`bin/check-size.sh` にトークン数ベースの評価を追加する。ハイブリッド方式（近似計算 + tiktoken）。

## 変更対象ファイル
- `bin/check-size.sh` — トークン数チェック機能追加
- `docs/aidlc.toml` テンプレート — `max_tokens` 設定追加（prompts/package/aidlc.toml.template 等）

## 実装計画
1. `check-size.sh` に以下を追加:
   - `max_tokens` 設定読み込み（デフォルト: 40000）
   - `--tokens-threshold` CLIオプション
   - 近似計算関数（バイト数 + 日本語比率からトークン数概算）
   - tiktoken検出・呼び出し関数
   - `check_file()` にトークン数チェックを統合
2. `docs/aidlc.toml` に `max_tokens = 40000` を追加

## 完了条件チェックリスト
- [x] `check-size.sh` へのトークン数チェック機能追加（近似計算 + tiktoken検出・呼び出し）
- [x] `aidlc.toml` 設定項目（`max_tokens`、デフォルト: 40000）の追加
- [x] CLI オプション（`--tokens-threshold`）の追加
- [x] 異常系処理（設定値不正、tiktoken import失敗時のフォールバック）
