# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.7.2
- **デプロイ予定日**: 2026-01-13
- **デプロイ環境**: GitHub リポジトリ（公開）
- **担当者**: プロジェクトオーナー

## デプロイ前チェックリスト

### コード品質

- [ ] すべてのMarkdownファイルがlint通過
- [ ] PRチェック（GitHub Actions）が成功
- [ ] コードレビュー / セルフレビューが完了

### ドキュメント

- [ ] version.txtが更新されている（1.7.2）
- [ ] starter_kit_versionが更新されている
- [ ] CHANGELOG.mdが更新されている
- [ ] README.mdが更新されている

### テンプレート・プロンプト

- [ ] prompts/package/からdocs/aidlc/への同期が完了
- [ ] テンプレートの整合性が確認されている

## デプロイ手順

### 1. 事前準備

```bash
# 最新の変更を確認
git status

# Markdownlintを実行
npx markdownlint-cli2 "docs/**/*.md" "prompts/**/*.md" "*.md"
```

### 2. コミット・プッシュ

```bash
# 変更をコミット
git add -A
git commit -m "chore: [v1.7.2] Operations Phase完了"

# プッシュ
git push origin cycle/v1.7.2
```

### 3. PR作成・マージ

```bash
# PRをReady for Reviewに変更
gh pr ready

# PRをマージ（レビュー後）
gh pr merge
```

### 4. タグ付け

```bash
# mainブランチに移動
git checkout main
git pull origin main

# タグを作成（GitHub Actionsが自動実行するため手動は不要）
# 確認: git tag | grep v1.7.2
```

## ロールバック手順

問題が発生した場合：

```bash
# 前バージョンに戻す
git checkout v1.7.1
```

## デプロイ後チェックリスト

- [ ] タグv1.7.2が作成されている
- [ ] GitHub Releasesにリリースが作成されている（オプション）
- [ ] READMEに記載の機能が正常に動作する

## 備考

- このプロジェクトはドキュメント・テンプレートプロジェクトのため、実行環境へのデプロイは不要
- GitHub Actionsのauto-tagワークフローにより、mainへのマージ時に自動タグ付けが行われる
