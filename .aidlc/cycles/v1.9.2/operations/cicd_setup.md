# CI/CD設定 - v1.9.2

## 概要

このプロジェクト（AI-DLCスターターキット）のCI/CD設定状況を記録します。

## 現在の設定（変更なし）

### 1. 自動タグ付け（auto-tag.yml）

- **トリガー**: mainブランチへのpush
- **動作**:
  1. version.txtからバージョン読み取り
  2. タグが存在しない場合、`v{VERSION}`タグを作成・push

### 2. PRチェック（pr-check.yml）

- **トリガー**: mainブランチへのPR（.mdファイル変更時）
- **動作**: Markdownlint実行
- **対象**:
  - `docs/translations/**/*.md`
  - `prompts/**/*.md`
  - `*.md`

## v1.9.2での変更

なし（既存設定を継続使用）

## 将来の検討事項

- テンプレート整合性チェック
- セットアップテストの自動化

## 参照

- 運用引き継ぎ情報: `docs/cycles/operations.md`
