# デプロイチェックリスト

## デプロイ情報

- **バージョン**: 1.7.4
- **デプロイ予定日**: 2026-01-14
- **デプロイ環境**: GitHub リポジトリ（公開）
- **担当者**: AI

## デプロイ前チェックリスト

### コード品質

- [x] すべてのUnitが完了している
- [x] Markdownlintでエラーがない
- [x] AIレビューが完了している（MCPレビュー）
- [ ] PRレビューが完了している

### 環境設定

- [x] version.txt が 1.7.4 に更新されている
- [x] docs/aidlc.toml の設定が正しい
- [x] starter_kit_version が更新される予定（アップグレード処理で更新）

### ドキュメント

- [ ] README.md が更新されている
- [ ] CHANGELOG.md が更新されている
- [x] Unit定義ファイルが完了状態になっている
- [x] 履歴ファイルが記録されている

## デプロイ手順

### 1. メタ開発: AI-DLC環境アップグレード

```bash
# setup-prompt.md を読み込んでアップグレード処理を実行
# rsync による prompts/package/ → docs/aidlc/ 同期
# aidlc.toml のマイグレーション
```

### 2. リリース準備

```bash
# CHANGELOG.md 更新
# README.md 更新
# Markdownlint実行
npx markdownlint-cli2 "docs/cycles/v1.7.4/**/*.md" "prompts/**/*.md" "*.md"
```

### 3. コミット・プッシュ

```bash
# Operations Phase完了コミット
jj describe -m "chore: [v1.7.4] Operations Phase完了 - デプロイ、CI/CD、監視を構築"
jj new
jj git push
```

### 4. PR Ready化

```bash
# ドラフトPRをReady for Reviewに変更
gh pr ready
```

### 5. PRマージ後

```bash
# mainブランチに移動
git checkout main
git pull origin main

# バージョンタグ付け（自動）
# GitHub Actionsが version.txt を読み取り v1.7.4 タグを作成

# マージ済みブランチの削除
git branch -d cycle/v1.7.4
```

## ロールバック手順

問題が発生した場合の手順：

```bash
# 前のバージョンに戻す場合
git checkout v1.7.3
```

## デプロイ後チェックリスト

- [ ] PRがマージされている
- [ ] v1.7.4 タグが作成されている
- [ ] README.md の内容が正しい
- [ ] 新規ユーザーがセットアップできることを確認

## 今回の変更内容（v1.7.4）

### Added

- ツールインストール案内セクション（setup-prompt.md）
- サブエージェント活用ガイド（construction.md）
- KiroCLI対応セクション（AGENTS.md）
- 質問深掘りルール（AGENTS.md）
- 受け入れ基準の書き方ガイダンス（inception.md）

### Fixed

- issue-onlyモードでのGitHub CLI検証・サイクルラベル作成の正常動作
- 未追跡ファイルのみ存在する場合のコミット処理

## 備考

- このプロジェクトはメタ開発のため、Operations Phase完了前にsetup-prompt.mdでアップグレード処理が必要
- project.type = general のため、配布ステップ（ステップ4）はスキップ
