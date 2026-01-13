# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.7.3
- **デプロイ予定日**: 2026-01-13
- **デプロイ環境**: GitHub Repository（公開リポジトリ）
- **担当者**: @ai-assistant

## デプロイ前チェックリスト

### コード品質

- [x] すべてのUnitが完了している
- [ ] ビルド（markdownlint）が成功している
- [ ] コードレビューが完了している（PR承認）

### ドキュメント

- [ ] README.mdが更新されている（変更履歴）
- [ ] CHANGELOG.mdが更新されている
- [ ] version.txtが更新されている: 1.7.3

### CI/CD

- [ ] GitHub Actions設定が正しい
- [ ] auto-tag.ymlで自動タグ付けが有効

## デプロイ手順

### 1. 事前準備

```bash
# 現在のブランチ確認
git branch --show-current

# リモートとの差分確認
git fetch origin
git log origin/main..HEAD --oneline
```

### 2. リリース準備

```bash
# Markdownlint実行
npx markdownlint-cli2 "docs/**/*.md" "prompts/**/*.md" "*.md"

# ステータス確認
git status
```

### 3. コミット・プッシュ

```bash
# 変更をコミット
git add -A
git commit -m "chore: [v1.7.3] Operations Phase完了"

# プッシュ
git push origin cycle/v1.7.3
```

### 4. PR作成・マージ

```bash
# PRをReady for Reviewに変更（ドラフトPRがある場合）
gh pr ready

# PRタイトル更新
gh pr edit --title "v1.7.3"
```

### 5. タグ付け（自動）

mainブランチへのマージ後、GitHub Actionsが自動で `v1.7.3` タグを作成

## ロールバック手順

問題が発生した場合の手順：

```bash
# 前のバージョンに戻す場合
git checkout v1.7.2

# 必要に応じてrevertコミット
git revert HEAD
```

## デプロイ後チェックリスト

- [ ] タグ v1.7.3 が作成されている
- [ ] mainブランチが最新状態
- [ ] GitHub Releasesでリリースノート作成（任意）

## v1.7.3 リリース内容

### 変更点

1. **Unit 001: ドキュメント整合性修正**
   - ステップ番号の統一
   - リリース内容の完全な記録
   - CIとチェックリストの整合性
   - YAML抜粋の正確性
   - 設定ファイルの整理
   - ドラフトPR表記の簡素化

2. **Unit 002: daselによるTOML読み込み対応**
   - setup-prompt.mdでのdasel活用
   - dasel未インストール時のフォールバック処理

3. **Unit 003: Markdownlint対象範囲の最適化**
   - Construction Phaseでのlint対象範囲の最適化
   - 現在サイクルまたは変更ファイルのみを対象

4. **Unit 004: jjサポートの改善**
   - jj作業フローの明確化
   - 作業開始・終了時のガイド追加
   - jj設定の推奨事項追加

## 備考

- このプロジェクトはドキュメント・テンプレートプロジェクトのため、従来のアプリケーションデプロイとは異なる
- メタ開発のため、Operations Phase完了前にAI-DLC環境のアップグレードが必要
