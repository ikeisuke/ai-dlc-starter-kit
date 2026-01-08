# Unit 007 計画: markdownlintルール有効化

## 概要

markdownlintの高優先度ルール（MD009, MD034, MD040）を有効化し、既存のMarkdownファイルをルールに準拠するよう修正する。

## 対象ルール

| ルール | 内容 | 対応方法 |
|--------|------|----------|
| MD009 | 末尾スペース | 末尾の空白を削除 |
| MD034 | 裸URL | リンク形式 `<URL>` または `[text](URL)` に変換 |
| MD040 | コードブロック言語指定 | 言語（markdown, bash, json等）を追加 |

## 実行計画

### Phase 1: 設計

1. **ドメインモデル設計**
   - 修正対象ファイルの特定
   - 各ルール違反の現状調査
   - 修正方針の決定

2. **論理設計**
   - 修正順序の決定
   - ツール利用方針

### Phase 2: 実装

1. **コード生成**
   - `.markdownlint.json` の修正（MD009, MD034, MD040 を有効化）
   - 既存Markdownファイルの修正

2. **テスト生成**
   - markdownlint の実行による検証

3. **統合とレビュー**
   - 全ファイルの lint 通過確認
   - 実装記録の作成

## 修正対象範囲

- `.markdownlint.json`
- `docs/**/*.md`
- `prompts/**/*.md`

## 成果物

- `docs/cycles/v1.5.4/design-artifacts/domain-models/markdownlint-rules_domain_model.md`
- `docs/cycles/v1.5.4/design-artifacts/logical-designs/markdownlint-rules_logical_design.md`
- `docs/cycles/v1.5.4/construction/units/markdownlint-rules_implementation.md`
- 修正されたMarkdownファイル群

## 注意事項

- `docs/aidlc/` は直接編集禁止（rsyncコピー先のため）
- 代わりに `prompts/package/` を編集
