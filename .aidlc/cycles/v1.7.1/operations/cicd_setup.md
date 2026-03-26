# CI/CD セットアップ

## サイクル情報

- **サイクル**: v1.7.1
- **作成日**: 2026-01-11

## 既存ワークフロー

### 1. auto-tag.yml（自動タグ付け）

- **トリガー**: mainブランチへのpush
- **動作**: version.txtからバージョンを読み取り、`vX.Y.Z`形式のタグを作成
- **状態**: 変更不要

### 2. pr-check.yml（PRチェック）

- **トリガー**: mainブランチへのPR作成時
- **対象**: `**.md`, `.markdownlint.json`, `.github/workflows/pr-check.yml`
- **チェック内容**: Markdownlint
- **状態**: 変更不要

## v1.7.1での変更

CI/CD設定に変更はありません。既存のワークフローで対応可能です。

## リリースフロー

```text
1. サイクルブランチで開発
   └── cycle/v1.7.1

2. PRをReady for Reviewに変更
   └── gh pr ready

3. Markdownlintチェック（自動）
   └── .github/workflows/pr-check.yml

4. PRレビュー・マージ

5. 自動タグ作成（自動）
   └── .github/workflows/auto-tag.yml
   └── v1.7.1タグが作成される
```

## 将来の検討事項

運用引き継ぎ（docs/cycles/operations.md）に記載:

- テンプレート整合性チェック
- セットアップテストの自動化
