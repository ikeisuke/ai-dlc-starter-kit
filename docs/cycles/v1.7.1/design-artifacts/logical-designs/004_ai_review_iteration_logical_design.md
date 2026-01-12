# 論理設計: AIレビュー反復プロセス

## 概要

AIレビューフローに反復プロセスを追加し、設定読み込みパターンを簡略化する。

**重要**: この論理設計では**コードは書かず**、変更箇所と変更内容の定義のみを行います。

## 変更対象の範囲

### 対象ファイル

`prompts/package/prompts/` 配下の以下のファイル:

- construction.md
- inception.md
- operations.md
- setup.md

### 対象外ファイル

- **`docs/aidlc/prompts/*.md`**: `prompts/package/prompts/` からrsyncでコピーされる生成物のため、直接編集しない。Operations PhaseでAI-DLC環境アップグレード時に自動更新される。
- **`prompts/setup-prompt.md`**: 設定セクションの追加と確認のみ行い、設定読み込み処理がないため対象外。

## 変更箇所と変更内容

### 1. AIレビューフロー反復プロセス（construction.md）

#### 変更箇所

`prompts/package/prompts/construction.md` の「AIレビューフロー」セクション

#### 改善内容

反復レビュープロセスを明文化:

```text
- **反復レビュー**（指摘がなくなるまで繰り返す）:
  1. AIレビューを実行
  2. レビュー結果を確認
  3. 指摘があれば修正を反映
  4. 指摘がゼロになるまで1-3を繰り返す
```

**注意**: 「レビュー後コミット」は反復完了後（指摘がゼロになった時点）のみ実行する。反復中の修正はコミットしない。

### 2. 設定読み込みパターン簡略化

#### 設計方針

TOMLファイルはAIエージェントが直接読んで理解すればよい。bashスクリプトで変数に読み込む必要はない。

#### 改善前（複雑なbashスクリプト）

```bash
MCP_REVIEW_MODE=$(grep -A1 "^\[rules.mcp_review\]" docs/aidlc.toml 2>/dev/null | grep "mode" | sed 's/.*"\([^"]*\)".*/\1/' || echo "recommend")
```

#### 改善後（シンプルな指示）

```text
**設定確認**: `docs/aidlc.toml` の `[rules.mcp_review]` セクションを読み、`mode` の値を確認
- `mode = "required"`: AIレビュー必須
- `mode = "recommend"`: AIレビュー推奨（デフォルト）
- `mode = "disabled"`: AIレビューを行わない
```

### 変更サマリ

| ファイル | 変更内容 |
|----------|----------|
| construction.md | MCP_REVIEW_MODE読み込み簡略化、AIレビューフロー反復追加 |
| inception.md | MCP_REVIEW_MODE読み込み簡略化 |
| operations.md | MCP_REVIEW_MODE、CHANGELOG_ENABLED、VERSION_TAG_ENABLED読み込み簡略化 |
| setup.md | WORKTREE_ENABLED読み込み簡略化 |

## 非機能要件への対応

- **パフォーマンス**: N/A（プロンプトファイルの変更のため）
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 実装上の注意事項

1. **AIがTOMLを直接読む**: bashスクリプトで変数に読み込まず、AIエージェントがTOMLファイルを読んで設定値を理解する
2. **視認性重視**: TOMLの可読性を活かしたシンプルな設計
3. **デフォルト値の明記**: 各設定のデフォルト値をプロンプトに明記

## 不明点と質問（設計中に記録）

（なし - 設計は明確）
