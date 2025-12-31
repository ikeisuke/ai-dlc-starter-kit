# 機能: AI側でworktreeを作成する

- **発見日**: 2025-12-27
- **発見フェーズ**: Setup
- **発見サイクル**: v1.5.2
- **優先度**: 中

## 概要

サイクル開始時にworktreeを選択した場合、AIが自動でworktreeを作成し、新しいディレクトリに移動してセットアップを継続する。

## 現状

1. ユーザーがworktreeを選択
2. AIがコマンドを提示
3. ユーザーが手動で実行
4. ユーザーが新しいディレクトリで新しいセッションを開始
5. ユーザーが `docs/aidlc/prompts/setup.md` を読み込むよう指示

## 理想

1. ユーザーがworktreeを選択
2. AIがworktreeを作成
3. AIが新しいディレクトリでClaude Codeを起動
4. 新しいセッションでセットアップを自動継続

## 技術的検討

### プロセス情報
- Claude Codeのプロセス名: `claude`
- 親プロセスから起動可能

### 実装案

```bash
# 1. worktree作成
git worktree add -b cycle/v1.5.3 ../project-v1.5.3

# 2. 新しいディレクトリでClaude Codeを起動
cd ../project-v1.5.3
claude "docs/aidlc/prompts/setup.md を読み込んでサイクル v1.5.3 を開始してください"
```

### 課題

1. 現在のセッションを終了する方法
2. 新しいセッションへの引き継ぎ情報
3. バージョン（v1.5.3）の引き渡し

## 関連

- worktree設定: `docs/aidlc.toml` の `[rules.worktree]`
