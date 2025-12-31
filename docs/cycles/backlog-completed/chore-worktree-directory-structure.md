# worktreeは並列ディレクトリに作成すべき

- **発見日**: 2025-12-27
- **発見フェーズ**: Setup
- **発見サイクル**: v1.5.3
- **優先度**: 高

## 概要

現在の setup.md の worktree 作成案内が不十分で、メインディレクトリ内に worktree が作成されてしまう問題がある。

## 詳細

setup.md の「補足: git worktree の使用」セクションには推奨ディレクトリ構成が記載されている:

```
~/projects/
├── my-project/              # メインディレクトリ（mainブランチ）
├── my-project-v1.4.0/       # worktree（cycle/v1.4.0ブランチ）
└── my-project-v1.5.0/       # worktree（cycle/v1.5.0ブランチ）
```

しかし、実際にユーザーが worktree を作成すると、以下のような構造になってしまった:

```
/Users/keisuke/repos/github.com/ikeisuke/ai-dlc-starter-kit/
├── ai-dlc-starter-kit-v1.5.3/  # worktree（メインディレクトリ内に作成されている）
└── ... (メインディレクトリのファイル)
```

**問題点**:
1. worktree がメインディレクトリの中に作成されている
2. これにより、メインディレクトリが git status で untracked files として表示される
3. 推奨構成と異なるため、ユーザーが混乱する

**根本原因**:
- setup.md には「worktree作成コマンド」が記載されているが、**現在のディレクトリ**から実行することを想定している
- しかし、ユーザーがメインディレクトリにいる状態で実行すると、メインディレクトリ内に worktree が作成されてしまう
- 「親ディレクトリに移動してworktreeを作成」と記載されているが、具体的な手順が不明確

## 対応案

### 1. setup.md の worktree 作成案内を改善

ブランチ確認のステップ（セクション3）で、worktree を選択した場合の処理を以下のように変更:

```
worktree を選択した場合:

1. 現在のディレクトリを確認
   - pwd で取得
   - ディレクトリ名を抽出（例: ai-dlc-starter-kit）

2. worktree 作成コマンドを具体的に提示
   ```
   以下のコマンドで worktree を作成します:

   cd ..
   git -C [元のディレクトリ名] worktree add -b cycle/{{CYCLE}} [元のディレクトリ名]-{{CYCLE}}
   cd [元のディレクトリ名]-{{CYCLE}}
   ```

   実行しますか？（Y/n）

3. 承認された場合、コマンドを実行
   - cd .. で親ディレクトリに移動
   - git worktree add で新しい worktree を作成
   - cd で新しいディレクトリに移動しない（ユーザーに移動を促す）

4. 完了メッセージ
   ```
   worktree を作成しました: [親ディレクトリ]/[元のディレクトリ名]-{{CYCLE}}

   新しいディレクトリに移動してください:
   cd ../[元のディレクトリ名]-{{CYCLE}}

   移動後、新しいセッションでこのプロンプトを再度読み込んでください:
   docs/aidlc/prompts/setup.md
   ```
```

### 2. 既存の誤った worktree の修正手順を提供

setup.md のサイクル存在確認（セクション4）で、以下のチェックを追加:

```bash
# メインディレクトリ内に誤って作成された worktree を検出
CURRENT_DIR=$(pwd)
WORKTREE_IN_MAIN=$(git worktree list | grep "^${CURRENT_DIR}/" | grep "\[cycle/" || echo "")

if [ -n "$WORKTREE_IN_MAIN" ]; then
  echo "WARNING: メインディレクトリ内に worktree が作成されています"
fi
```

警告を表示し、修正手順を案内する。

### 3. 実際に試して判明した正しいコマンド

**正しい worktree 作成方法**（v1.5.3 で検証済み）:

```bash
# メインディレクトリから実行
git worktree add ../ai-dlc-starter-kit-{{CYCLE}} cycle/{{CYCLE}}
```

**重要な学び**:
1. **相対パス `../` を使う**: メインディレクトリから `../` で親ディレクトリを参照する
2. **`git -C` は使わない**: `git -C` で相対パスを指定すると、パスがリポジトリディレクトリ基準になり、メインディレクトリ内に作成されてしまう
   - ❌ 間違い: `git -C ai-dlc-starter-kit worktree add ai-dlc-starter-kit-v1.5.3 cycle/v1.5.3`
   - → これは `ai-dlc-starter-kit/ai-dlc-starter-kit-v1.5.3/` に作成される

**誤って作成した worktree の修正手順**:

```bash
# 1. 誤った worktree を削除
git worktree remove ai-dlc-starter-kit-{{CYCLE}}

# 2. 正しい位置に再作成
git worktree add ../ai-dlc-starter-kit-{{CYCLE}} cycle/{{CYCLE}}

# 3. 確認
git worktree list
```

**期待される結果**:
```
/Users/.../ai-dlc-starter-kit         [main]
/Users/.../ai-dlc-starter-kit-v1.5.2  [cycle/v1.5.2]
/Users/.../ai-dlc-starter-kit-v1.5.3  [cycle/v1.5.3]
```

すべてが並列ディレクトリになっていることを確認する。
