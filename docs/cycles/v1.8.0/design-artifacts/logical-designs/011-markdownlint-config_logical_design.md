# 論理設計: markdownlint設定対応

## 概要

markdownlint実行を `aidlc.toml` の設定で制御する機能の実装詳細。

## コンポーネント構成

### 1. 設定テンプレート（aidlc_toml_template.toml）

追加するセクション:

```toml
[rules.linting]
# markdownlint設定（v1.8.0で追加）
# markdown_lint: true | false
# - true: markdownlint を実行する
# - false: markdownlint をスキップする（デフォルト）
markdown_lint = false
```

**配置位置**: `[rules.unit_branch]` セクションの後

### 2. 実行スクリプト（prompts/package/bin/run-markdownlint.sh）

**新規作成**: 条件分岐ロジックを含むスクリプト

```bash
#!/usr/bin/env bash
# markdownlint実行スクリプト（設定による制御付き）
# Usage: run-markdownlint.sh <cycle>

set -euo pipefail

CYCLE="${1:?Usage: run-markdownlint.sh <cycle>}"

# 設定確認（デフォルト: false = スキップ）
MARKDOWN_LINT=$(docs/aidlc/bin/get-config.sh rules.linting.markdown_lint false)

if [ "$MARKDOWN_LINT" = "true" ]; then
    echo "markdownlintを実行中..."
    npx markdownlint-cli2 "docs/cycles/${CYCLE}/**/*.md" "prompts/**/*.md" "*.md"
else
    echo "markdownlintはスキップされました（設定: markdown_lint=false）"
fi
```

### 3. プロンプト変更（prompts/package/prompts/construction.md）

**変更箇所**: 行635-640付近（Markdownlint実行セクション）

**変更前**:

```bash
npx markdownlint-cli2 "docs/cycles/{{CYCLE}}/**/*.md" "prompts/**/*.md" "*.md"
```

**変更後**:

```bash
docs/aidlc/bin/run-markdownlint.sh {{CYCLE}}
```

### 4. プロンプト変更（prompts/package/prompts/operations.md）

**変更箇所**: 行802-807付近（Markdownlint実行セクション）

**変更内容**: construction.mdと同様にスクリプト呼び出しに置換

### 5. 現サイクル設定（docs/aidlc.toml）

`[rules.jj]` セクションの後に追加:

```toml
[rules.linting]
# markdownlint設定（v1.8.0で追加）
markdown_lint = false
```

## 動作フロー

```text
1. AIがプロンプトを読み込む
2. markdownlint実行ステップに到達
3. run-markdownlint.sh を呼び出し
4. スクリプト内で get-config.sh により設定値を取得
5. 値が "true" の場合のみ markdownlint を実行
6. "false" または未設定の場合はスキップメッセージを表示
```

## エラーハンドリング

- 設定キーが存在しない場合: 第2引数のデフォルト値 `false` が返される
- get-config.sh が失敗した場合: 第2引数のデフォルト値 `false` が返される
- dasel 未インストールの場合: 空文字が返され、AIが設定ファイルを直接読み取る（フォールバック）

**get-config.sh の仕様**: 第2引数がデフォルト値として機能し、取得失敗時に自動的に返される。

## テスト観点

1. `markdown_lint = true` の場合、markdownlintが実行される
2. `markdown_lint = false` の場合、スキップメッセージが表示される
3. 設定キーが存在しない場合、スキップされる（デフォルト動作）
