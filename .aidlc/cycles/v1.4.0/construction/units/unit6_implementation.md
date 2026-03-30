# Unit 6: git worktree提案 - 実装記録

## 概要
セットアップ時にgit worktreeの使用を提案する機能を追加。デフォルトでは無効、aidlc.tomlの設定で有効化可能。

## 実装日
2025-12-14

## 変更ファイル

| ファイル | 変更内容 |
|---------|---------|
| `prompts/setup-init.md` | aidlc.tomlテンプレートに`[rules.worktree]`セクション追加、設定マイグレーション追加 |
| `prompts/setup-cycle.md` | セクション3.2にworktree条件分岐追加 |

## 実装詳細

### 1. setup-init.md

#### aidlc.toml テンプレート追加
```toml
[rules.worktree]
# git worktree設定
# enabled: true | false
# - true: サイクル開始時にworktreeの使用を提案する
# - false: 提案しない（デフォルト）
enabled = false
```

#### 設定マイグレーション追加
既存プロジェクトのアップグレード時に`[rules.worktree]`セクションを自動追加するコマンドを追加。

### 2. setup-cycle.md

セクション3.2「ブランチ作成の提案」を条件分岐に変更:
- worktree有効時: worktree選択肢を含む3つの選択肢を表示
- worktree無効時: 既存の2つの選択肢を表示（デフォルト動作、変更なし）

worktree選択時の案内:
- メリット説明（並行作業可能）
- 推奨ディレクトリ構成例
- worktree作成コマンドの案内

## テスト

このUnitはプロンプト編集のみのため、自動テストは不要。

**手動確認項目**:
- [x] aidlc.toml テンプレートに`[rules.worktree]`セクションが追加されている
- [x] 設定マイグレーションコマンドが正しく記述されている
- [x] setup-cycle.md の条件分岐が正しく記述されている
- [x] デフォルト動作（worktree無効時）が既存動作と同じ

## 状態
完了
