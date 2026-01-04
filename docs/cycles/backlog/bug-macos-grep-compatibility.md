# macOS の grep 互換性問題

- **発見日**: 2026-01-05
- **発見フェーズ**: サイクルセットアップ
- **発見サイクル**: v1.5.3 準備中
- **優先度**: 高

## 概要

setup.md のバージョン確認スクリプトで使用している `grep -oP` オプションが macOS で動作しない。

## 詳細

setup.md のステップ1（スターターキットバージョン確認）で以下のコマンドが使われている:

```bash
CURRENT_VERSION=$(grep -oP 'starter_kit_version\s*=\s*"\K[^"]+' docs/aidlc.toml 2>/dev/null || echo "")
```

- `-P` (Perl正規表現) オプションは GNU grep 固有の機能
- macOS はデフォルトで BSD grep を使用するため、このオプションをサポートしていない
- 結果として、macOS ユーザーは常にバージョン取得に失敗する

## 対応案

POSIX互換のコマンドに置き換える:

```bash
# 案1: awk を使用
CURRENT_VERSION=$(awk -F'"' '/starter_kit_version/ {print $2}' docs/aidlc.toml 2>/dev/null || echo "")

# 案2: sed を使用
CURRENT_VERSION=$(grep 'starter_kit_version' docs/aidlc.toml 2>/dev/null | sed 's/.*"\([^"]*\)".*/\1/' || echo "")
```

## 影響範囲

- `docs/aidlc/prompts/setup.md` - ステップ1のバージョン確認スクリプト
- すべての macOS ユーザー
