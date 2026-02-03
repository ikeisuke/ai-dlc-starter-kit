# git worktree の使用

git worktreeを使うと、同じリポジトリの複数ブランチを別ディレクトリで同時に開けます。
複数サイクルの並行作業に便利です。

## 推奨ディレクトリ構成

```text
~/projects/
└── my-project/              # メインディレクトリ（mainブランチ）
    └── .worktree/
        ├── cycle-v1.4.0/    # worktree（cycle/v1.4.0ブランチ）
        └── cycle-v1.5.0/    # worktree（cycle/v1.5.0ブランチ）
```

## worktree作成コマンド

```bash
# メインディレクトリから実行（既存ブランチの場合）
mkdir -p .worktree
git worktree add .worktree/cycle-{{CYCLE}} cycle/{{CYCLE}}

# 新規ブランチを同時に作成する場合（-b フラグを使用）
mkdir -p .worktree
git worktree add -b cycle/{{CYCLE}} .worktree/cycle-{{CYCLE}}

# 例: v1.5.3 のworktreeを作成（既存ブランチ）
mkdir -p .worktree
git worktree add .worktree/cycle-v1.5.3 cycle/v1.5.3

# 例: v1.5.3 のworktreeを新規ブランチで作成
mkdir -p .worktree
git worktree add -b cycle/v1.5.3 .worktree/cycle-v1.5.3
```

## スクリプトによる自動作成

`setup-branch.sh` を使用すると、worktree作成を自動化できます:

```bash
docs/aidlc/bin/setup-branch.sh v1.5.3 worktree
```

出力例:
```text
status:success
branch:cycle/v1.5.3
worktree_path:.worktree/cycle-v1.5.3
message:新しいブランチ cycle/v1.5.3 でworktreeを作成しました
```

## 既存worktreeの移行

旧形式（親ディレクトリ）のworktreeがある場合の移行手順:

```bash
# 1. 既存 worktree のパスを確認
git worktree list

# 2. 既存 worktree を削除（上記で確認したパスを指定）
git worktree remove [確認したパス]

# 3. 新形式で再作成
mkdir -p .worktree
git worktree add .worktree/cycle-{{CYCLE}} cycle/{{CYCLE}}

# 4. 確認
git worktree list
```

## worktree作成後

作成後、サブディレクトリに移動してセッションを開始してください:

```bash
cd .worktree/cycle-{{CYCLE}}
```

## worktreeの削除

不要になったworktreeを削除する場合:

```bash
# worktreeを削除
git worktree remove .worktree/cycle-v1.5.3

# ブランチも削除する場合
git branch -d cycle/v1.5.3
```

## トラブルシューティング

### worktree作成に失敗する

ブランチが既にチェックアウトされている場合、worktreeの作成に失敗します:

```text
fatal: 'cycle/v1.5.3' is already checked out at '/path/to/project'
```

この場合は、既存のチェックアウトを別ブランチに切り替えてから再試行してください。

### worktreeが残っている

worktreeのディレクトリを手動で削除した場合、gitの管理情報が残ることがあります:

```bash
# 残っている情報を確認
git worktree list

# 無効なworktreeをクリーンアップ
git worktree prune
```
