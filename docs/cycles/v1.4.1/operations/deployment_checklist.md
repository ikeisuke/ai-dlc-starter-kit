# デプロイチェックリスト

## デプロイ情報
- **バージョン**: v1.4.1
- **デプロイ予定日**: 2025-12-19
- **デプロイ環境**: GitHub リポジトリ（公開）
- **担当者**: AI

## デプロイ前チェックリスト

### コード品質
- [x] すべての Unit が完了している
- [x] 設計レビューが完了している
- [x] Construction Phase で作成したファイルがコミットされている
- [ ] セキュリティスキャンが完了している（該当なし：ドキュメントプロジェクト）

### バージョン管理
- [x] version.txt が更新されている（1.4.1）
- [x] サイクルブランチで作業している（cycle/v1.4.1）
- [ ] docs/aidlc/ が最新化されている

### ドキュメント
- [ ] README.md が更新されている（変更履歴、新機能など）
- [x] 各 Unit の設計ドキュメントが作成されている
- [x] 各 Unit の実装記録が作成されている

## デプロイ手順

### 1. 事前準備（完了済み）
```bash
# version.txt 更新
echo "1.4.1" > version.txt

# docs/aidlc/ 最新化
rsync -av --delete \
  --exclude='rules.md' \
  --exclude='operations.md' \
  prompts/package/ docs/aidlc/
```

### 2. README.md 更新
- 変更履歴セクションに v1.4.1 の内容を追記

### 3. PR 作成
```bash
gh pr create --base main --title "v1.4.1" --body "..."
```

### 4. マージ後の自動処理
- GitHub Actions が自動でタグ `v1.4.1` を作成

## ロールバック手順

問題が発生した場合の手順：

```bash
# 前のバージョンに戻す場合
git checkout v1.4.0
```

## デプロイ後チェックリスト
- [ ] タグ v1.4.1 が作成されている
- [ ] main ブランチにマージされている
- [ ] README.md の変更内容が正しく表示されている

## 今回のサイクルの変更内容

### Unit 001: コミットハッシュ記録廃止
- unit_definition_template.md からコミットフィールドを削除

### Unit 002: Unit定義ファイル番号付け
- inception.md、construction.md に番号付けルールを追加
- unit_definition_template.md にファイル名規則を追加

### Unit 003: workaround時バックログ追加ルール
- construction.md に workaround 実施時のルールを追加

### Unit 004: README.mdリンク辿り
- setup-init.md にリンク辿りルールを追加

### Unit 005: CLIプロジェクトタイプ追加
- operations.md とテンプレートに cli タイプを追加

## 備考
- メタ開発プロジェクト（AI-DLC Starter Kit 自体の開発）
- ドキュメント・テンプレートの修正が中心

## 不明点と質問

なし（前回の運用引き継ぎ情報を参照）
