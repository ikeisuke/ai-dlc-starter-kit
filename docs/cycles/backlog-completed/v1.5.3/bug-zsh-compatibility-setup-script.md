# バグ: setup.md のスクリプトが zsh で動作しない

## 概要

`docs/aidlc/prompts/setup.md` のスターターキットバージョン確認スクリプトが zsh でパースエラーになる。

## 現象

以下のスクリプトを実行すると `parse error near '('` エラーが発生:

```bash
LATEST_VERSION=$(curl -s --max-time 5 https://raw.githubusercontent.com/ikeisuke/ai-dlc-starter-kit/main/version.txt 2>/dev/null | tr -d '\n' || echo "")
CURRENT_VERSION=$(grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml 2>/dev/null || echo "")
echo "最新: ${LATEST_VERSION:-取得失敗}, 現在: ${CURRENT_VERSION:-なし}"
```

## 原因

- `grep -oP` の `-P` オプション（Perl正規表現）は macOS の grep ではサポートされていない
- zsh の複合コマンド実行時に構文解析エラーが発生

## 対処方針

1. `grep -oP` を `grep -E` + `sed` または `awk` に置き換える
2. スクリプトを bash/zsh 両方で動作するよう修正

## 修正例

```bash
# 修正前
grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml

# 修正後
grep -E 'starter_kit_version\s*=\s*"[^"]+"' docs/aidlc.toml | sed 's/.*"\([^"]*\)".*/\1/'
```

## 影響範囲

- `docs/aidlc/prompts/setup.md`
- `prompts/setup-prompt.md`（同様のスクリプトがあれば）

## 優先度

中 - セットアップ時にワークアラウンドは可能だが、UX改善のため修正が望ましい
