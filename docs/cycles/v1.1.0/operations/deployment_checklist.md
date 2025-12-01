# デプロイチェックリスト

## デプロイ情報
- **バージョン**: v1.1.0
- **デプロイ方式**: PR経由で feature/v1.1.0 → main へマージ
- **対象**: AI-DLCスターターキット（プロンプトファイル群）

## PR作成前チェックリスト

### 実装完了確認
- [x] Unit 1: Operations Phase再利用性 - 完了
- [x] Unit 2: 軽量サイクル（Lite版） - 完了
- [x] Unit 3: ブランチ確認機能 - 完了
- [x] Unit 4: コンテキストリセット提案機能 - 完了

### 品質確認
- [x] プロンプトファイルの構文・フォーマットが正しい
- [x] 既存のAI-DLC基本フローが維持されている
- [x] 新機能の使い方が各プロンプトに記載されている

### ドキュメント
- [x] 変更内容の概要が明確（Intent, Unit定義に記載）
- [x] 各Unitのユーザーストーリーが定義されている

## PR作成・マージ手順

### 1. 事前確認
```bash
# 現在のブランチ確認
git branch --show-current

# mainとの差分確認
git diff main...HEAD --stat
```

### 2. PR作成
```bash
gh pr create --base main --title "feat: v1.1.0 - AI-DLC実用性向上" --body "..."
```

### 3. マージ実行
- PRレビュー・承認後にマージ

## ロールバック手順

問題が発生した場合：
```bash
# マージコミットを特定
git log --oneline -5

# revertで取り消し
git revert -m 1 <merge-commit-hash>
git push origin main
```

## 不明点と質問

[Question] デプロイ方式は？
[Answer] PR経由でmainブランチへマージ
