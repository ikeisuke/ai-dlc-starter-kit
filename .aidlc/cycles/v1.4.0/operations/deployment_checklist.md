# デプロイチェックリスト

## デプロイ情報
- **バージョン**: v1.4.0
- **デプロイ予定日**: 2025-12-16
- **デプロイ環境**: GitHub リポジトリ（公開）
- **担当者**: AI-DLC / ユーザー

## デプロイ前チェックリスト

### コード品質
- [ ] すべてのテンプレートが正しいフォーマットである
- [ ] プロンプトファイルの整合性が確認されている
- [ ] 新機能のドキュメントが完備している

### 環境設定
- [ ] `version.txt` が新バージョン（1.4.0）に更新されている
- [ ] `docs/aidlc/` が `prompts/package/` と同期されている

### ドキュメント
- [ ] README.md が更新されている（変更履歴、新機能など）
- [ ] 各Unitの実装状態が「完了」になっている
- [ ] history.md に履歴が記録されている

## デプロイ手順

### 1. バージョン更新
```bash
# version.txt を更新
echo "1.4.0" > version.txt
```

### 2. パッケージ同期（メタ開発特有）
```bash
# prompts/package/ → docs/aidlc/ に同期
rsync -av --delete \
  --exclude='operations.md' \
  prompts/package/ docs/aidlc/
```

### 3. 最終コミット
```bash
git add .
git commit -m "chore: Operations Phase完了 - v1.4.0リリース準備"
```

### 4. PR作成
```bash
gh pr create --base main --title "v1.4.0" --body "..."
```

### 5. マージ後
- GitHub Actions が自動でタグ `v1.4.0` を作成

## ロールバック手順

問題が発生した場合の手順：

```bash
# 前のバージョンに戻す
git checkout v1.3.0

# または特定のコミットに戻す
git revert <commit-hash>
```

## デプロイ後チェックリスト
- [ ] タグ `v1.4.0` が作成されている
- [ ] README.md の内容が正しい
- [ ] 新機能のドキュメントがアクセス可能

## v1.4.0 の主な変更内容

### 新機能（Unit実装内容）
- Unit 1: GitHub Actionsの仕組み調査と導入
- Unit 2: GitHub Issue確認とセットアップ統合
- Unit 3: npm-scripts自動実行の提案機能
- Unit 4: 割り込み対応ルール追加
- Unit 5: AI MCPレビュー推奨機能追加
- Unit 6: git worktree提案機能追加
- Unit 7: 複数人開発時コンフリクト対策

## 備考
- このプロジェクトは PROJECT_TYPE=general（ドキュメント・テンプレートプロジェクト）
- アプリケーションデプロイではなく、GitHubリポジトリへの公開がデプロイに相当
