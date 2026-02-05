# Unit 001 計画: suggest-version.shバグ修正

## 概要

`suggest-version.sh`がprerelease サフィックス付きバージョン（例: `v2.0.0-alpha.7`）で実行した際にエラーとなる問題を修正する。

## 問題の原因

1. `get_latest_cycle()` が `v2.0.0-alpha.7` のようなディレクトリ名を返す
2. `parse_version()` が `v2.0.0-alpha.7` を `2 0 0-alpha 7` に変換
3. `read -r major minor patch` で `patch = "0-alpha"` になる
4. `$((patch + 1))` で `0-alpha` を評価 → `-alpha` を変数として解釈 → `set -u` でエラー

## 変更対象ファイル

- `prompts/package/bin/suggest-version.sh`（ソース）
- `docs/aidlc/bin/suggest-version.sh` は Operations Phase で rsync 同期

## 実装計画

### 修正方針

`parse_version()` 関数でSemVer拡張部分（prerelease サフィックス `-alpha` 等、ビルドメタデータ `+build` 等）を除去してから処理する。

### 修正内容

```bash
parse_version() {
    local version="$1"
    # SemVer拡張部分を除去（prerelease: -xxx, build metadata: +xxx）
    local base_version
    base_version=$(printf '%s' "$version" | sed 's/^v//' | sed 's/[-+].*//')
    # v1.2.3 -> 1 2 3
    printf '%s' "$base_version" | tr '.' ' '
}
```

**変更点**:
- `cut -d'-' -f1` → `sed 's/[-+].*//'` で `-` と `+` の両方を除去
- `echo` → `printf '%s'` で `-n` 等で始まる値の挙動を安定化

### テスト方針

以下のケースで動作確認:
1. 通常バージョン: `v1.2.3` → 正常動作
2. prerelease付き: `v2.0.0-alpha.7` → 正常動作（サフィックス無視）
3. ビルドメタデータ付き: `v1.2.3+build.5` → 正常動作（メタデータ無視）
4. prerelease+ビルドメタデータ: `v2.0.0-rc.1+build.123` → 正常動作
5. 既存サイクルなし → `v1.0.0` を提案

### スコープ外

- `v` で始まらないサイクル名（例: `feature-xyz`）は `get_latest_cycle()` の対象外（既存仕様）
- prerelease/stable混在時のソート優先順位は既存仕様を維持（今回の修正範囲外）

## 完了条件チェックリスト

- [ ] suggest-version.shのバージョン解析ロジックの修正
- [ ] prereleaseサフィックス（`-alpha`等）をオプショナルとして扱うよう変更
- [ ] ビルドメタデータ（`+build`等）もオプショナルとして扱うよう変更
- [ ] テストケースで動作確認（通常、prerelease、ビルドメタデータ、複合）

## 関連Issue

- #161
