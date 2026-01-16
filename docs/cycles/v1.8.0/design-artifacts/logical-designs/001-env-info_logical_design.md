# 論理設計: 環境情報一覧スクリプト（Unit 001）

## 1. コンポーネント構成

### 1.1 スクリプト構造

```text
env-info.sh
├── show_help()       # ヘルプメッセージ表示
├── check_tool()      # 汎用ツール存在確認関数（dasel, jj, git用）
├── check_gh()        # gh固有の認証確認
└── main()            # エントリポイント（引数解析、出力）
```

**注**: dasel, jj, git は認証不要のため、汎用的な `check_tool()` で対応。
個別関数（check_dasel等）は冗長なため省略。

## 2. インターフェース設計

### 2.1 スクリプト引数

```bash
./env-info.sh [OPTIONS]

OPTIONS:
  -h, --help    ヘルプを表示して終了（終了コード0）
```

**未対応オプションの扱い**:
- 不明なオプションが指定された場合はエラーメッセージを出力し終了コード1で終了
- `--json` は将来の拡張として検討（現時点では未対応オプションとして扱う）

### 2.2 出力形式

**標準出力**:

```text
gh:{status}
dasel:{status}
jj:{status}
git:{status}
```

**終了コード**:
- 0: 正常終了（全ツール確認完了）
- 1: エラー（引数エラー等）

## 3. 関数設計

### 3.1 check_tool(tool_name)

汎用的なツール存在確認。

```bash
# 入力: ツール名
# 出力: "available" または "not-installed"
check_tool() {
    local tool="$1"
    if command -v "$tool" >/dev/null 2>&1; then
        echo "available"
    else
        echo "not-installed"
    fi
}
```

### 3.2 check_gh()

gh固有の認証状態も確認。

```bash
# 出力: "available", "not-installed", または "not-authenticated"
check_gh() {
    if ! command -v gh >/dev/null 2>&1; then
        echo "not-installed"
        return
    fi
    # gh auth status はローカルの認証情報を確認（ネットワーク不要）
    # 認証以外の失敗（設定破損等）も not-authenticated として扱う
    # （診断用途ではないため、詳細な分類は行わない）
    if gh auth status >/dev/null 2>&1; then
        echo "available"
    else
        echo "not-authenticated"
    fi
}
```

**設計判断**: `gh auth status` の失敗理由（認証なし、設定破損、環境変数不備等）を区別せず、すべて `not-authenticated` として扱う。理由は本スクリプトの目的が「利用可能かどうか」の判定であり、詳細な診断は求められていないため。

### 3.3 main()

各ツールを順番にチェックして出力。

```bash
main() {
    echo "gh:$(check_gh)"
    echo "dasel:$(check_tool dasel)"
    echo "jj:$(check_tool jj)"
    echo "git:$(check_tool git)"
}
```

## 4. エラーハンドリング

### 4.1 対応するエラー

| エラー | 対応 |
|--------|------|
| 不正な引数 | エラーメッセージを標準エラー出力に出力、終了コード1 |
| command -v失敗 | not-installedを出力 |
| gh auth status失敗 | not-authenticatedを出力 |

### 4.2 エラーメッセージ

エラーは標準エラー出力に出力：
```bash
echo "Error: {message}" >&2
```

## 5. ファイル配置

```text
prompts/package/bin/
└── env-info.sh    # 実行権限付与（chmod +x）
```

**注**: `prompts/package/bin/` に配置し、rsync同期により `docs/aidlc/bin/` にコピーされる。
呼び出し時は `docs/aidlc/bin/env-info.sh` を使用する。

## 6. 使用例

```bash
# 基本的な使用
$ docs/aidlc/bin/env-info.sh
gh:available
dasel:not-installed
jj:available
git:available

# ヘルプ表示
$ docs/aidlc/bin/env-info.sh --help

# プロンプトからの呼び出し例
ENV_INFO=$(docs/aidlc/bin/env-info.sh)
if echo "$ENV_INFO" | grep -q "gh:available"; then
    echo "GitHub CLI is available"
fi
```

## 7. テスト方針

シェルスクリプトのため、手動テストで確認：

1. **正常系**: 各ツールがインストールされた環境で実行
2. **異常系（gh未認証）**: `gh auth logout` 後に実行
3. **異常系（ツール未インストール）**: PATH から除外して実行

## 8. 将来の拡張性

- `--json` オプションでJSON形式出力
- 追加ツール（node, npm等）の対応
- バージョン情報の出力オプション
