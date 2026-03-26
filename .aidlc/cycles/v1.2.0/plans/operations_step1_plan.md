# Operations Phase ステップ1: デプロイ準備 計画

## 概要
AI-DLC Starter Kit v1.2.0 のデプロイ準備を行う

## デプロイ方式
- PR作成 → mainブランチへマージ → GitHub Actions による自動タグ付け

## 現状確認
- **現在のブランチ**: cycle/v1.2.0
- **現在の version.txt**: 1.0.1（更新が必要）
- **GitHub Actions**: auto-tag.yml が設定済み（main への push 時に version.txt を読み取りタグを作成）

## 実施内容

### 1. バージョン更新
- `version.txt`（ルート）を `1.2.0` に更新

### 2. デプロイチェックリスト作成
- `docs/cycles/v1.2.0/operations/deployment_checklist.md` を作成
- AI-DLC Starter Kit に適した形式にカスタマイズ

### 3. 現在の変更をコミット
- Operations Phase の成果物をコミット

### 4. リモートへプッシュ
- cycle/v1.2.0 ブランチをリモートにプッシュ

### 5. PR作成
- cycle/v1.2.0 → main への PR を作成
- PR内容にv1.2.0の変更サマリーを含める

## 成果物
- `docs/cycles/v1.2.0/operations/deployment_checklist.md`
- version.txt の更新
- GitHub PR

## 次のステップ
- PR承認・マージ後、GitHub Actions が自動でタグ v1.2.0 を作成
