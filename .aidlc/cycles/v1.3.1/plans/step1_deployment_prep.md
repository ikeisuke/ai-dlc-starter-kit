# ステップ1: デプロイ準備 計画

## 概要
v1.3.1 のデプロイチェックリストを作成する

## 今回のサイクル内容
- Unit 1: バックログ対応済みチェック機能
- Unit 2: セットアップスキップ機能
- Unit 3: Dependabot PR確認機能

## 運用引き継ぎ情報からの確認
前回サイクル（v1.2.x）のデプロイ方針を継続：
- デプロイ方式: GitHubリポジトリとして公開
- リリース方法: mainブランチへのマージ + タグ作成（自動）
- バージョニング: セマンティックバージョニング

## 作成するチェックリスト
ドキュメント・テンプレートプロジェクトに適した項目：

### コード品質（該当項目のみ）
- prompts/package/ の変更内容確認
- Markdownファイルの整合性確認

### メタ開発特有の作業
- version.txt を 1.3.1 に更新
- setup-init 実行（docs/aidlc/ を最新化）

### ドキュメント
- README.md 更新

### デプロイ手順
1. version.txt 更新
2. setup-init 実行
3. Operations Phase 完了コミット
4. PR 作成
5. PR マージ → 自動タグ作成

## 成果物
`docs/cycles/v1.3.1/operations/deployment_checklist.md`
