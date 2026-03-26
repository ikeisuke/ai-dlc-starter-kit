# Unit 001 計画: setup_claude_permissions exit status修正

## 概要

`setup_claude_permissions` 関数が `result="failed"` を設定しても暗黙的に `return 0` で終了するため、呼び出し元の `aidlc-setup.sh` がエラーを検出できない。関数末尾に `result` 変数に基づく非ゼロ return を追加する。

## 変更対象ファイル

- `prompts/package/bin/setup-ai-tools.sh` — `setup_claude_permissions` 関数の末尾に return 文を追加

**注意**: `docs/aidlc/bin/setup-ai-tools.sh` は `prompts/package/` の rsync コピーであるため、直接編集しない。Operations Phase の `/aidlc-setup` 実行時に自動同期される。

## 実装計画

1. `setup_claude_permissions` 関数末尾（`echo "result:${result}"` の後）に、`case "$result"` による明示的な return コードマッピングを追加:
   - `failed` → `return 1`
   - `created` / `updated` / `skipped` / `degraded` → `return 0`（暗黙的に関数終了）
   - 未知値 → `return 1`（安全側に倒す）
2. 既存テストがあれば実行、なければ手動でバグ修正の動作を確認

## 完了条件チェックリスト

- [ ] `setup_claude_permissions` 関数の終了コードを `result` 変数に応じて適切に設定する（case文による明示マッピング）
- [ ] `aidlc-setup.sh` 側で非ゼロ終了コードを検出しエラーメッセージを表示する
- [ ] `setup-ai-tools.sh` が非ゼロ終了し、`aidlc-setup.sh` が `error:setup-ai-tools-failed` で停止するE2E異常系確認
