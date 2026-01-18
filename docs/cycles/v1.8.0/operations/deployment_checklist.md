# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.8.0
- **デプロイ予定日**: 2026-01-18
- **デプロイ環境**: GitHub リポジトリ（公開）
- **担当者**: Claude AI / プロジェクト管理者

## デプロイ前チェックリスト

### コード品質

- [x] すべてのUnitが完了している（15/15）
- [x] コードレビューが完了している（各Unit完了時に実施）
- [ ] Markdownlintがパスしている

### バージョン管理

- [x] version.txt が 1.8.0 に更新されている
- [ ] aidlc.toml の starter_kit_version が 1.8.0 に更新されている
- [ ] CHANGELOG.md が更新されている
- [ ] README.md が更新されている

### ドキュメント

- [ ] 新機能のドキュメントが完成している
- [ ] 変更履歴が記録されている
- [ ] 移行ガイドが必要な場合は作成されている

### メタ開発固有

- [ ] `prompts/package/` の変更が `docs/aidlc/` に同期されている
- [ ] セットアップテストが正常に動作する

## デプロイ手順

### 1. 事前準備

```bash
# 現在のブランチ確認
git branch --show-current

# 変更の確認
jj status
```

### 2. メタ開発アップグレード処理

```bash
# setup-prompt.mdを読み込んでアップグレード
# prompts/package/ → docs/aidlc/ の同期を実行
```

### 3. 最終コミット

```bash
# Operations Phase完了コミット
jj describe -m "feat: [v1.8.0] Operations Phase完了"
jj new
```

### 4. PR作成・マージ

```bash
# PR作成（Ready for Review）
gh pr create --base main --title "v1.8.0" --body "..."

# または既存のドラフトPRをReady化
gh pr ready [PR番号]
```

### 5. タグ作成（自動）

- mainブランチへマージ後、GitHub Actionsが自動でv1.8.0タグを作成

## ロールバック手順

問題が発生した場合：

```bash
# 前のバージョンに戻す場合
git checkout v1.7.4
```

## デプロイ後チェックリスト

- [ ] GitHub上でタグが作成されている
- [ ] セットアップテストが正常に動作する
- [ ] 新規プロジェクトでのセットアップが成功する

## 緊急連絡先

- **担当者**: プロジェクト管理者
- **エスカレーション先**: リポジトリ管理者

## 備考

- このプロジェクトはAI-DLCスターターキット自体を開発するメタ開発プロジェクト
- v1.8.0の主要変更: jjサポート、markdownlint設定、Unit完了チェック、フェーズ引き継ぎ機能、worktreeサブディレクトリ化、プロンプト最適化準備

## 不明点と質問（Operations Phase中に記録）

特になし
