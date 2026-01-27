# ドメインモデル: PRによるIssue自動Close機能

## 概要

Operations PhaseのPR作成時に、対応するIssue番号を自動的にPR本文に含め、マージ時に自動Closeされるようにする。

## ドメインエンティティ

### IssueReference（値オブジェクト）

PR本文に記載するIssue参照情報

**属性**:
- `issueNumber`: Issue番号（整数）
- `keyword`: Close用キーワード（`Closes`）

**振る舞い**:
- `format()`: `Closes #[番号]` 形式の文字列を生成

### IssueSource（列挙型）

Issue番号の取得元

**値**:
- `INTENT`: `docs/cycles/{{CYCLE}}/requirements/intent.md`
- `SETUP_CONTEXT`: `docs/cycles/{{CYCLE}}/requirements/setup-context.md`

## ドメインルール

1. **Issue番号取得の優先順位**:
   - intent.md の「対象Issue」セクションを優先
   - なければ setup-context.md を参照

2. **複数Issue対応**:
   - 複数のIssueがある場合、各Issueを別行で記載
   - フォーマット: 各行に `Closes #[番号]`

3. **Issue不在時の処理**:
   - Issue番号が見つからない場合、「Closes」セクション自体を省略

## 境界

- PRマージ後の実際のClose処理はGitHub標準機能に委譲
- Issue番号の自動取得は指定された2ファイルからの参照に限定
