# デプロイチェックリスト

## デプロイ情報
- **バージョン**: v1.5.2
- **デプロイ予定日**: PRマージ後
- **デプロイ環境**: GitHub リポジトリ公開
- **担当者**: ユーザー

## デプロイ前チェックリスト

### コード品質
- [ ] すべてのドキュメントが整合性を持っている
- [ ] テンプレートファイルが正しくフォーマットされている
- [ ] プロンプトファイルに構文エラーがない

### バージョン管理
- [ ] version.txt が v1.5.2 に更新されている
- [ ] README.md に変更履歴が記載されている
- [ ] docs/aidlc.toml の starter_kit_version が適切

### ドキュメント
- [ ] README.md が更新されている（変更履歴、新機能など）
- [ ] 新機能のドキュメントが追加されている
- [ ] 既存ドキュメントとの整合性が取れている

## デプロイ手順

### 1. 事前準備
```bash
# 現在のブランチ確認
git branch --show-current

# 変更内容確認
git status
git diff --stat
```

### 2. コミット
```bash
# Operations Phase 完了コミット
git add .
git commit -m "chore: [v1.5.2] Operations Phase完了 - デプロイ、CI/CD、監視を構築"
```

### 3. PR作成
```bash
gh pr create --base main --title "v1.5.2" --body "..."
```

### 4. PRマージ後
```bash
# mainブランチに移動
git checkout main

# 最新の変更を取得
git pull origin main

# マージ済みブランチの削除
git branch -d cycle/v1.5.2
```

### 5. 自動タグ付け確認
- GitHub Actions が自動で `v1.5.2` タグを作成することを確認

## ロールバック手順

問題が発生した場合の手順：

```bash
# 前のバージョンに戻す場合
git checkout v1.5.1
```

## デプロイ後チェックリスト
- [ ] GitHub に正常にpushされている
- [ ] タグが正しく作成されている
- [ ] README の内容が正しく表示されている

## 備考
- このプロジェクトはドキュメント・テンプレートプロジェクトのため、サーバーデプロイや監視設定は不要
- GitHub Actions による自動タグ付けを使用

## 不明点と質問（Operations Phase中に記録）

（なし）
