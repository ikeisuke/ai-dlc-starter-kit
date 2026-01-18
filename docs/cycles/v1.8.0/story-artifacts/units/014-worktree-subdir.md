# Unit: worktreeサブディレクトリ化

## 概要
git worktreeの作成先をプロジェクト配下の `.worktree/` サブディレクトリに変更する。

## 含まれるユーザーストーリー
- ストーリー 3-4: worktreeサブディレクトリ化

## 関連Issue
- #59

## 責務
- worktree作成先パスの変更
- worktree関連プロンプト記述の更新
- .gitignore設定の確認

## 境界
- worktree機能自体の新規追加は含まない（既存機能の改善）

## 依存関係

### 依存する Unit
- なし（独立して実装可能）

### 外部依存
- git worktree

## 非機能要件（NFR）
- **パフォーマンス**: N/A
- **セキュリティ**: N/A
- **スケーラビリティ**: N/A
- **可用性**: N/A

## 技術的考慮事項

### パス変更
- 変更前: プロジェクト外の任意ディレクトリ（例: `../project-worktree`）
- 変更後: `.worktree/cycle-vX.X.X`（プロジェクト直下）

### git コマンド変更例
```bash
# 変更前
git worktree add ../project-cycle-v1.8.0 cycle/v1.8.0

# 変更後
git worktree add .worktree/cycle-v1.8.0 cycle/v1.8.0
```

### jj コマンド変更例
```bash
# jj使用時も同様のパス変更
```

### .gitignore 確認
`.worktree/` ディレクトリはworktree自体なので .gitignore に追加不要
（worktreeは別のブランチをチェックアウトした状態なので、追跡対象外）

### 変更対象ファイル
- worktree関連のプロンプト記述箇所（setup.md等）

### 注意事項
- 既存worktreeがある場合の移行は手動対応
- AIエージェントからのアクセスしやすさが主目的

## 実装優先度
Low

## 見積もり
1時間

---
## 実装状態

- **状態**: 完了
- **開始日**: 2026-01-18
- **完了日**: 2026-01-18
- **担当**: -
