# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.9.3
- **デプロイ予定日**: 2026-01-26
- **デプロイ環境**: GitHub リポジトリ（公開）
- **担当者**: AI-DLC開発チーム

## デプロイ前チェックリスト

### コード品質

- [x] すべてのUnitが完了している（6/6完了）
- [x] コードレビューが完了している（AIレビュー実施済み）

### バージョン確認

- [x] version.txt が 1.9.3 に更新されている

### ドキュメント

- [ ] README.mdが更新されている
- [ ] CHANGELOG.mdが更新されている

## デプロイ手順

### 1. リリース準備

```bash
# Operations Phase 成果物をコミット
jj describe -m "chore: [v1.9.3] Operations Phase完了"
```

### 2. アップグレード処理（メタ開発）

```bash
# prompts/package/ → docs/aidlc/ 同期
# setup-prompt.md を読み込んで実行
```

### 3. PR作成・マージ

```bash
# ドラフトPRをReady for Reviewに変更
gh pr ready [PR番号]

# マージ後
git checkout main
git pull origin main
```

### 4. タグ作成（自動）

GitHub Actionsが自動で `v1.9.3` タグを作成

## ロールバック手順

問題が発生した場合：

```bash
# 前のバージョンに戻す
git checkout v1.9.2
```

## デプロイ後チェックリスト

- [ ] タグ v1.9.3 が作成されている
- [ ] GitHub Releasesにリリースノートがある（任意）

## 備考

- メタ開発プロジェクトのため、アップグレード処理（rsync）が必要
- ステップ5と6の間で実行すること
