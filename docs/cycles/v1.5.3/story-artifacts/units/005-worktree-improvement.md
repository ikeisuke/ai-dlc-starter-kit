# Unit: worktree機能の改善

## 概要
worktreeが並列ディレクトリに正しく作成されるよう修正し、AIによる自動作成機能を追加する。

## 含まれるユーザーストーリー
- ストーリー 1.5: worktreeディレクトリ構造の改善
- ストーリー 1.6: AIによるworktree自動作成

## 責務
- 正しいworktree作成コマンドへの修正（../project-vX.Y.Z 形式）
- AIによるworktree自動作成機能
- フォールバック動作の実装

## 境界
- 既存の誤ったworktreeの自動修正は行わない（手順を案内）
- worktree削除機能は含まない

## 依存関係

### 依存する Unit
- なし

### 外部依存
- git worktree

## 非機能要件（NFR）
- **パフォーマンス**: git worktree コマンドの実行速度に依存
- **セキュリティ**: ファイルシステムへの書き込み権限が必要
- **スケーラビリティ**: 該当なし
- **可用性**: 権限エラー時のフォールバック処理

## 技術的考慮事項

### 正しいworktree作成コマンド
```bash
# メインディレクトリから実行
git worktree add ../ai-dlc-starter-kit-{{CYCLE}} cycle/{{CYCLE}}
```

**重要なポイント**:
- 相対パス `../` を明示的に使用
- `git -C` は使わない（パスがリポジトリディレクトリ基準になるため）

### フォールバック動作
- **権限エラー時**: 手動実行コマンドを表示
- **ディスク容量不足時**: 警告を表示し中断
- **既存worktree検出時**: 既存を使用するか確認

### 誤ったworktreeの修正手順
```bash
# 1. 誤った worktree を削除
git worktree remove ai-dlc-starter-kit-{{CYCLE}}

# 2. 正しい位置に再作成
git worktree add ../ai-dlc-starter-kit-{{CYCLE}} cycle/{{CYCLE}}

# 3. 確認
git worktree list
```

## 対象ファイル
- prompts/setup-prompt.md
- prompts/package/prompts/setup.md

## 実装優先度
High

## 見積もり
コマンド修正と自動作成ロジックの追加

---
## 実装状態

- **状態**: 未着手
- **開始日**: -
- **完了日**: -
- **担当**: -
