# CI/CD設定

## サイクル情報

- **サイクル**: v1.9.0
- **更新日**: 2026-01-23

## CI/CDツール

- **プラットフォーム**: GitHub Actions
- **変更**: なし（v1.8.1から継続）

## ワークフロー一覧

### 1. 自動タグ付け (`auto-tag.yml`)

- **トリガー**: mainブランチへのpush
- **動作**: version.txt からバージョンを読み取り、`v{VERSION}` タグを自動作成
- **パーミッション**: contents: write

### 2. PRチェック (`pr-check.yml`)

- **トリガー**: mainブランチへのPR（.mdファイル変更時）
- **動作**: markdownlintによる自動チェック
- **対象ファイル**:
  - `docs/translations/**/*.md`
  - `prompts/**/*.md`
  - `*.md`

## リリースフロー

```text
1. サイクルブランチで開発
2. version.txt を更新（例: 1.9.0）
3. PR作成 → markdownlintチェック
4. PRマージ
5. GitHub Actionsが自動で v1.9.0 タグを作成
```

## 今後の検討事項

- テンプレート整合性チェックの自動化
- セットアップテストの自動化
