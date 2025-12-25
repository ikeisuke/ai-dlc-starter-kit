# 論理設計: Construction Phase Unit PR作成・マージ

## 概要
construction.mdプロンプトにUnitブランチ作成、PR作成・マージステップを追加するための論理設計。

**重要**: この論理設計では**コードは書かず**、構造とインターフェース定義のみを行います。

## 変更対象

### ファイル
- `prompts/package/prompts/construction.md`

### 追加箇所（2箇所）

#### 1. Unit開始時のブランチ作成
- 「5. 実行前確認」セクションの後にブランチ作成ステップを追加

#### 2. Unit完了時のPR作成・マージ
- 「Unit完了時の必須作業」セクション内（Gitコミットの後、コンテキストリセットの前）

## 追加するセクション構造

### Unit開始時（実行前確認の後）

```
### 5. 実行前確認【重要】
（既存のまま）

### 6. Unitブランチ作成【推奨】  ← 新規追加

GitHub CLI利用可能時、Unitブランチを作成してから作業を開始：
...
```

### Unit完了時の必須作業

```
## Unit完了時の必須作業【重要】

### 1. Unit定義ファイルの「実装状態」を更新
（既存のまま）

### 2. 履歴記録
（既存のまま）

### 3. Gitコミット
（既存のまま）

### 4. Unit PR作成・マージ【推奨】  ← 新規追加
（新規セクション）

### 5. コンテキストリセット【必須】  ← 番号変更（4→5）
（既存のまま）
```

## 処理フロー

### A. Unit開始時のブランチ作成フロー

**ステップ**:
1. GitHub CLI利用可否チェック
2. 現在のブランチがサイクルブランチか確認
3. Unitブランチ名生成（`cycle/vX.X.X/unit-NNN`）
4. ブランチ作成・切り替え
5. リモートへのプッシュ（-u オプション）

### B. Unit完了時のPR作成・マージフロー

**ステップ**:
1. 現在のブランチがUnitブランチか確認
2. 未コミットの変更がないか確認（あればコミット促す）
3. ユーザーへの確認（PR作成するか）
4. PR情報の生成（タイトル・本文）
5. PR作成コマンド実行
6. PR URL表示、レビュー依頼
7. ユーザーによるレビュー完了確認
8. PRマージコマンド実行
9. サイクルブランチに復帰

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

### Unitブランチ作成

```bash
# サイクルブランチから新しいUnitブランチを作成
CYCLE_BRANCH="cycle/{{CYCLE}}"
UNIT_BRANCH="cycle/{{CYCLE}}/unit-{NNN}"

git checkout -b "${UNIT_BRANCH}"
git push -u origin "${UNIT_BRANCH}"
```

### Unit PR作成

```bash
gh pr create \
  --base "cycle/{{CYCLE}}" \
  --title "[Unit {NNN}] {Unit名}" \
  --body "$(cat <<'EOF'
## Unit概要
[Unit定義から抽出した概要]

## 変更内容
[主な変更点]

## テスト結果
[テスト結果サマリ]

---
このPRはサイクルブランチへのマージ用です。
EOF
)"
```

### PRマージ

```bash
# squash mergeでマージし、ブランチを削除
gh pr merge --squash --delete-branch
```

### サイクルブランチへの復帰

```bash
git checkout "cycle/{{CYCLE}}"
git pull origin "cycle/{{CYCLE}}"
```

## ユーザーインタラクション設計

### Unit開始時: ブランチ作成確認

```
Unitブランチを作成しますか？

ブランチ名: cycle/{{CYCLE}}/unit-{NNN}

Unitブランチを使用すると：
- Unit単位でのPRレビューが可能になります
- 並行作業時のコンフリクトを減らせます

1. はい - Unitブランチを作成する（推奨）
2. いいえ - サイクルブランチで直接作業する
```

### Unit完了時: PR作成確認

```
Unit PRを作成しますか？

対象ブランチ: cycle/{{CYCLE}}/unit-{NNN} → cycle/{{CYCLE}}

1. はい - PRを作成してマージする（推奨）
2. いいえ - スキップする（後で手動で作成可能）
```

### PR作成成功時

```
PRを作成しました：
[PR URL]

レビューが完了したら「マージしてください」と入力してください。
（または手動でGitHub上からマージすることもできます）
```

### マージ成功時

```
PRをマージしました。
サイクルブランチに戻りました: cycle/{{CYCLE}}
```

### スキップ時メッセージ

```
Unit PR作成をスキップしました。
必要に応じて、後で以下のコマンドで作成できます：
gh pr create --base "cycle/{{CYCLE}}" --title "[Unit {NNN}] {Unit名}"
```

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: PR作成・マージは各10秒以内
- **対応策**: gh CLIの直接呼び出しで問題なし

### セキュリティ
- **要件**: GitHub認証の確認
- **対応策**: `gh auth status` で事前確認

### スケーラビリティ
- **要件**: 複数Unitの並列PR作成に対応
- **対応策**: ブランチ命名規則で一意性を保証

### 可用性
- **要件**: GitHub CLI利用不可時はスキップ
- **対応策**: 前提条件チェックでスキップパスを用意

## 実装上の注意事項
- `prompts/package/prompts/construction.md` を編集（`docs/aidlc/` は編集禁止）
- PR本文はHEREDOCを使用して複数行を適切に渡す
- 既存のセクション番号を適切に更新する
- Unitブランチ作成は「推奨」として、スキップ可能にする
- マージはユーザーの確認を得てから実行する

## 不明点と質問

なし（設計で明確化済み）
