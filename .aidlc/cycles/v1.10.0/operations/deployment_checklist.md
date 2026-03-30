# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.10.0
- **デプロイ予定日**: 2026-01-28
- **デプロイ環境**: GitHub リポジトリ（公開）
- **担当者**: 開発者

## デプロイ前チェックリスト

### コード品質

- [ ] PRチェック（Markdownlint）がパスしている
- [ ] コードレビューが完了している

### ドキュメント

- [ ] version.txt が更新されている（1.10.0）
- [ ] CHANGELOG.md が更新されている
- [ ] README.md が更新されている（変更履歴、新機能など）

### 整合性確認

- [ ] prompts/package/ → docs/aidlc/ のrsync同期が完了している
- [ ] aidlc.toml の starter_kit_version が更新されている

## デプロイ手順

### 1. 事前準備（ステップ5と6の間）

```bash
# setup-prompt.md でアップグレード処理を実行
# - rsync による prompts/package/ → docs/aidlc/ 同期
# - aidlc.toml のマイグレーション
# - starter_kit_version の更新
```

### 2. リリース準備

```bash
# CHANGELOG.md 更新
# README.md 更新
# コミット作成
```

### 3. PR作成・マージ

```bash
# ドラフトPRをReady for Reviewに変更
gh pr ready {PR番号}

# レビュー後マージ
```

### 4. タグ作成（自動）

```bash
# GitHub Actions が自動で v1.10.0 タグを作成
# version.txt の内容に基づく
```

## ロールバック手順

問題が発生した場合の手順：

```bash
# 前のバージョンに戻す場合
git checkout v1.9.3
```

## デプロイ後チェックリスト

- [ ] タグ v1.10.0 が作成されている
- [ ] GitHub Releases でリリースノートが作成されている（オプション）
- [ ] 新機能が正しく動作する

## 備考

- メタ開発プロジェクトのため、ステップ5と6の間でsetup-prompt.mdによるアップグレード処理が必須
- GitHub Actions による自動タグ付け機能を使用

## 不明点と質問（Operations Phase中に記録）

（なし - 運用引き継ぎ情報により手順が明確）
