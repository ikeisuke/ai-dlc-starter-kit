# デプロイチェックリスト

## デプロイ情報
- **バージョン**: v1.3.1
- **デプロイ環境**: GitHubリポジトリ（公開）
- **リリース方法**: mainブランチへのマージ + 自動タグ作成

## 今回のリリース内容
- Unit 1: バックログ対応済みチェック機能
- Unit 2: セットアップスキップ機能
- Unit 3: Dependabot PR確認機能

## デプロイ前チェックリスト

### コード品質
- [ ] prompts/package/ の変更内容が正しい
- [ ] Markdownファイルの構文エラーがない

### メタ開発特有の作業
- [ ] version.txt を 1.3.1 に更新
- [ ] setup-init 実行（docs/aidlc/ を最新化）

### ドキュメント
- [ ] README.md が更新されている

## デプロイ手順

### 1. バージョン更新
```bash
echo "1.3.1" > version.txt
```

### 2. setup-init 実行
prompts/setup-init.md を読み込み、セクション7（共通ファイルの配置）を実行：
```bash
rsync -av --delete \
  --exclude='rules.md' \
  --exclude='operations.md' \
  prompts/package/ docs/aidlc/
```

### 3. Operations Phase 完了コミット
```bash
git add .
git commit -m "chore: Operations Phase完了 - デプロイ、CI/CD、監視を構築"
```

### 4. PR 作成
```bash
gh pr create --base main --title "v1.3.1" --body "..."
```

### 5. PR マージ
- PRをマージすると GitHub Actions が自動で v1.3.1 タグを作成

## ロールバック手順

問題が発生した場合：
```bash
# 前のバージョンに戻す
git checkout v1.3.0
```

## デプロイ後チェックリスト
- [ ] タグ v1.3.1 が作成されている
- [ ] README.md の変更が反映されている
- [ ] 新機能（バックログチェック、セットアップスキップ、Dependabot確認）が動作する

## 備考
- このプロジェクトはドキュメント・テンプレートプロジェクトのため、インフラ・DB・監視の項目は該当しない
- CI/CDは既存のGitHub Actions（auto-tag.yml）を使用
