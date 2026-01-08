# Operations Phase 計画

サイクル: v1.5.4

## 概要

AI-DLC スターターキット v1.5.4 のリリース準備。バグ修正と機能改善を含む7つのUnitが完了済み。

## 主要な変更内容（v1.5.4）

### バグ修正
- AIレビュー必須設定が機能しない問題の修正
- macOSのgrep -oP互換性問題の修正
- Unitブランチ作成時にPRが作成されない問題の修正

### 機能改善
- AGENTS.md/CLAUDE.md統合
- スターターキットアップグレードフロー改善
- バックログ移行時の重複警告機能
- markdownlintルール有効化（MD009, MD034, MD040）

## 実行計画

### ステップ1: デプロイ準備
- version.txt を 1.5.3 → 1.5.4 に更新
- デプロイチェックリスト確認（運用引き継ぎ設定を再利用）
- 成果物: `deployment_checklist.md`

### ステップ2: CI/CD構築
- 既存の auto-tag.yml、pr-check.yml を確認
- 新たな設定変更は不要（既存設定で対応可能）
- 成果物: `cicd_setup.md`

### ステップ3: 監視・ロギング戦略
- ドキュメントプロジェクトのため監視設定は不要
- 運用引き継ぎの設定を継続
- 成果物: `monitoring_strategy.md`

### ステップ4: 配布
- スキップ（project.type: general）

### ステップ5: バックログ整理と運用計画
- 対応済みバックログ項目を `backlog-completed/v1.5.4/` に移動
- 未対応項目は次サイクルへ引き継ぎ
- 成果物: `post_release_operations.md`

### ステップ6: リリース準備
- README.md 更新
- 履歴記録
- Gitコミット
- ドラフトPR Ready化

## 参照設定

運用引き継ぎ（`docs/cycles/operations.md`）の設定を再利用:
- デプロイ方式: GitHubリポジトリ公開 + タグ作成
- CI/CD: GitHub Actions（auto-tag.yml による自動タグ付け）
- 監視: なし（ドキュメントプロジェクト）
