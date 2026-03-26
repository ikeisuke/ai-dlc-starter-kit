# 論理設計: Unit 2 - GitHub Issue確認とセットアップ統合

## 概要

`prompts/package/prompts/inception.md` への変更を定義。ブランチ確認とGitHub Issue確認の2つの機能を追加。

**重要**: このUnitはプロンプト編集のみで、実装コードは書きません。

## 設計方針

**ブランチ確認の二重化**:
- `setup-cycle.md` と `inception.md` の両方でブランチ確認を行う
- setup-cycle.md 経由の場合: setup-cycle.md でチェック → inception.md で再チェック（冗長だが安全）
- inception.md 直接の場合: inception.md でチェック（フォールバック）

**将来の構造改善**: Setup Phase 新設によりセットアップ処理を独立させる案はバックログに記録済み

## コンポーネント構成

### 編集対象ファイル

`prompts/package/prompts/inception.md`

> **注**: `setup-cycle.md` は変更しない（既にブランチ確認機能あり）

### 変更箇所

| # | 変更内容 | 挿入位置 |
|---|---------|---------|
| 1 | ブランチ確認 | ステップ1の冒頭（サイクル存在確認の前） |
| 2 | GitHub Issue確認 | ステップ2.5（Dependabot PR確認）の後、ステップ2.7として追加 |

## 詳細設計

### 変更1: ブランチ確認（ステップ1冒頭に追加）

**挿入位置**: 「### 1. サイクル存在確認」の直前

**追加内容**:

```markdown
### 0. ブランチ確認【推奨】

現在のブランチを確認し、サイクル用ブランチでの作業を推奨：

```bash
CURRENT_BRANCH=$(git branch --show-current)
echo "現在のブランチ: ${CURRENT_BRANCH}"
```

**判定**:
- **main または master の場合**: サイクル用ブランチの作成を提案
  ```
  現在 main/master ブランチで作業しています。
  サイクル用ブランチを作成しますか？

  1. はい - `cycle/{{CYCLE}}` ブランチを作成
  2. いいえ - このまま続行（非推奨）
  ```
  - **1を選択**: `git checkout -b cycle/{{CYCLE}}` を実行
  - **2を選択**: 警告を表示して続行
- **それ以外のブランチ**: 次のステップへ進行
```

### 変更2: GitHub Issue確認（ステップ2.7として追加）

**挿入位置**: ステップ2.5（Dependabot PR確認）の後

**追加内容**:

```markdown
### 2.7. GitHub Issue確認

GitHub CLIでオープンなIssueの有無を確認：

```bash
# GitHub CLIの利用可否確認と Issue一覧取得
if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    gh issue list --state open --limit 10
else
    echo "SKIP: GitHub CLI not available or not authenticated"
fi
```

**判定**:
- **SKIP（GitHub CLI利用不可）**: 次のステップへ進行
- **Issueが0件**: 「オープンなIssueはありません。」と表示し、次のステップへ進行
- **Issueが1件以上**: 以下の対応確認を実施

**対応確認**（Issueが存在する場合）:
```
以下のオープンなIssueがあります：

[Issue一覧表示]

これらのIssueを今回のサイクルで対応しますか？
1. はい - ユーザーストーリーとUnit定義に追加する
2. いいえ - 今回は対応しない
```

- **1を選択**: 選択されたIssueをユーザーストーリーとUnit定義に追加することを案内
- **2を選択**: 次のステップへ進行
```

## 依存関係

- **外部依存**: GitHub CLI（gh コマンド）
- **内部依存**: 既存のDependabot PR確認フロー（ステップ2.5）のパターンを踏襲

## 非機能要件

- **パフォーマンス**: GitHub API呼び出しはgh コマンドのデフォルトタイムアウトを使用
- **可用性**: GitHub CLI未認証時はスキップして続行可能

## 不明点と質問

なし
