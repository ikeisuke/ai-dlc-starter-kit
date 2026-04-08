# Branch Protection 設定ガイド

AI-DLCのマージフローでCIチェックを確実に通過させるためのGitHub Branch protection設定手順。

## 前提

- リポジトリの管理者権限が必要
- GitHub Actions等のCIが設定済みであること

## 設定手順

### 1. Branch protection rulesの有効化

1. リポジトリの **Settings → Branches** を開く
2. **Add branch protection rule** をクリック
3. **Branch name pattern** に保護対象ブランチ名を入力（例: `main`）

### 2. Required status checksの設定

1. **Require status checks to pass before merging** を有効化
2. **Require branches to be up to date before merging** を有効化（推奨）
3. 必須チェックを追加（例: `markdownlint`, `bash-substitution-check`）

### 3. Adminバイパスの禁止

1. **Do not allow bypassing the above settings** を有効化
2. これにより管理者もprotection rulesをバイパスできなくなる

### 4. Auto-mergeの有効化

1. リポジトリの **Settings → General** を開く
2. **Pull Requests** セクションの **Allow auto-merge** を有効化
3. これにより `gh pr merge --auto` でCI完了後の自動マージが利用可能になる

## 期待される効果

- CIチェックの確実な実行（adminバイパス防止）
- マージ待ち時間の削減（auto-mergeでCI完了後に自動マージ）
- 保護ルールの一貫した適用
