# ドメインモデル: Unit 2 - GitHub Issue確認とセットアップ統合

## 概要

Inception Phase開始時にGitHub Issueを確認し、ブランチ作成を確実に提案する機能を追加。このUnitはプロンプト編集のみで実装コードは書かないため、ドメインモデルは簡略化。

**重要**: このドメインモデル設計では**コードは書かず**、構造と責務の定義のみを行います。

## ドメイン概念

### 1. ブランチ確認フロー

- **責務**: 現在のGitブランチを確認し、main/masterの場合はサイクル用ブランチの作成を提案
- **トリガー**: Inception Phase開始時（ステップ1の冒頭）
- **判定ロジック**:
  - 現在のブランチ名を取得（`git branch --show-current`）
  - main または master の場合 → ブランチ作成を提案
  - それ以外 → 次のステップへ進行

### 2. GitHub Issue確認フロー

- **責務**: GitHub CLIを使用してオープンなIssueを取得・表示し、対応要否を確認
- **トリガー**: Dependabot PR確認（ステップ2.5）の後
- **判定ロジック**:
  - GitHub CLI利用可否を確認
  - オープンなIssueを取得（`gh issue list --state open`）
  - 結果に応じてユーザーに確認

## 振る舞い定義

### ブランチ確認

```
IF 現在のブランチ = "main" OR "master" THEN
    提案: "サイクル用ブランチを作成しますか？"
    IF ユーザー承認 THEN
        git checkout -b cycle/{{CYCLE}}
    END IF
END IF
```

### Issue確認

```
IF GitHub CLI 利用不可 THEN
    SKIP
ELSE IF オープンなIssue = 0件 THEN
    表示: "オープンなIssueはありません"
ELSE
    表示: Issue一覧
    質問: "これらのIssueを今回のサイクルで対応しますか？"
END IF
```

## ユビキタス言語

- **サイクル用ブランチ**: `cycle/vX.X.X` 形式のブランチ名
- **オープンなIssue**: GitHub上で未解決のIssue
- **SKIP**: GitHub CLI未認証時などに処理をスキップすること

## 不明点と質問

なし（既存のDependabot PR確認フローを参考にするため明確）
