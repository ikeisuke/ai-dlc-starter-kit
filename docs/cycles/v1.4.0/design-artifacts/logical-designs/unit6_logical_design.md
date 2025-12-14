# Unit 6: git worktree提案 - 論理設計

## 概要

サイクル開始時にgit worktreeの使用を提案する機能を追加する。
デフォルトでは無効で、aidlc.tomlの設定で有効化可能。

---

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-init.md` | aidlc.tomlテンプレートに`[rules.worktree]`セクション追加 |
| `prompts/setup-cycle.md` | セクション3にworktree条件分岐追加 |

---

## 1. setup-init.md の変更

### 1.1 aidlc.toml テンプレート追加

**挿入位置**: `[rules.mcp_review]` セクションの後

**追加内容**:
```toml
[rules.worktree]
# git worktree設定
# enabled: true | false
# - true: サイクル開始時にworktreeの使用を提案する
# - false: 提案しない（デフォルト）
enabled = false
```

### 1.2 設定マイグレーションセクションへの追加

**挿入位置**: セクション 6.4「設定マイグレーション」内

**追加内容**:
```bash
# [rules.worktree] セクションが存在しない場合は追加
if ! grep -q "^\[rules.worktree\]" docs/aidlc.toml; then
  echo "Adding [rules.worktree] section..."
  cat >> docs/aidlc.toml << 'EOF'

[rules.worktree]
# git worktree設定（v1.4.0で追加）
# enabled: true | false
# - true: サイクル開始時にworktreeの使用を提案する
# - false: 提案しない（デフォルト）
enabled = false
EOF
  echo "Added [rules.worktree] section"
else
  echo "[rules.worktree] section already exists"
fi
```

---

## 2. setup-cycle.md の変更

### 2.1 セクション3「Git ブランチの確認」の変更

**現在の構造**（セクション3.2）:
```markdown
## 3.2 ブランチ作成の提案

現在のブランチ: [ブランチ名]

推奨: cycle/[バージョン] ブランチで作業することを推奨します。

1. 新しいブランチを作成して切り替える: git checkout -b cycle/[バージョン]
2. 現在のブランチで続行する

どちらを選択しますか？
```

**変更後の構造**:

#### セクション 3.2 を条件付きに変更

```markdown
### 3.2 ブランチ作成の提案

`docs/aidlc.toml` の `[rules.worktree]` セクションを確認:

```bash
grep -A1 "^\[rules.worktree\]" docs/aidlc.toml | grep "enabled" | grep -q "true" && echo "WORKTREE_ENABLED" || echo "WORKTREE_DISABLED"
```

#### worktree が有効な場合（WORKTREE_ENABLED）

```
現在のブランチ: [ブランチ名]

推奨: cycle/[バージョン] ブランチで作業することを推奨します。

1. git worktreeを使用して新しい作業ディレクトリを作成する
2. 新しいブランチを作成して切り替える: git checkout -b cycle/[バージョン]
3. 現在のブランチで続行する

どれを選択しますか？
```

**1を選択した場合の案内**:

```
## git worktree の使用

git worktreeを使うと、同じリポジトリの複数ブランチを別ディレクトリで同時に開けます。
複数サイクルの並行作業に便利です。

**推奨ディレクトリ構成**:
```
~/projects/
├── my-project/              # メインディレクトリ（mainブランチ）
├── my-project-v1.4.0/       # worktree（cycle/v1.4.0ブランチ）
└── my-project-v1.5.0/       # worktree（cycle/v1.5.0ブランチ）
```

**worktree作成コマンド**:
```bash
# 親ディレクトリに移動してworktreeを作成
cd ..
git -C [元のディレクトリ名] worktree add -b cycle/[バージョン] [元のディレクトリ名]-[バージョン]
cd [元のディレクトリ名]-[バージョン]
```

作成後、新しいディレクトリでセッションを開始してください。
```

#### worktree が無効な場合（WORKTREE_DISABLED）- デフォルト

既存の動作と同じ:

```
現在のブランチ: [ブランチ名]

推奨: cycle/[バージョン] ブランチで作業することを推奨します。

1. 新しいブランチを作成して切り替える: git checkout -b cycle/[バージョン]
2. 現在のブランチで続行する

どちらを選択しますか？
```
```

---

## 設計上の決定事項

| 項目 | 決定 | 理由 |
|------|------|------|
| デフォルト値 | `enabled = false` | 既存ユーザーへの影響を避ける |
| worktree自動作成 | しない | 提案のみで、実行はユーザーに委ねる |
| ディレクトリ命名 | `[プロジェクト名]-[バージョン]` | シンプルで分かりやすい |
| 既存worktree確認 | 含めない | スコープ外（提案のみ） |

---

## 互換性

- **既存ユーザー**: worktree設定がないためデフォルト（無効）が適用され、動作変更なし
- **アップグレード時**: 設定マイグレーションで`[rules.worktree]`セクションが自動追加される
