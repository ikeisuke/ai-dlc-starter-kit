# 論理設計: CI/CD構築

## 概要

GitHub Actionsワークフローとmarkdownlint設定ファイルの詳細設計。

## 作成ファイル

| ファイル | 用途 |
|---------|-----|
| `.github/workflows/pr-check.yml` | PRチェックワークフロー |
| `.markdownlint.json` | リンター設定 |

## ワークフロー設計

### `.github/workflows/pr-check.yml`

```yaml
name: PR Check

on:
  pull_request:
    branches: [main]
    paths:
      - '**.md'
      - '.markdownlint.json'
      - '.github/workflows/pr-check.yml'

jobs:
  markdown-lint:
    name: Markdown Lint
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Run markdownlint
        uses: DavidAnson/markdownlint-cli2-action@v18
        with:
          globs: |
            docs/**/*.md
            prompts/**/*.md
            *.md
```

### 設計ポイント

1. **paths フィルター**: Markdownファイルや設定変更時のみ実行（効率化）
2. **markdownlint-cli2-action**: 公式推奨のアクション（v18）
3. **globs**: docs/, prompts/, ルートの.mdファイルを対象

## リンター設定設計

### `.markdownlint.json`

```json
{
  "default": true,
  "MD013": false,
  "MD033": false,
  "MD041": false,
  "MD024": {
    "siblings_only": true
  }
}
```

### ルール説明

| ルール | 設定 | 理由 |
|-------|-----|------|
| `default` | true | 基本ルールを全て有効化 |
| `MD013` | false | 行の長さ制限を無効化（日本語で長くなりがち） |
| `MD033` | false | HTML許可（Mermaid等で使用） |
| `MD041` | false | 最初の行がh1でなくても許可（テンプレートの柔軟性） |
| `MD024` | siblings_only | 同一レベルの見出し重複のみ警告（階層が違えばOK） |

## 非機能要件への対応

### パフォーマンス
- paths フィルターで不要な実行を回避
- 通常数秒〜数十秒で完了

### 可用性
- GitHub Actions の可用性に依存
- 失敗時はPRステータスに反映

## 拡張性

将来的に追加可能な機能:
- PRコメントへの詳細結果投稿
- テンプレート整合性チェック
- リンク切れチェック

## 不明点と質問

（なし）
