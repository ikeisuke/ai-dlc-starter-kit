# CI/CD設定

## 概要
v1.6.1で追加のCI/CD設定変更は不要。既存の設定を継続使用。

## 既存ワークフロー

### 1. 自動タグ作成（auto-tag.yml）
- **トリガー**: mainブランチへのpush
- **動作**: version.txtからバージョンを読み取り、`v{VERSION}`タグを自動作成
- **状態**: 正常稼働中

### 2. PRチェック（pr-check.yml）
- **トリガー**: mainブランチへのPR作成
- **動作**: markdownlintによるMarkdownファイルの検証
- **対象**: docs/translations/, prompts/, ルートのMarkdownファイル
- **状態**: 正常稼働中

## リリースフロー
1. サイクルブランチで開発完了
2. `version.txt` を新バージョンに更新
3. PRを作成（markdownlintが自動実行）
4. レビュー・マージ
5. mainマージ時にGitHub Actionsが自動でタグ作成

## 備考
- 追加のワークフロー変更なし
- 将来検討: テンプレート整合性チェック
