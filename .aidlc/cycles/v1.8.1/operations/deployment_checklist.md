# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.8.1
- **デプロイ予定日**: 2026-01-20
- **デプロイ環境**: GitHub リポジトリ（公開）
- **担当者**: AI

## デプロイ前チェックリスト

### コード・ドキュメント品質

- [ ] すべてのUnit実装が完了している
- [ ] version.txt が新バージョンに更新されている
- [ ] starter_kit_version が更新されている（メタ開発のためアップグレード時に自動）

### ファイル整合性

- [ ] prompts/package/ の変更が docs/aidlc/ に反映されている（rsync）
- [ ] テンプレートファイルに破損がない
- [ ] 参照パスが正しい

### ドキュメント

- [ ] README.md が更新されている
- [ ] CHANGELOG.md が更新されている
- [ ] 履歴ファイル（history/*.md）が記録されている

## デプロイ手順

### 1. 事前準備（メタ開発特有）

```bash
# prompts/setup-prompt.md を読み込んでアップグレード
# → rsync による docs/aidlc/ 同期
# → aidlc.toml マイグレーション
```

### 2. バージョン確認

```bash
# version.txt 確認
cat version.txt
# 期待値: 1.8.1

# starter_kit_version 確認（アップグレード後）
grep starter_kit_version docs/aidlc.toml
```

### 3. コミット・プッシュ

```bash
# jj を使用（jj.enabled = true）
jj describe -m "chore: [v1.8.1] Operations Phase完了"
jj git push
```

### 4. PR作成・マージ

```bash
# ドラフトPR を Ready for Review に変更
gh pr ready

# または新規PR作成
gh pr create --base main --title "v1.8.1"
```

### 5. 自動タグ付け

- mainブランチへのマージ後、GitHub Actions が自動で v1.8.1 タグを作成

## ロールバック手順

問題が発生した場合の手順：

```bash
# 前のバージョンに戻す場合
git checkout v1.8.0
```

## デプロイ後チェックリスト

- [ ] GitHub上でタグが作成されている
- [ ] README.md の変更が反映されている
- [ ] 別ディレクトリでセットアップをテスト（オプション）

## 備考

- このプロジェクトはメタ開発（AI-DLCスターターキット自体の開発）
- CI/CD: GitHub Actions による自動タグ付け（.github/workflows/auto-tag.yml）
- ロールバック: git checkout で前バージョンに戻す

## 不明点と質問

なし（前回サイクルの設定を引き継ぎ）
