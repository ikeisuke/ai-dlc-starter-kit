# 運用引き継ぎ情報

このファイルは、Operations Phaseで決定した運用設定・方針をサイクル横断で引き継ぐために使用します。
各サイクルのOperations Phase完了時に更新してください。

## 目的

- サイクル横断で運用設定・方針を引き継ぐ
- 毎回同じ質問をせずに済むよう、前回の設定を参照可能にする
- 運用で得た知見・注意事項を蓄積する

## 使い方

### Operations Phase開始時
1. このファイルが存在するか確認
2. 存在する場合、読み込んで前回の設定方針を確認
3. 再利用/更新/新規作成を選択

### Operations Phase完了時
1. 今回決定した設定方針をこのファイルに反映
2. 次サイクルで参照できるように更新

---

## プロジェクト概要

- **プロジェクト名**: AI-DLC Starter Kit
- **プロジェクトタイプ**: ドキュメント・テンプレートプロジェクト（general）
- **技術スタック**: Markdown、Claude Code
- **リポジトリ**: GitHub（ユーザーがクローンして利用）

---

## デプロイ方針

### デプロイ方式
- **方式**: GitHubリポジトリとして公開
- **リリース方法**: mainブランチへのマージ + タグ作成
- **バージョニング**: セマンティックバージョニング（v1.2.1形式）

### リリース手順
1. サイクルブランチで開発完了
2. `version.txt` を新バージョンに更新
3. setup-initを実行して `docs/aidlc/` を最新化
4. README.mdを更新
5. Operations Phase完了コミット
6. PRを作成（`gh pr create`）
7. PRをマージ
8. GitHub Actionsが自動でタグ作成
9. 必要に応じてGitHub Releasesでリリースノート作成

### ロールバック方法
```bash
# 前のバージョンに戻す場合
git checkout v1.2.0
```

---

## CI/CD設定方針

### 現状（v1.2.1時点）
- **CI/CDツール**: GitHub Actions
- **自動タグ付け**: mainブランチへのpush時に自動でタグ作成

### 設定ファイル
- `.github/workflows/auto-tag.yml` - 自動タグ付けワークフロー

### 自動タグ付けの仕組み
1. mainブランチにpush
2. `version.txt` からバージョンを読み取り
3. 同名タグが存在しなければ `v{VERSION}` タグを作成・push

### リリースフロー
1. サイクルブランチで `version.txt` を更新（例: 1.2.1）
2. mainブランチへマージ
3. GitHub Actionsが自動で `v1.2.1` タグを作成

### 将来検討事項
- Markdownリンター（markdownlint）
- テンプレート整合性チェック
- PR時の自動レビュー

---

## 監視設定

### 現状（v1.2.1時点）
- **監視ツール**: なし
- **理由**: ドキュメントプロジェクトのため不要

### 将来検討事項
- GitHub Insightsによるトラフィック分析
- 利用状況のトラッキング

---

## 既知の問題・注意点

### 運用で発覚した問題
| 問題 | ワークアラウンド | 根本対応予定 |
|------|-----------------|-------------|
| なし | - | - |

### 運用時の注意点
- メタ開発の意識: AI-DLCスターターキット自体を開発していることを常に意識
- セットアップ時の動作確認: 変更後は別ディレクトリでセットアップをテスト

---

## メタ開発特有の完了時作業【重要】

このプロジェクト（AI-DLC Starter Kit自体の開発）では、一般的なOperations Phase完了時の作業に加えて、以下の作業が必要です。

### 1. バージョン更新
`version.txt`（ルート）を新バージョンに更新:
```bash
echo "X.X.X" > version.txt
```

### 2. setup-init実行（アップグレード）
`docs/aidlc/` を最新のスターターキット（`prompts/package/`）と同期:
```bash
# prompts/package/ から docs/aidlc/ にコピー
\cp -f prompts/package/prompts/*.md docs/aidlc/prompts/
\cp -rf prompts/package/prompts/lite/ docs/aidlc/prompts/lite/
\cp -rf prompts/package/templates/ docs/aidlc/templates/
\cp -f version.txt docs/aidlc/version.txt
```

**効果**:
- プロンプト・テンプレートが最新化される
- `docs/aidlc/version.txt` がルートと同期される
- project.toml、additional-rules.md は保持される（上書きしない）

### 注意
これらの作業は一般プロジェクトでは不要です。AI-DLC Starter Kit自体を開発している（メタ開発）ため必要になります。

---

## 更新履歴

| 日時 | サイクル | 更新内容 |
|------|---------|---------|
| 2025-12-06 | v1.2.1 | 初回作成、メタ開発特有の完了時作業を追加 |
