# デプロイチェックリスト

## デプロイ情報
- **バージョン**: v1.2.0
- **デプロイ予定日**: 2025-12-05
- **デプロイ方式**: GitHub PR マージ → Actions 自動タグ付け

## デプロイ前チェックリスト

### コード品質
- [x] Construction Phase 完了
- [x] 全 Unit 実装完了（Unit 1-5, 7）
- [x] Unit 6 はスキップ（バージョン埋め込みは別方式で対応）

### 成果物確認
- [x] プロンプト分割・短縮化（Unit 1）
- [x] 変数テンプレート修正（Unit 2）
- [x] セットアップ処理分離（Unit 3）
- [x] フェーズプロンプト改修（Unit 4）
- [x] テンプレート外部ファイル化（Unit 5）
- [x] パス参照修正（Unit 7）

### バージョン管理
- [x] version.txt を 1.2.0 に更新
- [x] GitHub Actions auto-tag.yml 設定済み

## デプロイ手順

### 1. 変更をコミット
```bash
git add .
git commit -m "chore: Operations Phase - デプロイ準備完了"
```

### 2. リモートへプッシュ
```bash
git push -u origin cycle/v1.2.0
```

### 3. PR 作成
- cycle/v1.2.0 → main への PR を作成
- レビュー・承認

### 4. マージ
- PR をマージ
- GitHub Actions が自動で v1.2.0 タグを作成

## デプロイ後確認
- [ ] タグ v1.2.0 が作成されている
- [ ] GitHub Releases に反映されている

## ロールバック手順
問題発生時：
```bash
# タグを削除
git tag -d v1.2.0
git push origin :refs/tags/v1.2.0

# main を前のコミットにリセット（必要な場合）
git revert <commit-hash>
```

## 備考
- AI-DLC Starter Kit はテンプレート/ツールのため、サーバーデプロイは不要
- GitHub でのリリースがデプロイに相当
