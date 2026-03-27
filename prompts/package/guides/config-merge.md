# 設定マージガイド

AI-DLCの設定ファイルは4階層でマージされます。

**重要**: `read-config.sh` は設定値を取得するスクリプトです。単一キーモードとバッチモード（`--keys`）の2つの使用方法があります。以下のマージルールは、特定のキーを問い合わせた際の挙動を説明しています（ファイル全体を事前にマージするわけではありません）。

## 設定ファイルの階層

| ファイル | 用途 | Git管理 | 優先度 |
|----------|------|---------|--------|
| `skills/aidlc/config/defaults.toml`（スクリプト内蔵） | デフォルト値定義 | Yes（スターターキット同梱） | 最低 |
| `~/.aidlc/config.toml` | ユーザー共通設定 | No | 低 |
| `docs/aidlc.toml` | プロジェクト共有設定 | Yes | 中 |
| `docs/aidlc.local.toml` | 個人設定（上書き用） | No（.gitignore） | 高 |

**読み込み順序**: DEFAULTS → HOME → PROJECT → LOCAL（後から読み込んだ値が優先）

## マージルール

### 1. キー単位優先

`.local` にキーが存在すれば、ベース設定を上書きします。

```toml
# docs/aidlc.toml
[rules.reviewing]
mode = "recommend"

# docs/aidlc.local.toml
[rules.reviewing]
mode = "disabled"

# 結果: mode = "disabled"
```

### 2. 配列置換

配列型の値は完全に置換されます（要素のマージはしません）。

```toml
# docs/aidlc.toml
[rules.reviewing]
tools = ["codex", "claude"]

# docs/aidlc.local.toml
[rules.reviewing]
tools = ["gemini"]

# 結果: tools = ["gemini"]
```

### 3. ネスト再帰マージ（葉キーのみ）

テーブル型はキーごとに再帰的にマージされます。

**重要**: これは**葉キー（末端の値）を問い合わせた場合**のみ有効です。親テーブル（例: `rules`）を直接取得した場合は、`.local` に該当テーブルがあれば全体が置換されます。

```toml
# docs/aidlc.toml
[rules]
git = { enabled = true }
worktree = { enabled = false }

# docs/aidlc.local.toml
[rules]
worktree = { enabled = true }

# 葉キーを問い合わせた場合:
# read-config.sh rules.git.enabled → true（ベースから）
# read-config.sh rules.worktree.enabled → true（.localから）

# 親テーブルを問い合わせた場合（非推奨）:
# read-config.sh rules → .local の [rules] 全体が返される
```

### 4. 型不一致時

型が異なる場合、`.local` の値が常に勝ちます。

```toml
# docs/aidlc.toml
[rules]
custom = { enabled = true, level = 3 }

# docs/aidlc.local.toml
[rules]
custom = false

# 結果: rules.custom = false
```

## read-config.sh の使用方法

設定値を取得するスクリプトが用意されています。単一キーモードとバッチモードの2つの使い方があります。

### 単一キーモード

1つの設定値を取得します。

```bash
skills/aidlc/scripts/read-config.sh <key>
```

**使用例**:

```bash
# 設定値を取得
skills/aidlc/scripts/read-config.sh rules.reviewing.mode
# 出力: required（defaults.toml → プロジェクト設定の順でマージ）
```

### バッチモード（--keys）

複数の設定値を一括で取得します。

```bash
skills/aidlc/scripts/read-config.sh --keys <key1> [key2] ...
```

**出力フォーマット**: `key:value` 形式で1行1キー。

**使用例**:

```bash
skills/aidlc/scripts/read-config.sh --keys rules.reviewing.mode rules.squash.enabled rules.worktree.enabled
# 出力:
# rules.reviewing.mode:required
# rules.squash.enabled:true
# rules.worktree.enabled:false
```

**排他制約**:
- `--keys` と位置引数 `<key>` は同時に使用できません

**バッチモードの挙動**:
- 存在しないキーはスキップされます（エラーにならない）
- 全キーが不在の場合は終了コード 1 を返します
- いずれかのキーでエラーが発生した場合は即座に終了コード 2 で終了します（部分出力を防止）

### 終了コード

| コード | 意味 |
|--------|------|
| 0 | 値あり（設定値またはデフォルト値を出力） |
| 1 | キー不在（単一モード: デフォルトなし / バッチモード: 全キー不在） |
| 2 | エラー（dasel未インストール、設定ファイル不正等） |

### 終了コードを使った条件分岐

```bash
if skills/aidlc/scripts/read-config.sh rules.custom.feature; then
    echo "Feature is configured"
else
    echo "Feature is not configured"
fi
```

## .local ファイルの作成例

```toml
# docs/aidlc.local.toml
# このファイルはgitignoreされます

# AIレビューを個人的に無効化 / 独自のAIツール優先順位
[rules.reviewing]
mode = "disabled"
tools = ["claude", "codex"]
```

## ユーザー共通設定の作成

複数プロジェクトで共通の設定を使用したい場合:

```bash
# ディレクトリ作成
mkdir -p ~/.aidlc

# テンプレートから設定ファイル作成
cat > ~/.aidlc/config.toml << 'EOF'
# ユーザー共通設定
# このファイルは全プロジェクトに適用されます

[rules.reviewing]
# mode = "recommend"  # AIレビュー設定

[rules.commit]
# ai_author = "Claude <noreply@anthropic.com>"
EOF
```

## 注意事項

- `docs/aidlc.local.toml` は自動的に `.gitignore` に追加されます
- `.local` ファイルがなくても正常に動作します
- `~/.aidlc/config.toml` がなくても正常に動作します
- `$HOME` 環境変数が未設定の場合、ユーザー共通設定はスキップされます
- `dasel` がインストールされている必要があります（`brew install dasel`）
