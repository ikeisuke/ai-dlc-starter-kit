# 論理設計: 名前付きサイクル履歴修正

## 変更箇所

### prompts/package/bin/write-history.sh

#### validate_cycle() 関数（L92-101）

**現在の実装**:
```bash
validate_cycle() {
    local cycle="$1"
    if [[ -z "$cycle" ]]; then
        return 1
    fi
    if [[ "$cycle" == */* ]]; then
        return 1
    fi
    return 0
}
```

**修正後**:
```bash
validate_cycle() {
    local cycle="$1"
    if [[ -z "$cycle" ]]; then
        return 1
    fi
    # パストラバーサル防止（setup-branch.shと同じアプローチ）
    if [[ "$cycle" == *..* ]]; then
        return 1
    fi
    if [[ ! "$cycle" =~ ^([a-z0-9][a-z0-9-]*/)?v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
        return 1
    fi
    return 0
}
```

#### エラーメッセージ（L322）

**現在**:
```bash
echo "error:Invalid cycle name. Cannot be empty or contain '/'" >&2
```

**修正後**:
```bash
echo "error:Invalid cycle name. Expected format: vX.Y.Z, vX.Y.Z-prerelease, name/vX.Y.Z, or name/vX.Y.Z-prerelease" >&2
```

## テストケース

| 入力 | 期待結果 | 説明 |
|------|---------|------|
| `v1.21.1` | 成功（0） | 通常形式 |
| `waf/v1.0.0` | 成功（0） | 名前付き形式 |
| `my-project/v2.0.0` | 成功（0） | ハイフン含む名前 |
| `v1.0.0-rc.1` | 成功（0） | prerelease付き |
| `waf/v1.0.0-beta` | 成功（0） | 名前付き+prerelease |
| `` (空) | 失敗（1） | 空文字 |
| `../v1.0.0` | 失敗（1） | パストラバーサル（`..`チェック） |
| `v1.0.0-..` | 失敗（1） | パストラバーサル（`..`チェック） |
| `foo/bar/v1.0.0` | 失敗（1） | 多重スラッシュ |
| `FOO/v1.0.0` | 失敗（1） | 大文字名 |
| `hello world` | 失敗（1） | スペース含む |
| `/v1.0.0` | 失敗（1） | 先頭スラッシュ |
