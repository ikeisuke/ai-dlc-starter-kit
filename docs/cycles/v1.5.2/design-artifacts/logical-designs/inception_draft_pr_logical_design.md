# 論理設計: Inception Phase ドラフトPR作成

## 概要
inception.mdプロンプトにドラフトPR作成ステップを追加するための論理設計。

**重要**: この論理設計では**コードは書かず**、構造とインターフェース定義のみを行います。

## 変更対象

### ファイル
- `prompts/package/prompts/inception.md`

### 追加箇所
- 「完了時の必須作業」セクション内（履歴記録とGitコミットの間）

## 追加するセクション構造

```
## 完了時の必須作業【重要】

### 1. 履歴記録
（既存のまま）

### 2. ドラフトPR作成【推奨】  ← 新規追加
（新規セクション）

### 3. Gitコミット  ← 番号変更（2→3）
（既存のまま）
```

## 処理フロー

### ドラフトPR作成ステップの処理フロー

**ステップ**:
1. GitHub CLI利用可否チェック
2. GitHub認証状態チェック
3. 既存PR確認
4. ユーザーへの確認（作成するか）
5. PR情報の生成（タイトル・本文）
6. ドラフトPR作成コマンド実行
7. 結果表示

## コマンド設計

### 前提条件チェック

```bash
# GitHub CLI利用可否と認証状態を一括チェック
if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    echo "GITHUB_CLI_AVAILABLE"
else
    echo "GITHUB_CLI_NOT_AVAILABLE"
fi
```

### 既存PR確認

```bash
# 現在のブランチから既存のオープンPRがあるか確認
CURRENT_BRANCH=$(git branch --show-current)
gh pr list --head "${CURRENT_BRANCH}" --state open
```

### ドラフトPR作成

```bash
gh pr create --draft \
  --title "[Draft] サイクル {{CYCLE}}" \
  --body "$(cat <<'EOF'
## サイクル概要
[Intentから抽出した概要]

## 含まれるUnit
- Unit 001: [名前]
- Unit 002: [名前]
...

---
このPRはドラフト状態です。Operations Phase完了時にReady for Reviewに変更されます。
EOF
)"
```

## ユーザーインタラクション設計

### 提案メッセージ

```
ドラフトPRを作成しますか？

ドラフトPRを作成すると：
- 進捗がGitHub上で可視化されます
- 複数人での並行作業が容易になります
- Unit単位でのレビューが可能になります

1. はい - ドラフトPRを作成する
2. いいえ - スキップする（後で手動で作成可能）
```

### 成功時メッセージ

```
ドラフトPRを作成しました：
[PR URL]

このPRはOperations Phase完了時にReady for Reviewに変更されます。
```

### スキップ時メッセージ

```
ドラフトPR作成をスキップしました。
必要に応じて、後で以下のコマンドで作成できます：
gh pr create --draft --title "[Draft] サイクル {{CYCLE}}"
```

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: PR作成は10秒以内
- **対応策**: gh CLIの直接呼び出しで問題なし

### セキュリティ
- **要件**: GitHub認証の確認
- **対応策**: `gh auth status` で事前確認

### 可用性
- **要件**: GitHub CLI利用不可時はスキップ
- **対応策**: 前提条件チェックでスキップパスを用意

## 実装上の注意事項
- `prompts/package/prompts/inception.md` を編集（`docs/aidlc/` は編集禁止）
- PR本文はHEREDOCを使用して複数行を適切に渡す
- 既存のセクション番号を適切に更新する

## 不明点と質問

なし（設計で明確化済み）
