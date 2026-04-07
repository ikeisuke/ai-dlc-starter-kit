# Unit 006 計画: UTF-8文字化け自動検知

## 対象Unit

Unit 006: UTF-8文字化け自動検知（#537）

## 目的

PostToolUse hookでWriteツール実行後にU+FFFD（置換文字）を検出し、文字化けを早期に警告する。書き込み自体は阻害しない。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `bin/check-utf8-corruption.sh`（新規） | U+FFFD検出スクリプト |
| `.claude/settings.json` | PostToolUse hook設定追加 |

## 設計方針

### check-utf8-corruption.sh

- 標準入力からPostToolUseのhookデータ（JSON）を受け取る
- `tool_name` が `Write` でない場合はexit 0で終了
- `tool_input.file_path` からファイルパスを取得
- バイナリファイルはスキップ（`file` コマンドで判定）
- `LC_ALL=C grep -c '�'` でU+FFFDを検出
- 検出時: 警告メッセージを stderr に出力（exit 0 で書き込みを阻害しない）
- 未検出時: exit 0

### settings.json

PostToolUse hookを追加。matcher で `Write` ツールのみを対象:

```json
{
  "matcher": "Write",
  "hooks": [{
    "type": "command",
    "command": "bin/check-utf8-corruption.sh"
  }]
}
```

## 完了条件チェックリスト

- [ ] bin/check-utf8-corruption.sh が作成され実行権限が付与されている
- [ ] Writeツール以外では hook が発火しない
- [ ] バイナリファイルではチェックをスキップする
- [ ] U+FFFD検出時に警告が表示される
- [ ] U+FFFD未検出時は何も出力されない
- [ ] 書き込み自体を阻害しない（常にexit 0）
- [ ] .claude/settings.json にPostToolUse hookが追加されている
