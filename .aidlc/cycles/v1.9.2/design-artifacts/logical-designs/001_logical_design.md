# Unit 001 論理設計: サイクル名バリデーション統一

## 変更概要

`write-history.sh`の`validate_version()`関数を`validate_cycle()`に変更し、バリデーションロジックを緩和する。

## 現状

```bash
validate_version() {
    local version="$1"
    if [[ "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        return 0
    else
        return 1
    fi
}
```

## 変更後

```bash
validate_cycle() {
    local cycle="$1"
    # 空文字チェック
    if [[ -z "$cycle" ]]; then
        return 1
    fi
    # パス区切り文字を拒否（ディレクトリトラバーサル防止）
    if [[ "$cycle" == */* ]]; then
        return 1
    fi
    return 0
}
```

## 呼び出し箇所の変更

- L306: `validate_version "$CYCLE"` → `validate_cycle "$CYCLE"`
- L307-308: エラーメッセージを変更

## エラーメッセージ

変更前:
```
Invalid cycle format. Expected vX.X.X (e.g., v1.8.0)
```

変更後:
```
Invalid cycle name. Cannot be empty or contain '/'
```
