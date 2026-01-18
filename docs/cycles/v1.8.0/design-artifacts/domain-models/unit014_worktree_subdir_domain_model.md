# ドメインモデル設計: worktreeサブディレクトリ化

## 概要

git worktreeの作成先パスを親ディレクトリからプロジェクト配下のサブディレクトリに変更する。

## ドメイン概念

### Worktree（値オブジェクト）

worktreeの作成先パスを表す概念。

| 属性 | 変更前 | 変更後 |
|------|--------|--------|
| パス形式 | `../${PROJECT_NAME}-{{CYCLE}}` | `.worktree/cycle-{{CYCLE}}` |
| 基準位置 | 親ディレクトリ | プロジェクト配下 |

### パス構成要素

| 要素 | 変更前 | 変更後 |
|------|--------|--------|
| ベースディレクトリ | `../` | `.worktree/` |
| 識別子 | `${PROJECT_NAME}-{{CYCLE}}` | `cycle-{{CYCLE}}` |
| 例 | `../ai-dlc-starter-kit-v1.8.0` | `.worktree/cycle-v1.8.0` |

## 変更の影響範囲

### 直接影響

1. **WORKTREE_PATH変数定義**: パス生成ロジックの変更
2. **コマンド例**: `git worktree add` コマンドのパス引数
3. **説明文・メッセージ**: ユーザー向け説明の更新
4. **ディレクトリ構成図**: 推奨構成の図を更新

### 影響を受けないもの

- worktree機能自体の動作
- ブランチ名（`cycle/{{CYCLE}}`）
- gitコマンドの構文
- allowlistパターン（汎用パターンのため変更不要）

## 設計上の考慮事項

### メリット

1. **AIエージェントからのアクセス容易性**: プロジェクト配下にあることで相対パス参照が容易
2. **ディレクトリ構成の統一**: プロジェクト関連ファイルをプロジェクト内に集約
3. **プロジェクト名非依存**: `${PROJECT_NAME}` を使わないシンプルなパス

### 注意点

1. **既存worktree**: 既存のworktreeは手動で移行が必要（remove→再作成）
2. **.gitignore追加が必要**: `.worktree/`ディレクトリはgit statusにUntracked filesとして表示されるため、`.gitignore`への追加が必要
3. **親ディレクトリ作成**: `mkdir -p .worktree`が必要（git worktree addは親ディレクトリを自動作成しない）

## 検証結果

### git worktree addの動作確認

メインワークツリー配下のサブディレクトリへのworktree作成は正常に動作することを確認済み。

```bash
mkdir -p .worktree
git worktree add .worktree/test-branch -b test-branch  # 成功
```

### git statusの表示

`.worktree/`ディレクトリはUntracked filesとして表示される→`.gitignore`への追加が必要。

## 変更対象ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/package/prompts/setup.md` | パス定義、コマンド例、説明文の更新 |
| `prompts/package/guides/ai-agent-allowlist.md` | 確認のみ（変更不要の見込み） |
| `.gitignore` | `.worktree/`の追加 |

### 検索確認済み

`grep -r "worktree" prompts/package/`で検索し、上記以外のファイルには旧パスの記述がないことを確認済み。
