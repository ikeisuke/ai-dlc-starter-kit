# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.9.2
- **デプロイ予定日**: 2026-01-26
- **デプロイ環境**: GitHub リポジトリ
- **担当者**: AI-DLC ユーザー

## デプロイ前チェックリスト

### コード品質

- [x] すべてのUnitが完了している（001-005）
- [x] コードレビュー完了（AI-DLCプロセスによる）

### バージョン管理

- [x] version.txt が 1.9.2 に更新されている
- [ ] CHANGELOG.md が更新されている
- [ ] README.md が更新されている（変更履歴、新機能など）

### ドキュメント

- [x] Unit定義ファイルが完成
- [x] 設計ドキュメントが完成
- [ ] 運用引き継ぎ情報が更新されている

## デプロイ手順

### 1. メタ開発特有の準備（rsyncアップグレード）

```bash
# prompts/setup-prompt.md を読み込んでアップグレード処理実行
# prompts/package/ → docs/aidlc/ の同期
```

### 2. リリース準備

- CHANGELOG.md 更新
- README.md 更新
- 履歴記録

### 3. Gitコミット

```bash
# Operations Phase完了コミット
jj describe -m "chore: [v1.9.2] Operations Phase完了"
```

### 4. タグ付け（mainブランチで実行）

```bash
# GitHub Actionsが自動でタグ作成（version.txt読み取り）
# または手動タグ付け
git tag -a v1.9.2 -m "Release v1.9.2"
git push origin v1.9.2
```

## ロールバック手順

問題が発生した場合：

```bash
# 前のバージョンに戻す
git checkout v1.9.1
```

## デプロイ後チェックリスト

- [ ] タグが正しく作成されている
- [ ] GitHub上でリリースが確認できる
- [ ] セットアップテストが成功する

## 備考

- このプロジェクトはメタ開発（AI-DLCスターターキット自体の開発）
- 既にmainブランチにマージ済みの状態でOperations Phase開始

## v1.9.2 の主な変更点

### 新機能

1. **Unit 001**: プレリリースバージョンサポート（-alpha, -beta, -rc形式）
2. **Unit 002**: operations.mdサイズ最適化（付録を外部化）
3. **Unit 003**: ai_tools設定による複数AIサービス対応
4. **Unit 004**: AI著者情報の自動検出機能
5. **Unit 005**: KiroCLI Skills対応
