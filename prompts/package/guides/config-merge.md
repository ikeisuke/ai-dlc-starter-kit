# 設定マージガイド

AI-DLCの設定ファイル（`docs/aidlc.toml`）と個人設定ファイル（`docs/aidlc.toml.local`）のマージ仕様を説明します。

**重要**: `read-config.sh` は単一キーの値を取得するスクリプトです。以下のマージルールは、特定のキーを問い合わせた際の挙動を説明しています（ファイル全体を事前にマージするわけではありません）。

## 設定ファイルの階層

| ファイル | 用途 | Git管理 |
|----------|------|---------|
| `docs/aidlc.toml` | プロジェクト共有設定 | Yes |
| `docs/aidlc.toml.local` | 個人設定（上書き用） | No（.gitignore） |

## マージルール

### 1. キー単位優先

`.local` にキーが存在すれば、ベース設定を上書きします。

```toml
# docs/aidlc.toml
[rules.mcp_review]
mode = "recommend"

# docs/aidlc.toml.local
[rules.mcp_review]
mode = "disabled"

# 結果: mode = "disabled"
```

### 2. 配列置換

配列型の値は完全に置換されます（要素のマージはしません）。

```toml
# docs/aidlc.toml
[rules.mcp_review]
ai_tools = ["codex", "claude"]

# docs/aidlc.toml.local
[rules.mcp_review]
ai_tools = ["gemini"]

# 結果: ai_tools = ["gemini"]
```

### 3. ネスト再帰マージ（葉キーのみ）

テーブル型はキーごとに再帰的にマージされます。

**重要**: これは**葉キー（末端の値）を問い合わせた場合**のみ有効です。親テーブル（例: `rules`）を直接取得した場合は、`.local` に該当テーブルがあれば全体が置換されます。

```toml
# docs/aidlc.toml
[rules]
git = { enabled = true }
jj = { enabled = false }

# docs/aidlc.toml.local
[rules]
jj = { enabled = true }

# 葉キーを問い合わせた場合:
# read-config.sh rules.git.enabled → true（ベースから）
# read-config.sh rules.jj.enabled → true（.localから）

# 親テーブルを問い合わせた場合（非推奨）:
# read-config.sh rules → .local の [rules] 全体が返される
```

### 4. 型不一致時

型が異なる場合、`.local` の値が常に勝ちます。

```toml
# docs/aidlc.toml
[rules]
custom = { enabled = true, level = 3 }

# docs/aidlc.toml.local
[rules]
custom = false

# 結果: rules.custom = false
```

## read-config.sh の使用方法

設定値を取得するスクリプトが用意されています。

### 基本形式

```bash
docs/aidlc/bin/read-config.sh <key> [--default <value>]
```

### 使用例

```bash
# 設定値を取得
docs/aidlc/bin/read-config.sh rules.mcp_review.mode
# 出力: required

# デフォルト値付き
docs/aidlc/bin/read-config.sh rules.custom.foo --default "bar"
# 出力: bar（キーが存在しない場合）
```

### 終了コード

| コード | 意味 |
|--------|------|
| 0 | 値あり（設定値またはデフォルト値を出力） |
| 1 | キー不在（デフォルトなし、何も出力しない） |
| 2 | エラー（dasel未インストール等） |

### 終了コードを使った条件分岐

```bash
if docs/aidlc/bin/read-config.sh rules.custom.feature; then
    echo "Feature is configured"
else
    echo "Feature is not configured"
fi
```

## .local ファイルの作成例

```toml
# docs/aidlc.toml.local
# このファイルはgitignoreされます

# AIレビューを個人的に無効化
[rules.mcp_review]
mode = "disabled"

# 独自のAIツール優先順位
[rules.mcp_review]
ai_tools = ["claude", "codex"]
```

## 注意事項

- `docs/aidlc.toml.local` は自動的に `.gitignore` に追加されます
- `.local` ファイルがなくても正常に動作します
- `dasel` がインストールされている必要があります（`brew install dasel`）
