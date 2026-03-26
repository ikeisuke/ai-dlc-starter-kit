# CI/CD設定 - v1.5.3

## 概要

このサイクルでのCI/CD設定状況を記録します。

## 現在のCI/CD構成

### ワークフロー一覧

| ワークフロー | ファイル | トリガー | 用途 |
|-------------|---------|---------|------|
| Auto Tag on Main | `.github/workflows/auto-tag.yml` | main push | バージョンタグ自動作成 |
| PR Check | `.github/workflows/pr-check.yml` | PR (main) | Markdownリント |

### 1. Auto Tag on Main (`auto-tag.yml`)

**トリガー**: mainブランチへのpush

**処理内容**:
1. `version.txt` からバージョンを読み取り
2. 同名タグが存在するか確認
3. 存在しなければ `v{VERSION}` タグを作成・push

**設定済み**: v1.2.1から導入

### 2. PR Check (`pr-check.yml`)

**トリガー**: mainブランチへのPR（Markdownファイル変更時）

**処理内容**:
1. Markdownファイルのリント実行
2. `docs/**/*.md`, `prompts/**/*.md`, `*.md` を対象

**設定済み**: v1.5.3で導入（Unit 007）

## v1.5.3での変更点

- `pr-check.yml` を新規追加（Markdownリント）
- `.markdownlint.json` を追加（リント設定）

## リリースフロー

```
1. サイクルブランチで開発
   ↓
2. version.txt を更新（例: 1.5.3）
   ↓
3. Operations Phase完了コミット
   ↓
4. PRを作成
   ↓
5. PR Check（Markdownリント）実行 ← 自動
   ↓
6. PRをマージ
   ↓
7. Auto Tag実行 → v1.5.3タグ作成 ← 自動
```

## 将来の改善案

- [ ] テンプレート整合性チェック（テンプレートとプロンプトの同期確認）
- [ ] セットアップスクリプトのテスト自動化
- [ ] リリースノート自動生成

## 備考

- ドキュメントプロジェクトのため、ビルド・デプロイワークフローは不要
- リントエラーがあってもPRはマージ可能（警告のみ）
