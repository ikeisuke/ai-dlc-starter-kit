# Unit 3: タグ付け自動化

## 概要
mainブランチへのマージ時にversion.txtを読んで自動でGitタグを作成するGitHub Actionsを導入

## 含まれるユーザーストーリー
- ストーリー 2.1: マージ後のタグ付け自動化

## 責務
- GitHub Actionsワークフローの作成
- version.txt読み込みとタグ作成ロジック
- 既存タグチェック（重複防止）

## 境界
- タグ作成のみ、リリースノート生成等は行わない

## 依存関係

### 依存するUnit
- なし

### 外部依存
- GitHub Actions
- Git

## 非機能要件（NFR）
- **パフォーマンス**: ワークフロー実行時間1分以内
- **セキュリティ**: デフォルトのGITHUB_TOKENを使用
- **スケーラビリティ**: 該当なし
- **可用性**: GitHub Actionsの可用性に依存

## 技術的考慮事項
- 新規作成ファイル: `.github/workflows/auto-tag.yml`
- トリガー: mainブランチへのpush（マージ）
- version.txtパス: `docs/aidlc/version.txt`
- タグ形式: `vX.Y.Z`
- 既存タグがある場合はスキップ（エラーにしない）

## 実装優先度
Medium

## 見積もり
1時間
