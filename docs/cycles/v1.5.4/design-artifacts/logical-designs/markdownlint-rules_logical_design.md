# markdownlintルール有効化 - 論理設計

## 概要

高優先度ルール（MD009, MD040）を有効化し、既存ファイルを修正する手順を定義。

## コンポーネント構成

### 設定ファイル

- `.markdownlint.json`: ルール設定

### 修正対象ディレクトリ

1. `prompts/package/`: テンプレート・プロンプト（rsync元）
2. `docs/cycles/`: サイクル固有成果物

## 修正手順

### 1. `.markdownlint.json` の修正

```json
{
  "MD009": true,
  "MD034": true,
  "MD040": true
}
```

### 2. prompts/package/ の修正

コードブロックに言語指定を追加：

- `prompts/package/prompts/*.md`
- `prompts/package/templates/*.md`

### 3. docs/cycles/ の修正

末尾スペースの削除とコードブロック言語指定の追加：

- `docs/cycles/*/history/*.md`
- `docs/cycles/*/design-artifacts/**/*.md`
- `docs/cycles/*/plans/*.md`
- その他のMarkdownファイル

## 修正優先順位

1. `prompts/package/` - 今後のセットアップに影響
2. `docs/cycles/v1.5.4/` - 現在のサイクル
3. `docs/cycles/v1.5.3/` - 直近のサイクル
4. その他の過去サイクル

## 検証方法

修正後に以下のコマンドで確認：

```bash
# 末尾スペース確認
grep -rn ' $' docs/ prompts/ --include="*.md" | wc -l

# コードブロック言語なし確認
grep -rn '^```$' docs/ prompts/ --include="*.md" | wc -l
```

## 注意事項

- `docs/aidlc/` は編集しない（rsyncで上書きされる）
- heredoc内のコードブロックは意図的に言語なしの場合あり（確認必要）
