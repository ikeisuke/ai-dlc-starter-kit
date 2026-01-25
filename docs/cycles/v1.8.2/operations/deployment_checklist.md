# デプロイチェックリスト

## デプロイ情報

- **バージョン**: v1.8.2
- **デプロイ予定日**: 2026-01-21
- **デプロイ環境**: GitHub リポジトリ（公開）
- **担当者**: ikeisuke

## デプロイ前チェックリスト

### コード品質

- [ ] すべてのUnit（001-005）が完了している
- [ ] コードレビューが完了している（PR経由）
- [ ] Markdownlintエラーがない

### バージョン管理

- [x] version.txtが更新されている（1.8.2）
- [ ] CHANGELOG.mdが更新されている
- [ ] README.mdが更新されている

### ドキュメント

- [ ] prompts/package/ の変更が docs/aidlc/ に同期されている（rsync）
- [ ] 新機能のドキュメントが作成されている
- [ ] 既存ドキュメントの更新が完了している

## デプロイ手順

### 1. 事前準備

```bash
# jj/git の状態確認
jj status
jj log -r @-..@

# アップグレード処理（メタ開発特有）
# prompts/setup-prompt.md を読み込んでrsync実行
```

### 2. リリース準備

```bash
# CHANGELOG.md更新
# README.md更新
# 履歴記録
docs/aidlc/bin/write-history.sh \
    --cycle v1.8.2 \
    --phase operations \
    --step "リリース準備" \
    --content "Operations Phase完了" \
    --artifacts "deployment_checklist.md, CHANGELOG.md"
```

### 3. コミットとPR

```bash
# 変更をコミット
jj describe -m "chore: [v1.8.2] Operations Phase完了"

# ドラフトPRをReady for Reviewに変更
gh pr ready
```

### 4. 動作確認

- [ ] PRのCIチェックがパスする
- [ ] 変更内容が正しくマージされる

### 5. マージ後処理

```bash
# mainブランチに移動
jj bookmark set main -r @
jj git push

# タグ作成（GitHub Actionsで自動実行）
# version.txt から v1.8.2 タグが自動作成される

# ブランチ削除
jj bookmark delete cycle/v1.8.2
```

## ロールバック手順

問題が発生した場合:

```bash
# 前のバージョンに戻す
git checkout v1.8.1
```

## デプロイ後チェックリスト

- [ ] タグ v1.8.2 が作成されている
- [ ] GitHub Releasesでリリースノートが作成されている（オプション）
- [ ] 次サイクルの準備ができている

## 緊急連絡先

- GitHub Issues: https://github.com/ikeisuke/ai-dlc-starter-kit/issues

## 備考

- メタ開発のため、Operations Phase完了前にアップグレード処理（rsync）が必要
- GitHub Actionsによる自動タグ付けを使用
