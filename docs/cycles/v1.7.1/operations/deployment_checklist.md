# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.7.1
- **デプロイ予定日**: 2026-01-11
- **デプロイ環境**: GitHub リポジトリ
- **デプロイ方式**: mainブランチへのマージ + 自動タグ作成

## デプロイ前チェックリスト

### コード品質

- [x] 全Unitの実装が完了している（8/8 Unit完了）
- [ ] Markdownlintが通っている
- [ ] コードレビュー（PRレビュー）が完了している

### バージョン管理

- [x] version.txt が更新されている（1.7.1）
- [x] CHANGELOG.md が更新されている
- [x] README.md が更新されている

### ドキュメント

- [ ] 新機能のドキュメントが作成されている
- [ ] テンプレートの更新が完了している（メタ開発特有）

## デプロイ手順

### 1. 事前準備（ステップ1-5）

```bash
# バージョン確認
cat version.txt
```

### 2. メタ開発固有の処理

```bash
# AI-DLC環境アップグレード（prompts/setup-prompt.md を使用）
# prompts/package/ → docs/aidlc/ への同期
```

### 3. リリース準備（ステップ6）

```bash
# CHANGELOG.md 更新
# README.md 更新
# 最終コミット
git add -A && git commit -m "chore: [v1.7.1] Operations Phase完了"
```

### 4. PR作成・マージ

```bash
# PRをReady for Reviewに変更
gh pr ready

# PRをマージ（レビュー後）
gh pr merge --merge
```

### 5. タグ作成（自動）

```bash
# GitHub Actionsが自動で v1.7.1 タグを作成
```

## ロールバック手順

```bash
# 前のバージョンに戻す場合
git checkout v1.7.0
```

## デプロイ後チェックリスト

- [ ] タグ v1.7.1 が作成されている
- [ ] GitHub Releasesが作成されている（オプション）
- [ ] サイクルブランチが削除されている

## 今回のリリース内容

### 追加機能（8 Units）

1. **Unit 001**: バックログモード修正
2. **Unit 002**: バックログラベル作成
3. **Unit 003**: AskUserQuestion順序ルール
4. **Unit 004**: AIレビューイテレーション
5. **Unit 005**: Unitブランチ設定
6. **Unit 006**: 複合コマンド削減
7. **Unit 007**: iOSバージョンタイミング
8. **Unit 008**: jjサポート有効化フラグ
