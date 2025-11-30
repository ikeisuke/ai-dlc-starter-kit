# デプロイチェックリスト

## デプロイ情報
- **バージョン**: v1.0.1
- **デプロイ予定日**: 2025-11-29
- **デプロイ方式**: タグ付きで main ブランチにマージ（GitHub Release 作成なし）
- **担当者**: AI-DLC による自動実行

## デプロイ前チェックリスト

### ドキュメント品質
- [ ] すべてのテンプレートファイルが正しく作成されている
- [ ] プロンプトファイルの整合性が保たれている
- [ ] リンク切れがない
- [ ] 表記揺れが解消されている（変数置換ルールの適用）

### バージョン管理ファイル
- [ ] `docs/aidlc/version.txt` を `1.0.1` に更新
- [ ] `CHANGELOG.md` の v1.0.1 エントリが最新
- [ ] `README.md` のバージョンバッジを `1.0.1` に更新

### Construction Phase 成果物
- [ ] Unit 1: セットアップバグ修正 - 完了
- [ ] Unit 2: バージョンアップ基盤 - 完了
- [ ] Unit 3: 表記揺れ対策 - 完了
- [ ] Unit 5: Issue駆動統合設計 - 延期（AI-DLC成熟後に再検討）
- [ ] Unit 6: テストとバグ対応基盤 - 完了
- [ ] Unit 7: プロンプト参照ガイド - 完了

### Git 状態
- [ ] すべての変更がコミットされている
- [ ] feature/v1.0.1 ブランチが最新
- [ ] コンフリクトがない

## デプロイ手順

### 1. 事前準備
```bash
# 現在のブランチ確認
git branch

# 変更状況確認
git status
```

### 2. バージョンファイル更新
```bash
# version.txt 更新
echo "1.0.1" > docs/aidlc/version.txt

# README.md バージョンバッジ更新（手動またはスクリプト）
# 1.0.0 → 1.0.1
```

### 3. 最終コミット
```bash
# 変更をステージング
git add .

# コミット
git commit -m "chore: v1.0.1 リリース準備 - バージョンファイル更新"
```

### 4. main ブランチへマージ
```bash
# main ブランチに切り替え
git checkout main

# 最新化
git pull origin main

# マージ
git merge feature/v1.0.1

# プッシュ
git push origin main
```

### 5. タグ作成
```bash
# タグ作成
git tag -a v1.0.1 -m "v1.0.1 - バグ修正と継続的改善の仕組み構築"

# タグをプッシュ
git push origin v1.0.1
```

### 6. 動作確認
- [ ] main ブランチにすべての変更が反映されている
- [ ] タグ v1.0.1 が作成されている
- [ ] CHANGELOG.md が正しく表示される

## ロールバック手順

問題が発生した場合の手順：

```bash
# タグを削除（ローカル）
git tag -d v1.0.1

# タグを削除（リモート）
git push origin :refs/tags/v1.0.1

# main を前の状態に戻す
git checkout main
git revert HEAD

# または、強制的に戻す（注意が必要）
git reset --hard <前のコミットハッシュ>
git push origin main --force
```

## デプロイ後チェックリスト
- [ ] main ブランチの内容が正しい
- [ ] タグ v1.0.1 が GitHub で確認できる
- [ ] CHANGELOG.md がリポジトリトップで確認できる
- [ ] README.md のバージョンバッジが 1.0.1 を表示

## 備考
- このプロジェクトはドキュメント・テンプレート中心のスターターキット
- サーバーデプロイやデータベースマイグレーションは不要
- GitHub Release の正式作成は行わない（タグのみ）

## 不明点と質問（Operations Phase中に記録）

[Question] v1.0.1 のリリース方法について、以下のどちらを想定していますか？
[Answer] タグ（v1.0.1）を作成して main にマージ。GitHub Releases ページでの正式リリース作成は不要。

[Question] CHANGELOG.md や README.md の更新は必要ですか？
[Answer] 両方を更新する。特に CHANGELOG.md は v1.0.1 のバージョンアップ基盤機能で使用するため必須。
