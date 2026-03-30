# Unit 7: タグ付け自動化 - 実装計画

## 概要
mainブランチへのマージ時に自動でGitタグを作成するGitHub Actionsワークフローを作成

## 成果物
- `.github/workflows/auto-tag.yml`

## 実装内容

### ワークフロー仕様
- **トリガー**: mainブランチへのpush
- **バージョン取得元**: `docs/aidlc/version.txt`
- **タグ形式**: `vX.Y.Z`
- **既存タグチェック**: 重複する場合はスキップ
- **権限**: `contents: write`

### 処理フロー
1. mainブランチへのpushを検知
2. `docs/aidlc/version.txt` からバージョンを取得
3. `v` プレフィックスを付けてタグ名を生成
4. 既存タグをチェック
5. タグが存在しなければ作成・push

## 完了基準
- ワークフローファイルが作成されている
- 構文エラーがない
