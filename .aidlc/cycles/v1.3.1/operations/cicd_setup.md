# CI/CD設定

## 概要
v1.3.1 では既存のCI/CD設定を継続使用する。新規設定の追加は不要。

## 既存設定

### 自動タグ付けワークフロー
- **ファイル**: `.github/workflows/auto-tag.yml`
- **トリガー**: mainブランチへのpush
- **動作**: `version.txt` からバージョンを読み取り、タグが存在しなければ作成

### リリースフロー
1. サイクルブランチで `version.txt` を更新（例: 1.3.1）
2. PRを作成してmainブランチへマージ
3. GitHub Actionsが自動で `v1.3.1` タグを作成・push

## v1.3.1 での変更
なし（既存設定で十分）

## 将来検討事項
運用引き継ぎ情報（docs/cycles/operations.md）より：
- Markdownリンター（markdownlint）の導入
- テンプレート整合性チェック
- PR時の自動レビュー

これらは次回以降のサイクルで検討。
