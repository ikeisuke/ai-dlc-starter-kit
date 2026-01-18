# 論理設計: worktreeサブディレクトリ化

## 概要

setup.md内のworktree関連記述を更新し、作成先パスを `.worktree/cycle-{{CYCLE}}` に変更する。

## 変更仕様

### 1. WORKTREE_PATH変数定義（390-396行目付近）

**変更前**:

```bash
PROJECT_NAME=$(basename "$(pwd)")
WORKTREE_PATH="../${PROJECT_NAME}-{{CYCLE}}"
echo "プロジェクト名: ${PROJECT_NAME}"
echo "worktreeパス: ${WORKTREE_PATH}"
```

**変更後**:

```bash
WORKTREE_PATH=".worktree/cycle-{{CYCLE}}"
echo "worktreeパス: ${WORKTREE_PATH}"
```

**理由**: プロジェクト名の取得が不要になり、シンプルなパス定義に変更。

### 2. 成功時メッセージ（438-448行目付近）

**変更前**:

```text
worktreeを作成しました: [WORKTREE_PATH]

新しいディレクトリに移動して、セッションを開始してください:
cd [WORKTREE_PATH]

移動後、以下のプロンプトを読み込んでください:
docs/aidlc/prompts/setup.md
```

**変更後**:

```text
worktreeを作成しました: [WORKTREE_PATH]

サブディレクトリに移動して、セッションを開始してください:
cd [WORKTREE_PATH]

移動後、以下のプロンプトを読み込んでください:
docs/aidlc/prompts/setup.md
```

### 3. エラー時手動コマンド（451-469行目付近）

パスを `.worktree/cycle-{{CYCLE}}` 形式に更新。

### 4. 推奨ディレクトリ構成図（753-760行目付近）

**変更前**:

```text
~/projects/
├── my-project/              # メインディレクトリ（mainブランチ）
├── my-project-v1.4.0/       # worktree（cycle/v1.4.0ブランチ）
└── my-project-v1.5.0/       # worktree（cycle/v1.5.0ブランチ）
```

**変更後**:

```text
~/projects/
└── my-project/              # メインディレクトリ（mainブランチ）
    └── .worktree/
        ├── cycle-v1.4.0/    # worktree（cycle/v1.4.0ブランチ）
        └── cycle-v1.5.0/    # worktree（cycle/v1.5.0ブランチ）
```

### 5. 正しいworktree作成コマンド（762-772行目付近）

**変更前**:

```bash
# メインディレクトリから実行
git worktree add ../[プロジェクト名]-{{CYCLE}} cycle/{{CYCLE}}

# 例: ai-dlc-starter-kit ディレクトリから v1.5.3 のworktreeを作成
git worktree add ../ai-dlc-starter-kit-v1.5.3 cycle/v1.5.3
```

**変更後**:

```bash
# メインディレクトリから実行
git worktree add .worktree/cycle-{{CYCLE}} cycle/{{CYCLE}}

# 例: v1.5.3 のworktreeを作成
git worktree add .worktree/cycle-v1.5.3 cycle/v1.5.3
```

### 6. 誤ったworktreeの修正手順（776-789行目付近）

新しいパス形式に合わせて更新。サブディレクトリ方式では「誤った位置に作成」のケースが減るため、記述を簡素化。

### 7. worktree作成後（791-797行目付近）

**変更前**:

```bash
cd ../[プロジェクト名]-{{CYCLE}}
```

**変更後**:

```bash
cd .worktree/cycle-{{CYCLE}}
```

### 8. 注意書き（774行目付近）

`git -C` 非推奨の注意書きは、サブディレクトリ方式では不要になるため削除または簡素化。

## ai-agent-allowlist.md

確認結果: 変更不要

現在のallowlistパターン:

- `Bash(git worktree list)` - 変更不要
- `Bash(git worktree add:*)` - ワイルドカードパターンのため変更不要
- `Bash(git worktree remove:*)` - ワイルドカードパターンのため変更不要

## テスト方針

このUnitはドキュメント変更のみのため、以下を確認:

1. 変更後のsetup.mdが構文的に正しいこと
2. パス形式が一貫していること
3. コマンド例が正しく動作する形式であること
