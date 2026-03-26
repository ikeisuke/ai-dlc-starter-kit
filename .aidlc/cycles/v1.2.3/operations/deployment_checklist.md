# デプロイチェックリスト

## デプロイ情報
- **バージョン**: v1.2.3
- **デプロイ予定日**: 2025-12-09
- **デプロイ環境**: GitHub Repository（公開）
- **担当者**: AI-DLC

## 今回の変更内容
1. Lite版パス解決安定化
2. フェーズ遷移ガードレール強化
3. starter_kit_versionフィールド追加
4. 移行時ファイル削除確認追加
5. 日時記録必須ルール化
6. Inception Phaseステップ6削除

## デプロイ前チェックリスト

### コード品質
- [x] 全Unit（6件）が完了している
- [x] 実装がintentの要件を満たしている
- [x] 各Unit完了時にコミット済み

### バージョン更新（メタ開発特有）
- [ ] `version.txt` を 1.2.3 に更新
- [ ] setup-init実行で `docs/aidlc/` を最新化

### ドキュメント
- [ ] README.md更新（変更履歴）

## デプロイ手順

### 1. バージョン更新
```bash
echo "1.2.3" > version.txt
```

### 2. setup-init実行（アップグレードモード）
```bash
# prompts/setup-init.md をアップグレードモードで実行
# セクション7.2: rsync で prompts/package/ → docs/aidlc/ に同期
```

### 3. README.md更新
変更履歴セクションにv1.2.3の内容を追記

### 4. Operations Phase完了コミット
```bash
git add .
git commit -m "chore: Operations Phase完了 - v1.2.3"
```

### 5. PR作成
```bash
gh pr create --base main --title "v1.2.3" --body "..."
```

### 6. PRマージ（手動）
GitHub上でPRをマージ

### 7. 自動タグ作成
GitHub Actionsが `v1.2.3` タグを自動作成

## ロールバック手順

問題が発生した場合：
```bash
git checkout v1.2.2
```

## デプロイ後チェックリスト
- [ ] タグ `v1.2.3` が作成されている
- [ ] README.mdが更新されている
- [ ] 新規クローンでセットアップが動作する

## 備考
- パッチリリース（破壊的変更なし）
- 前サイクル（v1.2.2）の運用設定を継続
