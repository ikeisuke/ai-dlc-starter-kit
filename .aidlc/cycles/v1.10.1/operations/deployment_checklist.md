# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.10.1
- **デプロイ予定日**: 2026-01-28
- **デプロイ環境**: GitHub リポジトリ公開
- **担当者**: AI-DLC開発者

## デプロイ前チェックリスト

### コード・ドキュメント品質

- [x] すべてのUnitが完了している（5/5 Unit完了）
- [x] Construction Phaseが正常に完了している
- [ ] PRレビューが完了している（ステップ6で実施）
- [ ] CHANGELOG.mdが更新されている（ステップ6で実施）

### バージョン管理

- [x] version.txt が更新されている（1.10.1）
- [ ] README.mdが更新されている（ステップ6で実施）
- [ ] docs/aidlc.toml の starter_kit_version が更新されている（アップグレード処理で実施）

### CI/CD確認

- [ ] GitHub Actions が正常に動作している
- [ ] PRチェックワークフローがパスしている

## デプロイ手順

### 1. 事前準備（Operations Phase内）

```bash
# バージョン確認
cat version.txt  # 1.10.1 であることを確認

# 変更内容確認
jj status
jj log
```

### 2. メタ開発特有の処理

```bash
# prompts/package/ から docs/aidlc/ への同期
# setup-prompt.md のアップグレード処理で実施
```

### 3. リリース準備

```bash
# CHANGELOG.md更新
# README.md更新
# コミット
jj describe -m "chore: [v1.10.1] Operations Phase完了"
jj new
```

### 4. PR作成・マージ

```bash
# PRをReady for Reviewに変更
gh pr ready {PR番号}

# PRマージ後
git checkout main
git pull origin main
```

### 5. タグ付け

```bash
# 自動タグ付け（GitHub Actions）
# version.txt の内容に基づいて v1.10.1 タグが自動作成される
```

## ロールバック手順

問題が発生した場合:

```bash
# 前のバージョンに戻す
git checkout v1.10.0

# 必要に応じてmainに反映
git checkout main
git reset --hard v1.10.0
git push origin main --force  # 注意: 強制プッシュ
```

## デプロイ後チェックリスト

- [ ] タグが正常に作成されている
- [ ] GitHub Releasesにリリースが作成されている（任意）
- [ ] READMEの内容が正しい
- [ ] セットアップが正常に動作する（別ディレクトリでテスト推奨）

## 緊急連絡先

- **担当者**: リポジトリオーナー
- **Issue報告**: https://github.com/ikeisuke/ai-dlc-starter-kit/issues

## 今回のサイクルの変更点

### Unit 001: README.mdバージョン履歴の表示順序修正

- バージョン履歴を降順（新しい順）に変更

### Unit 002: PRマージ後の確認手順追加

- Operations Phaseにマージ確認のプロンプト追加

### Unit 003: Codex Skillの再開機能明確化

- resume引数の使い方を明確化

### Unit 004: gh (GitHub CLI) Skill追加

- GitHub CLIのAI-DLC向けスキルを追加

### Unit 005: jj (Jujutsu) Skill追加

- Jujutsuバージョン管理のAI-DLC向けスキルを追加

## 備考

- メタ開発プロジェクトのため、ステップ5と6の間でアップグレード処理を実行すること
- 運用引き継ぎ情報: `docs/cycles/operations.md` を参照
