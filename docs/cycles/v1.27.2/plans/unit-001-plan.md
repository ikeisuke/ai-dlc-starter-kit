# Unit 001 計画: warn メッセージ stdout 混入修正

## 概要
`aidlc-setup.sh` の `resolve_starter_kit_root` 関数で warn メッセージが stdout に出力されるバグを修正する。

## 変更対象ファイル
- `prompts/package/skills/aidlc-setup/bin/aidlc-setup.sh` (226行目)

## 実装計画
1. 226行目の `echo "warn:read-config-fallback:using default starter_kit_repo"` に `>&2` を追加

## 完了条件チェックリスト
- [ ] 226行目の `echo "warn:..."` が stderr にリダイレクトされている（`>&2` 追加）
- [ ] `project.starter_kit_repo` 未設定時に `aidlc-setup.sh --dry-run` を実行してパス解決が正常に動作する
- [ ] 既存の正常系の動作に影響がない
