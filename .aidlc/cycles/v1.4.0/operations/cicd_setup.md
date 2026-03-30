# CI/CD設定 - v1.4.0

## 概要
v1.2.1で構築したCI/CD設定を継続使用。

## 設定ファイル
- `.github/workflows/auto-tag.yml` - 自動タグ付けワークフロー

## 自動タグ付けの仕組み
1. mainブランチにpush
2. `version.txt` からバージョンを読み取り
3. 同名タグが存在しなければ `v{VERSION}` タグを作成・push

## v1.4.0での変更
- なし（既存設定を継続）

## 将来検討事項
- Markdownリンター（markdownlint）
- テンプレート整合性チェック
- PR時の自動レビュー
