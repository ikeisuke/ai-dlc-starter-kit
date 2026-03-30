# ドメインモデル: markdownlint設定対応

## 概要

markdownlint実行をプロジェクト設定で制御可能にする。CI環境やmarkdownlint未導入プロジェクトでの利便性を向上させる。

## ドメイン概念

### Linting設定

プロジェクトのlintツール実行を制御する設定群。

**属性**:

- `markdown_lint`: markdownlint実行の有効/無効（boolean）
- デフォルト値: `false`（スキップ）

**設計判断**:

- デフォルト `false` の理由: markdownlintはオプション依存であり、未インストール環境でエラーを起こさないため

### 設定の階層

```text
[rules]
└── [linting]
    └── markdown_lint = true | false
```

### 実行スクリプト

`run-markdownlint.sh` として条件分岐ロジックをスクリプト化:

```bash
#!/usr/bin/env bash
# 引数: サイクル名（例: v1.8.0）
CYCLE="${1:?Usage: run-markdownlint.sh <cycle>}"

# 設定確認
MARKDOWN_LINT=$(docs/aidlc/bin/get-config.sh rules.linting.markdown_lint false)

if [ "$MARKDOWN_LINT" = "true" ]; then
    npx markdownlint-cli2 "docs/cycles/${CYCLE}/**/*.md" "prompts/**/*.md" "*.md"
else
    echo "markdownlintはスキップされました（設定: markdown_lint=false）"
fi
```

**メリット**:
- construction.md / operations.md から単純な呼び出しで済む
- 条件分岐ロジックの一元管理
- 将来の変更が1箇所で完結

## 変更対象

| ファイル | 変更内容 |
|----------|----------|
| `prompts/package/templates/aidlc_toml_template.toml` | `[rules.linting]` セクション追加 |
| `prompts/package/bin/run-markdownlint.sh` | 新規作成（条件分岐込み） |
| `prompts/package/prompts/construction.md` | スクリプト呼び出しに置換 |
| `prompts/package/prompts/operations.md` | スクリプト呼び出しに置換 |
| `docs/aidlc.toml` | 現サイクル用に設定追加 |

**注意**: `docs/aidlc/` は `prompts/package/` の rsync コピーのため、正本である `prompts/package/` を編集する。

## 将来の拡張性

`[rules.linting]` セクションは将来の他lintツール対応を想定:

```toml
[rules.linting]
markdown_lint = false
# 将来追加可能:
# eslint = true
# prettier = true
```
