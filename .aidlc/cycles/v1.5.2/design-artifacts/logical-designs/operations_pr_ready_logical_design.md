# 論理設計: Operations Phase 全Unit完了確認とPR Ready化

## 概要
operations.mdプロンプトに全Unit完了確認とドラフトPR Ready化機能を追加するための論理設計。

**重要**: この論理設計では**コードは書かず**、構造とインターフェース定義のみを行います。

## 変更対象

### ファイル
- `prompts/package/prompts/operations.md`

### 変更箇所
1. 「最初に必ず実行すること（5ステップ）」セクションに全Unit完了確認を追加（→6ステップに変更）
2. 「ステップ6: リリース準備」の「6.4 PR作成」をドラフトPR Ready化に変更

## 変更1: 全Unit完了確認ステップの追加

### 追加箇所
- 「最初に必ず実行すること」セクション
- ステップ5（運用引き継ぎ情報の確認）の後に新規ステップ6として追加

### 追加するセクション構造

```
## 最初に必ず実行すること（6ステップ）  ← 5→6に変更

### 1. サイクル存在確認
（既存のまま）

### 2. 追加ルール確認
（既存のまま）

### 3. 進捗管理ファイル確認【重要】
（既存のまま）

### 4. 既存成果物の確認（冪等性の保証）
（既存のまま）

### 5. 運用引き継ぎ情報の確認【重要】
（既存のまま）

### 6. 全Unit完了確認【重要】  ← 新規追加
（新規セクション）
```

### 処理フロー

**ステップ**:
1. Unit定義ファイル一覧を取得
2. 各ファイルの「実装状態」セクションを確認
3. 結果を判定（全完了 or 未完了あり）
4. 結果に応じた表示・分岐

### コマンド設計

```bash
# Unit定義ファイル一覧を取得（番号順）
ls docs/cycles/{{CYCLE}}/story-artifacts/units/ | sort
```

### ユーザーインタラクション設計

#### 全Unit完了の場合

```
全Unitの実装状態を確認しました。

| Unit | 状態 | 完了日 |
|------|------|--------|
| 001 | 完了 | 2024-XX-XX |
| 002 | 完了 | 2024-XX-XX |
...

全Unitが完了しています。Operations Phaseを継続します。
```

#### 未完了Unitがある場合

```
【警告】未完了のUnitがあります。

| Unit | 状態 | 備考 |
|------|------|------|
| 001 | 完了 | - |
| 002 | 進行中 | ← 未完了 |
| 003 | 未着手 | ← 未完了 |

通常、Operations PhaseはすべてのUnitが完了してから開始します。

1. Construction Phaseに戻って未完了Unitを完了させる
2. このまま続行する（非推奨）

どちらを選択しますか？
```

## 変更2: ドラフトPR Ready化への変更

### 変更箇所
- 「ステップ6: リリース準備」の「6.4 PR作成」セクション

### 変更前（現在の構造）

```
#### 6.4 PR作成
mainブランチへのPRを作成:
```bash
gh pr create --base main --title "{{CYCLE}}" --body "..."
```
```

### 変更後

```
#### 6.4 ドラフトPR Ready化【重要】

Inception Phaseで作成したドラフトPRをReady for Reviewに変更します。

**前提条件チェック**:
```bash
# GitHub CLI利用可否と認証状態を確認
if command -v gh &> /dev/null && gh auth status &> /dev/null 2>&1; then
    echo "GITHUB_CLI_AVAILABLE"
else
    echo "GITHUB_CLI_NOT_AVAILABLE"
fi
```

**ドラフトPR検索**:
```bash
# 現在のブランチからのオープンなPRを確認
CURRENT_BRANCH=$(git branch --show-current)
gh pr list --head "${CURRENT_BRANCH}" --state open --json number,url,isDraft
```

**Ready化実行**:
```bash
# ドラフトPRをReady for Reviewに変更
gh pr ready {PR番号}
```

**ドラフトPRが存在しない場合**:
新規PRを作成するか確認し、ユーザーの選択に従う:
```bash
gh pr create --base main --title "{{CYCLE}}" --body "..."
```
```

### 処理フロー

**ステップ**:
1. GitHub CLI利用可否チェック
2. 現在のブランチからのオープンPRを検索
3. 結果に応じた分岐:
   - ドラフトPR存在 → Ready化を提案
   - すでにReady状態のPR存在 → その旨を表示
   - PR存在しない → 新規PR作成を提案
4. ユーザー確認後に実行
5. 結果表示

### ユーザーインタラクション設計

#### ドラフトPR存在時

```
サイクルブランチからのドラフトPRが見つかりました:
- PR #123: [Draft] サイクル v1.5.2
- URL: https://github.com/.../pull/123

このPRをReady for Reviewに変更しますか？

1. はい - Ready for Reviewに変更
2. いいえ - このままにする
```

#### Ready化成功時

```
ドラフトPRをReady for Reviewに変更しました:
- PR #123: サイクル v1.5.2
- URL: https://github.com/.../pull/123

レビューを依頼し、マージしてください。
```

#### ドラフトPR存在しない場合

```
サイクルブランチからのPRが見つかりません。

新規PRを作成しますか？

1. はい - 新規PRを作成
2. いいえ - スキップ（後で手動で作成可能）
```

#### GitHub CLI利用不可時

```
GitHub CLIが利用できません。

手動でPRをReady for Reviewに変更してください:
1. GitHub上でPRを開く
2. 「Ready for review」ボタンをクリック
```

## 非機能要件（NFR）への対応

### パフォーマンス
- **要件**: Unit完了確認は数秒以内、PR Ready化は10秒以内
- **対応策**: ファイルシステムアクセスとgh CLIの直接呼び出しで問題なし

### セキュリティ
- **要件**: GitHub認証の確認
- **対応策**: `gh auth status` で事前確認

### 可用性
- **要件**: GitHub CLI利用不可時は手動操作案内
- **対応策**: 前提条件チェックでスキップパスを用意

### スケーラビリティ
- **要件**: 大量のUnit（50件以上）にも対応
- **対応策**: 単純なファイル一覧取得で問題なし

## 実装上の注意事項
- `prompts/package/prompts/operations.md` を編集（`docs/aidlc/` は編集禁止）
- 「最初に必ず実行すること」のステップ数を5→6に変更
- 既存のセクションへの影響を最小限に抑える
- エラーハンドリングを適切に設計

## 不明点と質問

なし（設計で明確化済み）
