# Unit 001 計画: 「人間レビュー」→「ユーザーレビュー」用語変更

## 概要

`prompts/package/prompts/**/*.md` 配下の全プロンプトで「人間」を含むレビュー・承認関連の用語を「ユーザー」に統一する。

## 変更対象ファイル

| ファイル | 件数 |
|---------|------|
| prompts/package/prompts/common/review-flow.md | 22 |
| prompts/package/prompts/common/commit-flow.md | 2 |
| prompts/package/prompts/common/rules.md | 1 |
| prompts/package/prompts/common/intro.md | 1 |
| prompts/package/prompts/operations.md | 1 |
| prompts/package/prompts/inception.md | 1 |
| prompts/package/prompts/construction.md | 1 |
| prompts/package/prompts/CLAUDE.md | 1 |
| prompts/package/prompts/lite/inception.md | 1 |
| prompts/package/prompts/lite/construction.md | 1 |
| **合計** | **32** |

## 実装計画

### 置換マップ

| 置換前 | 置換後 |
|--------|--------|
| 人間レビュー | ユーザーレビュー |
| 人間に承認 | ユーザーに承認 |
| 人間に提示 | ユーザーに提示 |
| 人間の承認 | ユーザーの承認 |
| 人間への承認提示 | ユーザーへの承認提示 |
| 人間承認 | ユーザー承認 |
| 人間が承認 | ユーザーが承認 |

### 対象外語彙（置換しない）

| 語彙 | 理由 |
|------|------|
| 人間中心 | 従来SDLCの特性を説明する概念用語であり、ユーザー役割を指すものではない |

### 手順

1. **設計省略**: 文言変更のみのため、ドメインモデル・論理設計は省略
2. **一括置換**: 上記置換マップに基づき、10ファイルの32箇所を置換
3. **文脈確認**: 各置換後の文が自然であることを目視確認
4. **検証**: `grep -rE "人間レビュー|人間に承認|人間に提示|人間の承認|人間への承認提示|人間承認|人間が承認" prompts/package/prompts/` で0件を確認
5. **対象外確認**: `grep -r "人間" prompts/package/prompts/` の残存が対象外語彙のみであることを確認

## 完了条件チェックリスト

- [ ] `prompts/package/prompts/**/*.md` 配下の全ファイルで置換マップに記載した7パターンを対応するユーザー用語に置換
- [ ] 置換後の文脈が自然であることの確認
