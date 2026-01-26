# Unit 003: プレリリースバージョン対応 - 計画

## 概要

`prompts/package/bin/init-cycle-dir.sh` のバージョン形式チェックを緩和し、プレリリースバージョンや任意の文字列を受け入れるようにする。

## 関連Issue

- #88: [Enhancement] init-cycle-dir.sh でプレリリースバージョンをサポート

## 変更対象ファイル

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/bin/init-cycle-dir.sh` | `validate_version()` 関数の修正 |

## 実装計画

### Phase 1: 設計

1. **ドメインモデル設計**: N/A（スクリプト修正のためスキップ）
2. **論理設計**: バリデーション仕様の定義

### Phase 2: 実装

1. `validate_version()` 関数を修正
   - 正規表現チェック（`^v[0-9]+\.[0-9]+\.[0-9]+$`）を削除
   - 空文字チェックのみ残す
   - スラッシュ含有チェックを追加（パス生成の問題回避）
2. ヘルプメッセージの更新
3. テスト実行（手動確認）

## 完了条件チェックリスト

- [ ] バージョン形式の正規表現チェックを削除
- [ ] 空文字チェックのみ残す
- [ ] プレリリースバージョン（例: `v2.0.0-alpha.4`）が受け入れられる
- [ ] 任意の文字列（例: `feature-branch`）が受け入れられる
- [ ] 空文字は拒否される
- [ ] スラッシュを含む文字列は拒否される（パス安全性のため）

## 変更前後の比較

### 変更前（現在）

```bash
validate_version() {
    local version="$1"
    if [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        echo "[error] ${version}: Invalid version format. Expected vX.X.X (e.g., v1.8.0)" >&2
        return 1
    fi
}
```

### 変更後

```bash
validate_version() {
    local version="$1"

    # 空文字チェック
    if [[ -z "$version" ]]; then
        echo "[error] VERSION argument is required" >&2
        return 1
    fi

    # スラッシュ含有チェック（パス生成で問題になるため）
    if [[ "$version" == */* ]]; then
        echo "[error] ${version}: Version cannot contain slashes" >&2
        return 1
    fi

    return 0
}
```
