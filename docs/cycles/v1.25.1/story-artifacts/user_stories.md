# ユーザーストーリー

## Epic: サイズチェックのトークン数ベース化

### ストーリー 1: トークン数ベースの閾値チェック（ハイブリッド方式）
**優先順位**: Must-have

As a AI-DLC利用者
I want to プロンプトファイルのサイズをトークン数で評価したい
So that LLMのコンテキスト制約に直結する指標で管理できる

**受け入れ基準**:
- [ ] `check-size.sh` が `max_tokens`（デフォルト: 40000）閾値でファイルをチェックし、超過時に警告を出力する
- [ ] tiktoken未インストール時はバイト数と文字種比率からの近似計算でトークン数を算出し、出力に `(estimated)` と表示する
- [ ] tiktoken利用可能時は `tiktoken`（cl100k_base）で正確なトークン数を計測する
- [ ] `docs/aidlc.toml` の `[rules.size_check]` セクションに `max_tokens` 設定を追加できる
- [ ] CLIオプション `--tokens-threshold N` で閾値を一時的に上書きできる
- [ ] 既存の `max_bytes` / `max_lines` チェックは引き続き動作する（後方互換性）
- [ ] `max_tokens` に非数値が設定された場合、エラーメッセージを出力し終了コード2で終了する
- [ ] Pythonはあるがtiktokenが import 失敗した場合、近似計算にフォールバックする（警告表示あり）
