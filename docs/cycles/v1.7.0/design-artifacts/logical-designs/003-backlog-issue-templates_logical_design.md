# 論理設計: バックログ用Issueテンプレート

## 概要

GitHub Issueテンプレートの配置構成と、セットアッププロンプトへのコピー処理追加を設計する。

**重要**: この論理設計では**コードは書かず**、構成とインターフェース定義のみを行います。

## ファイル配置設計

### スターターキット側（ソース）

```text
prompts/
├── package/
│   └── .github/
│       └── ISSUE_TEMPLATE/
│           ├── backlog.md      # バックログ用テンプレート
│           ├── bug.md          # バグ報告用テンプレート
│           └── feature.md      # 機能要望用テンプレート
└── setup-prompt.md             # コピー処理追加対象
```

### プロジェクト側（デスティネーション）

```text
.github/
└── ISSUE_TEMPLATE/
    ├── backlog.md
    ├── bug.md
    └── feature.md
```

## テンプレートファイル設計

### 共通フォーマット

各テンプレートはGitHubのIssueテンプレート形式に従う:

```markdown
---
name: [表示名]
about: [説明文]
title: "[PREFIX] "
labels: [ラベル名]
assignees: ''
---

[本文]
```

### backlog.md

- **name**: "Backlog"
- **about**: "Record a task or idea for future implementation"
- **title**: "[Backlog] "
- **labels**: "backlog"
- **本文構成**:
  - Summary（必須）
  - Details（任意）
  - Discovery Context
    - Cycle
    - Phase
  - Priority（High / Medium / Low）
  - Proposed Solution

### bug.md

- **name**: "Bug Report"
- **about**: "Report a bug or unexpected behavior"
- **title**: "[Bug] "
- **labels**: "bug"
- **本文構成**:
  - Bug Summary（必須）
  - Steps to Reproduce
  - Expected Behavior
  - Actual Behavior
  - Environment（任意）

### feature.md

- **name**: "Feature Request"
- **about**: "Suggest a new feature or enhancement"
- **title**: "[Feature] "
- **labels**: "enhancement"
- **本文構成**:
  - Feature Summary（必須）
  - Motivation / Use Case
  - Proposed Solution
  - Alternatives Considered（任意）

## セットアッププロンプト修正設計

### 追加位置

`prompts/setup-prompt.md` の「8. 共通ファイルの配置」セクションに、「8.2.4」の後、「8.3」の前に新しいサブセクションを追加。

### 追加セクション名

`8.2.5 GitHub Issueテンプレートのコピー`

### 処理フロー

```text
1. プロジェクトの .github/ISSUE_TEMPLATE/ 状態確認
2. 状態に応じた処理分岐
   a. ディレクトリが存在しない → 新規作成
   b. 同名ファイルが存在 → ユーザー確認
   c. 同名ファイルが存在しない → コピー
3. 結果報告
```

### 状態確認コマンド

```bash
# .github/ISSUE_TEMPLATE/ の存在と内容確認
if [ -d ".github/ISSUE_TEMPLATE" ]; then
    ls -la .github/ISSUE_TEMPLATE/
    echo "ISSUE_TEMPLATE_EXISTS"
else
    echo "ISSUE_TEMPLATE_NOT_EXISTS"
fi
```

### コピー処理設計

#### ケース1: ディレクトリが存在しない

```bash
mkdir -p .github/ISSUE_TEMPLATE
cp [スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/*.md .github/ISSUE_TEMPLATE/
```

#### ケース2: 同名ファイルが存在する場合

**ユーザー確認メッセージ**:
```text
警告: 以下のIssueテンプレートが既に存在します：

[既存ファイル一覧]

選択してください:
1. 上書きする
2. スキップする（既存を保持）
3. 個別に確認する

どれを選択しますか？
```

#### ケース3: 同名ファイルが存在しない

```bash
# 存在しないファイルのみコピー
for file in backlog.md bug.md feature.md; do
    if [ ! -f ".github/ISSUE_TEMPLATE/$file" ]; then
        cp "[スターターキットパス]/prompts/package/.github/ISSUE_TEMPLATE/$file" ".github/ISSUE_TEMPLATE/"
    fi
done
```

### 結果報告

```text
GitHub Issueテンプレートの配置が完了しました：

| ファイル | 状態 |
|----------|------|
| backlog.md | [新規作成 / スキップ / 上書き] |
| bug.md | [新規作成 / スキップ / 上書き] |
| feature.md | [新規作成 / スキップ / 上書き] |
```

## 非機能要件への対応

### 可用性

- **要件**: GitHub CLI非依存
- **対応**: テンプレートのコピーは標準シェルコマンド（cp, mkdir）のみ使用
- **補足**: Issue作成・連携機能はUnit 005で別途実装

## 技術選定

- **テンプレート形式**: Markdown + YAML フロントマター
- **コピー処理**: シェルスクリプト（bash）
- **依存**: なし（標準コマンドのみ）

## 実装上の注意事項

- テンプレートファイル名はGitHubの規約に従う
- フロントマターのYAML構文エラーに注意（GitHubでパースエラーになる）
- `labels` に指定したラベルは、Issue作成時に自動付与されるが、存在しないラベルは無視される
- `assignees` は空文字列にしておく（リポジトリごとにユーザーが異なるため）

## 不明点と質問

（なし - 設計に必要な情報は揃っている）
