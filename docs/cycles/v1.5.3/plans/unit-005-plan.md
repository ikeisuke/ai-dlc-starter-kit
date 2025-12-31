# Unit 005: worktree機能の改善 - 実行計画

## 概要

worktreeが並列ディレクトリに正しく作成されるよう修正し、AIによる自動作成機能を追加する。

## 関連バックログ

- `chore-worktree-directory-structure.md`: worktreeが並列ディレクトリに正しく作成されるべき
- `feature-ai-creates-worktree.md`: AIによるworktree自動作成機能

## 対象ファイル

- `prompts/setup-prompt.md`
- `prompts/package/prompts/setup.md`

## 現状の問題点

### 問題1: worktree作成コマンドが誤り

現在の `setup.md` の「補足: git worktree の使用」セクション:

```bash
cd ..
git -C [元のディレクトリ名] worktree add -b cycle/{{CYCLE}} [元のディレクトリ名]-{{CYCLE}}
```

この方法では `git -C` を使用するため、相対パスがリポジトリディレクトリ基準になり、**メインディレクトリ内**にworktreeが作成されてしまう。

**正しいコマンド**:
```bash
# メインディレクトリから実行
git worktree add ../project-{{CYCLE}} cycle/{{CYCLE}}
```

### 問題2: AIによる自動作成がない

現状はユーザーが手動でコマンドを実行する必要がある。

## 実装方針

### Phase 1: 設計

1. **ドメインモデル設計**: worktree作成フローの設計
   - 正しいworktree作成コマンドの定義
   - AIによる自動作成フローの設計
   - フォールバック動作の設計

2. **論理設計**: プロンプト修正箇所の特定
   - setup.md の「補足: git worktree の使用」セクション修正
   - setup.md の「ステップ3: ブランチ確認」のworktree選択時処理修正
   - setup-prompt.md の同様箇所の修正（あれば）

### Phase 2: 実装

1. **コード生成**:
   - setup.md のworktree関連セクションを修正
   - setup-prompt.md の修正（必要な場合）

2. **テスト生成**:
   - 手動テスト手順の作成（実際のworktree作成はテストしない）

## 変更内容詳細

### setup.md の修正

1. **「補足: git worktree の使用」セクションの修正**:
   - 誤ったコマンド `git -C` を使用した方法を削除
   - 正しいコマンド `git worktree add ../project-{{CYCLE}} cycle/{{CYCLE}}` に置換

2. **「ステップ3: ブランチ確認」worktree選択時の処理追加**:
   - AIが自動でworktreeを作成するフローを追加
   - フォールバック（権限エラー時）の手動実行コマンド表示

### setup-prompt.md の確認

setup-prompt.md はエントリーポイントであり、worktree作成の具体的な処理は setup.md に委譲されている。
setup-prompt.md 自体にworktree作成コマンドの記載がないことを確認。

## 完了基準

- [ ] 正しいworktree作成コマンドへの修正完了
- [ ] AIによる自動作成フローの追加完了
- [ ] フォールバック動作の実装完了
- [ ] ドキュメントの整合性確認

## 備考

- 既存の誤ったworktreeの自動修正は行わない（Unit定義の境界による）
- worktree削除機能は含まない（Unit定義の境界による）
