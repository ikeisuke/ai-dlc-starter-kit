# CI/CD 設定

## 現状

GitHub Actions で自動タグ付けが設定済み。

## 設定ファイル

- `.github/workflows/auto-tag.yml` - 自動タグ付けワークフロー

## 自動タグ付けの仕組み

1. main ブランチに push
2. `version.txt` からバージョンを読み取り
3. 同名タグが存在しなければ `v{VERSION}` タグを作成・push

## リリースフロー

1. サイクルブランチで `version.txt` を更新（例: 1.4.1）
2. main ブランチへマージ
3. GitHub Actions が自動で `v1.4.1` タグを作成

## 今回のサイクルでの変更

なし（既存の設定を継続使用）

## 将来検討事項

- Markdown リンター（markdownlint）
- テンプレート整合性チェック
- PR 時の自動レビュー
